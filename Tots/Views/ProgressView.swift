import SwiftUI
import Charts


struct ProgressView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var showingAddGrowth = false
    @State private var editingGrowthEntry: GrowthEntry? = nil
    @State private var showAllHistory = false
    
    // Chart data computed properties
    private var weightChartData: [ChartDataPoint] {
        dataManager.growthData.map { entry in
            let monthsSinceBirth = Calendar.current.dateComponents([.month], from: dataManager.babyBirthDate, to: entry.date).month ?? 0
            let weight = dataManager.useMetricUnits ? entry.weight : entry.weight * 2.20462
            return ChartDataPoint(month: monthsSinceBirth, value: weight, date: entry.date)
        }.filter { $0.value > 0 }.sorted { $0.month < $1.month }
    }
    
    private var heightChartData: [ChartDataPoint] {
        dataManager.growthData.map { entry in
            let monthsSinceBirth = Calendar.current.dateComponents([.month], from: dataManager.babyBirthDate, to: entry.date).month ?? 0
            let height = dataManager.useMetricUnits ? entry.height : entry.height * 0.393701
            return ChartDataPoint(month: monthsSinceBirth, value: height, date: entry.date)
        }.filter { $0.value > 0 }.sorted { $0.month < $1.month }
    }
    
    private var headCircumferenceChartData: [ChartDataPoint] {
        dataManager.growthData.map { entry in
            let monthsSinceBirth = Calendar.current.dateComponents([.month], from: dataManager.babyBirthDate, to: entry.date).month ?? 0
            let headCircumference = dataManager.useMetricUnits ? entry.headCircumference : entry.headCircumference * 0.393701
            return ChartDataPoint(month: monthsSinceBirth, value: headCircumference, date: entry.date)
        }.filter { $0.value > 0 }.sorted { $0.month < $1.month }
    }
    
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Unit toggle at top
                        unitToggleRow
                        
                        // Growth overview cards
                        growthOverviewCards
                        
                        // Growth charts with tabs
                        growthTabView
                        
                        // History section
                        growthHistorySection
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    growthTitleView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Plus button always creates new entry
                        editingGrowthEntry = nil
                        showingAddGrowth = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(.regularMaterial)
                                .frame(width: 40, height: 40)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGrowth) {
            AddActivityView(preselectedType: .growth, editingActivity: nil, editingGrowthEntry: nil)
                .environmentObject(dataManager)
                }
        .sheet(item: $editingGrowthEntry) { entry in
            AddActivityView(preselectedType: .growth, editingActivity: nil, editingGrowthEntry: entry)
                .environmentObject(dataManager)
        }
    }
    
    private var growthTitleView: some View {
        VStack(spacing: 2) {
            Text("Growth Tracking")
                .font(.title2)
                .fontWeight(.bold)
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
            
    private var growthOverviewCards: some View {
        VStack(alignment: .leading, spacing: 16) {
            if dataManager.growthData.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    VStack(spacing: 8) {
                        Text("No Growth Data")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text("Start tracking your baby's growth to see charts and percentiles")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    }
                    
                    Button("Add Measurement") {
                        editingGrowthEntry = nil
                        showingAddGrowth = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
                .padding(.vertical, 60)
            } else {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        GrowthCard(
                            title: "Weight",
                            value: dataManager.formatWeight(dataManager.currentWeight),
                            subtitle: "\(dataManager.getWeightPercentile())th percentile",
                            color: .green,
                            onTap: {
                                if let latestEntry = dataManager.growthData.first {
                                    editingGrowthEntry = latestEntry
                                }
                            }
                        )
                        
                        GrowthCard(
                            title: "Height",
                            value: dataManager.formatHeight(dataManager.currentHeight),
                            subtitle: "\(dataManager.getHeightPercentile())th percentile",
                            color: .blue,
                            onTap: {
                                if let latestEntry = dataManager.growthData.first {
                                    editingGrowthEntry = latestEntry
                                }
                            }
                        )
                    }
                    
                    HStack(spacing: 16) {
                        GrowthCard(
                            title: "BMI",
                            value: String(format: "%.1f", dataManager.currentBMI),
                            subtitle: "\(dataManager.getBMIPercentile())th percentile for age",
                            color: .purple,
                            onTap: {
                                if let latestEntry = dataManager.growthData.first {
                                    editingGrowthEntry = latestEntry
                                }
                            }
                        )
                        
                        GrowthCard(
                            title: "Head Circumference",
                            value: dataManager.formatHeadCircumference(dataManager.currentHeadCircumference),
                            subtitle: "Latest measurement",
                            color: .orange,
                            onTap: {
                                if let latestEntry = dataManager.growthData.first {
                                    editingGrowthEntry = latestEntry
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var growthTabView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Growth Charts")
                        .font(.headline)
                        .fontWeight(.semibold)
            
            // Show all charts stacked vertically
            VStack(spacing: 16) {
                weightChartContent
                heightChartContent
                headCircumferenceChartContent
            }
        }
    }
    
    private var weightChartContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight Over Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            if dataManager.growthData.count > 0 {
                GrowthPercentileChart(
                    data: weightChartData,
                    percentiles: [],
                        color: .blue,
                    unitLabel: dataManager.useMetricUnits ? "kg" : "lbs",
                    title: "Weight",
                    useMetricUnits: dataManager.useMetricUnits
                )
            } else {
                EmptyStateView(
                    icon: "scalemass",
                    title: "Need More Data",
                    message: "Add weight measurements to see the growth chart"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
    
    private var heightChartContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Height Over Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            if dataManager.growthData.count > 0 {
                GrowthPercentileChart(
                    data: heightChartData,
                    percentiles: [],
                    color: .green,
                    unitLabel: dataManager.useMetricUnits ? "cm" : "in",
                    title: "Height",
                        useMetricUnits: dataManager.useMetricUnits
                    )
            } else {
                EmptyStateView(
                    icon: "ruler",
                    title: "Need More Data",
                    message: "Add height measurements to see the growth chart"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
    
    
    private var headCircumferenceChartContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Head Circumference Over Time")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
            if dataManager.growthData.count > 0 {
                GrowthPercentileChart(
                    data: headCircumferenceChartData,
                    percentiles: [],
                    color: .purple,
                    unitLabel: dataManager.useMetricUnits ? "cm" : "in",
                    title: "Head Circumference",
                    useMetricUnits: dataManager.useMetricUnits
                )
            } else {
                EmptyStateView(
                    icon: "head.profile.arrow.right",
                    title: "Need More Data",
                    message: "Add head circumference measurements to see the growth chart"
                )
            }
        }
        .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                )
            }
            
    private var growthHistorySection: some View {
                VStack(alignment: .leading, spacing: 16) {
            if dataManager.growthData.count > 1 {
                    HStack {
                        Text("Growth History")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if dataManager.growthData.count > 5 {
                            Button(showAllHistory ? "Show Less" : "Show All") {
                                showAllHistory.toggle()
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        let sortedGrowthData = dataManager.growthData.sorted { $0.date > $1.date }
                        let displayedEntries = showAllHistory ? sortedGrowthData : Array(sortedGrowthData.prefix(5))
                        
                        ForEach(Array(displayedEntries.enumerated()), id: \.offset) { index, entry in
                            GrowthHistoryRow(
                                entry: entry,
                                useMetricUnits: dataManager.useMetricUnits,
                                onTap: {
                                    editingGrowthEntry = entry
                                },
                                onDelete: {
                                    deleteGrowthEntry(entry)
                                }
                            )
                        }
                        
                        if !showAllHistory && sortedGrowthData.count > 5 {
                            Text("+ \(sortedGrowthData.count - 5) more entries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                    }
                }
            }
        }
    }
    
    private func deleteGrowthEntry(_ entry: GrowthEntry) {
        // Find and delete the corresponding activity for this growth entry
        if let correspondingActivity = dataManager.recentActivities.first(where: { 
            $0.type == .growth && 
            Calendar.current.isDate($0.time, equalTo: entry.date, toGranularity: .minute)
        }) {
            dataManager.deleteActivity(correspondingActivity)
        }
    }
}

// MARK: - Supporting Views

struct GrowthCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: getIconForTitle(title))
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getIconForTitle(_ title: String) -> String {
        switch title {
        case "Weight": return "scalemass.fill"
        case "Height": return "ruler.fill"
        case "BMI": return "chart.bar.fill"
        case "Head Circumference": return "circle.dotted"
        default: return "chart.bar.fill"
        }
    }
}



struct GrowthHistoryRow: View {
    let entry: GrowthEntry
    let useMetricUnits: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Date
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatDate(entry.date))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(timeAgo(from: entry.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Values
                    VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 16) {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("Weight")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        Text(formatWeight(entry.weight))
                            .font(.subheadline)
                            .fontWeight(.medium)
                                .foregroundColor(.primary)
                    }
                    
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("Height")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        Text(formatHeight(entry.height))
                            .font(.subheadline)
                            .fontWeight(.medium)
                                .foregroundColor(.primary)
                    }
                    
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("Head")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        Text(formatHeadCircumference(entry.headCircumference))
                            .font(.subheadline)
                            .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func timeAgo(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 3600 { // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes) min ago"
        } else if timeInterval < 86400 { // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return "\(hours) hr ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
    
    private func formatWeight(_ weight: Double) -> String {
        if useMetricUnits {
            let kg = weight * 0.453592
            return String(format: "%.1f kg", kg)
        } else {
            return String(format: "%.1f lbs", weight)
        }
    }
    
    private func formatHeight(_ height: Double) -> String {
        if useMetricUnits {
            let cm = height * 2.54
            return String(format: "%.1f cm", cm)
        } else {
            return String(format: "%.1f\"", height)
        }
    }
    
    private func formatHeadCircumference(_ headCircumference: Double) -> String {
        if useMetricUnits {
            let cm = headCircumference * 2.54
            return String(format: "%.1f cm", cm)
        } else {
            return String(format: "%.1f\"", headCircumference)
        }
    }
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Supporting Types

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let month: Int
    let value: Double
    let date: Date
}

struct PercentileCurve: Identifiable {
    let id = UUID()
    let percentile: Int
    let values: [Double]
}

struct GrowthPercentileChart: View {
    let data: [ChartDataPoint]
    let percentiles: [PercentileCurve]
    let color: Color
    let unitLabel: String
    let title: String
    let useMetricUnits: Bool
    
    
    
    private var childDataLine: some ChartContent {
        ForEach(data) { dataPoint in
            LineMark(
                x: .value("Month", dataPoint.month),
                y: .value(title, dataPoint.value)
            )
            .foregroundStyle(color)
            .lineStyle(StrokeStyle(lineWidth: 3))
            .interpolationMethod(.catmullRom)
        }
    }
    
    private var childDataPoints: some ChartContent {
        ForEach(data) { dataPoint in
            PointMark(
                x: .value("Month", dataPoint.month),
                y: .value(title, dataPoint.value)
            )
            .foregroundStyle(color)
            .symbolSize(60)
        }
    }
    
    private var maxMonth: Double {
        return 36.0 // Fixed to 36 months (3 years)
    }
    
    private var focusedDomain: ClosedRange<Double> {
        // Force wider domain to spread out the data points
        let maxMonth = data.map { Double($0.month) }.max() ?? 36.0
        let extendedMax = max(36.0, maxMonth * 1.5) // Extend the domain by 50%
        return 0...extendedMax
    }
    
    private var yAxisDomain: ClosedRange<Double> {
        // Fixed y-axis range based on the data type
        switch title {
        case "Weight":
            return useMetricUnits ? 0...15 : 0...35 // kg or lbs
        case "Height":
            return useMetricUnits ? 40...120 : 15...48 // cm or inches
        case "Head Circumference":
            return useMetricUnits ? 30...60 : 12...24 // cm or inches
        default:
            let values = data.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let padding = (maxValue - minValue) * 0.1
            return (minValue - padding)...(maxValue + padding)
        }
    }
    
    private func shouldShowLabel(for month: Int) -> Bool {
        return true  // Show all month labels
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Chart {
                childDataLine
                childDataPoints
            }
            .frame(height: 300)
            .frame(width: 36 * 30) // Always show full 36 months (1080 points wide - 0.5cm spacing)
            .chartXAxis {
                AxisMarks(values: .stride(by: 1)) { value in
                    AxisGridLine()
                        .foregroundStyle(.gray.opacity(0.2))
                    AxisValueLabel {
                        if let month = value.as(Int.self) {
                            VStack(spacing: 1) {
                                Text("\(month)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text("mo")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .opacity(0.8)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 1)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(.gray.opacity(0.3))
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text("\(val, specifier: "%.1f")\(unitLabel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartXScale(domain: 0...36) // Always show full 36-month range
            .chartYScale(domain: yAxisDomain)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity) // Fixed viewport width
        .clipped() // Clip the scrollable content to the viewport
    }
    
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
        .padding(.vertical, 40)
    }
}

#Preview {
    ProgressView()
        .environmentObject(TotsDataManager())
}





