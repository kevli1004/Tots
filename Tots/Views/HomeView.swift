import SwiftUI

// MARK: - Liquid Glass Effects
extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 20, shadowRadius: CGFloat = 10) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 4)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct LiquidBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.4),
                Color.purple.opacity(0.35),
                Color.pink.opacity(0.3),
                Color.orange.opacity(0.35)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var showingDatePicker = false
    @State private var selectedHistoryDate = Date()
    @State private var showingActivitySelector = false
    @State private var showingAddActivity = false
    @State private var showingTrackingGoals = false
    @State private var selectedActivityType: ActivityType = .feeding
    @State private var selectedFeedingType: AddActivityView.FeedingType?
    @State private var editingActivity: TotsActivity?
    @State private var selectedSummaryPeriod: SummaryPeriod = .today
    @State private var goalsUpdateTrigger = false
    
    // MARK: - Computed Properties for Weekly Data
    private var weeklyFeedings: Int {
        return dataManager.weeklyData.reduce(0) { $0 + $1.feedings }
    }
    
    private var weeklySleepHours: Double {
        return dataManager.weeklyData.reduce(0) { $0 + $1.sleepHours }
    }
    
    private var weeklyDiapers: Int {
        return dataManager.weeklyData.reduce(0) { $0 + $1.diapers }
    }
    
    private var weeklyTummyTime: Int {
        return dataManager.weeklyData.reduce(0) { $0 + $1.tummyTime }
    }
    
    // MARK: - Computed Properties for Monthly Data
    private var monthlyFeedings: Int {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let monthlyActivities = dataManager.recentActivities.filter { 
            $0.time >= thirtyDaysAgo && $0.type == .feeding 
        }
        return monthlyActivities.count
    }
    
    private var monthlySleepHours: Double {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let sleepActivities = dataManager.recentActivities.filter { 
            $0.time >= thirtyDaysAgo && $0.type == .sleep 
        }
        return Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
    }
    
    private var monthlyDiapers: Int {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let monthlyActivities = dataManager.recentActivities.filter { 
            $0.time >= thirtyDaysAgo && $0.type == .diaper 
        }
        return monthlyActivities.count
    }
    
    private var monthlyTummyTime: Int {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let tummyActivities = dataManager.recentActivities.filter { 
            $0.time >= thirtyDaysAgo && $0.type == .activity && $0.details.lowercased().contains("tummy")
        }
        return tummyActivities.compactMap { $0.duration }.reduce(0, +)
    }
    
    // Monthly goals (calculated based on daily goals * 30)
    private var monthlyFeedingGoal: Int { 
        let _ = goalsUpdateTrigger // Force dependency on trigger
        let dailyGoal = UserDefaults.standard.double(forKey: "feeding_goal")
        return Int(dailyGoal == 0 ? 8.0 : dailyGoal) * 30 
    }
    private var monthlySleepGoal: Double { 
        let _ = goalsUpdateTrigger // Force dependency on trigger
        let dailyGoal = UserDefaults.standard.double(forKey: "sleep_goal")
        return (dailyGoal == 0 ? 15.0 : dailyGoal) * 30 
    }
    private var monthlyDiaperGoal: Int { 
        let _ = goalsUpdateTrigger // Force dependency on trigger
        let dailyGoal = UserDefaults.standard.double(forKey: "diaper_goal")
        return Int(dailyGoal == 0 ? 6.0 : dailyGoal) * 30 
    }
    private var monthlyTummyTimeGoal: Int { 60 * 30 } // Keep tummy time as is for now
    
    // Daily goals from settings
    private var dailyFeedingGoal: Int {
        let _ = goalsUpdateTrigger // Force dependency on trigger
        let goal = UserDefaults.standard.double(forKey: "feeding_goal")
        return Int(goal == 0 ? 8.0 : goal)
    }
    
    private var dailySleepGoal: Double {
        let _ = goalsUpdateTrigger // Force dependency on trigger
        let goal = UserDefaults.standard.double(forKey: "sleep_goal")
        return goal == 0 ? 15.0 : goal
    }
    
    private var dailyDiaperGoal: Int {
        let _ = goalsUpdateTrigger // Force dependency on trigger
        let goal = UserDefaults.standard.double(forKey: "diaper_goal")
        return Int(goal == 0 ? 6.0 : goal)
    }
    
    // MARK: - Daily Data for Weekly View
    private var dailyDataForWeek: [DayProgressData] {
        let calendar = Calendar.current
        let today = calendar.dateInterval(of: .day, for: Date())?.start ?? Date()
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dayActivities = dataManager.recentActivities.filter { calendar.isDate($0.time, inSameDayAs: date) }
            
            let feedings = dayActivities.filter { $0.type == .feeding }.count
            let diapers = dayActivities.filter { $0.type == .diaper }.count
            let sleepActivities = dayActivities.filter { $0.type == .sleep }
            let sleepHours = Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
            let tummyActivities = dayActivities.filter { $0.type == .activity && $0.details.lowercased().contains("tummy") }
            let tummyTime = tummyActivities.compactMap { $0.duration }.reduce(0, +)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let dayString = formatter.string(from: date)
            
            return DayProgressData(
                day: dayString,
                date: date,
                feedings: feedings,
                diapers: diapers,
                sleepHours: sleepHours,
                tummyTime: tummyTime
            )
        }.reversed()
    }
    
    // MARK: - Weekly Data for Monthly View
    private var weeklyDataForMonth: [WeekProgressData] {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the past 4 weeks of data
        return (0..<4).compactMap { weekOffset in
            // Calculate the start and end of each week
            let weekStartDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: calendar.startOfDay(for: today))!
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStartDate)
            
            guard let interval = weekInterval else { return nil }
            
            let weekActivities = dataManager.recentActivities.filter { activity in
                interval.contains(activity.time)
            }
            
            let feedings = weekActivities.filter { $0.type == .feeding }.count
            let diapers = weekActivities.filter { $0.type == .diaper }.count
            let sleepActivities = weekActivities.filter { $0.type == .sleep }
            let sleepHours = Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
            let tummyActivities = weekActivities.filter { $0.type == .activity && $0.details.lowercased().contains("tummy") }
            let tummyTime = tummyActivities.compactMap { $0.duration }.reduce(0, +)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let weekLabel = "Week of \(formatter.string(from: interval.start))"
            
            return WeekProgressData(
                weekLabel: weekLabel,
                startDate: interval.start,
                feedings: feedings,
                diapers: diapers,
                sleepHours: sleepHours,
                tummyTime: tummyTime
            )
        }.reversed()
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Liquid animated background
                    LiquidBackground()
                    
                    ScrollView {
                        VStack(spacing: 12) {
                        // Ad Banner
                        AdBannerContainerWide()
                        
                        // Countdown timers
                        countdownView
                        
                        // Ongoing sessions
                        ongoingSessionsView
                        
                        // Today's summary with goals
                        todaySummaryWithGoalsView
                        
                        // Recent activities
                        recentActivitiesView
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
                    customTitleView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingDatePicker = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingActivitySelector = true
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
        .navigationViewStyle(StackNavigationViewStyle())
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GoalsUpdated"))) { _ in
            // Trigger view refresh when goals are updated
            goalsUpdateTrigger.toggle()
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerHistoryView(selectedDate: $selectedHistoryDate)
        }
        .sheet(isPresented: $showingAddActivity) {
            if let editingActivity = editingActivity {
                AddActivityView(editingActivity: editingActivity)
            } else {
                AddActivityView(preselectedType: selectedActivityType, preselectedFeedingType: selectedFeedingType)
            }
        }
        .sheet(isPresented: $showingTrackingGoals) {
            TrackingGoalsView()
                .environmentObject(dataManager)
        }
        .onChange(of: showingAddActivity) { isShowing in
            if !isShowing {
                editingActivity = nil
                selectedFeedingType = nil
            }
        }
        .overlay(
            // Sleek Activity Selector Overlay
            Group {
                if showingActivitySelector {
                    ZStack {
                        // Enhanced background overlay with blur effect
                        Color.black.opacity(0.4)
                            .background(.ultraThinMaterial)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    showingActivitySelector = false
                                }
                            }
                        
                    // Enhanced Activity selector card
                    VStack(spacing: 0) {
                        // Enhanced Header with better visual hierarchy
                        VStack(spacing: 16) {
                            // Close button centered at top
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        showingActivitySelector = false
                                    }
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .frame(width: 32, height: 32)
                                        .background(Color(.systemGray6))
                                        .clipShape(Circle())
                                }
                                .offset(x: 8, y: -8)
                            }
                            
                            // Title section
                            VStack(spacing: 8) {
                                Text("Add Activity")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Choose what you'd like to track")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                            
                            // Activity options
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                ForEach([ActivityType.feeding, .pumping, .diaper, .sleep, .activity, .growth], id: \.self) { type in
                                    Button(action: {
                                        selectedActivityType = type
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            showingActivitySelector = false
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            showingAddActivity = true
                                        }
                                    }) {
                                        VStack(spacing: 16) {
                                            // Enhanced icon presentation with background circle
                                            ZStack {
                                                Circle()
                                                    .fill(type.color.opacity(0.2))
                                                    .frame(width: 56, height: 56)
                                                
                                                if type == .sleep {
                                                    Image(systemName: "moon.zzz.fill")
                                                        .font(.system(size: 24, weight: .medium))
                                                        .foregroundColor(type.color)
                                                } else if type == .milestone {
                                                    Image(systemName: "figure.child")
                                                        .font(.system(size: 24, weight: .medium))
                                                        .foregroundColor(type.color)
                                                } else if type.rawValue == "DiaperIcon" || type.rawValue == "PumpingIcon" {
                                                    Image(type.rawValue)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 28, height: 28)
                                                        .foregroundColor(type.color)
                                                } else {
                                                    Text(type.rawValue)
                                                        .font(.system(size: 28))
                                                }
                                            }
                                            
                                            VStack(spacing: 4) {
                                                Text(type.name)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.primary)
                                            }
                                            .multilineTextAlignment(.center)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 120)
                                        .background(
                                            RoundedRectangle(cornerRadius: 24)
                                                .fill(Color(.systemBackground))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 24)
                                                        .stroke(type.color.opacity(0.15), lineWidth: 2)
                                                )
                                        )
                                        .shadow(color: type.color.opacity(0.15), radius: 12, x: 0, y: 6)
                                        .scaleEffect(1.0)
                                    }
                                    .buttonStyle(ActivityButtonStyle())
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(.thickMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 32)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .shadow(color: .black.opacity(0.08), radius: 40, x: 0, y: 20)
                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 16)
                        .scaleEffect(showingActivitySelector ? 1.0 : 0.95)
                        .opacity(showingActivitySelector ? 1.0 : 0.0)
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
                }
            }
        )
    }
    
    private var countdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming Activities")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                // Show feed card only if breastfeeding is not active
                if !isBreastfeedingActive {
                CountdownCard(
                    icon: "🍼",
                    title: "Feed",
                    countdownInterval: dataManager.nextFeedingCountdown,
                    time: dataManager.nextFeedingTime,
                    color: .pink
                )
                .environmentObject(dataManager)
                    .onTapGesture {
                        selectedActivityType = .feeding
                        showingAddActivity = true
                    }
                }
                
                CountdownCard(
                    icon: "DiaperIcon",
                    title: "Diaper",
                    countdownInterval: dataManager.nextDiaperCountdown,
                    time: dataManager.nextDiaperTime,
                    color: .orange
                )
                .environmentObject(dataManager)
                .onTapGesture {
                    selectedActivityType = .diaper
                    showingAddActivity = true
                }
                
                // Show pumping cards if pumping has been done before and not currently active
                if hasPumpingHistory && !isPumpingActive {
                    CountdownCard(
                        icon: "PumpingIcon",
                        title: "Pumping",
                        countdownInterval: dataManager.nextPumpingCountdown,
                        time: dataManager.nextPumpingTime,
                        color: .blue
                    )
                    .environmentObject(dataManager)
                    .onTapGesture {
                        selectedActivityType = .pumping
                        showingAddActivity = true
                    }
                }
            }
        }
    }
    
    private var ongoingSessionsView: some View {
        Group {
            if hasOngoingSessions {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Current Activities")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        if isBreastfeedingActive {
                            OngoingSessionCard(
                                title: "Breastfeeding",
                                icon: "🤱",
                                startTime: breastfeedingStartTime,
                                color: .pink
                            ) {
                                selectedActivityType = .feeding
                                selectedFeedingType = .breastfeeding
                                showingAddActivity = true
                            }
                        }
                        
                        if isLeftPumpingActive {
                            OngoingSessionCard(
                                title: "Left Pumping",
                                icon: "PumpingIcon",
                                startTime: leftPumpingStartTime,
                                color: .blue
                            ) {
                                selectedActivityType = .pumping
                                showingAddActivity = true
                            }
                        }
                        
                        if isRightPumpingActive {
                            OngoingSessionCard(
                                title: "Right Pumping",
                                icon: "PumpingIcon",
                                startTime: rightPumpingStartTime,
                                color: .purple
                            ) {
                                selectedActivityType = .pumping
                                showingAddActivity = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Ongoing Session State
    private var hasOngoingSessions: Bool {
        isBreastfeedingActive || isLeftPumpingActive || isRightPumpingActive
    }
    
    private var isBreastfeedingActive: Bool {
        UserDefaults.standard.bool(forKey: "breastfeedingIsRunning")
    }
    
    private var isLeftPumpingActive: Bool {
        UserDefaults.standard.bool(forKey: "leftPumpingIsRunning")
    }
    
    private var isRightPumpingActive: Bool {
        UserDefaults.standard.bool(forKey: "rightPumpingIsRunning")
    }
    
    private var isPumpingActive: Bool {
        isLeftPumpingActive || isRightPumpingActive
    }
    
    private var breastfeedingStartTime: Date? {
        UserDefaults.standard.object(forKey: "breastfeedingStartTime") as? Date
    }
    
    private var leftPumpingStartTime: Date? {
        UserDefaults.standard.object(forKey: "leftPumpingStartTime") as? Date
    }
    
    private var rightPumpingStartTime: Date? {
        UserDefaults.standard.object(forKey: "rightPumpingStartTime") as? Date
    }
    
    // MARK: - Pumping Countdown Logic
    private var hasPumpingHistory: Bool {
        !dataManager.recentActivities.filter { $0.type == .pumping }.isEmpty
    }
    
    private var lastPumpingTime: Date? {
        dataManager.recentActivities
            .filter { $0.type == .pumping }
            .sorted { $0.time > $1.time }
            .first?.time
    }
    
    // Removed local pumping countdown logic - now using dataManager.nextPumpingCountdown and dataManager.nextPumpingTime
    
    // MARK: - Timer Activity Creation
    private func createBreastfeedingActivityFromTimer() -> TotsActivity {
        let elapsed = breastfeedingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let minutes = Int(elapsed / 60)
        let seconds = Int(elapsed) % 60
        let details = "Breastfeeding - \(minutes)m \(seconds)s"
        
        return TotsActivity(
            type: .feeding,
            time: breastfeedingStartTime ?? Date(),
            details: details,
            mood: .content,
            duration: minutes,
            notes: nil
        )
    }
    
    private func createPumpingActivityFromTimer() -> TotsActivity {
        let leftElapsed = leftPumpingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let rightElapsed = rightPumpingStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        let leftMinutes = Int(leftElapsed / 60)
        let leftSeconds = Int(leftElapsed) % 60
        let rightMinutes = Int(rightElapsed / 60)
        let rightSeconds = Int(rightElapsed) % 60
        let totalMinutes = Int((leftElapsed + rightElapsed) / 60)
        let totalSeconds = Int(leftElapsed + rightElapsed) % 60
        
        let details = "Left: \(leftMinutes)m \(leftSeconds)s, Right: \(rightMinutes)m \(rightSeconds)s, Total: \(totalMinutes)m \(totalSeconds)s"
        
        return TotsActivity(
            type: .pumping,
            time: leftPumpingStartTime ?? rightPumpingStartTime ?? Date(),
            details: details,
            mood: .content,
            duration: totalMinutes,
            notes: nil
        )
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                    Text("Hi there! 👋")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Today is \(dataManager.babyName)'s \(getDaysOld()) day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("\(dataManager.streakCount) day streak")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                }
            }
        }
    }
    
    private var todaySummaryWithGoalsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
            Text("Summary & Goals")
                .font(.headline)
                .fontWeight(.semibold)
                
                Spacer()
                
                Button("Update Tracking Goals") {
                    showingTrackingGoals = true
                }
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
                .fontWeight(.medium)
            }
            
            // Swipeable TabView for different summary layouts
            TabView(selection: $selectedSummaryPeriod) {
                todaySummaryContent
                    .tag(SummaryPeriod.today)
                    .padding(.horizontal, 8) // Add padding to prevent cutoff
                
                weeklySummaryContent
                    .tag(SummaryPeriod.week)
                    .padding(.horizontal, 8)
                
                monthlySummaryContent
                    .tag(SummaryPeriod.month)
                    .padding(.horizontal, 8)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 320) // Increased height significantly for better content display
            
            // Centered dots indicator at bottom
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(Array(SummaryPeriod.allCases.enumerated()), id: \.offset) { index, period in
                        Circle()
                            .fill(selectedSummaryPeriod == period ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: selectedSummaryPeriod)
                    }
                }
                Spacer()
            }
        }
    }
    
    
    private var todaySummaryContent: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            SummaryGoalCard(
                icon: "🍼",
                title: "Feedings",
                current: dataManager.todayFeedings,
                goal: dailyFeedingGoal,
                color: .pink,
                onSettingsTap: { showingTrackingGoals = true }
            )
            
            SummaryGoalCard(
                icon: "moon.zzz.fill",
                title: "Sleep",
                current: dataManager.todaySleepHours,
                goal: dailySleepGoal,
                color: .purple,
                unit: "h",
                onSettingsTap: { showingTrackingGoals = true }
            )
            
            SummaryGoalCard(
                icon: "DiaperIcon",
                title: "Diapers",
                current: dataManager.todayDiapers,
                goal: dailyDiaperGoal,
                color: .white,
                onSettingsTap: { showingTrackingGoals = true }
            )
            
            SummaryGoalCard(
                icon: "🧸",
                title: "Tummy Time",
                current: dataManager.todayTummyTime,
                goal: 60,
                color: .green,
                unit: "m",
                onSettingsTap: { showingTrackingGoals = true }
            )
        }
    }
    
    private var weeklySummaryContent: some View {
        VStack(spacing: 12) {
            SimpleBarChart(
                title: "Daily Activity This Week",
                data: dailyDataForWeek,
                isWeekly: true
            )
        }
        .padding(.vertical, 8)
    }
    
    private var monthlySummaryContent: some View {
        VStack(spacing: 12) {
            if weeklyDataForMonth.isEmpty || weeklyDataForMonth.allSatisfy({ $0.feedings == 0 && $0.diapers == 0 && $0.sleepHours == 0 && $0.tummyTime == 0 }) {
                VStack(spacing: 8) {
                    Text("No Data Available")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("Start tracking activities to see monthly trends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
            } else {
                SimpleBarChart(
                    title: "Weekly Activity This Month",
                    data: weeklyDataForMonth,
                    isWeekly: false
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    
    private var horizontalHistoryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Days")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingDatePicker = true
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(recentDays, id: \.self) { date in
                        HorizontalDayCard(date: date)
                            .environmentObject(dataManager)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var recentDays: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()),
               let normalizedDate = calendar.dateInterval(of: .day, for: date)?.start {
                dates.append(normalizedDate)
            }
        }
        
        return dates
    }
    
    private var recentActivitiesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activities")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                    Button("View All") {
                        showingDatePicker = true
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
            
            VStack(spacing: 12) {
                ForEach(dataManager.recentActivities.prefix(5)) { activity in
                    ActivityRow(activity: activity) {
                        // Edit action
                        editingActivity = activity
                        showingAddActivity = true
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            deleteActivity(activity)
                        }
                    }
                }
            }
        }
    }
    
    private func deleteActivity(_ activity: TotsActivity) {
        dataManager.deleteActivity(activity)
    }
    
    private func getDaysOld() -> Int {
        Calendar.current.dateComponents([.day], from: dataManager.babyBirthDate, to: Date()).day ?? 0
    }
    
    private var customTitleView: some View {
        let calendar = Calendar.current
        let now = Date()
        let birthDate = dataManager.babyBirthDate
        let babyName = dataManager.babyName.isEmpty ? "Baby" : dataManager.babyName
        
        let ageComponents = calendar.dateComponents([.year, .month, .day], from: birthDate, to: now)
        let years = ageComponents.year ?? 0
        let months = ageComponents.month ?? 0
        
        return VStack(spacing: 2) {
            Text(babyName)
                .font(.title2)
                .fontWeight(.bold)
            
            if years >= 1 {
                // More than 1 year: show age in smaller text
                if months > 0 {
                    Text("\(years)y \(months)m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(years)y")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Less than 1 year: show days old
                let totalDays = calendar.dateComponents([.day], from: birthDate, to: now).day ?? 0
                Text("\(totalDays) days old")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func getTitleText() -> String {
        let calendar = Calendar.current
        let now = Date()
        let birthDate = dataManager.babyBirthDate
        let babyName = dataManager.babyName.isEmpty ? "Baby" : dataManager.babyName
        
        let ageComponents = calendar.dateComponents([.year, .month, .day], from: birthDate, to: now)
        let years = ageComponents.year ?? 0
        let months = ageComponents.month ?? 0
        let days = ageComponents.day ?? 0
        
        if years >= 1 {
            // More than 1 year: show "Name (1y 2m)" with smaller year text
            if months > 0 {
                return "\(babyName)"
            } else {
                return "\(babyName)"
            }
        } else {
            // Less than 1 year: show "Name (45 days old)"
            let totalDays = calendar.dateComponents([.day], from: birthDate, to: now).day ?? 0
            return "\(babyName) (\(totalDays) days old)"
        }
    }
}

// MARK: - Supporting Views

struct CountdownCard: View {
    let icon: String
    let title: String
    let countdownInterval: TimeInterval
    let time: Date?
    let color: Color
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var isFlashing = false
    @State private var isFlipped = false
    
    private var timeString: String {
        guard let time = time else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    private var isDiaperIcon: Bool {
        return icon == "DiaperIcon"
    }
    
    private var isPumpingIcon: Bool {
        return icon == "PumpingIcon"
    }
    
    private var countdownText: String {
        if isFirstTime {
            switch title.lowercased() {
            case "feed":
                return "Log Feeding"
            case "diaper":
                return "Log Diaper"
            case "pumping":
                return "Log Pumping"
            default:
                return "Start Logging"
            }
        }
        return dataManager.formatCountdown(countdownInterval)
    }
    
    private var isDue: Bool {
        return countdownInterval <= 0
    }
    
    private var isFirstTime: Bool {
        // Check if this is the first time for this activity type
        switch title.lowercased() {
        case "feed":
            return dataManager.recentActivities.filter { $0.type == .feeding }.isEmpty
        case "diaper":
            return dataManager.recentActivities.filter { $0.type == .diaper }.isEmpty
        case "pumping":
            return dataManager.recentActivities.filter { $0.type == .pumping }.isEmpty
        default:
            return false
        }
    }
    
    private var dueText: String {
        if isFirstTime {
            switch title.lowercased() {
            case "feed":
                return "START FIRST FEED"
            case "diaper":
                return "START FIRST DIAPER"
            case "pumping":
                return "START FIRST PUMP"
            default:
                return "START"
            }
        } else {
            return "DUE"
        }
    }
    
    var body: some View {
        ZStack {
            // Front side - Countdown
            if !isFlipped {
                VStack(spacing: 10) {
                    // Icon section
            if icon.contains(".") {
                Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    } else if isDiaperIcon || isPumpingIcon {
                        Image(icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    } else {
                        Text(icon)
                            .font(.title2)
                    }
                    
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    VStack(spacing: 2) {
                        if isDue {
                            Text(dueText)
                                .font(isFirstTime ? .caption2 : .headline)
                                .fontWeight(.bold)
                                .foregroundColor(isFirstTime ? color : .red)
                                .multilineTextAlignment(.center)
                        } else {
                            Text(countdownText)
                                .font(isFirstTime ? .subheadline : .headline)
                                .fontWeight(.bold)
                                .foregroundColor(color)
                            
                            if !isFirstTime {
                                Text("until next \(title.lowercased())")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
            // Back side - Activity Details
            else {
                VStack(spacing: 14) {
                    // Same icon but smaller
                    if icon.contains(".") {
                        Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            } else if isDiaperIcon || isPumpingIcon {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
            } else {
                Text(icon)
                    .font(.title2)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
                    VStack(spacing: 8) {
                        // Today's stats specific to activity type
                        if title.lowercased() == "feed" {
                            // Feeding stats
                            HStack(spacing: 16) {
                                VStack(spacing: 2) {
                                    Text("Today")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(getTodayActualFeedings())")
                                        .font(.title2)
                                        .fontWeight(.bold)
                .foregroundColor(color)
                                    Text("feeds")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(spacing: 2) {
                                    Text("Estimated")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(getTodayRealisticOz()) oz")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(color)
                                    Text("consumed")
                    .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Calories estimate
                            Text("\(getTodayRealisticOz() * 20) calories")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                                
                        } else {
                            // Diaper stats breakdown
                            VStack(spacing: 6) {
                                Text("Today's Diapers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    VStack(spacing: 2) {
                                        Text("\(getTodayPooDiapers())")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.brown)
                                        Text("poo")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(spacing: 2) {
                                        Text("\(getTodayPeeDiapers())")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        Text("pee")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    VStack(spacing: 2) {
                                        Text("\(getTodayMixedDiapers())")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.purple)
                                        Text("mixed")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Text("Total: \(dataManager.todayDiapers)")
                                    .font(.caption)
                                    .foregroundColor(color)
                    .fontWeight(.medium)
                            }
                        }
                        
                        // Last activity time
                        if let lastActivityTime = getLastActivityTime() {
                            Text("Last \(title.lowercased()): \(lastActivityTime)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120) // Reduced height for 3-column layout
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 4)
        )
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 1.0
        )
        .onChange(of: isDue) { newValue in
            if newValue {
                isFlashing = true
            } else {
                isFlashing = false
            }
        }
    }
    
    private func getLastActivityTime() -> String? {
        let activityType: ActivityType
        switch title.lowercased() {
        case "feed":
            activityType = .feeding
        case "diaper":
            activityType = .diaper
        default:
            return nil
        }
        
        if let lastActivity = dataManager.recentActivities.first(where: { $0.type == activityType }) {
            let timeAgo = Date().timeIntervalSince(lastActivity.time)
            let hours = Int(timeAgo) / 3600
            let minutes = Int(timeAgo) % 3600 / 60
            
            if hours > 0 {
                return "\(hours)h \(minutes)m ago"
            } else {
                return "\(minutes)m ago"
            }
        }
        return nil
    }
    
    private func getAverageInterval() -> String {
        switch title.lowercased() {
        case "feed":
            return "3 hours"
        case "diaper":
            return "2.5 hours"
        default:
            return "N/A"
        }
    }
    
    private func getTodayOz() -> Int {
        // Use the dataManager's todayFeedings count (which includes demo data)
        // Estimate 3-4 oz per feeding for average baby
        return dataManager.todayFeedings * 3
    }
    
    private func getTodayCalories() -> Int {
        // Breast milk/formula has about 20 calories per oz
        return getTodayOz() * 20
    }
    
    private func getTodayActualFeedings() -> Int {
        // Use the dataManager's todayFeedings count for consistency
        return dataManager.todayFeedings
    }
    
    private func getTodayRealisticOz() -> Int {
        // Get actual feeding activities for today
        let today = Calendar.current.dateInterval(of: .day, for: Date())?.start ?? Date()
        let todayFeedingActivities = dataManager.recentActivities.filter { 
            $0.type == .feeding && Calendar.current.isDate($0.time, inSameDayAs: today)
        }
        
        var totalOz = 0
        
        // Extract actual oz amounts from activity details
        for activity in todayFeedingActivities {
            let details = activity.details.lowercased()
            
            // Look for patterns like "4 oz", "3.5 oz", "2oz", etc.
            let ozPattern = #"(\d+(?:\.\d+)?)\s*oz"#
            if let regex = try? NSRegularExpression(pattern: ozPattern),
               let match = regex.firstMatch(in: details, range: NSRange(details.startIndex..., in: details)),
               let range = Range(match.range(at: 1), in: details) {
                if let ozAmount = Double(String(details[range])) {
                    totalOz += Int(ozAmount)
                }
            } else {
                // Fallback to reasonable estimate if no oz found in details
                totalOz += 3
            }
        }
        
        // If no actual activities, fall back to demo calculation
        if todayFeedingActivities.isEmpty {
            return dataManager.todayFeedings * 3
        }
        
        return totalOz
    }
    
    private func getTodayPooDiapers() -> Int {
        // Get today's diaper activities and count those with poo
        let today = Calendar.current.dateInterval(of: .day, for: Date())?.start ?? Date()
        let todayDiaperActivities = dataManager.recentActivities.filter { 
            $0.type == .diaper && Calendar.current.isDate($0.time, inSameDayAs: today)
        }
        
        return todayDiaperActivities.filter { 
            $0.details.lowercased().contains("poo") || $0.details.lowercased().contains("💩") || $0.details.lowercased().contains("dirty")
        }.count
    }
    
    private func getTodayPeeDiapers() -> Int {
        // Get today's diaper activities and count those with only pee
        let today = Calendar.current.dateInterval(of: .day, for: Date())?.start ?? Date()
        let todayDiaperActivities = dataManager.recentActivities.filter { 
            $0.type == .diaper && Calendar.current.isDate($0.time, inSameDayAs: today)
        }
        
        return todayDiaperActivities.filter { activity in
            let details = activity.details.lowercased()
            return (details.contains("pee") || details.contains("💧") || details.contains("wet")) && 
                   !details.contains("poo") && !details.contains("💩") && !details.contains("dirty")
        }.count
    }
    
    private func getTodayMixedDiapers() -> Int {
        // Get today's diaper activities and count those with both
        let today = Calendar.current.dateInterval(of: .day, for: Date())?.start ?? Date()
        let todayDiaperActivities = dataManager.recentActivities.filter { 
            $0.type == .diaper && Calendar.current.isDate($0.time, inSameDayAs: today)
        }
        
        return todayDiaperActivities.filter { activity in
            let details = activity.details.lowercased()
            return (details.contains("mixed") || details.contains("both") || 
                   (details.contains("poo") && details.contains("pee")) ||
                   (details.contains("💩") && details.contains("💧")))
        }.count
    }
    
    // MARK: - Weekly Data Computed Properties
    
    private var weeklyFeedings: Int {
        return dataManager.weeklyData.reduce(0) { $0 + $1.feedings }
    }
    
    private var weeklyDiapers: Int {
        return dataManager.weeklyData.reduce(0) { $0 + $1.diapers }
    }
    
    private var weeklySleepHours: Double {
        return dataManager.weeklyData.reduce(0) { $0 + $1.sleepHours }
    }
    
    private var weeklyTummyTime: Int {
        return dataManager.weeklyData.reduce(0) { $0 + $1.tummyTime }
    }
    
    // MARK: - Monthly Data Computed Properties
    
    private var monthlyFeedings: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return dataManager.recentActivities.filter { activity in
            activity.type == .feeding && activity.time >= startOfMonth
        }.count
    }
    
    private var monthlyDiapers: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return dataManager.recentActivities.filter { activity in
            activity.type == .diaper && activity.time >= startOfMonth
        }.count
    }
    
    private var monthlySleepHours: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let sleepActivities = dataManager.recentActivities.filter { activity in
            activity.type == .sleep && activity.time >= startOfMonth
        }
        
        return Double(sleepActivities.compactMap { $0.duration }.reduce(0, +)) / 60.0
    }
    
    private var monthlyTummyTime: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let tummyActivities = dataManager.recentActivities.filter { activity in
            activity.type == .activity && 
            activity.details.lowercased().contains("tummy") && 
            activity.time >= startOfMonth
        }
        
        return tummyActivities.compactMap { $0.duration }.reduce(0, +)
    }
    
    
    private var monthlyTummyTimeGoal: Int {
        let calendar = Calendar.current
        let now = Date()
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        return daysInMonth * 60 // 60 minutes per day
    }
}

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    private var isDiaperIcon: Bool {
        return icon == "DiaperIcon"
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if icon.contains(".") {
                    // SF Symbol
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                } else if isDiaperIcon {
                    // Custom SVG diaper icon
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                } else {
                    // Regular Emoji
                    Text(icon)
                        .font(.title2)
                }
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                
                Spacer()
            }
        }
        .padding()
        .liquidGlassCard(cornerRadius: 16, shadowRadius: 12)
    }
}

struct SummaryGoalCard: View {
    let icon: String
    let title: String
    let current: Any
    let goal: Any
    let color: Color
    let unit: String
    let onSettingsTap: () -> Void
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var isFlipped = false
    
    init(icon: String, title: String, current: Any, goal: Any, color: Color, unit: String = "", onSettingsTap: @escaping () -> Void = {}) {
        self.icon = icon
        self.title = title
        self.current = current
        self.goal = goal
        self.color = color
        self.unit = unit
        self.onSettingsTap = onSettingsTap
    }
    
    private var isDiaperIcon: Bool {
        return icon == "DiaperIcon"
    }
    
    private var currentValue: String {
        if let intValue = current as? Int {
            return "\(intValue)"
        } else if let doubleValue = current as? Double {
            return String(format: "%.1f", doubleValue)
        }
        return "\(current)"
    }
    
    private var goalValue: String {
        if let intValue = goal as? Int {
            return "\(intValue)"
        } else if let doubleValue = goal as? Double {
            return String(format: "%.0f", doubleValue)
        }
        return "\(goal)"
    }
    
    private var progress: Double {
        let currentDouble: Double
        let goalDouble: Double
        
        if let intValue = current as? Int {
            currentDouble = Double(intValue)
        } else if let doubleValue = current as? Double {
            currentDouble = doubleValue
        } else {
            return 0.0
        }
        
        if let intValue = goal as? Int {
            goalDouble = Double(intValue)
        } else if let doubleValue = goal as? Double {
            goalDouble = doubleValue
        } else {
            return 0.0
        }
        
        return min(currentDouble / goalDouble, 1.0)
    }
    
    // MARK: - Detail Computed Properties
    private var lastFeedingTime: String {
        guard let lastFeeding = dataManager.recentActivities
            .filter({ $0.type == .feeding })
            .sorted(by: { $0.time > $1.time })
            .first else { return "No feedings yet" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lastFeeding.time)
    }
    
    private var averageFeedingInterval: String {
        let feedings = dataManager.recentActivities
            .filter { $0.type == .feeding && Calendar.current.isDateInToday($0.time) }
            .sorted { $0.time < $1.time }
        
        guard feedings.count > 1 else { return "Not enough data" }
        
        var totalInterval: TimeInterval = 0
        for i in 1..<feedings.count {
            totalInterval += feedings[i].time.timeIntervalSince(feedings[i-1].time)
        }
        
        let averageInterval = totalInterval / Double(feedings.count - 1)
        let hours = Int(averageInterval) / 3600
        let minutes = Int(averageInterval.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var lastSleepTime: String {
        guard let lastSleep = dataManager.recentActivities
            .filter({ $0.type == .sleep })
            .sorted(by: { $0.time > $1.time })
            .first else { return "No sleep yet" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lastSleep.time)
    }
    
    private var longestNapToday: String {
        let sleeps = dataManager.recentActivities
            .filter { $0.type == .sleep && Calendar.current.isDateInToday($0.time) }
        
        guard let longestDuration = sleeps.compactMap({ $0.duration }).max() else {
            return "No naps yet"
        }
        
        let hours = longestDuration / 60
        let minutes = longestDuration % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    
    private var lastDiaperTime: String {
        guard let lastDiaper = dataManager.recentActivities
            .filter({ $0.type == .diaper })
            .sorted(by: { $0.time > $1.time })
            .first else { return "No changes yet" }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: lastDiaper.time)
    }
    
    private var wetDiapersToday: Int {
        return dataManager.recentActivities
            .filter { $0.type == .diaper && Calendar.current.isDateInToday($0.time) && $0.details.lowercased().contains("wet") }
            .count
    }
    
    private var dirtyDiapersToday: Int {
        return dataManager.recentActivities
            .filter { $0.type == .diaper && Calendar.current.isDateInToday($0.time) && $0.details.lowercased().contains("dirty") }
            .count
    }
    
    private var tummyTimeSessions: Int {
        return dataManager.recentActivities
            .filter { $0.type == .activity && Calendar.current.isDateInToday($0.time) && $0.details.lowercased().contains("tummy") }
            .count
    }
    
    
    private var remainingTummyTime: String {
        let currentMinutes = current as? Int ?? 0
        let goalMinutes = goal as? Int ?? 0
        let remaining = max(0, goalMinutes - currentMinutes)
        
        return "\(remaining)m"
    }
    
    @ViewBuilder
    private var detailsForActivity: some View {
        switch title.lowercased() {
        case "feedings":
            VStack(spacing: 6) {
                HStack {
                    Text("Last feeding:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(lastFeedingTime)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Average interval:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(averageFeedingInterval)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Progress:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))% of goal")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(progress >= 1.0 ? .green : color)
                }
            }
            
        case "sleep":
            VStack(spacing: 6) {
                HStack {
                    Text("Last sleep:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(lastSleepTime)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Longest nap:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(longestNapToday)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Progress:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))% of goal")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(progress >= 1.0 ? .green : color)
                }
            }
            
        case "diapers":
            VStack(spacing: 6) {
                HStack {
                    Text("Last change:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(lastDiaperTime)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Wet diapers:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(wetDiapersToday)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Dirty diapers:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(dirtyDiapersToday)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
        case "tummy time":
            VStack(spacing: 6) {
                HStack {
                    Text("Sessions today:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(tummyTimeSessions)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Remaining:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(remainingTummyTime)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(progress >= 1.0 ? .green : color)
                }
                
                HStack {
                    Text("Progress:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))% of goal")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(progress >= 1.0 ? .green : color)
                }
            }
            
        default:
            VStack(spacing: 6) {
                HStack {
                    Text("Current:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(currentValue)\(unit)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Goal:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(goalValue)\(unit)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Progress:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(progress >= 1.0 ? .green : color)
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Front side - Current view
            if !isFlipped {
        VStack(spacing: 12) {
            HStack {
                if icon.contains(".") {
                    // SF Symbol
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                } else if isDiaperIcon {
                    // Custom SVG diaper icon
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                } else {
                    // Regular Emoji
                    Text(icon)
                        .font(.title2)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(currentValue)\(unit)")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(goalValue)\(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(color)
                            .frame(width: geometry.size.width * progress, height: 4)
                            .cornerRadius(2)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 4)
                
                        HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                            
                            Spacer()
                            
                            Text("click for details")
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.7))
                                .fontWeight(.medium)
                        }
                    }
                    
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 120, maxHeight: 120)
            }
            // Back side - Detailed view
            else {
                VStack(spacing: 12) {
                    HStack {
                        if icon.contains(".") {
                            Image(systemName: icon)
                                .foregroundColor(color)
                                .font(.title3)
                        } else if isDiaperIcon {
                            Image(icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                        } else {
                            Text(icon)
                                .font(.title3)
                        }
                        
                        Text(title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        detailsForActivity
                        Spacer(minLength: 0)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(minHeight: 120, maxHeight: 120)
                .scaleEffect(x: -1, y: 1) // Fix text mirroring on back side
            }
        }
        .frame(height: 120)
        .padding()
        .liquidGlassCard(cornerRadius: 16, shadowRadius: 12)
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 1.0
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isFlipped.toggle()
            }
        }
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(min(progress, 1.0) * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}


struct ActivityRow: View {
    let activity: TotsActivity
    let onTap: () -> Void
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: activity.time)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activity.type.color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Group {
                        if activity.type.rawValue == "DiaperIcon" || activity.type.rawValue == "PumpingIcon" {
                            // Custom SVG icons
                            Image(activity.type.rawValue)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                .foregroundColor(.white)
                        } else if activity.type.rawValue == "moon.zzz.fill" {
                            // SF Symbol sleep icon
                            Image(systemName: activity.type.rawValue)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        } else {
                            Text(activity.type.rawValue)
                                .font(.caption)
                        }
                    }
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.type.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Cal AI Style History View

struct DatePickerHistoryView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var scrollToDate: Date?
    
    // Generate last 30 days for scrollable history
    private var historyDates: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()),
               let normalizedDate = calendar.dateInterval(of: .day, for: date)?.start {
                dates.append(normalizedDate)
            }
        }
        
        return dates
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Liquid animated background
                    LiquidBackground()
                    
                    VStack(spacing: 0) {
                        // Ad Banner
                        AdBannerContainer()
                    
                    // Horizontal date selector
                    dateScrollerView
                    
                            Divider()
                    
                    // Scrollable multi-day history
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                ForEach(historyDates, id: \.self) { date in
                                    DayHistoryCard(date: date)
                                        .id(date)
                                        .environmentObject(dataManager)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    .onAppear {
                        // Scroll to selected date
                        if let scrollDate = scrollToDate {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(scrollDate, anchor: .top)
                                }
                            }
                        }
                    }
                    .onChange(of: selectedDate) { newDate in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newDate, anchor: .top)
                        }
                    }
                }
                .frame(width: geometry.size.width)
            }
            }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                scrollToDate = selectedDate
            }
        }
    }
    
    private var dateScrollerView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(historyDates, id: \.self) { date in
                        DateScrollItem(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        ) {
                            selectedDate = date
                        }
                        .id(date)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(selectedDate, anchor: .center)
                    }
                }
            }
            .onChange(of: selectedDate) { newDate in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newDate, anchor: .center)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct DateScrollItem: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    private var dayName: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(dayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(dayNumber)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(minWidth: 60)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color(.systemGray) : Color(.systemBackground))
                    .shadow(color: .black.opacity(isSelected ? 0.15 : 0.08), radius: isSelected ? 10 : 8, x: 0, y: isSelected ? 5 : 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DayHistoryCard: View {
    let date: Date
    @EnvironmentObject var dataManager: TotsDataManager
    
    private var activities: [TotsActivity] {
        dataManager.getActivities(for: date)
    }
    
    private var dayStats: DayStats {
        dataManager.getStatsForDate(date)
    }
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !activities.isEmpty {
                        Text("\(activities.count) activities")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Activities timeline
            if activities.isEmpty {
                EmptyDayView()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(activities.sorted(by: { $0.time > $1.time })) { activity in
                        TimelineActivityRow(activity: activity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    
    private var isDiaperIcon: Bool {
        return icon == "DiaperIcon"
    }
    
    private var isSFSymbol: Bool {
        return icon.contains(".")
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if isDiaperIcon {
                // Custom SVG diaper icon
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundColor(.white)
            } else if isSFSymbol {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.white)
            } else {
                Text(icon)
                    .font(.caption2)
            }
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .liquidGlassCard(cornerRadius: 16, shadowRadius: 12)
    }
}

struct TimelineActivityRow: View {
    let activity: TotsActivity
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: activity.time)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            Text(timeString)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .trailing)
            
            // Activity indicator
            Circle()
                .fill(activity.type.color)
                .frame(width: 8, height: 8)
            
            // Activity content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if activity.type.rawValue == "DiaperIcon" || activity.type.rawValue == "PumpingIcon" {
                        Image(activity.type.rawValue)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)
                            .foregroundColor(.primary)
                    } else if activity.type.rawValue == "moon.zzz.fill" {
                        // SF Symbol sleep icon
                        Image(systemName: activity.type.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                    } else {
                        Text(activity.type.rawValue)
                            .font(.caption2)
                    }
                    
                    Text(activity.type.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if !activity.details.isEmpty {
                    Text(activity.details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                if let notes = activity.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

struct EmptyDayView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("No activities recorded")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemBackground))
            .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Horizontal Day Card

struct HorizontalDayCard: View {
    let date: Date
    @EnvironmentObject var dataManager: TotsDataManager
    
    private var activities: [TotsActivity] {
        dataManager.getActivities(for: date)
    }
    
    private var dayStats: DayStats {
        dataManager.getStatsForDate(date)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Date header
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(dayNumber)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            // Activity summary
            if activities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "moon.zzz")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("No activities")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(height: 60)
            } else {
                VStack(spacing: 8) {
                    // Activity count
                    Text("\(activities.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("activities")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.3)
                    
                    // Quick stats
                    HStack(spacing: 8) {
                        if dayStats.feedings > 0 {
                            Text("\(dayStats.feedings)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        if dayStats.diapers > 0 {
                            Text("·")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(dayStats.diapers)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        if dayStats.sleepHours > 0 {
                            Text("·")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", dayStats.sleepHours))h")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .frame(width: 80)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

struct ActivityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Milestones View

struct MilestonesView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var selectedAgeGroup: AgeGroup = .all
    @State private var showingAddMilestone = false
    @State private var searchText = ""
    
    enum AgeGroup: String, CaseIterable {
        case all = "All"
        case newborn = "0-3 months"
        case infant = "3-6 months"
        case mobileBaby = "6-12 months"
        case toddler = "12-24 months"
        case preschooler = "2+ years"
        
        var icon: String {
            switch self {
            case .all: return "line.horizontal.3"
            case .newborn: return "heart.fill"
            case .infant: return "face.smiling.fill"
            case .mobileBaby: return "figure.crawl"
            case .toddler: return "figure.walk"
            case .preschooler: return "figure.run"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .newborn: return .pink
            case .infant: return .green
            case .mobileBaby: return .orange
            case .toddler: return .purple
            case .preschooler: return .red
            }
        }
        
        var ageRange: (min: Int, max: Int) {
            switch self {
            case .all: return (0, 999)
            case .newborn: return (0, 12)  // 0-3 months
            case .infant: return (12, 24)  // 3-6 months
            case .mobileBaby: return (24, 52)  // 6-12 months
            case .toddler: return (52, 104)  // 12-24 months
            case .preschooler: return (104, 999)  // 2+ years
            }
        }
    }
    
    var filteredMilestones: [Milestone] {
        let relevantMilestones = dataManager.getRelevantMilestones()
        
        let ageFiltered = selectedAgeGroup == .all ? 
            relevantMilestones : 
            relevantMilestones.filter { milestone in
                let ageRange = selectedAgeGroup.ageRange
                return milestone.minAgeWeeks >= ageRange.min && milestone.maxAgeWeeks <= ageRange.max
            }
        
        if searchText.isEmpty {
            return ageFiltered
        } else {
            return ageFiltered.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var completedCount: Int {
        filteredMilestones.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Liquid animated background with tap gesture for keyboard dismissal
                    LiquidBackground()
                        .onTapGesture {
                            // Dismiss keyboard when tapping background
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    
                    VStack(spacing: 16) {
                        // Ad Banner
                        AdBannerContainerMedium()
                        
                        // Header with stats
                        headerView
                        
                        // Age group selector
                        ageGroupSelector
                    
                    // Search bar
                    searchBar
                    
                    // Milestones list
                    milestonesList
                }
                .padding(.top, 16)
                .frame(width: geometry.size.width)
            }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    milestonesTitleView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMilestone = true
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
            .sheet(isPresented: $showingAddMilestone) {
                ImprovedAddMilestoneView()
                    .environmentObject(dataManager)
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside search field
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var milestonesTitleView: some View {
        VStack(spacing: 2) {
            Text("Milestones")
                .font(.title2)
                .fontWeight(.bold)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your baby is \(dataManager.getBabyAgeFormatted())")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("\(completedCount) of \(filteredMilestones.count) milestones")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: filteredMilestones.isEmpty ? 0 : Double(completedCount) / Double(filteredMilestones.count))
                        .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: completedCount)
                    
                    Text("\(Int((filteredMilestones.isEmpty ? 0 : Double(completedCount) / Double(filteredMilestones.count)) * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
    }
    
    private var ageGroupSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AgeGroup.allCases, id: \.self) { ageGroup in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedAgeGroup = ageGroup
                        }
                    }) {
                        HStack(spacing: 6) {
                            if ageGroup == .all {
                                Image(systemName: ageGroup.icon)
                                    .font(.caption)
                            }
                            Text(ageGroup.rawValue)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedAgeGroup == ageGroup ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedAgeGroup == ageGroup ? ageGroup.color : Color(.systemGray6))
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search milestones...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var milestonesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Top anchor for scrolling
                    Color.clear
                        .frame(height: 0)
                        .id("milestonesTop")
                    
                if filteredMilestones.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("No milestones yet")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Text("Add custom milestones to track your baby's development")
                                .font(.subheadline)
                                .foregroundColor(.secondary.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Add First Milestone") {
                            showingAddMilestone = true
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.vertical, 60)
                } else {
                    // Group milestones by age ranges for better organization
                    let groupedMilestones = Dictionary(grouping: filteredMilestones) { milestone in
                        getAgeGroupForMilestone(milestone)
                    }
                    
                    ForEach(AgeGroup.allCases.filter { ageGroup in
                        groupedMilestones[ageGroup] != nil && !groupedMilestones[ageGroup]!.isEmpty
                    }, id: \.self) { ageGroup in
                        VStack(alignment: .leading, spacing: 12) {
                            // Age group header
                            HStack {
                                Text(ageGroup.rawValue)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                let milestones = groupedMilestones[ageGroup] ?? []
                                let completed = milestones.filter { $0.isCompleted }.count
                                
                                Text("\(completed)/\(milestones.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 16)
                            
                            // Milestones in this age group
                            ForEach(groupedMilestones[ageGroup] ?? []) { milestone in
                                MilestoneCard(
                                    milestone: milestone,
                                    onComplete: {
                                        dataManager.completeMilestone(milestone)
                                    },
                                    onUncomplete: {
                                        dataManager.uncompleteMilestone(milestone)
                                    },
                                    onDelete: {
                                        dataManager.deleteMilestone(milestone)
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            }
            .onChange(of: selectedAgeGroup) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo("milestonesTop", anchor: .top)
                }
            }
        }
    }
    
    private func getAgeGroupForMilestone(_ milestone: Milestone) -> AgeGroup {
        let midWeek = (milestone.minAgeWeeks + milestone.maxAgeWeeks) / 2
        
        if midWeek <= 12 { return .newborn }
        else if midWeek <= 24 { return .infant }
        else if midWeek <= 52 { return .mobileBaby }
        else if midWeek <= 104 { return .toddler }
        else { return .preschooler }
    }
}

struct AgeGroupChip: View {
    let ageGroup: MilestonesView.AgeGroup
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(ageGroup.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(isSelected ? ageGroup.color : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(isSelected ? Color.clear : ageGroup.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct MilestoneCard: View {
    let milestone: Milestone
    let onComplete: () -> Void
    let onUncomplete: () -> Void
    let onDelete: (() -> Void)?
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(milestone.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(milestone.isCompleted ? .secondary : .primary)
                    .strikethrough(milestone.isCompleted)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Text(milestone.expectedAgeRange)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(milestone.category.color.opacity(0.8))
                    )
            }
            
            Text(milestone.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            if milestone.isCompleted, let completedDate = milestone.completedDate {
                Text("Completed \(completedDate, style: .date)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // Action buttons row
            HStack {
                Spacer()
                
                // Delete button (only for custom milestones)
                if let onDelete = onDelete, !milestone.isPredefined {
                    Button(action: {
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Complete/uncomplete button
                if milestone.isCompleted {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            onUncomplete()
                        }
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            onComplete()
                        }
                    }) {
                        Image(systemName: isPressed ? "checkmark.circle.fill" : "circle")
                            .font(.title)
                            .foregroundColor(isPressed ? .green : milestone.category.color)
                            .scaleEffect(isPressed ? 1.2 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 50, pressing: { pressing in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = pressing
                        }
                    }, perform: {})
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(milestone.isCompleted ? 
                      Color(.systemGray6) : 
                      Color(.systemBackground))
                .shadow(
                    color: milestone.isCompleted ? .clear : .black.opacity(0.08), 
                    radius: milestone.isCompleted ? 0 : 12, 
                    x: 0, 
                    y: milestone.isCompleted ? 0 : 4
                )
        )
        .scaleEffect(milestone.isCompleted ? 0.98 : 1.0)
        .opacity(milestone.isCompleted ? 0.8 : 1.0)
    }
}

// MARK: - Improved Add Milestone View

struct ImprovedAddMilestoneView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var customTitle = ""
    @State private var customDescription = ""
    @State private var minAgeWeeks = 4
    @State private var maxAgeWeeks = 8
    
    private func formatAgeFromWeeks(_ weeks: Int) -> String {
        if weeks == 0 {
            return "Birth"
        } else if weeks < 8 {
            return "\(weeks) week\(weeks == 1 ? "" : "s")"
        } else if weeks < 52 {
            let months = weeks / 4
            return "\(months) month\(months == 1 ? "" : "s")"
        } else if weeks >= 104 {
            return "2+ years"
        } else {
            let years = weeks / 52
            let remainingWeeks = weeks % 52
            let months = remainingWeeks / 4
            if months == 0 {
                return "\(years) year\(years == 1 ? "" : "s")"
            } else {
                return "\(years) year\(years == 1 ? "" : "s") \(months) month\(months == 1 ? "" : "s")"
            }
        }
    }
    
    private var ageRangeDescription: String {
        let fromAge = formatAgeFromWeeks(minAgeWeeks)
        let toAge = formatAgeFromWeeks(maxAgeWeeks)
        return "\(fromAge) - \(toAge)"
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    LiquidBackground()
                    
                    ScrollView {
                    VStack(spacing: 24) {
                        // Ad Banner
                        AdBannerContainer()
                        
                        // Milestone Details
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                TextField("e.g., First giggle, Loves peek-a-boo", text: $customTitle)
                                    .font(.title2)
                                    .frame(height: 52)
                                    .padding(.horizontal, 16)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description (Optional)")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                TextField("Add more details about this milestone", text: $customDescription, axis: .vertical)
                                    .font(.body)
                                    .lineLimit(3...6)
                                    .frame(minHeight: 80)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                            }
                        }
                        .padding(20)
                        .liquidGlassCard()
                        
                        // Age Range
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Expected Age Range")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            // Current age range description
                            Text(ageRangeDescription)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                                .padding(.vertical, 8)
                                .animation(.easeInOut(duration: 0.2), value: ageRangeDescription)
                            
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("From: \(formatAgeFromWeeks(minAgeWeeks))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Slider(value: Binding(
                                        get: { Double(minAgeWeeks) },
                                        set: { 
                                            minAgeWeeks = Int($0)
                                            if maxAgeWeeks < minAgeWeeks {
                                                maxAgeWeeks = minAgeWeeks
                                            }
                                        }
                                    ), in: 0...104, step: 1)
                                    .accentColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("To: \(formatAgeFromWeeks(maxAgeWeeks))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Slider(value: Binding(
                                        get: { Double(maxAgeWeeks) },
                                        set: { maxAgeWeeks = max(Int($0), minAgeWeeks) }
                                    ), in: 0...104, step: 1)
                                    .accentColor(.blue)
                                }
                            }
                        }
                        .padding(20)
                        .liquidGlassCard()
                        
                        // Save button
                        Button("Add Milestone") {
                            let milestone = Milestone(
                                title: customTitle,
                                minAgeWeeks: minAgeWeeks,
                                maxAgeWeeks: max(minAgeWeeks, maxAgeWeeks),
                                category: .motor, // Default category since we removed selection
                                description: customDescription.isEmpty ? "Custom milestone" : customDescription
                            )
                            
                            dataManager.addMilestone(milestone)
                            dismiss()
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue)
                        .cornerRadius(16)
                        .disabled(customTitle.isEmpty)
                        .opacity(customTitle.isEmpty ? 0.6 : 1.0)
                    }
                    .padding()
                    .frame(width: geometry.size.width)
                }
            }
            }
            .navigationTitle("Add Custom Milestone")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

// MARK: - Word Tracker View

struct WordTrackerView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var selectedCategory: WordCategory? = nil // nil means "All"
    @State private var showingAddWord = false
    @State private var searchText = ""
    
    var filteredWords: [BabyWord] {
        let categoryFiltered = dataManager.words.filter { word in
            selectedCategory == nil ? true : word.category == selectedCategory
        }
        
        let searchFiltered: [BabyWord]
        if searchText.isEmpty {
            searchFiltered = categoryFiltered
        } else {
            searchFiltered = categoryFiltered.filter { 
                $0.word.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Order by most recent said
        return searchFiltered.sorted { $0.dateFirstSaid > $1.dateFirstSaid }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Liquid animated background with tap gesture for keyboard dismissal
                    LiquidBackground()
                        .onTapGesture {
                            // Dismiss keyboard when tapping background
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    
                    VStack(spacing: 16) {
                        // Ad Banner
                        AdBannerContainerMedium()
                        
                        // Header with stats
                        headerView
                        
                        // Category selector
                        categorySelector
                    
                    // Search bar
                    searchBar
                    
                    // Words list
                    wordsList
                }
                .padding(.top, 16)
                .frame(width: geometry.size.width)
                .background(
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Additional keyboard dismissal on content area
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                )
            }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    wordTrackerTitleView
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddWord = true
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
            .sheet(isPresented: $showingAddWord) {
                AddWordView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var wordTrackerTitleView: some View {
        VStack(spacing: 2) {
            Text("Word Tracker")
                .font(.title2)
                .fontWeight(.bold)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(dataManager.wordCount) words")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("vocabulary learned")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: min(Double(dataManager.wordCount) / 50.0, 1.0)) // Goal of 50 words
                        .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: dataManager.wordCount)
                    
                    Text("\(dataManager.wordCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.green.opacity(0.3), .blue.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All button
                Button(action: {
                    selectedCategory = nil
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.horizontal.3")
                            .font(.caption)
                        Text("All")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(selectedCategory == nil ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(selectedCategory == nil ? Color.blue : Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Category buttons
                ForEach(WordCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedCategory == category ? Color.blue : Color(.systemGray6))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search words...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var wordsList: some View {
            if filteredWords.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No words yet")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Start tracking your baby's vocabulary by adding their first words!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button("Add First Word") {
                        showingAddWord = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 60)
            }
            } else {
            List(filteredWords) { word in
                        WordCard(word: word) {
                            dataManager.deleteWord(word)
                        }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
        }
    }
}

struct WordCategoryChip: View {
    let category: WordCategory
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .font(.caption)
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : category.color)
                }
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? category.color : category.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(category.color, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WordCard: View {
    let word: BabyWord
    let onDelete: () -> Void
    
    var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(word.word.capitalized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(word.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(word.category.color)
                        .clipShape(Capsule())
                }
                
                Text("First said \(word.dateFirstSaid, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !word.notes.isEmpty {
                    Text(word.notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .opacity(0.7)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
}

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataManager: TotsDataManager
        @State private var word = ""
        @State private var suggestions: [String] = []
        @State private var showingSuggestions = false
        @State private var isSelectingSuggestion = false
        @State private var isTextFieldFocused = false
        @State private var wordWasSelected = false
    
    var detectedCategory: WordCategory {
        dataManager.getAutoCategorizedCategory(for: word)
    }
    
    var hasValidInput: Bool {
        !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Liquid animated background
                    LiquidBackground()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Ad Banner
                            AdBannerContainer()
                        
                        // Popular Words Section
                        if !hasValidInput {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Popular First Words")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                let popularWords = [
                                    "mama", "dada", "hi", "bye", "more", "no", "up", "go", "please", "thank you",
                                    "water", "milk", "eat", "hungry", "help", "yes", "stop", "come", "sit", "down",
                                    "hot", "cold", "big", "little", "red", "blue", "ball", "book", "car", "dog",
                                    "cat", "baby", "love", "happy", "sleepy", "all done", "open", "close"
                                ]
                                
                                ScrollView(.vertical, showsIndicators: true) {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 16) {
                                        ForEach(popularWords, id: \.self) { popularWord in
                                            Button(action: {
                                                // Set flag to prevent typeahead from appearing
                                                isSelectingSuggestion = true
                                                isTextFieldFocused = false
                                                wordWasSelected = true
                                                word = popularWord.capitalized
                                                showingSuggestions = false
                                                // Reset flag after delay
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    isSelectingSuggestion = false
                                                }
                                            }) {
                                                Text(popularWord.capitalized)
                                                    .font(.body)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(Color(.systemBackground))
                                                    .cornerRadius(12)
                                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .contentShape(Rectangle())
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 20)
                                }
                                .frame(maxHeight: 200)
                            }
                            .padding(20)
                            .liquidGlassCard()
                        }
                        
                        // Word Input Section with Typeahead
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Word")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    TextField("What word did they say?", text: $word)
                                        .font(.title2)
                                        .frame(height: 52)
                                        .padding(.horizontal, 16)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                                        .autocapitalization(.words)
                                        .contentShape(Rectangle())
                                        .onChange(of: word) { newValue in
                                            if !isTextFieldFocused {
                                                isTextFieldFocused = true
                                            }
                                            // Reset wordWasSelected when user types manually
                                            if !isSelectingSuggestion {
                                                wordWasSelected = false
                                            }
                                            updateSuggestions(for: newValue.trimmingCharacters(in: .whitespacesAndNewlines))
                                        }
                                        .onTapGesture {
                                            isTextFieldFocused = true
                                            updateSuggestions(for: word.trimmingCharacters(in: .whitespacesAndNewlines))
                                        }
                                    
                                    // Typeahead suggestions dropdown
                                    if showingSuggestions && !suggestions.isEmpty {
                                        ScrollView {
                                            LazyVStack(spacing: 0) {
                                                ForEach(suggestions, id: \.self) { suggestion in
                                                    Button(action: {
                                                        // Set flag to prevent suggestions from reappearing
                                                        isSelectingSuggestion = true
                                                        isTextFieldFocused = false
                                                        showingSuggestions = false
                                                        wordWasSelected = true
                                                        word = suggestion
                                                        // Dismiss keyboard
                                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                                        // Reset the flag after a longer delay
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                            isSelectingSuggestion = false
                                                        }
                                                    }) {
                                                        HStack {
                                                            Text(suggestion)
                                                                .font(.body)
                                                                .foregroundColor(.primary)
                                                            Spacer()
                                                            Text(dataManager.getAutoCategorizedCategory(for: suggestion).rawValue)
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                        .frame(height: 52)
                                                        .padding(.horizontal, 16)
                                                        .background(Color(.systemBackground))
                                                    }
                                                    .buttonStyle(PlainButtonStyle())
                                                    .contentShape(Rectangle())
                                                    
                                                    if suggestion != suggestions.last {
                                                        Divider()
                                                    }
                                                }
                                            }
                                        }
                                        .frame(height: 158)
                                        .scrollIndicators(.visible)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(8)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        .padding(.top, 4)
                                    }
                                }
                            }
                            
                            // Auto-detected category display
                            if hasValidInput && (wordWasSelected || !isTextFieldFocused) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Auto-detected Category")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Text(detectedCategory.rawValue)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("✓")
                                            .foregroundColor(.green)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(height: 52)
                                    .padding(.horizontal, 16)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                                }
                            }
                            
                        }
                        .padding(20)
                        .liquidGlassCard()
                        
                        // Save button
                        Button("Add Word") {
                            dataManager.addWord(
                                word.trimmingCharacters(in: .whitespacesAndNewlines), 
                                category: detectedCategory
                            )
                            dismiss()
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(hasValidInput ? Color.green : Color.gray)
                        .cornerRadius(16)
                        .disabled(!hasValidInput)
                        .opacity(hasValidInput ? 1.0 : 0.6)
                        .contentShape(Rectangle()) // Make whole button clickable
                    }
                    .padding()
                    .onTapGesture {
                        // Dismiss keyboard and show category when tapping outside text field
                        isTextFieldFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .frame(width: geometry.size.width)
                }
            }
            }
            .navigationTitle("Add Word")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onTapGesture {
                // Dismiss suggestions and keyboard when tapping outside
                showingSuggestions = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
    private func updateSuggestions(for input: String) {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Don't show suggestions if we're currently selecting one
        if isSelectingSuggestion {
            showingSuggestions = false
            return
        }
        
        if trimmedInput.isEmpty {
            suggestions = []
            showingSuggestions = false
        } else {
            suggestions = dataManager.getWordSuggestions(for: trimmedInput)
            // Show suggestions if we have some, we're focused, and not selecting
            showingSuggestions = !suggestions.isEmpty && isTextFieldFocused && !isSelectingSuggestion
        }
    }
}

enum SummaryPeriod: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
}

// MARK: - Data Models for New Views

struct DayProgressData: Identifiable {
    let id = UUID()
    let day: String
    let date: Date
    let feedings: Int
    let diapers: Int
    let sleepHours: Double
    let tummyTime: Int
}

struct WeekProgressData: Identifiable {
    let id = UUID()
    let weekLabel: String
    let startDate: Date
    let feedings: Int
    let diapers: Int
    let sleepHours: Double
    let tummyTime: Int
}

// MARK: - Simple Bar Chart

struct SimpleBarChart: View {
    let title: String
    let data: Any
    let isWeekly: Bool
    
    private var dailyData: [DayProgressData] {
        return data as? [DayProgressData] ?? []
    }
    
    private var weeklyData: [WeekProgressData] {
        return data as? [WeekProgressData] ?? []
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if isWeekly {
                dailyBarChart
            } else {
                weeklyBarChart
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private var dailyBarChart: some View {
        VStack(spacing: 16) {
            // Activity rows
            VStack(spacing: 12) {
                DailyActivityRow(
                    icon: "🍼",
                    title: "Feedings",
                    color: .pink,
                    dailyData: dailyData,
                    maxValue: 8,
                    getValue: { $0.feedings }
                )
                
                DailyActivityRow(
                    icon: "moon.zzz.fill",
                    title: "Sleep",
                    color: .purple,
                    dailyData: dailyData,
                    maxValue: 15,
                    getValue: { Int($0.sleepHours) }
                )
                
                DailyActivityRow(
                    icon: "DiaperIcon",
                    title: "Diapers",
                    color: .orange,
                    dailyData: dailyData,
                    maxValue: 6,
                    getValue: { $0.diapers }
                )
                
                DailyActivityRow(
                    icon: "🧸",
                    title: "Tummy Time",
                    color: .green,
                    dailyData: dailyData,
                    maxValue: 60,
                    getValue: { $0.tummyTime }
                )
            }
            
            // Day labels
            HStack {
                ForEach(Array(dailyData.enumerated()), id: \.offset) { index, dayData in
                    Text(dayData.day)
                        .font(.caption2)
                        .fontWeight(Calendar.current.isDateInToday(dayData.date) ? .bold : .regular)
                        .foregroundColor(Calendar.current.isDateInToday(dayData.date) ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private var weeklyBarChart: some View {
        VStack(spacing: 16) {
            // Activity rows
            VStack(spacing: 12) {
                WeeklyActivityRow(
                    icon: "🍼",
                    title: "Feedings",
                    color: .pink,
                    weeklyData: weeklyData,
                    maxValue: 56,
                    getValue: { $0.feedings }
                )
                
                WeeklyActivityRow(
                    icon: "moon.zzz.fill",
                    title: "Sleep",
                    color: .purple,
                    weeklyData: weeklyData,
                    maxValue: 105,
                    getValue: { Int($0.sleepHours) }
                )
                
                WeeklyActivityRow(
                    icon: "DiaperIcon",
                    title: "Diapers",
                    color: .orange,
                    weeklyData: weeklyData,
                    maxValue: 42,
                    getValue: { $0.diapers }
                )
                
                WeeklyActivityRow(
                    icon: "🧸",
                    title: "Tummy Time",
                    color: .green,
                    weeklyData: weeklyData,
                    maxValue: 420,
                    getValue: { $0.tummyTime }
                )
            }
            
            // Week labels
            HStack {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, weekData in
                    Text("W\(index + 1)")
                        .font(.caption2)
                        .fontWeight(index == weeklyData.count - 1 ? .bold : .regular)
                        .foregroundColor(index == weeklyData.count - 1 ? .blue : .secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct DailyActivityRow: View {
    let icon: String
    let title: String
    let color: Color
    let dailyData: [DayProgressData]
    let maxValue: Int
    let getValue: (DayProgressData) -> Int
    
    private var isDiaperIcon: Bool {
        return icon == "DiaperIcon"
    }
    
    private var isSFSymbol: Bool {
        return icon.contains(".")
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon and title
            HStack(spacing: 6) {
                if isDiaperIcon {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .foregroundColor(color)
                } else if isSFSymbol {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                } else {
                    Text(icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70, alignment: .leading)
            
            // Progress bars for each day
            HStack(spacing: 4) {
                ForEach(Array(dailyData.enumerated()), id: \.offset) { index, dayData in
                    let value = getValue(dayData)
                    let progress = min(Double(value) / Double(maxValue), 1.0)
                    let isToday = Calendar.current.isDateInToday(dayData.date)
                    
                    VStack(spacing: 2) {
                        // Progress bar
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 30)
                            
                            Rectangle()
                                .fill(color.opacity(isToday ? 1.0 : 0.7))
                                .frame(height: 30 * progress)
                        }
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        
                        // Value annotation
                        Text("\(value)")
                            .font(.caption2)
                            .fontWeight(isToday ? .semibold : .regular)
                            .foregroundColor(isToday ? color : .secondary)
                    }
                }
            }
        }
    }
}

struct WeeklyActivityRow: View {
    let icon: String
    let title: String
    let color: Color
    let weeklyData: [WeekProgressData]
    let maxValue: Int
    let getValue: (WeekProgressData) -> Int
    
    private var isDiaperIcon: Bool {
        return icon == "DiaperIcon"
    }
    
    private var isSFSymbol: Bool {
        return icon.contains(".")
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon and title
            HStack(spacing: 6) {
                if isDiaperIcon {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .foregroundColor(color)
                } else if isSFSymbol {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                } else {
                    Text(icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70, alignment: .leading)
            
            // Progress bars for each week
            HStack(spacing: 4) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, weekData in
                    let value = getValue(weekData)
                    let progress = min(Double(value) / Double(maxValue), 1.0)
                    let isCurrentWeek = index == weeklyData.count - 1
                    
                    VStack(spacing: 2) {
                        // Progress bar
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 30)
                            
                            Rectangle()
                                .fill(color.opacity(isCurrentWeek ? 1.0 : 0.7))
                                .frame(height: 30 * progress)
                        }
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        
                        // Value annotation
                        Text("\(value)")
                            .font(.caption2)
                            .fontWeight(isCurrentWeek ? .semibold : .regular)
                            .foregroundColor(isCurrentWeek ? color : .secondary)
                    }
                }
            }
        }
    }
}

struct OngoingSessionCard: View {
    let title: String
    let icon: String
    let startTime: Date?
    let color: Color
    let onTap: () -> Void
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Group {
                if icon == "PumpingIcon" {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(color)
                } else {
                    Text(icon)
                        .font(.title2)
                }
            }
            .frame(width: 40, height: 40)
            .background(color.opacity(0.2))
            .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(formatElapsedTime(elapsedTime))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: elapsedTime)
                
                Text("Active")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onTapGesture {
            onTap()
        }
        .onAppear {
            updateElapsedTime()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func updateElapsedTime() {
        guard let startTime = startTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateElapsedTime()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    HomeView()
        .environmentObject(TotsDataManager())
}
