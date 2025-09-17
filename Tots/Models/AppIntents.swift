import Foundation
import AppIntents

// MARK: - App Intent for Quick Actions

@available(iOS 16.0, *)
struct AddActivityIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Activity"
    static var description = IntentDescription("Quickly add a feeding, diaper change, or sleep activity.")
    
    @Parameter(title: "Activity Type")
    var activityType: ActivityTypeEntity
    
    func perform() async throws -> some IntentResult {
        // In a real implementation, this would save the activity
        // For now, we'll just return success
        return .result()
    }
}

// MARK: - Activity Type Entity

@available(iOS 16.0, *)
struct ActivityTypeEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Activity Type"
    
    var id: String
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
    
    var title: String
    var emoji: String
    
    static var defaultQuery = ActivityTypeEntityQuery()
    
    static let feeding = ActivityTypeEntity(id: "feeding", title: "Feeding", emoji: "🍼")
    static let diaper = ActivityTypeEntity(id: "diaper", title: "Diaper", emoji: "🩲")
    static let sleep = ActivityTypeEntity(id: "sleep", title: "Sleep", emoji: "😴")
}

@available(iOS 16.0, *)
struct ActivityTypeEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ActivityTypeEntity] {
        identifiers.compactMap { id in
            switch id {
            case "feeding": return .feeding
            case "diaper": return .diaper
            case "sleep": return .sleep
            default: return nil
            }
        }
    }
    
    func suggestedEntities() async throws -> [ActivityTypeEntity] {
        [.feeding, .diaper, .sleep]
    }
}

// MARK: - App Shortcuts Provider

@available(iOS 16.0, *)
struct TotsShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: AddActivityIntent(),
                phrases: [
                    "Log feeding in \(.applicationName)",
                    "Add diaper change in \(.applicationName)",
                    "Record sleep in \(.applicationName)"
                ],
                shortTitle: "Log Activity",
                systemImageName: "plus.circle"
            )
        ]
    }
}
