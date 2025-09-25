import SwiftUI

struct TrackingCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon with glass background
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 56, height: 56)
                        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 130)
            .liquidGlassCard(cornerRadius: 20, shadowRadius: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityCard: View {
    let activity: TotsActivity
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: activity.time)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity icon
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if activity.type.rawValue == "DiaperIcon" || activity.type.rawValue == "PumpingIcon" {
                    Image(activity.type.rawValue)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(activity.type.color)
                } else if activity.type.rawValue == "moon.zzz.fill" {
                    Image(systemName: activity.type.rawValue)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(activity.type.color)
                } else {
                    Text(activity.type.rawValue)
                        .font(.system(size: 24))
                        .foregroundColor(activity.type.color)
                }
            }
            
            // Activity details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(activity.details)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time
            Text(timeString)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Color indicator
                Circle()
                    .fill(color.opacity(0.8))
                    .frame(width: 8, height: 8)
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(color.opacity(0.15))
                }
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 16, shadowRadius: 6)
    }
}


#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            TrackingCard(
                icon: "drop.fill",
                title: "Log feeding",
                color: .red
            ) {}
            
            TrackingCard(
                icon: "leaf.fill",
                title: "Diaper change",
                color: .orange
            ) {}
        }
        
        ActivityCard(
            activity: TotsActivity(
                type: .feeding,
                time: Date(),
                details: "Bottle - 4oz"
            )
        )
        
        HStack(spacing: 16) {
            StatCard(
                title: "Total Sleep",
                value: "12.5h",
                subtitle: "This week",
                color: .blue
            )
            
            StatCard(
                title: "Milestones",
                value: "15",
                subtitle: "This month",
                color: .purple
            )
        }
        
    }
    .padding()
}
