//
//  CreditsManager.swift
//  DirectorStudio
//
//  PURPOSE: Manage user credits and demo mode based on credits
//

import Foundation
import CoreTypes

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
    
    private let userDefaults = UserDefaults.standard
    private let creditsKey = "user_credits"
    private let firstLaunchKey = "first_launch_completed"
    
    private init() {
        loadCredits()
        checkFirstLaunch()
    }
    
    /// Load credits from storage
    private func loadCredits() {
        credits = userDefaults.integer(forKey: creditsKey)
    }
    
    /// Save credits to storage
    private func saveCredits() {
        userDefaults.set(credits, forKey: creditsKey)
    }
    
    /// Check if this is first launch and give free credits
    private func checkFirstLaunch() {
        if !userDefaults.bool(forKey: firstLaunchKey) {
            // First launch - give 3 free credits
            credits = 3
            saveCredits()
            userDefaults.set(true, forKey: firstLaunchKey)
            print("🎁 Welcome! You've received 3 free credits to get started!")
        }
    }
    
    /// Check if user should be in demo mode
    public var shouldUseDemoMode: Bool {
        return credits <= 0
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
        guard credits >= amount else {
            print("❌ Not enough credits. Need \(amount), have \(credits)")
            return false
        }
        
        credits -= amount
        saveCredits()
        print("💳 Used \(amount) credits. Remaining: \(credits)")
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
    public func addCredits(_ amount: Int) {
        credits += amount
        saveCredits()
        print("✅ Added \(amount) credits. Total: \(credits)")
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
}
