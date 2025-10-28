//
//  CreditsManager.swift
//  DirectorStudio
//
//  PURPOSE: Manage user credits and demo mode based on credits
//

import Foundation
import SwiftUI

/// Credit-related errors
public enum CreditError: LocalizedError {
    case insufficientCredits(needed: Int, have: Int)
    case generationBlocked
    case purchaseRequired
    
    public var errorDescription: String? {
        switch self {
        case .insufficientCredits(let needed, let have):
            return "You need \(needed) credits but only have \(have). Please purchase a credit pack or upgrade your plan."
        case .generationBlocked:
            return "Video generation is blocked. Please check your credits."
        case .purchaseRequired:
            return "You need more credits to generate a video. Please purchase a credit pack or upgrade your plan."
        }
    }
}

/// Cost breakdown for transparency
public struct CostBreakdown {
    let videoDuration: TimeInterval
    let baseTokens: Int
    let multiplier: Double
    let totalTokens: Int
    let priceInCents: Int
    let pipelineFeatures: [String]
    
    var formattedBreakdown: String {
        var result = "Cost Breakdown:\n"
        result += "• Duration: \(Int(videoDuration))s\n"
        result += "• Base rate: $0.15/sec\n"
        result += "• Base cost: $\(String(format: "%.2f", videoDuration * 0.15))\n"
        
        if !pipelineFeatures.isEmpty {
            result += "\nFeatures:\n"
            for feature in pipelineFeatures {
                result += "• \(feature)\n"
            }
            if multiplier > 1.0 {
                result += "• Multiplier: \(String(format: "%.1fx", multiplier))\n"
            }
        }
        
        result += "\n━━━━━━━━━━━━━━━\n"
        result += "Total: \(totalTokens) tokens"
        result += " ($\(String(format: "%.2f", Double(priceInCents) / 100.0)))"
        return result
    }
}

/// Manages user credits and determines demo mode status
public final class CreditsManager: ObservableObject {
    public static let shared = CreditsManager()
    
    @Published public var tokens: Int = 0
    @Published public var credits: Int = 0 // Legacy support during migration
    @Published public var isLoadingCredits: Bool = false
    @Published public var hasPurchased: Bool = false
    @Published public var lastCreditError: CreditError? = nil
    @Published public var selectedQuality: VideoQualityTier = .medium
    
    private let userDefaults = UserDefaults.standard
    private let tokensKey = "user_tokens"
    private let creditsKey = "user_credits" // Legacy key
    private let firstLaunchKey = "first_launch_completed"
    private let hasPurchasedKey = "user_has_purchased"
    private let freeCreditGrantedKey = "free_credit_granted"
    
    /// Developer mode for free testing (highly secure implementation)
    public var isDevMode: Bool {
        #if DEBUG
        // Multiple security checks required:
        
        // 1. Check if dev mode is enabled in UserDefaults
        guard UserDefaults.standard.bool(forKey: "DEV_MODE_ENABLED") else {
            return false
        }
        
        // 2. Verify secret passcode was entered correctly
        guard let lastPasscodeEntry = UserDefaults.standard.object(forKey: "DEV_MODE_PASSCODE_TIMESTAMP") as? Date else {
            return false
        }
        
        // 3. Passcode expires after 1 hour for security
        let oneHourAgo = Date().addingTimeInterval(-3600)
        guard lastPasscodeEntry > oneHourAgo else {
            // Expired - disable dev mode
            UserDefaults.standard.set(false, forKey: "DEV_MODE_ENABLED")
            UserDefaults.standard.removeObject(forKey: "DEV_MODE_PASSCODE_TIMESTAMP")
            return false
        }
        
        // Dev mode is now active!
        return true
        #else
        // Never allow dev mode in release builds
        return false
        #endif
    }
    
    private init() {
        loadTokens()
        checkFirstLaunch()
        
        // Load selected quality
        if let qualityRaw = userDefaults.string(forKey: "selected_video_quality"),
           let quality = VideoQualityTier(rawValue: qualityRaw) {
            selectedQuality = quality
        }
    }
    
