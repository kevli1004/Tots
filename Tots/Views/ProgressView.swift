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
        // WHO Growth Standards - proper percentile data
        let value = getWHOPercentileValue(for: type, month: month, percentile: percentile, isMale: isMale)
        
        // Convert units if needed
        if !useMetricUnits {
            switch type {
            case "weight":
                return value * 2.20462 // kg to lbs
            case "height", "headCircumference":
                return value * 0.393701 // cm to inches
            default:
                return value
            }
        }
        
        return value
    }
    
    private func getWHOPercentileValue(for type: String, month: Int, percentile: Int, isMale: Bool) -> Double {
        // Use gender-specific data for charts
        let median = getExpectedValue(for: type, month: month, isMale: isMale)
        let standardDeviation = getStandardDeviation(for: type, month: month, isMale: isMale)
        
        // Convert percentile to z-score
        let zScore = getZScore(for: percentile)
        
        // Calculate the percentile value
        return median + (zScore * standardDeviation)
    }
    
    private func getExpectedValue(for type: String, month: Int, isMale: Bool) -> Double {
        switch type {
        case "weight":
            return getExpectedWeight(month: month, isMale: isMale)
        case "height":
            return getExpectedHeight(month: month, isMale: isMale)
        case "headCircumference":
            return getExpectedHeadCircumference(month: month, isMale: isMale)
        default:
            return 0
        }
    }
    
    private func getExpectedWeight(month: Int, isMale: Bool) -> Double {
        // WHO weight-for-age 50th percentile (kg) - more complete data
        let maleWeights: [Double] = [
            3.3, 4.5, 5.6, 6.4, 7.0, 7.5, 7.9, 8.3, 8.6, 8.9, 9.2, 9.4, 9.6, 9.9, 10.1, 10.3, 10.5, 10.7, 10.9, 11.1, 11.3, 11.5, 11.8, 12.0, 12.2, 12.4, 12.7, 12.9, 13.1, 13.4, 13.6, 13.8, 14.1, 14.3, 14.6, 14.8, 15.1
        ]
        let femaleWeights: [Double] = [
            3.2, 4.2, 5.1, 5.8, 6.4, 6.9, 7.3, 7.6, 7.9, 8.2, 8.5, 8.7, 8.9, 9.2, 9.4, 9.6, 9.8, 10.0, 10.2, 10.4, 10.6, 10.9, 11.1, 11.3, 11.5, 11.7, 12.0, 12.2, 12.4, 12.7, 12.9, 13.1, 13.4, 13.6, 13.9, 14.1, 14.4
        ]
        
        let weights = isMale ? maleWeights : femaleWeights
        if month < weights.count {
            return weights[month]
        } else {
            // Extrapolate for older ages
            let lastWeight = weights.last ?? 15.0
            let monthlyGain = isMale ? 0.15 : 0.14
            return lastWeight + Double(month - weights.count + 1) * monthlyGain
        }
    }
    
    private func getExpectedHeight(month: Int, isMale: Bool) -> Double {
        // WHO length/height-for-age 50th percentile (cm)
        let maleHeights: [Double] = [
            49.9, 54.7, 58.4, 61.4, 63.9, 65.9, 67.6, 69.2, 70.6, 72.0, 73.3, 74.5, 75.7, 76.9, 78.0, 79.1, 80.2, 81.2, 82.3, 83.2, 84.2, 85.1, 86.0, 86.9, 87.8, 88.7, 89.6, 90.4, 91.2, 92.1, 92.9, 93.7, 94.4, 95.2, 95.9, 96.6, 97.4
        ]
        let femaleHeights: [Double] = [
            49.1, 53.7, 57.1, 59.8, 62.1, 64.0, 65.7, 67.3, 68.7, 70.1, 71.4, 72.6, 73.8, 75.0, 76.0, 77.1, 78.1, 79.1, 80.0, 81.0, 81.9, 82.8, 83.7, 84.6, 85.4, 86.3, 87.1, 87.9, 88.7, 89.5, 90.3, 91.1, 91.8, 92.6, 93.3, 94.1, 94.8
        ]
        
        let heights = isMale ? maleHeights : femaleHeights
        if month < heights.count {
            return heights[month]
        } else {
            // Extrapolate for older ages
            let lastHeight = heights.last ?? 95.0
            let monthlyGain = isMale ? 0.5 : 0.45
            return lastHeight + Double(month - heights.count + 1) * monthlyGain
        }
    }
    
    private func getExpectedHeadCircumference(month: Int, isMale: Bool) -> Double {
        // WHO head circumference-for-age 50th percentile (cm)
        let maleHeadCirc: [Double] = [
            34.5, 37.3, 39.1, 40.5, 41.6, 42.6, 43.3, 43.9, 44.5, 45.0, 45.4, 45.8, 46.1, 46.4, 46.7, 47.0, 47.2, 47.4, 47.6, 47.8, 48.0, 48.2, 48.4, 48.5, 48.7, 48.9, 49.0, 49.2, 49.3, 49.5, 49.6, 49.8, 49.9, 50.1, 50.2, 50.4, 50.5
        ]
        let femaleHeadCirc: [Double] = [
            33.9, 36.5, 38.3, 39.5, 40.4, 41.2, 41.8, 42.4, 42.9, 43.3, 43.7, 44.0, 44.3, 44.6, 44.9, 45.1, 45.4, 45.6, 45.8, 46.0, 46.2, 46.4, 46.5, 46.7, 46.9, 47.0, 47.2, 47.3, 47.5, 47.6, 47.8, 47.9, 48.1, 48.2, 48.4, 48.5, 48.7
        ]
        
        let headCircs = isMale ? maleHeadCirc : femaleHeadCirc
        if month < headCircs.count {
            return headCircs[month]
        } else {
            // Extrapolate for older ages
            let lastCirc = headCircs.last ?? 50.0
            let monthlyGain = isMale ? 0.08 : 0.07
            return lastCirc + Double(month - headCircs.count + 1) * monthlyGain
        }
    }
    
    private func getStandardDeviation(for type: String, month: Int, isMale: Bool) -> Double {
        // Use actual WHO standard deviations (same as TotsDataManager)
        switch type {
        case "weight":
            return getWeightStandardDeviation(ageInMonths: month)
        case "height":
            return getHeightStandardDeviation(ageInMonths: month)
        case "headCircumference":
            return getHeadCircumferenceStandardDeviation(ageInMonths: month)
        default:
            return 1.0
        }
    }
    
    private func getWeightStandardDeviation(ageInMonths: Int) -> Double {
        // WHO weight standard deviations (kg)
        let whoWeightSD: [Double] = [
            0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.0, 1.1, 1.1, 1.2, 1.2, 1.3, 1.3, // 0-12 months
            1.3, 1.4, 1.4, 1.4, 1.5, 1.5, 1.5, 1.6, 1.6, 1.6, 1.7, 1.7 // 13-24 months
        ]
        
        if ageInMonths < whoWeightSD.count {
            return whoWeightSD[ageInMonths]
        } else {
            return 1.8 // Default for older ages
        }
    }
    
    private func getHeightStandardDeviation(ageInMonths: Int) -> Double {
        // WHO height standard deviations (cm)
        let whoHeightSD: [Double] = [
            1.9, 2.0, 2.1, 2.2, 2.3, 2.4, 2.4, 2.5, 2.5, 2.6, 2.6, 2.7, 2.7, // 0-12 months
            2.8, 2.8, 2.9, 2.9, 3.0, 3.0, 3.1, 3.1, 3.2, 3.2, 3.3, 3.3 // 13-24 months
        ]
        
        if ageInMonths < whoHeightSD.count {
            return whoHeightSD[ageInMonths]
        } else {
            return 3.5 // Default for older ages
        }
    }
    
    private func getHeadCircumferenceStandardDeviation(ageInMonths: Int) -> Double {
        // WHO head circumference standard deviations (cm)
        let whoHeadCircSD: [Double] = [
            1.1, 1.2, 1.3, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4, // 0-12 months
            1.4, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4, 1.4 // 13-24 months
        ]
        
        if ageInMonths < whoHeadCircSD.count {
            return whoHeadCircSD[ageInMonths]
        } else {
            return 1.5 // Default for older ages
        }
    }
    
    private func getZScore(for percentile: Int) -> Double {
        // Convert percentile to z-score using inverse normal distribution
        let p = Double(percentile) / 100.0
        return inverseNormalCDF(p)
    }
    
    private func inverseNormalCDF(_ p: Double) -> Double {
        // Approximation of inverse normal CDF (Beasley-Springer-Moro algorithm)
        let a = [0, -3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02, 1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00]
        let b = [0, -5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02, 6.680131188771972e+01, -1.328068155288572e+01]
        let c = [0, -7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00, -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00]
        let d = [0, 7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00, 3.754408661907416e+00]
        
        let pLow = 0.02425
        let pHigh = 1 - pLow
        
        if p < pLow {
            let q = sqrt(-2 * log(p))
            return (((((c[1]*q+c[2])*q+c[3])*q+c[4])*q+c[5])*q+c[6]) / ((((d[1]*q+d[2])*q+d[3])*q+d[4])*q+1)
        } else if p <= pHigh {
            let q = p - 0.5
            let r = q * q
            return (((((a[1]*r+a[2])*r+a[3])*r+a[4])*r+a[5])*r+a[6])*q / (((((b[1]*r+b[2])*r+b[3])*r+b[4])*r+b[5])*r+1)
        } else {
            let q = sqrt(-2 * log(1-p))
            return -(((((c[1]*q+c[2])*q+c[3])*q+c[4])*q+c[5])*q+c[6]) / ((((d[1]*q+d[2])*q+d[3])*q+d[4])*q+1)
        }
    }
    
    
    
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Liquid animated background
                    LiquidBackground()
                    
                    ScrollView {
                    VStack(spacing: 16) {
                        // Ad Banner
                        AdBannerContainerWide()
                        
                        // Combined toggles row
                        combinedTogglesRow
                        
                        // Growth overview cards
                        growthOverviewCards
                        
                        // Growth charts with tabs
                        growthTabView
                        
                        // History section
                        growthHistorySection
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .frame(width: geometry.size.width)
                }
            }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
        .navigationViewStyle(StackNavigationViewStyle())
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
    
    
    private var combinedTogglesRow: some View {
        HStack {
            // Gender toggle on the left
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
            
            Spacer()
            
            // Unit toggle on the right
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
        .padding(.horizontal)
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
                            subtitle: "\(dataManager.getWeightPercentile(isMale: isMale))th percentile",
                            color: .green,
                            onTap: {
                                if let latestEntry = dataManager.growthData.sorted(by: { $0.date > $1.date }).first {
                                    editingGrowthEntry = latestEntry
                                }
                            }
                        )
                        
                        GrowthCard(
                            title: "Height",
                            value: dataManager.formatHeight(dataManager.currentHeight),
                            subtitle: "\(dataManager.getHeightPercentile(isMale: isMale))th percentile",
                            color: .blue,
                            onTap: {
                                if let latestEntry = dataManager.growthData.sorted(by: { $0.date > $1.date }).first {
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
                                if let latestEntry = dataManager.growthData.sorted(by: { $0.date > $1.date }).first {
                                    editingGrowthEntry = latestEntry
                                }
                            }
                        )
                        
                        GrowthCard(
                            title: "Head Circumference",
                            value: dataManager.formatHeadCircumference(dataManager.currentHeadCircumference),
                            subtitle: "\(dataManager.getHeadCircumferencePercentile(isMale: isMale))th percentile",
                            color: .orange,
                            onTap: {
                                if let latestEntry = dataManager.growthData.sorted(by: { $0.date > $1.date }).first {
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
            }
            
            // Show all charts stacked vertically or single empty state
            if dataManager.growthData.count > 0 {
                VStack(spacing: 16) {
                    weightChartContent
                    heightChartContent
                    headCircumferenceChartContent
                }
            } else {
                // Single empty state for all growth charts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Growth Charts")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    EmptyStateView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "No Growth Data Yet",
                        message: "Add your first growth measurement to see weight, height, and head circumference charts with percentile tracking"
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                )
            }
        }
    }
    
    private var weightChartContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight Over Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            GrowthPercentileChart(
                data: weightChartData,
                percentiles: weightPercentileData,
                color: .blue,
                unitLabel: dataManager.useMetricUnits ? "kg" : "lbs",
                title: "Weight",
                useMetricUnits: dataManager.useMetricUnits
            )
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
            
            GrowthPercentileChart(
                data: heightChartData,
                percentiles: heightPercentileData,
                color: .green,
                unitLabel: dataManager.useMetricUnits ? "cm" : "in",
                title: "Height",
                useMetricUnits: dataManager.useMetricUnits
            )
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
                    
            GrowthPercentileChart(
                data: headCircumferenceChartData,
                percentiles: headCircumferencePercentileData,
                color: .purple,
                unitLabel: dataManager.useMetricUnits ? "cm" : "in",
                title: "Head Circumference",
                useMetricUnits: dataManager.useMetricUnits
            )
        }
        .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                )
            }
            
    private var growthHistorySection: some View {
                VStack(alignment: .leading, spacing: 16) {
            if dataManager.growthData.count > 0 {
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
            .frame(height: 120) // Fixed height for consistency
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
            return String(format: "%.1f kg", weight) // weight is already in kg
        } else {
            let lbs = weight * 2.20462 // convert kg to lbs
            return String(format: "%.1f lbs", lbs)
        }
    }
    
    private func formatHeight(_ height: Double) -> String {
        if useMetricUnits {
            return String(format: "%.1f cm", height) // height is already in cm
        } else {
            let inches = height * 0.393701 // convert cm to inches
            return String(format: "%.1f\"", inches)
        }
    }
    
    private func formatHeadCircumference(_ headCircumference: Double) -> String {
        if useMetricUnits {
            return String(format: "%.1f cm", headCircumference) // headCircumference is already in cm
        } else {
            let inches = headCircumference * 0.393701 // convert cm to inches
            return String(format: "%.1f\"", inches)
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
            return useMetricUnits ? 0...25 : 0...55 // kg or lbs
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





