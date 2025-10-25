// MODULE: DirectorStudioTheme
// VERSION: 1.0.0
// PURPOSE: Unified design system for consistent UI/UX across the app

import SwiftUI

// MARK: - Theme Definition

struct DirectorStudioTheme {
    // MARK: - Colors
    
    struct Colors {
        // Primary brand colors
        static let primary = Color.blue
        static let secondary = Color.purple
        static let accent = Color.orange
        
        // Gradient definitions
        static let primaryGradient = LinearGradient(
            colors: [primary, secondary],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let backgroundGradient = LinearGradient(
            colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Credit status colors
        static let creditsSufficient = Color.green
        static let creditsLow = Color.orange
        static let creditsEmpty = Color.red
        static let creditsFree = Color.purple  // Dev mode
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Title styles
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title, design: .rounded).weight(.semibold)
        static let title2 = Font.system(.title2, design: .rounded).weight(.semibold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.medium)
        
        // Body styles
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // Special styles
        static let mono = Font.system(.body, design: .monospaced)
        static let creditDisplay = Font.system(.title2, design: .rounded).weight(.bold)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
        static let xxxLarge: CGFloat = 40
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 12
        static let xLarge: CGFloat = 16
        static let xxLarge: CGFloat = 20
        static let round: CGFloat = 25
    }
    
    // MARK: - Animation
    
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
        static let gentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.9)
    }
    
    // MARK: - Shadows
    
    struct Shadow {
        static let small = (color: Color.black.opacity(0.05), radius: 3.0, y: 2.0)
        static let medium = (color: Color.black.opacity(0.1), radius: 5.0, y: 3.0)
        static let large = (color: Color.black.opacity(0.15), radius: 10.0, y: 5.0)
        static let xlarge = (color: Color.black.opacity(0.2), radius: 20.0, y: 10.0)
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    var isSelected: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(DirectorStudioTheme.CornerRadius.large)
            .shadow(
                color: DirectorStudioTheme.Shadow.medium.color,
                radius: DirectorStudioTheme.Shadow.medium.radius,
                y: DirectorStudioTheme.Shadow.medium.y
            )
            .overlay(
                RoundedRectangle(cornerRadius: DirectorStudioTheme.CornerRadius.large)
                    .stroke(isSelected ? DirectorStudioTheme.Colors.primary : Color.clear, lineWidth: 2)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, DirectorStudioTheme.Spacing.large)
            .padding(.vertical, DirectorStudioTheme.Spacing.medium)
            .background(
                isEnabled ? DirectorStudioTheme.Colors.primaryGradient : 
                LinearGradient(colors: [Color.gray], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(DirectorStudioTheme.CornerRadius.large)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DirectorStudioTheme.Animation.quick, value: configuration.isPressed)
            .shadow(
                color: isEnabled ? DirectorStudioTheme.Colors.primary.opacity(0.3) : .clear,
                radius: 10,
                y: 5
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(DirectorStudioTheme.Colors.primary)
            .padding(.horizontal, DirectorStudioTheme.Spacing.medium)
            .padding(.vertical, DirectorStudioTheme.Spacing.small)
            .background(
                RoundedRectangle(cornerRadius: DirectorStudioTheme.CornerRadius.medium)
                    .stroke(DirectorStudioTheme.Colors.primary, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DirectorStudioTheme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(isSelected: Bool = false) -> some View {
        modifier(CardStyle(isSelected: isSelected))
    }
    
    func primaryButton() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
    
    func standardSpacing() -> some View {
        padding(DirectorStudioTheme.Spacing.medium)
    }
    
    func sectionSpacing() -> some View {
        padding(.vertical, DirectorStudioTheme.Spacing.large)
    }
    
    func fadeInAnimation(delay: Double = 0) -> some View {
        opacity(0)
            .animation(.easeOut(duration: 0.4).delay(delay), value: UUID())
            .onAppear {
                withAnimation {
                    self.opacity(1)
                }
            }
    }
}

// MARK: - Haptic Feedback

struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
