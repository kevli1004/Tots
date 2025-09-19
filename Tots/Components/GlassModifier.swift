import SwiftUI

// MARK: - Glass Effect Modifier
struct GlassEffect: ViewModifier {
    let intensity: Double
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    
    init(intensity: Double = 0.3, cornerRadius: CGFloat = 16, borderWidth: CGFloat = 0.5) {
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial, style: .continuous)
                    .opacity(intensity)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.2), lineWidth: borderWidth)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Liquid Glass Card
struct LiquidGlassCard: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(cornerRadius: CGFloat = 20, shadowRadius: CGFloat = 10) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.regularMaterial, style: .continuous)
                    .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 4)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - View Extensions
extension View {
    func glassEffect(intensity: Double = 0.3, cornerRadius: CGFloat = 16, borderWidth: CGFloat = 0.5) -> some View {
        self.modifier(GlassEffect(intensity: intensity, cornerRadius: cornerRadius, borderWidth: borderWidth))
    }
    
    func liquidGlassCard(cornerRadius: CGFloat = 20, shadowRadius: CGFloat = 10) -> some View {
        self.modifier(LiquidGlassCard(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}

// MARK: - Animated Background
struct LiquidBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.6),
                Color.purple.opacity(0.4),
                Color.pink.opacity(0.3),
                Color.orange.opacity(0.5)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}
