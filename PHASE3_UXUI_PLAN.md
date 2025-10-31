# Phase 3: Prompt Intelligence - UX/UI Planning Document

**Design System:** DirectorStudioTheme (LensDepth Cinema)  
**Goal:** Create intuitive, delightful, and accessible UI for prompt intelligence features

---

## 🎨 Design System Foundation

### Colors (DirectorStudioTheme)
- **Background:** `#191919` (dark base)
- **Surface Panel:** `#262626` (elevated UI)
- **Primary:** `#2563EB` (professional blue)
- **Secondary:** `#FF6B35` (warm orange)
- **Semantic:** `.success`, `.warning`, `.error`, `.info`

### Spacing (8px Grid)
- `xSmall: 8px` - Tight spacing
- `small: 16px` - Inner padding
- `medium: 24px` - Outer padding
- `large: 32px` - Section margins

### Typography
- **Titles:** `.rounded` design, `.semibold` weight
- **Body:** System fonts, clear hierarchy
- **Code/Mono:** `.monospaced` for technical content

---

## 🎯 Phase 3 UX/UI Components

### 1. **ValidationFeedbackView** - Real-time Prompt Validation

#### Purpose
Show validation errors and suggestions **as the user types**, preventing frustration before generation starts.

#### Design Patterns
```
┌─────────────────────────────────────┐
│ ✏️ Writing Prompt...                │
├─────────────────────────────────────┤
│                                     │
│ [Text Input Field]                  │
│                                     │
│ ⚠️ Prompt too short                │
│    Add more detail (at least 10     │
│    characters)                      │
│                                     │
│ 💡 Suggestion:                     │
│    "A cinematic shot of..."         │
│                                     │
└─────────────────────────────────────┘
```

#### UX Principles
- **Progressive Disclosure:** Only show errors when relevant
- **Inline Feedback:** Errors appear directly below input
- **Actionable Suggestions:** Provide fix suggestions, not just errors
- **Non-Blocking:** Warnings in orange, errors in red
- **Character Counter:** Show remaining characters (4000 max)

#### Implementation
```swift
struct ValidationFeedbackView: View {
    let result: ValidationService.Result
    let promptText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DirectorStudioTheme.Spacing.small) {
            // Character counter
            HStack {
                Spacer()
                Text("\(promptText.count)/4000")
                    .font(.caption)
                    .foregroundColor(counterColor)
            }
            
            // Errors (blocking)
            if !result.errors.isEmpty {
                ForEach(result.errors, id: \.description) { error in
                    ValidationBanner(
                        message: error.description,
                        type: .error,
                        suggestion: suggestionFor(error)
                    )
                }
            }
            
            // Suggestions (non-blocking)
            if !result.suggestions.isEmpty {
                ForEach(result.suggestions, id: \.self) { suggestion in
                    ValidationBanner(
                        message: suggestion,
                        type: .info
                    )
                }
            }
        }
        .padding(.top, DirectorStudioTheme.Spacing.xSmall)
    }
}
```

#### Visual States
- **✅ Valid:** Green checkmark, subtle success indicator
- **⚠️ Warning:** Orange banner, generation can proceed
- **❌ Error:** Red banner, generation blocked
- **💡 Info:** Blue banner, helpful tips

---

### 2. **DialoguePreviewCard** - Extracted Dialogue Display

#### Purpose
Show extracted dialogue with speaker attribution **before generation**, allowing users to verify and edit.

#### Design Patterns
```
┌─────────────────────────────────────┐
│ 🎭 Dialogue Detected                │
├─────────────────────────────────────┤
│                                     │
│ 👤 Narrator                         │
│    "Welcome to the story..."        │
│                                     │
│ 👤 Character                        │
│    "This is important!"             │
│                                     │
│ [Edit] [Remove] [✓ Keep]           │
│                                     │
└─────────────────────────────────────┘
```

#### UX Principles
- **Card-Based:** Each dialogue block is a card
- **Speaker Attribution:** Clear visual hierarchy
- **Confidence Indicator:** Show extraction confidence (if low, allow editing)
- **Quick Actions:** Edit, remove, or keep dialogue
- **Collapsible:** Can collapse if dialogue is long

