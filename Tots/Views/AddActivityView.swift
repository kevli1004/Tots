import SwiftUI


struct AddActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var selectedActivityType: ActivityType = .feeding
    
    let preselectedType: ActivityType?
    let editingActivity: TotsActivity?
    let editingGrowthEntry: GrowthEntry?
    
    init(preselectedType: ActivityType? = nil, editingActivity: TotsActivity? = nil, editingGrowthEntry: GrowthEntry? = nil) {
        self.preselectedType = preselectedType
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
    
    @State private var rightPumpingIsRunning = false
    @State private var rightPumpingStartTime: Date?
    @State private var rightPumpingElapsed: TimeInterval = 0
    @State private var rightPumpingTimer: Timer?
    @State private var showingDeleteConfirmation = false
    
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
        let isEditing = editingActivity != nil || editingGrowthEntry != nil
        return isEditing ? "Edit \(selectedActivityType.name)" : "Add \(selectedActivityType.name)"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
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
                        dismiss()
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
        .onAppear {
            if let editingActivity = editingActivity {
                // Populate fields for editing
                selectedActivityType = editingActivity.type
                activityTime = editingActivity.time
                notes = editingActivity.notes ?? ""
                
                // Parse activity-specific data from details
                parseActivityDetails(editingActivity)
            } else if let editingGrowthEntry = editingGrowthEntry {
                // Populate fields for editing growth entry
                selectedActivityType = .growth
                activityTime = editingGrowthEntry.date
                
                // Populate growth-specific fields
                selectedWeightLbs = editingGrowthEntry.weight
                selectedWeightKg = editingGrowthEntry.weight * 0.453592
                
                // Convert height to feet and inches
                let totalInches = editingGrowthEntry.height
                selectedHeightFt = Int(totalInches / 12)
                selectedHeightIn = totalInches.truncatingRemainder(dividingBy: 12)
                selectedHeightCm = editingGrowthEntry.height * 2.54
                
                selectedHeadCircumferenceCm = editingGrowthEntry.headCircumference
                selectedHeadCircumferenceIn = editingGrowthEntry.headCircumference / 2.54
            } else if let preselectedType = preselectedType {
                selectedActivityType = preselectedType
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
    
    private var growthDetailsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Unit toggle
            HStack {
                Text("Units")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("kg/cm")
                        .font(.caption)
                        .fontWeight(dataManager.useMetricUnits ? .semibold : .regular)
                        .foregroundColor(dataManager.useMetricUnits ? .blue : .secondary)
                    
                    Toggle("", isOn: Binding(
                        get: { !dataManager.useMetricUnits },
                        set: { dataManager.useMetricUnits = !$0 }
                    ))
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .scaleEffect(0.8)
                    
                    Text("lb/in")
                        .font(.caption)
                        .fontWeight(!dataManager.useMetricUnits ? .semibold : .regular)
                        .foregroundColor(!dataManager.useMetricUnits ? .blue : .secondary)
                }
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
            let leftMinutes = Int(leftPumpingElapsed / 60)
            let leftSeconds = Int(leftPumpingElapsed) % 60
            let rightMinutes = Int(rightPumpingElapsed / 60)
            let rightSeconds = Int(rightPumpingElapsed) % 60
            let totalMinutes = Int((leftPumpingElapsed + rightPumpingElapsed) / 60)
            let totalSeconds = Int(leftPumpingElapsed + rightPumpingElapsed) % 60
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
            Text("Pumping Session")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                // Left breast timer
                VStack(spacing: 16) {
                    Text("Left Breast")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        Text(formatElapsedTime(leftPumpingElapsed))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(leftPumpingIsRunning ? .cyan : .primary)
                        
                        Text(leftPumpingIsRunning ? "Running" : "Stopped")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Left timer controls
                    VStack(spacing: 8) {
                        if leftPumpingIsRunning {
                            Button(action: stopLeftPumping) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                    Text("Stop")
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
                                    Text("Start")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.cyan)
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
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Right breast timer
                VStack(spacing: 16) {
                    Text("Right Breast")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        Text(formatElapsedTime(rightPumpingElapsed))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(rightPumpingIsRunning ? .cyan : .primary)
                        
                        Text(rightPumpingIsRunning ? "Running" : "Stopped")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Right timer controls
                    VStack(spacing: 8) {
                        if rightPumpingIsRunning {
                            Button(action: stopRightPumping) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                    Text("Stop")
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
                                    Text("Start")
                                }
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.cyan)
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
                
                Text(formatElapsedTime(leftPumpingElapsed + rightPumpingElapsed))
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
        leftPumpingStartTime = Date()
        leftPumpingIsRunning = true
        
        leftPumpingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let startTime = leftPumpingStartTime {
                leftPumpingElapsed = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopLeftPumping() {
        leftPumpingIsRunning = false
        leftPumpingTimer?.invalidate()
        leftPumpingTimer = nil
    }
    
    private func resetLeftPumping() {
        leftPumpingElapsed = 0
        leftPumpingStartTime = nil
    }
    
    private func startRightPumping() {
        rightPumpingStartTime = Date()
        rightPumpingIsRunning = true
        
        rightPumpingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let startTime = rightPumpingStartTime {
                rightPumpingElapsed = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopRightPumping() {
        rightPumpingIsRunning = false
        rightPumpingTimer?.invalidate()
        rightPumpingTimer = nil
    }
    
    private func resetRightPumping() {
        rightPumpingElapsed = 0
        rightPumpingStartTime = nil
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
            if let duration = activity.duration {
                // For now, split the total duration evenly between left and right
                // In a real implementation, you'd parse the individual times
                let totalSeconds = TimeInterval(duration * 60)
                leftPumpingElapsed = totalSeconds / 2
                rightPumpingElapsed = totalSeconds / 2
            }
            
        default:
            break
        }
    }
    
    private func getDuration() -> Int? {
        switch selectedActivityType {
        case .sleep:
            return Int(sleepDuration * 60) // Convert hours to minutes
        case .feeding:
            return feedingType == .breastfeeding ? 15 : nil
        case .activity:
            // Only return duration for activities that use timers
            if selectedActivitySubType == .tummyTime || selectedActivitySubType == .screenTime {
                return Int(activityElapsed / 60) // Convert seconds to minutes
            } else {
                return nil // Quick log activities don't have duration
            }
        case .pumping:
            return Int((leftPumpingElapsed + rightPumpingElapsed) / 60) // Convert seconds to minutes
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
}

#Preview {
    AddActivityView()
        .environmentObject(TotsDataManager())
}