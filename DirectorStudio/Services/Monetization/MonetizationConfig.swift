//
//  MonetizationConfig.swift
//  DirectorStudio
//
//  PURPOSE: Core monetization configuration following Platinum Guide specs
//

import Foundation

/// Core monetization configuration with 50% gross margin target
public struct MonetizationConfig {
    
    // MARK: - Core Constants
    
    /// Customer price per second in USD
    public static let PRICE_PER_SEC: Double = 0.15
    
    /// Tokens per 20 seconds (for stable accounting)
    public static let TOKENS_PER_20S: Double = 10.0
    
    /// Tokens per second (derived)
    public static let TOKENS_PER_SEC: Double = TOKENS_PER_20S / 20.0  // 0.5
    
    /// Target gross margin on credit economics
    public static let TARGET_MARGIN: Double = 0.50
    
    /// Current upstream cost per second (from environment or API)
    /// This should be updated dynamically from Pollo's actual pricing
    public static var CURRENT_UPSTREAM_COST: Double = {
        if let envValue = ProcessInfo.processInfo.environment["UPSTREAM_COST_PER_SEC"],
           let cost = Double(envValue) {
            return cost
        }
        // Default to $0.08/sec if not specified
        return 0.08
    }()
    
    // MARK: - Derived Values
    
    /// Maximum allowed cost per second to maintain target margin
    public static var ALLOWED_COST_PER_SEC: Double {
        PRICE_PER_SEC * (1 - TARGET_MARGIN)  // 0.075
    }
    
    /// Maximum cost per token to maintain margin
    public static var MAX_COST_PER_TOKEN: Double {
        ALLOWED_COST_PER_SEC / TOKENS_PER_SEC  // 0.15
    }
    
    /// Retail price per token for bundle sales
    public static var RETAIL_TOKEN_PRICE: Double {
        PRICE_PER_SEC / TOKENS_PER_SEC  // 0.30
    }
    
    /// Check if pricing is in degraded mode (margin at risk)
    public static var PRICING_DEGRADED: Bool {
        CURRENT_UPSTREAM_COST > MAX_COST_PER_TOKEN
    }
    
    /// Minimum price per second in degraded mode (2x upstream cost)
    public static var MIN_PRICE_PER_SEC: Double {
        2 * CURRENT_UPSTREAM_COST * TOKENS_PER_SEC
    }
    
    // MARK: - Bundle Discounts
    
    /// Discount tiers for bulk token purchases
    public static let BUNDLE_DISCOUNTS: [(tokens: Int, discountPercent: Double)] = [
        (100, 0.0),      // No discount
        (500, 0.05),     // 5% off
        (1000, 0.10),    // 10% off
        (5000, 0.15),    // 15% off
        (10000, 0.20),   // 20% off
        (50000, 0.25),   // 25% off (max discount)
    ]
    
    /// Overage multiplier when credits exhausted
    public static let OVERAGE_MULTIPLIER: Double = 1.2
    
    // MARK: - Operational Settings
    
    /// Minimum billable duration in seconds
    public static let MINIMUM_DURATION: Double = 1.0
    
    /// Maximum single video duration in seconds
    public static let MAXIMUM_DURATION: Double = 300.0  // 5 minutes
    
    /// Days before alerting on low margin
    public static let MARGIN_ALERT_DAYS: Int = 3
    
    // MARK: - Pricing Functions
    
    /// Calculate price in cents for a given duration
    public static func priceForSeconds(_ seconds: Double) -> Int {
        guard seconds >= MINIMUM_DURATION else { return 0 }
        let price = PRICE_PER_SEC * seconds
        // Round to nearest cent using banker's rounding
        return Int(round(price * 100))
    }
    
    /// Calculate credits needed for a given duration (high precision)
    public static func creditsForSeconds(_ seconds: Double) -> Double {
        return TOKENS_PER_SEC * seconds
    }
    
    /// Calculate tokens to debit (always ceil for accounting)
    public static func tokensToDebit(_ credits: Double) -> Int {
        return Int(ceil(credits))
    }
    
    /// Calculate price for overage tokens
    public static func overagePriceForTokens(_ tokens: Int) -> Double {
        return Double(tokens) * RETAIL_TOKEN_PRICE * OVERAGE_MULTIPLIER
    }
    
    /// Get bundle price with discount
    public static func bundlePrice(tokens: Int) -> (price: Double, discount: Double) {
        let basePrice = Double(tokens) * RETAIL_TOKEN_PRICE
        
        // Find applicable discount
        var discountPercent = 0.0
        for tier in BUNDLE_DISCOUNTS.reversed() {
            if tokens >= tier.tokens {
                discountPercent = tier.discountPercent
                break
            }
        }
        
        let finalPrice = basePrice * (1 - discountPercent)
        return (price: finalPrice, discount: discountPercent)
    }
    
