//
//  BillingManager.swift
//  DirectorStudio
//
//  PURPOSE: Coordinate billing operations and user balance management
//

import Foundation
import Combine

/// Central billing manager coordinating tokens, pricing, and payments
public final class BillingManager: ObservableObject {
    public static let shared = BillingManager()
    
    // MARK: - Published Properties
    
    @Published public var userBalance: UserBalance
    @Published public var activeSubscription: PricingEngine.SubscriptionPlan?
    @Published public var isProcessingPayment: Bool = false
    @Published public var lastError: BillingError?
    
    // MARK: - Dependencies
    
    private let tokenEngine = TokenMeteringEngine.shared
    private let pricingEngine = PricingEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - User Balance Management
    
    /// Check if user can afford a generation
    public func canAffordGeneration(
        duration: TimeInterval,
        quality: VideoQualityTier,
        modelTier: PricingEngine.ModelTier
    ) -> (canAfford: Bool, reason: String?) {
        
        let tokenCalc = tokenEngine.calculateTokens(for: duration, quality: quality)
        
        // Check token balance
        if userBalance.availableTokens < tokenCalc.totalTokens {
            let needed = tokenCalc.totalTokens - userBalance.availableTokens
            return (false, "Need \(Int(needed)) more tokens")
        }
        
        // Check if within subscription limits
        if let sub = activeSubscription {
            let monthlyUsage = getMonthlyUsage()
            if monthlyUsage.tokensUsed + tokenCalc.totalTokens > Double(sub.includedSeconds) {
                // Would exceed subscription - check overage settings
                if !userBalance.allowOverage {
                    return (false, "Would exceed subscription limit. Enable overage billing in settings.")
                }
                
                // Calculate overage cost
                let overageTokens = (monthlyUsage.tokensUsed + tokenCalc.totalTokens) - Double(sub.includedSeconds)
                let overageCost = overageTokens * sub.overageRate
                
                return (true, "Includes $\(String(format: "%.2f", overageCost)) overage charge")
            }
        }
        
        return (true, nil)
    }
    
    /// Process a generation charge
    public func chargeGeneration(
        userId: String,
        generationId: String,
        duration: TimeInterval,
        quality: VideoQualityTier,
        modelTier: PricingEngine.ModelTier,
        success: Bool
    ) async throws -> BillingTransaction {
        
        // Calculate tokens
        let tokenCalc = tokenEngine.calculateTokens(for: duration, quality: quality)
        
        // Only charge if successful
        guard success else {
            // Log failed attempt but don't charge
            tokenEngine.logTokenBurn(
                userId: userId,
                calculation: tokenCalc,
                generationId: generationId,
                success: false
            )
            
            throw BillingError.generationFailed
        }
        
        // Check balance
        let affordability = canAffordGeneration(duration: duration, quality: quality, modelTier: modelTier)
        guard affordability.canAfford else {
            throw BillingError.insufficientBalance(affordability.reason ?? "Insufficient balance")
        }
        
        // Calculate pricing
        let priceCalc = pricingEngine.calculatePrice(
            tokens: tokenCalc.totalTokens,
            modelTier: modelTier,
            qualityTier: quality,
            userPlan: activeSubscription
        )
        
        // Deduct tokens
        userBalance.availableTokens -= tokenCalc.totalTokens
        
        // Log the burn
        tokenEngine.logTokenBurn(
            userId: userId,
            calculation: tokenCalc,
            generationId: generationId,
            success: true,
            metadata: [
                "model_tier": modelTier.rawValue,
                "price_charged": priceCalc.total
            ]
        )
        
        // Create transaction record
        let transaction = BillingTransaction(
            id: UUID(),
            userId: userId,
            timestamp: Date(),
            type: .generation,
            tokens: tokenCalc.totalTokens,
            amount: priceCalc.total,
            description: "Video Generation (\(Int(duration))s, \(quality.rawValue))",
            metadata: [
                "generation_id": generationId,
                "duration": String(duration),
                "quality": quality.rawValue,
                "model": modelTier.rawValue
            ]
        )
        
        // Save transaction
        saveTransaction(transaction)
        
        // Update balance
        saveUserBalance()
        
        return transaction
    }
    
    /// Purchase tokens via PAYG bundle
    public func purchaseBundle(
        _ bundle: PricingEngine.PAYGBundle,
        paymentMethodId: String
    ) async throws -> BillingTransaction {
        
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        
        // In production: Process with Stripe
        // let payment = try await stripeClient.charge(
        //     amount: bundle.finalPrice,
        //     paymentMethod: paymentMethodId
        // )
        
        // Simulate payment processing
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Add tokens to balance
        userBalance.availableTokens += Double(bundle.seconds)
        userBalance.lifetimeTokensPurchased += Double(bundle.seconds)
        
        // Create transaction
        let transaction = BillingTransaction(
            id: UUID(),
            userId: getCurrentUserId(),
            timestamp: Date(),
            type: .purchase,
            tokens: Double(bundle.seconds),
            amount: bundle.finalPrice,
            description: "Token Bundle Purchase (\(bundle.seconds) seconds)",
            metadata: [
                "bundle_size": String(bundle.seconds),
                "discount": String(bundle.discountPercent),
                "stripe_fee": String(format: "%.2f", bundle.stripeFee)
            ]
        )
        
        saveTransaction(transaction)
        saveUserBalance()
        
        return transaction
    }
    
