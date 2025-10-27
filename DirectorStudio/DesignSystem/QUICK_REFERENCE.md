# LensDepth Quick Reference Card
**Fast lookup for developers**

## 🎨 Colors (Dark Mode)

```swift
// Backgrounds
LensDepthTokens.colorBackgroundBase    // #191919
LensDepthTokens.colorSurfacePanel      // #262626

// Interactive
LensDepthTokens.colorPrimaryAmber      // #FF9E0A
LensDepthTokens.colorSecondaryBlue     // #4A8FE8

// Semantic
LensDepthTokens.colorSemanticSuccess   // #32C48D
LensDepthTokens.colorSemanticDanger    // #C74432

// Text
LensDepthTokens.colorTextPrimary       // #F0F0F0
LensDepthTokens.colorTextSecondary     // #A0A0A0
```

## 📏 Spacing (8px Grid)

```swift
LensDepthTokens.spacingUnit            // 8px
LensDepthTokens.spacingInner           // 16px (2x)
LensDepthTokens.spacingOuter           // 24px (3x)
LensDepthTokens.spacingMargin          // 32px (4x)
```

## 🧩 Components

### Button
```swift
LDPrimaryButton(title: "Generate", action: { /* action */ })
LDSecondaryButton(title: "Cancel", action: { /* action */ })
```

### Panel
```swift
LDPanel {
    // Content here
}
```

### Shadows
```swift
.modifier(LensDepthShadow(depth: .surface))   // Light shadow
.modifier(LensDepthShadow(depth: .floating))  // Medium shadow
.modifier(LensDepthShadow(depth: .modal))     // Heavy shadow
```

### Genre Halo
```swift
PreviewView()
    .modifier(GenreHaloModifier(genre: .sciFi))
```

## 🔤 Typography

```swift
.font(.system(size: 32, weight: .semibold))  // Display
.font(.system(size: 24, weight: .semibold))  // Title
.font(.system(size: 20, weight: .medium))    // Headline
.font(.system(size: 15, weight: .regular))   // Body
.font(.system(size: 13, weight: .regular))   // Caption
.font(.system(size: 11, weight: .regular))   // Micro
```

## 🎬 Common Patterns

### Modal Dialog
```swift
.overlay(
    ZStack {
        Color.black.opacity(0.8)
            .ignoresSafeArea()
        
        LDPanel {
            VStack(spacing: LensDepthTokens.spacingOuter) {
                Text("Title")
                    .font(.system(size: 20, weight: .medium))
                
                LDPrimaryButton(title: "Confirm", action: { })
            }
        }
        .modifier(StainedGlassEffect(intensity: 1.0))
    }
)
```

### Form Group
```swift
VStack(alignment: .leading, spacing: LensDepthTokens.spacingInner) {
    Text("Label")
        .foregroundColor(LensDepthTokens.colorTextSecondary)
        .font(.system(size: 13))
    
    // Input field
}
```

### Cost Display
```swift
HStack {
    Image(systemName: "sparkles")
        .foregroundColor(LensDepthTokens.colorPrimaryAmber)
    
    Text("\(tokens) tokens")
        .foregroundColor(LensDepthTokens.colorTextPrimary)
    
    Spacer()
    
    Text("$\(String(format: "%.2f", cost))")
        .foregroundColor(LensDepthTokens.colorTextSecondary)
}
.padding(LensDepthTokens.spacingInner)
.background(LensDepthTokens.colorSurfacePanel)
.cornerRadius(8)
```

## ✅ Pre-flight Checklist

Before submitting code:
- [ ] No hardcoded colors (use tokens)
- [ ] No hardcoded spacing (use 8px multiples)
- [ ] Includes hover/active/disabled states
- [ ] Meets contrast requirements
- [ ] Has focus indicators
- [ ] Works in light/dark mode

## 🚨 Common Mistakes

### ❌ DON'T
```swift
Color(hex: "FF9E0A")              // Hardcoded color
.padding(20)                      // Non-8px spacing
.background(Color.orange)         // Generic color
```

### ✅ DO
```swift
LensDepthTokens.colorPrimaryAmber                // Token
.padding(LensDepthTokens.spacingOuter)           // Token spacing
.background(LensDepthTokens.colorPrimaryAmber)   // Token
```

## 🎯 Genre Color Reference

| Genre | Primary Halo | Opacity | Mood |
|-------|-------------|---------|------|
| Drama | `#FF9E0A` | 5% | Warm |
| Sci-Fi | `#4A8FE8` | 5% | Cool |
| Documentary | `#6B8E6B` | 5% | Natural |
| Noir | `#4A8FE8` | 3% | Dramatic |

## 📱 Responsive Breakpoints

```swift
// iPhone SE
if screenWidth < 375 { /* compact */ }

// iPhone Pro
if screenWidth >= 375 && screenWidth < 430 { /* standard */ }

// iPhone Pro Max / iPad
if screenWidth >= 430 { /* expanded */ }
```

## 🔗 Related Files

- Full system: `DirectorStudio/DesignSystem/LensDepthSystem.md`
- Tokens: `DirectorStudio/DesignSystem/Tokens/LensDepthTokens.swift`
- Components: `DirectorStudio/DesignSystem/Components/`
- Examples: `DirectorStudio/DesignSystem/Documentation/EXAMPLES.md`

