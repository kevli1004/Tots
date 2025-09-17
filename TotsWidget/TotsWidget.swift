import WidgetKit
import SwiftUI

// MARK: - Widget Entry

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

// MARK: - Timeline Provider

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

// MARK: - Widget Views

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

// MARK: - Supporting Views

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

// MARK: - Widget Configuration

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

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    TotsWidget()
} timeline: {
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

#Preview("Medium", as: .systemMedium) {
    TotsWidget()
} timeline: {
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

#Preview("Lock Screen", as: .accessoryRectangular) {
    TotsWidget()
} timeline: {
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
