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
                Text("👶")
                    .font(.title2)
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
                    Text("👶")
                        .font(.title2)
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
                Text("👶")
                    .font(.caption)
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

// MARK: - Regular Widget Configuration

struct TotsWidget: Widget {
    let kind: String = "TotsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TotsWidgetProvider()) { entry in
            TotsWidgetView(entry: entry)
        }
        .configurationDisplayName("Tots Countdown")
        .description("Keep track of feeding, diaper, and sleep schedules.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct TotsWidgetView: View {
    let entry: TotsWidgetEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            TotsWidgetSmallView(entry: entry)
        case .systemMedium:
            TotsWidgetMediumView(entry: entry)
        case .accessoryRectangular:
            TotsWidgetLockScreenView(entry: entry)
        default:
            TotsWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Live Activity Attributes (Standalone for Widget Extension)
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

// MARK: - Helper Functions
func getNextActivity(from context: ActivityViewContext<TotsLiveActivityAttributes>) -> (label: String, time: Date?, color: Color)? {
    let now = Date()
    // Focus on diaper and feeding mainly
    let activities: [(String, Date?, Color)] = [
        ("Feeding", context.state.nextFeedingTime, .pink),
        ("Diaper", context.state.nextDiaperTime, .orange)
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
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Text("👶")
                            .font(.title2)
                        Text(context.attributes.babyName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Today")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        CompactStat(icon: "🍼", value: "\(context.state.todayFeedings)", label: "Feed")
                        CompactStat(icon: "🧷", value: "\(context.state.todayDiapers)", label: "Diaper")
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                Text("👶")
            } compactTrailing: {
                if let nextActivity = getNextActivity(from: context), let nextTime = nextActivity.time {
                    VStack(spacing: 1) {
                        Text(nextTime, style: .timer)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(nextActivity.color)
                        Text(nextActivity.label.prefix(4))
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 2) {
                        Text("👶")
                        Text("\(context.state.todayFeedings)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.pink)
                }
            } minimal: {
                Text("👶")
            }
            .widgetURL(URL(string: "tots://home"))
            .keylineTint(Color.pink)
        }
    }
}

// MARK: - Lock Screen View
struct TotsLockScreenView: View {
    let context: ActivityViewContext<TotsLiveActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with next activity countdown
            HStack {
                Text("👶 Tots")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Next activity countdown (feeding or diaper)
                if let nextActivity = getNextActivity(from: context) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Next \(nextActivity.label)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if let nextTime = nextActivity.time {
                            Text(nextTime, style: .timer)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(nextActivity.color)
                        }
                    }
                } else {
                    Text("All caught up!")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Focus on feeding and diaper with larger display
            HStack(spacing: 24) {
                // Feeding countdown
                FeedingDiaperCountdown(
                    icon: "🍼",
                    label: "Feeding",
                    count: context.state.todayFeedings,
                    goal: context.attributes.feedingGoal,
                    nextTime: context.state.nextFeedingTime,
                    color: .pink
                )
                
                // Diaper countdown
                FeedingDiaperCountdown(
                    icon: "🧷",
                    label: "Diaper",
                    count: context.state.todayDiapers,
                    goal: context.attributes.diaperGoal,
                    nextTime: context.state.nextDiaperTime,
                    color: .orange
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
            sleepGoal: 15.0,
            diaperGoal: 6,
            tummyTimeGoal: 60
        )
    }
}

extension TotsLiveActivityAttributes.ContentState {
    fileprivate static var morning: TotsLiveActivityAttributes.ContentState {
        TotsLiveActivityAttributes.ContentState(
            todayFeedings: 3,
            todaySleepHours: 6.5,
            todayDiapers: 2,
            todayTummyTime: 15,
            lastUpdateTime: Date(),
            nextFeedingTime: Calendar.current.date(byAdding: .minute, value: 45, to: Date()),
            nextDiaperTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date()),
            nextSleepTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
            nextTummyTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
        )
    }
    
    fileprivate static var afternoon: TotsLiveActivityAttributes.ContentState {
        TotsLiveActivityAttributes.ContentState(
            todayFeedings: 6,
            todaySleepHours: 12.0,
            todayDiapers: 4,
            todayTummyTime: 45,
            lastUpdateTime: Date(),
            nextFeedingTime: Calendar.current.date(byAdding: .minute, value: 30, to: Date()),
            nextDiaperTime: Calendar.current.date(byAdding: .minute, value: 20, to: Date()),
            nextSleepTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
            nextTummyTime: Calendar.current.date(byAdding: .minute, value: 90, to: Date())
        )
    }
}

#Preview("Lock Screen", as: .content, using: TotsLiveActivityAttributes.preview) {
   TotsLiveActivity()
} contentStates: {
    TotsLiveActivityAttributes.ContentState.morning
    TotsLiveActivityAttributes.ContentState.afternoon
}