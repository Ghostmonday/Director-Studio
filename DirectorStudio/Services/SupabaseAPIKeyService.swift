// MODULE: SupabaseAPIKeyService
// VERSION: 1.0.0
// PURPOSE: Securely fetch API keys from Supabase backend

import Foundation

/// Service for fetching API keys from Supabase Edge Function
/// Keys are stored securely in Supabase database, never in app binary
class SupabaseAPIKeyService {
    static let shared = SupabaseAPIKeyService()
    
    // TODO: Replace with your actual Supabase project URL
    private let supabaseURL = "https://YOUR_PROJECT_REF.supabase.co"
    
    // Cache keys for session (don't fetch every time)
    private var keyCache: [String: String] = [:]
    
    private init() {}
    
    /// Fetch API key for a specific service (Pollo, DeepSeek, etc.)
    /// - Parameter service: Service name (e.g. "Pollo", "DeepSeek")
    /// - Returns: The API key for the service
    func getAPIKey(service: String) async throws -> String {
        // Return cached key if available
        if let cached = keyCache[service] {
            print("🔑 Using cached \(service) key")
            return cached
        }
        
        print("🔑 Fetching \(service) key from Supabase...")
        
        let url = URL(string: "\(supabaseURL)/functions/v1/generate-api-key")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // TODO: Replace with actual user authentication
        // For now, using dev mode token
        // In production, get from Supabase Auth:
        // let token = try await supabase.auth.session.accessToken
        request.setValue("Bearer dev-token", forHTTPHeaderField: "Authorization")
        
        let body = ["service": service]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIKeyError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Failed to fetch \(service) key: HTTP \(httpResponse.statusCode)")
            throw APIKeyError.httpError(httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(APIKeyResponse.self, from: data)
        
        // Cache the key
        keyCache[service] = result.key
        
        print("✅ Successfully fetched \(service) key")
        return result.key
    }
    
    /// Clear the key cache (e.g. on logout)
    func clearCache() {
        keyCache.removeAll()
    }
}

// MARK: - Response Models

struct APIKeyResponse: Codable {
    let key: String
}

// MARK: - Errors

enum APIKeyError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case missingKey
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .missingKey:
            return "API key not found"
        }
    }
}

