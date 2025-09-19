import Foundation
import SwiftUI
import ActivityKit
import CloudKit

class TotsDataManager: ObservableObject {
    // MARK: - Storage Keys
    private let activitiesKey = "tots_activities"
    private let milestonesKey = "tots_milestones"
    private let growthDataKey = "tots_growth_data"
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
    @Published var widgetEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(widgetEnabled, forKey: "widget_enabled")
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
    @Published var nextSleepCountdown: TimeInterval = 0
    @Published var nextFeedingTime: Date?
    @Published var nextDiaperTime: Date?
    @Published var nextSleepTime: Date?
    
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
    
    var currentWeight: Double {
        growthData.last?.weight ?? 14.2
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
        widgetEnabled = UserDefaults.standard.object(forKey: "widget_enabled") as? Bool ?? true
        
        // Load activities
        if let data = UserDefaults.standard.data(forKey: activitiesKey),
           let activities = try? JSONDecoder().decode([TotsActivity].self, from: data) {
            recentActivities = activities.sorted { $0.time > $1.time }
        }
        
        // Load milestones
        if let data = UserDefaults.standard.data(forKey: milestonesKey),
           let milestones = try? JSONDecoder().decode([Milestone].self, from: data) {
            self.milestones = milestones
        } else {
            // Initialize with default milestones if none exist
            initializeDefaultMilestones()
        }
        
        // Load growth data
        if let data = UserDefaults.standard.data(forKey: growthDataKey),
           let growth = try? JSONDecoder().decode([GrowthEntry].self, from: data) {
            growthData = growth
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
    
    private func initializeDefaultMilestones() {
        milestones = [
            Milestone(title: "First Smile", expectedAge: "6-8 weeks", category: .social, description: "First genuine social smile"),
            Milestone(title: "Holds Head Up", expectedAge: "2-4 months", category: .motor, description: "Can hold head steady when upright"),
            Milestone(title: "First Tooth", expectedAge: "6-10 months", category: .physical, description: "First tooth has broken through"),
            Milestone(title: "Sits Without Support", expectedAge: "6-8 months", category: .motor, description: "Can sit upright without falling over"),
            Milestone(title: "Says First Word", expectedAge: "8-12 months", category: .language, description: "First recognizable word like 'mama' or 'dada'"),
            Milestone(title: "Crawls", expectedAge: "7-10 months", category: .motor, description: "Moves forward on hands and knees"),
            Milestone(title: "Pulls to Stand", expectedAge: "9-12 months", category: .motor, description: "Pulls themselves up to standing position"),
        ]
    }
    
    private func calculateStats() {
        totalActivitiesLogged = recentActivities.count
        
        // Calculate streak (consecutive days with activities)
        var streak = 0
        let calendar = Calendar.current
        var currentDate = Date()
        
        while true {
            let hasActivityOnDate = recentActivities.contains { activity in
                calendar.isDate(activity.time, inSameDayAs: currentDate)
            }
            
            if hasActivityOnDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        streakCount = streak
        
        // Update today's stats
        let today = Date()
        let todayActivities = recentActivities.filter { calendar.isDate($0.time, inSameDayAs: today) }
        
        todayFeedings = todayActivities.filter { $0.type == .feeding }.count
        todayDiapers = todayActivities.filter { $0.type == .diaper }.count
        todayMilestones = todayActivities.filter { $0.type == .milestone }.count
        
        let sleepActivities = todayActivities.filter { $0.type == .sleep }
        todaySleepHours = Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
        
        let tummyActivities = todayActivities.filter { $0.type == .play && $0.details.lowercased().contains("tummy") }
        todayTummyTime = tummyActivities.compactMap { $0.duration }.reduce(0, +)
        
        let playActivities = todayActivities.filter { $0.type == .play && !$0.details.lowercased().contains("tummy") }
        todayPlayTime = playActivities.compactMap { $0.duration }.reduce(0, +)
        
        // Update weekly data based on real activities
        updateWeeklyData()
        
        // Save widget data
        saveWidgetData()
    }
    
    private func updateWeeklyData() {
        let calendar = Calendar.current
        let today = Date()
        
        weeklyData = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayActivities = recentActivities.filter { calendar.isDate($0.time, inSameDayAs: date) }
            
            let feedings = dayActivities.filter { $0.type == .feeding }.count
            let diapers = dayActivities.filter { $0.type == .diaper }.count
            
            let sleepActivities = dayActivities.filter { $0.type == .sleep }
            let sleepHours = Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
            
            let tummyActivities = dayActivities.filter { $0.type == .play && $0.details.lowercased().contains("tummy") }
            let tummyTime = tummyActivities.compactMap { $0.duration }.reduce(0, +)
            
            let playActivities = dayActivities.filter { $0.type == .play && !$0.details.lowercased().contains("tummy") }
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
    
    private func updateTodayStats(for activity: TotsActivity) {
        switch activity.type {
        case .feeding:
            todayFeedings += 1
        case .diaper:
            todayDiapers += 1
        case .sleep:
            todaySleepHours += Double(activity.duration ?? 90) / 60.0
        case .milestone:
            todayMilestones += 1
        case .play:
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
        case .diaper:
            if timeSinceLastActivity > 1 {
                return .play
            }
        case .sleep:
            if timeSinceLastActivity > 0.5 {
                return .feeding
            }
        case .play:
            if timeSinceLastActivity > 1.5 {
                return .feeding
            }
        case .milestone:
            return .play // Celebrate with play time
        case .growth:
            return .feeding // After growth tracking, suggest feeding
        }
        
        // Default prediction based on time of day
        let hour = Calendar.current.component(.hour, from: now)
        switch hour {
        case 6...9, 12...13, 17...18: return .feeding
        case 10...11, 14...16: return .play
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
            let lastTummyTime = recentActivities.first { $0.type == .play && $0.details.lowercased().contains("tummy") }
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
        
        let tummyTimeActivities = activities.filter { $0.type == .play && $0.details.contains("Tummy") }
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
            nextFeedingTime = now
            nextFeedingCountdown = 0
        }
        
        // Calculate next diaper change
        if let lastDiaper = recentActivities.first(where: { $0.type == .diaper }) {
            let averageDiaperInterval: TimeInterval = 2.5 * 3600 // 2.5 hours
            let nextDiaper = lastDiaper.time.addingTimeInterval(averageDiaperInterval)
            nextDiaperTime = nextDiaper
            nextDiaperCountdown = max(0, nextDiaper.timeIntervalSince(now))
        } else {
            nextDiaperTime = now
            nextDiaperCountdown = 0
        }
        
        // Calculate next sleep time
        if let lastSleep = recentActivities.first(where: { $0.type == .sleep }) {
            let averageSleepInterval: TimeInterval = 2 * 3600 // 2 hours
            let nextSleep = lastSleep.time.addingTimeInterval(averageSleepInterval)
            nextSleepTime = nextSleep
            nextSleepCountdown = max(0, nextSleep.timeIntervalSince(now))
        } else {
            nextSleepTime = now
            nextSleepCountdown = 0
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
    case diaper = "DiaperIcon"
    case sleep = "moon.zzz.fill"
    case milestone = "🎉"
    case play = "🧸"
    case growth = "📏"
    
    var name: String {
        switch self {
        case .feeding: return "Feeding"
        case .diaper: return "Diaper"
        case .sleep: return "Sleep"
        case .milestone: return "Milestone"
        case .play: return "Tummy Time"
        case .growth: return "Growth"
        }
    }
    
        var color: Color {
            switch self {
            case .feeding: return .pink
            case .diaper: return .orange
            case .sleep: return .purple
            case .milestone: return .purple
            case .play: return .green
            case .growth: return .blue
            }
        }
    
    var gradientColors: [Color] {
        switch self {
        case .feeding: return [.pink, .red]
        case .diaper: return [.orange, .yellow]
        case .sleep: return [.indigo, .blue]
        case .milestone: return [.purple, .pink]
        case .play: return [.green, .mint]
        case .growth: return [.blue, .cyan]
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
    let expectedAge: String
    let category: MilestoneCategory
    let description: String
    
    init(title: String, isCompleted: Bool = false, completedDate: Date? = nil, expectedAge: String, category: MilestoneCategory, description: String) {
        self.title = title
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.expectedAge = expectedAge
        self.category = category
        self.description = description
    }
}

enum MilestoneCategory: String, CaseIterable, Codable {
    case motor = "Motor Skills"
    case language = "Language"
    case social = "Social"
    case cognitive = "Cognitive"
    case physical = "Physical"
    
    var icon: String {
        switch self {
        case .motor: return "figure.walk"
        case .language: return "message.fill"
        case .social: return "heart.fill"
        case .cognitive: return "brain.head.profile"
        case .physical: return "ruler.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .motor: return .blue
        case .language: return .green
        case .social: return .pink
        case .cognitive: return .purple
        case .physical: return .orange
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
        public var nextSleepTime: Date?
        public var nextTummyTime: Date?
        
        public init(todayFeedings: Int, todaySleepHours: Double, todayDiapers: Int, todayTummyTime: Int, lastUpdateTime: Date, nextFeedingTime: Date? = nil, nextDiaperTime: Date? = nil, nextSleepTime: Date? = nil, nextTummyTime: Date? = nil) {
            self.todayFeedings = todayFeedings
            self.todaySleepHours = todaySleepHours
            self.todayDiapers = todayDiapers
            self.todayTummyTime = todayTummyTime
            self.lastUpdateTime = lastUpdateTime
            self.nextFeedingTime = nextFeedingTime
            self.nextDiaperTime = nextDiaperTime
            self.nextSleepTime = nextSleepTime
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
            nextSleepTime: nextSleepTime,
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
            nextSleepTime: nextSleepTime,
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

