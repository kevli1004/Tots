import Foundation
import SwiftUI

// MARK: - AI & Analytics Models

struct AIInsight: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let type: InsightType
    let confidence: Double
    
    enum InsightType {
        case positive, neutral, exciting, warning
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .neutral: return .blue
            case .exciting: return .purple
            case .warning: return .orange
            }
        }
    }
}

struct SmartSuggestion: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let action: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .green
            }
        }
    }
}

struct SleepPattern: Identifiable {
    let id = UUID()
    let date: Date
    let bedtime: Date
    let wakeTime: Date
    let quality: SleepQuality
    let interruptions: Int
    
    enum SleepQuality: String, CaseIterable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }
    }
}

struct HealthTrend: Identifiable {
    let id = UUID()
    let date: Date
    let metric: HealthMetric
    let value: Double
    let trend: TrendDirection
    
    enum HealthMetric: String, CaseIterable {
        case weight = "Weight"
        case height = "Height"
        case sleepQuality = "Sleep Quality"
        case feedingEfficiency = "Feeding Efficiency"
        case moodScore = "Mood Score"
        
        var unit: String {
            switch self {
            case .weight: return "kg"
            case .height: return "cm"
            case .sleepQuality: return "/10"
            case .feedingEfficiency: return "%"
            case .moodScore: return "/10"
            }
        }
    }
    
    enum TrendDirection: String, CaseIterable {
        case up = "↗️"
        case down = "↘️"
        case stable = "→"
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .blue
            }
        }
    }
}

struct DayStats {
    let feedings: Int
    let sleepHours: Double
    let diapers: Int
    let tummyTime: Int
}
