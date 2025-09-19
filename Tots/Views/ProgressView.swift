import SwiftUI


struct ProgressView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var selectedTimeframe: TimeFrame = .thisWeek
    
    enum TimeFrame: String, CaseIterable {
        case thisWeek = "This Week"
        case lastWeek = "Last Week"
        case thisMonth = "This Month"
        
        var days: Int {
            switch self {
            case .thisWeek, .lastWeek: return 7
            case .thisMonth: return 30
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
                        // Time frame selector
                        timeFrameSelectorView
                        
                        // Key stats
                        keyStatsView
                        
                        // Weekly overview
                        weeklyOverviewView
                        
                        // Milestones
                        milestonesView
                        
                        // Growth tracking
                        growthView
                    }
                    .padding()
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var timeFrameSelectorView: some View {
        HStack(spacing: 12) {
            ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                Button(action: {
                    selectedTimeframe = timeframe
                }) {
                    Text(timeframe.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTimeframe == timeframe ? Color.blue : Color(.systemGray6))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var keyStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ProgressStatCard(
                    title: "Total Activities",
                    value: "\(dataManager.totalActivitiesLogged)",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                ProgressStatCard(
                    title: "Streak",
                    value: "\(dataManager.streakCount) days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                ProgressStatCard(
                    title: "Milestones",
                    value: "\(getMilestoneProgress())/\(dataManager.milestones.count)",
                    icon: "star.fill",
                    color: .purple
                )
                
                ProgressStatCard(
                    title: "Development",
                    value: "\(dataManager.developmentScore)%",
                    icon: "brain.head.profile",
                    color: .green
                )
            }
        }
    }
    
    private var weeklyOverviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                WeeklyBarChart(
                    title: "Feedings per Day",
                    data: dataManager.weeklyData.map { Double($0.feedings) },
                    color: .pink,
                    maxValue: 10
                )
                
                WeeklyBarChart(
                    title: "Sleep Hours per Day",
                    data: dataManager.weeklyData.map { $0.sleepHours },
                    color: .indigo,
                    maxValue: 16
                )
                
                WeeklyBarChart(
                    title: "Diaper Changes per Day",
                    data: dataManager.weeklyData.map { Double($0.diapers) },
                    color: .orange,
                    maxValue: 8
                )
            }
        }
    }
    
    private var milestonesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Milestones")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(getMilestoneProgress()) of \(dataManager.milestones.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(dataManager.milestones.prefix(5)) { milestone in
                    MilestoneRow(milestone: milestone)
                }
            }
            
            if dataManager.milestones.count > 5 {
                Button("View All Milestones") {
                    // Navigate to full milestone list
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
    }
    
    private var growthView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Growth")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Unit toggle
                HStack(spacing: 8) {
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
                    
                    Text("in/lb")
                        .font(.caption)
                        .fontWeight(!dataManager.useMetricUnits ? .semibold : .regular)
                        .foregroundColor(!dataManager.useMetricUnits ? .blue : .secondary)
                }
            }
            
            HStack(spacing: 16) {
                GrowthCard(
                    title: "Weight",
                    value: dataManager.formatWeight(dataManager.currentWeight),
                    subtitle: "75th percentile",
                    color: .green
                )
                
                GrowthCard(
                    title: "Height",
                    value: dataManager.formatHeight(dataManager.growthData.last?.height ?? 68.5),
                    subtitle: "82nd percentile",
                    color: .blue
                )
            }
        }
    }
    
    private func getMilestoneProgress() -> Int {
        return dataManager.milestones.filter { $0.isCompleted }.count
    }
}

// MARK: - Supporting Views

struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WeeklyBarChart: View {
    let title: String
    let data: [Double]
    let color: Color
    let maxValue: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(color)
                            .frame(width: 30, height: max(4, (value / maxValue) * 80))
                            .cornerRadius(2)
                        
                        Text(getDayLabel(for: index))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getDayLabel(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[safe: index] ?? ""
    }
}

struct MilestoneRow: View {
    let milestone: Milestone
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: milestone.category.icon)
                .foregroundColor(milestone.category.color)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(milestone.expectedAge)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if milestone.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 2)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.vertical, 4)
    }
}

struct GrowthCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ProgressView()
        .environmentObject(TotsDataManager())
}