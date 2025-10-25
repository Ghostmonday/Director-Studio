//
//  TokenMeteringEngine.swift
//  DirectorStudio
//
//  PURPOSE: Core token metering engine for video generation billing
//

import Foundation

/// Token metering engine that tracks video generation usage
public final class TokenMeteringEngine: ObservableObject {
    public static let shared = TokenMeteringEngine()
    
    // MARK: - Properties
    
    /// 1 token = 1 second of video
    private let tokensPerSecond: Double = 1.0
    
    /// Minimum charge threshold in seconds
    private let minimumChargeSeconds: Double = 30.0
    
    /// Token burn log for audit trail
    private var tokenBurnLog: [TokenBurnRecord] = []
    
    // MARK: - Token Calculation
    
    /// Calculate tokens needed for video duration
    public func calculateTokens(for duration: TimeInterval, quality: VideoQualityTier) -> TokenCalculation {
        // Round up fractional seconds
        let baseTokens = ceil(duration * tokensPerSecond)
        
        // Apply quality multiplier
        let multiplier = quality.tokenMultiplier
        let totalTokens = baseTokens * multiplier
        
        // Enforce minimum charge
        let chargedTokens = max(totalTokens, minimumChargeSeconds * multiplier)
        
        return TokenCalculation(
            duration: duration,
            baseTokens: baseTokens,
            qualityTier: quality,
            multiplier: multiplier,
            totalTokens: chargedTokens,
            minimumApplied: chargedTokens > totalTokens
        )
    }
    
    /// Log successful token burn
    public func logTokenBurn(
        userId: String,
        calculation: TokenCalculation,
        generationId: String,
        success: Bool,
        metadata: [String: Any] = [:]
    ) {
        let record = TokenBurnRecord(
            id: UUID(),
            userId: userId,
            generationId: generationId,
            timestamp: Date(),
            duration: calculation.duration,
            tokensCharged: success ? calculation.totalTokens : 0, // Only charge if successful
            qualityTier: calculation.qualityTier,
            success: success,
            metadata: metadata
        )
        
        tokenBurnLog.append(record)
        
        // Persist to storage
        saveTokenBurnLog()
        
        // Log for analytics
        logAnalytics(record: record)
    }
    
    /// Get user's token usage history
    public func getUsageHistory(for userId: String, days: Int = 30) -> [TokenBurnRecord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return tokenBurnLog
            .filter { $0.userId == userId && $0.timestamp > cutoffDate }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Calculate total tokens used by user
    public func getTotalTokensUsed(by userId: String) -> Double {
        return tokenBurnLog
            .filter { $0.userId == userId && $0.success }
            .reduce(0) { $0 + $1.tokensCharged }
    }
    
    // MARK: - Private Methods
    
    private func saveTokenBurnLog() {
        // In production: Save to CoreData/CloudKit
        UserDefaults.standard.set(
            try? JSONEncoder().encode(tokenBurnLog),
            forKey: "token_burn_log"
        )
    }
    
    private func loadTokenBurnLog() {
        if let data = UserDefaults.standard.data(forKey: "token_burn_log"),
           let log = try? JSONDecoder().decode([TokenBurnRecord].self, from: data) {
            tokenBurnLog = log
        }
    }
    
    private func logAnalytics(record: TokenBurnRecord) {
        print("📊 Token Burn: \(record.tokensCharged) tokens for \(record.duration)s video (\(record.qualityTier.rawValue))")
        
        // In production: Send to analytics service
        // Analytics.track("token_burn", properties: [
        //     "user_id": record.userId,
        //     "tokens": record.tokensCharged,
        //     "duration": record.duration,
        //     "quality": record.qualityTier.rawValue,
        //     "success": record.success
        // ])
    }
    
    private init() {
        loadTokenBurnLog()
    }
}

// MARK: - Supporting Types
/// Token calculation result
public struct TokenCalculation {
    public let duration: TimeInterval
    public let baseTokens: Double
    public let qualityTier: VideoQualityTier
    public let multiplier: Double
    public let totalTokens: Double
    public let minimumApplied: Bool
    
    /// Formatted description for UI
    public var description: String {
        var desc = "\(Int(duration))s × \(multiplier)x = \(Int(totalTokens)) tokens"
        if minimumApplied {
            desc += " (minimum charge applied)"
        }
        return desc
    }
}

/// Token burn record for audit trail
public struct TokenBurnRecord: Codable, Identifiable {
    public let id: UUID
    public let userId: String
    public let generationId: String
    public let timestamp: Date
    public let duration: TimeInterval
    public let tokensCharged: Double
    public let qualityTier: VideoQualityTier
    public let success: Bool
    public let metadata: [String: String] // Simplified for Codable
    
    init(id: UUID, userId: String, generationId: String, timestamp: Date,
         duration: TimeInterval, tokensCharged: Double, qualityTier: VideoQualityTier,
         success: Bool, metadata: [String: Any]) {
        self.id = id
        self.userId = userId
        self.generationId = generationId
        self.timestamp = timestamp
        self.duration = duration
        self.tokensCharged = tokensCharged
        self.qualityTier = qualityTier
        self.success = success
        // Convert metadata to string representation
        self.metadata = metadata.mapValues { String(describing: $0) }
    }
}
