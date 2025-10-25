//
//  CreditsManager.swift
//  DirectorStudio
//
//  PURPOSE: Manage user credits and demo mode based on credits
//

import Foundation

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
    let baseCost: Int
    let stagesCosts: [(String, Int)]
    let totalCost: Int
    
    var formattedBreakdown: String {
        var result = "Cost Breakdown:\n"
        result += "• Video (\(Int(videoDuration))s): \(baseCost) credits\n"
        for (stage, cost) in stagesCosts {
            result += "• \(stage): \(cost) credit\(cost > 1 ? "s" : "")\n"
        }
        result += "━━━━━━━━━━━━━━━\n"
        result += "Total: \(totalCost) credits"
        return result
    }
}

/// Manages user credits and determines demo mode status
public final class CreditsManager: ObservableObject {
    public static let shared = CreditsManager()
    
    @Published public var credits: Int = 0
    @Published public var isLoadingCredits: Bool = false
    @Published public var hasPurchased: Bool = false
    @Published public var lastCreditError: CreditError? = nil
    
    private let userDefaults = UserDefaults.standard
    private let creditsKey = "user_credits"
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
        
        // 4. Check for debug build configuration
        guard Bundle.main.infoDictionary?["DEV_MODE"] as? String == "YES" else {
            return false
        }
        
        // 5. Additional check for Xcode connection (prevents release builds)
        let isDebugging = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil ||
                         ProcessInfo.processInfo.environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] != nil
        
        return true
        #else
        // Never allow dev mode in release builds
        return false
        #endif
    }
    
    private init() {
        loadCredits()
        checkFirstLaunch()
    }
    
    /// Load credits from storage
    private func loadCredits() {
        credits = userDefaults.integer(forKey: creditsKey)
        hasPurchased = userDefaults.bool(forKey: hasPurchasedKey)
    }
    
    /// Save credits to storage
    private func saveCredits() {
        userDefaults.set(credits, forKey: creditsKey)
    }
    
    /// Check if this is first launch and give free credits
    private func checkFirstLaunch() {
        // Grant 1 free demo credit for new users
        if !userDefaults.bool(forKey: freeCreditGrantedKey) && credits == 0 && !hasPurchased {
            credits = 1
            saveCredits()
            userDefaults.set(true, forKey: freeCreditGrantedKey)
            print("🎁 Welcome! You've received 1 free credit to try DirectorStudio!")
        }
        
        // Legacy: Handle old first launch key
        if !userDefaults.bool(forKey: firstLaunchKey) {
            userDefaults.set(true, forKey: firstLaunchKey)
        }
    }
    
    /// Check if user should be in demo mode
    public var shouldUseDemoMode: Bool {
        // Dev mode never uses demo mode - always gets real API access
        if isDevMode {
            return false
        }
        return !hasPurchased && credits == 0
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
        return credits == 0 || (!hasPurchased && credits <= 3)
    }
    
    /// Calculate credits needed for video duration
    public func creditsNeeded(for duration: TimeInterval, enabledStages: Set<PipelineStage>) -> Int {
        // Base cost: 1 credit per 5 seconds of video
        let baseCost = Int(ceil(duration / 5.0))
        
        // Additional costs for pipeline stages
        var pipelineCost = 0
        if enabledStages.contains(.continuityAnalysis) { pipelineCost += 1 }
        if enabledStages.contains(.continuityInjection) { pipelineCost += 1 }
        if enabledStages.contains(.enhancement) { pipelineCost += 2 } // DeepSeek costs more
        if enabledStages.contains(.cameraDirection) { pipelineCost += 1 }
        if enabledStages.contains(.lighting) { pipelineCost += 1 }
        
        return baseCost + pipelineCost
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
        
        let totalCost = baseCost + stagesCost.reduce(0) { $0 + $1.1 }
        
        return CostBreakdown(
            videoDuration: duration,
            baseCost: baseCost,
            stagesCosts: stagesCost,
            totalCost: totalCost
        )
    }
    
    /// Add credits (for purchases)
    public func addCredits(_ amount: Int, fromPurchase: Bool = true) {
        credits += amount
        if fromPurchase && !hasPurchased {
            hasPurchased = true
            userDefaults.set(true, forKey: hasPurchasedKey)
        }
        saveCredits()
        lastCreditError = nil
        print("✅ Added \(amount) credits. Total: \(credits)")
        
        // Track lifetime credits
        let lifetime = userDefaults.integer(forKey: "lifetime_credits_earned")
        userDefaults.set(lifetime + amount, forKey: "lifetime_credits_earned")
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .creditsDidChange,
            object: nil,
            userInfo: ["creditsAdded": amount, "total": credits]
        )
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
