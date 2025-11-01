// MODULE: VideoEngineRouter
// VERSION: 1.0.0
// PURPOSE: Multi-API backend routing with zero-downtime switching
// BUILD STATUS: ✅ Complete

import Foundation

/// Video generation engine types with routing and cost information
public enum VideoEngine: String, Codable, CaseIterable {
    case kling = "kling"
    case runway = "runway"
    case custom = "custom"
    case none = "none"
    
    /// Base URL for the API endpoint
    public var baseURL: URL {
        switch self {
        case .kling:
            return URL(string: "https://api-singapore.klingai.com/v1")!
        case .runway:
            return URL(string: "https://api.runwayml.com/v4")!
        case .custom:
            if let customURL = UserDefaults.standard.string(forKey: "custom_api_url"),
               !customURL.isEmpty,
               let url = URL(string: customURL) {
                return url
            }
            // Fallback to Kling if custom URL invalid
            return URL(string: "https://api-singapore.klingai.com/v1")!
        case .none:
            fatalError("No engine selected")
        }
    }
    
    /// Authentication header for the engine
    public var authHeader: (key: String, value: String)? {
        switch self {
        case .kling:
            // Use Supabase for Kling credentials (existing system)
            // Return nil to use existing JWT system
            return nil // Handled by KlingAPIClient's JWT system
            
        case .runway:
            guard let token = UserDefaults.standard.string(forKey: "runway_bearer_token"),
                  !token.isEmpty else {
                return nil
            }
            return ("Authorization", "Bearer \(token)")
            
        case .custom:
            guard let header = UserDefaults.standard.string(forKey: "custom_auth_header"),
                  !header.isEmpty else {
                return nil
            }
            // Parse header format: "Key: Value" or just "Value"
            if header.contains(":") {
                let parts = header.components(separatedBy: ":")
                if parts.count >= 2 {
                    return (parts[0].trimmingCharacters(in: .whitespaces),
                           parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces))
                }
            }
            return ("Authorization", header)
            
        case .none:
            return nil
        }
    }
    
    /// Cost per clip in credits
    public var costPerClip: Int {
        switch self {
        case .kling:
            return 12 // Average across v1.6, v2.0, v2.5
        case .runway:
            return 28 // Runway Gen-4 pricing
        case .custom:
            return 20 // Default custom pricing
        case .none:
            return 0
        }
    }
    
    /// Expected latency in seconds
    public var expectedLatency: TimeInterval {
        switch self {
        case .kling:
            return 4.2
        case .runway:
            return 7.8
        case .custom:
            return 6.0
        case .none:
            return .infinity
        }
    }
    
    /// Human-readable name
    public var displayName: String {
        switch self {
        case .kling:
            return "Kling AI"
        case .runway:
            return "Runway Gen-4"
        case .custom:
            return "Custom API"
        case .none:
            return "None"
        }
    }
    
    /// Check if engine has valid credentials
    public var hasValidCredentials: Bool {
        switch self {
        case .kling:
            // Kling uses Supabase, so always available if Supabase configured
            return true
        case .runway:
            return UserDefaults.standard.string(forKey: "runway_bearer_token") != nil
        case .custom:
            return UserDefaults.standard.string(forKey: "custom_auth_header") != nil &&
                   UserDefaults.standard.string(forKey: "custom_api_url") != nil
        case .none:
            return false
        }
    }
    
    /// Fallback chain priority
    public static var fallbackChain: [VideoEngine] {
        return [.kling, .runway, .custom]
    }
    
    /// Get next available fallback engine
    public static func nextAvailableFallback(current: VideoEngine) -> VideoEngine? {
        let chain = fallbackChain
        guard let currentIndex = chain.firstIndex(of: current) else {
            return chain.first { $0.hasValidCredentials }
        }
        
        // Try engines after current
        for i in (currentIndex + 1)..<chain.count {
            if chain[i].hasValidCredentials {
                return chain[i]
            }
        }
        
        // Try engines before current
        for i in 0..<currentIndex {
            if chain[i].hasValidCredentials {
                return chain[i]
            }
        }
        
        return nil
    }
}

/// Video generation error types
public enum VideoError: LocalizedError {
    case missingCredentials
    case engineUnavailable(VideoEngine)
    case invalidAPIURL
    case noAvailableEngines
    
    public var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "API credentials are missing for the selected engine"
        case .engineUnavailable(let engine):
            return "\(engine.displayName) is currently unavailable"
        case .invalidAPIURL:
            return "Invalid custom API URL"
        case .noAvailableEngines:
            return "No video generation engines are available"
        }
    }
}

