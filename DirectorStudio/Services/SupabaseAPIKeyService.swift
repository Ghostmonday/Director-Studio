// MODULE: SupabaseAPIKeyService
// VERSION: 2.0.0
// PURPOSE: Securely fetch API keys from hosted Supabase backend

import Foundation

/// Service for fetching API keys from Supabase database
/// Keys are stored securely in Supabase database, never in app binary
class SupabaseAPIKeyService {
    static let shared = SupabaseAPIKeyService()
    
    // Hosted Supabase instance
    private let supabaseURL = "https://carkncjucvtbggqrilwj.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhcmtuY2p1Y3Z0YmdncXJpbHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1NjQ1NjIsImV4cCI6MjA3NjE0MDU2Mn0.Iksm_EIXh4UpBFRt7rXv08SuqfJYyJZbwB9yK0lGyes"
    
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
        
        print("🔑 Fetching \(service) key from hosted Supabase...")
        
        // Use Supabase REST API to query the api_keys table
        let url = URL(string: "\(supabaseURL)/rest/v1/api_keys?service=eq.\(service)&select=key")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIKeyError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ Failed to fetch \(service) key: HTTP \(httpResponse.statusCode)")
            print("📦 Response: \(responseBody.prefix(200))")
            
            if httpResponse.statusCode == 400 {
                print("💡 Check: 1) Service name matches Supabase ('Pollo', 'DeepSeek', etc.), 2) Row exists in api_keys table")
            } else if httpResponse.statusCode == 401 {
                print("💡 Check: Supabase anon key is correct")
            } else if httpResponse.statusCode == 404 {
                print("💡 Check: api_keys table exists and has a row for service '\(service)'")
            }
            
            throw APIKeyError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response array
        let results = try JSONDecoder().decode([APIKeyRecord].self, from: data)
        
        guard let record = results.first else {
            print("❌ No API key found for service: \(service)")
            throw APIKeyError.missingKey
        }
        
        // Cache the key
        keyCache[service] = record.key
        
        print("✅ Successfully fetched \(service) key from hosted Supabase")
        return record.key
    }
    
    /// Fetch API key using a more injectable approach for pipeline modules
    /// - Parameter service: Service name (e.g. "Pollo", "DeepSeek")
    /// - Returns: The API key for the service
    func fetchAPIKey(for service: String) async throws -> String {
        return try await getAPIKey(service: service)
    }
    
    /// Clear the key cache (e.g. on logout)
    func clearCache() {
        keyCache.removeAll()
    }
}

// MARK: - Response Models

struct APIKeyRecord: Codable {
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

