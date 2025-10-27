# Monetization UI Guide for LensDepth
**Credit-based video generation pricing**

## 📋 System Overview

DirectorStudio uses a **credit-based consumption model**:
- **3.6 credits per second** of video
- **Volume-discounted bundles** (17-40% savings)
- **10 seconds free per account** (36 credits on signup)
- **Transparent, predictable pricing**

## 💰 Credit Pricing System

### Core Economics
- **Credits per Second**: 3.6 credits
- **Base Price**: $0.0499/credit (Starter Pack)
- **Volume Discount Range**: 0-40%

### Credit Bundles

| Bundle Name | Credits | Price | $/Credit | Video Time | Discount |
|-------------|---------|-------|----------|------------|----------|
| **Starter Pack** | 100 | $4.99 | $0.0499 | ~28s | 0% |
| **Explorer Bundle** | 350 | $14.49 | $0.0414 | ~97s | 17% |
| **Creator Pack** | 1,000 | $36.99 | $0.0370 | ~4.6min | 26% |
| **Video Pro Bundle** | 3,000 | $99.99 | $0.0333 | ~13.8min | 33% |
| **Mega Studio Pack** | 10,000 | $299.99 | $0.0300 | ~46min | 40% |

### Example Costs

| Duration | Credits | Cost (Starter) | Cost (Mega) |
|----------|---------|----------------|-------------|
| 5s | 18 | $0.90 | $0.54 |
| 10s | 36 | $1.80 | $1.08 |
| 30s | 108 | $5.39 | $3.24 |
| 60s | 216 | $10.78 | $6.48 |
| 120s | 432 | $21.55 | $12.96 |

### Free Trial
- **36 credits** on signup (10 seconds of video)
- One-time only, no expiration
- Perfect for first-time experience

## 🎨 UI Components for Monetization

### 1. Live Cost Preview (Before Generation)

```swift
struct LiveCostPreview: View {
    let duration: TimeInterval
    @ObservedObject var creditsManager = CreditsManager.shared
    
    // 3.6 credits per second
    var creditsNeeded: Int {
        Int(ceil(duration * 3.6))
    }
    
    var costUSD: Double {
        // Cost using Mega bundle rate ($0.03/credit)
        Double(creditsNeeded) * 0.03
    }
    
    var canAfford: Bool {
        creditsManager.availableCredits >= creditsNeeded
    }
    
    var body: some View {
        HStack(spacing: LensDepthTokens.spacingInner) {
            Image(systemName: "sparkles")
                .foregroundColor(LensDepthTokens.colorPrimaryAmber)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("This will cost:")
                    .font(.system(size: 13))
                    .foregroundColor(LensDepthTokens.colorTextSecondary)
                
                HStack(spacing: 8) {
                    Text("\(creditsNeeded) credits")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(
                            canAfford 
                            ? LensDepthTokens.colorTextPrimary 
                            : LensDepthTokens.colorSemanticDanger
                        )
                    
                    Text("(~$\(String(format: "%.2f", costUSD)))")
                        .font(.system(size: 13))
                        .foregroundColor(LensDepthTokens.colorTextSecondary)
                }
            }
            
            Spacer()
            
            if !canAfford {
                Text("Insufficient credits")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(LensDepthTokens.colorSemanticDanger)
            }
        }
        .padding(LensDepthTokens.spacingOuter)
        .background(LensDepthTokens.colorSurfacePanel)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    canAfford ? Color.clear : LensDepthTokens.colorSemanticDanger,
                    lineWidth: 2
                )
        )
    }
}
```

### 2. Credit Balance Display (Always Visible)

```swift
struct CreditBalanceBadge: View {
    @ObservedObject var creditsManager = CreditsManager.shared
    
    var videoSecondsRemaining: Int {
        Int(Double(creditsManager.availableCredits) / 3.6)
    }
    
    var body: some View {
        Button(action: { /* show purchase sheet */ }) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13))
                    .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(creditsManager.availableCredits)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(LensDepthTokens.colorTextPrimary)
                    
                    Text("~\(videoSecondsRemaining)s")
                        .font(.system(size: 11))
                        .foregroundColor(LensDepthTokens.colorTextSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(LensDepthTokens.colorSurfacePanel)
            .cornerRadius(20)
            .modifier(LensDepthShadow(depth: .surface))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### 3. Bundle Purchase Cards

```swift
struct BundlePurchaseView: View {
    @State private var selectedBundle: Int?
    
