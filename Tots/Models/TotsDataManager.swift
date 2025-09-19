import Foundation
import SwiftUI
import ActivityKit
import CloudKit

class TotsDataManager: ObservableObject {
    // MARK: - Storage Keys
    private let activitiesKey = "tots_activities"
    private let milestonesKey = "tots_milestones"
    private let growthDataKey = "tots_growth_data"
    private let wordsKey = "tots_words"
    private let babyNameKey = "tots_baby_name"
    private let babyBirthDateKey = "tots_baby_birth_date"
    private let weeklyGoalsKey = "tots_weekly_goals"
    private var countdownTimer: Timer?
    // MARK: - Smart Analytics
    @Published var aiInsights: [AIInsight] = []
    @Published var predictedNextActivity: ActivityType?
    @Published var sleepPatterns: [SleepPattern] = []
    @Published var feedingEfficiency: Double = 0.85
    @Published var developmentScore: Int = 78
    
    // Growth percentile data
    var currentBMI: Double {
        guard let latestGrowth = growthData.last else { return 0.0 }
        let weightKg = convertWeightToKg(latestGrowth.weight)
        let heightM = convertHeightToCm(latestGrowth.height) / 100.0
        return weightKg / (heightM * heightM)
    }
    
    var currentWeight: Double {
        return growthData.last?.weight ?? 15.0 // Default weight in lbs
    }
    
    var currentHeight: Double {
        return growthData.last?.height ?? 68.5 // Default height in cm
    }
    @Published var healthTrends: [HealthTrend] = []
    
    // CloudKit
    @Published var familySharingEnabled: Bool = false
    @Published var babyProfileRecord: CKRecord?
    let cloudKitManager = CloudKitManager.shared
    private let schemaSetup = CloudKitSchemaSetup.shared
    
    // App State Management
    @Published var shouldShowOnboarding: Bool = false
    
