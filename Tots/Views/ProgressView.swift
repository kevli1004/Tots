import SwiftUI


struct ProgressView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var showingAddGrowth = false
    @State private var editingGrowthEntry: GrowthEntry? = nil
    @State private var showAllHistory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Growth tracking content
                        growthViewContent
                    }
                    .padding()
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
                        // If there's existing data, default to latest values for editing
                        // Otherwise, start fresh
                        editingGrowthEntry = dataManager.growthData.isEmpty ? nil : dataManager.growthData.first
                        showingAddGrowth = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(.regularMaterial)
                                .frame(width: 40, height: 40)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddGrowth) {
            AddActivityView(preselectedType: .growth, editingGrowthEntry: editingGrowthEntry)
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
    
    private var growthViewContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 12) {
                // Unit toggle row
                HStack {
                    Spacer()
                    
                    HStack(spacing: 4) {
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
                        editingGrowthEntry = nil
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
                            color: .green,
                            onTap: {
                                if let latestEntry = dataManager.growthData.first {
                                    editingGrowthEntry = latestEntry
                                    showingAddGrowth = true
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
                                    showingAddGrowth = true
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
                                    showingAddGrowth = true
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
                                    showingAddGrowth = true
                                }
                            }
                        )
                    }
                }
            }
            
            
            // Growth History Section
            if dataManager.growthData.count > 1 {
                VStack(alignment: .leading, spacing: 16) {
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
                        let displayedEntries = showAllHistory ? dataManager.growthData : Array(dataManager.growthData.prefix(5))
                        
                        ForEach(Array(displayedEntries.enumerated()), id: \.offset) { index, entry in
                            GrowthHistoryRow(
                                entry: entry,
                                isLatest: index == 0,
                                useMetricUnits: dataManager.useMetricUnits,
                                onTap: {
                                    editingGrowthEntry = entry
                                    showingAddGrowth = true
                                },
                                onDelete: {
                                    deleteGrowthEntry(entry)
                                }
                            )
                        }
                        
                        if !showAllHistory && dataManager.growthData.count > 5 {
                            Text("+ \(dataManager.growthData.count - 5) more entries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
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

struct GrowthHistoryRow: View {
    let entry: GrowthEntry
    let isLatest: Bool
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
                    
                    if isLatest {
                        Text("Latest")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    } else {
                        Text(timeAgo(from: entry.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Measurements
                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatWeight(entry.weight))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Weight")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatHeight(entry.height))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Height")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatHeadCircumference(entry.headCircumference))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Head")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Edit indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isLatest ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isLatest ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, equalTo: now, toGranularity: .day) {
            return "Today"
        } else if calendar.isDate(date, equalTo: calendar.date(byAdding: .day, value: -1, to: now) ?? now, toGranularity: .day) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days < 7 {
                return "\(days) days ago"
            } else if days < 30 {
                let weeks = days / 7
                return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
            } else {
                let months = calendar.dateComponents([.month], from: date, to: now).month ?? 0
                return "\(months) month\(months == 1 ? "" : "s") ago"
            }
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
            return String(format: "%.0f cm", cm)
        } else {
            let feet = Int(height / 12)
            let inches = height.truncatingRemainder(dividingBy: 12)
            return String(format: "%d'%.1f\"", feet, inches)
        }
    }
    
    private func formatHeadCircumference(_ circumference: Double) -> String {
        if useMetricUnits {
            return String(format: "%.1f cm", circumference)
        } else {
            let inches = circumference / 2.54
            return String(format: "%.1f\"", inches)
        }
    }
}

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
                    .foregroundColor(.primary)
                
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
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getIcon() -> String {
        switch title {
        case "Weight": return "scale.3d"
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
                        let chartWidth = geometry.size.width - 60 // Leave more space for Y-axis on left
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
        .offset(x: 60, y: 20)
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
        .offset(x: 60, y: 20)
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
                    .offset(x: x + 60 - 4, y: y + 20 - 4)
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
        .frame(width: 55)
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
        .offset(x: 60, y: height + 30)
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

struct BMIChart: View {
    let title: String
    let growthData: [GrowthEntry]
    let useMetricUnits: Bool
    
    private var bmiData: [(date: Date, bmi: Double)] {
        return growthData.map { entry in
            let weightKg = entry.weight * 0.453592 // Convert lbs to kg
            let heightM = entry.height * 0.0254 // Convert inches to meters
            let bmi = weightKg / (heightM * heightM)
            return (date: entry.date, bmi: bmi)
        }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if growthData.count > 1 {
                VStack(spacing: 8) {
                    // Chart area
                    GeometryReader { geometry in
                        let chartWidth = geometry.size.width - 60 // More space for y-axis labels on left
                        let chartHeight = geometry.size.height - 40
                        
                        ZStack {
                            // Background grid
                            drawBMIGrid(width: chartWidth, height: chartHeight)
                            
                            // BMI line
                            drawBMILine(width: chartWidth, height: chartHeight)
                            
                            // Y-axis labels (on the left)
                            drawBMIYAxisLabels(height: chartHeight)
                            
                            // X-axis labels
                            drawBMIXAxisLabels(width: chartWidth, height: chartHeight)
                        }
                    }
                    .frame(height: 200)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Add more growth entries to see BMI trends")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
    
    private var dateRange: (start: Date, end: Date) {
        let dates = bmiData.map { $0.date }
        let start = dates.min() ?? Date()
        let end = dates.max() ?? Date()
        return (start: start, end: end)
    }
    
    private var bmiRange: (min: Double, max: Double) {
        let bmis = bmiData.map { $0.bmi }
        let minBMI = bmis.min() ?? 0
        let maxBMI = bmis.max() ?? 30
        // Add some padding to the range
        let padding = (maxBMI - minBMI) * 0.1
        return (min: max(0, minBMI - padding), max: maxBMI + padding)
    }
    
    private func drawBMIGrid(width: CGFloat, height: CGFloat) -> some View {
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
        .offset(x: 60, y: 20) // More offset for left y-axis
    }
    
    private func drawBMILine(width: CGFloat, height: CGFloat) -> some View {
        let dateRangeData = dateRange
        let bmiRangeData = bmiRange
        
        return Path { path in
            let points = bmiData.map { entry in
                let x = width * CGFloat(entry.date.timeIntervalSince(dateRangeData.start)) / CGFloat(dateRangeData.end.timeIntervalSince(dateRangeData.start))
                let normalizedBMI = (entry.bmi - bmiRangeData.min) / (bmiRangeData.max - bmiRangeData.min)
                let y = height * (1 - normalizedBMI)
                return CGPoint(x: x, y: y)
            }
            
            if let firstPoint = points.first {
                path.move(to: firstPoint)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(.purple, lineWidth: 2)
        .offset(x: 60, y: 20)
    }
    
    private func drawBMIYAxisLabels(height: CGFloat) -> some View {
        let bmiRangeData = bmiRange
        
        return VStack(alignment: .trailing, spacing: 0) {
            ForEach(0..<5) { i in
                let bmiValue = bmiRangeData.max - (bmiRangeData.max - bmiRangeData.min) * Double(i) / 4
                Text(String(format: "%.1f", bmiValue))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(height: height / 4)
            }
        }
        .frame(width: 55)
        .offset(y: 20)
    }
    
    private func drawBMIXAxisLabels(width: CGFloat, height: CGFloat) -> some View {
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
        .offset(x: 60, y: height + 30)
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