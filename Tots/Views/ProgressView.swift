import SwiftUI
import Charts


struct ProgressView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var showingAddGrowth = false
    @State private var editingGrowthEntry: GrowthEntry? = nil
    @State private var showAllHistory = false
    @State private var isMale = true // true for boy, false for girl
    
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
    
    // Percentile data for growth charts
    private var weightPercentileData: [PercentileCurve] {
        generatePercentileCurves(for: "weight", isMale: isMale, useMetricUnits: dataManager.useMetricUnits)
    }
    
    private var heightPercentileData: [PercentileCurve] {
        generatePercentileCurves(for: "height", isMale: isMale, useMetricUnits: dataManager.useMetricUnits)
    }
    
    private var headCircumferencePercentileData: [PercentileCurve] {
        generatePercentileCurves(for: "headCircumference", isMale: isMale, useMetricUnits: dataManager.useMetricUnits)
    }
    
    private func generatePercentileCurves(for type: String, isMale: Bool, useMetricUnits: Bool) -> [PercentileCurve] {
        let percentiles = [5, 50, 95]
        var curves: [PercentileCurve] = []
        
        for percentile in percentiles {
            var values: [Double] = []
            // Create points for every month for smooth curves
            for month in 0...36 {
                let value = getPercentileValue(for: type, month: month, percentile: percentile, isMale: isMale, useMetricUnits: useMetricUnits)
                values.append(value)
            }
            curves.append(PercentileCurve(percentile: percentile, values: values))
        }
        
        return curves
    }
    
    private func getPercentileValue(for type: String, month: Int, percentile: Int, isMale: Bool, useMetricUnits: Bool) -> Double {
        // Simplified percentile data - in a real app, you'd use WHO/CDC growth charts
        let baseValues: [String: [Double]] = [
            "weight": isMale ? [3.3, 4.3, 5.3, 6.0, 6.7, 7.3, 7.8, 8.2, 8.6, 9.0, 9.3, 9.6, 9.9, 10.2, 10.5, 10.8, 11.1, 11.4, 11.7, 12.0, 12.3, 12.6, 12.9, 13.2, 13.5, 13.8, 14.1, 14.4, 14.7, 15.0, 15.3, 15.6, 15.9, 16.2, 16.5, 16.8, 17.1] : [3.2, 4.2, 5.1, 5.8, 6.4, 6.9, 7.3, 7.7, 8.0, 8.3, 8.6, 8.9, 9.2, 9.5, 9.8, 10.1, 10.4, 10.7, 11.0, 11.3, 11.6, 11.9, 12.2, 12.5, 12.8, 13.1, 13.4, 13.7, 14.0, 14.3, 14.6, 14.9, 15.2, 15.5, 15.8, 16.1, 16.4],
            "height": isMale ? [49.9, 54.7, 58.4, 61.4, 63.9, 65.9, 67.6, 69.2, 70.6, 72.0, 73.4, 74.7, 76.1, 77.4, 78.7, 80.0, 81.3, 82.5, 83.8, 85.0, 86.2, 87.4, 88.6, 89.8, 91.0, 92.2, 93.4, 94.6, 95.8, 97.0, 98.2, 99.4, 100.6, 101.8, 103.0, 104.2, 105.4] : [49.1, 53.7, 57.1, 59.8, 62.1, 64.0, 65.7, 67.3, 68.7, 70.1, 71.4, 72.8, 74.1, 75.4, 76.7, 78.0, 79.3, 80.5, 81.8, 83.0, 84.2, 85.4, 86.6, 87.8, 89.0, 90.2, 91.4, 92.6, 93.8, 95.0, 96.2, 97.4, 98.6, 99.8, 101.0, 102.2, 103.4],
            "headCircumference": isMale ? [33.2, 35.7, 37.8, 39.5, 40.9, 42.1, 43.1, 44.0, 44.8, 45.5, 46.1, 46.6, 47.1, 47.5, 47.9, 48.3, 48.6, 48.9, 49.2, 49.5, 49.8, 50.0, 50.3, 50.5, 50.8, 51.0, 51.3, 51.5, 51.8, 52.0, 52.3, 52.5, 52.8, 53.0, 53.3, 53.5, 53.8] : [32.6, 35.1, 37.1, 38.7, 40.0, 41.1, 42.0, 42.8, 43.5, 44.1, 44.6, 45.1, 45.5, 45.9, 46.3, 46.6, 47.0, 47.3, 47.6, 47.9, 48.2, 48.5, 48.8, 49.0, 49.3, 49.6, 49.8, 50.1, 50.3, 50.6, 50.8, 51.1, 51.3, 51.6, 51.8, 52.1, 52.3]
        ]
        
        guard let values = baseValues[type], month < values.count else { return 0 }
        let baseValue = values[month]
        
        // Apply percentile adjustment (simplified)
        let adjustment = Double(percentile - 50) * 0.1
        let adjustedValue = baseValue + adjustment
        
        // Convert units if needed
        if !useMetricUnits {
            switch type {
            case "weight":
                return adjustedValue * 2.20462 // kg to lbs
            case "height", "headCircumference":
                return adjustedValue * 0.393701 // cm to inches
            default:
                return adjustedValue
            }
        }
        
        return adjustedValue
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
            HStack {
                Text("Growth Charts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Gender toggle
                HStack(spacing: 8) {
                    Button(action: { isMale = true }) {
                        Text("Boy")
                            .font(.caption)
                            .fontWeight(isMale ? .semibold : .regular)
                            .foregroundColor(isMale ? .blue : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isMale ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                    }
                    
                    Button(action: { isMale = false }) {
                        Text("Girl")
                            .font(.caption)
                            .fontWeight(!isMale ? .semibold : .regular)
                            .foregroundColor(!isMale ? .blue : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(!isMale ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                    }
                }
            }
            
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
                    percentiles: weightPercentileData,
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
                    percentiles: heightPercentileData,
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
                    percentiles: headCircumferencePercentileData,
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
    let percentile: Int?
    
    init(month: Int, value: Double, date: Date, percentile: Int? = nil) {
        self.month = month
        self.value = value
        self.date = date
        self.percentile = percentile
    }
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
        // Fixed y-axis range based on the data type - extended to fit 95th percentile
        switch title {
        case "Weight":
            return useMetricUnits ? 0...20 : 0...45 // kg or lbs - extended for 95th percentile
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
    
    private func getPercentileColor(_ percentile: Int) -> Color {
        switch percentile {
        case 5: return .red.opacity(0.6)
        case 50: return .orange.opacity(0.6)
        case 95: return .green.opacity(0.6)
        default: return .gray.opacity(0.6)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Legend for percentiles
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.red.opacity(0.5))
                        .frame(width: 20, height: 2)
                    Text("5th")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.orange.opacity(0.5))
                        .frame(width: 20, height: 2)
                    Text("50th")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.green.opacity(0.5))
                        .frame(width: 20, height: 2)
                    Text("95th")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                Chart {
                // 3 Percentile lines with connected points
                if percentiles.count >= 3 {
                    // 5th percentile line
                    ForEach(Array(percentiles[0].values.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Month", index),
                            y: .value("Value", value),
                            series: .value("Percentile", "5th")
                        )
                        .foregroundStyle(.red.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                    
                    // 50th percentile line
                    ForEach(Array(percentiles[1].values.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Month", index),
                            y: .value("Value", value),
                            series: .value("Percentile", "50th")
                        )
                        .foregroundStyle(.orange.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                    
                    // 95th percentile line
                    ForEach(Array(percentiles[2].values.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Month", index),
                            y: .value("Value", value),
                            series: .value("Percentile", "95th")
                        )
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                }
                
                // Your actual data - solid line with points
                ForEach(data) { dataPoint in
                    LineMark(
                        x: .value("Month", dataPoint.month),
                        y: .value("Value", dataPoint.value),
                        series: .value("Data", "Your Baby")
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                }
                
                ForEach(data) { dataPoint in
                    PointMark(
                        x: .value("Month", dataPoint.month),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(color)
                    .symbolSize(80)
                }
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
                            .padding(.horizontal, 4)
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
            .chartPlotStyle { plotArea in
                plotArea
                    .padding(.leading, 0) // Ensure plot area starts at y-axis
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity) // Fixed viewport width
        .clipped() // Clip the scrollable content to the viewport
        }
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