#### Implementation
```swift
struct DialoguePreviewCard: View {
    let dialogue: DialogueExtractor.Line
    let onEdit: () -> Void
    let onRemove: () -> Void
    let onKeep: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: DirectorStudioTheme.Spacing.small) {
            // Speaker icon
            Image(systemName: "person.fill")
                .foregroundColor(DirectorStudioTheme.Colors.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                // Speaker name
                Text(dialogue.speaker)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Dialogue text
                Text("\"\(dialogue.text)\"")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
                
                // Confidence badge (if low)
                if dialogue.confidence < 0.8 {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                        Text("Low confidence")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            // Actions
            Menu {
                Button("Edit", action: onEdit)
                Button("Remove", role: .destructive, action: onRemove)
                Button("Keep", action: onKeep)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .padding(DirectorStudioTheme.Spacing.small)
        .background(DirectorStudioTheme.Colors.surfacePanel)
        .cornerRadius(DirectorStudioTheme.CornerRadius.medium)
        .cinemaDepth(1)
    }
}
```

---

### 3. **ModelRecommendationBadge** - Smart Model Selection

#### Purpose
Show **why** a specific Kling version was recommended, building user trust and understanding.

#### Design Patterns
```
┌─────────────────────────────────────┐
│ 🤖 Recommended: Kling 2.5 Turbo     │
├─────────────────────────────────────┤
│                                     │
│ Complexity: ████████░░ 80%         │
│                                     │
│ Reasons:                            │
│ • High visual complexity detected   │
│ • Multiple characters              │
│ • Complex motion required          │
│                                     │
│ [Use Recommended] [Choose Other]   │
│                                     │
└─────────────────────────────────────┘
```

#### UX Principles
- **Transparency:** Explain the recommendation logic
- **Visual Score:** Progress bar for complexity
- **Reasons List:** Bullet points explaining why
- **Override Option:** Allow manual selection
- **Cost Indicator:** Show cost difference

#### Implementation
```swift
struct ModelRecommendationBadge: View {
    let recommendation: KlingVersion
    let complexityScore: Float
    let reasons: [String]
    let onAccept: () -> Void
    let onOverride: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DirectorStudioTheme.Spacing.small) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(DirectorStudioTheme.Colors.secondary)
                Text("Recommended: \(recommendation.rawValue)")
                    .font(.headline)
            }
            
            // Complexity visual
            VStack(alignment: .leading, spacing: 4) {
                Text("Complexity: \(Int(complexityScore * 100))%")
                    .font(.caption)
                ProgressView(value: complexityScore)
                    .tint(DirectorStudioTheme.Colors.secondary)
            }
            
            // Reasons
            VStack(alignment: .leading, spacing: 4) {
                Text("Reasons:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ForEach(reasons, id: \.self) { reason in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(reason)
                            .font(.caption)
                    }
                }
            }
            
            // Actions
            HStack {
                Button("Use Recommended", action: onAccept)
                    .buttonStyle(.borderedProminent)
                    .tint(DirectorStudioTheme.Colors.primary)
                
                Button("Choose Other", action: onOverride)
                    .buttonStyle(.bordered)
            }
        }
        .padding(DirectorStudioTheme.Spacing.medium)
        .background(DirectorStudioTheme.Colors.surfacePanel)
        .cornerRadius(DirectorStudioTheme.CornerRadius.large)
        .cinemaDepth(2)
    }
}
```

---

### 4. **SmartPromptAssistant** - AI-Powered Guidance

#### Purpose
Provide **contextual help** as users write prompts, suggesting improvements in real-time.

#### Design Patterns
```
┌─────────────────────────────────────┐
│ 💡 Smart Suggestions                │
├─────────────────────────────────────┤
│                                     │
│ Your prompt is good! Here's how     │
│ to make it even better:              │
│                                     │
│ [Add Camera Angle]                  │
│ [Specify Lighting]                  │
│ [Add Mood/Atmosphere]               │
│                                     │
│ [Apply All] [Dismiss]               │
│                                     │
└─────────────────────────────────────┘
```

