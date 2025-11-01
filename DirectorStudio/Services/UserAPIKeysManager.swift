// MODULE: UserAPIKeysManager
// VERSION: 1.0.0
// PURPOSE: Manage user-provided API keys (e.g., Runway) stored locally

import Foundation

/// Manages user-provided API keys stored locally on device
/// Allows users to use their own API keys for optional services
public final class UserAPIKeysManager: ObservableObject {
    public static let shared = UserAPIKeysManager()
    
    @Published public var runwayAPIKey: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let runwayKeyKey = "user_runway_api_key"
    
    private init() {
        loadKeys()
    }
    
    /// Load all user API keys from storage
    private func loadKeys() {
        if let stored = userDefaults.string(forKey: runwayKeyKey), !stored.isEmpty {
            runwayAPIKey = stored
        }
    }
    
    /// Save Runway API key
    /// - Parameter key: The API key to save (empty string clears it)
    public func setRunwayAPIKey(_ key: String) {
        runwayAPIKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if runwayAPIKey.isEmpty {
            userDefaults.removeObject(forKey: runwayKeyKey)
        } else {
            userDefaults.set(runwayAPIKey, forKey: runwayKeyKey)
        }
    }
    
    /// Get Runway API key if user has provided one
    /// - Returns: User's Runway API key, or nil if not set
    public func getRunwayAPIKey() -> String? {
        let key = runwayAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return key.isEmpty ? nil : key
    }
    
    /// Check if user has provided a Runway API key
    public var hasRunwayKey: Bool {
        return getRunwayAPIKey() != nil
    }
    
    /// Clear all user API keys
    public func clearAllKeys() {
        setRunwayAPIKey("")
    }
}

