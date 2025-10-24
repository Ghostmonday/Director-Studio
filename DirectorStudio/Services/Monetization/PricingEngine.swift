//
//  PricingEngine.swift
//  DirectorStudio
//
//  PURPOSE: Handle pricing calculations for different models and tiers
//

import Foundation

/// Pricing engine for token-based billing
public final class PricingEngine: ObservableObject {
    public static let shared = PricingEngine()
    
    // MARK: - Pricing Configuration
    
    /// Model tiers with base pricing
    public enum ModelTier: String, CaseIterable, Codable {
        case standard = "Standard"
        case pro = "Pro"
        case ultra = "Ultra"
        
        /// Base price per second in USD
        public var pricePerSecond: Double {
            switch self {
            case .standard: return 0.08
            case .pro: return 0.14
            case .ultra: return 0.45
            }
        }
        
        /// Display name with pricing
        public var displayName: String {
            return "\(rawValue) ($\(String(format: "%.2f", pricePerSecond))/sec)"
        }
    }
    
    /// Minimum charge threshold
    private let minimumChargeUSD: Double = 2.40
    
    /// Minimum allowed price per second (for promos)
    private let minimumPricePerSecond: Double = 0.06
    
    // MARK: - PAYG Bundle Pricing
    
    public struct PAYGBundle: Identifiable {
        public let id = UUID()
        public let seconds: Int
        public let basePrice: Double
        public let discountPercent: Double
        public let finalPrice: Double
        public let stripeFee: Double
        public let netRevenue: Double
        
        public var displayName: String {
            if discountPercent > 0 {
                return "\(seconds)s (-\(Int(discountPercent))%)"
            }
            return "\(seconds) seconds"
        }
        
        public var pricePerSecond: Double {
            return finalPrice / Double(seconds)
        }
    }
    
    /// Get available PAYG bundles for a model tier
    public func getPAYGBundles(for modelTier: ModelTier) -> [PAYGBundle] {
        let bundleConfigs: [(seconds: Int, discount: Double)] = [
            (30, 0.0),      // No discount
            (60, 0.05),     // 5% off
            (120, 0.10),    // 10% off
            (300, 0.20),    // 20% off
            (600, 0.25),    // 25% off
            (1200, 0.33)    // 33% off (max discount)
        ]
        
        return bundleConfigs.map { config in
            let basePrice = Double(config.seconds) * modelTier.pricePerSecond
            let discountedPrice = basePrice * (1.0 - config.discount)
            let stripeFee = calculateStripeFee(amount: discountedPrice)
            let netRevenue = discountedPrice - stripeFee
            
            return PAYGBundle(
                seconds: config.seconds,
                basePrice: basePrice,
                discountPercent: config.discount * 100,
                finalPrice: discountedPrice,
                stripeFee: stripeFee,
                netRevenue: netRevenue
            )
        }
    }
    
    // MARK: - Subscription Plans
    
    public struct SubscriptionPlan: Identifiable {
        public let id = UUID()
        public let name: String
        public let monthlyPrice: Double
        public let includedSeconds: Int
        public let overageRate: Double
        public let rolloverEnabled: Bool
        public let features: [String]
        
        public var effectiveRate: Double {
            return monthlyPrice / Double(includedSeconds)
        }
    }
    
    /// Available subscription plans
    public let subscriptionPlans: [SubscriptionPlan] = [
        SubscriptionPlan(
            name: "Creator",
            monthlyPrice: 29.99,
            includedSeconds: 600,  // 10 minutes
            overageRate: 0.06,
            rolloverEnabled: false,
            features: ["Standard & HD quality", "Priority support"]
        ),
        SubscriptionPlan(
            name: "Pro",
            monthlyPrice: 99.99,
            includedSeconds: 2400, // 40 minutes
            overageRate: 0.05,
            rolloverEnabled: true,
            features: ["All qualities", "API access", "Priority rendering"]
        ),
        SubscriptionPlan(
            name: "Agency",
            monthlyPrice: 299.99,
            includedSeconds: 9000, // 150 minutes
            overageRate: 0.04,
            rolloverEnabled: true,
            features: ["All qualities", "Team seats", "Custom branding"]
        ),
        SubscriptionPlan(
            name: "Studio",
            monthlyPrice: 999.99,
            includedSeconds: 36000, // 600 minutes
            overageRate: 0.03,
            rolloverEnabled: true,
            features: ["All qualities", "Dedicated support", "SLA guarantee"]
        )
    ]
    
    // MARK: - Pricing Calculations
    
