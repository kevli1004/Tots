import SwiftUI


struct ProgressView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var selectedTimeframe: TimeFrame = .thisWeek
    @State private var showingAddGrowth = false
    
    enum TimeFrame: String, CaseIterable {
        case thisWeek = "This Week"
        case lastWeek = "Last Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        
        var days: Int {
            switch self {
            case .thisWeek, .lastWeek: return 7
            case .thisMonth, .lastMonth: return 30
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
                        
                        // Growth tracking
                        growthView
                    }
                    .padding()
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAddGrowth) {
            AddActivityView(preselectedType: .growth)
                .environmentObject(dataManager)
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
            }
        }
    }
    
    private var weeklyOverviewView: some View {
        let timeframeData = dataManager.getDataForTimeframe(selectedTimeframe)
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("\(selectedTimeframe.rawValue) Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                WeeklyBarChart(
                    title: selectedTimeframe == .thisMonth ? "Average Feedings per Day (by week)" : "Feedings per Day",
                    data: timeframeData.map { Double($0.feedings) },
                    color: .pink,
                    maxValue: 10,
                    yAxisLabels: ["0", "2", "4", "6", "8", "10"]
                )
                
                WeeklyBarChart(
                    title: selectedTimeframe == .thisMonth ? "Average Sleep Hours per Day (by week)" : "Sleep Hours per Day",
                    data: timeframeData.map { $0.sleepHours },
                    color: .indigo,
                    maxValue: 16,
                    yAxisLabels: ["0", "4", "8", "12", "16"]
                )
                
                WeeklyBarChart(
                    title: selectedTimeframe == .thisMonth ? "Average Diaper Changes per Day (by week)" : "Diaper Changes per Day",
                    data: timeframeData.map { Double($0.diapers) },
                    color: .orange,
                    maxValue: 8,
                    yAxisLabels: ["0", "2", "4", "6", "8"]
                )
            }
        }
    }
    
    
    private var growthView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Growth Tracking")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Add growth entry button
                if !dataManager.growthData.isEmpty {
                    Button(action: {
                        showingAddGrowth = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                
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
            
            // Current Stats Cards or Add First Entry
            if dataManager.growthData.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Add Your First Growth Measurement")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Track your baby's weight, height, and head circumference over time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Add Measurement") {
                        showingAddGrowth = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                )
            } else {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        GrowthCard(
                            title: "Weight",
                            value: dataManager.formatWeight(dataManager.currentWeight),
                            subtitle: "\(dataManager.getWeightPercentile())th percentile",
                            color: .green
                        )
                        
                        GrowthCard(
                            title: "Height",
                            value: dataManager.formatHeight(dataManager.currentHeight),
                            subtitle: "\(dataManager.getHeightPercentile())th percentile",
                            color: .blue
                        )
                    }
                    
                    HStack(spacing: 16) {
                        GrowthCard(
                            title: "BMI",
                            value: String(format: "%.1f", dataManager.currentBMI),
                            subtitle: "\(dataManager.getBMIPercentile())th percentile for age",
                            color: .purple
                        )
                        
                        GrowthCard(
                            title: "Head Circumference",
                            value: dataManager.formatHeadCircumference(dataManager.currentHeadCircumference),
                            subtitle: "Latest measurement",
                            color: .orange
                        )
                    }
                }
            }
            
            // Growth Charts
            if dataManager.growthData.count > 1 {
                VStack(spacing: 16) {
                    GrowthLineChart(
                        title: "Weight Over Time",
                        data: dataManager.growthData,
                        dataType: .weight,
                        color: .green,
                        useMetricUnits: dataManager.useMetricUnits,
                        babyBirthDate: dataManager.babyBirthDate
                    )
                    
                    GrowthLineChart(
                        title: "Height Over Time",
                        data: dataManager.growthData,
                        dataType: .height,
                        color: .blue,
                        useMetricUnits: dataManager.useMetricUnits,
                        babyBirthDate: dataManager.babyBirthDate
                    )
                    
                    GrowthLineChart(
                        title: "Head Circumference Over Time",
                        data: dataManager.growthData,
                        dataType: .headCircumference,
                        color: .orange,
                        useMetricUnits: dataManager.useMetricUnits,
                        babyBirthDate: dataManager.babyBirthDate
                    )
                    
                    PercentileTrackingChart(
                        title: "Growth Percentiles Over Time",
                        percentileHistory: dataManager.growthPercentileHistory
                    )
                }
            } else if dataManager.growthData.count == 1 {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Add more growth measurements to see trends")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Add Measurement") {
                        showingAddGrowth = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                )
            }
        }
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
    let yAxisLabels: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 8) {
                // Y-axis labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(Array(yAxisLabels.reversed().enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(height: 80 / Double(yAxisLabels.count - 1))
                    }
                }
                .frame(width: 20)
                
                // Chart bars
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        VStack(spacing: 4) {
                            // Value label on top of bar
                            if value > 0 {
                                Text(String(format: "%.0f", value))
                                    .font(.caption2)
                                    .foregroundColor(color)
                                    .fontWeight(.medium)
                            }
                            
                            Rectangle()
                                .fill(color.opacity(0.8))
                                .frame(width: 30, height: max(4, (value / maxValue) * 80))
                                .cornerRadius(2)
                                .overlay(
                                    Rectangle()
                                        .fill(color)
                                        .frame(width: 30, height: max(2, (value / maxValue) * 80 * 0.3))
                                        .cornerRadius(2),
                                    alignment: .top
                                )
                            
                            Text(getDayLabel(for: index))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(height: 120)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
    
    private func getDayLabel(for index: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[safe: index] ?? ""
    }
}


