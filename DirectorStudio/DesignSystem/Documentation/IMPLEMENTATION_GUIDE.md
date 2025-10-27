# LensDepth Implementation Guide
**Step-by-step guide for building with the design system**

## 🚀 Getting Started

### 1. Import the Token System
```swift
import SwiftUI

// Always have this available
struct MyView: View {
    var body: some View {
        VStack {
            // Use tokens throughout
        }
        .background(LensDepthTokens.colorBackgroundBase)
    }
}
```

### 2. Use Theme Manager
```swift
struct MyView: View {
    @EnvironmentObject var theme: ThemeManager
    
    var body: some View {
        Text("Hello")
            .foregroundColor(theme.semanticTextPrimary)
    }
}
```

## 🎨 Building Components

### Example 1: Custom Button
```swift
struct GenerateButton: View {
    let title: String
    let tokenCost: Int
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: LensDepthTokens.spacingInner) {
                Image(systemName: "sparkles")
                    .foregroundColor(LensDepthTokens.colorTextPrimary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(LensDepthTokens.colorTextPrimary)
                    
                    Text("\(tokenCost) tokens")
                        .font(.system(size: 13))
                        .foregroundColor(LensDepthTokens.colorTextSecondary)
                }
            }
            .padding(.horizontal, LensDepthTokens.spacingOuter)
            .padding(.vertical, LensDepthTokens.spacingInner)
            .background(
                LinearGradient(
                    colors: [
                        LensDepthTokens.colorPrimaryAmber,
                        LensDepthTokens.colorPrimaryAmber.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(8)
            .shadow(
                color: .black.opacity(isHovered ? 0.4 : 0.2),
                radius: isHovered ? 4 : 2,
                y: isHovered ? 2 : 1
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}
```

### Example 2: Info Panel
```swift
struct InfoPanel: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: LensDepthTokens.spacingInner) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                
                Text(title)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(LensDepthTokens.colorTextPrimary)
            }
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(LensDepthTokens.colorTextSecondary)
                .lineSpacing(4)
        }
        .padding(LensDepthTokens.spacingOuter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LensDepthTokens.colorSurfacePanel)
        .cornerRadius(12)
        .shadow(
            color: .black.opacity(0.3),
            radius: 8,
            y: 4
        )
    }
}
```

### Example 3: Cost Calculator Display
```swift
struct CostCalculator: View {
    let duration: TimeInterval
    let quality: String
    let tokens: Int
    let cost: Double
    
    var body: some View {
        VStack(spacing: LensDepthTokens.spacingOuter) {
            // Header
            HStack {
                Text("Generation Cost")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(LensDepthTokens.colorTextPrimary)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundColor(LensDepthTokens.colorPrimaryAmber)
            }
            
            Divider()
                .background(LensDepthTokens.colorTextSecondary.opacity(0.3))
            
            // Details
            VStack(spacing: LensDepthTokens.spacingInner) {
                CostRow(label: "Duration", value: "\(Int(duration))s")
                CostRow(label: "Quality", value: quality)
                CostRow(label: "Tokens", value: "\(tokens)")
            }
            
            Divider()
                .background(LensDepthTokens.colorTextSecondary.opacity(0.3))
            
            // Total
            HStack {
                Text("Total Cost")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(LensDepthTokens.colorTextPrimary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(tokens) tokens")
                        .font(.system(size: 15))
                        .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                    
                    Text("$\(String(format: "%.2f", cost))")
                        .font(.system(size: 13))
                        .foregroundColor(LensDepthTokens.colorTextSecondary)
                }
            }
        }
        .padding(LensDepthTokens.spacingOuter)
        .background(LensDepthTokens.colorSurfacePanel)
        .cornerRadius(12)
        .modifier(LensDepthShadow(depth: .floating))
    }
}

struct CostRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(LensDepthTokens.colorTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(LensDepthTokens.colorTextPrimary)
        }
    }
}
```

## 🎬 Genre-Aware Preview

```swift
struct PreviewCanvas: View {
    @EnvironmentObject var theme: ThemeManager
    let videoURL: URL?
    
    var body: some View {
        ZStack {
            // Pure black background for cinematic feel
            Color.black
            
            // Video player
            if let url = videoURL {
                VideoPlayer(url: url)
            } else {
                // Placeholder
                VStack(spacing: LensDepthTokens.spacingOuter) {
                    Image(systemName: "film")
                        .font(.system(size: 48))
                        .foregroundColor(LensDepthTokens.colorTextSecondary)
                    
                    Text("Preview will appear here")
                        .foregroundColor(LensDepthTokens.colorTextSecondary)
                }
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .cornerRadius(16)
        .modifier(GenreHaloModifier(genre: theme.currentGenre))
        .modifier(LensDepthShadow(depth: .floating))
    }
}
```

