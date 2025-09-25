import SwiftUI
import Combine

// MARK: - Liquid Background (if not available from GlassModifier)
struct LiquidBackground: View {
    @State private var animateGradient = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? darkModeColors : lightModeColors,
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
    
    private var lightModeColors: [Color] {
        [
            Color.blue.opacity(0.6),
            Color.purple.opacity(0.4),
            Color.pink.opacity(0.3),
            Color.orange.opacity(0.5)
        ]
    }
    
    private var darkModeColors: [Color] {
        [
            Color.blue.opacity(0.3),
            Color.purple.opacity(0.2),
            Color.pink.opacity(0.15),
            Color.orange.opacity(0.25)
        ]
    }
}

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
    @State private var selectedWeightKg: Double = 3.6
    @State private var selectedHeightIn: Double = 20.0  // Total inches
    @State private var selectedHeightCm: Double = 50.8
    @State private var selectedHeadCircumferenceCm: Double = 35.0
    @State private var selectedHeadCircumferenceIn: Double = 13.8
    
    // Activity counter state (for non-timed activities)
    @State private var activityCount: Int = 1
    
    // Activity timer states (for tummy time and screen time)
    @State private var activityIsRunning = false
    @State private var activityStartTime: Date?
    @State private var activityElapsed: TimeInterval = 0
    @State private var activityTimer: Timer?
    @State private var selectedActivitySubType: ActivitySubType = .tummyTime
    
    // Sleep timer states
    @State private var sleepIsRunning = false
    @State private var sleepStartTime: Date?
    @State private var sleepElapsed: TimeInterval = 0
    @State private var sleepTimer: Timer?
    @State private var sleepHours = ""
    @State private var sleepMinutes = ""
    @State private var sleepSeconds = ""
    
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
        breastfeedingIsRunning || leftPumpingIsRunning || rightPumpingIsRunning || activityIsRunning || sleepIsRunning
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
            GeometryReader { geometry in
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Standard layout for all activities
                        // Ad Banner
                        AdBannerContainerWide()
                        
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
                    .frame(width: geometry.size.width)
                }
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
            } else if selectedActivityType == .sleep && sleepIsRunning {
                Button("Stop Sleep Timer") {
                    stopSleepTimer()
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
                
                if sleepIsRunning {
                    Button("Stop Sleep Timer") {
                        stopSleepTimer()
                        checkAndDismissIfNoTimers()
                    }
                }
            }
            
            Button("Exit but Keep Timers", role: .cancel) {
                dismiss()
            }
        } message: {
            if sleepIsRunning && selectedActivityType == .sleep {
                Text("You have a sleep timer running. Do you want to stop it or exit while keeping it running?")
            } else if breastfeedingIsRunning && selectedActivityType == .feeding {
                Text("You have a breastfeeding timer running. Do you want to stop it or exit while keeping it running?")
            } else if (leftPumpingIsRunning || rightPumpingIsRunning) && selectedActivityType == .pumping {
                Text("You have pumping timers running. Do you want to stop them or exit while keeping them running?")
            } else if activityIsRunning && selectedActivityType == .activity {
                Text("You have an activity timer running. Do you want to stop it or exit while keeping it running?")
            } else {
                Text("You have active timers running. Do you want to stop them or exit while keeping them running?")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            restoreBreastfeedingTimer()
            restorePumpingTimers()
            restoreSleepTimer()
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
                    restoreSleepTimer()
                    
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
                    } else if editingActivity.type == .sleep {
                        if sleepHours.isEmpty && sleepElapsed > 0 {
                            sleepHours = String(Int(sleepElapsed / 3600))
                        }
                        if sleepMinutes.isEmpty && sleepElapsed > 0 {
                            sleepMinutes = String(Int(sleepElapsed) % 3600 / 60)
                        }
                        if sleepSeconds.isEmpty && sleepElapsed > 0 {
                            sleepSeconds = String(Int(sleepElapsed) % 60)
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
                
                // Convert height from cm to total inches
                selectedHeightIn = editingGrowthEntry.height / 2.54 // Convert cm to inches
                selectedHeightCm = editingGrowthEntry.height // Already in cm
                
                selectedHeadCircumferenceCm = editingGrowthEntry.headCircumference
                selectedHeadCircumferenceIn = editingGrowthEntry.headCircumference / 2.54
            } else {
                // Only restore timers when not editing
                restoreBreastfeedingTimer()
                restorePumpingTimers()
                restoreSleepTimer()
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
            // Clean up timers when view disappears, but preserve paused timer state
            activityTimer?.invalidate()
            activityTimer = nil
            
            // For pumping timers, only clean up the Timer objects but preserve the state
            // This allows paused timers to maintain their elapsed time
            leftPumpingTimer?.invalidate()
            leftPumpingTimer = nil
            rightPumpingTimer?.invalidate()
            rightPumpingTimer = nil
            
            // Save paused timer states to UserDefaults for restoration
            savePumpingTimerStates()
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
                    Text(selectedActivityType.name)
                        .font(.headline)
                        .fontWeight(.semibold)
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
                    Text("Breastfeeding Timer")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 16) {
                        // Timer display - only show when not editing
                        if editingActivity == nil {
                            HStack {
                                Spacer()
                                Text(formatTime(breastfeedingElapsed))
                                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        
                        // Timer controls - only show when not editing
                        if editingActivity == nil {
                            HStack(spacing: 12) {
                                Spacer()
                                
                                // Start/Stop button
                                Button(action: {
                                    if breastfeedingIsRunning {
                                        stopBreastfeedingTimer()
                                    } else {
                                        startBreastfeedingTimer()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: breastfeedingIsRunning ? "pause.fill" : "play.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text(breastfeedingIsRunning ? "End Feed" : "Start Feed")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(breastfeedingIsRunning ? Color.red : Color.green)
                                    .cornerRadius(25)
                                }
                                
                                // Reset button
                                Button(action: resetBreastfeedingTimer) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Reset")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.orange)
                                    .cornerRadius(25)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        // Manual time entry - expanded in edit mode
                        VStack(spacing: editingActivity != nil ? 24 : 8) {
                            Text(editingActivity != nil ? "Enter feeding duration:" : "Or enter time manually:")
                                .font(editingActivity != nil ? .headline : .caption)
                                .fontWeight(editingActivity != nil ? .semibold : .regular)
                                .foregroundColor(editingActivity != nil ? .primary : .secondary)
                            
                            VStack(spacing: editingActivity != nil ? 20 : 12) {
                                HStack(spacing: editingActivity != nil ? 24 : 12) {
                                    VStack(spacing: editingActivity != nil ? 8 : 4) {
                                        Text("Minutes")
                                            .font(editingActivity != nil ? .subheadline : .caption2)
                                            .fontWeight(editingActivity != nil ? .semibold : .regular)
                                            .foregroundColor(.secondary)
                                        TextField("0", text: $breastfeedingMinutes)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.numberPad)
                                            .frame(width: editingActivity != nil ? 100 : 60)
                                            .disabled(breastfeedingIsRunning)
                                    }
                                    
                                    Text(":")
                                        .font(editingActivity != nil ? .largeTitle : .title2)
                                        .fontWeight(.bold)
                                    
                                    VStack(spacing: editingActivity != nil ? 8 : 4) {
                                        Text("Seconds")
                                            .font(editingActivity != nil ? .subheadline : .caption2)
                                            .fontWeight(editingActivity != nil ? .semibold : .regular)
                                            .foregroundColor(.secondary)
                                        TextField("0", text: $breastfeedingSeconds)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .keyboardType(.numberPad)
                                            .frame(width: editingActivity != nil ? 100 : 60)
                                            .disabled(breastfeedingIsRunning)
                                    }
                                }
                                
                                // Add some helpful text in edit mode
                                if editingActivity != nil {
                                    Text("Enter the total duration of the breastfeeding session")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 8)
                                }
                            }
                        }
                    }
                    .padding(editingActivity != nil ? 24 : 16)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: editingActivity != nil ? 200 : nil)
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
        VStack(alignment: .leading, spacing: 16) {
            // Timer Section (match pumping indentation)
            VStack(alignment: .leading, spacing: 12) {
                Text("Sleep Timer")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
                
                VStack(spacing: 16) {
                    // Timer display - only show when not editing
                    if editingActivity == nil {
                        HStack {
                            Spacer()
                            Text(formatSleepTime(sleepElapsed))
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    // Timer controls - only show when not editing
                    if editingActivity == nil {
                        HStack(spacing: 12) {
                            Spacer()
                            
                            // Start/Stop button
                            Button(action: {
                                if sleepIsRunning {
                                    stopSleepTimer()
                                } else {
                                    startSleepTimer()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: sleepIsRunning ? "pause.fill" : "play.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text(sleepIsRunning ? "End Sleep" : "Start Sleep")
                                        .fontWeight(.semibold)
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(sleepIsRunning ? Color.red : Color.green)
                                .cornerRadius(25)
                            }
                            
                            // Reset button
                            Button(action: resetSleepTimer) {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Reset")
                                        .fontWeight(.semibold)
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.orange)
                                .cornerRadius(25)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Manual time entry
                    VStack(spacing: 12) {
                        if editingActivity != nil {
                            Text("Sleep Duration")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        } else {
                            Text("Or enter time manually:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: editingActivity != nil ? 16 : 12) {
                            VStack(spacing: 6) {
                                Text(editingActivity != nil ? "H" : "Hours")
                                    .font(editingActivity != nil ? .subheadline : .caption2)
                                    .fontWeight(editingActivity != nil ? .semibold : .regular)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                TextField("0", text: $sleepHours)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: editingActivity != nil ? 90 : 60)
                                    .disabled(sleepIsRunning)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Text(":")
                                .font(editingActivity != nil ? .largeTitle : .title2)
                                .fontWeight(.bold)
                            
                            VStack(spacing: 6) {
                                Text(editingActivity != nil ? "M" : "Minutes")
                                    .font(editingActivity != nil ? .subheadline : .caption2)
                                    .fontWeight(editingActivity != nil ? .semibold : .regular)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                TextField("0", text: $sleepMinutes)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: editingActivity != nil ? 90 : 60)
                                    .disabled(sleepIsRunning)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Text(":")
                                .font(editingActivity != nil ? .largeTitle : .title2)
                                .fontWeight(.bold)
                            
                            VStack(spacing: 6) {
                                Text(editingActivity != nil ? "S" : "Seconds")
                                    .font(editingActivity != nil ? .subheadline : .caption2)
                                    .fontWeight(editingActivity != nil ? .semibold : .regular)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                TextField("0", text: $sleepSeconds)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: editingActivity != nil ? 90 : 60)
                                    .disabled(sleepIsRunning)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                .padding(.leading, 16)
            }
            
            // Quick Duration Buttons (match pumping indentation)
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Duration")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach([0.5, 1.0, 1.5, 2.0, 3.0, 4.0], id: \.self) { duration in
                        Button(action: {
                            sleepDuration = duration
                            sleepElapsed = duration * 3600 // Convert hours to seconds
                            sleepHours = String(Int(duration))
                            sleepMinutes = String(Int((duration - Double(Int(duration))) * 60))
                            sleepSeconds = "0"
                        }) {
                            Text("\(duration == floor(duration) ? String(format: "%.0f", duration) : String(format: "%.1f", duration))h")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(20)
                        }
                        .disabled(sleepIsRunning)
                    }
                }
                .padding(.leading, 16)
            }
            
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
                    set: { newValue in 
                        let wasMetric = dataManager.useMetricUnits
                        dataManager.useMetricUnits = !newValue
                        
                        // Convert values when switching units
                        if wasMetric && !dataManager.useMetricUnits {
                            // Converting from metric to imperial
                            selectedWeightLbs = selectedWeightKg * 2.20462
                            selectedHeightIn = selectedHeightCm / 2.54
                            selectedHeadCircumferenceIn = selectedHeadCircumferenceCm / 2.54
                        } else if !wasMetric && dataManager.useMetricUnits {
                            // Converting from imperial to metric
                            selectedWeightKg = selectedWeightLbs * 0.453592
                            selectedHeightCm = selectedHeightIn * 2.54
                            selectedHeadCircumferenceCm = selectedHeadCircumferenceIn * 2.54
                        }
                    }
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
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                    Text("Values pre-filled with your last recorded measurements. Adjust as needed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
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
                            Text("25 kg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $selectedWeightKg, in: 2...25, step: 0.1)
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
                            Text(String(format: "%.1f lbs", selectedWeightLbs))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("55 lbs")
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
                            Slider(value: $selectedWeightLbs, in: 4...55, step: 0.1)
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
                            Text("150 cm")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $selectedHeightCm, in: 30...150, step: 0.5)
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
                            Text("12\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f\"", selectedHeightIn))
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("59\"")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Inches")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            Slider(value: $selectedHeightIn, in: 12...59, step: 0.1)
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
            // Use timer data if available, otherwise fall back to slider
            if sleepElapsed > 0 || !sleepHours.isEmpty || !sleepMinutes.isEmpty || !sleepSeconds.isEmpty {
                let hours: Int
                let minutes: Int
                let seconds: Int
                
                // Prioritize manual input when editing or when we have manual values
                if !sleepHours.isEmpty || !sleepMinutes.isEmpty || !sleepSeconds.isEmpty {
                    hours = Int(sleepHours) ?? 0
                    minutes = Int(sleepMinutes) ?? 0
                    seconds = Int(sleepSeconds) ?? 0
                } else {
                    hours = Int(sleepElapsed / 3600)
                    minutes = Int(sleepElapsed) % 3600 / 60
                    seconds = Int(sleepElapsed) % 60
                }
                
                let totalSeconds = hours * 3600 + minutes * 60 + seconds
                let hoursDecimal = Double(totalSeconds) / 3600.0
                details = String(format: "Sleep - %dh %dm %ds (%.1f hours)", hours, minutes, seconds, hoursDecimal)
            } else {
                details = String(format: "Slept for %.1f hours", sleepDuration)
            }
        case .milestone:
            details = milestoneDescription.isEmpty ? milestoneTitle : "\(milestoneTitle) - \(milestoneDescription)"
        case .activity:
            if selectedActivitySubType == .tummyTime || selectedActivitySubType == .screenTime {
                // Timer-based activities include duration
                let minutes = Int(activityElapsed / 60)
                let seconds = Int(activityElapsed) % 60
                details = "\(selectedActivitySubType.name) - \(minutes)m \(seconds)s"
            } else {
                // Non-timer activities just use the activity name
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
                details = String(format: "Weight: %.1f lbs, Height: %.1f\", Head: %.1f\"", 
                               selectedWeightLbs, selectedHeightIn, selectedHeadCircumferenceIn)
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
            // Update live activity immediately
            dataManager.updateLiveActivity()
        } else if selectedActivityType == .pumping {
            // Stop and reset both pumping timers
            stopLeftPumping()
            stopRightPumping()
            resetLeftPumping()
            resetRightPumping()
            // Update live activity immediately
            dataManager.updateLiveActivity()
        } else if selectedActivityType == .sleep {
            resetSleepTimer()
            // Update live activity immediately
            dataManager.updateLiveActivity()
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
            
            // Show timer for tummy time and screen time, count for others
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
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
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
                        
                        // Reset button
                        Button(action: resetLeftPumping) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(8)
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
                        
                        // Reset button
                        Button(action: resetRightPumping) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reset")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(8)
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
        
        // Update live activity immediately
        dataManager.updateLiveActivity()
    }
    
    private func stopLeftPumping() {
        leftPumpingTimer?.invalidate()
        leftPumpingTimer = nil
        leftPumpingIsRunning = false
        
        // Clear background tracking
        UserDefaults.standard.removeObject(forKey: "leftPumpingStartTime")
        UserDefaults.standard.removeObject(forKey: "leftPumpingElapsed")
        UserDefaults.standard.set(false, forKey: "leftPumpingIsRunning")
        
        // Update live activity immediately
        dataManager.updateLiveActivity()
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
        
        // Update live activity immediately
        dataManager.updateLiveActivity()
    }
    
    private func stopRightPumping() {
        rightPumpingTimer?.invalidate()
        rightPumpingTimer = nil
        rightPumpingIsRunning = false
        
        // Clear background tracking
        UserDefaults.standard.removeObject(forKey: "rightPumpingStartTime")
        UserDefaults.standard.removeObject(forKey: "rightPumpingElapsed")
        UserDefaults.standard.set(false, forKey: "rightPumpingIsRunning")
        
        // Update live activity immediately
        dataManager.updateLiveActivity()
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
        
        // Stop sleep timer
        if sleepIsRunning {
            stopSleepTimer()
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
            // Parse sleep data - check for timer format first, then fallback to hours
            let originalDetails = activity.details // Use original case-sensitive details
            if originalDetails.contains("Sleep - ") {
                // New timer format: "Sleep - 2h 30m 45s (2.5 hours)"
                let timerPattern = #"Sleep - (\d+)h (\d+)m (\d+)s"#
                if let regex = try? NSRegularExpression(pattern: timerPattern),
                   let match = regex.firstMatch(in: originalDetails, range: NSRange(originalDetails.startIndex..., in: originalDetails)) {
                    
                    if let hoursRange = Range(match.range(at: 1), in: originalDetails),
                       let minutesRange = Range(match.range(at: 2), in: originalDetails),
                       let secondsRange = Range(match.range(at: 3), in: originalDetails) {
                        let hours = String(originalDetails[hoursRange])
                        let minutes = String(originalDetails[minutesRange])
                        let seconds = String(originalDetails[secondsRange])
                        sleepHours = hours
                        sleepMinutes = minutes
                        sleepSeconds = seconds
                        let totalSeconds = (Int(hours) ?? 0) * 3600 + (Int(minutes) ?? 0) * 60 + (Int(seconds) ?? 0)
                        sleepElapsed = TimeInterval(totalSeconds)
                    }
                } else {
                    // Fallback: try format without seconds "Sleep - 2h 30m (2.5 hours)"
                    let timerPatternNoSeconds = #"Sleep - (\d+)h (\d+)m"#
                    if let regex = try? NSRegularExpression(pattern: timerPatternNoSeconds),
                       let match = regex.firstMatch(in: originalDetails, range: NSRange(originalDetails.startIndex..., in: originalDetails)) {
                        
                        if let hoursRange = Range(match.range(at: 1), in: originalDetails),
                           let minutesRange = Range(match.range(at: 2), in: originalDetails) {
                            let hours = String(originalDetails[hoursRange])
                            let minutes = String(originalDetails[minutesRange])
                            sleepHours = hours
                            sleepMinutes = minutes
                            sleepSeconds = "0"
                            let totalSeconds = (Int(hours) ?? 0) * 3600 + (Int(minutes) ?? 0) * 60
                            sleepElapsed = TimeInterval(totalSeconds)
                        }
                    } else {
                        // Fallback: try old format "Sleep - 120m 30s" for backwards compatibility
                        let oldTimerPattern = #"Sleep - (\d+)m (\d+)s"#
                        if let regex = try? NSRegularExpression(pattern: oldTimerPattern),
                           let match = regex.firstMatch(in: originalDetails, range: NSRange(originalDetails.startIndex..., in: originalDetails)) {
                            
                            if let minutesRange = Range(match.range(at: 1), in: originalDetails),
                               let secondsRange = Range(match.range(at: 2), in: originalDetails) {
                                let totalMinutes = Int(String(originalDetails[minutesRange])) ?? 0
                                let seconds = Int(String(originalDetails[secondsRange])) ?? 0
                                sleepHours = String(totalMinutes / 60)
                                sleepMinutes = String(totalMinutes % 60)
                                sleepSeconds = String(seconds)
                                sleepElapsed = TimeInterval(totalMinutes * 60 + seconds)
                            }
                        }
                    }
                }
            } else {
                // Parse sleep duration from details like "Slept for 1.5 hours"
                let hourPattern = #"(\d+(?:\.\d+)?)\s*hours?"#
                if let regex = try? NSRegularExpression(pattern: hourPattern, options: .caseInsensitive),
                   let match = regex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
                   let range = Range(match.range(at: 1), in: details) {
                    sleepDuration = Double(String(details[range])) ?? 1.5
                }
            }
            
        case .activity:
            // Parse activity subtype first
            for subType in ActivitySubType.allCases {
                if details.contains(subType.name.lowercased()) {
                    selectedActivitySubType = subType
                    break
                }
            }
            
            // Parse timer data for tummy time/screen time or count for others
            if selectedActivitySubType == .tummyTime || selectedActivitySubType == .screenTime {
                // Parse timer data from details like "Tummy Time - 15m 30s"
                let timePattern = #"(\d+)m\s*(\d+)s"#
                if let regex = try? NSRegularExpression(pattern: timePattern),
                   let match = regex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
                   let minutesRange = Range(match.range(at: 1), in: details),
                   let secondsRange = Range(match.range(at: 2), in: details) {
                    let minutes = Int(String(details[minutesRange])) ?? 0
                    let seconds = Int(String(details[secondsRange])) ?? 0
                    activityElapsed = TimeInterval(minutes * 60 + seconds)
                }
            } else {
                // Non-timer activities don't need special parsing
                // Activity subtype is already set from the main loop above
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
                    selectedHeightIn = selectedHeightCm / 2.54
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
                let heightPattern = #"height:\s*([\d.]+)\""#
                let headPattern = #"head:\s*([\d.]+)\""#
                
                if let weightRegex = try? NSRegularExpression(pattern: weightPattern),
                   let match = weightRegex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
                   let range = Range(match.range(at: 1), in: details) {
                    selectedWeightLbs = Double(String(details[range])) ?? 0
                    selectedWeightKg = selectedWeightLbs * 0.453592
                }
                
                if let heightRegex = try? NSRegularExpression(pattern: heightPattern),
                   let match = heightRegex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
                   let range = Range(match.range(at: 1), in: details) {
                    selectedHeightIn = Double(String(details[range])) ?? 0
                    selectedHeightCm = selectedHeightIn * 2.54
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
        
        selectedHeightIn = lastEntry.height / 2.54  // Convert cm to total inches
        selectedHeightCm = lastEntry.height
        
        selectedHeadCircumferenceCm = lastEntry.headCircumference
        selectedHeadCircumferenceIn = lastEntry.headCircumference / 2.54
        
        // Set flag to show prepopulation message
        growthValuesPrepopulated = true
    }
    
    private func getDuration() -> Int? {
        switch selectedActivityType {
        case .sleep:
            // Use timer data if available, otherwise fall back to slider
            if sleepElapsed > 0 || !sleepHours.isEmpty || !sleepMinutes.isEmpty || !sleepSeconds.isEmpty {
                let hours: Int
                let minutes: Int
                let seconds: Int
                
                if (editingActivity != nil || (!sleepIsRunning && sleepElapsed > 0)) && (!sleepHours.isEmpty || !sleepMinutes.isEmpty || !sleepSeconds.isEmpty) {
                    hours = Int(sleepHours) ?? 0
                    minutes = Int(sleepMinutes) ?? 0
                    seconds = Int(sleepSeconds) ?? 0
                } else {
                    hours = Int(sleepElapsed / 3600)
                    minutes = Int(sleepElapsed) % 3600 / 60
                    seconds = Int(sleepElapsed) % 60
                }
                
                let totalMinutes = hours * 60 + minutes + (seconds > 0 ? 1 : 0) // Round up if there are seconds
                return totalMinutes
            } else {
                return Int(sleepDuration * 60) // Convert hours to minutes
            }
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
            return dataManager.convertWeightToKg(selectedWeightLbs, fromImperial: true)
        }
    }
    
    private func getHeight() -> Double {
        if dataManager.useMetricUnits {
            return selectedHeightCm
        } else {
            // Convert imperial to cm for storage
            return dataManager.convertHeightToCm(selectedHeightIn, fromImperial: true)
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
        
        // Update live activity immediately
        dataManager.updateLiveActivity()
    }
    
    private func stopBreastfeedingTimer() {
        breastfeedingTimer?.invalidate()
        breastfeedingTimer = nil
        breastfeedingIsRunning = false
        
        // Clear background tracking
        UserDefaults.standard.removeObject(forKey: "breastfeedingStartTime")
        UserDefaults.standard.removeObject(forKey: "breastfeedingElapsed")
        UserDefaults.standard.set(false, forKey: "breastfeedingIsRunning")
        
        // Update live activity immediately
        dataManager.updateLiveActivity()
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
    
    private func formatSleepTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - Sleep Timer Functions
    
    private func startSleepTimer() {
        // If we have edited values in text fields, use them as the starting point
        if !sleepHours.isEmpty || !sleepMinutes.isEmpty || !sleepSeconds.isEmpty {
            let hours = Int(sleepHours) ?? 0
            let minutes = Int(sleepMinutes) ?? 0
            let seconds = Int(sleepSeconds) ?? 0
            sleepElapsed = TimeInterval(hours * 3600 + minutes * 60 + seconds)
        }
        
        // Always calculate start time based on current elapsed time (for resume functionality)
        sleepStartTime = Date().addingTimeInterval(-sleepElapsed)
        
        sleepIsRunning = true
        
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateSleepElapsed()
        }
        
        // Store start time for background tracking
        UserDefaults.standard.set(sleepStartTime, forKey: "sleepStartTime")
        UserDefaults.standard.set(sleepElapsed, forKey: "sleepElapsed")
        UserDefaults.standard.set(true, forKey: "sleepIsRunning")
        
        // Update live activity immediately
        dataManager.updateLiveActivity()
    }
    
    private func stopSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        sleepIsRunning = false
        
        // Clear background tracking - ensure proper cleanup
        UserDefaults.standard.removeObject(forKey: "sleepStartTime")
        UserDefaults.standard.removeObject(forKey: "sleepElapsed")
        UserDefaults.standard.set(false, forKey: "sleepIsRunning")
        
        // Force synchronization to ensure UserDefaults are written immediately
        UserDefaults.standard.synchronize()
        
        // Update live activity immediately
        dataManager.updateLiveActivity()
    }
    
    private func resetSleepTimer() {
        stopSleepTimer()
        sleepElapsed = 0
        sleepStartTime = nil
        sleepHours = ""
        sleepMinutes = ""
        sleepSeconds = ""
        
        // Ensure all UserDefaults are properly cleared
        UserDefaults.standard.removeObject(forKey: "sleepStartTime")
        UserDefaults.standard.removeObject(forKey: "sleepElapsed")
        UserDefaults.standard.set(false, forKey: "sleepIsRunning")
        UserDefaults.standard.synchronize()
    }
    
    private func updateSleepElapsed() {
        guard let startTime = sleepStartTime else { return }
        sleepElapsed = Date().timeIntervalSince(startTime)
        
        // Update stored elapsed time for background tracking
        UserDefaults.standard.set(sleepElapsed, forKey: "sleepElapsed")
    }
    
    private func restoreSleepTimer() {
        // Double-check UserDefaults to avoid race conditions
        UserDefaults.standard.synchronize()
        let isRunning = UserDefaults.standard.bool(forKey: "sleepIsRunning")
        
        // Only restore if we're not already running a timer
        guard !sleepIsRunning else { return }
        
        if isRunning {
            if let startTime = UserDefaults.standard.object(forKey: "sleepStartTime") as? Date {
                sleepStartTime = startTime
                sleepElapsed = Date().timeIntervalSince(startTime)
                sleepIsRunning = true
                
                sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    updateSleepElapsed()
                }
            }
        } else {
            // Restore any saved elapsed time even if not running
            sleepElapsed = UserDefaults.standard.double(forKey: "sleepElapsed")
            
            if sleepElapsed > 0 {
                let hours = Int(sleepElapsed) / 3600
                let minutes = Int(sleepElapsed) % 3600 / 60
                let seconds = Int(sleepElapsed) % 60
                sleepHours = String(hours)
                sleepMinutes = String(minutes)
                sleepSeconds = String(seconds)
            }
        }
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
    
    private func savePumpingTimerStates() {
        // Save left pumping state (whether running or paused)
        UserDefaults.standard.set(leftPumpingElapsed, forKey: "leftPumpingElapsed_saved")
        UserDefaults.standard.set(leftPumpingIsRunning, forKey: "leftPumpingIsRunning_saved")
        if let startTime = leftPumpingStartTime {
            UserDefaults.standard.set(startTime, forKey: "leftPumpingStartTime_saved")
        }
        
        // Save right pumping state (whether running or paused)
        UserDefaults.standard.set(rightPumpingElapsed, forKey: "rightPumpingElapsed_saved")
        UserDefaults.standard.set(rightPumpingIsRunning, forKey: "rightPumpingIsRunning_saved")
        if let startTime = rightPumpingStartTime {
            UserDefaults.standard.set(startTime, forKey: "rightPumpingStartTime_saved")
        }
    }
    
    private func restorePumpingTimers() {
        // First try to restore from saved states (paused or running)
        restoreFromSavedStates()
        
        // Then try to restore from active background timers (only for running timers)
        restoreFromBackgroundTimers()
    }
    
    private func restoreFromSavedStates() {
        // Restore left pumping timer from saved state
        if UserDefaults.standard.object(forKey: "leftPumpingElapsed_saved") != nil {
            leftPumpingElapsed = UserDefaults.standard.double(forKey: "leftPumpingElapsed_saved")
            let wasRunning = UserDefaults.standard.bool(forKey: "leftPumpingIsRunning_saved")
            
            if let savedStartTime = UserDefaults.standard.object(forKey: "leftPumpingStartTime_saved") as? Date {
                leftPumpingStartTime = savedStartTime
            }
            
            // Only restart timer if it was running when saved
            if wasRunning {
                leftPumpingIsRunning = true
                leftPumpingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    updateLeftPumpingElapsed()
                }
            } else {
                leftPumpingIsRunning = false
            }
            
            // Clear saved state
            UserDefaults.standard.removeObject(forKey: "leftPumpingElapsed_saved")
            UserDefaults.standard.removeObject(forKey: "leftPumpingIsRunning_saved")
            UserDefaults.standard.removeObject(forKey: "leftPumpingStartTime_saved")
        }
        
        // Restore right pumping timer from saved state
        if UserDefaults.standard.object(forKey: "rightPumpingElapsed_saved") != nil {
            rightPumpingElapsed = UserDefaults.standard.double(forKey: "rightPumpingElapsed_saved")
            let wasRunning = UserDefaults.standard.bool(forKey: "rightPumpingIsRunning_saved")
            
            if let savedStartTime = UserDefaults.standard.object(forKey: "rightPumpingStartTime_saved") as? Date {
                rightPumpingStartTime = savedStartTime
            }
            
            // Only restart timer if it was running when saved
            if wasRunning {
                rightPumpingIsRunning = true
                rightPumpingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    updateRightPumpingElapsed()
                }
            } else {
                rightPumpingIsRunning = false
            }
            
            // Clear saved state
            UserDefaults.standard.removeObject(forKey: "rightPumpingElapsed_saved")
            UserDefaults.standard.removeObject(forKey: "rightPumpingIsRunning_saved")
            UserDefaults.standard.removeObject(forKey: "rightPumpingStartTime_saved")
        }
    }
    
    private func restoreFromBackgroundTimers() {
        // Restore left pumping timer from background (only if not already restored from saved state)
        if leftPumpingElapsed == 0 && UserDefaults.standard.bool(forKey: "leftPumpingIsRunning"),
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
        
        // Restore right pumping timer from background (only if not already restored from saved state)
        if rightPumpingElapsed == 0 && UserDefaults.standard.bool(forKey: "rightPumpingIsRunning"),
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
