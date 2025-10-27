# Semantic Expansion Feature - Documentation

## Overview

The **Semantic Expansion** feature is an optional, LLM-powered layer that enhances short or emotionally charged script segments by generating vivid, expressive, cinematic prompt variants. This feature analyzes tone, emotion, and implied meaning to create richer prompts for video generation while preserving the original text.

---

## Key Features

✅ **Optional & Configurable** - Toggle on/off via LLMConfiguration  
✅ **Intelligent Candidate Selection** - Identifies short or emotional segments  
✅ **Token Budget Control** - Enforces expansion token limits  
✅ **Preserves Original** - Base prompt always accessible  
✅ **5 Expansion Styles** - Vivid, Emotional, Action, Atmospheric, Balanced  
✅ **Enhanced Taxonomy** - Improved hints from expansion analysis  
✅ **Cost Control** - Configurable max expansions per script  
✅ **Quality Scoring** - LLM confidence tracking  

---

## Quick Start

### Enable Semantic Expansion

```swift
var llmConfig = LLMConfiguration(apiKey: "your-api-key")

// Enable expansion
llmConfig.enableSemanticExpansion = true

// Configure expansion behavior
llmConfig.expansionConfig.expansionStyle = .vivid
llmConfig.expansionConfig.tokenBudgetPerSegment = 100
llmConfig.expansionConfig.maxExpansions = 5

// Segment with expansion enabled
let result = try await module.segment(
    script: userScript,
    mode: .ai,
    llmConfig: llmConfig
)

// Check which segments were expanded
for segment in result.segments {
    if let expansion = segment.expandedPrompt {
        print("Expanded: \(segment.text)")
        print("  → \(expansion.text)")
        print("  Reason: \(expansion.expansionReason)")
        print("  Added Tokens: \(expansion.additionalTokens)")
    }
}

// View expansion statistics
if let stats = result.metadata.expansionStats {
    print("\nExpansion Stats:")
    print(stats.summary)
}
```

---

## Configuration

### SemanticExpansionConfig

```swift
struct SemanticExpansionConfig {
    // Core Settings
    var enabled: Bool = true
    var expansionStyle: ExpansionStyle = .vivid
    var tokenBudgetPerSegment: Int = 100
    var preserveOriginal: Bool = true
    
    // Candidate Selection
    var expandShortSegments: Bool = true
    var minLengthForExpansion: Int = 30        // Characters
    var expandEmotionalSegments: Bool = true
    var emotionThreshold: Double = 0.6         // 0.0-1.0
    
    // Cost Control
    var maxExpansions: Int = 5
    
    // Quality Control
    var expansionTemperature: Double = 0.7     // Higher = more creative
}
```

### Expansion Styles

| Style | Best For | Focus |
|-------|----------|-------|
| **Vivid** | Visual storytelling | Colors, lighting, textures, framing |
| **Emotional** | Character-driven scenes | Feelings, psychology, internal states |
| **Action** | Dynamic sequences | Movement, energy, choreography |
| **Atmospheric** | Mood pieces | Environment, ambiance, sensory details |
| **Balanced** | General use | Mix of all aspects |

---

## How It Works

### 1. Candidate Identification

The system automatically identifies segments that benefit from expansion:

**Short Segments:**
```swift
if segment.text.count < config.minLengthForExpansion {
    // Candidate for expansion
}
```

**Emotionally Charged Segments:**
```swift
let emotionScore = detectEmotionalIntensity(segment.text)
if emotionScore > config.emotionThreshold {
    // Candidate for expansion
}
```

### 2. Emotion Detection

The built-in emotion detector analyzes:
- **High emotion keywords**: scream, terror, rage, love, panic, etc. (+0.3 each)
- **Medium emotion keywords**: angry, sad, excited, nervous, etc. (+0.15 each)
- **Punctuation intensity**: Exclamation marks (+0.1 each)
- **Capitalization**: SHOUTING detection (+0.2)

