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
            AddActivityView(preselectedType: selectedActivityType)
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
                                ForEach([ActivityType.feeding, .diaper, .sleep, .play, .milestone, .growth], id: \.self) { type in
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
                                                } else if type.rawValue == "DiaperIcon" {
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
                                                Text(type.name.components(separatedBy: " ").first ?? type.name)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                
                                                if type.name.contains(" ") {
                                                    Text(type.name.components(separatedBy: " ").dropFirst().joined(separator: " "))
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.secondary)
                                                }
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
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                CountdownCard(
                    icon: "🍼",
                    title: "Feed",
                    countdown: dataManager.formatCountdown(dataManager.nextFeedingCountdown),
                    time: dataManager.nextFeedingTime,
                    color: .pink
                )
                
                CountdownCard(
                    icon: "DiaperIcon",
                    title: "Diaper",
                    countdown: dataManager.formatCountdown(dataManager.nextDiaperCountdown),
                    time: dataManager.nextDiaperTime,
                    color: .white
                )
                
                CountdownCard(
                    icon: "moon.zzz.fill",
                    title: "Sleep",
                    countdown: dataManager.formatCountdown(dataManager.nextSleepCountdown),
                    time: dataManager.nextSleepTime,
                    color: .indigo
                )
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
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dates.append(date)
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
                    ActivityRow(activity: activity)
                }
            }
        }
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
    let countdown: String
    let time: Date?
    let color: Color
    
    private var timeString: String {
        guard let time = time else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    private var isDiaperIcon: Bool {
        return icon == "DiaperIcon"
    }
    
    var body: some View {
        VStack(spacing: 10) {
            if icon.contains(".") {
                // SF Symbol
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
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
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(countdown)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            if !timeString.isEmpty {
                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .liquidGlassCard(cornerRadius: 20, shadowRadius: 15)
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
                        if activity.type.rawValue == "DiaperIcon" {
                            // Custom SVG diaper icon
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
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dates.append(date)
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    proxy.scrollTo(scrollDate, anchor: .top)
                                }
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
                    if activity.type.rawValue == "DiaperIcon" {
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

#Preview {
    HomeView()
        .environmentObject(TotsDataManager())
}