    let bundles = [
        (credits: 100, name: "Starter Pack", price: 4.99, discount: 0),
        (credits: 350, name: "Explorer Bundle", price: 14.49, discount: 17),
        (credits: 1000, name: "Creator Pack", price: 36.99, discount: 26),
        (credits: 3000, name: "Video Pro Bundle", price: 99.99, discount: 33),
        (credits: 10000, name: "Mega Studio Pack", price: 299.99, discount: 40)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: LensDepthTokens.spacingOuter) {
                ForEach(bundles, id: \.credits) { bundle in
                    BundleCard(
                        credits: bundle.credits,
                        name: bundle.name,
                        price: bundle.price,
                        discount: bundle.discount,
                        isSelected: selectedBundle == bundle.credits,
                        onSelect: { selectedBundle = bundle.credits }
                    )
                }
            }
            .padding(LensDepthTokens.spacingMargin)
        }
        .background(LensDepthTokens.colorBackgroundBase)
    }
}

struct BundleCard: View {
    let credits: Int
    let name: String
    let price: Double
    let discount: Int
    let isSelected: Bool
    let onSelect: () -> Void
    
    var videoSeconds: Int {
        Int(Double(credits) / 3.6)
    }
    
    var videoMinutes: Int {
        videoSeconds / 60
    }
    
    var pricePerCredit: Double {
        price / Double(credits)
    }
    
    var savingsText: String? {
        guard discount > 0 else { return nil }
        return "Save \(discount)%"
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: LensDepthTokens.spacingOuter) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(LensDepthTokens.colorTextPrimary)
                        
                        Text("\(credits) credits")
                            .font(.system(size: 15))
                            .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                    }
                    
                    Spacer()
                    
                    if let savings = savingsText {
                        Text(savings)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(LensDepthTokens.colorSemanticSuccess)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(LensDepthTokens.colorSemanticSuccess.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                
                // Outcome
                Text("Create up to \(videoMinutes) minutes of video")
                    .font(.system(size: 13))
                    .foregroundColor(LensDepthTokens.colorTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .background(LensDepthTokens.colorTextSecondary.opacity(0.3))
                
                // Price
                HStack {
                    Text("$\(String(format: "%.2f", price))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(LensDepthTokens.colorTextPrimary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(String(format: "%.4f", pricePerCredit))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(LensDepthTokens.colorTextSecondary)
                        
                        Text("per credit")
                            .font(.system(size: 11))
                            .foregroundColor(LensDepthTokens.colorTextSecondary)
                    }
                }
            }
            .padding(LensDepthTokens.spacingOuter)
            .background(LensDepthTokens.colorSurfacePanel)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? LensDepthTokens.colorPrimaryAmber : Color.clear,
                        lineWidth: 2
                    )
            )
            .modifier(LensDepthShadow(depth: isSelected ? .floating : .surface))
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### 4. Post-Generation Summary