    /// Subscribe to a plan
    public func subscribeToPlan(
        _ plan: PricingEngine.SubscriptionPlan,
        paymentMethodId: String
    ) async throws -> BillingTransaction {
        
        isProcessingPayment = true
        defer { isProcessingPayment = false }
        
        // In production: Create Stripe subscription
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Set active subscription
        activeSubscription = plan
        userBalance.subscriptionTokens = Double(plan.includedSeconds)
        userBalance.subscriptionRenewDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        // Create transaction
        let transaction = BillingTransaction(
            id: UUID(),
            userId: getCurrentUserId(),
            timestamp: Date(),
            type: .subscription,
            tokens: Double(plan.includedSeconds),
            amount: plan.monthlyPrice,
            description: "\(plan.name) Subscription",
            metadata: [
                "plan": plan.name,
                "included_seconds": String(plan.includedSeconds),
                "overage_rate": String(plan.overageRate)
            ]
        )
        
        saveTransaction(transaction)
        saveUserBalance()
        
        return transaction
    }
    
    // MARK: - Usage Analytics
    
    /// Get monthly usage statistics
    public func getMonthlyUsage() -> MonthlyUsage {
        let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        let history = tokenEngine.getUsageHistory(for: getCurrentUserId(), days: 30)
        
        let monthlyHistory = history.filter { $0.timestamp >= startOfMonth }
        let tokensUsed = monthlyHistory.reduce(0) { $0 + $1.tokensCharged }
        
        let qualityBreakdown = Dictionary(grouping: monthlyHistory, by: { $0.qualityTier })
            .mapValues { records in
                records.reduce(0) { $0 + $1.tokensCharged }
            }
        
        return MonthlyUsage(
            month: startOfMonth,
            tokensUsed: tokensUsed,
            generationCount: monthlyHistory.count,
            qualityBreakdown: qualityBreakdown,
            estimatedCost: calculateEstimatedCost(tokens: tokensUsed)
        )
    }
    
    /// Get transaction history
    public func getTransactionHistory(limit: Int = 50) -> [BillingTransaction] {
        return loadTransactions()
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Private Methods
    
    private func getCurrentUserId() -> String {
        // In production: Get from auth service
        return "current_user"
    }
    
    private func calculateEstimatedCost(tokens: Double) -> Double {
        // Simplified calculation
        if let sub = activeSubscription {
            let included = Double(sub.includedSeconds)
            if tokens <= included {
                return 0 // Within subscription
            } else {
                return (tokens - included) * sub.overageRate
            }
        } else {
            return tokens * 0.08 // Default PAYG rate
        }
    }
    
    // MARK: - Persistence
    
    private func saveUserBalance() {
        UserDefaults.standard.set(
            try? JSONEncoder().encode(userBalance),
            forKey: "user_balance"
        )
    }
    
    private func loadUserBalance() {
        if let data = UserDefaults.standard.data(forKey: "user_balance"),
           let balance = try? JSONDecoder().decode(UserBalance.self, from: data) {
            userBalance = balance
        } else {
            // Initialize with starter balance
            userBalance = UserBalance(
                availableTokens: 30, // 30 second starter
                subscriptionTokens: 0,
                lifetimeTokensPurchased: 30,
                allowOverage: false,
                subscriptionRenewDate: nil
            )
        }
    }
    
    private func saveTransaction(_ transaction: BillingTransaction) {
        var transactions = loadTransactions()
        transactions.append(transaction)
        
        UserDefaults.standard.set(
            try? JSONEncoder().encode(transactions),
            forKey: "billing_transactions"
        )
    }
    
    private func loadTransactions() -> [BillingTransaction] {
        if let data = UserDefaults.standard.data(forKey: "billing_transactions"),
           let transactions = try? JSONDecoder().decode([BillingTransaction].self, from: data) {
            return transactions
        }
        return []
    }
    
    private init() {
        loadUserBalance()
    }
}

// MARK: - Supporting Types

/// User's token balance and settings
public struct UserBalance: Codable {
    public var availableTokens: Double
    public var subscriptionTokens: Double
    public var lifetimeTokensPurchased: Double
    public var allowOverage: Bool
    public var subscriptionRenewDate: Date?
    
    public var totalAvailable: Double {
        return availableTokens + subscriptionTokens
    }
}

/// Billing transaction record
public struct BillingTransaction: Codable, Identifiable {
    public let id: UUID
    public let userId: String
    public let timestamp: Date
    public let type: TransactionType
    public let tokens: Double
    public let amount: Double
    public let description: String
    public let metadata: [String: String]
    
    public enum TransactionType: String, Codable {
        case purchase = "purchase"
        case subscription = "subscription"
        case generation = "generation"
        case overage = "overage"
        case refund = "refund"
        case bonus = "bonus"
    }
}

/// Monthly usage statistics
public struct MonthlyUsage {
    public let month: Date
    public let tokensUsed: Double
    public let generationCount: Int
    public let qualityBreakdown: [VideoQualityTier: Double]
    public let estimatedCost: Double
}

/// Billing errors
public enum BillingError: LocalizedError {
    case insufficientBalance(String)
    case paymentFailed(String)
    case subscriptionInactive
    case generationFailed
    case invalidPromoCode
    
    public var errorDescription: String? {
        switch self {
        case .insufficientBalance(let reason):
            return "Insufficient balance: \(reason)"
        case .paymentFailed(let reason):
            return "Payment failed: \(reason)"
        case .subscriptionInactive:
            return "Subscription is not active"
        case .generationFailed:
            return "Generation failed - no charge applied"
        case .invalidPromoCode:
            return "Invalid or expired promo code"
        }
    }
}