    /// Load tokens from storage (with migration from credits)
    private func loadTokens() {
        // DEV MODE: Give unlimited tokens for testing
        #if DEBUG
        if userDefaults.bool(forKey: "DEV_MODE_ENABLED") {
            tokens = 999999
            credits = 9999
            print("💰 DEV MODE: Granted unlimited tokens")
            return
        }
        #endif
        
        // Check if we have tokens already
        let storedTokens = userDefaults.integer(forKey: tokensKey)
        
        if storedTokens > 0 {
            // Use existing tokens
            tokens = storedTokens
        } else {
            // Migrate from old credits system (1 credit = 100 tokens)
            let oldCredits = userDefaults.integer(forKey: creditsKey)
            if oldCredits > 0 {
                tokens = oldCredits * 100
                userDefaults.set(tokens, forKey: tokensKey)
                print("💱 Migrated \(oldCredits) credits to \(tokens) tokens")
            }
        }
        
        // Sync legacy credits property
        credits = tokens / 100
        
        hasPurchased = userDefaults.bool(forKey: hasPurchasedKey)
    }
    
    /// Save tokens to storage
    private func saveTokens() {
        userDefaults.set(tokens, forKey: tokensKey)
        // Also update legacy credits for backward compatibility
        credits = tokens / 100
        userDefaults.set(credits, forKey: creditsKey)
    }
    
    /// Save credits to storage (legacy support)
    private func saveCredits() {
        userDefaults.set(credits, forKey: creditsKey)
    }
    
    /// Check if this is first launch and give free tokens
    private func checkFirstLaunch() {
        // Grant 150 free tokens for new users (enough for ~10 seconds of SD video)
        if !userDefaults.bool(forKey: freeCreditGrantedKey) && tokens == 0 && !hasPurchased {
            tokens = FreeTrialConfig.tokens
            saveTokens()
            userDefaults.set(true, forKey: freeCreditGrantedKey)
            print("🎁 Welcome! You've received \(FreeTrialConfig.tokens) free tokens to try DirectorStudio!")
        }
        
        // Legacy: Handle old first launch key
        if !userDefaults.bool(forKey: firstLaunchKey) {
            userDefaults.set(true, forKey: firstLaunchKey)
        }
    }
    
    // REMOVED: Demo mode no longer exists - all users get full access
    
    /// Set video quality preference
    public func setVideoQuality(_ quality: VideoQualityTier) {
        selectedQuality = quality
        userDefaults.set(quality.rawValue, forKey: "selected_video_quality")
    }
    
    /// Check if user can generate video with given cost
    public func canGenerate(cost: Int) -> Bool {
        // Dev mode always allows generation
        if isDevMode {
            return true
        }
        return credits >= cost
    }
    
    /// Pre-flight check for video generation
    public func checkCreditsForGeneration(cost: Int) throws {
        // Dev mode bypasses all credit checks
        if isDevMode {
            print("🧑‍💻 DEV MODE: Bypassing credit check (would cost \(cost) credits)")
            lastCreditError = nil
            return
        }
        
        guard credits >= cost else {
            lastCreditError = .insufficientCredits(needed: cost, have: credits)
            throw CreditError.insufficientCredits(needed: cost, have: credits)
        }
        lastCreditError = nil
    }
    
    /// Check if user should see purchase prompts
    public var shouldPromptPurchase: Bool {
        return tokens < 300 || (!hasPurchased && tokens <= 500)
    }
    
    /// Calculate credits needed for video duration using new pricing
    public func creditsNeeded(for duration: TimeInterval, enabledStages: Set<PipelineStage>) -> Int {
        // Use MonetizationConfig for consistent pricing
        let credits = MonetizationConfig.creditsForSeconds(duration)
        let baseTokens = MonetizationConfig.tokensToDebit(credits)
        
        // Apply multipliers for pipeline stages
        var multiplier = 1.0
        
        // Enhancement adds 20% to cost
        if enabledStages.contains(.enhancement) {
            multiplier *= 1.2
        }
        
        // Continuity adds 10% to cost
        if enabledStages.contains(.continuityAnalysis) || 
           enabledStages.contains(.continuityInjection) {
            multiplier *= 1.1
        }
        
        // Calculate final tokens
        let finalTokens = Int(ceil(Double(baseTokens) * multiplier))
        
        return finalTokens
    }
    