    /// Validate pricing is safe (not selling at loss)
    public static func validatePricing() throws {
        guard !PRICING_DEGRADED else {
            throw MonetizationError.degradedMode(
                currentCost: CURRENT_UPSTREAM_COST,
                maxAllowed: MAX_COST_PER_TOKEN,
                minPrice: MIN_PRICE_PER_SEC
            )
        }
    }
    
    /// Calculate gross margin for a transaction
    public static func calculateMargin(revenue: Double, upstreamCost: Double) -> Double {
        guard revenue > 0 else { return 0 }
        return (revenue - upstreamCost) / revenue
    }
    
    /// Format price for display
    public static func formatPrice(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        return String(format: "$%.2f", dollars)
    }
    
    /// Format tokens for display
    public static func formatTokens(_ tokens: Double) -> String {
        if tokens == floor(tokens) {
            return String(format: "%.0f", tokens)
        } else {
            return String(format: "%.1f", tokens)
        }
    }
}

/// Monetization-specific errors
public enum MonetizationError: LocalizedError {
    case degradedMode(currentCost: Double, maxAllowed: Double, minPrice: Double)
    case insufficientDuration
    case overrideRequired
    
    public var errorDescription: String? {
        switch self {
        case .degradedMode(let current, let max, let min):
            return "Pricing degraded: Upstream cost $\(String(format: "%.3f", current))/sec exceeds max $\(String(format: "%.3f", max)). Minimum price must be $\(String(format: "%.2f", min))/sec to maintain margin."
        case .insufficientDuration:
            return "Minimum billable duration is 1 second"
        case .overrideRequired:
            return "Admin override required to continue sales in degraded mode"
        }
    }
}

// MARK: - Test Vectors

#if DEBUG
extension MonetizationConfig {
    /// QA Test Vector 1: 20s render
    public static func testVector1() -> Bool {
        let seconds = 20.0
        let price = priceForSeconds(seconds)  // Should be 300 cents ($3.00)
        let credits = creditsForSeconds(seconds)  // Should be 10.0
        let upstreamCost = seconds * 0.08  // $1.60
        let margin = calculateMargin(revenue: 3.00, upstreamCost: upstreamCost)
        
        print("Test Vector 1 (20s):")
        print("  Price: \(formatPrice(price)) (expected: $3.00)")
        print("  Credits: \(formatTokens(credits)) (expected: 10.0)")
        print("  Upstream: $\(String(format: "%.2f", upstreamCost))")
        print("  Margin: \(String(format: "%.1f%%", margin * 100)) (expected: 46.7%)")
        
        return price == 300 && credits == 10.0
    }
    
    /// QA Test Vector 2: 600s render (10 min)
    public static func testVector2() -> Bool {
        let seconds = 600.0
        let price = priceForSeconds(seconds)  // Should be 9000 cents ($90.00)
        let credits = creditsForSeconds(seconds)  // Should be 300.0
        let upstreamCost = seconds * 0.08  // $48.00
        let margin = calculateMargin(revenue: 90.00, upstreamCost: upstreamCost)
        
        print("Test Vector 2 (600s):")
        print("  Price: \(formatPrice(price)) (expected: $90.00)")
        print("  Credits: \(formatTokens(credits)) (expected: 300.0)")
        print("  Upstream: $\(String(format: "%.2f", upstreamCost))")
        print("  Margin: \(String(format: "%.1f%%", margin * 100)) (expected: 46.7%)")
        
        return price == 9000 && credits == 300.0
    }
    
    /// QA Test Vector 3: Degraded mode test
    public static func testVector3() -> Bool {
        // Save original
        let originalCost = CURRENT_UPSTREAM_COST
        
        // Set degraded cost
        CURRENT_UPSTREAM_COST = 0.16
        
        let degraded = PRICING_DEGRADED  // Should be true
        let minPrice = MIN_PRICE_PER_SEC  // Should be 0.16
        
        print("Test Vector 3 (Degraded):")
        print("  Upstream: $\(String(format: "%.2f", CURRENT_UPSTREAM_COST))/sec")
        print("  Degraded: \(degraded) (expected: true)")
        print("  Min Price: $\(String(format: "%.2f", minPrice))/sec (expected: $0.16)")
        
        // Restore original
        CURRENT_UPSTREAM_COST = originalCost
        
        return degraded == true && minPrice == 0.16
    }
    
    /// Run all test vectors
    public static func runAllTests() {
        print("\n=== Monetization Config Test Vectors ===\n")
        let test1 = testVector1()
        print("")
        let test2 = testVector2()
        print("")
        let test3 = testVector3()
        print("\n=== Results ===")
        print("Test 1: \(test1 ? "✅ PASS" : "❌ FAIL")")
        print("Test 2: \(test2 ? "✅ PASS" : "❌ FAIL")")
        print("Test 3: \(test3 ? "✅ PASS" : "❌ FAIL")")
        print("")
    }
}
#endif
