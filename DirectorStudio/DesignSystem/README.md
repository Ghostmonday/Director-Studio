# DirectorStudio Design System
**LensDepth v1.0 - A Cinematic Design Language**

## 📚 Documentation Structure

```
DirectorStudio/DesignSystem/
├── README.md                          # This file - start here
├── LensDepthSystem.md                 # Complete design system specification
├── QUICK_REFERENCE.md                 # Fast lookup for developers
├── Documentation/
│   ├── IMPLEMENTATION_GUIDE.md        # Step-by-step build guide
│   └── EXAMPLES.md                    # Real-world component examples
├── Tokens/
│   ├── LensDepthTokens.swift          # Core token definitions
│   ├── ColorTokens.swift              # Color system
│   └── SpacingTokens.swift            # Spacing system
├── Components/
│   ├── LDButton.swift                 # Button components
│   ├── LDPanel.swift                  # Panel components
│   ├── LDInput.swift                  # Form inputs
│   └── LDEffects.swift                # Visual effects & modifiers
└── ThemeManager.swift                 # Theme management system
```

## 🚀 Quick Start

### 1. Read the Documentation
Start with these files in order:
1. `LensDepthSystem.md` - Understand the design philosophy
2. `QUICK_REFERENCE.md` - Bookmark for daily use
3. `IMPLEMENTATION_GUIDE.md` - Learn how to build components
4. `EXAMPLES.md` - See real implementations

### 2. Import the Tokens
```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        Text("Hello, LensDepth!")
            .foregroundColor(LensDepthTokens.colorTextPrimary)
            .padding(LensDepthTokens.spacingOuter)
    }
}
```

### 3. Use Pre-built Components
```swift
LDPrimaryButton(title: "Generate Video", action: {
    // Your action here
})
```

### 4. Follow the Checklist
Every component should:
- [ ] Use design tokens (no hardcoded values)
- [ ] Follow 8px spacing grid
- [ ] Include appropriate visual depth
- [ ] Meet WCAG contrast requirements
- [ ] Have proper accessibility labels
- [ ] Support light/dark mode

## 🎨 Core Principles

### The "LensDepth" Philosophy
1. **Interface Recedes** - UI fades into the background, content comes forward
2. **Cinematic Focus** - Warm amber guides attention, cool blue supports logic
3. **Professional Trust** - Clean, consistent, reliable
4. **Cognitive Ease** - Minimize mental overhead, maximize creative flow

### Design Pillars
- **8px Grid System** - All spacing in multiples of 8
- **Semantic Color Tokens** - Colors have meaning, not just appearance
- **Lens-Depth Occlusion** - Subtle shadows create tactile depth
- **Genre-Aware Aesthetics** - UI adapts to creative context

## 🎯 Key Files

| File | Purpose | When to Use |
|------|---------|-------------|
| `LensDepthSystem.md` | Full specification | Understanding the "why" |
| `QUICK_REFERENCE.md` | Token cheat sheet | Daily development |
| `IMPLEMENTATION_GUIDE.md` | How-to guide | Building new components |
| `EXAMPLES.md` | Real code | Learning by example |
| `MONETIZATION_UI_GUIDE.md` | Credit system UI | Building purchase flows |
| `PRICING_SUMMARY.txt` | Quick pricing ref | Credit bundle details |
| `Tokens/*.swift` | Token definitions | Always imported |
| `Components/*.swift` | Reusable UI | Copy & customize |

## 🧩 Component Library

### Available Components
- `LDPrimaryButton` - Main action buttons
- `LDSecondaryButton` - Secondary actions
- `LDPanel` - Content containers with depth
- `LDInput` - Text inputs with focus states
- `LensDepthShadow` - Shadow modifier (surface/floating/modal)
- `GenreHaloModifier` - Genre-aware preview glow
- `StainedGlassEffect` - Modal overlay effect

### Coming Soon
- `LDSlider` - Amber-themed range selector
- `LDSegmentedControl` - Mode switcher
- `LDProgressBar` - Generation progress
- `LDTimeline` - Video timeline component

