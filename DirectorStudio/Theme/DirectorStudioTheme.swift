// MODULE: DirectorStudioTheme
// VERSION: 1.0.0
// PURPOSE: Unified design system for consistent UI/UX across the app

import SwiftUI

// MARK: - Theme Definition

struct DirectorStudioTheme {
    // MARK: - Cinema Depth System
    
    enum CinemaDepth {
        case card      // Level 1
        case button    // Level 2
        case modal     // Level 3
        
        var shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch self {
            case .card:
                return (.black.opacity(0.1), 4, 0, 2)
            case .button:
                return (.black.opacity(0.2), 8, 0, 4)
            case .modal:
                return (.black.opacity(0.3), 12, 0, 6)
            }
        }
    }
    
    // MARK: - Colors
    
    struct Colors {
        // Primary brand colors - Premium feel
        static let primary = Color(red: 0, green: 102/255, blue: 255/255)  // #0066FF - Deeper blue
        static let secondary = Color(red: 142/255, green: 68/255, blue: 173/255)  // #8E44AD - Richer purple
        static let accent = Color(red: 255/255, green: 149/255, blue: 0/255)  // #FF9500 - Warmer orange
        
        // Gradient definitions with better color stops
        static let primaryGradient = LinearGradient(
            colors: [primary, primary.opacity(0.9), secondary.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // LensDepth Cinema Theme (from design system)
        static let backgroundBase = Color(red: 25/255, green: 25/255, blue: 25/255)     // #191919
        static let surfacePanel = Color(red: 38/255, green: 38/255, blue: 38/255)       // #262626
        static let cinemaGrey = backgroundBase  // Alias for compatibility
        static let stainlessSteel = surfacePanel  // Alias for compatibility
        static let darkSurface = surfacePanel  // Alias for compatibility
        
        static let backgroundGradient = LinearGradient(
            colors: [cinemaGrey, stainlessSteel.opacity(0.8)],
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
        // 8pt grid system for better visual rhythm
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 16   // Better rhythm
        static let medium: CGFloat = 24   // More breathing room
        static let large: CGFloat = 32    // Clear sections
        static let xLarge: CGFloat = 40   // Major spacing
        static let xxLarge: CGFloat = 48  // Section breaks
        static let xxxLarge: CGFloat = 56 // Hero spacing
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
        // More sophisticated shadows with blur for depth
        static let small = (color: Color.black.opacity(0.08), radius: 4.0, x: 0.0, y: 2.0)
        static let medium = (color: Color.black.opacity(0.12), radius: 8.0, x: 0.0, y: 4.0)
        static let large = (color: Color.black.opacity(0.16), radius: 16.0, x: 0.0, y: 8.0)
        static let xlarge = (color: Color.black.opacity(0.20), radius: 24.0, x: 0.0, y: 12.0)
        
        // Colored shadows for primary elements
        static let primaryGlow = (color: Colors.primary.opacity(0.3), radius: 16.0, x: 0.0, y: 8.0)
        static let secondaryGlow = (color: Colors.secondary.opacity(0.3), radius: 16.0, x: 0.0, y: 8.0)
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    var isSelected: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(DirectorStudioTheme.Colors.darkSurface)
            .cornerRadius(DirectorStudioTheme.CornerRadius.large)
            .shadow(
                color: Color.black.opacity(0.3),
                radius: DirectorStudioTheme.Shadow.medium.radius,
                x: DirectorStudioTheme.Shadow.medium.x,
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
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, DirectorStudioTheme.Spacing.large)
            .padding(.vertical, DirectorStudioTheme.Spacing.small)
            .background(
                ZStack {
                    // Base gradient
                    if isEnabled {
                        DirectorStudioTheme.Colors.primaryGradient
                    } else {
                        LinearGradient(colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)], 
                                     startPoint: .topLeading, 
                                     endPoint: .bottomTrailing)
                    }
                    
                    // Inner shadow for depth when pressed
                    if configuration.isPressed && isEnabled {
                        RoundedRectangle(cornerRadius: DirectorStudioTheme.CornerRadius.large)
                            .fill(Color.black.opacity(0.2))
                            .blur(radius: 4)
                            .offset(y: 2)
                    }
                }
            )
            .cornerRadius(DirectorStudioTheme.CornerRadius.large)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(DirectorStudioTheme.Animation.smooth, value: configuration.isPressed)
            .shadow(
                color: isEnabled ? DirectorStudioTheme.Shadow.primaryGlow.color : Color.clear,
                radius: configuration.isPressed ? 8 : DirectorStudioTheme.Shadow.primaryGlow.radius,
                x: 0,
                y: configuration.isPressed ? 4 : DirectorStudioTheme.Shadow.primaryGlow.y
            )
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    HapticFeedback.impact(.light)
                }
            }
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

// MARK: - Additional Styles

struct FloatingLabelTextFieldStyle: ViewModifier {
    let title: String
    @Binding var text: String
    @FocusState var isFocused: Bool
    
    var shouldFloat: Bool {
        !text.isEmpty || isFocused
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            // Floating label
            Text(title)
                .font(shouldFloat ? .caption : .body)
                .foregroundColor(shouldFloat ? DirectorStudioTheme.Colors.primary : Color(.placeholderText))
                .offset(y: shouldFloat ? -20 : 0)
                .scaleEffect(shouldFloat ? 0.8 : 1, anchor: .leading)
                .animation(DirectorStudioTheme.Animation.smooth, value: shouldFloat)
            
            content
                .font(.body)
                .focused($isFocused)
        }
        .padding(.top, 20)
        .overlay(
            Rectangle()
                .frame(height: 2)
                .foregroundColor(isFocused ? DirectorStudioTheme.Colors.primary : Color(.separator))
                .animation(DirectorStudioTheme.Animation.quick, value: isFocused),
            alignment: .bottom
        )
    }
}

// MARK: - Cinema Background Style

struct CinemaBackgroundStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DirectorStudioTheme.Colors.backgroundGradient)
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
        self
            .transition(.opacity)
            .animation(.easeOut(duration: 0.4).delay(delay), value: UUID())
    }
    
    func floatingLabel(_ title: String, text: Binding<String>, isFocused: FocusState<Bool>) -> some View {
        modifier(FloatingLabelTextFieldStyle(title: title, text: text, isFocused: isFocused))
    }
    
    func cinemaBackground() -> some View {
        modifier(CinemaBackgroundStyle())
    }
    
    func cinemaDepth(_ level: Int) -> some View {
        self.shadow(
            color: .black.opacity(0.1 * Double(level)),
            radius: CGFloat(level * 4),
            x: 0,
            y: CGFloat(level * 2)
        )
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