    /// Use credits for video generation
    public func useCredits(amount: Int) -> Bool {
        // Dev mode doesn't consume credits
        if isDevMode {
            print("🧑‍💻 DEV MODE: Skipping credit deduction (would use \(amount) credits)")
            return true
        }
        
        guard credits >= amount else {
            print("❌ Not enough credits. Need \(amount), have \(credits)")
            NotificationCenter.default.post(
                name: .insufficientCredits, 
                object: nil,
                userInfo: ["needed": amount, "have": credits]
            )
            return false
        }
        
        credits -= amount
        saveCredits()
        print("💳 Used \(amount) credits. Remaining: \(credits)")
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .creditsDidChange,
            object: nil,
            userInfo: ["creditsUsed": amount, "remaining": credits]
        )
        
        return true
    }
    
    /// Get cost breakdown for transparency
    public func getCostBreakdown(duration: TimeInterval, enabledStages: Set<PipelineStage>) -> CostBreakdown {
        let baseCost = Int(ceil(duration / 5.0))
        var stagesCost: [(String, Int)] = []
        
        if enabledStages.contains(.continuityAnalysis) {
            stagesCost.append(("Continuity Analysis", 1))
        }
        if enabledStages.contains(.continuityInjection) {
            stagesCost.append(("Continuity Injection", 1))
        }
        if enabledStages.contains(.enhancement) {
            stagesCost.append(("AI Enhancement", 2))
        }
        if enabledStages.contains(.cameraDirection) {
            stagesCost.append(("Camera Direction", 1))
        }
        if enabledStages.contains(.lighting) {
            stagesCost.append(("Lighting", 1))
        }
        
        _ = baseCost + stagesCost.reduce(0) { $0 + $1.1 }
        
        // Calculate using new pricing system
        let credits = MonetizationConfig.creditsForSeconds(duration)
        let baseTokens = MonetizationConfig.tokensToDebit(credits)
        
        // Track features and multiplier
        var features: [String] = []
        var multiplier = 1.0
        
        // Enhancement adds 20%
        if enabledStages.contains(.enhancement) {
            features.append("Enhancement (+20%)")
            multiplier *= 1.2
        }
        
        // Continuity adds 10%
        if enabledStages.contains(.continuityAnalysis) || 
           enabledStages.contains(.continuityInjection) {
            features.append("Continuity (+10%)")
            multiplier *= 1.1
        }
        
        // Camera and lighting are included in base price now
        if enabledStages.contains(.cameraDirection) {
            features.append("Camera Direction")
        }
        if enabledStages.contains(.lighting) {
            features.append("Lighting")
        }
        
        // Calculate final cost
        let totalTokens = Int(ceil(Double(baseTokens) * multiplier))
        let priceInCents = MonetizationConfig.priceForSeconds(duration)
        let adjustedPriceCents = Int(ceil(Double(priceInCents) * multiplier))
        
        return CostBreakdown(
            videoDuration: duration,
            baseTokens: baseTokens,
            multiplier: multiplier,
            totalTokens: totalTokens,
            priceInCents: adjustedPriceCents,
            pipelineFeatures: features
        )
    }
    
    /// Add credits (for purchases) - LEGACY
    public func addCredits(_ amount: Int, fromPurchase: Bool = true) {
        // Convert to tokens
        addTokens(amount * 100, fromPurchase: fromPurchase)
    }
    
    // MARK: - Token Management
    
    /// Add tokens (for purchases)
    public func addTokens(_ amount: Int, fromPurchase: Bool = true) {
        tokens += amount
        if fromPurchase && !hasPurchased {
            hasPurchased = true
            userDefaults.set(true, forKey: hasPurchasedKey)
        }
        saveTokens()
        lastCreditError = nil
        print("✅ Added \(amount) tokens. Total: \(tokens)")
        
        // Track lifetime tokens
        let lifetime = userDefaults.integer(forKey: "lifetime_tokens_earned")
        userDefaults.set(lifetime + amount, forKey: "lifetime_tokens_earned")
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .creditsDidChange,
            object: nil,
            userInfo: ["tokensAdded": amount, "totalTokens": tokens, "creditsAdded": amount/100, "total": credits]
        )
    }
    
    /// Use tokens for generation
    public func useTokens(amount: Int) -> Bool {
        // Dev mode doesn't consume tokens
        if isDevMode {
            print("🧑‍💻 DEV MODE: Skipping token deduction (would use \(amount) tokens)")
            return true
        }
        
        guard tokens >= amount else {
            print("❌ Not enough tokens. Need \(amount), have \(tokens)")
            NotificationCenter.default.post(
                name: .insufficientCredits, 
                object: nil,
                userInfo: ["needed": amount, "have": tokens, "isTokens": true]
            )
            lastCreditError = .insufficientCredits(needed: amount/100, have: tokens/100)
            return false
        }
        
        tokens -= amount
        saveTokens()
        print("💳 Used \(amount) tokens. Remaining: \(tokens)")
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .creditsDidChange,
            object: nil,
            userInfo: ["tokensUsed": amount, "remainingTokens": tokens, "creditsUsed": amount/100, "remaining": credits]
        )
        
        return true
    }
    
    /// Calculate token cost for video generation
    public func calculateTokenCost(
        duration: TimeInterval,
        quality: VideoQualityTier,
        enabledStages: Set<PipelineStage>
    ) -> Int {
        let includesEnhancement = enabledStages.contains(.enhancement)
        let includesContinuity = enabledStages.contains(.continuityInjection)
        
        return TokenCalculator.calculateCost(
            duration: duration,
            quality: quality,
            includesEnhancement: includesEnhancement,
            includesContinuity: includesContinuity
        )
    }
    
    /// Check if user can afford generation with tokens
    public func canAffordGeneration(tokenCost: Int) -> Bool {
        if isDevMode { return true }
        return tokens >= tokenCost
    }
    
    /// Purchase options
    public enum PurchaseOption: CaseIterable {
        case starter      // 10 credits for $4.99
        case popular      // 30 credits for $9.99 (best value)
        case professional // 100 credits for $24.99
        
        var credits: Int {
            switch self {
            case .starter: return 10
            case .popular: return 30
            case .professional: return 100
            }
        }
        
        var price: String {
            switch self {
            case .starter: return "$4.99"
            case .popular: return "$9.99"
            case .professional: return "$24.99"
            }
        }
        
        var name: String {
            switch self {
            case .starter: return "Starter Pack"
            case .popular: return "Popular Pack"
            case .professional: return "Professional"
            }
        }
        
        var description: String {
            switch self {
            case .starter: return "10 video generations"
            case .popular: return "30 video generations"
            case .professional: return "100 video generations"
            }
        }
        
        var isBestValue: Bool {
            self == .popular
        }
    }
    
    /// Simulate purchase (replace with StoreKit in production)
    public func simulatePurchase(_ option: PurchaseOption) {
        isLoadingCredits = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.addCredits(option.credits)
            self?.isLoadingCredits = false
        }
    }
    
    #if DEBUG
    /// Enable dev mode with secure passcode
    public func enableDevMode(passcode: String) -> Bool {
        // Secure passcode: current year + "DS" + current month (e.g., "2025DS10")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let year = dateFormatter.string(from: Date())
        dateFormatter.dateFormat = "MM"
        let month = dateFormatter.string(from: Date())
        
        let expectedPasscode = "\(year)DS\(month)"
        
        guard passcode == expectedPasscode else {
            print("❌ Invalid dev mode passcode")
            return false
        }
        
        // Enable dev mode and record timestamp
        UserDefaults.standard.set(true, forKey: "DEV_MODE_ENABLED")
        UserDefaults.standard.set(Date(), forKey: "DEV_MODE_PASSCODE_TIMESTAMP")
        print("🧑‍💻 Dev mode enabled until \(Date().addingTimeInterval(3600))")
        
        // Post notification to update UI
        NotificationCenter.default.post(name: .creditsDidChange, object: nil)
        
        return true
    }
    
    /// Disable dev mode
    public func disableDevMode() {
        UserDefaults.standard.set(false, forKey: "DEV_MODE_ENABLED")
        UserDefaults.standard.removeObject(forKey: "DEV_MODE_PASSCODE_TIMESTAMP")
        print("🧑‍💻 Dev mode disabled")
    }
    #endif
}