## 🎬 Usage Examples

### Basic Screen Layout
```swift
VStack(spacing: LensDepthTokens.spacingOuter) {
    // Header
    Text("Screen Title")
        .font(.system(size: 24, weight: .semibold))
        .foregroundColor(LensDepthTokens.colorTextPrimary)
    
    // Content
    LDPanel {
        Text("Panel content")
    }
    
    // Footer
    LDPrimaryButton(title: "Continue", action: { })
}
.padding(LensDepthTokens.spacingMargin)
.background(LensDepthTokens.colorBackgroundBase)
```

### Genre-Aware Preview
```swift
VideoPreview(url: videoURL)
    .modifier(GenreHaloModifier(genre: .sciFi))
    .modifier(LensDepthShadow(depth: .floating))
```

### Cost Calculator
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
.padding(LensDepthTokens.spacingOuter)
.background(LensDepthTokens.colorSurfacePanel)
.cornerRadius(12)
```

## ♿ Accessibility

All LensDepth components meet or exceed:
- **WCAG AAA** for text contrast (7:1)
- **WCAG AA** for interactive elements (3:1)
- **Focus indicators** on all interactive elements
- **VoiceOver support** with proper labels
- **Dynamic Type** support for text scaling

## 🎨 Theming

### Dark Mode (Default)
```swift
// Automatically applied
```

### Light Mode
```swift
@Environment(\.colorScheme) var colorScheme

// Tokens automatically adapt
```

### Genre Variants
```swift
@EnvironmentObject var theme: ThemeManager

// Change genre
theme.currentGenre = .sciFi  // Changes preview halo
```

## 🧪 Testing

### Preview Components
```swift
#if DEBUG
struct MyComponent_Previews: PreviewProvider {
    static var previews: some View {
        MyComponent()
            .preferredColorScheme(.dark)
            .environmentObject(ThemeManager.shared)
    }
}
#endif
```

### Validate Contrast
All text on background combinations in LensDepth are pre-validated for WCAG compliance.

## 🚨 Common Mistakes

### ❌ Don't Do This
```swift
Color.orange                    // Use tokens
.padding(25)                    // Use 8px grid
Text("Hello").font(.body)       // Define size explicitly
```

### ✅ Do This
```swift
LensDepthTokens.colorPrimaryAmber
.padding(LensDepthTokens.spacingOuter)  // 24px
Text("Hello").font(.system(size: 15, weight: .regular))
```

## 📖 Learning Path

1. **Day 1**: Read `LensDepthSystem.md` cover to cover
2. **Day 2**: Build a simple screen using `IMPLEMENTATION_GUIDE.md`
3. **Day 3**: Study `EXAMPLES.md` and adapt to your needs
4. **Ongoing**: Keep `QUICK_REFERENCE.md` open while coding

## 🤝 Contributing

When adding new components:
1. Follow existing token structure
2. Add to `Components/` directory
3. Document in `EXAMPLES.md`
4. Include accessibility features
5. Test in light/dark modes
6. Update this README

## 📋 Validation Checklist

Before committing UI code:
- [ ] No hardcoded colors (use `LensDepthTokens`)
- [ ] No non-8px spacing values
- [ ] Includes hover/active/disabled states
- [ ] Has accessibility labels
- [ ] Tested in both light/dark mode
- [ ] Follows naming conventions
- [ ] Documented if it's a new pattern

## 🎓 Resources

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- Film Theory & Cinematography (for genre aesthetics)

## 📝 Version History

### v1.0 (Current - 2024)
- Initial LensDepth design system
- Core token library
- Base component set
- Genre variant system
- Full documentation suite

---

## 🎬 Ready to Build?

Start with `QUICK_REFERENCE.md` for fast token lookups, then dive into `IMPLEMENTATION_GUIDE.md` to build your first LensDepth component!

**Questions?** Check the documentation files above or review `EXAMPLES.md` for real-world patterns.

*LensDepth Design System - Making movie creation insanely fast with maximum creative control.* ✨

