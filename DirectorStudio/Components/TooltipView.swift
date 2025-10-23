// MODULE: TooltipView
// VERSION: 1.0.0  
// PURPOSE: Reusable tooltip component for contextual help

import SwiftUI

/// Tooltip modifier for adding contextual help
struct TooltipModifier: ViewModifier {
    let tooltip: String
    @State private var showTooltip = false
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .offset(x: 10, y: -10)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showTooltip.toggle()
                        }
                    }
            }
            .overlay(alignment: .top) {
                if showTooltip {
                    TooltipBubble(text: tooltip)
                        .offset(y: -40)
                        .transition(.scale.combined(with: .opacity))
                }
            }
    }
}

/// Tooltip bubble view
struct TooltipBubble: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.9))
                )
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 250)
            
            // Arrow
            Triangle()
                .fill(Color.black.opacity(0.9))
                .frame(width: 12, height: 6)
                .rotationEffect(.degrees(180))
                .offset(y: -1)
        }
    }
}

/// Triangle shape for tooltip arrow
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Interactive tooltip with expanded info
struct InteractiveTooltip: View {
    let title: String
    let description: String
    let icon: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

/// Inline help button
struct HelpButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "questionmark.circle")
                .font(.body)
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// View extension for easy tooltip usage
extension View {
    func tooltip(_ text: String) -> some View {
        modifier(TooltipModifier(tooltip: text))
    }
}

// Preview
struct TooltipView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            Text("Pipeline Stage")
                .tooltip("This controls how your video is generated")
            
            InteractiveTooltip(
                title: "Continuity Engine",
                description: "Ensures visual consistency across multiple clips by tracking characters, objects, and scene elements throughout your story.",
                icon: "link.circle.fill"
            )
            .padding()
            
            HelpButton {
                print("Help tapped")
            }
        }
        .padding()
    }
}