```swift
struct GenerationSummary: View {
    let creditsUsed: Int
    let duration: TimeInterval
    @ObservedObject var creditsManager = CreditsManager.shared
    
    var costUSD: Double {
        // Cost using Mega bundle rate
        Double(creditsUsed) * 0.03
    }
    
    var body: some View {
        VStack(spacing: LensDepthTokens.spacingOuter) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(LensDepthTokens.colorSemanticSuccess)
            
            // Title
            Text("Generation Complete")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(LensDepthTokens.colorTextPrimary)
            
            // Cost breakdown
            VStack(spacing: LensDepthTokens.spacingInner) {
                CostRow(
                    label: "Duration",
                    value: "\(Int(duration))s"
                )
                
                CostRow(
                    label: "Credits Used",
                    value: "\(creditsUsed)"
                )
                
                CostRow(
                    label: "Cost",
                    value: "$\(String(format: "%.2f", costUSD))"
                )
                
                Divider()
                    .background(LensDepthTokens.colorTextSecondary.opacity(0.3))
                
                HStack {
                    Text("Remaining Balance")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(LensDepthTokens.colorTextSecondary)
                    
                    Spacer()
                    
                    Text("\(creditsManager.availableCredits) credits")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(LensDepthTokens.colorPrimaryAmber)
                }
            }
            .padding(LensDepthTokens.spacingOuter)
            .background(LensDepthTokens.colorSurfacePanel)
            .cornerRadius(12)
        }
        .padding(LensDepthTokens.spacingMargin)
        .background(LensDepthTokens.colorBackgroundBase)
        .cornerRadius(16)
        .modifier(LensDepthShadow(depth: .modal))
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

## 🎨 Color Semantics for Monetization

Use these LensDepth colors for monetary UI:

| Element | Color Token | Rationale |
|---------|-------------|-----------|
| Credit count | `colorPrimaryAmber` | Attention, value |
| USD cost | `colorTextSecondary` | Secondary info |
| Insufficient balance | `colorSemanticDanger` | Alert, warning |
| Savings badge | `colorSemanticSuccess` | Positive outcome (17-40% off) |
| Balance badge background | `colorSurfacePanel` | Subtle, non-intrusive |
| Free trial badge | `colorSemanticSuccess` | Positive first impression |

## 📊 Transparency Guidelines

### Always Show BEFORE Action
- Credit cost (e.g., "36 credits")
- USD equivalent (e.g., "~$1.08")
- Remaining balance after action
- Warning if balance insufficient

### Always Show AFTER Action
- Credits debited
- USD cost
- New balance
- Duration generated

### Never Hide
- True per-credit pricing
- Bundle discount percentages (17-40%)
- Remaining balance
- Free trial status (36 credits = 10 seconds)

## 🚫 What NOT to Do

❌ Hardcode credit costs (always use `3.6 credits/second`)  
❌ Hide USD costs from users  
❌ Use exploitative gamification (we keep it simple)  
❌ Auto-purchase credits  
❌ Expire credits (they never expire)  
❌ Offer subscription with recurring charges (PAYG only)

## ✅ Integration Checklist

When building monetization UI:
- [ ] Use `CreditsManager.shared` for balance
- [ ] Calculate costs with `Int(ceil(duration * 3.6))`
- [ ] Display with `$\(String(format: "%.2f", cost))`
- [ ] Use LensDepth color tokens
- [ ] Show both credits and USD
- [ ] Include "insufficient balance" state
- [ ] Show free trial badge for new users (36 credits)
- [ ] Test with various durations (5s, 10s, 30s, 60s, 120s)

## 📱 Example Integration

```swift
import SwiftUI

struct VideoGenerationView: View {
    @State private var duration: TimeInterval = 10.0
    @ObservedObject var creditsManager = CreditsManager.shared
    
    var creditsNeeded: Int {
        Int(ceil(duration * 3.6))
    }
    
    var costUSD: Double {
        Double(creditsNeeded) * 0.03  // Mega bundle rate
    }
    
    var canAfford: Bool {
        creditsManager.availableCredits >= creditsNeeded
    }
    
    var body: some View {
        VStack(spacing: LensDepthTokens.spacingOuter) {
            // Duration slider
            Slider(value: $duration, in: 1...20, step: 1)
            
            // Cost preview
            LiveCostPreview(duration: duration)
            
            // Generate button
            LDPrimaryButton(
                title: "Generate Video (\(creditsNeeded) credits)",
                action: { /* generate */ }
            )
            .disabled(!canAfford)
            
            // Insufficient credits warning
            if !canAfford {
                Text("Need \(creditsNeeded - creditsManager.availableCredits) more credits")
                    .foregroundColor(LensDepthTokens.colorSemanticDanger)
                    .font(.system(size: 13))
            }
        }
        .padding(LensDepthTokens.spacingMargin)
    }
}
```

## 🎁 Free Trial Implementation

```swift
struct OnboardingView: View {
    @ObservedObject var creditsManager = CreditsManager.shared
    
    var body: some View {
        VStack(spacing: LensDepthTokens.spacingOuter) {
            // Free trial badge
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .foregroundColor(LensDepthTokens.colorSemanticSuccess)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome Gift!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(LensDepthTokens.colorTextPrimary)
                    
                    Text("36 free credits • Create 10 seconds of AI video")
                        .font(.system(size: 13))
                        .foregroundColor(LensDepthTokens.colorTextSecondary)
                }
            }
            .padding(LensDepthTokens.spacingOuter)
            .background(LensDepthTokens.colorSemanticSuccess.opacity(0.1))
            .cornerRadius(12)
        }
        .onAppear {
            // Grant free trial on first launch
            if creditsManager.isNewUser {
                creditsManager.grantFreeTrialCredits(36)
            }
        }
    }
}
```

---

**Credit System: 3.6 credits/second • 10 seconds free per account • Volume discounts 17-40% • No expiration** ✅