#### UX Principles
- **Contextual:** Only show relevant suggestions
- **One-Click Apply:** Easy to accept suggestions
- **Learn from User:** Hide suggestions user dismisses
- **Non-Intrusive:** Can be dismissed
- **Helpful, Not Pushy:** Suggestions, not requirements

---

### 5. **PromptIntelligenceSummary** - Pre-Generation Overview

#### Purpose
Show **complete prompt analysis** before generation starts: validation, dialogue, model recommendation, cost.

#### Design Patterns
```
┌─────────────────────────────────────┐
│ 📊 Prompt Analysis                  │
├─────────────────────────────────────┤
│                                     │
│ ✅ Validation: Passed               │
│ 🎭 Dialogue: 3 lines detected        │
│ 🤖 Model: Kling 2.5 Turbo          │
│ 💰 Cost: ~$0.40                    │
│ ⏱️ Est. Duration: 8 seconds        │
│                                     │
│ [Generate] [Edit Prompt]            │
│                                     │
└─────────────────────────────────────┘
```

#### UX Principles
- **Summary View:** All intelligence in one place
- **Visual Indicators:** Icons + colors for quick scanning
- **Cost Transparency:** Show estimated cost upfront
- **One-Click Generate:** Start generation with confidence
- **Quick Edit:** Easy to go back and refine

---

## 🎬 Micro-Interactions & Animations

### Validation Feedback
- **Fade In:** Errors fade in smoothly (0.3s)
- **Shake:** Input field shakes on error (subtle)
- **Pulse:** Success checkmark pulses once

### Dialogue Extraction
- **Slide In:** Dialogue cards slide in from right
- **Highlight:** Extracted text highlights in input
- **Confidence Animation:** Low confidence badge pulses

### Model Recommendation
- **Scale Up:** Badge scales up when recommendation changes
- **Color Transition:** Smooth color change for complexity bar
- **Sparkle Effect:** Subtle sparkle animation on recommendation

### Loading States
- **Skeleton Screens:** Show structure while analyzing
- **Progress Indicators:** Clear progress for long operations
- **Smooth Transitions:** Between analysis states

---

## ♿ Accessibility

### VoiceOver Support
- **Labels:** All UI elements have descriptive labels
- **Hints:** Contextual hints for complex interactions
- **Status Updates:** Announce validation state changes

### Dynamic Type
- **Scalable Text:** All text respects user font size preferences
- **Line Height:** Adequate spacing for readability

### Color Contrast
- **WCAG AA:** All text meets contrast requirements
- **Not Color-Only:** Don't rely solely on color for meaning
- **Dark Mode:** Full support for dark/light modes

### Keyboard Navigation
- **Tab Order:** Logical tab sequence
- **Focus Indicators:** Clear focus states
- **Keyboard Shortcuts:** Common actions accessible via keyboard

---

## 📱 Responsive Design

### iPhone (Portrait)
- **Stack Layout:** Vertical stacking for all components
- **Full-Width Cards:** Dialogue cards take full width
- **Bottom Sheet:** Model recommendation as bottom sheet

### iPhone (Landscape)
- **Side-by-Side:** Validation + input side-by-side when space allows
- **Compact Cards:** Smaller dialogue cards

### iPad
- **Two-Column:** Input + preview side-by-side
- **Larger Cards:** More spacious dialogue cards
- **Popover:** Model recommendation as popover

---

## 🎯 User Flows

### Flow 1: Writing a Prompt
```
1. User starts typing
   ↓
2. Real-time validation appears (fade in)
   ↓
3. Suggestions appear as user types
   ↓
4. Character counter updates
   ↓
5. When valid: Show success indicator
```

### Flow 2: Dialogue Detection
```
1. User finishes prompt
   ↓
2. Dialogue extraction runs (show loading)
   ↓
3. Dialogue cards appear (slide in)
   ↓
4. User reviews/edits dialogue
   ↓
5. User confirms or removes
```

### Flow 3: Model Recommendation
```
1. Prompt complexity analyzed
   ↓
2. Recommendation badge appears (scale up)
   ↓
3. User reviews reasons
   ↓
4. User accepts or overrides
   ↓
5. Selection saved for next time
```