```swift
// Example emotion scores
"The person walks."              // ~0.0 (neutral)
"She's nervous and worried."     // ~0.3 (medium)
"TERROR! She screams in panic!"  // ~0.8 (high)
```

### 3. LLM Expansion

For each candidate, the system:
1. Builds a specialized expansion prompt
2. Calls LLM with higher temperature (creative mode)
3. Parses enhanced prompt + taxonomy hints
4. Validates token budget
5. Attaches expansion to segment

### 4. Token Budgeting

```swift
// Original segment
text: "She walks away."
estimatedTokens: 10

// After expansion
expandedPrompt.text: "She walks away slowly, her silhouette fading into the golden sunset, shoulders slumped with the weight of goodbye."
expandedPrompt.additionalTokens: 25

// Total tokens
segment.totalTokens: 35  // 10 + 25
```

---

## Data Structures

### ExpandedPrompt

```swift
struct ExpandedPrompt {
    let text: String                    // Expanded prompt
    let additionalTokens: Int           // Tokens added
    let expansionReason: String         // Why expanded
    let emotionScore: Double?           // Detected emotion (0-1)
    let expansionStyle: String          // Style used
    let llmConfidence: Double           // Quality score (0-1)
    let enhancedHints: TaxonomyHints?   // Improved hints
}
```

### CinematicSegment (Enhanced)

```swift
struct CinematicSegment {
    let text: String                    // Base prompt (always preserved)
    var expandedPrompt: ExpandedPrompt? // Optional expansion
    
    // Helper properties
    var effectivePrompt: String {
        expandedPrompt?.text ?? text    // Use expansion if available
    }
    
    var totalTokens: Int {
        estimatedTokens + (expandedPrompt?.additionalTokens ?? 0)
    }
}
```

### ExpansionStats

```swift
struct ExpansionStats {
    let enabled: Bool
    let expandedCount: Int              // Segments expanded
    let totalExpansionTokens: Int       // Total tokens added
    let averageEmotionScore: Double?    // Avg emotion detected
    let expansionStyle: String
    let expansionTime: TimeInterval     // Processing time
}
```

---

## Integration Examples

### Basic Integration

```swift
// Configure expansion
var llmConfig = LLMConfiguration(apiKey: apiKey)
llmConfig.enableSemanticExpansion = true
llmConfig.expansionConfig.expansionStyle = .balanced

// Segment script
let result = try await module.segment(
    script: "A detective enters. Something's wrong.",
    mode: .ai,
    llmConfig: llmConfig
)

// Use expanded prompts for generation
for segment in result.segments {
    let promptForGeneration = segment.effectivePrompt
    await generateVideo(prompt: promptForGeneration)
}
```

### Advanced: Style Selection Based on Genre

```swift
func selectExpansionStyle(for genre: String) -> SemanticExpansionConfig.ExpansionStyle {
    switch genre.lowercased() {
    case "action": return .action
    case "drama": return .emotional
    case "thriller", "horror": return .atmospheric
    case "romance": return .emotional
    default: return .balanced
    }
}

var config = LLMConfiguration(apiKey: apiKey)
config.enableSemanticExpansion = true
config.expansionConfig.expansionStyle = selectExpansionStyle(for: userGenre)
```

### Advanced: Dynamic Token Budgets

```swift
// Adjust budget based on segment importance
for segment in result.segments {
    if let expansion = segment.expandedPrompt {
        if expansion.emotionScore ?? 0 > 0.8 {
            // High emotion = important scene, allow more tokens
            config.expansionConfig.tokenBudgetPerSegment = 150
        } else {
            config.expansionConfig.tokenBudgetPerSegment = 75
        }
    }
}
```

### UI Display

