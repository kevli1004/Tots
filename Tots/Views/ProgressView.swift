import SwiftUI


struct ProgressView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var showingAddGrowth = false
    @State private var editingGrowthEntry: GrowthEntry? = nil
    @State private var showAllHistory = false
    @State private var selectedGrowthTab: GrowthTab = .weight
    
    enum GrowthTab: String, CaseIterable {
        case weight = "Weight"
        case height = "Height"
        case bmi = "BMI"
        case headCircumference = "Head Circumference"
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
        VStack(alignment: .leading, spacing: 0) {
            Text("Growth Charts")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Swipeable TabView for different growth charts
            TabView(selection: $selectedGrowthTab) {
                weightChartContent
                    .tag(GrowthTab.weight)
                    .padding(.horizontal, 8)
                
                heightChartContent
                    .tag(GrowthTab.height)
                    .padding(.horizontal, 8)
                
                bmiChartContent
                    .tag(GrowthTab.bmi)
                    .padding(.horizontal, 8)
                
                headCircumferenceChartContent
                    .tag(GrowthTab.headCircumference)
                    .padding(.horizontal, 8)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 400)
            
            // Centered dots indicator at bottom
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(Array(GrowthTab.allCases.enumerated()), id: \.offset) { index, tab in
                        Circle()
                            .fill(selectedGrowthTab == tab ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: selectedGrowthTab)
                    }
                }
                Spacer()
            }
        }
    }
    
    private var weightChartContent: some View {
        VStack(spacing: 12) {
            if dataManager.growthData.count > 1 {
                SimpleGrowthChart(
                    title: "Weight Over Time",
                    data: dataManager.growthData,
                    dataType: .weight,
                    color: .green,
                    useMetricUnits: dataManager.useMetricUnits,
                    babyBirthDate: dataManager.babyBirthDate
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Need More Data")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Add more weight measurements to see the growth chart")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            }
        }
    }
    
    private var heightChartContent: some View {
        VStack(spacing: 12) {
            if dataManager.growthData.count > 1 {
                SimpleGrowthChart(
                    title: "Height Over Time",
                    data: dataManager.growthData,
                    dataType: .height,
                    color: .blue,
                    useMetricUnits: dataManager.useMetricUnits,
                    babyBirthDate: dataManager.babyBirthDate
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Need More Data")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Add more height measurements to see the growth chart")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            }
        }
    }
    
    private var bmiChartContent: some View {
        VStack(spacing: 12) {
            if dataManager.growthData.count > 1 {
                BMIChart(
                    title: "BMI Over Time",
                    growthData: dataManager.growthData,
                    useMetricUnits: dataManager.useMetricUnits
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Need More Data")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Add more measurements to see the BMI chart")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            }
        }
    }
    
    private var headCircumferenceChartContent: some View {
        VStack(spacing: 12) {
            if dataManager.growthData.count > 1 {
                SimpleGrowthChart(
                    title: "Head Circumference Over Time",
                    data: dataManager.growthData,
                    dataType: .headCircumference,
                    color: .orange,
                    useMetricUnits: dataManager.useMetricUnits,
                    babyBirthDate: dataManager.babyBirthDate
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Need More Data")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Add more measurements to see the head circumference chart")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            }
        }
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

struct SimpleGrowthChart: View {
    let title: String
    let data: [GrowthEntry]
    let dataType: GrowthDataType
    let color: Color
    let useMetricUnits: Bool
    let babyBirthDate: Date
    
    @State private var zoomScale: CGFloat = 1.0
    @State private var panOffset: CGSize = .zero
    @State private var lastPanOffset: CGSize = .zero
    
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
                        let chartWidth = geometry.size.width - 40
                        let chartHeight = geometry.size.height - 40
                        
                        ZStack {
                            // Background grid
                            drawGrid(width: chartWidth, height: chartHeight)
                            
                            // Growth data line
                            drawGrowthLine(width: chartWidth, height: chartHeight)
                            
                            // Data points
                            drawDataPoints(width: chartWidth, height: chartHeight)
                            
                            // Month labels
                            drawMonthLabels(width: chartWidth, height: chartHeight)
                        }
                        .scaleEffect(zoomScale)
                        .offset(panOffset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        zoomScale = max(0.5, min(3.0, value))
                                    }
                                    .onEnded { value in
                                        zoomScale = max(0.5, min(3.0, value))
                                    },
                                
                                DragGesture()
                                    .onChanged { value in
                                        panOffset = CGSize(
                                            width: lastPanOffset.width + value.translation.width,
                                            height: lastPanOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { value in
                                        lastPanOffset = panOffset
                                    }
                            )
                        )
                    }
                    .frame(height: 200)
                    
                    // Legend
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                        Text("\(babyName)'s \(getDataTypeLabel())")
                            .font(.caption)
                            .foregroundColor(.primary)
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
    
    private var babyName: String {
        return UserDefaults.standard.string(forKey: "tots_baby_name") ?? "Baby"
    }
    
    private var sortedData: [GrowthEntry] {
        return data.sorted { $0.date < $1.date }
    }
    
    private var valueRange: (min: Double, max: Double) {
        let values = sortedData.map { getValue(for: $0) }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let padding = (maxValue - minValue) * 0.1
        return (min: minValue - padding, max: maxValue + padding)
    }
    
    private var maxMonths: Int {
        return 12 // Fixed at 12 months to avoid calculation issues
    }
    
    private func getDataTypeLabel() -> String {
        switch dataType {
        case .weight: return "Weight"
        case .height: return "Height"
        case .headCircumference: return "Head Circumference"
        }
    }
    
    private func getValue(for entry: GrowthEntry) -> Double {
        switch dataType {
        case .weight:
            return useMetricUnits ? entry.weight * 0.453592 : entry.weight
        case .height:
            return useMetricUnits ? entry.height * 2.54 : entry.height
        case .headCircumference:
            return useMetricUnits ? entry.headCircumference * 2.54 : entry.headCircumference
        }
    }
    
    private func drawGrid(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            // Horizontal grid lines
            for i in 0...4 {
                let y = height * CGFloat(i) / 4
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
            
            // Vertical grid lines
            for i in 0...12 {
                let x = width * CGFloat(i) / 12
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
            }
        }
        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        .offset(x: 20, y: 10)
    }
    
    private func drawMonthLabels(width: CGFloat, height: CGFloat) -> some View {
        VStack {
            Spacer()
            HStack {
                ForEach(0...12, id: \.self) { month in
                    Text("\(month)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .offset(x: 20, y: 5)
        }
    }
    
    private func drawGrowthLine(width: CGFloat, height: CGFloat) -> some View {
        let range = valueRange
        
        return Path { path in
            let points = sortedData.map { entry in
                let monthsSinceBirth = Calendar.current.dateComponents([.month], from: babyBirthDate, to: entry.date).month ?? 0
                let x = width * CGFloat(monthsSinceBirth) / 12
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
        .offset(x: 20, y: 10)
    }
    
    private func drawDataPoints(width: CGFloat, height: CGFloat) -> some View {
        let range = valueRange
        
        return ZStack {
            ForEach(Array(sortedData.enumerated()), id: \.offset) { index, entry in
                let monthsSinceBirth = Calendar.current.dateComponents([.month], from: babyBirthDate, to: entry.date).month ?? 0
                let x = width * CGFloat(monthsSinceBirth) / 12
                let value = getValue(for: entry)
                let y = height * (1 - (value - range.min) / (range.max - range.min))
                
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .position(x: x + 20, y: y + 10)
            }
        }
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
                        let chartWidth = geometry.size.width - 40
                        let chartHeight = geometry.size.height - 20
                        
                        ZStack {
                            // Background grid
                            drawBMIGrid(width: chartWidth, height: chartHeight)
                            
                            // BMI line
                            drawBMILine(width: chartWidth, height: chartHeight)
                        }
                    }
                    .frame(height: 240)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Need More Data")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Add more measurements to see the BMI chart")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
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
        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        .offset(x: 20, y: 10)
    }
    
    private func drawBMILine(width: CGFloat, height: CGFloat) -> some View {
        let bmiValues = bmiData.map { $0.bmi }
        let minBMI = bmiValues.min() ?? 0
        let maxBMI = bmiValues.max() ?? 1
        let range = maxBMI - minBMI
        let padding = range * 0.1
        
        return Path { path in
            let points = bmiData.enumerated().map { index, data in
                let x = width * CGFloat(index) / CGFloat(max(1, bmiData.count - 1))
                let y = height * (1 - (data.bmi - minBMI + padding) / (range + 2 * padding))
                return CGPoint(x: x, y: y)
            }
            
            if let firstPoint = points.first {
                path.move(to: firstPoint)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
        }
        .stroke(Color.purple, lineWidth: 3)
        .offset(x: 20, y: 10)
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

#Preview {
    ProgressView()
        .environmentObject(TotsDataManager())
}