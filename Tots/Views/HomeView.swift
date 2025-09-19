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
    @State private var selectedActivityType: ActivityType = .feeding
    @State private var editingActivity: TotsActivity?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Countdown timers
                        countdownView
                        
                        // Today's summary with goals
                        todaySummaryWithGoalsView
                        
                        // Recent activities
                        recentActivitiesView
                    }
                    .padding()
                }
            }
                .navigationTitle("")
            .navigationBarTitleDisplayMode(.large)
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
        .sheet(isPresented: $showingDatePicker) {
            DatePickerHistoryView(selectedDate: $selectedHistoryDate)
        }
        .sheet(isPresented: $showingAddActivity) {
            if let editingActivity = editingActivity {
                AddActivityView(editingActivity: editingActivity)
            } else {
                AddActivityView(preselectedType: selectedActivityType)
            }
        }
        .onChange(of: showingAddActivity) { isShowing in
            if !isShowing {
                editingActivity = nil
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
            Text("Next Activities")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                CountdownCard(
                    icon: "🍼",
                    title: "Feed",
                    countdownInterval: dataManager.nextFeedingCountdown,
                    time: dataManager.nextFeedingTime,
                    color: .pink
                )
                .environmentObject(dataManager)
                
                CountdownCard(
                    icon: "DiaperIcon",
                    title: "Diaper",
                    countdownInterval: dataManager.nextDiaperCountdown,
                    time: dataManager.nextDiaperTime,
                    color: .orange
                )
                .environmentObject(dataManager)
            }
        }
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
        VStack(alignment: .leading, spacing: 20) {
            Text("Today's Summary & Goals")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Summary cards with progress
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                SummaryGoalCard(
                    icon: "🍼",
                    title: "Feedings",
                    current: dataManager.todayFeedings,
                    goal: 8,
                    color: .pink
                )
                
                SummaryGoalCard(
                    icon: "moon.zzz.fill",
                    title: "Sleep",
                    current: dataManager.todaySleepHours,
                    goal: 15.0,
                    color: .purple,
                    unit: "h"
                )
                
                SummaryGoalCard(
                    icon: "DiaperIcon",
                    title: "Diapers",
                    current: dataManager.todayDiapers,
                    goal: 6,
                    color: .white
                )
                
                SummaryGoalCard(
                    icon: "🧸",
                    title: "Tummy Time",
                    current: dataManager.todayTummyTime,
                    goal: 60,
                    color: .green,
                    unit: "m"
                )
            }
        }
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
    
    private var countdownText: String {
        return dataManager.formatCountdown(countdownInterval)
    }
    
    private var isDue: Bool {
        return countdownInterval <= 0
    }
    
    var body: some View {
        ZStack {
            // Front side - Countdown
            if !isFlipped {
                VStack(spacing: 14) {
                    // Icon section
                    if icon.contains(".") {
                        Image(systemName: icon)
                            .font(.title)
                            .foregroundColor(color)
                    } else if isDiaperIcon {
                        Image(icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .foregroundColor(.white)
                    } else {
                        Text(icon)
                            .font(.title)
                    }
                    
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    VStack(spacing: 4) {
                        if isDue {
                            Text("DUE")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .opacity(isFlashing ? 0.3 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isFlashing)
                        } else {
                            Text(countdownText)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(color)
                            
                            Text("until next \(title.lowercased())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Tap hint
                    Text("tap for details")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                        .fontWeight(.medium)
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
                    } else if isDiaperIcon {
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
        .frame(height: 160) // Fixed height for consistent flip animation
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
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
            axis: (x: 0, y: 1, z: 0)
        )
        .scaleEffect(x: isFlipped ? -1 : 1, y: 1) // Fix mirroring on back side
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
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
    
    init(icon: String, title: String, current: Any, goal: Any, color: Color, unit: String = "") {
        self.icon = icon
        self.title = title
        self.current = current
        self.goal = goal
        self.color = color
        self.unit = unit
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
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        }
        .padding()
        .liquidGlassCard(cornerRadius: 16, shadowRadius: 12)
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
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                VStack(spacing: 0) {
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
            }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
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
                
                // Quick stats
                if !activities.isEmpty {
                    HStack(spacing: 16) {
                        if dayStats.feedings > 0 {
                            StatPill(icon: "🍼", value: "\(dayStats.feedings)")
                        }
                        if dayStats.sleepHours > 0 {
                            StatPill(icon: "😴", value: "\(String(format: "%.1f", dayStats.sleepHours))h")
                        }
                        if dayStats.diapers > 0 {
                            StatPill(icon: "DiaperIcon", value: "\(dayStats.diapers)")
                        }
                    }
                }
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
    
    var body: some View {
        HStack(spacing: 4) {
            if isDiaperIcon {
                // Custom SVG diaper icon
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
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
                    
                    Spacer()
                    
                    Text(activity.mood.rawValue)
                        .font(.caption)
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
            case .all: return "list.bullet"
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
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                VStack(spacing: 0) {
                    // Header with stats
                    headerView
                    
                    // Age group selector
                    ageGroupSelector
                    
                    // Search bar
                    searchBar
                    
                    // Milestones list
                    milestonesList
                }
            }
            .navigationTitle("Milestones")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Custom") {
                        showingAddMilestone = true
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddMilestone) {
                ImprovedAddMilestoneView()
                    .environmentObject(dataManager)
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your baby is \(dataManager.getBabyAgeInWeeks()) weeks old")
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
                    AgeGroupChip(
                        ageGroup: ageGroup,
                        isSelected: selectedAgeGroup == ageGroup
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedAgeGroup = ageGroup
                        }
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
        ScrollView {
            LazyVStack(spacing: 16) {
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
                                Image(systemName: ageGroup.icon)
                                    .font(.headline)
                                    .foregroundColor(ageGroup.color)
                                
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
            HStack(spacing: 6) {
                Image(systemName: ageGroup.icon)
                    .font(.caption)
                Text(ageGroup.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : ageGroup.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? ageGroup.color : ageGroup.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(ageGroup.color, lineWidth: isSelected ? 0 : 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MilestoneCard: View {
    let milestone: Milestone
    let onComplete: () -> Void
    let onUncomplete: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            VStack {
                Image(systemName: milestone.category.icon)
                    .font(.title2)
                    .foregroundColor(milestone.isCompleted ? .white : milestone.category.color)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(milestone.isCompleted ? 
                                  milestone.category.color : 
                                  milestone.category.color.opacity(0.1))
                    )
                    .overlay(
                        Circle()
                            .stroke(milestone.category.color, lineWidth: milestone.isCompleted ? 0 : 2)
                    )
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(milestone.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(milestone.isCompleted ? .secondary : .primary)
                        .strikethrough(milestone.isCompleted)
                    
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
                    .lineLimit(milestone.isCompleted ? 2 : 3)
                
                if milestone.isCompleted, let completedDate = milestone.completedDate {
                    HStack(spacing: 6) {
                        Image(systemName: "party.popper.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text("Completed \(completedDate, style: .date)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            // Action button
            VStack {
                Spacer()
                
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
    @State private var selectedCategory: MilestoneCategory = .motor
    @State private var customTitle = ""
    @State private var customDescription = ""
    @State private var minAgeWeeks = 4
    @State private var maxAgeWeeks = 8
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LiquidBackground()
                
                    VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Add Custom Milestone")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Track special moments unique to your baby's journey")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Category Selection
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "tag.fill")
                                        .foregroundColor(.blue)
                                    Text("Choose Category")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(MilestoneCategory.allCases, id: \.self) { category in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedCategory = category
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: category.icon)
                                                    .font(.title2)
                                                    .foregroundColor(selectedCategory == category ? .white : category.color)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(category.rawValue)
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(selectedCategory == category ? .white : .primary)
                                                        .multilineTextAlignment(.leading)
                                                }
                                                
                                                Spacer()
                                            }
                                            .padding(16)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(selectedCategory == category ? 
                                                          category.color : 
                                                          category.color.opacity(0.1))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(category.color, lineWidth: selectedCategory == category ? 0 : 2)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .liquidGlassCard()
                            
                            // Milestone Details
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Milestone Details")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                VStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Title")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        TextField("e.g., 'First giggle', 'Loves peek-a-boo'", text: $customTitle)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .font(.body)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Description (Optional)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                        TextField("Add more details about this milestone...", text: $customDescription, axis: .vertical)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .lineLimit(2...4)
                                            .font(.body)
                                    }
                                }
                            }
                            .liquidGlassCard()
                            
                            // Age Range
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "calendar.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("Expected Age Range")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                
                                VStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("From: \(minAgeWeeks) weeks")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("(\(minAgeWeeks/4) months)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Slider(value: Binding(
                                            get: { Double(minAgeWeeks) },
                                            set: { minAgeWeeks = Int($0) }
                                        ), in: 0...104, step: 1)
                                        .accentColor(selectedCategory.color)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("To: \(maxAgeWeeks) weeks")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("(\(maxAgeWeeks/4) months)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Slider(value: Binding(
                                            get: { Double(maxAgeWeeks) },
                                            set: { maxAgeWeeks = Int($0) }
                                        ), in: 0...104, step: 1)
                                        .accentColor(selectedCategory.color)
                                    }
                                }
                            }
                            .liquidGlassCard()
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray5))
                        .cornerRadius(16)
                        
                        Button("Add Milestone") {
                            let milestone = Milestone(
                                title: customTitle,
                                minAgeWeeks: minAgeWeeks,
                                maxAgeWeeks: max(minAgeWeeks, maxAgeWeeks),
                                category: selectedCategory,
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
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [selectedCategory.color, selectedCategory.color.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .disabled(customTitle.isEmpty)
                        .opacity(customTitle.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Word Tracker View

struct WordTrackerView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var selectedCategory: WordCategory = .people
    @State private var showingAddWord = false
    @State private var searchText = ""
    
    var filteredWords: [BabyWord] {
        let categoryFiltered = dataManager.words.filter { word in
            selectedCategory == .other ? true : word.category == selectedCategory
        }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { 
                $0.word.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid animated background
                LiquidBackground()
                
                VStack(spacing: 0) {
                    // Header with stats
                    headerView
                    
                    // Category selector
                    categorySelector
                    
                    // Search bar
                    searchBar
                    
                    // Words list
                    wordsList
                }
            }
            .navigationTitle("Word Tracker")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Word") {
                        showingAddWord = true
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddWord) {
                AddWordView()
            }
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
                        .foregroundColor(.white.opacity(0.8))
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
                ForEach(WordCategory.allCases, id: \.self) { category in
                    WordCategoryChip(
                        category: category,
                        isSelected: selectedCategory == category,
                        count: dataManager.wordsByCategory[category]?.count ?? 0
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
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
    
    private var wordsList: some View {
        ScrollView {
            if filteredWords.isEmpty {
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
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredWords) { word in
                        WordCard(word: word) {
                            dataManager.deleteWord(word)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
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
        HStack(spacing: 16) {
            // Category icon
            VStack {
                Image(systemName: word.category.icon)
                    .font(.title2)
                    .foregroundColor(word.category.color)
                    .frame(width: 40, height: 40)
                    .background(word.category.color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(word.word)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(word.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
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
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
    @State private var selectedCategory: WordCategory = .other
    @State private var notes = ""
    @State private var showingSuggestions = false
    
    // Common first words suggestions
    let commonWords: [String: [String]] = [
        "People": ["mama", "dada", "papa", "baby", "bye-bye", "hi"],
        "Animals": ["dog", "cat", "cow", "duck", "fish", "bird"],
        "Food": ["milk", "water", "cookie", "banana", "apple", "more"],
        "Actions": ["go", "up", "down", "stop", "come", "sit"],
        "Objects": ["ball", "book", "car", "cup", "shoe", "toy"],
        "Feelings": ["happy", "sad", "mad", "love", "good", "bad"],
        "Sounds": ["wow", "oh", "uh-oh", "shh", "boom", "beep"],
        "Other": ["yes", "no", "please", "thank you", "help", "mine"]
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Word Details") {
                    TextField("Word", text: $word)
                        .autocapitalization(.none)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(WordCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Suggestions") {
                    ForEach(commonWords[selectedCategory.rawValue] ?? [], id: \.self) { suggestion in
                        Button(suggestion.capitalized) {
                            word = suggestion
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Add Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dataManager.addWord(word.trimmingCharacters(in: .whitespacesAndNewlines), 
                                          category: selectedCategory, 
                                          notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                    .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(TotsDataManager())
}