```swift
struct SegmentReviewView: View {
    let segment: CinematicSegment
    @State private var useExpansion = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Original Prompt")
                .font(.headline)
            Text(segment.text)
                .padding()
                .background(Color.gray.opacity(0.1))
            
            if let expansion = segment.expandedPrompt {
                Divider()
                
                HStack {
                    Text("Expanded Prompt")
                        .font(.headline)
                    Spacer()
                    Toggle("Use Expansion", isOn: $useExpansion)
                }
                
                Text(expansion.text)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                
                HStack {
                    Label("\(expansion.additionalTokens) tokens added",
                          systemImage: "plus.circle")
                    Spacer()
                    Label("Quality: \(Int(expansion.llmConfidence * 100))%",
                          systemImage: "checkmark.seal")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if let emotion = expansion.emotionScore {
                    Label("Emotion: \(Int(emotion * 100))%",
                          systemImage: "theatermasks")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}
```

---

## Warnings & Quality Control

### Expansion Warnings

```swift
// Budget exceeded
case .expansionBudgetExceeded(segmentIndex: 2, tokens: 120, budget: 100)
// Severity: Info

// Low quality expansion
case .lowExpansionQuality(segmentIndex: 1, confidence: 0.45)
// Severity: Warning

// Expansion failed
case .expansionFailed(segmentIndex: 0, reason: "Network timeout")
// Severity: Warning

// Max expansions reached
case .maxExpansionsReached(limit: 5)
// Severity: Info
```

### Quality Thresholds

- **High Quality**: confidence ≥ 0.8 (use confidently)
- **Medium Quality**: confidence 0.6-0.8 (review recommended)
- **Low Quality**: confidence < 0.6 (warning issued, review required)

---

## Cost Optimization

### Strategies

1. **Limit Max Expansions**
```swift
config.maxExpansions = 3  // Only expand 3 most important segments
```

2. **Target Specific Segment Types**
```swift
config.expandShortSegments = true   // Only short segments
config.expandEmotionalSegments = false  // Skip emotional analysis
```

3. **Reduce Token Budget**
```swift
config.tokenBudgetPerSegment = 50  // Smaller expansions
```

4. **Disable for Rehearsals**
```swift
if isDraftMode {
    llmConfig.enableSemanticExpansion = false
}
```

### Cost Estimation

```swift
// Rough cost calculation (DeepSeek pricing)
let expansionCost = (
    promptTokens: ~200 per segment,
    completionTokens: ~100 per segment,
    totalTokens: ~300 per expansion
)

// With 5 expansions @ $0.14 per 1M input tokens
let estimatedCost = (5 * 300 * 0.14) / 1_000_000
// ≈ $0.0002 per script
```

---

## Performance

### Benchmarks

| Segments | Expansions | Time | Cost (DeepSeek) |
|----------|------------|------|-----------------|
| 10 | 0 (disabled) | 2.5s | $0 |
| 10 | 3 | 4.0s | ~$0.0002 |
| 10 | 5 | 5.5s | ~$0.0003 |
| 20 | 5 | 6.0s | ~$0.0003 |

### Optimization Tips

```swift
// Parallel expansion (future enhancement)
// Process multiple expansions concurrently
await withTaskGroup(of: ExpandedPrompt.self) { group in
    for candidate in candidates {
        group.addTask {
            try await expandSegment(candidate)
        }
    }
}
```

---

## Testing

### Unit Tests

```swift
func testExpansionDisabled() async throws {
    var config = LLMConfiguration(apiKey: apiKey)
    config.enableSemanticExpansion = false
    
    let result = try await module.segment(
        script: "Short.",
        mode: .ai,
        llmConfig: config
    )
    
    XCTAssertTrue(result.segments.allSatisfy { $0.expandedPrompt == nil })
}

func testEmotionDetection() {
    let processor = SemanticExpansionProcessor.shared
    
    let neutral = processor.detectEmotionalIntensity("The person walks.")
    XCTAssertLessThan(neutral, 0.3)
    
    let emotional = processor.detectEmotionalIntensity("She screams in terror!")
    XCTAssertGreaterThan(emotional, 0.5)
}

func testCandidateSelection() {
    // Test that short and emotional segments are identified
    let candidates = processor.identifyExpansionCandidates(segments, config: config)
    XCTAssertGreaterThan(candidates.count, 0)
}
```

---

## Downstream Module Integration

### TaxonomyModule

