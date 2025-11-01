// MODULE: AnimatedCreditDisplay
// VERSION: 1.0.0
// PURPOSE: Premium animated credit counter with visual feedback

import SwiftUI
import Combine

/// Animated credit display with odometer-style animation
struct AnimatedCreditDisplay: View {
    @ObservedObject var creditsManager = CreditsManager.shared
    @State private var displayValue: Int = 0
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    
    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    
    var creditStatus: CreditStatus {
        let credits = creditsManager.tokens
        if credits == 0 {
            return .empty
        } else if credits < 50 {
            return .low
        } else {
            return .sufficient
        }
    }
    
    enum CreditStatus {
        case empty, low, sufficient
        
        var color: Color {
            switch self {
            case .empty: return DirectorStudioTheme.Colors.creditsEmpty
            case .low: return DirectorStudioTheme.Colors.creditsLow
            case .sufficient: return DirectorStudioTheme.Colors.creditsSufficient
            }
        }
        
        var icon: String {
            switch self {
            case .empty: return "exclamationmark.circle.fill"
            case .low: return "exclamationmark.triangle.fill"
            case .sufficient: return "checkmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated icon
            Image(systemName: creditStatus.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(creditStatus.color)
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .animation(
                    creditStatus == .low ? 
                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true) : 
                    .default,
                    value: pulseAnimation
                )
            
            // Animated number display
            HStack(spacing: 2) {
                ForEach(Array(String(format: "%05d", displayValue)), id: \.self) { digit in
                    Text(String(digit))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(DirectorStudioTheme.Colors.primary)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .id("\(digit)-\(displayValue)")
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: displayValue)
            
            Text("credits")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color(.systemBackground))
                .shadow(
                    color: DirectorStudioTheme.Shadow.medium.color,
                    radius: DirectorStudioTheme.Shadow.medium.radius,
                    x: DirectorStudioTheme.Shadow.medium.x,
                    y: DirectorStudioTheme.Shadow.medium.y
                )
        )
        .overlay(
            Capsule()
                .stroke(creditStatus.color.opacity(0.3), lineWidth: 2)
        )
        .onAppear {
            displayValue = creditsManager.tokens
            if creditStatus == .low {
                pulseAnimation = true
            }
        }
        .onReceive(timer) { _ in
            if displayValue != creditsManager.tokens {
                animateToNewValue()
            }
        }
        .onChange(of: creditsManager.tokens) { _, _ in
            HapticFeedback.impact(.light)
        }
    }
    
    private func animateToNewValue() {
        let target = creditsManager.tokens
        let difference = abs(target - displayValue)
        let step = max(1, difference / 20)
        
        if displayValue < target {
            displayValue = min(displayValue + step, target)
        } else if displayValue > target {
            displayValue = max(displayValue - step, target)
        }
    }
}

/// Inline credit cost preview with animation
struct CreditCostPreview: View {
    let cost: Int
    let duration: TimeInterval
    @State private var showCost = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(DirectorStudioTheme.Colors.accent)
            
            Text("\(cost)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(DirectorStudioTheme.Colors.primary)
                .transition(.scale.combined(with: .opacity))
                .id(cost)
            
            Text("credits")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text("•")
                .foregroundColor(.secondary)
            
            Text("\(Int(duration))s")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showCost = true
            }
        }
        .scaleEffect(showCost ? 1 : 0.8)
        .opacity(showCost ? 1 : 0)
    }
}

// MARK: - Preview

struct AnimatedCreditDisplay_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AnimatedCreditDisplay()
            CreditCostPreview(cost: 180, duration: 10)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
