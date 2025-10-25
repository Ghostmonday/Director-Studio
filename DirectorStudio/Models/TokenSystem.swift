// MODULE: TokenSystem
// VERSION: 1.0.0
// PURPOSE: Token-based pricing system with quality tiers

import Foundation

/// Video quality tiers with associated token costs
public enum VideoQualityTier: String, CaseIterable {
    case low = "Standard"
    case medium = "HD"
    case high = "4K"
    
    /// Tokens per second of video
    public var tokensPerSecond: Int {
        switch self {
        case .low: return 15
        case .medium: return 20
        case .high: return 25
        }
    }
    
    /// Display name for UI
    public var displayName: String {
        switch self {
        case .low: return "Standard Quality"
        case .medium: return "HD Quality"
        case .high: return "4K Quality"
        }
    }
    
    /// Short name for compact UI
    public var shortName: String {
        switch self {
        case .low: return "SD"
        case .medium: return "HD"
        case .high: return "4K"
        }
    }
    
    /// System icon
    public var icon: String {
        switch self {
        case .low: return "tv"
        case .medium: return "tv.inset.filled"
        case .high: return "4k.tv"
        }
    }
    
    /// Description for tooltips
    public var description: String {
        switch self {
        case .low: return "Good for drafts and testing"
        case .medium: return "Professional quality for most uses"
        case .high: return "Cinema-grade for final production"
        }
    }
    
    /// Processing speed multiplier
    public var speedMultiplier: Double {
        switch self {
        case .low: return 1.0
        case .medium: return 0.8
        case .high: return 0.6
        }
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
    public static func calculateCost(
        duration: TimeInterval,
        quality: VideoQualityTier,
        includesEnhancement: Bool = true,
        includesContinuity: Bool = false
    ) -> Int {
        let baseCost = Int(ceil(duration)) * quality.tokensPerSecond
        var totalCost = baseCost
        
        // Add 20% for enhancement
        if includesEnhancement {
            totalCost = Int(ceil(Double(totalCost) * 1.2))
        }
        
        // Add 10% for continuity
        if includesContinuity {
            totalCost = Int(ceil(Double(totalCost) * 1.1))
        }
        
        return totalCost
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
        quality: VideoQualityTier = .medium
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
