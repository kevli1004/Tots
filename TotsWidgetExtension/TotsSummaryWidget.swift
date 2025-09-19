import WidgetKit
import SwiftUI

struct TotsSummaryWidget: Widget {
    let kind: String = "TotsSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TotsSummaryProvider()) { entry in
            TotsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Tots Summary")
        .description("Quick overview of your baby's recent activities.")
        .supportedFamilies(getWidgetFamilies())
    }
    
    private func getWidgetFamilies() -> [WidgetFamily] {
        let widgetEnabled = UserDefaults.standard.object(forKey: "widget_enabled") as? Bool ?? false
        return widgetEnabled ? [.systemSmall, .systemMedium] : []
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let feedingCount: Int
    let diaperCount: Int
    let lastActivity: String
}

struct TotsSummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), feedingCount: 3, diaperCount: 2, lastActivity: "Feeding 30m ago")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), feedingCount: 3, diaperCount: 2, lastActivity: "Feeding 30m ago")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // In a real implementation, you'd fetch data from your data manager
        // For now, we'll use sample data
        let currentDate = Date()
        let entry = SimpleEntry(
            date: currentDate,
            feedingCount: 3,
            diaperCount: 2,
            lastActivity: "Feeding 30m ago"
        )
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct TotsWidgetEntryView: View {
    var entry: TotsSummaryProvider.Entry

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("👶 Tots")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(entry.feedingCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.pink)
                    Text("Feedings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(entry.diaperCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Diapers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Last activity
            Text(entry.lastActivity)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding()
    }
}

#Preview(as: .systemSmall) {
    TotsSummaryWidget()
} timeline: {
    SimpleEntry(date: .now, feedingCount: 3, diaperCount: 2, lastActivity: "Feeding 30m ago")
}
