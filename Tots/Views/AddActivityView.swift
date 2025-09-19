import SwiftUI


struct AddActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var selectedActivityType: ActivityType = .feeding
    
    let preselectedType: ActivityType?
    let editingActivity: TotsActivity?
    
    init(preselectedType: ActivityType? = nil, editingActivity: TotsActivity? = nil) {
        self.preselectedType = preselectedType
        self.editingActivity = editingActivity
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
    @State private var selectedHeightFt: Int = 1
    @State private var selectedHeightIn: Double = 8.0
    
    // Tummy time stopwatch states
    @State private var tummyTimeIsRunning = false
    @State private var tummyTimeStartTime: Date?
    @State private var tummyTimeElapsed: TimeInterval = 0
    @State private var tummyTimeTimer: Timer?
    
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
                .navigationTitle(editingActivity != nil ? "Edit \(selectedActivityType.name)" : "Add \(selectedActivityType.name)")
                .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let editingActivity = editingActivity {
                // Populate fields for editing
                selectedActivityType = editingActivity.type
                activityTime = editingActivity.time
                notes = editingActivity.notes ?? ""
                
                // Parse activity-specific data from details
                parseActivityDetails(editingActivity)
            } else if let preselectedType = preselectedType {
                selectedActivityType = preselectedType
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            tummyTimeTimer?.invalidate()
            tummyTimeTimer = nil
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
        case .play:
            tummyTimeDetailsView
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
            // Weight slider
            VStack(alignment: .leading, spacing: 12) {
                Text("Weight")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
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
            
            // Height slider
            VStack(alignment: .leading, spacing: 12) {
                Text("Height")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
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
            Text("Save Activity")
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
        case .play:
            let minutes = Int(tummyTimeElapsed / 60)
            let seconds = Int(tummyTimeElapsed) % 60
            details = "Tummy time - \(minutes)m \(seconds)s"
        case .growth:
            let totalWeightLbs = selectedWeightLbs + (selectedWeightOz / 16.0)
            let totalHeightInches = Double(selectedHeightFt * 12) + selectedHeightIn
            details = String(format: "Weight: %.1f lbs, Height: %d'%.1f\"", 
                           totalWeightLbs, selectedHeightFt, selectedHeightIn)
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
                weight: selectedActivityType == .growth ? selectedWeightLbs + (selectedWeightOz / 16.0) : nil,
                height: selectedActivityType == .growth ? Double(selectedHeightFt * 12) + selectedHeightIn : nil
            ))
        } else {
            // Create new activity
            let activity = TotsActivity(
                type: selectedActivityType,
                time: activityTime,
                details: details,
                mood: .content,
                duration: getDuration(),
                notes: notes.isEmpty ? nil : notes,
                weight: selectedActivityType == .growth ? selectedWeightLbs + (selectedWeightOz / 16.0) : nil,
                height: selectedActivityType == .growth ? Double(selectedHeightFt * 12) + selectedHeightIn : nil
            )
            
            dataManager.addActivity(activity)
        }
        
        dismiss()
    }
    
    private var tummyTimeDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tummy Time")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                // Stopwatch display
                VStack(spacing: 8) {
                    Text(formatElapsedTime(tummyTimeElapsed))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(tummyTimeIsRunning ? .green : .primary)
                    
                    Text(tummyTimeIsRunning ? "Timer Running" : "Timer Stopped")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Start/Stop button (only show one at a time)
                if tummyTimeIsRunning {
                    Button(action: stopTummyTime) {
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
                    Button(action: startTummyTime) {
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
                Button(action: resetTummyTime) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .disabled(tummyTimeIsRunning)
            }
            .padding()
            .liquidGlassCard()
        }
    }
    
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startTummyTime() {
        tummyTimeIsRunning = true
        tummyTimeStartTime = Date()
        
        tummyTimeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let startTime = tummyTimeStartTime {
                tummyTimeElapsed = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopTummyTime() {
        tummyTimeIsRunning = false
        tummyTimeTimer?.invalidate()
        tummyTimeTimer = nil
    }
    
    private func resetTummyTime() {
        tummyTimeElapsed = 0
        tummyTimeStartTime = nil
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
            
        case .play:
            // Parse tummy time duration from details like "Tummy time - 15m 30s"
            if let duration = activity.duration {
                tummyTimeElapsed = TimeInterval(duration * 60) // Convert minutes to seconds
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
        case .play:
            return Int(tummyTimeElapsed / 60) // Convert seconds to minutes
        default:
            return nil
        }
    }
}

#Preview {
    AddActivityView()
        .environmentObject(TotsDataManager())
}