// MODULE: MicroAnimations
// VERSION: 1.0.0
// PURPOSE: Reusable animation effects for DirectorStudio

import SwiftUI

// MARK: - View Extensions for Animations

extension View {
    // Pulse animation for credits/important info
    func pulseEffect(isActive: Bool = true) -> some View {
        self.scaleEffect(isActive ? 1.05 : 1.0)
            .animation(
                isActive ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                value: isActive
            )
    }
    
    // Typewriter effect for loading messages
    func typewriterText(text: String, isAnimating: Binding<Bool>) -> some View {
        self.modifier(TypewriterModifier(text: text, isAnimating: isAnimating))
    }
    
    // Film burn transition
    func filmBurnTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .scale(scale: 1.2).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        ))
    }
    
    // Success bounce
    func successBounce(trigger: Bool) -> some View {
        self.scaleEffect(trigger ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: trigger)
    }
    
    // Shimmer effect for loading states
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
    
    // Cinema depth shadow effect
    func cinemaDepth(_ level: Int = 2) -> some View {
        self.shadow(color: .black.opacity(0.1 * Double(level)), radius: 5 * CGFloat(level), y: 2 * CGFloat(level))
    }
    
    // Gentle fade transition
    func fadeTransition(duration: Double = 0.3) -> some View {
        self.transition(.opacity.animation(.easeInOut(duration: duration)))
    }
    
    // Press effect for buttons
    func pressEffect(isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    // Jiggle animation for errors
    func jiggle(trigger: Bool) -> some View {
        self.modifier(JiggleModifier(trigger: trigger))
    }
}

// MARK: - Typewriter Modifier

struct TypewriterModifier: ViewModifier {
    let text: String
    @Binding var isAnimating: Bool
    @State private var displayedText = ""
    
    func body(content: Content) -> some View {
        Text(displayedText)
            .onAppear {
                animateText()
            }
            .onChange(of: text) { newText in
                displayedText = ""
                animateText()
            }
    }
    
    private func animateText() {
        displayedText = ""
        isAnimating = true
        
        for (index, character) in text.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                displayedText += String(character)
                if index == text.count - 1 {
                    isAnimating = false
                }
            }
        }
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = -1
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 400)
                .mask(content)
                .allowsHitTesting(false)
                .opacity(isActive ? 1 : 0)
            )
            .onAppear {
                if isActive {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
}

// MARK: - Jiggle Modifier

struct JiggleModifier: ViewModifier {
    let trigger: Bool
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _ in
                if trigger {
                    jiggle()
                }
            }
    }
    
    private func jiggle() {
        withAnimation(.linear(duration: 0.05)) {
            offset = -5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.linear(duration: 0.05)) {
                offset = 5
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.linear(duration: 0.05)) {
                offset = -3
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.linear(duration: 0.05)) {
                offset = 3
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.linear(duration: 0.05)) {
                offset = 0
            }
        }
    }
}

// MARK: - Animated Loading Dots

struct AnimatedLoadingDots: View {
    @State private var currentDot = 0
    let dotCount = 3
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(Color.primaryAmber)
                    .frame(width: 8, height: 8)
                    .scaleEffect(currentDot == index ? 1.3 : 0.8)
                    .opacity(currentDot == index ? 1.0 : 0.5)
            }
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentDot = (currentDot + 1) % dotCount
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateDots()
        }
    }
}

// MARK: - Haptic Feedback

enum HapticFeedback {
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case notification(UINotificationFeedbackGenerator.FeedbackType)
    case selection
    
    func trigger() {
        switch self {
        case .impact(let style):
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        case .notification(let type):
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(type)
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }
    
    static func light() {
        HapticFeedback.impact(.light).trigger()
    }
    
    static func medium() {
        HapticFeedback.impact(.medium).trigger()
    }
    
    static func heavy() {
        HapticFeedback.impact(.heavy).trigger()
    }
    
    static func success() {
        HapticFeedback.notification(.success).trigger()
    }
    
    static func warning() {
        HapticFeedback.notification(.warning).trigger()
    }
    
    static func error() {
        HapticFeedback.notification(.error).trigger()
    }
    
    static func selection() {
        HapticFeedback.selection.trigger()
    }
}

// MARK: - Animated Progress Ring

struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat = 4
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newValue in
            animatedProgress = newValue
        }
    }
}