    // Live Activity
    @Published var currentActivity: Activity<TotsLiveActivityAttributes>?
    @Published var widgetEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(widgetEnabled, forKey: "widget_enabled")
        }
    }
    
    // Units preference
    @Published var useMetricUnits: Bool = true {
        didSet {
            UserDefaults.standard.set(useMetricUnits, forKey: "use_metric_units")
        }
    }
    
    @Published var babyName: String = "" {
        didSet {
            UserDefaults.standard.set(babyName, forKey: babyNameKey)
        }
    }
    @Published var babyBirthDate: Date = Date() {
        didSet {
            UserDefaults.standard.set(babyBirthDate, forKey: babyBirthDateKey)
        }
    }
    @Published var streakCount: Int = 0
    @Published var totalActivitiesLogged: Int = 0
    
    // MARK: - Countdown Timers
    @Published var nextFeedingCountdown: TimeInterval = 0
    @Published var nextDiaperCountdown: TimeInterval = 0
    @Published var nextFeedingTime: Date?
    @Published var nextDiaperTime: Date?
    
    // Today's tracking data
    @Published var todayFeedings: Int = 7
    @Published var todayDiapers: Int = 5
    @Published var todaySleepHours: Double = 14.2
    @Published var todayMilestones: Int = 1
    @Published var todayTummyTime: Int = 45 // minutes
    @Published var todayPlayTime: Int = 120 // minutes
    
    // Weekly goals
    @Published var weeklyFeedingGoal: Int = 56 // 8 per day
    @Published var weeklyDiaperGoal: Int = 42 // 6 per day
    @Published var weeklySleepGoal: Double = 105.0 // 15 hours per day
    @Published var weeklyTummyTimeGoal: Int = 350 // 50 minutes per day
    
    // Recent activities - loaded from storage
    @Published var recentActivities: [TotsActivity] = [] {
        didSet {
            saveActivities()
        }
    }
    
    // Weekly progress data - calculated from real activities
    @Published var weeklyData: [DayData] = []
    
    // Milestones - loaded from storage
    @Published var milestones: [Milestone] = [] {
        didSet {
            saveMilestones()
        }
    }
    
    // Growth tracking - loaded from storage
    @Published var growthData: [GrowthEntry] = [] {
        didSet {
            saveGrowthData()
        }
    }
    
    // Predefined milestones for different age groups
    private let predefinedMilestones: [Milestone] = [
        // 0-3 months (Newborn)
        Milestone(title: "First smile", minAgeWeeks: 4, maxAgeWeeks: 8, category: .social, description: "Baby shows their first social smile in response to you", isPredefined: true),
        Milestone(title: "Holds head up briefly", minAgeWeeks: 2, maxAgeWeeks: 6, category: .motor, description: "Can lift head for short periods during tummy time", isPredefined: true),
        Milestone(title: "Follows objects with eyes", minAgeWeeks: 3, maxAgeWeeks: 8, category: .sensory, description: "Tracks moving objects or faces with their eyes", isPredefined: true),
        Milestone(title: "Makes cooing sounds", minAgeWeeks: 6, maxAgeWeeks: 12, category: .language, description: "Makes soft cooing or gurgling sounds", isPredefined: true),
        Milestone(title: "Startles at loud sounds", minAgeWeeks: 0, maxAgeWeeks: 4, category: .sensory, description: "Shows startle reflex to sudden noises", isPredefined: true),
        
        // 3-6 months
        Milestone(title: "Laughs out loud", minAgeWeeks: 12, maxAgeWeeks: 20, category: .social, description: "Giggles and laughs in response to play", isPredefined: true),
        Milestone(title: "Sits with support", minAgeWeeks: 16, maxAgeWeeks: 24, category: .motor, description: "Can sit upright when supported by pillows or hands", isPredefined: true),
        Milestone(title: "Reaches for toys", minAgeWeeks: 12, maxAgeWeeks: 20, category: .motor, description: "Deliberately reaches for and grasps objects", isPredefined: true),
        Milestone(title: "Rolls over", minAgeWeeks: 16, maxAgeWeeks: 28, category: .motor, description: "Rolls from tummy to back or back to tummy", isPredefined: true),
        Milestone(title: "Babbles consonants", minAgeWeeks: 20, maxAgeWeeks: 32, category: .language, description: "Makes sounds like 'ba-ba' or 'da-da'", isPredefined: true),
        Milestone(title: "Puts everything in mouth", minAgeWeeks: 16, maxAgeWeeks: 24, category: .sensory, description: "Explores objects by putting them in mouth", isPredefined: true),
        
        // 6-9 months
        Milestone(title: "Sits without support", minAgeWeeks: 24, maxAgeWeeks: 36, category: .motor, description: "Sits independently without falling over", isPredefined: true),
        Milestone(title: "Crawls or scoots", minAgeWeeks: 28, maxAgeWeeks: 40, category: .motor, description: "Moves around by crawling, scooting, or rolling", isPredefined: true),
        Milestone(title: "Says 'mama' or 'dada'", minAgeWeeks: 28, maxAgeWeeks: 44, category: .language, description: "Says first words, may not be specific to parent yet", isPredefined: true),
        Milestone(title: "Plays peek-a-boo", minAgeWeeks: 32, maxAgeWeeks: 44, category: .social, description: "Enjoys and participates in peek-a-boo games", isPredefined: true),
        Milestone(title: "Pincer grasp", minAgeWeeks: 36, maxAgeWeeks: 48, category: .motor, description: "Picks up small objects with thumb and finger", isPredefined: true),
        Milestone(title: "Eats finger foods", minAgeWeeks: 32, maxAgeWeeks: 44, category: .feeding, description: "Self-feeds with small pieces of soft food", isPredefined: true),
        
        // 9-12 months
        Milestone(title: "Pulls to standing", minAgeWeeks: 36, maxAgeWeeks: 48, category: .motor, description: "Pulls themselves up to standing position", isPredefined: true),
        Milestone(title: "Cruises along furniture", minAgeWeeks: 40, maxAgeWeeks: 52, category: .motor, description: "Walks while holding onto furniture for support", isPredefined: true),
        Milestone(title: "Waves bye-bye", minAgeWeeks: 36, maxAgeWeeks: 48, category: .social, description: "Waves hand to say goodbye", isPredefined: true),
        Milestone(title: "Responds to name", minAgeWeeks: 32, maxAgeWeeks: 44, category: .language, description: "Looks when you call their name", isPredefined: true),
        Milestone(title: "Imitates sounds", minAgeWeeks: 36, maxAgeWeeks: 52, category: .language, description: "Copies sounds and gestures you make", isPredefined: true),
        Milestone(title: "Drinks from cup", minAgeWeeks: 40, maxAgeWeeks: 60, category: .feeding, description: "Drinks from a sippy cup or regular cup with help", isPredefined: true),
        
        // 12-18 months (Toddler)
        Milestone(title: "First steps", minAgeWeeks: 48, maxAgeWeeks: 72, category: .motor, description: "Takes first independent steps", isPredefined: true),
        Milestone(title: "Says first words", minAgeWeeks: 44, maxAgeWeeks: 68, category: .language, description: "Uses words meaningfully (mama, dada, ball, etc.)", isPredefined: true),
        Milestone(title: "Points at objects", minAgeWeeks: 48, maxAgeWeeks: 64, category: .language, description: "Points to show you things they want or find interesting", isPredefined: true),
        Milestone(title: "Stacks blocks", minAgeWeeks: 52, maxAgeWeeks: 72, category: .cognitive, description: "Stacks 2-3 blocks on top of each other", isPredefined: true),
        Milestone(title: "Shows affection", minAgeWeeks: 48, maxAgeWeeks: 68, category: .social, description: "Gives hugs, kisses, or shows other signs of affection", isPredefined: true),
        Milestone(title: "Uses spoon", minAgeWeeks: 52, maxAgeWeeks: 78, category: .feeding, description: "Attempts to use a spoon to self-feed", isPredefined: true),
        
        // 18-24 months
        Milestone(title: "Runs steadily", minAgeWeeks: 72, maxAgeWeeks: 96, category: .motor, description: "Runs without falling frequently", isPredefined: true),
        Milestone(title: "Kicks a ball", minAgeWeeks: 78, maxAgeWeeks: 104, category: .motor, description: "Kicks a ball forward while walking", isPredefined: true),
        Milestone(title: "Two-word phrases", minAgeWeeks: 78, maxAgeWeeks: 104, category: .language, description: "Combines words like 'more milk' or 'go car'", isPredefined: true),
        Milestone(title: "Pretend play", minAgeWeeks: 72, maxAgeWeeks: 96, category: .cognitive, description: "Pretends to feed dolls, talk on phone, etc.", isPredefined: true),
        Milestone(title: "Follows simple instructions", minAgeWeeks: 68, maxAgeWeeks: 88, category: .cognitive, description: "Follows one-step instructions like 'come here'", isPredefined: true),
        Milestone(title: "Shows independence", minAgeWeeks: 78, maxAgeWeeks: 104, category: .social, description: "Wants to do things by themselves", isPredefined: true),
        
        // 2+ years
        Milestone(title: "Jumps with both feet", minAgeWeeks: 96, maxAgeWeeks: 130, category: .motor, description: "Jumps off ground with both feet together", isPredefined: true),
        Milestone(title: "Three-word sentences", minAgeWeeks: 104, maxAgeWeeks: 130, category: .language, description: "Uses sentences with 3+ words", isPredefined: true),
        Milestone(title: "Sorts shapes", minAgeWeeks: 104, maxAgeWeeks: 130, category: .cognitive, description: "Sorts objects by shape, color, or size", isPredefined: true),
        Milestone(title: "Plays with other children", minAgeWeeks: 104, maxAgeWeeks: 156, category: .social, description: "Engages in parallel or cooperative play", isPredefined: true),
        Milestone(title: "Potty training", minAgeWeeks: 104, maxAgeWeeks: 208, category: .physical, description: "Shows interest in or begins potty training", isPredefined: true),
    ]
    
    // Word tracking - loaded from storage
    @Published var words: [BabyWord] = [] {
        didSet {
            saveWords()
        }
    }
    
    var babyAge: String {
        let months = Calendar.current.dateComponents([.month], from: babyBirthDate, to: Date()).month ?? 0
        if months < 12 {
            return "\(months) months old"
        } else {
            let years = months / 12
            let remainingMonths = months % 12
            if remainingMonths == 0 {
                return "\(years) year\(years == 1 ? "" : "s") old"
            } else {
                return "\(years)y \(remainingMonths)m old"
            }
        }
    }
    
    // MARK: - Unit Conversion Helpers
    
    func formatWeight(_ weightInKg: Double) -> String {
        if useMetricUnits {
            return String(format: "%.1f kg", weightInKg)
        } else {
            let weightInLbs = weightInKg * 2.20462
            return String(format: "%.1f lbs", weightInLbs)
        }
    }
    
    func formatHeight(_ heightInCm: Double) -> String {
        if useMetricUnits {
            return String(format: "%.1f cm", heightInCm)
        } else {
            let heightInInches = heightInCm / 2.54
            return String(format: "%.1f in", heightInInches)
        }
    }
    
    func convertWeightToKg(_ weight: Double, fromImperial: Bool = false) -> Double {
        if fromImperial {
            return weight / 2.20462
        }
        return weight
    }
    
    func convertHeightToCm(_ height: Double, fromImperial: Bool = false) -> Double {
        if fromImperial {
            return height * 2.54
        }
        return height
    }
    
    init() {
        loadData()
        updateCountdowns()
        startCountdownTimer()
    }
    
    // MARK: - Data Persistence
    
    private func loadData() {
        // Load basic settings
        babyName = UserDefaults.standard.string(forKey: babyNameKey) ?? "Baby"
        if let birthDate = UserDefaults.standard.object(forKey: babyBirthDateKey) as? Date {
            babyBirthDate = birthDate
        } else {
            babyBirthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
        }
        
        // Load widget settings
        widgetEnabled = UserDefaults.standard.object(forKey: "widget_enabled") as? Bool ?? false
        
        // Load units preference
        useMetricUnits = UserDefaults.standard.object(forKey: "use_metric_units") as? Bool ?? true
        
        // Load activities
        if let data = UserDefaults.standard.data(forKey: activitiesKey),
           let activities = try? JSONDecoder().decode([TotsActivity].self, from: data) {
            recentActivities = activities.sorted { $0.time > $1.time }
        }
        
        // Load milestones
        if let data = UserDefaults.standard.data(forKey: milestonesKey),
           let milestones = try? JSONDecoder().decode([Milestone].self, from: data) {
            self.milestones = milestones
        }
        
        // Load growth data
        if let data = UserDefaults.standard.data(forKey: growthDataKey),
           let growth = try? JSONDecoder().decode([GrowthEntry].self, from: data) {
            growthData = growth
        }
        
        // Load words
        if let data = UserDefaults.standard.data(forKey: wordsKey),
           let words = try? JSONDecoder().decode([BabyWord].self, from: data) {
            self.words = words.sorted { $0.dateFirstSaid < $1.dateFirstSaid }
        }
        
        // Load CloudKit settings
        familySharingEnabled = UserDefaults.standard.bool(forKey: "family_sharing_enabled")
        
        // Always try to fetch existing baby profiles from CloudKit
        Task {
            await loadExistingBabyProfile()
        }
        
        // Calculate stats from loaded data
        calculateStats()
    }
    
    private func saveActivities() {
        if let data = try? JSONEncoder().encode(recentActivities) {
            UserDefaults.standard.set(data, forKey: activitiesKey)
        }
        calculateStats()
    }
    
    private func saveMilestones() {
        if let data = try? JSONEncoder().encode(milestones) {
            UserDefaults.standard.set(data, forKey: milestonesKey)
        }
    }
    
    private func saveGrowthData() {
        if let data = try? JSONEncoder().encode(growthData) {
            UserDefaults.standard.set(data, forKey: growthDataKey)
        }
    }
    
    private func saveWords() {
        if let data = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(data, forKey: wordsKey)
        }
    }
    
    
    private func calculateStats() {
        totalActivitiesLogged = recentActivities.count
        
        // Calculate streak (consecutive days with activities)
        var streak = 0
        let calendar = Calendar.current
        var currentDate = calendar.dateInterval(of: .day, for: Date())?.start ?? Date()
        
        while true {
            let hasActivityOnDate = recentActivities.contains { activity in
                calendar.isDate(activity.time, inSameDayAs: currentDate)
            }
            
            if hasActivityOnDate {
                streak += 1
                if let nextDate = calendar.date(byAdding: .day, value: -1, to: currentDate),
                   let normalizedDate = calendar.dateInterval(of: .day, for: nextDate)?.start {
                    currentDate = normalizedDate
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        streakCount = streak
        
        // Update today's stats
        let today = calendar.dateInterval(of: .day, for: Date())?.start ?? Date()
        let todayActivities = recentActivities.filter { calendar.isDate($0.time, inSameDayAs: today) }
        
        todayFeedings = todayActivities.filter { $0.type == .feeding }.count
        todayDiapers = todayActivities.filter { $0.type == .diaper }.count
        todayMilestones = todayActivities.filter { $0.type == .milestone }.count
        
        let sleepActivities = todayActivities.filter { $0.type == .sleep }
        todaySleepHours = Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
        
        let tummyActivities = todayActivities.filter { $0.type == .activity && $0.details.lowercased().contains("tummy") }
        todayTummyTime = tummyActivities.compactMap { $0.duration }.reduce(0, +)
        
        let playActivities = todayActivities.filter { $0.type == .activity && !$0.details.lowercased().contains("tummy") }
        todayPlayTime = playActivities.compactMap { $0.duration }.reduce(0, +)
        
        // Update weekly data based on real activities
        updateWeeklyData()
        
        // Save widget data
        saveWidgetData()
    }
    
    private func updateWeeklyData() {
        let calendar = Calendar.current
        let today = calendar.dateInterval(of: .day, for: Date())?.start ?? Date()
        
        weeklyData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayActivities = recentActivities.filter { calendar.isDate($0.time, inSameDayAs: date) }
            
            let feedings = dayActivities.filter { $0.type == .feeding }.count
            let diapers = dayActivities.filter { $0.type == .diaper }.count
            
            let sleepActivities = dayActivities.filter { $0.type == .sleep }
            let sleepHours = Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
            
            let tummyActivities = dayActivities.filter { $0.type == .activity && $0.details.lowercased().contains("tummy") }
            let tummyTime = tummyActivities.compactMap { $0.duration }.reduce(0, +)
            
            let playActivities = dayActivities.filter { $0.type == .activity && !$0.details.lowercased().contains("tummy") }
            let playTime = playActivities.compactMap { $0.duration }.reduce(0, +)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let dayString = formatter.string(from: date)
            
            return DayData(
                day: dayString,
                date: date,
                feedings: feedings,
                diapers: diapers,
                sleepHours: sleepHours,
                tummyTime: tummyTime,
                playTime: playTime
            )
        }.reversed()
    }
    
    func getDataForTimeframe(_ timeframe: ProgressView.TimeFrame) -> [DayData] {
        let calendar = Calendar.current
        let today = calendar.dateInterval(of: .day, for: Date())?.start ?? Date()
        
        switch timeframe {
        case .thisWeek, .lastWeek:
            let (startDate, days) = getTimeframeRange(timeframe, from: today)
            return (0..<days).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
                return getDayData(for: date, formatter: "E")
            }
            
        case .thisMonth:
            // For monthly view, aggregate data by week to prevent overflow
            let (startDate, _) = getTimeframeRange(timeframe, from: today)
            let endDate = today
            
            var weeklyData: [DayData] = []
            var currentWeekStart = startDate
            
            while currentWeekStart < endDate {
                let weekEnd = min(calendar.date(byAdding: .day, value: 6, to: currentWeekStart) ?? endDate, endDate)
                
                // Aggregate data for this week
                var totalFeedings = 0
                var totalDiapers = 0
                var totalSleepHours = 0.0
                var totalTummyTime = 0
                var totalPlayTime = 0
                var daysInWeek = 0
                
                var date = currentWeekStart
                while date <= weekEnd {
                    let dayActivities = recentActivities.filter { calendar.isDate($0.time, inSameDayAs: date) }
                    
                    totalFeedings += dayActivities.filter { $0.type == .feeding }.count
                    totalDiapers += dayActivities.filter { $0.type == .diaper }.count
                    
                    let sleepActivities = dayActivities.filter { $0.type == .sleep }
                    totalSleepHours += Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
                    
                    let tummyActivities = dayActivities.filter { $0.type == .activity && $0.details.lowercased().contains("tummy") }
                    totalTummyTime += tummyActivities.compactMap { $0.duration }.reduce(0, +)
                    
                    let playActivities = dayActivities.filter { $0.type == .activity && !$0.details.lowercased().contains("tummy") }
                    totalPlayTime += playActivities.compactMap { $0.duration }.reduce(0, +)
                    
                    daysInWeek += 1
                    date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
                }
                
                // Calculate averages for the week
                let avgFeedings = daysInWeek > 0 ? totalFeedings / daysInWeek : 0
                let avgDiapers = daysInWeek > 0 ? totalDiapers / daysInWeek : 0
                let avgSleepHours = daysInWeek > 0 ? totalSleepHours / Double(daysInWeek) : 0.0
                let avgTummyTime = daysInWeek > 0 ? totalTummyTime / daysInWeek : 0
                let avgPlayTime = daysInWeek > 0 ? totalPlayTime / daysInWeek : 0
                
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d"
                let weekLabel = formatter.string(from: currentWeekStart)
                
                weeklyData.append(DayData(
                    day: weekLabel,
                    date: currentWeekStart,
                    feedings: avgFeedings,
                    diapers: avgDiapers,
                    sleepHours: avgSleepHours,
                    tummyTime: avgTummyTime,
                    playTime: avgPlayTime
                ))
                
                currentWeekStart = calendar.date(byAdding: .day, value: 7, to: currentWeekStart) ?? currentWeekStart
            }
            
            return weeklyData
        }
    }
    
    private func getDayData(for date: Date, formatter: String) -> DayData {
        let calendar = Calendar.current
        let dayActivities = recentActivities.filter { calendar.isDate($0.time, inSameDayAs: date) }
        
        let feedings = dayActivities.filter { $0.type == .feeding }.count
        let diapers = dayActivities.filter { $0.type == .diaper }.count
        
        let sleepActivities = dayActivities.filter { $0.type == .sleep }
        let sleepHours = Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
        
        let tummyActivities = dayActivities.filter { $0.type == .activity && $0.details.lowercased().contains("tummy") }
        let tummyTime = tummyActivities.compactMap { $0.duration }.reduce(0, +)
        
        let playActivities = dayActivities.filter { $0.type == .activity && !$0.details.lowercased().contains("tummy") }
        let playTime = playActivities.compactMap { $0.duration }.reduce(0, +)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatter
        let dayString = dateFormatter.string(from: date)
        
        return DayData(
            day: dayString,
            date: date,
            feedings: feedings,
            diapers: diapers,
            sleepHours: sleepHours,
            tummyTime: tummyTime,
            playTime: playTime
        )
    }
    
    private func getTimeframeRange(_ timeframe: ProgressView.TimeFrame, from today: Date) -> (startDate: Date, days: Int) {
        let calendar = Calendar.current
        
        switch timeframe {
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
            return (startOfWeek, 7)
            
        case .lastWeek:
            let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: today) ?? today
            let startOfLastWeek = calendar.dateInterval(of: .weekOfYear, for: lastWeek)?.start ?? today
            return (startOfLastWeek, 7)
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
            let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
            return (startOfMonth, daysInMonth)
        }
    }
    
    var weeklyProgress: (feedings: Double, diapers: Double, sleep: Double, tummyTime: Double) {
        let totalFeedings = weeklyData.reduce(0) { $0 + $1.feedings }
        let totalDiapers = weeklyData.reduce(0) { $0 + $1.diapers }
        let totalSleep = weeklyData.reduce(0) { $0 + $1.sleepHours }
        let totalTummyTime = weeklyData.reduce(0) { $0 + $1.tummyTime }
        
        return (
            feedings: Double(totalFeedings) / Double(weeklyFeedingGoal),
            diapers: Double(totalDiapers) / Double(weeklyDiaperGoal),
            sleep: totalSleep / weeklySleepGoal,
            tummyTime: Double(totalTummyTime) / Double(weeklyTummyTimeGoal)
        )
    }
    
    func addActivity(_ activity: TotsActivity) {
        recentActivities.insert(activity, at: 0)
        updateCountdowns() // Update countdowns after adding activity
        
        // Update Live Activity if running
        updateLiveActivity()
        
        // Start Live Activity if not running and widget is enabled
        if currentActivity == nil && widgetEnabled {
            startLiveActivity()
        }
        
        // Debug logging
        print("🔍 Add Activity Debug:")
        print("   familySharingEnabled: \(familySharingEnabled)")
        print("   babyProfileRecord: \(babyProfileRecord != nil ? "exists" : "nil")")
        
        // Always sync to CloudKit (create baby profile if needed)
        Task {
            do {
                // Ensure we have a baby profile record
                if babyProfileRecord == nil {
                    print("🍼 No baby profile found, creating one...")
                    await createDefaultBabyProfile()
                }
                
                guard let profileRecord = babyProfileRecord else {
                    print("❌ Failed to create baby profile record")
                    return
                }
                
                try await cloudKitManager.saveActivity(activity, to: profileRecord.recordID)
                print("✅ Activity synced to CloudKit")
            } catch {
                print("❌ Failed to sync activity to CloudKit: \(error)")
            }
        }
    }
    
    func deleteActivity(_ activity: TotsActivity) {
        recentActivities.removeAll { $0.id == activity.id }
        updateCountdowns() // Update countdowns after deleting activity
        
        // Update Live Activity if running
        updateLiveActivity()
        
        // Recalculate stats
        calculateStats()
    }
    
    func updateActivity(_ oldActivity: TotsActivity, with newActivity: TotsActivity) {
        if let index = recentActivities.firstIndex(where: { $0.id == oldActivity.id }) {
            // Create updated activity with same ID
            var updatedActivity = newActivity
            updatedActivity = TotsActivity(
                type: newActivity.type,
                time: newActivity.time,
                details: newActivity.details,
                mood: newActivity.mood,
                duration: newActivity.duration,
                notes: newActivity.notes,
                weight: newActivity.weight,
                height: newActivity.height
            )
            
            recentActivities[index] = updatedActivity
            updateCountdowns()
            updateLiveActivity()
            calculateStats()
        }
    }
    
    private func updateTodayStats(for activity: TotsActivity) {
        switch activity.type {
        case .feeding:
            todayFeedings += 1
        case .pumping:
            // Pumping doesn't directly affect feeding count but could be tracked separately
            break
        case .diaper:
            todayDiapers += 1
        case .sleep:
            todaySleepHours += Double(activity.duration ?? 90) / 60.0
        case .milestone:
            todayMilestones += 1
        case .activity:
            if activity.details.lowercased().contains("tummy") {
                todayTummyTime += activity.duration ?? 15
            } else {
                todayPlayTime += activity.duration ?? 30
            }
        case .growth:
            // Growth tracking doesn't affect daily stats
            break
        }
        
        // Save widget data
        saveWidgetData()
    }
    
    private func saveWidgetData() {
        UserDefaults.standard.set(todayFeedings, forKey: "today_feedings")
        UserDefaults.standard.set(todaySleepHours, forKey: "today_sleep_hours")
        UserDefaults.standard.set(todayDiapers, forKey: "today_diapers")
        UserDefaults.standard.set(todayTummyTime, forKey: "today_tummy_time")
    }
    
    func completeMilestone(_ milestone: Milestone) {
        if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
            milestones[index].isCompleted = true
            milestones[index].completedDate = Date()
        } else if milestone.isPredefined {
            // Add the predefined milestone as completed
            var completedMilestone = milestone
            completedMilestone.isCompleted = true
            completedMilestone.completedDate = Date()
            milestones.append(completedMilestone)
        }
        
        // Add milestone activity
        let activity = TotsActivity(
            type: .milestone,
            time: Date(),
            details: milestone.title,
            mood: .happy,
            notes: milestone.description
        )
        addActivity(activity)
        
        // Update development score
        updateDevelopmentScore()
        generateAIInsights()
    }
    
    // MARK: - Word Tracking
    
    func addWord(_ word: String, category: WordCategory = .other, notes: String = "") {
        // Check if word already exists
        if !words.contains(where: { $0.word.lowercased() == word.lowercased() }) {
            let newWord = BabyWord(
                word: word,
                category: category,
                dateFirstSaid: Date(),
                notes: notes
            )
            words.append(newWord)
            words.sort { $0.dateFirstSaid < $1.dateFirstSaid }
            
            // Add milestone activity for first words
            if words.count == 1 {
                let activity = TotsActivity(
                    type: .milestone,
                    time: Date(),
                    details: "First Word: \(word)",
                    mood: .happy,
                    notes: "Said their very first word!"
                )
                addActivity(activity)
            } else if words.count == 10 {
                let activity = TotsActivity(
                    type: .milestone,
                    time: Date(),
                    details: "10 Words Milestone",
                    mood: .happy,
                    notes: "Now knows 10 words!"
                )
                addActivity(activity)
            }
            
            updateDevelopmentScore()
            generateAIInsights()
        }
    }
    
    func deleteWord(_ word: BabyWord) {
        words.removeAll { $0.id == word.id }
    }
    
    func updateWord(_ word: BabyWord, newWord: String, category: WordCategory, notes: String) {
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index].word = newWord
            words[index].category = category
            words[index].notes = notes
        }
    }
    
    var wordCount: Int {
        return words.count
    }
    
    var wordsByCategory: [WordCategory: [BabyWord]] {
        return Dictionary(grouping: words) { $0.category }
    }
    
    // MARK: - Milestone Management
    
    func getRelevantMilestones() -> [Milestone] {
        let babyAgeInWeeks = getBabyAgeInWeeks()
        
        // Get predefined milestones that are relevant for current age
        let relevantPredefined = predefinedMilestones.filter { milestone in
            milestone.isRelevantForAge(weeks: babyAgeInWeeks) &&
            !milestones.contains { existing in existing.title == milestone.title }
        }
        
        // Combine with user's custom milestones and completed ones
        return (milestones + relevantPredefined).sorted { milestone1, milestone2 in
            // Sort by: completed status (incomplete first), then by min age, then by title
            if milestone1.isCompleted != milestone2.isCompleted {
                return !milestone1.isCompleted && milestone2.isCompleted
            }
            if milestone1.minAgeWeeks != milestone2.minAgeWeeks {
                return milestone1.minAgeWeeks < milestone2.minAgeWeeks
            }
            return milestone1.title < milestone2.title
        }
    }
    
    func getBabyAgeInWeeks() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: babyBirthDate, to: Date())
        return max(0, components.weekOfYear ?? 0)
    }
    
    func addMilestone(_ milestone: Milestone) {
        milestones.append(milestone)
    }
    
    
    // MARK: - Growth Percentile Calculations
    
    func getWeightPercentile() -> Int {
        guard let latestGrowth = growthData.last else { return 50 }
        return getWeightPercentile(for: latestGrowth)
    }
    
    func getHeightPercentile() -> Int {
        guard let latestGrowth = growthData.last else { return 50 }
        return getHeightPercentile(for: latestGrowth)
    }
    
    func getBMIPercentile() -> Int {
        guard let latestGrowth = growthData.last else { return 50 }
        return getBMIPercentile(for: latestGrowth)
    }
    
    func getWeightPercentile(for entry: GrowthEntry) -> Int {
        let ageInMonths = Calendar.current.dateComponents([.month], from: babyBirthDate, to: entry.date).month ?? 0
        let weightKg = convertWeightToKg(entry.weight)
        
        // WHO growth standards with age-appropriate standard deviation
        let expectedWeight = getExpectedWeight(ageInMonths: ageInMonths)
        let standardDeviation = getWeightStandardDeviation(ageInMonths: ageInMonths)
        let percentile = calculatePercentile(value: weightKg, expected: expectedWeight, standardDeviation: standardDeviation)
        return percentile
    }
    
    func getHeightPercentile(for entry: GrowthEntry) -> Int {
        let ageInMonths = Calendar.current.dateComponents([.month], from: babyBirthDate, to: entry.date).month ?? 0
        let heightCm = convertHeightToCm(entry.height)
        
        // WHO growth standards with age-appropriate standard deviation
        let expectedHeight = getExpectedHeight(ageInMonths: ageInMonths)
        let standardDeviation = getHeightStandardDeviation(ageInMonths: ageInMonths)
        let percentile = calculatePercentile(value: heightCm, expected: expectedHeight, standardDeviation: standardDeviation)
        return percentile
    }
    
    func getBMIPercentile(for entry: GrowthEntry) -> Int {
        let ageInMonths = Calendar.current.dateComponents([.month], from: babyBirthDate, to: entry.date).month ?? 0
        let weightKg = convertWeightToKg(entry.weight)
        let heightM = convertHeightToCm(entry.height) / 100.0
        let bmi = weightKg / (heightM * heightM)
        
        // WHO BMI-for-age standards with age-appropriate standard deviation
        let expectedBMI = getExpectedBMI(ageInMonths: ageInMonths)
        let standardDeviation = getBMIStandardDeviation(ageInMonths: ageInMonths)
        let percentile = calculatePercentile(value: bmi, expected: expectedBMI, standardDeviation: standardDeviation)
        return percentile
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
    
    private func getBMIStandardDeviation(ageInMonths: Int) -> Double {
        // WHO BMI standard deviations (kg/m²)
        let whoBMISD: [Double] = [
            1.3, 1.4, 1.4, 1.3, 1.2, 1.2, 1.1, 1.1, 1.0, 1.0, 1.0, 1.0, 0.9, // 0-12 months
            0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9 // 13-24 months
        ]
        
        if ageInMonths < whoBMISD.count {
            return whoBMISD[ageInMonths]
        } else {
            return 1.0 // Default for older ages
        }
    }
    
    var growthPercentileHistory: [(date: Date, weightPercentile: Int, heightPercentile: Int, bmiPercentile: Int)] {
        return growthData.map { entry in
            (
                date: entry.date,
                weightPercentile: getWeightPercentile(for: entry),
                heightPercentile: getHeightPercentile(for: entry),
                bmiPercentile: getBMIPercentile(for: entry)
            )
        }
    }
    
    private func getAgeInMonths() -> Int {
        let components = Calendar.current.dateComponents([.month], from: babyBirthDate, to: Date())
        return max(0, components.month ?? 0)
    }
    
    private func getExpectedWeight(ageInMonths: Int) -> Double {
        // WHO growth standards 50th percentile for boys/girls average (in kg)
        let whoWeightData: [Double] = [
            3.3, 4.5, 5.6, 6.4, 7.0, 7.5, 7.9, 8.3, 8.6, 8.9, 9.2, 9.4, 9.6, // 0-12 months
            9.9, 10.1, 10.3, 10.5, 10.7, 10.9, 11.1, 11.3, 11.5, 11.8, 12.0, 12.2 // 13-24 months
        ]
        
        if ageInMonths < whoWeightData.count {
            return whoWeightData[ageInMonths]
        } else {
            // Extrapolate for older ages
            return 12.2 + Double(ageInMonths - 24) * 0.15
        }
    }
    
    private func getExpectedHeight(ageInMonths: Int) -> Double {
        // WHO growth standards 50th percentile for boys/girls average (in cm)
        let whoHeightData: [Double] = [
            49.9, 54.7, 58.4, 61.4, 63.9, 65.9, 67.6, 69.2, 70.6, 72.0, 73.3, 74.5, 75.7, // 0-12 months
            76.9, 78.0, 79.1, 80.2, 81.2, 82.3, 83.2, 84.2, 85.1, 86.0, 86.9, 87.8 // 13-24 months
        ]
        
        if ageInMonths < whoHeightData.count {
            return whoHeightData[ageInMonths]
        } else {
            // Extrapolate for older ages
            return 87.8 + Double(ageInMonths - 24) * 0.5
        }
    }
    
    private func getExpectedBMI(ageInMonths: Int) -> Double {
        // WHO BMI-for-age 50th percentile (kg/m²)
        let whoBMIData: [Double] = [
            13.3, 14.9, 16.3, 16.8, 16.8, 16.6, 16.4, 16.2, 16.0, 15.8, 15.7, 15.5, 15.4, // 0-12 months
            15.3, 15.2, 15.1, 15.0, 14.9, 14.9, 14.8, 14.8, 14.7, 14.7, 14.7, 14.6 // 13-24 months
        ]
        
        if ageInMonths < whoBMIData.count {
            return whoBMIData[ageInMonths]
        } else {
            // Extrapolate for older ages
            return 14.6 + Double(ageInMonths - 24) * -0.02
        }
    }
    
    private func calculatePercentile(value: Double, expected: Double, standardDeviation: Double) -> Int {
        let zScore = (value - expected) / standardDeviation
        
        // More accurate z-score to percentile conversion using cumulative distribution
        let percentile = cumulativeNormalDistribution(zScore) * 100
        
        return max(3, min(97, Int(percentile.rounded())))
    }
    
    private func cumulativeNormalDistribution(_ z: Double) -> Double {
        // Approximation of cumulative normal distribution using error function
        return 0.5 * (1 + erf(z / sqrt(2)))
    }
    
    private func erf(_ x: Double) -> Double {
        // Approximation of error function
        let a1 = 0.254829592
        let a2 = -0.284496736
        let a3 = 1.421413741
        let a4 = -1.453152027
        let a5 = 1.061405429
        let p = 0.3275911
        
        let sign = x < 0 ? -1.0 : 1.0
        let absX = abs(x)
        
        let t = 1.0 / (1.0 + p * absX)
        let y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-absX * absX)
        
        return sign * y
    }
    
    // MARK: - AI & Smart Features
    
    func generateAIInsights() {
        aiInsights = []
        
        // Sleep pattern analysis
        if let sleepInsight = analyzeSleepPatterns() {
            aiInsights.append(sleepInsight)
        }
        
        // Feeding optimization
        if let feedingInsight = analyzeFeedingPatterns() {
            aiInsights.append(feedingInsight)
        }
        
        // Milestone prediction
        if let milestoneInsight = predictNextMilestone() {
            aiInsights.append(milestoneInsight)
        }
        
        // Mood analysis
        if let moodInsight = analyzeMoodPatterns() {
            aiInsights.append(moodInsight)
        }
        
        // Growth analysis
        if let growthInsight = analyzeGrowthTrends() {
            aiInsights.append(growthInsight)
        }
    }
    
    private func analyzeSleepPatterns() -> AIInsight? {
        let recentSleep = weeklyData.suffix(7).map { $0.sleepHours }
        let avgSleep = recentSleep.reduce(0, +) / Double(recentSleep.count)
        let idealSleep = 14.5
        
        if avgSleep >= idealSleep {
            return AIInsight(
                id: "sleep_excellent",
                icon: "moon.stars.fill",
                title: "Excellent Sleep Pattern",
                description: "\(babyName) is getting \(String(format: "%.1f", avgSleep)) hours of sleep on average. This is optimal for healthy development!",
                type: .positive,
                confidence: 0.94
            )
        } else if avgSleep < idealSleep - 2 {
            return AIInsight(
                id: "sleep_concern",
                icon: "moon.circle.fill",
                title: "Sleep Improvement Needed",
                description: "\(babyName) is getting \(String(format: "%.1f", avgSleep)) hours of sleep. Consider adjusting bedtime routine for better rest.",
                type: .warning,
                confidence: 0.87
            )
        }
        
        return nil
    }
    
    private func analyzeFeedingPatterns() -> AIInsight? {
        let recentFeedings = weeklyData.suffix(7).map { $0.feedings }
        let avgFeedings = Double(recentFeedings.reduce(0, +)) / Double(recentFeedings.count)
        let consistency = calculateConsistency(recentFeedings.map { Double($0) })
        
        if consistency > 0.8 && avgFeedings >= 7 {
            return AIInsight(
                id: "feeding_optimal",
                icon: "drop.fill",
                title: "Perfect Feeding Rhythm",
                description: "Your feeding schedule is very consistent with \(String(format: "%.1f", avgFeedings)) feeds per day. Great job!",
                type: .positive,
                confidence: 0.91
            )
        }
        
        return nil
    }
    
    private func predictNextMilestone() -> AIInsight? {
        let completedCount = milestones.filter { $0.isCompleted }.count
        let totalCount = milestones.count
        let completionRate = Double(completedCount) / Double(totalCount)
        
        if let nextMilestone = milestones.first(where: { !$0.isCompleted }) {
            let daysOld = Calendar.current.dateComponents([.day], from: babyBirthDate, to: Date()).day ?? 0
            let weeksOld = daysOld / 7
            
            return AIInsight(
                id: "milestone_prediction",
                icon: "star.fill",
                title: "Next Milestone Prediction",
                description: "Based on current development, \(nextMilestone.title.lowercased()) may occur within the next 2-4 weeks!",
                type: .exciting,
                confidence: min(0.95, completionRate + 0.2)
            )
        }
        
        return nil
    }
    
    private func analyzeMoodPatterns() -> AIInsight? {
        let recentActivities = recentActivities.prefix(20)
        let moodCounts = Dictionary(grouping: recentActivities, by: { $0.mood })
            .mapValues { $0.count }
        
        let totalActivities = recentActivities.count
        let happyRatio = Double(moodCounts[.happy] ?? 0) / Double(totalActivities)
        
        if happyRatio > 0.7 {
            return AIInsight(
                id: "mood_excellent",
                icon: "face.smiling.fill",
                title: "Very Happy Baby",
                description: "\(babyName) has been happy in \(Int(happyRatio * 100))% of recent activities. You're doing an amazing job!",
                type: .positive,
                confidence: 0.88
            )
        } else if happyRatio < 0.3 {
            return AIInsight(
                id: "mood_attention",
                icon: "face.dashed.fill",
                title: "Mood Needs Attention",
                description: "\(babyName) seems fussy lately. Consider checking for growth spurts or schedule adjustments.",
                type: .warning,
                confidence: 0.75
            )
        }
        
        return nil
    }
    
    private func analyzeGrowthTrends() -> AIInsight? {
        guard growthData.count >= 3 else { return nil }
        
        let recentGrowth = growthData.suffix(3)
        let weightGain = recentGrowth.last!.weight - recentGrowth.first!.weight
        let timeSpan = Calendar.current.dateComponents([.month], 
                                                      from: recentGrowth.first!.date, 
                                                      to: recentGrowth.last!.date).month ?? 1
        
        let monthlyWeightGain = weightGain / Double(max(timeSpan, 1))
        
        if monthlyWeightGain >= 0.5 && monthlyWeightGain <= 1.0 {
            return AIInsight(
                id: "growth_healthy",
                icon: "chart.line.uptrend.xyaxis",
                title: "Healthy Growth Rate",
                description: "\(babyName) is gaining \(String(format: "%.1f", monthlyWeightGain)) kg per month. This is perfect for their age!",
                type: .positive,
                confidence: 0.92
            )
        }
        
        return nil
    }
    
    private func calculateConsistency(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        // Normalize to 0-1 scale (lower deviation = higher consistency)
        return max(0, 1 - (standardDeviation / mean))
    }
    
    private func updateDevelopmentScore() {
        let completedMilestones = milestones.filter { $0.isCompleted }.count
        let totalMilestones = milestones.count
        let baseScore = Int(Double(completedMilestones) / Double(totalMilestones) * 100)
        
        // Adjust based on age appropriateness
        let daysOld = Calendar.current.dateComponents([.day], from: babyBirthDate, to: Date()).day ?? 0
        let monthsOld = daysOld / 30
        
        // Bonus for early milestones, penalty for delayed ones
        var adjustedScore = baseScore
        if monthsOld < 8 && completedMilestones > 4 {
            adjustedScore += 10 // Early achiever bonus
        } else if monthsOld > 10 && completedMilestones < 3 {
            adjustedScore -= 5 // Gentle adjustment for delayed milestones
        }
        
        developmentScore = min(100, max(0, adjustedScore))
    }
    
    func predictNextActivity() -> ActivityType? {
        guard !recentActivities.isEmpty else { return .feeding }
        
        let now = Date()
        let lastActivity = recentActivities.first!
        let timeSinceLastActivity = now.timeIntervalSince(lastActivity.time) / 3600 // hours
        
        // Smart prediction based on patterns and time
        switch lastActivity.type {
        case .feeding:
            if timeSinceLastActivity > 2.5 {
                return .diaper
            }
        case .pumping:
            if timeSinceLastActivity > 1 {
                return .feeding // After pumping, suggest feeding
            }
        case .diaper:
            if timeSinceLastActivity > 1 {
                return .activity
            }
        case .sleep:
            if timeSinceLastActivity > 0.5 {
                return .feeding
            }
        case .activity:
            if timeSinceLastActivity > 1.5 {
                return .feeding
            }
        case .milestone:
            return .activity // Celebrate with activity time
        case .growth:
            return .feeding // After growth tracking, suggest feeding
        }
        
        // Default prediction based on time of day
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 6...9, 12...13, 17...18: return .feeding
        case 10...11, 14...16: return .activity
        case 19...22: return .sleep
        default: return .diaper
        }
    }
    
    func getSmartSuggestions() -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Time-based suggestions
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        
        if let lastActivity = recentActivities.first {
            let timeSinceLastActivity = now.timeIntervalSince(lastActivity.time) / 3600 // hours
            
            // Feeding suggestion
            if timeSinceLastActivity > 3 && lastActivity.type != .feeding {
                suggestions.append(SmartSuggestion(
                    id: "feeding_time",
                    icon: "drop.fill",
                    title: "Feeding Time",
                    description: "It's been \(Int(timeSinceLastActivity)) hours since last feeding",
                    action: "Log Feeding",
                    priority: .high
                ))
            }
            
            // Tummy time suggestion
            let lastTummyTime = recentActivities.first { $0.type == .activity && $0.details.lowercased().contains("tummy") }
            if let lastTummy = lastTummyTime {
                let timeSinceTummy = now.timeIntervalSince(lastTummy.time) / 3600
                if timeSinceTummy > 3 {
                    suggestions.append(SmartSuggestion(
                        id: "tummy_time",
                        icon: "figure.strengthtraining.traditional",
                        title: "Tummy Time",
                        description: "Important for motor development",
                        action: "Start Session",
                        priority: .medium
                    ))
                }
            }
        }
        
        // Milestone-based suggestions
        if let nextMilestone = milestones.first(where: { !$0.isCompleted }) {
            suggestions.append(SmartSuggestion(
                id: "milestone_activity",
                icon: "star.circle.fill",
                title: "Milestone Practice",
                description: "Activities to help with \(nextMilestone.title.lowercased())",
                action: "Get Ideas",
                priority: .medium
            ))
        }
        
        // Photo memory suggestion
        if Calendar.current.isDateInToday(Date()) {
            let todayActivities = recentActivities.filter { Calendar.current.isDateInToday($0.time) }
            if todayActivities.count > 3 && !todayActivities.contains(where: { $0.notes?.contains("photo") ?? false }) {
                suggestions.append(SmartSuggestion(
                    id: "photo_memory",
                    icon: "camera.fill",
                    title: "Capture Today",
                    description: "Document this special day",
                    action: "Take Photo",
                    priority: .low
                ))
            }
        }
        
        return suggestions
    }
    
    // MARK: - History Methods
    
    func getActivities(for date: Date) -> [TotsActivity] {
        let calendar = Calendar.current
        return recentActivities.filter { activity in
            calendar.isDate(activity.time, inSameDayAs: date)
        }
    }
    
    func getStatsForDate(_ date: Date) -> DayStats {
        let activities = getActivities(for: date)
        
        let feedings = activities.filter { $0.type == .feeding }.count
        let diapers = activities.filter { $0.type == .diaper }.count
        
        let sleepActivities = activities.filter { $0.type == .sleep }
        let sleepHours = Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
        
        let tummyTimeActivities = activities.filter { $0.type == .activity && $0.details.contains("Tummy") }
        let tummyTime = tummyTimeActivities.compactMap { $0.duration }.reduce(0, +)
        
        return DayStats(
            feedings: feedings,
            sleepHours: sleepHours,
            diapers: diapers,
            tummyTime: tummyTime
        )
    }
    
    // MARK: - Countdown Methods
    
    func updateCountdowns() {
        let now = Date()
        
        // Calculate next feeding time
        if let lastFeeding = recentActivities.first(where: { $0.type == .feeding }) {
            let averageFeedingInterval: TimeInterval = 3 * 3600 // 3 hours
            let nextFeeding = lastFeeding.time.addingTimeInterval(averageFeedingInterval)
            nextFeedingTime = nextFeeding
            nextFeedingCountdown = max(0, nextFeeding.timeIntervalSince(now))
        } else {
            // Default to 2 minutes from now for demo purposes to see seconds timer
            let defaultNextFeeding = now.addingTimeInterval(2 * 60)
            nextFeedingTime = defaultNextFeeding
            nextFeedingCountdown = max(0, defaultNextFeeding.timeIntervalSince(now))
        }
        
        // Calculate next diaper change
        if let lastDiaper = recentActivities.first(where: { $0.type == .diaper }) {
            let averageDiaperInterval: TimeInterval = 2.5 * 3600 // 2.5 hours
            let nextDiaper = lastDiaper.time.addingTimeInterval(averageDiaperInterval)
            nextDiaperTime = nextDiaper
            nextDiaperCountdown = max(0, nextDiaper.timeIntervalSince(now))
        } else {
            // Default to 3 minutes from now for demo purposes to see seconds timer
            let defaultNextDiaper = now.addingTimeInterval(3 * 60)
            nextDiaperTime = defaultNextDiaper
            nextDiaperCountdown = max(0, defaultNextDiaper.timeIntervalSince(now))
        }
        
    }
    
    func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateCountdowns()
            }
        }
    }
    
    func formatCountdown(_ timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "Now"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Now"
        }
    }
    
    func formatCountdownWithSeconds(_ timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "DUE"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct TotsActivity: Identifiable, Codable {
    let id = UUID()
    let type: ActivityType
    let time: Date
    let details: String
    let mood: BabyMood
    let duration: Int? // in minutes
    let notes: String?
    let weight: Double? // in pounds
    let height: Double? // in inches
    
    init(type: ActivityType, time: Date, details: String, mood: BabyMood = .neutral, duration: Int? = nil, notes: String? = nil, weight: Double? = nil, height: Double? = nil) {
        self.type = type
        self.time = time
        self.details = details
        self.mood = mood
        self.duration = duration
        self.notes = notes
        self.weight = weight
        self.height = height
    }
}

enum ActivityType: String, CaseIterable, Codable {
    case feeding = "🍼"
    case pumping = "PumpingIcon"
    case diaper = "DiaperIcon"
    case sleep = "moon.zzz.fill"
    case milestone = "🎉"
    case activity = "🧸"
    case growth = "📏"
    
    var name: String {
        switch self {
        case .feeding: return "Feeding"
        case .pumping: return "Pumping"
        case .diaper: return "Diaper"
        case .sleep: return "Sleep"
        case .milestone: return "Milestone"
        case .activity: return "Activity"
        case .growth: return "Growth"
        }
    }
    
        var color: Color {
            switch self {
            case .feeding: return .pink
            case .pumping: return .cyan
            case .diaper: return .orange
            case .sleep: return .purple
            case .milestone: return .purple
            case .activity: return .green
            case .growth: return .blue
            }
        }
    
    var gradientColors: [Color] {
        switch self {
        case .feeding: return [.pink, .red]
        case .pumping: return [.cyan, .blue]
        case .diaper: return [.orange, .yellow]
        case .sleep: return [.indigo, .blue]
        case .milestone: return [.purple, .pink]
        case .activity: return [.green, .mint]
        case .growth: return [.blue, .cyan]
        }
    }
}

enum ActivitySubType: String, CaseIterable, Codable {
    case tummyTime = "🤸‍♂️"
    case bathTime = "🛁"
    case storyTime = "📖"
    case screenTime = "📱"
    case outdoorTime = "🌳"
    case playTime = "🧸"
    case musicTime = "🎵"
    case artTime = "🎨"
    
    var name: String {
        switch self {
        case .tummyTime: return "Tummy Time"
        case .bathTime: return "Bath Time"
        case .storyTime: return "Story Time"
        case .screenTime: return "Screen Time"
        case .outdoorTime: return "Outdoor Time"
        case .playTime: return "Play Time"
        case .musicTime: return "Music Time"
        case .artTime: return "Art Time"
        }
    }
    
    var color: Color {
        switch self {
        case .tummyTime: return .green
        case .bathTime: return .blue
        case .storyTime: return .purple
        case .screenTime: return .orange
        case .outdoorTime: return .green
        case .playTime: return .yellow
        case .musicTime: return .pink
        case .artTime: return .red
        }
    }
}

enum BabyMood: String, CaseIterable, Codable {
    case happy = "😊"
    case content = "😌"
    case sleepy = "😴"
    case fussy = "😫"
    case curious = "🤔"
    case neutral = "😐"
    
    var name: String {
        switch self {
        case .happy: return "Happy"
        case .content: return "Content"
        case .sleepy: return "Sleepy"
        case .fussy: return "Fussy"
        case .curious: return "Curious"
        case .neutral: return "Neutral"
        }
    }
    
    var color: Color {
        switch self {
        case .happy: return .yellow
        case .content: return .green
        case .sleepy: return .blue
        case .fussy: return .red
        case .curious: return .orange
        case .neutral: return .gray
        }
    }
}

struct DayData: Identifiable {
    let id = UUID()
    let day: String
    let date: Date
    let feedings: Int
    let diapers: Int
    let sleepHours: Double
    let tummyTime: Int // minutes
    let playTime: Int // minutes
}

struct Milestone: Identifiable, Codable {
    let id = UUID()
    let title: String
    var isCompleted: Bool
    var completedDate: Date?
    let minAgeWeeks: Int // Minimum age in weeks
    let maxAgeWeeks: Int // Maximum age in weeks  
    let category: MilestoneCategory
    let description: String
    let isPredefined: Bool
    
    init(title: String, isCompleted: Bool = false, completedDate: Date? = nil, minAgeWeeks: Int, maxAgeWeeks: Int, category: MilestoneCategory, description: String, isPredefined: Bool = false) {
        self.title = title
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.minAgeWeeks = minAgeWeeks
        self.maxAgeWeeks = maxAgeWeeks
        self.category = category
        self.description = description
        self.isPredefined = isPredefined
    }
    
    var expectedAgeRange: String {
        if minAgeWeeks == maxAgeWeeks {
            return "\(minAgeWeeks) weeks"
        } else if minAgeWeeks < 52 && maxAgeWeeks < 52 {
            return "\(minAgeWeeks)-\(maxAgeWeeks) weeks"
        } else {
            let minMonths = minAgeWeeks / 4
            let maxMonths = maxAgeWeeks / 4
            if minMonths == maxMonths {
                return "\(minMonths) months"
            } else {
                return "\(minMonths)-\(maxMonths) months"
            }
        }
    }
    
    func isRelevantForAge(weeks: Int) -> Bool {
        // Show milestones that are within 4 weeks of being due, or overdue
        return weeks >= (minAgeWeeks - 4) && weeks <= (maxAgeWeeks + 8)
    }
}

enum MilestoneCategory: String, CaseIterable, Codable {
    case motor = "Motor Skills"
    case language = "Language & Communication"
    case social = "Social & Emotional"
    case cognitive = "Cognitive & Learning"
    case physical = "Physical Growth"
    case feeding = "Feeding & Eating"
    case sleep = "Sleep & Routine"
    case sensory = "Sensory Development"
    
    var icon: String {
        switch self {
        case .motor: return "figure.walk"
        case .language: return "bubble.left.and.text.bubble.right.fill"
        case .social: return "heart.2.fill"
        case .cognitive: return "brain.head.profile.fill"
        case .physical: return "ruler.fill"
        case .feeding: return "fork.knife"
        case .sleep: return "moon.zzz.fill"
        case .sensory: return "eye.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .motor: return .blue
        case .language: return .green
        case .social: return .pink
        case .cognitive: return .purple
        case .physical: return .orange
        case .feeding: return .red
        case .sleep: return .indigo
        case .sensory: return .yellow
        }
    }
}

struct GrowthEntry: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let weight: Double // kg
    let height: Double // cm
    let headCircumference: Double // cm
}

