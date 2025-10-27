// MODULE: Notifications+Credits
// VERSION: 1.0.0
// PURPOSE: Notification names and helpers for credit system

import Foundation

extension Notification.Name {
    /// Posted when credits change (add or deduct)
    static let creditsDidChange = Notification.Name("creditsDidChange")
    
    /// Posted when user attempts action without sufficient credits
    static let insufficientCredits = Notification.Name("insufficientCredits")
    
    /// Posted when user successfully purchases credits
    static let creditsPurchased = Notification.Name("creditsPurchased")
    
    // Demo mode removed - all users have full access
}

/// Helper to extract credit info from notifications
extension Notification {
    var creditsUsed: Int? {
        return userInfo?["creditsUsed"] as? Int
    }
    
    var creditsAdded: Int? {
        return userInfo?["creditsAdded"] as? Int
    }
    
    var creditsRemaining: Int? {
        return userInfo?["remaining"] as? Int
    }
    
    var creditsTotal: Int? {
        return userInfo?["total"] as? Int
    }
    
    var creditsNeeded: Int? {
        return userInfo?["needed"] as? Int
    }
    
    var creditsHave: Int? {
        return userInfo?["have"] as? Int
    }
}