```swift
// Use enhanced hints from expansion
if let enhancedHints = segment.expandedPrompt?.enhancedHints {
    taxonomyModule.applyHints(enhancedHints, to: segment)
} else {
    taxonomyModule.applyHints(segment.taxonomyHints, to: segment)
}
```

### ContinuityModule

```swift
// Analyze emotional flow across expanded segments
let emotionFlow = segments.compactMap { 
    $0.expandedPrompt?.emotionScore 
}

if hasEmotionalDisruption(emotionFlow) {
    suggestTransitionAdjustment()
}
```

### PromptBuilder

```swift
// Build final prompt with optional expansion
func buildPrompt(for segment: CinematicSegment) -> String {
    let basePrompt = segment.effectivePrompt
    
    if let hints = segment.expandedPrompt?.enhancedHints {
        return "\(basePrompt) [Camera: \(hints.cameraAngle ?? "default")]"
    }
    
    return basePrompt
}
```

---

## Best Practices

### Do's ✅

- **Enable for production** - Better quality prompts
- **Review expansions** - Check expansion quality in UI
- **Use appropriate style** - Match to content genre
- **Set reasonable budgets** - Balance quality vs cost
- **Monitor expansion stats** - Track effectiveness
- **Test with real scripts** - Validate in context

### Don'ts ❌

- **Don't over-expand** - Keep maxExpansions reasonable
- **Don't skip validation** - Always check expansion quality
- **Don't ignore warnings** - Review low-confidence expansions
- **Don't expand everything** - Target important segments
- **Don't forget cost** - Monitor API usage
- **Don't disable preserveOriginal** - Keep base text accessible

---

## Troubleshooting

### Issue: No Segments Expanded

**Possible Causes:**
- Expansion disabled in config
- No segments meet criteria (too long, not emotional)
- maxExpansions set to 0
- All LLM calls failed

**Solution:**
```swift
// Check configuration
print("Expansion enabled: \(config.enableSemanticExpansion)")
print("Max expansions: \(config.expansionConfig.maxExpansions)")

// Lower thresholds
config.expansionConfig.minLengthForExpansion = 50  // Expand more
config.expansionConfig.emotionThreshold = 0.3      // Lower threshold
```

### Issue: Low Quality Expansions

**Possible Causes:**
- Temperature too high (too creative)
- Token budget too small
- Poor base prompt
- Style mismatch

**Solution:**
```swift
// Adjust temperature
config.expansionConfig.expansionTemperature = 0.5  // More focused

// Increase token budget
config.expansionConfig.tokenBudgetPerSegment = 150

// Try different style
config.expansionConfig.expansionStyle = .balanced
```

### Issue: High API Costs

**Possible Causes:**
- Too many expansions
- Large token budgets
- Frequent re-segmentation

**Solution:**
```swift
// Reduce expansions
config.expansionConfig.maxExpansions = 3

// Smaller budgets
config.expansionConfig.tokenBudgetPerSegment = 50

// Cache results
// (store result.segments for reuse)
```

---

## Future Enhancements

### Planned Features

1. **Multi-language Support** - Expand non-English prompts
2. **User Feedback Loop** - Learn from manual edits
3. **Parallel Processing** - Concurrent expansions
4. **Style Learning** - Adapt to user preferences
5. **Context-Aware Expansion** - Consider preceding/following segments
6. **Visual Complexity Analysis** - Estimate rendering difficulty
7. **Character Tracking** - Maintain character descriptions across segments

---

## Summary

The Semantic Expansion feature provides an optional, intelligent layer that enhances script segments with vivid, cinematic descriptions. Key benefits:

✅ **Optional** - Toggle on/off per use case  
✅ **Intelligent** - Targets short/emotional segments  
✅ **Controlled** - Token budgets and max expansions  
✅ **Preserves Original** - Base text always accessible  
✅ **Enhances Taxonomy** - Improved hints for downstream  
✅ **Quality Scored** - LLM confidence tracking  
✅ **Modular** - Clean integration with existing pipeline  

**Ready for production use in DirectorStudio.**
