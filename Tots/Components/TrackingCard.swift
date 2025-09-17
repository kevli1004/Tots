import SwiftUI

struct TrackingCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 120)
            .background(Color(.systemGray6))
            .cornerRadius(16)
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
            Text(activity.type.rawValue)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(activity.type.color.opacity(0.2))
                .clipShape(Circle())
            
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
