//
//  RenderTransaction.swift
//  DirectorStudio
//
//  PURPOSE: Track render transactions for reconciliation and margin monitoring
//

import Foundation

/// Record of a video render transaction for accounting
public struct RenderTransaction: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let userId: String
    public let generationId: String
    
    // Duration metrics
    public let requestedSeconds: Double
    public let actualSeconds: Double?
    
    // Credit metrics
    public let estimatedCredits: Double
    public let actualCredits: Double?
    public let tokensDebited: Int
    
    // Financial metrics (all in cents)
    public let priceChargedCents: Int
    public let upstreamCostCents: Int
    public let netRevenueCents: Int
    
    // Margin calculation
    public let grossMarginPercent: Double
    
    // Metadata
    public let prompt: String?
    public let isMultiClip: Bool
    public let pipelineStages: [String]
    public let errorMessage: String?
    public let wasSuccessful: Bool
    
    public init(
        userId: String,
        generationId: String,
        requestedSeconds: Double,
        actualSeconds: Double? = nil,
        estimatedCredits: Double,
        actualCredits: Double? = nil,
        tokensDebited: Int,
        priceChargedCents: Int,
        upstreamCostCents: Int,
        prompt: String? = nil,
        isMultiClip: Bool = false,
        pipelineStages: [String] = [],
        errorMessage: String? = nil,
        wasSuccessful: Bool = true
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.userId = userId
        self.generationId = generationId
        
        self.requestedSeconds = requestedSeconds
        self.actualSeconds = actualSeconds
        
        self.estimatedCredits = estimatedCredits
        self.actualCredits = actualCredits
        self.tokensDebited = tokensDebited
        
        self.priceChargedCents = priceChargedCents
        self.upstreamCostCents = upstreamCostCents
        self.netRevenueCents = priceChargedCents - upstreamCostCents
        
        // Calculate margin
        if priceChargedCents > 0 {
            let revenue = Double(priceChargedCents) / 100.0
            let cost = Double(upstreamCostCents) / 100.0
            self.grossMarginPercent = (revenue - cost) / revenue
        } else {
            self.grossMarginPercent = 0.0
        }
        
        self.prompt = prompt
        self.isMultiClip = isMultiClip
        self.pipelineStages = pipelineStages
        self.errorMessage = errorMessage
        self.wasSuccessful = wasSuccessful
    }
}

// MARK: - Transaction Manager

/// Manages render transaction persistence and analytics
public final class RenderTransactionManager: ObservableObject {
    public static let shared = RenderTransactionManager()
    
    @Published private(set) var transactions: [RenderTransaction] = []
    
    private let userDefaults = UserDefaults.standard
    private let transactionsKey = "render_transactions"
    
    private init() {
        loadTransactions()
    }
    
    // MARK: - Public Methods
    
    /// Record a new render transaction
    public func recordTransaction(_ transaction: RenderTransaction) {
        transactions.append(transaction)
        saveTransactions()
        
        // Check if we need to alert about margins
        Task {
            await checkMarginHealth()
        }
    }
    
    /// Get transactions for a specific date range
    public func transactions(from startDate: Date, to endDate: Date) -> [RenderTransaction] {
        transactions.filter { transaction in
            transaction.timestamp >= startDate && transaction.timestamp <= endDate
        }
    }
    