    /// Calculate final price for a generation
    public func calculatePrice(
        tokens: Double,
        modelTier: ModelTier,
        qualityTier: VideoQualityTier,
        userPlan: SubscriptionPlan? = nil,
        promoCode: PromoCode? = nil
    ) -> PriceCalculation {
        
        // Base calculation
        let seconds = tokens / qualityTier.tokenMultiplier
        var pricePerSecond = modelTier.pricePerSecond
        
        // Apply subscription rate if applicable
        if let plan = userPlan {
            pricePerSecond = min(pricePerSecond, plan.overageRate)
        }
        
        // Apply promo if valid
        if let promo = promoCode, promo.isValid {
            pricePerSecond = pricePerSecond * (1.0 - promo.discountPercent)
            // Enforce minimum price unless special promo
            if !promo.allowBelowMinimum {
                pricePerSecond = max(pricePerSecond, minimumPricePerSecond)
            }
        }
        
        // Calculate total
        let subtotal = tokens * pricePerSecond
        let total = max(subtotal, minimumChargeUSD)
        
        return PriceCalculation(
            tokens: tokens,
            seconds: seconds,
            modelTier: modelTier,
            qualityTier: qualityTier,
            pricePerSecond: pricePerSecond,
            subtotal: subtotal,
            minimumApplied: total > subtotal,
            total: total,
            promoApplied: promoCode?.code
        )
    }
    
    /// Calculate Stripe processing fee
    private func calculateStripeFee(amount: Double) -> Double {
        return (amount * 0.029) + 0.30
    }
    
    // MARK: - Promo Codes
    
    public struct PromoCode: Codable {
        public let code: String
        public let discountPercent: Double
        public let validUntil: Date
        public let usageLimit: Int
        public var usageCount: Int
        public let allowBelowMinimum: Bool
        
        public var isValid: Bool {
            return Date() < validUntil && usageCount < usageLimit
        }
    }
    
    private var promoCodes: [String: PromoCode] = [
        "LAUNCH50": PromoCode(
            code: "LAUNCH50",
            discountPercent: 0.50,
            validUntil: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days
            usageLimit: 1000,
            usageCount: 0,
            allowBelowMinimum: false
        ),
        "CREATOR20": PromoCode(
            code: "CREATOR20",
            discountPercent: 0.20,
            validUntil: Date().addingTimeInterval(90 * 24 * 60 * 60), // 90 days
            usageLimit: 5000,
            usageCount: 0,
            allowBelowMinimum: false
        )
    ]
    
    /// Validate and get promo code
    public func getPromoCode(_ code: String) -> PromoCode? {
        return promoCodes[code.uppercased()]
    }
    
    /// Use a promo code
    public func usePromoCode(_ code: String) -> Bool {
        guard var promo = promoCodes[code.uppercased()], promo.isValid else {
            return false
        }
        
        promo.usageCount += 1
        promoCodes[code.uppercased()] = promo
        savePromoCodes()
        
        return true
    }
    
    // MARK: - Persistence
    
    private func savePromoCodes() {
        UserDefaults.standard.set(
            try? JSONEncoder().encode(promoCodes),
            forKey: "promo_codes"
        )
    }
    
    private func loadPromoCodes() {
        if let data = UserDefaults.standard.data(forKey: "promo_codes"),
           let codes = try? JSONDecoder().decode([String: PromoCode].self, from: data) {
            promoCodes = codes
        }
    }
    
    private init() {
        loadPromoCodes()
    }
}

// MARK: - Supporting Types

/// Price calculation result
public struct PriceCalculation {
    public let tokens: Double
    public let seconds: Double
    public let modelTier: PricingEngine.ModelTier
    public let qualityTier: VideoQualityTier
    public let pricePerSecond: Double
    public let subtotal: Double
    public let minimumApplied: Bool
    public let total: Double
    public let promoApplied: String?
    
    /// Formatted breakdown for UI
    public var breakdown: String {
        var lines: [String] = []
        lines.append("Duration: \(Int(seconds))s")
        lines.append("Quality: \(qualityTier.displayName)")
        lines.append("Model: \(modelTier.rawValue)")
        lines.append("Rate: $\(String(format: "%.3f", pricePerSecond))/sec")
        
        if let promo = promoApplied {
            lines.append("Promo: \(promo)")
        }
        
        lines.append("───────────────")
        lines.append("Subtotal: $\(String(format: "%.2f", subtotal))")
        
        if minimumApplied {
            lines.append("Minimum charge: $\(String(format: "%.2f", total))")
        }
        
        lines.append("Total: $\(String(format: "%.2f", total))")
        
        return lines.joined(separator: "\n")
    }
}