struct BabyWord: Identifiable, Codable {
    let id = UUID()
    var word: String
    var category: WordCategory
    let dateFirstSaid: Date
    var notes: String
    
    init(word: String, category: WordCategory = .other, dateFirstSaid: Date = Date(), notes: String = "") {
        self.word = word
        self.category = category
        self.dateFirstSaid = dateFirstSaid
        self.notes = notes
    }
}

enum WordCategory: String, CaseIterable, Codable {
    case people = "People"
    case animals = "Animals"
    case food = "Food"
    case actions = "Actions"
    case objects = "Objects"
    case feelings = "Feelings"
    case sounds = "Sounds"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .people: return "person.2.fill"
        case .animals: return "pawprint.fill"
        case .food: return "fork.knife"
        case .actions: return "figure.run"
        case .objects: return "cube.box.fill"
        case .feelings: return "heart.fill"
        case .sounds: return "speaker.wave.2.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .people: return .blue
        case .animals: return .brown
        case .food: return .green
        case .actions: return .orange
        case .objects: return .gray
        case .feelings: return .pink
        case .sounds: return .purple
        case .other: return .secondary
        }
    }
}

// MARK: - Live Activity Attributes
public struct TotsLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic properties that change during the activity
        public var todayFeedings: Int
        public var todaySleepHours: Double
        public var todayDiapers: Int
        public var todayTummyTime: Int
        public var lastUpdateTime: Date
        
        // Timer countdowns for next activities
        public var nextFeedingTime: Date?
        public var nextDiaperTime: Date?
        public var nextTummyTime: Date?
        
        public init(todayFeedings: Int, todaySleepHours: Double, todayDiapers: Int, todayTummyTime: Int, lastUpdateTime: Date, nextFeedingTime: Date? = nil, nextDiaperTime: Date? = nil, nextTummyTime: Date? = nil) {
            self.todayFeedings = todayFeedings
            self.todaySleepHours = todaySleepHours
            self.todayDiapers = todayDiapers
            self.todayTummyTime = todayTummyTime
            self.lastUpdateTime = lastUpdateTime
            self.nextFeedingTime = nextFeedingTime
            self.nextDiaperTime = nextDiaperTime
            self.nextTummyTime = nextTummyTime
        }
    }

    // Fixed properties for the activity
    public var babyName: String
    public var feedingGoal: Int
    public var sleepGoal: Double
    public var diaperGoal: Int
    public var tummyTimeGoal: Int
    
    public init(babyName: String, feedingGoal: Int, sleepGoal: Double, diaperGoal: Int, tummyTimeGoal: Int) {
        self.babyName = babyName
        self.feedingGoal = feedingGoal
        self.sleepGoal = sleepGoal
        self.diaperGoal = diaperGoal
        self.tummyTimeGoal = tummyTimeGoal
    }
}