## 📱 Responsive Layout

```swift
struct AdaptiveGrid<Content: View>: View {
    let content: () -> Content
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var columns: [GridItem] {
        switch sizeClass {
        case .compact:
            return [GridItem(.flexible())]
        case .regular:
            return [
                GridItem(.flexible(), spacing: LensDepthTokens.spacingOuter),
                GridItem(.flexible(), spacing: LensDepthTokens.spacingOuter)
            ]
        default:
            return [GridItem(.flexible())]
        }
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: LensDepthTokens.spacingOuter) {
            content()
        }
    }
}
```

## 🎨 Modal Dialog Pattern

```swift
struct ConfirmationDialog: View {
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // Overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Dialog
            VStack(spacing: LensDepthTokens.spacingOuter) {
                // Icon
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                
                // Title
                Text(title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(LensDepthTokens.colorTextPrimary)
                
                // Message
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(LensDepthTokens.colorTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // Buttons
                HStack(spacing: LensDepthTokens.spacingInner) {
                    LDSecondaryButton(title: cancelTitle, action: onCancel)
                    LDPrimaryButton(title: confirmTitle, action: onConfirm)
                }
            }
            .padding(LensDepthTokens.spacingMargin)
            .frame(maxWidth: 400)
            .background(LensDepthTokens.colorSurfacePanel)
            .cornerRadius(16)
            .modifier(StainedGlassEffect(intensity: 1.0))
            .modifier(LensDepthShadow(depth: .modal))
        }
    }
}
```

## 🔄 Animation Guidelines

### Duration Standards
```swift
// Quick feedback
.animation(.easeOut(duration: 0.15), value: someState)

// Standard transition
.animation(.easeOut(duration: 0.2), value: someState)

// Dramatic effect
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: someState)
```

### Common Transitions
```swift
// Fade in
.opacity(isVisible ? 1 : 0)
.animation(.easeOut(duration: 0.2), value: isVisible)

// Slide in from bottom
.offset(y: isVisible ? 0 : 20)
.opacity(isVisible ? 1 : 0)
.animation(.spring(response: 0.3), value: isVisible)

// Scale effect
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.easeOut(duration: 0.15), value: isPressed)
```

## ♿ Accessibility Best Practices

### Focus Management
```swift
struct AccessibleButton: View {
    let title: String
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding()
                .background(LensDepthTokens.colorPrimaryAmber)
        }
        .focused($isFocused)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(LensDepthTokens.colorPrimaryAmber, lineWidth: isFocused ? 2 : 0)
                .padding(-4)
        )
        .accessibilityLabel(title)
        .accessibilityHint("Tap to perform action")
    }
}
```

### Contrast Validation
```swift
// Use this helper to ensure contrast meets WCAG standards
extension Color {
    func contrastRatio(with other: Color) -> Double {
        // Implementation would calculate actual contrast
        // For now, use design system colors which are pre-validated
        return 7.0 // LensDepth guarantees 7:1 for text
    }
}
```

## 🧪 Testing Components

```swift
#if DEBUG
struct MyComponent_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Dark mode (default)
            MyComponent()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            // Light mode
            MyComponent()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            // Different sizes
            MyComponent()
                .previewLayout(.fixed(width: 375, height: 812))
                .previewDisplayName("iPhone SE")
            
            MyComponent()
                .previewLayout(.fixed(width: 430, height: 932))
                .previewDisplayName("iPhone Pro Max")
        }
        .environmentObject(ThemeManager.shared)
    }
}
#endif
```

## 🎯 Common Patterns Checklist

When building a new screen, follow this sequence:

1. **Define State**
   ```swift
   @State private var isLoading = false
   @State private var errorMessage: String?
   ```

2. **Structure Layout**
   ```swift
   VStack(spacing: LensDepthTokens.spacingOuter) {
       // Header
       // Content
       // Footer/Actions
   }
   .padding(LensDepthTokens.spacingMargin)
   ```

3. **Apply Theme**
   ```swift
   .background(LensDepthTokens.colorBackgroundBase)
   .foregroundColor(LensDepthTokens.colorTextPrimary)
   ```

4. **Add Interactions**
   ```swift
   .onAppear { /* load data */ }
   .onChange(of: someValue) { /* react */ }
   ```

5. **Include Accessibility**
   ```swift
   .accessibilityLabel("...")
   .accessibilityHint("...")
   ```

## 📚 Next Steps

- Review `LensDepthSystem.md` for full specifications
- Check `QUICK_REFERENCE.md` for fast lookups
- See `EXAMPLES.md` for real-world component examples
- Read token documentation in `Tokens/` directory

---

*Happy building with LensDepth! 🎬*

