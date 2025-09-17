import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let total: Double
    let color: Color
    let icon: String
    let title: String
    let subtitle: String
    
    private var progressValue: Double {
        guard total > 0 else { return 0 }
        return min(progress / total, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progressValue)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progressValue)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 2) {
                Text("\(Int(progress))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LargeCircularProgressView: View {
    let progress: Double
    let total: Double
    let title: String
    
    private var progressValue: Double {
        guard total > 0 else { return 0 }
        return min(progress / total, 1.0)
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .frame(width: 120, height: 120)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(Color.black, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progressValue)
            
            // Content
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text("\(Int(progress))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        HStack(spacing: 30) {
            CircularProgressView(
                progress: 6,
                total: 8,
                color: .red,
                icon: "drop.fill",
                title: "Feedings",
                subtitle: "today"
            )
            
            CircularProgressView(
                progress: 4,
                total: 6,
                color: .orange,
                icon: "leaf.fill",
                title: "Diapers",
                subtitle: "changed"
            )
            
            CircularProgressView(
                progress: 12.5,
                total: 16,
                color: .blue,
                icon: "moon.fill",
                title: "Sleep",
                subtitle: "hours"
            )
        }
        
        LargeCircularProgressView(
            progress: 147,
            total: 200,
            title: "Activities today"
        )
    }
    .padding()
}
