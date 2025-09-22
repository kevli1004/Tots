//
//  TotsWidgetExtensionLiveActivity.swift
//  TotsWidgetExtension
//
//  Created by Kevin Li on 9/17/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Regular Widget Entry and Provider

struct TotsWidgetEntry: TimelineEntry {
    let date: Date
    let nextFeedingCountdown: String
    let nextDiaperCountdown: String  
    let nextSleepCountdown: String
    let nextFeedingTime: Date?
    let nextDiaperTime: Date?
    let nextSleepTime: Date?
    let babyName: String
}

struct TotsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TotsWidgetEntry {
        TotsWidgetEntry(
            date: Date(),
            nextFeedingCountdown: "2h 15m",
            nextDiaperCountdown: "1h 30m",
            nextSleepCountdown: "45m",
            nextFeedingTime: Date().addingTimeInterval(8100),
            nextDiaperTime: Date().addingTimeInterval(5400),
            nextSleepTime: Date().addingTimeInterval(2700),
            babyName: "Emma"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TotsWidgetEntry) -> ()) {
        let entry = createEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TotsWidgetEntry>) -> ()) {
        let currentDate = Date()
        let entry = createEntry()
        
        // Refresh every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func createEntry() -> TotsWidgetEntry {
        // In a real app, this would fetch data from UserDefaults or App Groups
        // For now, we'll simulate the data
        let now = Date()
        
        return TotsWidgetEntry(
            date: now,
            nextFeedingCountdown: formatCountdown(8100), // 2h 15m
            nextDiaperCountdown: formatCountdown(5400),  // 1h 30m
            nextSleepCountdown: formatCountdown(2700),   // 45m
            nextFeedingTime: now.addingTimeInterval(8100),
            nextDiaperTime: now.addingTimeInterval(5400),
            nextSleepTime: now.addingTimeInterval(2700),
            babyName: "Emma"
        )
    }
    
    private func formatCountdown(_ timeInterval: TimeInterval) -> String {
        if timeInterval <= 0 {
            return "Due now"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Regular Widget Views

struct TotsWidgetSmallView: View {
    let entry: TotsWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image("TotsIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Text(entry.babyName)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                CountdownRow(
                    icon: "🍼",
                    title: "Feed",
                    countdown: entry.nextFeedingCountdown
                )
                
                CountdownRow(
                    icon: "🩲",
                    title: "Diaper",
                    countdown: entry.nextDiaperCountdown
                )
                
                CountdownRow(
                    icon: "😴",
                    title: "Sleep",
                    countdown: entry.nextSleepCountdown
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct TotsWidgetMediumView: View {
    let entry: TotsWidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image("TotsIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                    Text(entry.babyName)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("Next activities")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                MediumCountdownCard(
                    icon: "🍼",
                    title: "Feeding",
                    countdown: entry.nextFeedingCountdown,
                    time: entry.nextFeedingTime
                )
                
                MediumCountdownCard(
                    icon: "🩲", 
                    title: "Diaper",
                    countdown: entry.nextDiaperCountdown,
                    time: entry.nextDiaperTime
                )
                
                MediumCountdownCard(
                    icon: "😴",
                    title: "Sleep",
                    countdown: entry.nextSleepCountdown,
                    time: entry.nextSleepTime
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct TotsWidgetLockScreenView: View {
    let entry: TotsWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image("TotsIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                Text(entry.babyName)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            HStack(spacing: 12) {
                LockScreenCountdown(
                    icon: "🍼",
                    countdown: entry.nextFeedingCountdown
                )
                
                LockScreenCountdown(
                    icon: "🩲",
                    countdown: entry.nextDiaperCountdown
                )
                
                LockScreenCountdown(
                    icon: "😴", 
                    countdown: entry.nextSleepCountdown
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }
}

// MARK: - Regular Widget Supporting Views

struct CountdownRow: View {
    let icon: String
    let title: String
    let countdown: String
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.caption)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(countdown)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}

struct MediumCountdownCard: View {
    let icon: String
    let title: String
    let countdown: String
    let time: Date?
    
    private var timeString: String {
        guard let time = time else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Text(countdown)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            if !timeString.isEmpty {
                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

struct LockScreenCountdown: View {
    let icon: String
    let countdown: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(icon)
                .font(.caption2)
            
            Text(countdown)
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Regular Widget Configuration (Removed - replaced by TotsSummaryWidget)


// MARK: - Live Activity Attributes (Standalone for Widget Extension)
public struct TotsLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic properties that change during the activity
        public var todayFeedings: Int
        public var todayPumping: Int
        public var todayDiapers: Int
        public var todayTummyTime: Int
        public var lastUpdateTime: Date
        
        // Timer countdowns for next activities
        public var nextFeedingTime: Date?
        public var nextDiaperTime: Date?
        public var nextPumpingTime: Date?
        public var nextTummyTime: Date?
        
        // Active timer information
        public var isBreastfeedingActive: Bool
        public var isPumpingLeftActive: Bool
        public var isPumpingRightActive: Bool
        public var breastfeedingElapsed: TimeInterval
        public var pumpingLeftElapsed: TimeInterval
        public var pumpingRightElapsed: TimeInterval
        
        public init(todayFeedings: Int, todayPumping: Int, todayDiapers: Int, todayTummyTime: Int, lastUpdateTime: Date, nextFeedingTime: Date? = nil, nextDiaperTime: Date? = nil, nextPumpingTime: Date? = nil, nextTummyTime: Date? = nil, isBreastfeedingActive: Bool = false, isPumpingLeftActive: Bool = false, isPumpingRightActive: Bool = false, breastfeedingElapsed: TimeInterval = 0, pumpingLeftElapsed: TimeInterval = 0, pumpingRightElapsed: TimeInterval = 0) {
            self.todayFeedings = todayFeedings
            self.todayPumping = todayPumping
            self.todayDiapers = todayDiapers
            self.todayTummyTime = todayTummyTime
            self.lastUpdateTime = lastUpdateTime
            self.nextFeedingTime = nextFeedingTime
            self.nextDiaperTime = nextDiaperTime
            self.nextPumpingTime = nextPumpingTime
            self.nextTummyTime = nextTummyTime
            self.isBreastfeedingActive = isBreastfeedingActive
            self.isPumpingLeftActive = isPumpingLeftActive
            self.isPumpingRightActive = isPumpingRightActive
            self.breastfeedingElapsed = breastfeedingElapsed
            self.pumpingLeftElapsed = pumpingLeftElapsed
            self.pumpingRightElapsed = pumpingRightElapsed
        }
    }

    // Fixed properties for the activity
    public var babyName: String
    public var feedingGoal: Int
    public var pumpingGoal: Int
    public var diaperGoal: Int
    public var tummyTimeGoal: Int
    
    public init(babyName: String, feedingGoal: Int, pumpingGoal: Int, diaperGoal: Int, tummyTimeGoal: Int) {
        self.babyName = babyName
        self.feedingGoal = feedingGoal
        self.pumpingGoal = pumpingGoal
        self.diaperGoal = diaperGoal
        self.tummyTimeGoal = tummyTimeGoal
    }
}

// MARK: - Helper Functions
func getNextActivity(from context: ActivityViewContext<TotsLiveActivityAttributes>) -> (label: String, time: Date?, color: Color)? {
    let now = Date()
    // Include feeding, diaper, and pumping
    let activities: [(String, Date?, Color)] = [
        ("Feeding Time", context.state.nextFeedingTime, .pink),
        ("Diaper Change", context.state.nextDiaperTime, .orange),
        ("Pumping Time", context.state.nextPumpingTime, .cyan)
    ]
    
    // Find the next upcoming activity
    let upcomingActivities = activities.compactMap { (label, date, color) -> (String, Date, Color)? in
        guard let date = date, date > now else { return nil }
        return (label, date, color)
    }
    
    let nextActivity = upcomingActivities.min { $0.1 < $1.1 }
    return nextActivity.map { (label: $0.0, time: $0.1, color: $0.2) }
}

// MARK: - Live Activity Widget
struct TotsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TotsLiveActivityAttributes.self) { context in
            // Lock screen/banner UI
            TotsLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.4))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            // Empty Dynamic Island - no camera island notifications
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.trailing) {
                    EmptyView()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    EmptyView()
                }
            } compactLeading: {
                EmptyView()
            } compactTrailing: {
                EmptyView()
            } minimal: {
                EmptyView()
            }
        }
    }
}

// MARK: - Lock Screen View
struct TotsLockScreenView: View {
    let context: ActivityViewContext<TotsLiveActivityAttributes>
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean header
            HStack {
                HStack(spacing: 6) {
                    Image("TotsIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                    Text(context.attributes.babyName)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Spacer()
            }
            .padding(.bottom, 12)
            
            // Combined content area - show both active timers and upcoming activities
            VStack(spacing: 12) {
                // Active timers section (if any)
                if context.state.isBreastfeedingActive || context.state.isPumpingLeftActive || context.state.isPumpingRightActive {
                    VStack(spacing: 6) {
                        Text("Active Sessions")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack(spacing: 12) {
                            if context.state.isBreastfeedingActive {
                                DynamicActiveTimerView(
                                    icon: "🍼",
                                    label: "Feeding",
                                    startTime: Date().addingTimeInterval(-context.state.breastfeedingElapsed),
                                    color: .pink
                                )
                            }
                            
                            if context.state.isPumpingLeftActive {
                                DynamicActiveTimerView(
                                    icon: "PumpingIcon",
                                    label: "Pump L",
                                    startTime: Date().addingTimeInterval(-context.state.pumpingLeftElapsed),
                                    color: .cyan
                                )
                            }
                            
                            if context.state.isPumpingRightActive {
                                DynamicActiveTimerView(
                                    icon: "PumpingIcon",
                                    label: "Pump R",
                                    startTime: Date().addingTimeInterval(-context.state.pumpingRightElapsed),
                                    color: .cyan
                                )
                            }
                        }
                    }
                }
                
                // Upcoming activities section (always show but compact if timers are active)
                VStack(spacing: 6) {
                    if context.state.isBreastfeedingActive || context.state.isPumpingLeftActive || context.state.isPumpingRightActive {
                        Text("Upcoming")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    HStack(spacing: 16) {
                        // Feeding section with next due info
                        CompactUpcomingSection(
                            icon: "🍼",
                            count: context.state.todayFeedings,
                            goal: context.attributes.feedingGoal,
                            nextTime: context.state.nextFeedingTime,
                            color: .pink,
                            isActive: context.state.isBreastfeedingActive,
                            showNextDue: getNextActivity(from: context)?.label.contains("Feeding") == true,
                            nextDueTime: getNextActivity(from: context)?.time
                        )
                        
                        // Diaper section with next due info (fallback)
                        CompactUpcomingSection(
                            icon: "DiaperIcon",
                            count: context.state.todayDiapers,
                            goal: context.attributes.diaperGoal,
                            nextTime: context.state.nextDiaperTime,
                            color: .orange,
                            isActive: false,
                            showNextDue: getNextActivity(from: context)?.label.contains("Diaper") == true || (getNextActivity(from: context)?.label.contains("Feeding") != true),
                            nextDueTime: getNextActivity(from: context)?.time
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Dynamic Active Timer View (auto-updating)
struct DynamicActiveTimerView: View {
    let icon: String
    let label: String
    let startTime: Date
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            // Icon
            if icon == "PumpingIcon" {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundColor(color)
            } else {
                Text(icon)
                    .font(.system(size: 16))
            }
            
            // Dynamic Timer (auto-updating)
            Text(startTime, style: .timer)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(color)
                .monospacedDigit()
            
            // Label
            Text(label)
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Compact Upcoming Section
struct CompactUpcomingSection: View {
    let icon: String
    let count: Int
    let goal: Int
    let nextTime: Date?
    let color: Color
    let isActive: Bool
    let showNextDue: Bool
    let nextDueTime: Date?
    
    var body: some View {
        VStack(spacing: 3) {
            // Icon
            if icon == "PumpingIcon" {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                    .foregroundColor(isActive ? color.opacity(0.6) : color)
            } else if icon == "DiaperIcon" {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                    .foregroundColor(isActive ? color.opacity(0.6) : color)
            } else if icon == "🩲" {
                // Fallback emoji diaper
                Text(icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .background(
                        Text(icon)
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .offset(x: 0.5, y: 0.5)
                    )
                    .opacity(isActive ? 0.6 : 1.0)
            } else {
                Text(icon)
                    .font(.system(size: 14))
                    .opacity(isActive ? 0.6 : 1.0)
            }
            
            // Count/Goal
            Text("\(count)/\(goal)")
                .font(.system(size: 10, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(isActive ? .white.opacity(0.5) : .white)
            
            // Next time indicator or Next Due countdown
            if showNextDue, let nextDueTime = nextDueTime, nextDueTime > Date() {
                VStack(spacing: 1) {
                    Text("Next Due")
                        .font(.system(size: 7, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    Text(nextDueTime, style: .timer)
                        .font(.system(size: 8, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(color)
                        .monospacedDigit()
                }
            } else if let nextTime = nextTime, nextTime > Date(), !isActive {
                Text(nextTime, style: .timer)
                    .font(.system(size: 8, design: .rounded))
                    .foregroundColor(color)
                    .monospacedDigit()
            } else if !isActive {
                Text("Due")
                    .font(.system(size: 8, design: .rounded))
                    .foregroundColor(color)
            } else {
                Text("Active")
                    .font(.system(size: 8, design: .rounded))
                    .foregroundColor(color.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Legacy Active Timer View (kept for compatibility)
struct ActiveTimerView: View {
    let icon: String
    let label: String
    let elapsed: TimeInterval
    let color: Color
    
    private var formattedTime: String {
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Icon
            if icon == "PumpingIcon" {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .foregroundColor(color)
            } else {
                Text(icon)
                    .font(.system(size: 16))
            }
            
            // Timer
            Text(formattedTime)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(color)
            
            // Label
            Text(label)
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Clean Lock Screen Section
enum SectionPosition {
    case left, center, right
}

struct CleanLockScreenSection: View {
    let icon: String
    let count: Int
    let goal: Int
    let nextTime: Date?
    let color: Color
    let position: SectionPosition
    let unit: String?
    
    private var isDiaperIcon: Bool {
        return icon == "🩲"
    }
    
    var body: some View {
        VStack(alignment: position == .right ? .trailing : (position == .center ? .center : .leading), spacing: 6) {
            // Icon and count
            HStack(spacing: 6) {
                if position != .right {
                    iconView
                }
                
                VStack(alignment: position == .right ? .trailing : (position == .center ? .center : .leading), spacing: 1) {
                    HStack(spacing: 2) {
                        Text("\(count)")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let unit = unit {
                            Text(unit)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Text("of \(goal)\(unit ?? "")")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                if position == .right {
                    iconView
                }
            }
            
            // Next time indicator with clearer labels
            if let nextTime = nextTime, nextTime > Date() {
                VStack(alignment: position == .right ? .trailing : (position == .center ? .center : .leading), spacing: 1) {
                    Text(nextTime, style: .timer)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                    
                    Text(getActivityLabel())
                        .font(.system(size: 9, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            } else {
                VStack(alignment: .center, spacing: 1) {
                    Text("Due")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(color)
                    
                    Text("now")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var iconView: some View {
        if icon.contains(".") {
            // SF Symbol
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
        } else if isDiaperIcon {
            // Custom white diaper with black outline (scaled for widget)
            Text(icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .background(
                    Text(icon)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .offset(x: 0.5, y: 0.5)
                )
                .background(
                    Text(icon)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .offset(x: -0.5, y: -0.5)
                )
                .background(
                    Text(icon)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .offset(x: 0.5, y: -0.5)
                )
                .background(
                    Text(icon)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .offset(x: -0.5, y: 0.5)
                )
        } else if icon == "PumpingIcon" {
            // Custom pumping icon
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundColor(color)
        } else {
            // Regular emoji
            Text(icon)
                .font(.system(size: 16))
        }
    }
    
    private func getActivityLabel() -> String {
        if icon == "🍼" {
            return "till feeding"
        } else if icon == "🩲" {
            return "till diaper"
        } else if icon == "PumpingIcon" {
            return "till pumping"
        } else {
            return "until next"
        }
    }
}

// MARK: - Feeding & Diaper Countdown Component
struct FeedingDiaperCountdown: View {
    let icon: String
    let label: String
    let count: Int
    let goal: Int
    let nextTime: Date?
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon and count
            VStack(spacing: 4) {
                Text(icon)
                    .font(.title2)
                
                Text("\(count)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Countdown timer (prominent display)
            if let nextTime = nextTime, nextTime > Date() {
                VStack(spacing: 2) {
                    Text("Next in")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(nextTime, style: .timer)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            } else {
                VStack(spacing: 2) {
                    Text("Ready")
                        .font(.system(size: 9))
                        .foregroundColor(color)
                        .fontWeight(.semibold)
                    
                    Text("now!")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.2))
                .cornerRadius(8)
            }
            
            // Label
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct CompactStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.system(size: 20))
            Text(value)
                .font(.system(size: 12, weight: .semibold))
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
extension TotsLiveActivityAttributes {
    fileprivate static var preview: TotsLiveActivityAttributes {
        TotsLiveActivityAttributes(
            babyName: "Emma",
            feedingGoal: 8,
            pumpingGoal: 3,
            diaperGoal: 6,
            tummyTimeGoal: 60
        )
    }
}

extension TotsLiveActivityAttributes.ContentState {
    fileprivate static var morning: TotsLiveActivityAttributes.ContentState {
        TotsLiveActivityAttributes.ContentState(
            todayFeedings: 3,
            todayPumping: 1,
            todayDiapers: 2,
            todayTummyTime: 15,
            lastUpdateTime: Date(),
            nextFeedingTime: Calendar.current.date(byAdding: .minute, value: 45, to: Date()),
            nextDiaperTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()),
            nextPumpingTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
            nextTummyTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
            isBreastfeedingActive: false,
            isPumpingLeftActive: false,
            isPumpingRightActive: false,
            breastfeedingElapsed: 0,
            pumpingLeftElapsed: 0,
            pumpingRightElapsed: 0
        )
    }
    
    fileprivate static var afternoon: TotsLiveActivityAttributes.ContentState {
        TotsLiveActivityAttributes.ContentState(
            todayFeedings: 6,
            todayPumping: 2,
            todayDiapers: 4,
            todayTummyTime: 45,
            lastUpdateTime: Date(),
            nextFeedingTime: Calendar.current.date(byAdding: .minute, value: 30, to: Date()),
            nextDiaperTime: Calendar.current.date(byAdding: .minute, value: 20, to: Date()),
            nextPumpingTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
            nextTummyTime: Calendar.current.date(byAdding: .minute, value: 90, to: Date()),
            isBreastfeedingActive: true,
            isPumpingLeftActive: false,
            isPumpingRightActive: true,
            breastfeedingElapsed: 1245, // 20 minutes 45 seconds
            pumpingLeftElapsed: 0,
            pumpingRightElapsed: 892 // 14 minutes 52 seconds
        )
    }
}

#Preview("Lock Screen", as: .content, using: TotsLiveActivityAttributes.preview) {
   TotsLiveActivity()
} contentStates: {
    TotsLiveActivityAttributes.ContentState.morning
    TotsLiveActivityAttributes.ContentState.afternoon
}