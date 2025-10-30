// MODULE: TokenSystem
// VERSION: 1.0.0
// PURPOSE: Token-based pricing system with quality tiers

import Foundation

/// Video quality tiers with associated token costs
public enum VideoQualityTier: String, CaseIterable, Codable {
    case economy = "Economy"
    case basic = "Basic"
    case pro = "Pro"
    case premium = "Premium"
    
    /// Base cost per second (what you pay Pollo.ai)
    public var baseCostPerSecond: Double {
        switch self {
        case .economy: return 0.07
        case .basic: return 0.10
        case .pro: return 0.12
        case .premium: return 0.30
        }
    }
    
    /// Customer price per second (with markup)
    public var customerPricePerSecond: Double {
        switch self {
        case .economy: return 0.20  // 186% markup
        case .basic: return 0.31    // 210% markup
        case .pro: return 0.37      // 208% markup
        case .premium: return 0.93  // 210% markup
        }
    }
    
    /// Tokens per second of video
    public var tokensPerSecond: Int {
        switch self {
        case .economy: return 20   // $0.20
        case .basic: return 31     // $0.31
        case .pro: return 37       // $0.37
        case .premium: return 93   // $0.93
        }
    }
    
    /// Token cost multiplier for each tier (used by TokenMeteringEngine)
    public var tokenMultiplier: Double {
        switch self {
        case .economy: return 0.65   // Cheapest option
        case .basic: return 1.0      // Baseline
        case .pro: return 1.19       // ~19% more than basic
        case .premium: return 3.0    // 3x basic price
        }
    }
    
    /// API endpoint for each tier
    public var apiEndpoint: String {
        switch self {
        case .economy: return "https://pollo.ai/api/platform/generation/kling-ai/kling-v1-6"
        case .basic: return "https://pollo.ai/api/platform/generation/pollo/pollo-v1-6"
        case .pro: return "https://pollo.ai/api/platform/generation/kling-ai/kling-v2-5-turbo"
        case .premium: return "https://pollo.ai/api/platform/generation/runway/runway-gen-4-turbo"
        }
    }
    
    /// Model name for display
    public var modelName: String {
        switch self {
        case .economy: return "Kling 1.6"
        case .basic: return "Pollo 1.6"
        case .pro: return "Kling 2.5 Turbo"
        case .premium: return "Runway Gen-4 Turbo"
        }
    }
    
    /// Display name for UI
    public var displayName: String {
        switch self {
        case .economy: return "Starter"
        case .basic: return "Standard"
        case .pro: return "Premium"
        case .premium: return "Runway Gen-4 (Your Key Required)"
        }
    }
    
    /// Short name for compact UI
    public var shortName: String {
        switch self {
        case .economy: return "Starter"
        case .basic: return "Standard"
        case .pro: return "Premium"
        case .premium: return "Runway (Your Key)"
        }
    }
    
    /// System icon
    public var icon: String {
        switch self {
        case .economy: return "dollarsign.circle"
        case .basic: return "bolt.circle"
        case .pro: return "video.circle"
        case .premium: return "crown.fill"
        }
    }
    
    /// Description for tooltips
    public var description: String {
        switch self {
        case .economy: return "Great for rapid prototyping and quick iterations"
        case .basic: return "Perfect balance of speed and quality for everyday content"
        case .pro: return "Cinematic excellence for your most important projects"
        case .premium: return "Unparalleled video quality with Runway Gen-4 (pricey but exceptional)"
        }
    }
    
    /// Features list
    public var features: [String] {
        switch self {
        case .economy:
            return ["Fast generation", "Great for drafts", "Up to 10 seconds", "Text & Image input"]
        case .basic:
            return ["Best value", "Reliable quality", "Up to 8 seconds", "Perfect for content creation"]
        case .pro:
            return ["Cinematic quality", "Enhanced motion", "Professional results", "Up to 10 seconds"]
        case .premium:
            return ["Unparalleled quality", "Runway Gen-4 Turbo", "Your own API key", "Premium pricing"]
        }
    }
    
