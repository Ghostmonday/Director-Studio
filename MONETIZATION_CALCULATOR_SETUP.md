# Monetization Calculator Setup

## Summary

I've created a comprehensive cost calculation and monetization analysis system for DirectorStudio. This addresses the issue where costs were incorrectly calculated (700 tokens needed when should be much less).

## What Was Fixed

### 1. **Cost Calculation Bug**
**Problem:** In `VideoGenerationScreen.swift`, multi-clip generation was calculating costs incorrectly:
```swift
// ❌ OLD (WRONG): Used 20 tokens per second (way too high!)
let tokensForDuration = Int(take.estimatedDuration * 20)

// ✅ NEW (CORRECT): Uses MonetizationConfig (0.5 tokens per second)
let credits = MonetizationConfig.creditsForSeconds(take.estimatedDuration)
let tokensForDuration = MonetizationConfig.tokensToDebit(credits)
```

**Impact:** This was causing the "need 700, have 150" error for reasonable video lengths.

### 2. **New Cost Calculator Tool**
Created `CostCalculator.swift` with comprehensive cost calculation functions:
- Single video cost calculation
- Multi-clip film cost calculation  
- Monetization analysis (profit margins, ROI)
- Token estimation helpers

### 3. **Monetization Analysis View**
Created `MonetizationAnalysisView.swift` - A full UI tool that lets you:
- Calculate costs for any video duration/quality
- Analyze profit margins and upstream costs
- Estimate how many videos you can generate with available tokens
- Adjust upstream costs to see impact on profitability
- View detailed breakdowns

## Files Created

1. **`DirectorStudio/Services/Monetization/CostCalculator.swift`**
   - Core cost calculation logic
   - Monetization analysis functions
   - Film cost breakdown calculations

2. **`DirectorStudio/Features/Settings/MonetizationAnalysisView.swift`**
   - User-facing calculator UI
   - Interactive cost analysis tool
   - Detailed breakdown views

## Files Modified

1. **`DirectorStudio/Features/Prompt/VideoGenerationScreen.swift`**
   - Fixed cost calculation bug (line 182-186)

2. **`DirectorStudio/Features/Settings/PolishedSettingsView.swift`**
   - Added "Monetization Calculator" button in Preferences section
   - Added sheet presentation for calculator view

## How to Use

### In the App:
1. Go to **Settings** tab
2. Scroll to **Preferences** section
3. Tap **"Monetization Calculator"**
4. Adjust duration, quality, features
5. See real-time cost breakdown and profit analysis

### For Development:
Use `CostCalculator` functions directly:
```swift
// Calculate single video cost
let cost = CostCalculator.calculateVideoCost(
    duration: 10.0,
    quality: .basic,
    enabledStages: [.enhancement]
)

// Analyze monetization
let analysis = CostCalculator.analyzeMonetization(
    costBreakdown: cost,
    upstreamCostPerSecond: 0.08
)

// Estimate videos possible
let estimate = CostCalculator.estimateVideosPossible(
    availableTokens: 150,
    duration: 10.0
)
```

## Cost Formula Reference

**Base Calculation:**
- 0.5 tokens per second (MonetizationConfig.TOKENS_PER_SEC)
- Price: $0.15 per second (MonetizationConfig.PRICE_PER_SEC)

**Multipliers:**
- Enhancement: +20%
- Continuity: +10%
- Quality tiers: 0.65x (Economy) to 3.0x (Premium)

**Example:**
- 10 seconds basic video = 5 tokens = $1.50
- 10 seconds with enhancement = 6 tokens = $1.80
- 35 seconds (7 takes × 5s) basic = 17.5 tokens = $5.25

## Next Steps

1. **Add files to Xcode project** (needed for build):
   - Add `CostCalculator.swift` to Monetization group
   - Add `MonetizationAnalysisView.swift` to Settings group
   - Add both to Sources build phase

2. **Test the calculator:**
   - Build and run app
   - Navigate to Settings → Monetization Calculator
   - Verify cost calculations match expected values

3. **Update cost displays:**
   - Use `CostCalculator` throughout app for consistent pricing
   - Replace manual calculations with calculator functions

## Cost Calculation Examples

### Single 10-Second Video:
- Base: 5 tokens ($1.50)
- With Enhancement: 6 tokens ($1.80)
- Pro Quality: 5.95 tokens ($1.79)

### Multi-Clip Film (35 seconds, 7 takes):
- Base: 17.5 tokens ($5.25)
- With Enhancement: 21 tokens ($6.30)
- Previously calculated: 700 tokens ❌ (way too high!)

## Profit Analysis

The calculator shows:
- **Revenue:** What customer pays
- **Upstream Cost:** What you pay Pollo/AI services
- **Gross Profit:** Revenue - Cost
- **Margin:** Percentage profit (target: 50%)

Example for 10-second basic video:
- Revenue: $1.50
- Upstream Cost: $0.80 (at $0.08/sec)
- Profit: $0.70
- Margin: 46.7% ✅

---

**Status:** Files created, ready to add to Xcode project and test.

