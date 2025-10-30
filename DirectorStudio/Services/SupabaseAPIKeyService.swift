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
        // PostgREST uses special query format: service=eq.Pollo
        // The "eq." prefix is part of PostgREST's query syntax, not a URL encoding issue
        let baseURL = "\(supabaseURL)/rest/v1/api_keys"
        // Construct query string directly - PostgREST expects: service=eq.{value}
        let queryString = "service=eq.\(service)&select=key"
        let fullURLString = "\(baseURL)?\(queryString)"
        
        guard let url = URL(string: fullURLString) else {
            print("❌ Failed to create URL for service: \(service)")
            print("❌ URL string was: \(fullURLString)")
            throw APIKeyError.invalidResponse
        }
        
        print("🔗 Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        print("📤 Headers: apikey=\(supabaseAnonKey.prefix(20))..., Authorization=Bearer \(supabaseAnonKey.prefix(20))...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw APIKeyError.invalidResponse
        }
        
        print("📥 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ Failed to fetch \(service) key: HTTP \(httpResponse.statusCode)")
            print("📦 Response body: \(responseBody)")
            print("🔗 Requested URL: \(url.absoluteString)")
            
            if httpResponse.statusCode == 400 {
                print("💡 HTTP 400 Bad Request - Check:")
                print("   1) Service name matches exactly: '\(service)'")
                print("   2) Row exists in api_keys table")
                print("   3) RLS policy allows anon read access")
                print("   4) URL format is correct: service=eq.{service_name}")
            } else if httpResponse.statusCode == 401 {
                print("💡 HTTP 401 Unauthorized - Check Supabase anon key is correct")
            } else if httpResponse.statusCode == 404 {
                print("💡 HTTP 404 Not Found - Check api_keys table exists and has row for '\(service)'")
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
        print("🗑️ Clearing Supabase API key cache")
        keyCache.removeAll()
    }
    
    /// Force refresh a specific service key (clear cache for that service)
    func forceRefresh(service: String) {
        print("🔄 Force refreshing \(service) API key cache")
        keyCache.removeValue(forKey: service)
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

