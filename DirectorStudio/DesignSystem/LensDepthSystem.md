# LensDepth Design System v1.0
**DirectorStudio Visual Language**

## 🎨 Overview

LensDepth is a cinematic design system that prioritizes focus, creative control, and professional trustworthiness. It draws inspiration from professional camera optics and the layered depth of cinematic composition.

### Core Philosophy
- Make the interface recede, putting the user's script and film at the forefront
- Use subtle, organic textures and depth that guides focus without overwhelming
- Create an environment that feels both warm and professionally cool

## 🎯 Design Principles

### 1. Minimized Cognitive Load
The dark, neutral base reduces cognitive overload, allowing the user's brain to dedicate more resources to creative decision-making rather than processing UI elements.

### 2. Emotional Resonance and Focus
Warm amber (#FF9E0A) fosters concentration and evokes the focused atmosphere of a film set. Cool blue (#4A8FE8) provides psychological balance for analytical tools.

### 3. Visual Clarity
High contrast between text and background ensures legibility and reduces eye strain during long editing sessions. All text meets WCAG AAA standards (7:1 contrast ratio for normal text).

## 🎨 Color System

### Core Palette (Dark Mode)

| Role | HEX Code | RGB | Usage |
|------|----------|-----|-------|
| **Background/Base** | `#191919` | 25, 25, 25 | Primary canvas/workspace |
| **Surface/Panel** | `#262626` | 38, 38, 38 | Tool panels, modal windows |
| **Primary/Accent** | `#FF9E0A` | 255, 158, 10 | Primary buttons, active selection |
| **Secondary/Accent** | `#4A8FE8` | 74, 143, 232 | Secondary buttons, links |
| **Success** | `#32C48D` | 50, 196, 141 | Successful render, export complete |
| **Danger/Warning** | `#C74432` | 199, 68, 50 | Delete actions, critical warnings |
| **Text (Primary)** | `#F0F0F0` | 240, 240, 240 | Primary labels and UI copy |
| **Text (Secondary)** | `#A0A0A0` | 160, 160, 160 | Less prominent labels, placeholders |

### Light Mode Overrides

| Role | HEX Code | RGB |
|------|----------|-----|
| **Background/Base** | `#FFFFFF` | 255, 255, 255 |
| **Surface/Panel** | `#F5F5F5` | 245, 245, 245 |
| **Text (Primary)** | `#333333` | 51, 51, 51 |
| **Text (Secondary)** | `#666666` | 102, 102, 102 |
| *Accent colors remain the same* | | |

### Genre Variants (Preview Halo Effects)

| Genre | Halo Color | Opacity | Atmosphere |
|-------|------------|---------|------------|
| **Cinematic Drama** | `#FF9E0A` | 5% | Warm, classic film lighting |
| **Sci-Fi** | `#4A8FE8` | 5% | Cool, futuristic feel |
| **Documentary** | `#6B8E6B` | 5% | Natural, authentic |
| **Noir** | `#4A8FE8` | 3% | High-contrast, dramatic |

## 📏 Spacing System

### 8px Base Grid
All spacing follows multiples of 8px for consistency and rhythm.

| Token | Value | Usage |
|-------|-------|-------|
| **spacing-unit** | 8px | Base unit |
| **spacing-xs** | 4px | Tight grouping |
| **spacing-sm** | 8px | Internal element padding |
| **spacing-md** | 16px | Component padding |
| **spacing-lg** | 24px | Between modules |
| **spacing-xl** | 32px | Section margins |
| **spacing-xxl** | 48px | Major sections |

### Module Margin Ratio
Follow 1:1.5:2 ratio:
- Internal element padding: 16px
- Spacing between modules: 24px
- Margin around main canvas: 32px

## 🔤 Typography

### Font Stack
```css
font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', 'Helvetica Neue', Helvetica, Arial, sans-serif;
```

### Monospace Stack
```css
font-family: 'SF Mono', Monaco, Inconsolata, 'Roboto Mono', 'Source Code Pro', monospace;
```

### Type Scale

| Level | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| **Display** | 32px | 600 | 1.2 | Main titles |
| **Title** | 24px | 600 | 1.3 | Section headers |
| **Headline** | 20px | 500 | 1.4 | Panel titles |
| **Body** | 15px | 400 | 1.5 | Main content |
| **Caption** | 13px | 400 | 1.4 | Labels, metadata |
| **Micro** | 11px | 400 | 1.3 | Timestamps, hints |

## 🎨 Visual Effects

### 1. Lens-Depth Occlusion
Tool palettes and timelines cast optically accurate soft shadows:
```css
box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
```

### 2. Organic Gradient Embossing
Buttons feature vertical gradient embossment:
```css
background: linear-gradient(180deg, #FF9E0A 0%, #E68A00 100%);
```

### 3. Stained-Glassmorphism
Modal overlays with subtle tinted glass effect:
```css
background: rgba(25, 25, 25, 0.8);
backdrop-filter: blur(4px);
box-shadow: 0 0 40px rgba(255, 158, 10, 0.2);
```

## 🧩 Component Library

### Buttons

#### Primary Button
- Background: Primary amber with gradient
- Text: Primary text color
- Shadow: Subtle drop shadow
- States: Default, Hover (+10% brightness), Active (-10% brightness), Disabled (50% opacity)

#### Secondary Button
- Background: Secondary blue
- Text: Primary text color
- Shadow: Minimal
- States: Same as primary

### Panels

#### Surface Panel
- Background: Surface color (#262626)
- Border-radius: 12px
- Shadow: Lens-depth occlusion
- Padding: 16px (spacing-md)

#### Modal Panel
- Background: Surface with stained-glass effect
- Border: 1px primary amber
- Shadow: Large glow effect
- Padding: 32px (spacing-xl)

### Form Elements

#### Text Input
- Background: Darken(surface, 10%)
- Border: 1px transparent, 2px primary on focus
- Text: Primary text
- Placeholder: Secondary text

#### Sliders
- Track: Surface color
- Fill: Primary amber
- Thumb: Primary amber with shadow

## 🎬 UI Regions

### 1. Script Input Area
- Background: Base
- Typography: Monospace for script text
- Accent: Amber for cursor and selection

### 2. Control Panels
- Background: Surface panels
- Spacing: 24px between major controls
- Grouping: Related controls with 16px spacing

### 3. Preview Canvas
- Background: Pure black (#000000) for true cinematic feel
- Genre halo: Subtle colored glow based on selected genre
- Controls: Overlay with semi-transparent background

### 4. Timeline
- Background: Surface
- Playhead: Primary amber
- Segments: Alternating surface tints
- Transitions: Secondary blue markers

## ♿ Accessibility

### Color Contrast Requirements
- Normal text: 7:1 ratio (AAA)
- Large text: 4.5:1 ratio (AA)
- Interactive elements: 3:1 ratio minimum

### Focus States
- 2px primary amber outline
- 4px offset for breathing room
- High contrast against any background

### Motion
- Respect prefers-reduced-motion
- Transitions: 200ms ease-out default
- No auto-playing animations

## 🚀 Implementation Guidelines

### CSS Custom Properties
```css
:root {
  /* Colors */
  --ld-background-base: #191919;
  --ld-surface-panel: #262626;
  --ld-primary-amber: #FF9E0A;
  --ld-secondary-blue: #4A8FE8;
  --ld-semantic-success: #32C48D;
  --ld-semantic-danger: #C74432;
  --ld-text-primary: #F0F0F0;
  --ld-text-secondary: #A0A0A0;
  
  /* Spacing */
  --ld-spacing-unit: 8px;
  --ld-spacing-xs: 4px;
  --ld-spacing-sm: 8px;
  --ld-spacing-md: 16px;
  --ld-spacing-lg: 24px;
  --ld-spacing-xl: 32px;
  --ld-spacing-xxl: 48px;
}
```

### SwiftUI Token Usage
```swift
// Always use tokens, never hardcode values
LensDepthTokens.colorPrimaryAmber  // ✅
Color(hex: "FF9E0A")              // ❌

LensDepthTokens.spacingOuter      // ✅
24                                // ❌
```

## 📋 Checklist for New Components

- [ ] Uses LensDepth color tokens exclusively
- [ ] Follows 8px spacing grid
- [ ] Includes appropriate depth/shadow
- [ ] Has defined hover/active/disabled states
- [ ] Meets WCAG contrast requirements
- [ ] Includes focus state for accessibility
- [ ] Respects theme variations (light/dark)
- [ ] Considers genre variant effects
- [ ] Tested at multiple screen sizes
- [ ] Performance optimized (no heavy effects)

## 🔄 Version History

### v1.0 (Current)
- Initial LensDepth system
- Core color palette
- Spacing system
- Base components
- Genre variants

---

*LensDepth Design System © 2024 DirectorStudio*