struct GrowthCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: getIcon())
                    .foregroundColor(color)
                    .font(.title3)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
    
    private func getIcon() -> String {
        switch title {
        case "Weight": return "scalemass.fill"
        case "Height": return "ruler.fill"
        case "BMI": return "figure.child"
        case "Head Circumference": return "circle.dotted"
        default: return "chart.bar.fill"
        }
    }
}

struct GrowthLineChart: View {
    let title: String
    let data: [GrowthEntry]
    let dataType: GrowthDataType
    let color: Color
    let useMetricUnits: Bool
    let babyBirthDate: Date
    
    enum GrowthDataType {
        case weight, height, headCircumference
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if data.count > 1 {
                VStack(spacing: 8) {
                    // Chart area
                    GeometryReader { geometry in
                        let chartWidth = geometry.size.width - 40 // Leave space for Y-axis
                        let chartHeight = geometry.size.height - 40 // Leave space for X-axis
                        
                        ZStack {
                            // Background grid
                            drawGrid(width: chartWidth, height: chartHeight)
                            
                            // Growth data line
                            drawGrowthLine(width: chartWidth, height: chartHeight)
                            
                            // Data points
                            drawDataPoints(width: chartWidth, height: chartHeight)
                            
                            // Y-axis labels
                            drawYAxisLabels(height: chartHeight)
                            
                            // X-axis labels
                            drawXAxisLabels(width: chartWidth, height: chartHeight)
                        }
                    }
                    .frame(height: 200)
                    
                    // Legend and Axis Labels
                    VStack(spacing: 8) {
                        HStack(spacing: 20) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 8, height: 8)
                                Text("\(babyName)'s \(dataType == .weight ? "Weight" : dataType == .height ? "Height" : "Head Circumference")")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text("X-axis: Date")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Y-axis: \(getYAxisLabel())")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
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
    
    private var babyName: String {
        // Get baby name from UserDefaults or use default
        return UserDefaults.standard.string(forKey: "tots_baby_name") ?? "Baby"
    }
    
    private var sortedData: [GrowthEntry] {
        return data.sorted { $0.date < $1.date }
    }
    
    private var valueRange: (min: Double, max: Double) {
        let values = sortedData.map { entry in
            getValue(for: entry)
        }
        
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let padding = (maxValue - minValue) * 0.1
        
        return (min: minValue - padding, max: maxValue + padding)
    }
    
    private var dateRange: (start: Date, end: Date) {
        let dates = sortedData.map { $0.date }
        let start = dates.min() ?? Date()
        let end = dates.max() ?? Date()
        return (start: start, end: end)
    }
    
    private func convertWeightToKg(_ weight: Double) -> Double {
        return weight * 0.453592 // Convert lbs to kg
    }
    
    private func convertHeightToCm(_ height: Double) -> Double {
        return height * 2.54 // Convert inches to cm
    }
    
    private func drawGrid(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            // Horizontal lines
            for i in 0...4 {
                let y = height * CGFloat(i) / 4
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
            
            // Vertical lines
            for i in 0...4 {
                let x = width * CGFloat(i) / 4
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
            }
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        .offset(x: 40, y: 20)
    }
    
    private func drawAverageLine(width: CGFloat, height: CGFloat) -> some View {
        let range = valueRange
        let dateRangeData = dateRange
        
        return Path { path in
            let points = getAveragePoints(dateRange: dateRangeData, valueRange: range, width: width, height: height)
            
            if let firstPoint = points.first {
                path.move(to: firstPoint)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
        .offset(x: 40, y: 20)
    }
    
    private func drawGrowthLine(width: CGFloat, height: CGFloat) -> some View {
        let range = valueRange
        let dateRangeData = dateRange
        
        return Path { path in
            let points = sortedData.enumerated().map { index, entry in
                let x = width * CGFloat(entry.date.timeIntervalSince(dateRangeData.start)) / CGFloat(dateRangeData.end.timeIntervalSince(dateRangeData.start))
                let value = getValue(for: entry)
                let y = height * (1 - (value - range.min) / (range.max - range.min))
                
                return CGPoint(x: x, y: y)
            }
            
            if let firstPoint = points.first {
                path.move(to: firstPoint)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(color, lineWidth: 3)
        .offset(x: 40, y: 20)
    }
    
    private func drawDataPoints(width: CGFloat, height: CGFloat) -> some View {
        let range = valueRange
        let dateRangeData = dateRange
        
        return ZStack {
            ForEach(Array(sortedData.enumerated()), id: \.offset) { index, entry in
                let x = width * CGFloat(entry.date.timeIntervalSince(dateRangeData.start)) / CGFloat(dateRangeData.end.timeIntervalSince(dateRangeData.start))
                
                let value = getValue(for: entry)
                let y = height * (1 - (value - range.min) / (range.max - range.min))
                
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .offset(x: x + 40 - 4, y: y + 20 - 4)
            }
        }
    }
    
    private func getValue(for entry: GrowthEntry) -> Double {
        switch dataType {
        case .weight:
            return useMetricUnits ? convertWeightToKg(entry.weight) : entry.weight
        case .height:
            return useMetricUnits ? convertHeightToCm(entry.height) : entry.height
        case .headCircumference:
            return useMetricUnits ? entry.headCircumference : (entry.headCircumference / 2.54)
        }
    }
    
    private func getYAxisLabel() -> String {
        switch dataType {
        case .weight:
            return useMetricUnits ? "Weight (kg)" : "Weight (lbs)"
        case .height:
            return useMetricUnits ? "Height (cm)" : "Height (in)"
        case .headCircumference:
            return useMetricUnits ? "Head Circumference (cm)" : "Head Circumference (in)"
        }
    }
    
    private func drawYAxisLabels(height: CGFloat) -> some View {
        let range = valueRange
        
        return VStack(alignment: .trailing, spacing: 0) {
            ForEach(0..<5) { i in
                let value = range.max - (range.max - range.min) * Double(i) / 4
                let formattedValue = dataType == .weight ? 
                    String(format: "%.1f", value) :
                    String(format: "%.0f", value)
                
                Text(formattedValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(height: height / 4)
            }
        }
        .frame(width: 35)
        .offset(y: 20)
    }
    
    private func drawXAxisLabels(width: CGFloat, height: CGFloat) -> some View {
        let dateRangeData = dateRange
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        return HStack(spacing: 0) {
            ForEach(0..<5) { i in
                let timeInterval = dateRangeData.end.timeIntervalSince(dateRangeData.start)
                let date = dateRangeData.start.addingTimeInterval(timeInterval * Double(i) / 4)
                
                Text(formatter.string(from: date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: width / 4)
            }
        }
        .offset(x: 40, y: height + 30)
    }
    
    private func getAveragePoints(dateRange: (start: Date, end: Date), valueRange: (min: Double, max: Double), width: CGFloat, height: CGFloat) -> [CGPoint] {
        var points: [CGPoint] = []
        
        let timeInterval = dateRange.end.timeIntervalSince(dateRange.start)
        let pointCount = 20 // Number of points for smooth average line
        
        for i in 0...pointCount {
            let x = width * CGFloat(i) / CGFloat(pointCount)
            let date = dateRange.start.addingTimeInterval(timeInterval * Double(i) / Double(pointCount))
            
            let ageInMonths = Calendar.current.dateComponents([.month], from: babyBirthDate, to: date).month ?? 0
            
            let averageValue: Double
            if dataType == .weight {
                averageValue = getExpectedWeight(ageInMonths: ageInMonths, useMetric: useMetricUnits)
            } else {
                averageValue = getExpectedHeight(ageInMonths: ageInMonths, useMetric: useMetricUnits)
            }
            
            let y = height * (1 - (averageValue - valueRange.min) / (valueRange.max - valueRange.min))
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    private func getExpectedWeight(ageInMonths: Int, useMetric: Bool) -> Double {
        // WHO growth standards 50th percentile data
        let whoWeightData: [Double] = [
            3.3, 4.5, 5.6, 6.4, 7.0, 7.5, 7.9, 8.3, 8.6, 8.9, 9.2, 9.4, 9.6, // 0-12 months
            9.9, 10.1, 10.3, 10.5, 10.7, 10.9, 11.1, 11.3, 11.5, 11.8, 12.0, 12.2 // 13-24 months
        ]
        
        let weightKg: Double
        if ageInMonths < whoWeightData.count {
            weightKg = whoWeightData[ageInMonths]
        } else {
            // Extrapolate for older ages
            weightKg = 12.2 + Double(ageInMonths - 24) * 0.15
        }
        
        return useMetric ? weightKg : weightKg / 0.453592 // Convert to lbs if needed
    }
    
    private func getExpectedHeight(ageInMonths: Int, useMetric: Bool) -> Double {
        // WHO growth standards 50th percentile data
        let whoHeightData: [Double] = [
            49.9, 54.7, 58.4, 61.4, 63.9, 65.9, 67.6, 69.2, 70.6, 72.0, 73.3, 74.5, 75.7, // 0-12 months
            76.9, 78.0, 79.1, 80.2, 81.2, 82.3, 83.2, 84.2, 85.1, 86.0, 86.9, 87.8 // 13-24 months
        ]
        
        let heightCm: Double
        if ageInMonths < whoHeightData.count {
            heightCm = whoHeightData[ageInMonths]
        } else {
            // Extrapolate for older ages
            heightCm = 87.8 + Double(ageInMonths - 24) * 0.5
        }
        
        return useMetric ? heightCm : heightCm / 2.54 // Convert to inches if needed
    }
}

struct PercentileTrackingChart: View {
    let title: String
    let percentileHistory: [(date: Date, weightPercentile: Int, heightPercentile: Int, bmiPercentile: Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if percentileHistory.count > 1 {
                VStack(spacing: 8) {
                    // Chart area
                    GeometryReader { geometry in
                        let chartWidth = geometry.size.width - 40
                        let chartHeight = geometry.size.height - 40
                        
                        ZStack {
                            // Background grid
                            drawPercentileGrid(width: chartWidth, height: chartHeight)
                            
                            // Percentile reference lines (25th, 50th, 75th)
                            drawPercentileReferenceLines(width: chartWidth, height: chartHeight)
                            
                            // Weight percentile line
                            drawPercentileLine(width: chartWidth, height: chartHeight, dataType: .weight, color: .green)
                            
                            // Height percentile line
                            drawPercentileLine(width: chartWidth, height: chartHeight, dataType: .height, color: .blue)
                            
                            // BMI percentile line
                            drawPercentileLine(width: chartWidth, height: chartHeight, dataType: .bmi, color: .purple)
                            
                            // Y-axis labels
                            drawPercentileYAxisLabels(height: chartHeight)
                            
                            // X-axis labels
                            drawPercentileXAxisLabels(width: chartWidth, height: chartHeight)
                        }
                    }
                    .frame(height: 200)
                    
                    // Legend
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("Weight")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.blue)
                                .frame(width: 8, height: 8)
                            Text("Height")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(.purple)
                                .frame(width: 8, height: 8)
                            Text("BMI")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
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
    
    private enum PercentileDataType {
        case weight, height, bmi
    }
    
    private var sortedHistory: [(date: Date, weightPercentile: Int, heightPercentile: Int, bmiPercentile: Int)] {
        return percentileHistory.sorted { $0.date < $1.date }
    }
    
    private var dateRange: (start: Date, end: Date) {
        let dates = sortedHistory.map { $0.date }
        let start = dates.min() ?? Date()
        let end = dates.max() ?? Date()
        return (start: start, end: end)
    }
    
    private func drawPercentileGrid(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            // Horizontal lines
            for i in 0...4 {
                let y = height * CGFloat(i) / 4
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
            
            // Vertical lines
            for i in 0...4 {
                let x = width * CGFloat(i) / 4
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
            }
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        .offset(x: 40, y: 20)
    }
    
    private func drawPercentileReferenceLines(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            // 25th percentile line
            let y25 = height * (1 - 25.0 / 100.0)
            path.move(to: CGPoint(x: 0, y: y25))
            path.addLine(to: CGPoint(x: width, y: y25))
            
            // 50th percentile line
            let y50 = height * (1 - 50.0 / 100.0)
            path.move(to: CGPoint(x: 0, y: y50))
            path.addLine(to: CGPoint(x: width, y: y50))
            
            // 75th percentile line
            let y75 = height * (1 - 75.0 / 100.0)
            path.move(to: CGPoint(x: 0, y: y75))
            path.addLine(to: CGPoint(x: width, y: y75))
        }
        .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
        .offset(x: 40, y: 20)
    }
    
    private func drawPercentileLine(width: CGFloat, height: CGFloat, dataType: PercentileDataType, color: Color) -> some View {
        let dateRangeData = dateRange
        
        return Path { path in
            let points = sortedHistory.map { entry in
                let x = width * CGFloat(entry.date.timeIntervalSince(dateRangeData.start)) / CGFloat(dateRangeData.end.timeIntervalSince(dateRangeData.start))
                
                let percentile: Double
                switch dataType {
                case .weight:
                    percentile = Double(entry.weightPercentile)
                case .height:
                    percentile = Double(entry.heightPercentile)
                case .bmi:
                    percentile = Double(entry.bmiPercentile)
                }
                
                let y = height * (1 - percentile / 100.0)
                
                return CGPoint(x: x, y: y)
            }
            
            if let firstPoint = points.first {
                path.move(to: firstPoint)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(color, lineWidth: 2)
        .offset(x: 40, y: 20)
    }
    
    private func drawPercentileYAxisLabels(height: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach([100, 75, 50, 25, 0], id: \.self) { percentile in
                Text("\(percentile)%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(height: height / 4)
            }
        }
        .frame(width: 35)
        .offset(y: 20)
    }
    
    private func drawPercentileXAxisLabels(width: CGFloat, height: CGFloat) -> some View {
        let dateRangeData = dateRange
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        
        return HStack(spacing: 0) {
            ForEach(0..<5) { i in
                let timeInterval = dateRangeData.end.timeIntervalSince(dateRangeData.start)
                let date = dateRangeData.start.addingTimeInterval(timeInterval * Double(i) / 4)
                
                Text(formatter.string(from: date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: width / 4)
            }
        }
        .offset(x: 40, y: height + 30)
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