// MARK: - Live Activity Management
extension TotsDataManager {
    func startLiveActivity() {
        // Check if Live Activities are supported on this device
        #if targetEnvironment(simulator)
        print("Live Activities are not supported in the iOS Simulator")
        return
        #endif
        
        let authInfo = ActivityAuthorizationInfo()
        print("Live Activity authorization status: \(authInfo.areActivitiesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            print("Live Activities are not enabled. User needs to enable in Settings → Face ID & Passcode → Live Activities")
            return
        }
        
        // Check if activity is already running
        if currentActivity != nil {
            updateLiveActivity()
            return
        }
        
        let attributes = TotsLiveActivityAttributes(
            babyName: babyName,
            feedingGoal: 8,
            sleepGoal: 15.0,
            diaperGoal: 6,
            tummyTimeGoal: 60
        )
        
        let initialState = TotsLiveActivityAttributes.ContentState(
            todayFeedings: todayFeedings,
            todaySleepHours: todaySleepHours,
            todayDiapers: todayDiapers,
            todayTummyTime: todayTummyTime,
            lastUpdateTime: Date(),
            nextFeedingTime: nextFeedingTime,
            nextDiaperTime: nextDiaperTime,
            nextTummyTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            print("✅ Started Live Activity: \(activity.id)")
            print("🔒 Lock your device to see the Live Activity on the lock screen")
        } catch {
            print("Failed to start Live Activity: \(error)")
            print("Error details: \(error.localizedDescription)")
            
            // Handle common error cases
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("unsupported") {
                print("Live Activities are not supported on this device")
            } else if errorString.contains("denied") {
                print("Live Activities permission denied - check Settings")
            } else if errorString.contains("disabled") {
                print("Live Activities are disabled in Settings")
            }
        }
    }
    
