//
//  APIUsageManager.swift
//  DirectorStudio
//
//  Emergency API usage tracking to prevent overspending
//

import Foundation

public final class APIUsageManager {
    public static let shared = APIUsageManager()
    
    private let userDefaults = UserDefaults.standard
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // Daily limits (adjust based on your budget)
    private let maxDailyGenerations = 500
    private let maxGenerationsPerUser = 10
    
    private init() {}
    
    /// Check if we can make an API call
    public func canMakeAPICall(userId: String) -> (allowed: Bool, reason: String?) {
        let today = dateFormatter.string(from: Date())
        
        // Check global daily limit
        let globalKey = "api_calls_\(today)"
        let globalCount = userDefaults.integer(forKey: globalKey)
        
        if globalCount >= maxDailyGenerations {
            return (false, "Service at capacity. Please try again tomorrow.")
        }
        
        // Check per-user daily limit
        let userKey = "user_\(userId)_\(today)"
        let userCount = userDefaults.integer(forKey: userKey)
        
        if userCount >= maxGenerationsPerUser {
            return (false, "Daily limit reached. You can generate \(maxGenerationsPerUser) videos per day.")
        }
        
        return (true, nil)
    }
    
    /// Record an API call
    public func recordAPICall(userId: String, cost: Double = 0.25) {
        let today = dateFormatter.string(from: Date())
        
        // Increment global counter
        let globalKey = "api_calls_\(today)"
        let globalCount = userDefaults.integer(forKey: globalKey)
        userDefaults.set(globalCount + 1, forKey: globalKey)
        
        // Increment user counter
        let userKey = "user_\(userId)_\(today)"
        let userCount = userDefaults.integer(forKey: userKey)
        userDefaults.set(userCount + 1, forKey: userKey)
        
        // Track estimated cost
        let costKey = "api_cost_\(today)"
        let currentCost = userDefaults.double(forKey: costKey)
        userDefaults.set(currentCost + cost, forKey: costKey)
        
        print("📊 API Usage: User \(userId) - Call #\(userCount + 1) today")
        print("💰 Estimated daily cost: $\(String(format: "%.2f", currentCost + cost))")
    }
    
    /// Get today's usage stats
    public func getTodayStats() -> (calls: Int, estimatedCost: Double) {
        let today = dateFormatter.string(from: Date())
        let globalKey = "api_calls_\(today)"
        let costKey = "api_cost_\(today)"
        
        let calls = userDefaults.integer(forKey: globalKey)
        let cost = userDefaults.double(forKey: costKey)
        
        return (calls, cost)
    }
    
    /// Emergency shutdown if spending too much
    public func checkEmergencyShutdown() -> Bool {
        let stats = getTodayStats()
        let maxDailyCost = 50.0 // $50 per day max
        
        if stats.estimatedCost > maxDailyCost {
            print("🚨 EMERGENCY: Daily cost limit exceeded! Shutting down API calls.")
            return true
        }
        
        return false
    }
}
