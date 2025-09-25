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
                    .stroke(.primary.opacity(0.1), lineWidth: borderWidth)
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
                    .shadow(color: .primary.opacity(0.15), radius: shadowRadius, x: 0, y: 4)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.primary.opacity(0.2), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Premium Glass Card
struct PremiumGlassCard: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let borderOpacity: Double
    
    init(cornerRadius: CGFloat = 24, shadowRadius: CGFloat = 12, borderOpacity: Double = 0.3) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.borderOpacity = borderOpacity
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial, style: .continuous)
                    .shadow(color: .primary.opacity(0.08), radius: shadowRadius, x: 0, y: 6)
                    .shadow(color: .primary.opacity(0.04), radius: shadowRadius * 2, x: 0, y: 12)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .primary.opacity(borderOpacity),
                                .primary.opacity(borderOpacity * 0.5),
                                .primary.opacity(borderOpacity * 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Frosted Glass Button
struct FrostedGlassButton: ViewModifier {
    let cornerRadius: CGFloat
    let isPressed: Bool
    
    init(cornerRadius: CGFloat = 16, isPressed: Bool = false) {
        self.cornerRadius = cornerRadius
        self.isPressed = isPressed
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.thickMaterial, style: .continuous)
                    .scaleEffect(isPressed ? 0.98 : 1.0)
                    .shadow(color: .primary.opacity(0.12), radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.primary.opacity(0.25), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Glass Floating Panel
struct GlassFloatingPanel: ViewModifier {
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 28) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial, style: .continuous)
                    .shadow(color: .primary.opacity(0.06), radius: 20, x: 0, y: 10)
                    .shadow(color: .primary.opacity(0.12), radius: 6, x: 0, y: 4)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .primary.opacity(0.4),
                                .primary.opacity(0.1),
                                .primary.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
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
    
    func premiumGlassCard(cornerRadius: CGFloat = 24, shadowRadius: CGFloat = 12, borderOpacity: Double = 0.3) -> some View {
        self.modifier(PremiumGlassCard(cornerRadius: cornerRadius, shadowRadius: shadowRadius, borderOpacity: borderOpacity))
    }
    
    func frostedGlassButton(cornerRadius: CGFloat = 16, isPressed: Bool = false) -> some View {
        self.modifier(FrostedGlassButton(cornerRadius: cornerRadius, isPressed: isPressed))
    }
    
    func glassFloatingPanel(cornerRadius: CGFloat = 28) -> some View {
        self.modifier(GlassFloatingPanel(cornerRadius: cornerRadius))
    }
}

// MARK: - Animated Background
struct LiquidBackground: View {
    @State private var animateGradient = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? darkModeColors : lightModeColors,
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
    
    private var lightModeColors: [Color] {
        [
            Color.blue.opacity(0.4),
            Color.purple.opacity(0.3),
            Color.pink.opacity(0.2),
            Color.cyan.opacity(0.3),
            Color.indigo.opacity(0.25),
            Color.mint.opacity(0.2)
        ]
    }
    
    private var darkModeColors: [Color] {
        [
            Color.blue.opacity(0.2),
            Color.purple.opacity(0.15),
            Color.pink.opacity(0.1),
            Color.cyan.opacity(0.15),
            Color.indigo.opacity(0.12),
            Color.mint.opacity(0.1)
        ]
    }
}

// MARK: - Glass Navigation Bar
struct GlassNavigationBar: View {
    let title: String
    let leadingAction: (() -> Void)?
    let trailingAction: (() -> Void)?
    let leadingIcon: String?
    let trailingIcon: String?
    
    init(
        title: String,
        leadingAction: (() -> Void)? = nil,
        trailingAction: (() -> Void)? = nil,
        leadingIcon: String? = nil,
        trailingIcon: String? = nil
    ) {
        self.title = title
        self.leadingAction = leadingAction
        self.trailingAction = trailingAction
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
    }
    
    var body: some View {
        HStack {
            if let leadingAction = leadingAction, let leadingIcon = leadingIcon {
                Button(action: leadingAction) {
                    Image(systemName: leadingIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .frostedGlassButton(cornerRadius: 12)
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }
            
            Spacer()
            
            Text(title)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let trailingAction = trailingAction, let trailingIcon = trailingIcon {
                Button(action: trailingAction) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .frostedGlassButton(cornerRadius: 12)
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassFloatingPanel(cornerRadius: 24)
    }
}

// MARK: - Glass Card with Header
struct GlassCardWithHeader<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let content: Content
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background {
                            Circle()
                                .fill(.ultraThinMaterial, style: .continuous)
                        }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Content
            content
        }
        .padding(20)
        .premiumGlassCard()
    }
}

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    let isDestructive: Bool
    
    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isDestructive ? .red : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frostedGlassButton(isPressed: configuration.isPressed)
    }
}