    func updateLiveActivity() {
        guard let activity = currentActivity else { return }
        
        let updatedState = TotsLiveActivityAttributes.ContentState(
            todayFeedings: todayFeedings,
            todaySleepHours: todaySleepHours,
            todayDiapers: todayDiapers,
            todayTummyTime: todayTummyTime,
            lastUpdateTime: Date(),
            nextFeedingTime: nextFeedingTime,
            nextDiaperTime: nextDiaperTime,
            nextTummyTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
        )
        
        Task {
            await activity.update(
                ActivityContent(
                    state: updatedState,
                    staleDate: nil
                )
            )
        }
    }
    
    func stopLiveActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            await MainActor.run {
                currentActivity = nil
            }
        }
    }
    
    // MARK: - CloudKit Family Sharing
    
    func enableFamilySharing() async throws {
        let goals = BabyGoals(
            feeding: weeklyFeedingGoal / 7,
            sleep: weeklySleepGoal / 7.0,
            diaper: weeklyDiaperGoal / 7
        )
        
        babyProfileRecord = try await cloudKitManager.createBabyProfile(
            name: babyName,
            birthDate: babyBirthDate,
            goals: goals
        )
        
        familySharingEnabled = true
        UserDefaults.standard.set(true, forKey: "family_sharing_enabled")
        UserDefaults.standard.set(babyProfileRecord!.recordID.recordName, forKey: "baby_profile_record_id")
    }
    
    func shareBabyProfile() async throws -> CKShare? {
        guard let profileRecord = babyProfileRecord else { 
            print("❌ No baby profile record found to share")
            return nil 
        }
        
        print("🔄 Attempting to share profile: \(profileRecord.recordID.recordName)")
        
        do {
            let share = try await cloudKitManager.shareBabyProfile(profileRecord)
            print("✅ Share created successfully")
            
            await cloudKitManager.setActiveShare(share)
            
            // Enable family sharing
            await MainActor.run {
                self.familySharingEnabled = true
                UserDefaults.standard.set(true, forKey: "family_sharing_enabled")
            }
            
            return share
        } catch {
            print("❌ Failed to share profile: \(error)")
            throw error
        }
    }
    
    func stopSharingProfile() async throws {
        guard let profileRecord = babyProfileRecord else { return }
        try await cloudKitManager.stopSharingProfile(profileRecord)
        
        await cloudKitManager.setActiveShare(nil)
    }
    
    func fetchFamilyMembers() async throws -> [FamilyMember] {
        guard let share = await cloudKitManager.activeShare else { return [] }
        return try await cloudKitManager.fetchFamilyMembers(for: share)
    }
    
    // MARK: - Account Management
    
    func signOut() async {
        print("🚪 TotsDataManager: Starting sign out process")
        await cloudKitManager.signOut()
        
        await MainActor.run {
            // Reset all local data
            self.recentActivities = []
            self.milestones = []
            self.growthData = []
            self.babyName = "Baby"
            self.babyBirthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
            self.babyProfileRecord = nil
            self.familySharingEnabled = false
            
            // Stop any running live activities
            self.stopLiveActivity()
            
            // Trigger app to show onboarding
            self.shouldShowOnboarding = true
            
            print("🚪 TotsDataManager: Local data reset complete")
        }
    }
    
    func deleteAccount() async throws {
        print("🗑️ TotsDataManager: Starting account deletion process")
        
        // Delete from CloudKit first
        try await cloudKitManager.deleteAccount()
        
        await MainActor.run {
            // Clear all local data
            self.recentActivities = []
            self.milestones = []
            self.growthData = []
            self.babyName = "Baby"
            self.babyBirthDate = Calendar.current.date(byAdding: .month, value: -8, to: Date()) ?? Date()
            self.babyProfileRecord = nil
            self.familySharingEnabled = false
            
            // Stop any running live activities
            self.stopLiveActivity()
            
            // Trigger app to show onboarding
            self.shouldShowOnboarding = true
            
            print("🗑️ TotsDataManager: Account deletion complete")
        }
    }
    
    func syncFromCloudKit() async {
        guard let profileRecord = babyProfileRecord else { 
            print("⚠️ No baby profile record available for syncing")
            return 
        }
        
        print("🔄 Starting CloudKit activity sync for profile: \(profileRecord.recordID.recordName)")
        
        do {
            let cloudActivities = try await cloudKitManager.fetchActivities(for: profileRecord.recordID)
            print("🔄 Found \(cloudActivities.count) activities in CloudKit")
            
            await MainActor.run {
                let originalCount = self.recentActivities.count
                
                // Merge cloud activities with local ones
                for cloudActivity in cloudActivities {
                    if !self.recentActivities.contains(where: { $0.id == cloudActivity.id }) {
                        self.recentActivities.append(cloudActivity)
                        print("✅ Added activity: \(cloudActivity.type.rawValue) at \(cloudActivity.time)")
                    }
                }
                
                // Sort activities by time (most recent first)
                self.recentActivities.sort { $0.time > $1.time }
                
                let newCount = self.recentActivities.count
                print("✅ Activities sync complete: \(originalCount) → \(newCount) total activities")
                
                self.updateCountdowns()
                self.updateLiveActivity()
            }
        } catch {
            print("❌ Failed to sync from CloudKit: \(error)")
        }
    }
    
    private func loadBabyProfileRecord(recordName: String) async {
        do {
            let recordID = CKRecord.ID(recordName: recordName)
            let record = try await cloudKitManager.fetchBabyProfile(recordID: recordID)
            await MainActor.run {
                self.babyProfileRecord = record
                print("✅ Baby profile record loaded successfully")
            }
        } catch {
            print("❌ Failed to load baby profile record: \(error)")
        }
    }
    
    func loadExistingBabyProfile() async {
        print("🔄 TotsDataManager: Starting loadExistingBabyProfile...")
        
        // First check if we have a stored record ID (for existing installations)
        if let recordName = UserDefaults.standard.string(forKey: "baby_profile_record_id") {
            print("🍼 Found saved baby profile record ID: \(recordName)")
            await loadBabyProfileRecord(recordName: recordName)
            return
        }
        
        // If no stored record ID, try to fetch existing profiles from CloudKit
        print("🔍 No stored record ID found, searching CloudKit for existing baby profiles...")
        do {
            let profiles = try await cloudKitManager.fetchBabyProfiles()
            print("🔍 TotsDataManager: CloudKit returned \(profiles.count) profiles")
            
            if let mostRecentProfile = profiles.first {
                await MainActor.run {
                    self.babyProfileRecord = mostRecentProfile
                    // Store the record ID for future use
                    UserDefaults.standard.set(mostRecentProfile.recordID.recordName, forKey: "baby_profile_record_id")
                    
                    // Update local data with CloudKit data
                    if let name = mostRecentProfile["name"] as? String {
                        print("🔄 Setting baby name from CloudKit: \(name)")
                        self.babyName = name
                        print("✅ Baby name updated to: \(self.babyName)")
                    }
                    if let birthDate = mostRecentProfile["birthDate"] as? Date {
                        print("🔄 Setting baby birth date from CloudKit: \(birthDate)")
                        self.babyBirthDate = birthDate
                        print("✅ Baby birth date updated to: \(self.babyBirthDate)")
                    }
                    
                    // Load goals from CloudKit
                    if let feedingGoal = mostRecentProfile["feedingGoal"] as? Int {
                        UserDefaults.standard.set(feedingGoal, forKey: "feeding_goal")
                    }
                    if let sleepGoal = mostRecentProfile["sleepGoal"] as? Double {
                        UserDefaults.standard.set(sleepGoal, forKey: "sleep_goal")
                    }
                    if let diaperGoal = mostRecentProfile["diaperGoal"] as? Int {
                        UserDefaults.standard.set(diaperGoal, forKey: "diaper_goal")
                    }
                    
                    print("✅ Found existing baby profile: \(self.babyName)")
                    print("🔄 Updated local data with CloudKit profile and goals")
                }
                
                // Also sync activities from CloudKit
                await syncFromCloudKit()
            } else {
                print("📝 No existing baby profiles found in CloudKit")
            }
        } catch {
            print("❌ Failed to fetch baby profiles from CloudKit: \(error)")
        }
    }
    
    private func createDefaultBabyProfile() async {
        do {
            // Use default values if not set
            let name = babyName.isEmpty ? "Baby" : babyName
            let birthDate = babyBirthDate
            let goals = BabyGoals(
                feeding: weeklyFeedingGoal / 7,
                sleep: weeklySleepGoal / 7.0,
                diaper: weeklyDiaperGoal / 7
            )
            
            let record = try await cloudKitManager.createBabyProfile(
                name: name,
                birthDate: birthDate,
                goals: goals
            )
            
            await MainActor.run {
                self.babyProfileRecord = record
                UserDefaults.standard.set(record.recordID.recordName, forKey: "baby_profile_record_id")
                print("✅ Default baby profile created and saved")
            }
        } catch {
            print("❌ Failed to create default baby profile: \(error)")
        }
    }
    
    func checkCloudKitSchema() async {
        let status = await schemaSetup.checkSchemaStatus()
        print(status.description)
        
        if !status.allExist {
            print("⚠️ CloudKit schema not complete. Attempting automatic setup...")
            
            // Try to create schema automatically
            do {
                try await schemaSetup.createSampleRecordsForSchema()
                print("✅ Schema created automatically!")
            } catch {
                print("❌ Automatic schema creation failed: \(error)")
                print("\n" + String(repeating: "=", count: 60))
                print("🔧 MANUAL CLOUDKIT SETUP REQUIRED")
                print(String(repeating: "=", count: 60))
                schemaSetup.printSchemaInstructions()
                print("\n💡 KEY ISSUE: The 'createdBy' field must be a REFERENCE type, not String!")
                print("   1. Go to CloudKit Console")
                print("   2. Delete any existing 'createdBy' fields that are String type") 
                print("   3. Add new 'createdBy' field as Reference to Users")
                print("   4. Do the same for 'babyProfile' field in Activity (Reference to BabyProfile)")
                print(String(repeating: "=", count: 60))
            }
        }
    }
}