    /// Get today's transactions
    public func todaysTransactions() -> [RenderTransaction] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return transactions(from: startOfDay, to: endOfDay)
    }
    
    /// Calculate aggregate metrics for a period
    public func calculateMetrics(for transactions: [RenderTransaction]) -> AggregateMetrics {
        guard !transactions.isEmpty else {
            return AggregateMetrics()
        }
        
        let successfulTransactions = transactions.filter { $0.wasSuccessful }
        
        let totalRevenue = successfulTransactions.reduce(0) { $0 + $1.priceChargedCents }
        let totalCost = successfulTransactions.reduce(0) { $0 + $1.upstreamCostCents }
        let totalSeconds = successfulTransactions.reduce(0.0) { $0 + $1.requestedSeconds }
        let totalTokens = successfulTransactions.reduce(0) { $0 + $1.tokensDebited }
        
        let averageMargin = successfulTransactions.isEmpty ? 0.0 :
            successfulTransactions.reduce(0.0) { $0 + $1.grossMarginPercent } / Double(successfulTransactions.count)
        
        return AggregateMetrics(
            totalRevenueCents: totalRevenue,
            totalCostCents: totalCost,
            totalSeconds: totalSeconds,
            totalTokens: totalTokens,
            averageMarginPercent: averageMargin,
            transactionCount: transactions.count,
            successCount: successfulTransactions.count,
            failureCount: transactions.count - successfulTransactions.count
        )
    }
    
    // MARK: - Private Methods
    
    private func loadTransactions() {
        guard let data = userDefaults.data(forKey: transactionsKey),
              let decoded = try? JSONDecoder().decode([RenderTransaction].self, from: data) else {
            return
        }
        transactions = decoded
    }
    
    private func saveTransactions() {
        // Keep only last 90 days of transactions
        let cutoffDate = Date().addingTimeInterval(-90 * 24 * 60 * 60)
        transactions = transactions.filter { $0.timestamp > cutoffDate }
        
        if let encoded = try? JSONEncoder().encode(transactions) {
            userDefaults.set(encoded, forKey: transactionsKey)
        }
    }
    
    /// Check margin health and alert if needed
    private func checkMarginHealth() async {
        let calendar = Calendar.current
        let today = Date()
        
        // Check last N days
        let daysToCheck = MonetizationConfig.MARGIN_ALERT_DAYS
        var lowMarginDays = 0
        
        for daysAgo in 0..<daysToCheck {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let dayTransactions = transactions(from: startOfDay, to: endOfDay)
            let metrics = calculateMetrics(for: dayTransactions)
            
            if metrics.averageMarginPercent < MonetizationConfig.TARGET_MARGIN &&
               metrics.transactionCount > 0 {
                lowMarginDays += 1
            }
        }
        
        // Alert if margin has been low for too many days
        if lowMarginDays >= daysToCheck {
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .marginAlert,
                    object: nil,
                    userInfo: ["days": lowMarginDays]
                )
            }
        }
    }
}

// MARK: - Aggregate Metrics

/// Aggregate metrics for a set of transactions
public struct AggregateMetrics {
    public let totalRevenueCents: Int
    public let totalCostCents: Int
    public let totalSeconds: Double
    public let totalTokens: Int
    public let averageMarginPercent: Double
    public let transactionCount: Int
    public let successCount: Int
    public let failureCount: Int
    
    public var totalRevenueDollars: Double {
        Double(totalRevenueCents) / 100.0
    }
    
    public var totalCostDollars: Double {
        Double(totalCostCents) / 100.0
    }
    
    public var netRevenueDollars: Double {
        totalRevenueDollars - totalCostDollars
    }
    
    public var averageRevenuePerTransaction: Double {
        guard transactionCount > 0 else { return 0 }
        return totalRevenueDollars / Double(transactionCount)
    }
    
    public var averageSecondsPerTransaction: Double {
        guard transactionCount > 0 else { return 0 }
        return totalSeconds / Double(transactionCount)
    }
    
    init(
        totalRevenueCents: Int = 0,
        totalCostCents: Int = 0,
        totalSeconds: Double = 0,
        totalTokens: Int = 0,
        averageMarginPercent: Double = 0,
        transactionCount: Int = 0,
        successCount: Int = 0,
        failureCount: Int = 0
    ) {
        self.totalRevenueCents = totalRevenueCents
        self.totalCostCents = totalCostCents
        self.totalSeconds = totalSeconds
        self.totalTokens = totalTokens
        self.averageMarginPercent = averageMarginPercent
        self.transactionCount = transactionCount
        self.successCount = successCount
        self.failureCount = failureCount
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted when margin falls below target for multiple days
    public static let marginAlert = Notification.Name("DirectorStudio.marginAlert")
    
    /// Posted when a new transaction is recorded
    public static let transactionRecorded = Notification.Name("DirectorStudio.transactionRecorded")
}