    /// Max duration in seconds
    public var maxDuration: Int {
        switch self {
        case .economy: return 10
        case .basic: return 8
        case .pro: return 10
        case .premium: return 10
        }
    }
    
    /// Processing speed multiplier
    public var speedMultiplier: Double {
        switch self {
        case .economy: return 1.0
        case .basic: return 1.2
        case .pro: return 0.9
        case .premium: return 0.7
        }
    }
    
    /// Is this tier most popular?
    public var isPopular: Bool {
        self == .basic  // Standard tier is most popular
    }
}

/// Token bundle for purchase
public struct TokenBundle {
    public let id: String
    public let tokens: Int
    public let price: Double
    public let savings: Double?
    public let badge: String?
    public let isPopular: Bool
    
    /// Price per token
    public var pricePerToken: Double {
        price / Double(tokens)
    }
    
    /// Display price string
    public var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
    
    /// Savings percentage string
    public var savingsText: String? {
        guard let savings = savings else { return nil }
        return "Save \(Int(savings))%"
    }
    
    /// Standard bundles
    public static let bundles = [
        TokenBundle(
            id: "tokens_500",
            tokens: 500,
            price: 4.99,
            savings: nil,
            badge: nil,
            isPopular: false
        ),
        TokenBundle(
            id: "tokens_1000",
            tokens: 1000,
            price: 9.99,
            savings: nil,
            badge: nil,
            isPopular: false
        ),
        TokenBundle(
            id: "tokens_2200",
            tokens: 2200,
            price: 19.99,
            savings: 10,
            badge: "Save 10%",
            isPopular: true
        ),
        TokenBundle(
            id: "tokens_6000",
            tokens: 6000,
            price: 49.99,
            savings: 16.67,
            badge: "Best Value",
            isPopular: false
        )
    ]
}

/// Token calculation utilities
public struct TokenCalculator {
    
    /// Calculate token cost for a video
    /// Uses MonetizationConfig for accurate token calculation (0.5 tokens per second base)
    public static func calculateCost(
        duration: TimeInterval,
        quality: VideoQualityTier,
        includesEnhancement: Bool = true,
        includesContinuity: Bool = false
    ) -> Int {
        // Use MonetizationConfig for base token calculation (0.5 tokens per second)
        let baseCredits = MonetizationConfig.creditsForSeconds(duration)
        let baseTokens = MonetizationConfig.tokensToDebit(baseCredits)
        
        // Apply quality multiplier
        var totalCost = Double(baseTokens) * quality.tokenMultiplier
        
        // Add 20% for enhancement
        if includesEnhancement {
            totalCost = totalCost * 1.2
        }
        
        // Add 10% for continuity
        if includesContinuity {
            totalCost = totalCost * 1.1
        }
        
        return Int(ceil(totalCost))
    }
    
    /// Convert tokens to dollar value
    public static func tokensToDollars(_ tokens: Int) -> Double {
        Double(tokens) * 0.01
    }
    
    /// Convert dollars to tokens
    public static func dollarsToTokens(_ dollars: Double) -> Int {
        Int(dollars * 100)
    }
    
    /// Format tokens for display
    public static func formatTokens(_ tokens: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: tokens)) ?? "\(tokens)"
    }
    
    /// Estimate videos possible with token amount
    public static func estimateVideos(
        tokens: Int,
        duration: TimeInterval = 10,
        quality: VideoQualityTier = .pro
    ) -> Int {
        let costPerVideo = calculateCost(duration: duration, quality: quality)
        return tokens / costPerVideo
    }
}

/// Free trial configuration
public struct FreeTrialConfig {
    public static let tokens = 150
    public static let requiresPaymentMethod = true
    public static let description = "150 free tokens with payment method"
    
    /// Check if user is eligible
    public static func isEligible(hasPaymentMethod: Bool, hasMadePurchase: Bool) -> Bool {
        !hasMadePurchase && hasPaymentMethod
    }
}
