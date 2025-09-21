import SwiftUI
import Combine


struct AddActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var selectedActivityType: ActivityType = .feeding
    
    let preselectedType: ActivityType?
    let preselectedFeedingType: FeedingType?
    let editingActivity: TotsActivity?
    let editingGrowthEntry: GrowthEntry?
    
    init(preselectedType: ActivityType? = nil, preselectedFeedingType: FeedingType? = nil, editingActivity: TotsActivity? = nil, editingGrowthEntry: GrowthEntry? = nil) {
        self.preselectedType = preselectedType
        self.preselectedFeedingType = preselectedFeedingType
        self.editingActivity = editingActivity
        self.editingGrowthEntry = editingGrowthEntry
    }
    @State private var activityTime = Date()
    @State private var selectedMood: BabyMood = .content
    @State private var notes = ""
    
    // Activity-specific states
    @State private var feedingAmount = ""
    @State private var feedingAmountOz: Double = 4.0
    @State private var feedingType: FeedingType = .bottle
    @State private var diaperType: DiaperType = .wet
    @State private var sleepDuration = 1.5
    @State private var milestoneTitle = ""
    @State private var milestoneDescription = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var selectedWeightLbs: Double = 8.0
    @State private var selectedWeightOz: Double = 0.0
    @State private var selectedWeightKg: Double = 3.6
    @State private var selectedHeightFt: Int = 1
    @State private var selectedHeightIn: Double = 8.0
    @State private var selectedHeightCm: Double = 50.8
    @State private var selectedHeadCircumferenceCm: Double = 35.0
    @State private var selectedHeadCircumferenceIn: Double = 13.8
    
    // Activity stopwatch states
    @State private var activityIsRunning = false
    @State private var activityStartTime: Date?
    @State private var activityElapsed: TimeInterval = 0
    @State private var activityTimer: Timer?
    @State private var selectedActivitySubType: ActivitySubType = .tummyTime
    
    // Pumping timer states
    @State private var leftPumpingIsRunning = false
    @State private var leftPumpingStartTime: Date?
    @State private var leftPumpingElapsed: TimeInterval = 0
    @State private var leftPumpingTimer: Timer?
    @State private var leftPumpingMinutes: String = ""
    @State private var leftPumpingSeconds: String = ""
    
    @State private var rightPumpingIsRunning = false
    @State private var rightPumpingStartTime: Date?
    @State private var rightPumpingElapsed: TimeInterval = 0
    @State private var rightPumpingTimer: Timer?
    @State private var rightPumpingMinutes: String = ""
    @State private var rightPumpingSeconds: String = ""
    @State private var pumpingManualMode = false
    
    // Breastfeeding timer states
    @State private var breastfeedingIsRunning = false
    @State private var breastfeedingStartTime: Date?
    @State private var breastfeedingElapsed: TimeInterval = 0
    @State private var breastfeedingTimer: Timer?
    @State private var breastfeedingMinutes: String = ""
    @State private var breastfeedingSeconds: String = ""
    @State private var breastfeedingManualMode = false
    
    @State private var showingDeleteConfirmation = false
    @State private var showingCancelConfirmation = false
    @State private var growthValuesPrepopulated = false
    
    // Background time tracking
    @State private var backgroundStartTime: Date?
    
    // MARK: - Computed Properties
    private var hasActiveTimers: Bool {
        breastfeedingIsRunning || leftPumpingIsRunning || rightPumpingIsRunning || activityIsRunning
    }
    
    enum FeedingType: String, CaseIterable {
        case bottle = "Bottle"
        case breastfeeding = "Breastfeeding"
        case solid = "Solid Food"
        
        var icon: String {
            switch self {
            case .bottle: return "🍼"
            case .breastfeeding: return "🤱"
            case .solid: return "🥄"
            }
        }
    }
    
    enum DiaperType: String, CaseIterable {
        case wet = "Wet"
        case dirty = "Dirty"
        case mixed = "Mixed"
        
        var icon: String {
            switch self {
            case .wet: return "💧"
            case .dirty: return "💩"
            case .mixed: return "🔄"
            }
        }
    }
    
    private var navigationTitle: String {
        if let editingActivity = editingActivity {
            return "Edit \(editingActivity.type.name)"
        } else if editingGrowthEntry != nil {
            return "Edit Growth"
        } else {
            return "Add \(selectedActivityType.name)"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Unit toggle for growth activities
                        if selectedActivityType == .growth {
                            unitToggleRow
                        }
                        
                        // Time selector
                        timeSelectorView
                        
                        // Activity details
                        activityDetailsView
                        
                        // Notes
                        notesView
                        
                        // Save button
                        saveButtonView
                    }
                    .padding()
                }
            }
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasActiveTimers {
                            showingCancelConfirmation = true
                        } else {
                        dismiss()
                        }
                    }
                }
                
                // Add delete button when editing existing records
                if editingActivity != nil || editingGrowthEntry != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Delete") {
                            showingDeleteConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .confirmationDialog("Delete Record", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteRecord()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this record? This action cannot be undone.")
        }
        .confirmationDialog("Active Timers", isPresented: $showingCancelConfirmation, titleVisibility: .visible) {
            // Context-aware timer controls based on current activity
            if selectedActivityType == .feeding && breastfeedingIsRunning {
                Button("Stop Breastfeeding Timer") {
                    stopBreastfeedingTimer()
                    dismiss()
                }
            } else if selectedActivityType == .pumping && (leftPumpingIsRunning || rightPumpingIsRunning) {
                Button("Stop Pumping Timers") {
                    stopLeftPumping()
                    stopRightPumping()
                    dismiss()
                }
            } else if selectedActivityType == .activity && activityIsRunning {
                Button("Stop Activity Timer") {
                    stopActivity()
                    dismiss()
                }
            } else {
                // Fallback: show all active timers if context is unclear
                if breastfeedingIsRunning {
                    Button("Stop Breastfeeding Timer") {
                        stopBreastfeedingTimer()
                        checkAndDismissIfNoTimers()
                    }
                }
                
                if leftPumpingIsRunning || rightPumpingIsRunning {
                    Button("Stop Pumping Timers") {
                        stopLeftPumping()
                        stopRightPumping()
                        checkAndDismissIfNoTimers()
                    }
                }
                
                if activityIsRunning {
                    Button("Stop Activity Timer") {
                        stopActivity()
                        checkAndDismissIfNoTimers()
                    }
                }
            }
            
            Button("Exit but Keep Timers", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("You have active timers running. Do you want to stop them or exit while keeping them running?")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            restoreBreastfeedingTimer()
            restorePumpingTimers()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            // Timers continue running in background via UserDefaults tracking
        }
        .onAppear {
            if let editingActivity = editingActivity {
                // Check if this is an active session being edited (time is very recent)
                let isActiveSession = Date().timeIntervalSince(editingActivity.time) < 60 // Within last minute
                
                // Always parse details first to get the stored values
                parseActivityDetails(editingActivity)
                
                if isActiveSession {
                    // For active sessions, also restore timers
                    restoreBreastfeedingTimer()
                    restorePumpingTimers()
                    
                    // Only override with current timer values if text fields are still empty
                    if editingActivity.type == .feeding && editingActivity.details.contains("Breastfeeding") {
                        if breastfeedingMinutes.isEmpty {
                            breastfeedingMinutes = String(Int(breastfeedingElapsed / 60))
                        }
                        if breastfeedingSeconds.isEmpty {
                            breastfeedingSeconds = String(Int(breastfeedingElapsed) % 60)
                        }
                        feedingType = .breastfeeding
                    } else if editingActivity.type == .pumping {
                        if leftPumpingMinutes.isEmpty {
                            leftPumpingMinutes = String(Int(leftPumpingElapsed / 60))
                        }
                        if leftPumpingSeconds.isEmpty {
                            leftPumpingSeconds = String(Int(leftPumpingElapsed) % 60)
                        }
                        if rightPumpingMinutes.isEmpty {
                            rightPumpingMinutes = String(Int(rightPumpingElapsed / 60))
                        }
                        if rightPumpingSeconds.isEmpty {
                            rightPumpingSeconds = String(Int(rightPumpingElapsed) % 60)
                        }
                    }
                }
                
                // Populate fields for editing
                selectedActivityType = editingActivity.type
                activityTime = editingActivity.time
                notes = editingActivity.notes ?? ""
            } else if let editingGrowthEntry = editingGrowthEntry {
                // Populate fields for editing growth entry
                selectedActivityType = .growth
                activityTime = editingGrowthEntry.date
                
                // Populate growth-specific fields
                // GrowthEntry stores weight in kg, height in cm, head circumference in cm
                selectedWeightKg = editingGrowthEntry.weight
                selectedWeightLbs = editingGrowthEntry.weight / 0.453592 // Convert kg to lbs
                
                // Convert height from cm to feet and inches
                let totalInches = editingGrowthEntry.height / 2.54 // Convert cm to inches
                selectedHeightFt = Int(totalInches / 12)
                selectedHeightIn = totalInches.truncatingRemainder(dividingBy: 12)
                selectedHeightCm = editingGrowthEntry.height // Already in cm
                
                selectedHeadCircumferenceCm = editingGrowthEntry.headCircumference
                selectedHeadCircumferenceIn = editingGrowthEntry.headCircumference / 2.54
            } else {
                // Only restore timers when not editing
                restoreBreastfeedingTimer()
                restorePumpingTimers()
                if let preselectedType = preselectedType {
                selectedActivityType = preselectedType
                    if let preselectedFeedingType = preselectedFeedingType {
                        feedingType = preselectedFeedingType
                    }
                }
                
                // For new growth entries, prepopulate with last recorded values
                if selectedActivityType == .growth {
                    prepopulateGrowthWithLastValues()
                }
            }
        }
        .onDisappear {
            // Clean up all timers when view disappears
            activityTimer?.invalidate()
            activityTimer = nil
            leftPumpingTimer?.invalidate()
            leftPumpingTimer = nil
            rightPumpingTimer?.invalidate()
            rightPumpingTimer = nil
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var activityTypeSelectorView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Show only the selected activity type (non-interactive)
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    // Use same icons as recent activities
                    if selectedActivityType == .sleep {
                        Image(systemName: "moon.zzz.fill")
                            .font(.title2)
                            .foregroundColor(selectedActivityType.color)
                    } else if selectedActivityType == .milestone {
                        Image(systemName: "figure.child")
                            .font(.title2)
                            .foregroundColor(selectedActivityType.color)
                    } else if selectedActivityType.rawValue == "DiaperIcon" {
                        Image(selectedActivityType.rawValue)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(selectedActivityType.color)
                    } else {
                        Text(selectedActivityType.rawValue)
                            .font(.title2)
                    }
                    
                    Text(selectedActivityType.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .frame(width: 120, height: 80)
                .background(selectedActivityType.color.opacity(0.2))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                Spacer()
            }
        }
    }
    
    private var timeSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            DatePicker("Activity Time", selection: $activityTime, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(CompactDatePickerStyle())
                .padding()
                .liquidGlassCard()
        }
    }
    
    @ViewBuilder
    private var activityDetailsView: some View {
        switch selectedActivityType {
        case .feeding:
            feedingDetailsView
        case .diaper:
            diaperDetailsView
        case .sleep:
            sleepDetailsView
        case .milestone:
            milestoneDetailsView
        case .activity:
            activitySpecificDetailsView
        case .pumping:
            pumpingDetailsView
        case .growth:
            growthDetailsView
        }
    }
    
    private var feedingDetailsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Feeding type selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Type")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 0) {
                    ForEach(FeedingType.allCases.indices, id: \.self) { index in
                        let type = FeedingType.allCases[index]
                        Button(action: {
                            feedingType = type
                        }) {
                            Text(type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundColor(feedingType == type ? .white : .primary)
                                .background(feedingType == type ? Color.blue.opacity(0.8) : Color(.systemBackground))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .overlay(
                            Rectangle()
                                .frame(width: 1)
                                .foregroundColor(Color(.systemGray4))
                                .opacity(index < FeedingType.allCases.count - 1 ? 1 : 0),
                            alignment: .trailing
                        )
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            
            // Amount controls
            if feedingType == .bottle {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Amount")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("0 oz")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f oz", feedingAmountOz))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("12 oz")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $feedingAmountOz, in: 0...12, step: 0.5)
                            .accentColor(.pink)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
            } else if feedingType == .solid {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Description")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    TextField("What did they eat?", text: $feedingAmount)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
            } else if feedingType == .breastfeeding {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Duration")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Manual mode toggle - only show when not editing
                        if editingActivity == nil {
                            HStack(spacing: 4) {
                                Text(breastfeedingManualMode ? "Manual" : "Automatic")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Toggle("", isOn: $breastfeedingManualMode)
                                    .toggleStyle(SwitchToggleStyle(tint: .pink))
                                    .scaleEffect(0.8)
                                    .onChange(of: breastfeedingManualMode) { isManual in
                                        if isManual {
                                            // When switching to manual, populate text fields with current values
                                            if breastfeedingElapsed > 0 {
                                                breastfeedingMinutes = String(Int(breastfeedingElapsed / 60))
                                                breastfeedingSeconds = String(Int(breastfeedingElapsed) % 60)
                                            }
                                            if breastfeedingIsRunning {
                                                stopBreastfeedingTimer()
                                            }
                                        } else if !isManual && !breastfeedingMinutes.isEmpty {
                                            // Update elapsed time from manual input when switching back to automatic
                                            let minutes = Int(breastfeedingMinutes) ?? 0
                                            let seconds = Int(breastfeedingSeconds) ?? 0
                                            breastfeedingElapsed = TimeInterval(minutes * 60 + seconds)
                                        }
                                    }
                            }
                        }
                    }
                    
                    Group {
                        if breastfeedingManualMode || editingActivity != nil {
                            // Manual input fields when editing or when timer is stopped with elapsed time
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Minutes")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("0", text: Binding(
                                        get: {
                                            if !breastfeedingMinutes.isEmpty {
                                                return breastfeedingMinutes
                                            } else if breastfeedingElapsed > 0 {
                                                return String(Int(breastfeedingElapsed / 60))
                                            } else {
                                                return "0"
                                            }
                                        },
                                        set: { breastfeedingMinutes = $0 }
                                    ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Seconds")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("0", text: Binding(
                                        get: {
                                            if !breastfeedingSeconds.isEmpty {
                                                return breastfeedingSeconds
                                            } else if breastfeedingElapsed > 0 {
                                                return String(Int(breastfeedingElapsed) % 60)
                                            } else {
                                                return "0"
                                            }
                                        },
                                        set: { breastfeedingSeconds = $0 }
                                    ))
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                }
                            }
                        } else {
                            VStack(spacing: 16) {
                                // Timer display
                                VStack(spacing: 8) {
                                    Text(formatTime(breastfeedingElapsed))
                                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                                        .foregroundColor(.pink)
                                    
                                    Text("Duration")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Start/Pause button
                                Button(action: {
                                    if breastfeedingIsRunning {
                                        stopBreastfeedingTimer()
                                    } else {
                                        startBreastfeedingTimer()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: breastfeedingIsRunning ? "pause.fill" : "play.fill")
                                        Text(breastfeedingIsRunning ? "Pause" : (breastfeedingElapsed > 0 ? "Resume" : "Start"))
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(breastfeedingIsRunning ? Color.red : Color.green)
                                    .cornerRadius(12)
                                }
                                
                                // Reset button
                                if breastfeedingElapsed > 0 {
                                    Button(action: resetBreastfeedingTimer) {
                                        HStack {
                                            Image(systemName: "arrow.counterclockwise")
                                            Text("Reset")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
            }
        }
    }
    
    private var diaperDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack(spacing: 0) {
                ForEach(DiaperType.allCases.indices, id: \.self) { index in
                    let type = DiaperType.allCases[index]
                    Button(action: {
                        diaperType = type
                    }) {
                        Text(type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundColor(diaperType == type ? .white : .primary)
                            .background(diaperType == type ? Color.orange.opacity(0.8) : Color(.systemBackground))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .overlay(
                        Rectangle()
                            .frame(width: 1)
                            .foregroundColor(Color(.systemGray4))
                            .opacity(index < DiaperType.allCases.count - 1 ? 1 : 0),
                        alignment: .trailing
                    )
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }
    
    private var sleepDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Duration")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("30 min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f hours", sleepDuration))
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("12 hrs")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $sleepDuration, in: 0.5...12.0, step: 0.5)
                    .accentColor(.purple)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }
    
    private var milestoneDetailsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Title")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                TextField("e.g., First smile", text: $milestoneTitle)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                TextField("Additional details (optional)", text: $milestoneDescription, axis: .vertical)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    .lineLimit(3...6)
            }
        }
    }
    
    private var unitToggleRow: some View {
        HStack {
            Spacer()
            
            HStack(spacing: 6) {
                Text("cm/kg")
                    .font(.caption)
                    .fontWeight(dataManager.useMetricUnits ? .semibold : .regular)
                    .foregroundColor(dataManager.useMetricUnits ? .blue : .secondary)
                
                Toggle("", isOn: Binding(
                    get: { !dataManager.useMetricUnits },
                    set: { dataManager.useMetricUnits = !$0 }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .scaleEffect(0.8)
                .fixedSize()
                
                Text("in/lb")
                    .font(.caption)
                    .fontWeight(!dataManager.useMetricUnits ? .semibold : .regular)
                    .foregroundColor(!dataManager.useMetricUnits ? .blue : .secondary)
            }
        }
    }
    
    private var growthDetailsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Prepopulation message
            if growthValuesPrepopulated && editingActivity == nil && editingGrowthEntry == nil {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Values pre-filled with your last recorded measurements. Adjust as needed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Weight slider
            VStack(alignment: .leading, spacing: 12) {
                Text("Weight")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                if dataManager.useMetricUnits {
                    // Metric weight (kg)
                    VStack(spacing: 12) {
                        HStack {
                            Text("2 kg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f kg", selectedWeightKg))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("10 kg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $selectedWeightKg, in: 2...10, step: 0.1)
                            .accentColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                } else {
                    // Imperial weight (lbs/oz)
                    VStack(spacing: 12) {
                        HStack {
                            Text("4 lbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f lbs %.0f oz", selectedWeightLbs, selectedWeightOz))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("20 lbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Pounds")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            Slider(value: $selectedWeightLbs, in: 4...20, step: 0.1)
                                .accentColor(.blue)
                            
                            HStack {
                                Text("Ounces")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            Slider(value: $selectedWeightOz, in: 0...15, step: 0.5)
                                .accentColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
            }
            
            // Height slider
            VStack(alignment: .leading, spacing: 12) {
                Text("Height")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                if dataManager.useMetricUnits {
                    // Metric height (cm)
                    VStack(spacing: 12) {
                        HStack {
                            Text("30 cm")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f cm", selectedHeightCm))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("100 cm")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $selectedHeightCm, in: 30...100, step: 0.5)
                            .accentColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                } else {
                    // Imperial height (feet/inches)
                    VStack(spacing: 12) {
                        HStack {
                            Text("1' 0\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%d' %.1f\"", selectedHeightFt, selectedHeightIn))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("3' 0\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Feet")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            Slider(value: Binding(
                                get: { Double(selectedHeightFt) },
                                set: { selectedHeightFt = Int($0) }
                            ), in: 1...3, step: 1)
                                .accentColor(.blue)
                            
                            HStack {
                                Text("Inches")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            Slider(value: $selectedHeightIn, in: 0...11.5, step: 0.5)
                                .accentColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
            }
            
            // Head Circumference slider
            VStack(alignment: .leading, spacing: 12) {
                Text("Head Circumference")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                if dataManager.useMetricUnits {
                    // Metric head circumference (cm)
                    VStack(spacing: 12) {
                        HStack {
                            Text("30 cm")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f cm", selectedHeadCircumferenceCm))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("55 cm")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $selectedHeadCircumferenceCm, in: 30...55, step: 0.1)
                            .accentColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                } else {
                    // Imperial head circumference (inches)
                    VStack(spacing: 12) {
                        HStack {
                            Text("12\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f\"", selectedHeadCircumferenceIn))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("22\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $selectedHeadCircumferenceIn, in: 12...22, step: 0.1)
                            .accentColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
            }
        }
    }
    
    private var moodSelectorView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How was \(dataManager.babyName)'s mood?")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(BabyMood.allCases, id: \.self) { mood in
                    Button(action: {
                        selectedMood = mood
                    }) {
                        VStack(spacing: 4) {
                            Text(mood.rawValue)
                                .font(.title2)
                            
                            Text(mood.name)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .foregroundColor(selectedMood == mood ? .white : .primary)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMood == mood ? mood.color : Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var notesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Notes")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            TextField("Any additional details...", text: $notes, axis: .vertical)
                .padding()
                .liquidGlassCard()
                .lineLimit(3...6)
        }
    }
    
    private var saveButtonView: some View {
        Button(action: saveActivity) {
            Text(editingActivity != nil || editingGrowthEntry != nil ? "Update Activity" : "Save Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding()
                .liquidGlassCard()
        }
        .disabled(!isFormValid)
    }
    
    private var isFormValid: Bool {
        switch selectedActivityType {
        case .feeding:
            if feedingType == .bottle {
                return feedingAmountOz > 0
            } else if feedingType == .solid {
                return !feedingAmount.isEmpty
            } else {
                return true // Breastfeeding doesn't need additional input
            }
        case .milestone:
            return !milestoneTitle.isEmpty
        case .growth:
            return true // Always valid since sliders have default values
        default:
            return true
        }
    }
    
    private func saveActivity() {
        let details: String
        
        switch selectedActivityType {
        case .feeding:
            if feedingType == .bottle {
                details = "\(feedingType.rawValue) - \(String(format: "%.1f", feedingAmountOz)) oz"
            } else if feedingType == .solid {
                details = "\(feedingType.rawValue) - \(feedingAmount)"
            } else if feedingType == .breastfeeding {
                // Use text field values if editing or if timer is stopped with elapsed time
                let minutes: Int
                let seconds: Int
                
                if (editingActivity != nil || (!breastfeedingIsRunning && breastfeedingElapsed > 0)) && !breastfeedingMinutes.isEmpty {
                    minutes = Int(breastfeedingMinutes) ?? 0
                    seconds = Int(breastfeedingSeconds) ?? 0
                } else {
                    minutes = Int(breastfeedingElapsed / 60)
                    seconds = Int(breastfeedingElapsed) % 60
                }
                
                details = "\(feedingType.rawValue) - \(minutes)m \(seconds)s"
            } else {
                details = feedingType.rawValue
            }
        case .diaper:
            details = "\(diaperType.rawValue) diaper"
        case .sleep:
            details = String(format: "Slept for %.1f hours", sleepDuration)
        case .milestone:
            details = milestoneDescription.isEmpty ? milestoneTitle : "\(milestoneTitle) - \(milestoneDescription)"
        case .activity:
            if selectedActivitySubType == .tummyTime || selectedActivitySubType == .screenTime {
                // Timed activities include duration
                let minutes = Int(activityElapsed / 60)
                let seconds = Int(activityElapsed) % 60
                details = "\(selectedActivitySubType.name) - \(minutes)m \(seconds)s"
            } else {
                // Quick log activities just include the activity name
                details = selectedActivitySubType.name
            }
        case .pumping:
            // Use text field values if editing or if timer is stopped with elapsed time
            let leftMinutes: Int
            let leftSeconds: Int
            let rightMinutes: Int
            let rightSeconds: Int
            
            if (editingActivity != nil || (!leftPumpingIsRunning && leftPumpingElapsed > 0)) && !leftPumpingMinutes.isEmpty {
                leftMinutes = Int(leftPumpingMinutes) ?? 0
                leftSeconds = Int(leftPumpingSeconds) ?? 0
            } else {
                leftMinutes = Int(leftPumpingElapsed / 60)
                leftSeconds = Int(leftPumpingElapsed) % 60
            }
            
            if (editingActivity != nil || (!rightPumpingIsRunning && rightPumpingElapsed > 0)) && !rightPumpingMinutes.isEmpty {
                rightMinutes = Int(rightPumpingMinutes) ?? 0
                rightSeconds = Int(rightPumpingSeconds) ?? 0
            } else {
                rightMinutes = Int(rightPumpingElapsed / 60)
                rightSeconds = Int(rightPumpingElapsed) % 60
            }
            
            let totalMinutes = leftMinutes + rightMinutes + (leftSeconds + rightSeconds) / 60
            let totalSeconds = (leftSeconds + rightSeconds) % 60
            details = "Left: \(leftMinutes)m \(leftSeconds)s, Right: \(rightMinutes)m \(rightSeconds)s, Total: \(totalMinutes)m \(totalSeconds)s"
        case .growth:
            if dataManager.useMetricUnits {
                details = String(format: "Weight: %.1f kg, Height: %.1f cm, Head: %.1f cm", 
                               selectedWeightKg, selectedHeightCm, selectedHeadCircumferenceCm)
            } else {
                let totalWeightLbs = selectedWeightLbs + (selectedWeightOz / 16.0)
                details = String(format: "Weight: %.1f lbs, Height: %d'%.1f\", Head: %.1f\"", 
                               totalWeightLbs, selectedHeightFt, selectedHeightIn, selectedHeadCircumferenceIn)
            }
        }
        
        if let editingActivity = editingActivity {
            // Update existing activity
            dataManager.updateActivity(editingActivity, with: TotsActivity(
                type: selectedActivityType,
                time: activityTime,
                details: details,
                mood: .content,
                duration: getDuration(),
                notes: notes.isEmpty ? nil : notes,
                weight: selectedActivityType == .growth ? getWeight() : nil,
                height: selectedActivityType == .growth ? getHeight() : nil,
                headCircumference: selectedActivityType == .growth ? getHeadCircumference() : nil
            ))
        } else if let editingGrowthEntry = editingGrowthEntry {
            // Find and update the corresponding activity for this growth entry
            if let correspondingActivity = dataManager.recentActivities.first(where: { 
                $0.type == .growth && 
                Calendar.current.isDate($0.time, equalTo: editingGrowthEntry.date, toGranularity: .minute)
            }) {
                dataManager.updateActivity(correspondingActivity, with: TotsActivity(
                    type: selectedActivityType,
                    time: activityTime,
                    details: details,
                    mood: .content,
                    duration: getDuration(),
                    notes: notes.isEmpty ? nil : notes,
                    weight: selectedActivityType == .growth ? getWeight() : nil,
                    height: selectedActivityType == .growth ? getHeight() : nil,
                    headCircumference: selectedActivityType == .growth ? getHeadCircumference() : nil
                ))
            } else {
                // If no corresponding activity found, create a new one
                let activity = TotsActivity(
                    type: selectedActivityType,
                    time: activityTime,
                    details: details,
                    mood: .content,
                    duration: getDuration(),
                    notes: notes.isEmpty ? nil : notes,
                    weight: selectedActivityType == .growth ? getWeight() : nil,
                    height: selectedActivityType == .growth ? getHeight() : nil,
                    headCircumference: selectedActivityType == .growth ? getHeadCircumference() : nil
                )
                
                dataManager.addActivity(activity)
            }
        } else {
            // Create new activity
            let activity = TotsActivity(
                type: selectedActivityType,
                time: activityTime,
                details: details,
                mood: .content,
                duration: getDuration(),
                notes: notes.isEmpty ? nil : notes,
                weight: selectedActivityType == .growth ? getWeight() : nil,
                height: selectedActivityType == .growth ? getHeight() : nil,
                headCircumference: selectedActivityType == .growth ? getHeadCircumference() : nil
            )
            
            dataManager.addActivity(activity)
        }
        
        // Reset timers after saving
        if selectedActivityType == .feeding && feedingType == .breastfeeding {
            resetBreastfeedingTimer()
        } else if selectedActivityType == .pumping {
            // Stop and reset both pumping timers
            stopLeftPumping()
            stopRightPumping()
            resetLeftPumping()
            resetRightPumping()
        }
        
        dismiss()
    }
    
    private func deleteRecord() {
        if let editingActivity = editingActivity {
            // Delete the activity
            dataManager.deleteActivity(editingActivity)
        } else if let editingGrowthEntry = editingGrowthEntry {
            // Find and delete the corresponding activity for this growth entry
            if let correspondingActivity = dataManager.recentActivities.first(where: { 
                $0.type == .growth && 
                Calendar.current.isDate($0.time, equalTo: editingGrowthEntry.date, toGranularity: .minute)
            }) {
                dataManager.deleteActivity(correspondingActivity)
            }
        }
        
        dismiss()
    }
    
    private var activitySpecificDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Activity type selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Activity Type")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(ActivitySubType.allCases, id: \.self) { subType in
                        Button(action: {
                            selectedActivitySubType = subType
                        }) {
                            HStack {
                                Text(subType.rawValue)
                                    .font(.title2)
                                Text(subType.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedActivitySubType == subType ? subType.color.opacity(0.2) : Color(.systemGray6))
                            .foregroundColor(selectedActivitySubType == subType ? subType.color : .primary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Only show timer for activities that need duration tracking
            if selectedActivitySubType == .tummyTime || selectedActivitySubType == .screenTime {
                VStack(spacing: 20) {
                    // Stopwatch display
                    VStack(spacing: 8) {
                        Text(formatElapsedTime(activityElapsed))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(activityIsRunning ? .green : .primary)
                        
                        Text(activityIsRunning ? "Timer Running" : "Timer Stopped")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Start/Stop button (only show one at a time)
                    if activityIsRunning {
                        Button(action: stopActivity) {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    } else {
                        Button(action: startActivity) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    
                    // Reset button
                    Button(action: resetActivity) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .disabled(activityIsRunning)
                }
            } else {
                // For other activities, just show a note that it's a quick log
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Quick Log Activity")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Text("This activity will be logged with the current time. No timer needed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding()
        .liquidGlassCard()
    }
    
    private var pumpingDetailsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
            Text("Pumping Session")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                
                Spacer()
                
                // Manual mode toggle - only show when not editing
                if editingActivity == nil {
                    HStack(spacing: 4) {
                        Text(pumpingManualMode ? "Manual" : "Automatic")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Toggle("", isOn: $pumpingManualMode)
                            .toggleStyle(SwitchToggleStyle(tint: .cyan))
                            .scaleEffect(0.8)
                            .onChange(of: pumpingManualMode) { isManual in
                                if isManual {
                                    // When switching to manual, populate text fields with current values
                                    if leftPumpingElapsed > 0 {
                                        leftPumpingMinutes = String(Int(leftPumpingElapsed / 60))
                                        leftPumpingSeconds = String(Int(leftPumpingElapsed) % 60)
                                    }
                                    if rightPumpingElapsed > 0 {
                                        rightPumpingMinutes = String(Int(rightPumpingElapsed / 60))
                                        rightPumpingSeconds = String(Int(rightPumpingElapsed) % 60)
                                    }
                                    if leftPumpingIsRunning {
                                        stopLeftPumping()
                                    }
                                    if rightPumpingIsRunning {
                                        stopRightPumping()
                                    }
                                } else if !isManual {
                                    // Update elapsed times from manual input when switching back to automatic
                                    if !leftPumpingMinutes.isEmpty {
                                        let minutes = Int(leftPumpingMinutes) ?? 0
                                        let seconds = Int(leftPumpingSeconds) ?? 0
                                        leftPumpingElapsed = TimeInterval(minutes * 60 + seconds)
                                    }
                                    if !rightPumpingMinutes.isEmpty {
                                        let minutes = Int(rightPumpingMinutes) ?? 0
                                        let seconds = Int(rightPumpingSeconds) ?? 0
                                        rightPumpingElapsed = TimeInterval(minutes * 60 + seconds)
                                    }
                                }
                            }
                    }
                }
            }
            
            HStack(spacing: 20) {
                // Left breast timer
                VStack(spacing: 16) {
                    Text("Left Breast")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if pumpingManualMode || editingActivity != nil {
                        // Manual input for editing or stopped timer
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                TextField("0", text: Binding(
                                    get: {
                                        if !leftPumpingMinutes.isEmpty {
                                            return leftPumpingMinutes
                                        } else if leftPumpingElapsed > 0 {
                                            return String(Int(leftPumpingElapsed / 60))
                                        } else {
                                            return "0"
                                        }
                                    },
                                    set: { leftPumpingMinutes = $0 }
                                ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: 50)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sec")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                TextField("0", text: Binding(
                                    get: {
                                        if !leftPumpingSeconds.isEmpty {
                                            return leftPumpingSeconds
                                        } else if leftPumpingElapsed > 0 {
                                            return String(Int(leftPumpingElapsed) % 60)
                                        } else {
                                            return "0"
                                        }
                                    },
                                    set: { leftPumpingSeconds = $0 }
                                ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: 50)
                            }
                        }
                    } else {
                    VStack(spacing: 8) {
                        Text(formatTime(leftPumpingElapsed))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(leftPumpingIsRunning ? .cyan : .primary)
                        
                            Text(leftPumpingIsRunning ? "Running" : (leftPumpingElapsed > 0 ? "Paused" : "Stopped"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Left timer controls - only show if not editing and not in manual mode
                    if editingActivity == nil && !pumpingManualMode {
                    VStack(spacing: 8) {
                        if leftPumpingIsRunning {
                            Button(action: stopLeftPumping) {
                                HStack {
                                        Image(systemName: "pause.fill")
                                        Text("Pause")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .cornerRadius(8)
                            }
                        } else {
                            Button(action: startLeftPumping) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        Text(leftPumpingElapsed > 0 ? "Resume" : "Start")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                    .background(Color.green)
                                .cornerRadius(8)
                            }
                        }
                        
                        Button(action: resetLeftPumping) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Right breast timer
                VStack(spacing: 16) {
                    Text("Right Breast")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if pumpingManualMode || editingActivity != nil {
                        // Manual input for editing or stopped timer
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Min")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                TextField("0", text: Binding(
                                    get: {
                                        if !rightPumpingMinutes.isEmpty {
                                            return rightPumpingMinutes
                                        } else if rightPumpingElapsed > 0 {
                                            return String(Int(rightPumpingElapsed / 60))
                                        } else {
                                            return "0"
                                        }
                                    },
                                    set: { rightPumpingMinutes = $0 }
                                ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: 50)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sec")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                TextField("0", text: Binding(
                                    get: {
                                        if !rightPumpingSeconds.isEmpty {
                                            return rightPumpingSeconds
                                        } else if rightPumpingElapsed > 0 {
                                            return String(Int(rightPumpingElapsed) % 60)
                                        } else {
                                            return "0"
                                        }
                                    },
                                    set: { rightPumpingSeconds = $0 }
                                ))
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: 50)
                            }
                        }
                    } else {
                    VStack(spacing: 8) {
                        Text(formatTime(rightPumpingElapsed))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(rightPumpingIsRunning ? .cyan : .primary)
                        
                            Text(rightPumpingIsRunning ? "Running" : (rightPumpingElapsed > 0 ? "Paused" : "Stopped"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    // Right timer controls - only show if not editing and not in manual mode
                    if editingActivity == nil && !pumpingManualMode {
                    VStack(spacing: 8) {
                        if rightPumpingIsRunning {
                            Button(action: stopRightPumping) {
                                HStack {
                                        Image(systemName: "pause.fill")
                                        Text("Pause")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .cornerRadius(8)
                            }
                        } else {
                            Button(action: startRightPumping) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        Text(rightPumpingElapsed > 0 ? "Resume" : "Start")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                    .background(Color.green)
                                .cornerRadius(8)
                            }
                        }
                        
                        Button(action: resetRightPumping) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Total session time
            VStack(spacing: 8) {
                Text("Total Session Time")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(formatTime(leftPumpingElapsed + rightPumpingElapsed))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(12)
        }
        .padding()
        .liquidGlassCard()
    }
    
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startActivity() {
        activityIsRunning = true
        activityStartTime = Date()
        
        activityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = activityStartTime {
                activityElapsed = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopActivity() {
        activityIsRunning = false
        activityTimer?.invalidate()
        activityTimer = nil
    }
    
    private func resetActivity() {
        activityElapsed = 0
        activityStartTime = nil
    }
    
    // Pumping timer functions
    private func startLeftPumping() {
        // If we have edited values in text fields, use them as the starting point
        if !leftPumpingMinutes.isEmpty || !leftPumpingSeconds.isEmpty {
            let minutes = Int(leftPumpingMinutes) ?? 0
            let seconds = Int(leftPumpingSeconds) ?? 0
            leftPumpingElapsed = TimeInterval(minutes * 60 + seconds)
        }
        
        // Always calculate start time based on current elapsed time (for resume functionality)
        leftPumpingStartTime = Date().addingTimeInterval(-leftPumpingElapsed)
        
        leftPumpingIsRunning = true
        
        leftPumpingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateLeftPumpingElapsed()
        }
        
        // Store start time for background tracking
        UserDefaults.standard.set(leftPumpingStartTime, forKey: "leftPumpingStartTime")
        UserDefaults.standard.set(leftPumpingElapsed, forKey: "leftPumpingElapsed")
        UserDefaults.standard.set(true, forKey: "leftPumpingIsRunning")
    }
    
    private func stopLeftPumping() {
        leftPumpingTimer?.invalidate()
        leftPumpingTimer = nil
        leftPumpingIsRunning = false
        
        // Clear background tracking
        UserDefaults.standard.removeObject(forKey: "leftPumpingStartTime")
        UserDefaults.standard.removeObject(forKey: "leftPumpingElapsed")
        UserDefaults.standard.set(false, forKey: "leftPumpingIsRunning")
    }
    
    private func resetLeftPumping() {
        stopLeftPumping()
        leftPumpingElapsed = 0
        leftPumpingStartTime = nil
        leftPumpingMinutes = ""
        leftPumpingSeconds = ""
    }
    
    private func updateLeftPumpingElapsed() {
        guard let startTime = leftPumpingStartTime else { return }
        leftPumpingElapsed = Date().timeIntervalSince(startTime)
        
        // Update stored elapsed time for background tracking
        UserDefaults.standard.set(leftPumpingElapsed, forKey: "leftPumpingElapsed")
    }
    
    private func startRightPumping() {
        // If we have edited values in text fields, use them as the starting point
        if !rightPumpingMinutes.isEmpty || !rightPumpingSeconds.isEmpty {
            let minutes = Int(rightPumpingMinutes) ?? 0
            let seconds = Int(rightPumpingSeconds) ?? 0
            rightPumpingElapsed = TimeInterval(minutes * 60 + seconds)
        }
        
        // Always calculate start time based on current elapsed time (for resume functionality)
        rightPumpingStartTime = Date().addingTimeInterval(-rightPumpingElapsed)
        
        rightPumpingIsRunning = true
        
        rightPumpingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateRightPumpingElapsed()
        }
        
        // Store start time for background tracking
        UserDefaults.standard.set(rightPumpingStartTime, forKey: "rightPumpingStartTime")
        UserDefaults.standard.set(rightPumpingElapsed, forKey: "rightPumpingElapsed")
        UserDefaults.standard.set(true, forKey: "rightPumpingIsRunning")
    }
    
    private func stopRightPumping() {
        rightPumpingTimer?.invalidate()
        rightPumpingTimer = nil
        rightPumpingIsRunning = false
        
        // Clear background tracking
        UserDefaults.standard.removeObject(forKey: "rightPumpingStartTime")
        UserDefaults.standard.removeObject(forKey: "rightPumpingElapsed")
        UserDefaults.standard.set(false, forKey: "rightPumpingIsRunning")
    }
    
    private func resetRightPumping() {
        stopRightPumping()
        rightPumpingElapsed = 0
        rightPumpingStartTime = nil
        rightPumpingMinutes = ""
        rightPumpingSeconds = ""
    }
    
    private func updateRightPumpingElapsed() {
        guard let startTime = rightPumpingStartTime else { return }
        rightPumpingElapsed = Date().timeIntervalSince(startTime)
        
        // Update stored elapsed time for background tracking
        UserDefaults.standard.set(rightPumpingElapsed, forKey: "rightPumpingElapsed")
    }
    
    private func stopAllTimers() {
        // Stop breastfeeding timer
        if breastfeedingIsRunning {
            stopBreastfeedingTimer()
        }
        
        // Stop pumping timers
        if leftPumpingIsRunning {
            stopLeftPumping()
        }
        if rightPumpingIsRunning {
            stopRightPumping()
        }
        
        // Stop activity timer
        if activityIsRunning {
            stopActivity()
        }
    }
    
    private func checkAndDismissIfNoTimers() {
        // If no timers are running after stopping one, dismiss the view
        if !hasActiveTimers {
            dismiss()
        }
    }
    
    private func parseActivityDetails(_ activity: TotsActivity) {
        let details = activity.details.lowercased()
        
        switch activity.type {
        case .feeding:
            // Parse feeding amount from details like "Bottle - 4.0 oz"
            let ozPattern = #"(\d+(?:\.\d+)?)\s*oz"#
            if let regex = try? NSRegularExpression(pattern: ozPattern),
               let match = regex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
               let range = Range(match.range(at: 1), in: details) {
                feedingAmountOz = Double(String(details[range])) ?? 4.0
            }
            
            if details.contains("bottle") {
                feedingType = .bottle
            } else if details.contains("breastfeeding") {
                feedingType = .breastfeeding
                // Parse breastfeeding duration from details like "Breastfeeding - 15m 30s"
                let timePattern = #"(\d+)m\s*(\d+)s"#
                if let regex = try? NSRegularExpression(pattern: timePattern),
                   let match = regex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
                   let minutesRange = Range(match.range(at: 1), in: details),
                   let secondsRange = Range(match.range(at: 2), in: details) {
                    let minutes = Int(String(details[minutesRange])) ?? 0
                    let seconds = Int(String(details[secondsRange])) ?? 0
                    breastfeedingElapsed = TimeInterval(minutes * 60 + seconds)
                    // Populate text fields for editing
                    breastfeedingMinutes = String(minutes)
                    breastfeedingSeconds = String(seconds)
                }
            } else if details.contains("solid") {
                feedingType = .solid
            }
            
        case .diaper:
            if details.contains("wet") {
                diaperType = .wet
            } else if details.contains("dirty") {
                diaperType = .dirty
            } else if details.contains("mixed") {
                diaperType = .mixed
            }
            
        case .sleep:
            // Parse sleep duration from details like "Slept for 1.5 hours"
            let hourPattern = #"(\d+(?:\.\d+)?)\s*hours?"#
            if let regex = try? NSRegularExpression(pattern: hourPattern),
               let match = regex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
               let range = Range(match.range(at: 1), in: details) {
                sleepDuration = Double(String(details[range])) ?? 1.5
            }
            
        case .activity:
            // Parse activity duration and type from details like "Tummy Time - 15m 30s"
            if let duration = activity.duration {
                activityElapsed = TimeInterval(duration * 60) // Convert minutes to seconds
            }
            
            // Parse activity subtype
            for subType in ActivitySubType.allCases {
                if details.contains(subType.name.lowercased()) {
                    selectedActivitySubType = subType
                    break
                }
            }
            
        case .pumping:
            // Parse pumping session from details like "Left: 10m 30s, Right: 8m 45s, Total: 19m 15s"
            let leftPattern = #"left:\s*(\d+)m\s*(\d+)s"#
            let rightPattern = #"right:\s*(\d+)m\s*(\d+)s"#
            
            if let leftRegex = try? NSRegularExpression(pattern: leftPattern),
               let leftMatch = leftRegex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
               let leftMinutesRange = Range(leftMatch.range(at: 1), in: details),
               let leftSecondsRange = Range(leftMatch.range(at: 2), in: details) {
                let leftMinutes = Int(String(details[leftMinutesRange])) ?? 0
                let leftSeconds = Int(String(details[leftSecondsRange])) ?? 0
                leftPumpingElapsed = TimeInterval(leftMinutes * 60 + leftSeconds)
                // Populate text fields for editing
                leftPumpingMinutes = String(leftMinutes)
                leftPumpingSeconds = String(leftSeconds)
            }
            
            if let rightRegex = try? NSRegularExpression(pattern: rightPattern),
               let rightMatch = rightRegex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
               let rightMinutesRange = Range(rightMatch.range(at: 1), in: details),
               let rightSecondsRange = Range(rightMatch.range(at: 2), in: details) {
                let rightMinutes = Int(String(details[rightMinutesRange])) ?? 0
                let rightSeconds = Int(String(details[rightSecondsRange])) ?? 0
                rightPumpingElapsed = TimeInterval(rightMinutes * 60 + rightSeconds)
                // Populate text fields for editing
                rightPumpingMinutes = String(rightMinutes)
                rightPumpingSeconds = String(rightSeconds)
            }
            
        case .growth:
            // Parse growth measurements from details like "Weight: 7.5 kg, Height: 60.0 cm, Head: 40.0 cm"
            // or "Weight: 16.5 lbs, Height: 2'0.0", Head: 15.7""
            
            // Check if metric or imperial based on presence of "kg" or "lbs"
            if details.contains("kg") {
                // Metric units
                let weightPattern = #"weight:\s*([\d.]+)\s*kg"#
                let heightPattern = #"height:\s*([\d.]+)\s*cm"#
                let headPattern = #"head:\s*([\d.]+)\s*cm"#
                
                if let weightRegex = try? NSRegularExpression(pattern: weightPattern),
                   let match = weightRegex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
                   let range = Range(match.range(at: 1), in: details) {
                    selectedWeightKg = Double(String(details[range])) ?? 0
                    selectedWeightLbs = selectedWeightKg / 0.453592
                }
                
                if let heightRegex = try? NSRegularExpression(pattern: heightPattern),
                   let match = heightRegex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
                   let range = Range(match.range(at: 1), in: details) {
                    selectedHeightCm = Double(String(details[range])) ?? 0
                    let totalInches = selectedHeightCm / 2.54
                    selectedHeightFt = Int(totalInches / 12)
                    selectedHeightIn = totalInches.truncatingRemainder(dividingBy: 12)
                }
                
                if let headRegex = try? NSRegularExpression(pattern: headPattern),
                   let match = headRegex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
                   let range = Range(match.range(at: 1), in: details) {
                    selectedHeadCircumferenceCm = Double(String(details[range])) ?? 0
                    selectedHeadCircumferenceIn = selectedHeadCircumferenceCm / 2.54
                }
            } else {
                // Imperial units
                let weightPattern = #"weight:\s*([\d.]+)\s*lbs"#
                let heightPattern = #"height:\s*(\d+)'([\d.]+)\""#
                let headPattern = #"head:\s*([\d.]+)\""#
                
                if let weightRegex = try? NSRegularExpression(pattern: weightPattern),
                   let match = weightRegex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
                   let range = Range(match.range(at: 1), in: details) {
                    let totalLbs = Double(String(details[range])) ?? 0
                    selectedWeightLbs = floor(totalLbs)
                    selectedWeightOz = (totalLbs - selectedWeightLbs) * 16
                    selectedWeightKg = totalLbs * 0.453592
                }
                
                if let heightRegex = try? NSRegularExpression(pattern: heightPattern),
                   let match = heightRegex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
                   let feetRange = Range(match.range(at: 1), in: details),
                   let inchesRange = Range(match.range(at: 2), in: details) {
                    selectedHeightFt = Int(String(details[feetRange])) ?? 0
                    selectedHeightIn = Double(String(details[inchesRange])) ?? 0
                    let totalInches = Double(selectedHeightFt) * 12 + selectedHeightIn
                    selectedHeightCm = totalInches * 2.54
                }
                
                if let headRegex = try? NSRegularExpression(pattern: headPattern),
                   let match = headRegex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
                   let range = Range(match.range(at: 1), in: details) {
                    selectedHeadCircumferenceIn = Double(String(details[range])) ?? 0
                    selectedHeadCircumferenceCm = selectedHeadCircumferenceIn * 2.54
                }
            }
            
        default:
            break
        }
    }
    
    private func prepopulateGrowthWithLastValues() {
        // Get the most recent growth entry
        let sortedGrowthData = dataManager.growthData.sorted { $0.date > $1.date }
        guard let lastEntry = sortedGrowthData.first else { return }
        
        // Prepopulate with last recorded values
        selectedWeightKg = lastEntry.weight
        selectedWeightLbs = lastEntry.weight / 0.453592
        
        let totalInches = lastEntry.height / 2.54
        selectedHeightFt = Int(totalInches / 12)
        selectedHeightIn = totalInches.truncatingRemainder(dividingBy: 12)
        selectedHeightCm = lastEntry.height
        
        selectedHeadCircumferenceCm = lastEntry.headCircumference
        selectedHeadCircumferenceIn = lastEntry.headCircumference / 2.54
        
        // Set flag to show prepopulation message
        growthValuesPrepopulated = true
    }
    
    private func getDuration() -> Int? {
        switch selectedActivityType {
        case .sleep:
            return Int(sleepDuration * 60) // Convert hours to minutes
        case .feeding:
            if feedingType == .breastfeeding {
                // Use text field values if editing or if timer is stopped with elapsed time
                if (editingActivity != nil || (!breastfeedingIsRunning && breastfeedingElapsed > 0)) && !breastfeedingMinutes.isEmpty {
                    let minutes = Int(breastfeedingMinutes) ?? 0
                    let seconds = Int(breastfeedingSeconds) ?? 0
                    return minutes + (seconds > 0 ? 1 : 0) // Round up if there are seconds
                } else {
                    return Int(breastfeedingElapsed / 60)
                }
            } else {
                return nil
            }
        case .activity:
            // Only return duration for activities that use timers
            if selectedActivitySubType == .tummyTime || selectedActivitySubType == .screenTime {
                return Int(activityElapsed / 60) // Convert seconds to minutes
            } else {
                return nil // Quick log activities don't have duration
            }
        case .pumping:
            // Use text field values if editing or if timer is stopped with elapsed time
            let leftMinutes: Int
            let leftSeconds: Int
            let rightMinutes: Int
            let rightSeconds: Int
            
            if (editingActivity != nil || (!leftPumpingIsRunning && leftPumpingElapsed > 0)) && !leftPumpingMinutes.isEmpty {
                leftMinutes = Int(leftPumpingMinutes) ?? 0
                leftSeconds = Int(leftPumpingSeconds) ?? 0
            } else {
                leftMinutes = Int(leftPumpingElapsed / 60)
                leftSeconds = Int(leftPumpingElapsed) % 60
            }
            
            if (editingActivity != nil || (!rightPumpingIsRunning && rightPumpingElapsed > 0)) && !rightPumpingMinutes.isEmpty {
                rightMinutes = Int(rightPumpingMinutes) ?? 0
                rightSeconds = Int(rightPumpingSeconds) ?? 0
            } else {
                rightMinutes = Int(rightPumpingElapsed / 60)
                rightSeconds = Int(rightPumpingElapsed) % 60
            }
            
            return leftMinutes + rightMinutes + (leftSeconds + rightSeconds > 0 ? 1 : 0) // Round up if there are seconds
        default:
            return nil
        }
    }
    
    private func getWeight() -> Double {
        if dataManager.useMetricUnits {
            return selectedWeightKg
        } else {
            // Convert imperial to kg for storage
            let totalWeightLbs = selectedWeightLbs + (selectedWeightOz / 16.0)
            return dataManager.convertWeightToKg(totalWeightLbs, fromImperial: true)
        }
    }
    
    private func getHeight() -> Double {
        if dataManager.useMetricUnits {
            return selectedHeightCm
        } else {
            // Convert imperial to cm for storage
            let totalHeightInches = Double(selectedHeightFt * 12) + selectedHeightIn
            return dataManager.convertHeightToCm(totalHeightInches, fromImperial: true)
        }
    }
    
    private func getHeadCircumference() -> Double {
        if dataManager.useMetricUnits {
            return selectedHeadCircumferenceCm
        } else {
            // Convert imperial to cm for storage
            return selectedHeadCircumferenceIn * 2.54
        }
    }
    
    // MARK: - Breastfeeding Timer Functions
    
    private func startBreastfeedingTimer() {
        // If we have edited values in text fields, use them as the starting point
        if !breastfeedingMinutes.isEmpty || !breastfeedingSeconds.isEmpty {
            let minutes = Int(breastfeedingMinutes) ?? 0
            let seconds = Int(breastfeedingSeconds) ?? 0
            breastfeedingElapsed = TimeInterval(minutes * 60 + seconds)
        }
        
        // Always calculate start time based on current elapsed time (for resume functionality)
        breastfeedingStartTime = Date().addingTimeInterval(-breastfeedingElapsed)
        
        breastfeedingIsRunning = true
        
        breastfeedingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateBreastfeedingElapsed()
        }
        
        // Store start time for background tracking
        UserDefaults.standard.set(breastfeedingStartTime, forKey: "breastfeedingStartTime")
        UserDefaults.standard.set(breastfeedingElapsed, forKey: "breastfeedingElapsed")
        UserDefaults.standard.set(true, forKey: "breastfeedingIsRunning")
    }
    
    private func stopBreastfeedingTimer() {
        breastfeedingTimer?.invalidate()
        breastfeedingTimer = nil
        breastfeedingIsRunning = false
        
        // Clear background tracking
        UserDefaults.standard.removeObject(forKey: "breastfeedingStartTime")
        UserDefaults.standard.removeObject(forKey: "breastfeedingElapsed")
        UserDefaults.standard.set(false, forKey: "breastfeedingIsRunning")
    }
    
    private func resetBreastfeedingTimer() {
        stopBreastfeedingTimer()
        breastfeedingElapsed = 0
        breastfeedingStartTime = nil
        breastfeedingMinutes = ""
        breastfeedingSeconds = ""
    }
    
    private func updateBreastfeedingElapsed() {
        guard let startTime = breastfeedingStartTime else { return }
        breastfeedingElapsed = Date().timeIntervalSince(startTime)
        
        // Update stored elapsed time for background tracking
        UserDefaults.standard.set(breastfeedingElapsed, forKey: "breastfeedingElapsed")
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func restoreBreastfeedingTimer() {
        // Check if there's a running breastfeeding session
        if UserDefaults.standard.bool(forKey: "breastfeedingIsRunning"),
           let startTime = UserDefaults.standard.object(forKey: "breastfeedingStartTime") as? Date {
            
            // Calculate elapsed time including background time
            let backgroundElapsed = Date().timeIntervalSince(startTime)
            breastfeedingElapsed = backgroundElapsed
            breastfeedingStartTime = startTime
            breastfeedingIsRunning = true
            
            // Restart the timer
            breastfeedingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateBreastfeedingElapsed()
            }
        }
    }
    
    private func restorePumpingTimers() {
        // Restore left pumping timer
        if UserDefaults.standard.bool(forKey: "leftPumpingIsRunning"),
           let startTime = UserDefaults.standard.object(forKey: "leftPumpingStartTime") as? Date {
            
            // Calculate elapsed time including background time
            let backgroundElapsed = Date().timeIntervalSince(startTime)
            leftPumpingElapsed = backgroundElapsed
            leftPumpingStartTime = startTime
            leftPumpingIsRunning = true
            
            // Restart the timer
            leftPumpingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateLeftPumpingElapsed()
            }
        }
        
        // Restore right pumping timer
        if UserDefaults.standard.bool(forKey: "rightPumpingIsRunning"),
           let startTime = UserDefaults.standard.object(forKey: "rightPumpingStartTime") as? Date {
            
            // Calculate elapsed time including background time
            let backgroundElapsed = Date().timeIntervalSince(startTime)
            rightPumpingElapsed = backgroundElapsed
            rightPumpingStartTime = startTime
            rightPumpingIsRunning = true
            
            // Restart the timer
            rightPumpingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                updateRightPumpingElapsed()
            }
        }
    }
}

#Preview {
    AddActivityView()
        .environmentObject(TotsDataManager())
}