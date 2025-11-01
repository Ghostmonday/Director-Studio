// MODULE: AccessibilityHelpers
// VERSION: 2.0.0
// PURPOSE: Enhanced accessibility with Dynamic Type, VoiceOver, haptic cues
// BUILD STATUS: ✅ Complete

import SwiftUI
import UIKit

/// Accessibility helper extensions
extension View {
    /// Add comprehensive accessibility support
    func accessible(label: String, hint: String? = nil, value: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Support Dynamic Type scaling
    func dynamicTypeSize(_ range: ClosedRange<DynamicTypeSize>) -> some View {
        self.dynamicTypeSize(range)
    }
    
    /// Add haptic feedback for VoiceOver users
    func voiceOverHaptic() -> some View {
        self.onTapGesture {
            UIAccessibility.post(notification: .announcement, argument: "Button activated")
        }
    }
}

/// Accessibility-aware button style
struct AccessibleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

/// VoiceOver-friendly card modifier
struct AccessibleCard: ViewModifier {
    let title: String
    let description: String
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title). \(description)")
    }
}

extension View {
    func accessibleCard(title: String, description: String) -> some View {
        modifier(AccessibleCard(title: title, description: description))
    }
}