### Flow 4: Pre-Generation Summary
```
1. All analysis complete
   ↓
2. Summary card appears
   ↓
3. User reviews all intelligence
   ↓
4. User clicks "Generate"
   ↓
5. Generation starts with confidence
```

---

## 🚀 Implementation Priority

### Phase 3.1: Core Validation UI (Week 1)
- [ ] ValidationFeedbackView component
- [ ] Real-time validation integration
- [ ] Character counter
- [ ] Error/suggestion banners

### Phase 3.2: Dialogue UI (Week 2)
- [ ] DialoguePreviewCard component
- [ ] Dialogue extraction integration
- [ ] Edit/remove/keep actions
- [ ] Confidence indicators

### Phase 3.3: Model Recommendation UI (Week 3)
- [ ] ModelRecommendationBadge component
- [ ] Complexity visualization
- [ ] Reasons display
- [ ] Override functionality

### Phase 3.4: Polish & Animation (Week 4)
- [ ] Micro-interactions
- [ ] Smooth transitions
- [ ] Accessibility improvements
- [ ] Responsive refinements

---

## 📐 Component Specifications

### ValidationBanner
- **Height:** Auto (min 44pt for touch)
- **Padding:** 16px horizontal, 12px vertical
- **Corner Radius:** 10px
- **Shadow:** Cinema depth level 1
- **Animation:** Fade in 0.3s, slide from top

### DialoguePreviewCard
- **Height:** Auto (min 80pt)
- **Padding:** 16px all sides
- **Corner Radius:** 12px
- **Shadow:** Cinema depth level 1
- **Animation:** Slide in from right 0.4s

### ModelRecommendationBadge
- **Width:** Full width (with margins)
- **Padding:** 24px all sides
- **Corner Radius:** 16px
- **Shadow:** Cinema depth level 2
- **Animation:** Scale up 0.3s with spring

---

## 🎨 Design Tokens

### Colors
```swift
// Validation States
validation.success = DirectorStudioTheme.Colors.success
validation.warning = DirectorStudioTheme.Colors.warning
validation.error = DirectorStudioTheme.Colors.error
validation.info = DirectorStudioTheme.Colors.info

// Dialogue
dialogue.speaker = DirectorStudioTheme.Colors.secondary
dialogue.text = Color.secondary
dialogue.confidence.low = Color.orange

// Model Recommendation
recommendation.complexity = DirectorStudioTheme.Colors.secondary
recommendation.reason = Color.primary
```

### Spacing
```swift
// Component spacing
component.innerPadding = DirectorStudioTheme.Spacing.small  // 16px
component.outerMargin = DirectorStudioTheme.Spacing.medium  // 24px
component.sectionSpacing = DirectorStudioTheme.Spacing.large // 32px
```

### Typography
```swift
// Headers
header.font = DirectorStudioTheme.Typography.headline
header.color = Color.primary

// Body
body.font = DirectorStudioTheme.Typography.body
body.color = Color.secondary

// Captions
caption.font = DirectorStudioTheme.Typography.caption
caption.color = Color.secondary.opacity(0.8)
```

---

## ✅ Success Metrics

### User Experience
- **Validation Errors:** < 5% of prompts have validation errors at generation time
- **Dialogue Accuracy:** > 90% of dialogue correctly attributed
- **Model Acceptance:** > 80% users accept recommended model
- **Time to Generate:** < 30 seconds from prompt to generation start

### Accessibility
- **VoiceOver Coverage:** 100% of Phase 3 UI elements
- **Color Contrast:** WCAG AA compliance
- **Dynamic Type:** Support for all system sizes

### Performance
- **Validation Latency:** < 100ms for real-time validation
- **Dialogue Extraction:** < 500ms for analysis
- **Model Recommendation:** < 200ms for calculation

---

## 🎬 Next Steps

1. **Design Review:** Review with team
2. **Prototype:** Create SwiftUI previews for all components
3. **User Testing:** Test with 5-10 users
4. **Iterate:** Refine based on feedback
5. **Implement:** Build Phase 3 components

---

**This planning document ensures Phase 3 UI is:**
- ✅ Intuitive and delightful
- ✅ Accessible to all users
- ✅ Consistent with design system
- ✅ Performance-optimized
- ✅ User-tested and validated

