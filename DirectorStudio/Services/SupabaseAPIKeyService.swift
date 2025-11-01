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
    
    /// Fetch API key for a specific service (Kling, DeepSeek, etc.)
    /// - Parameter service: Service name (e.g. "Kling", "DeepSeek")
    /// - Returns: The API key for the service
    func getAPIKey(service: String) async throws -> String {
        let requestId = UUID().uuidString.prefix(8)
        let startTime = Date()
        
        // Return cached key if available
        if let cached = keyCache[service] {
            let cacheDuration = Date().timeIntervalSince(startTime)
            print("🔑 [Supabase][\(requestId)] Using cached \(service) key (fetched in \(String(format: "%.3f", cacheDuration))s)")
            return cached
        }
        
        print("🔑 [Supabase][\(requestId)] Fetching \(service) key from hosted Supabase...")
        
        // Use Supabase REST API to query the api_keys table
        // PostgREST uses special query format: service=eq.Kling
        // The "eq." prefix is part of PostgREST's query syntax, not a URL encoding issue
        let baseURL = "\(supabaseURL)/rest/v1/api_keys"
        // Construct query string directly - PostgREST expects: service=eq.{value}
        let queryString = "service=eq.\(service)&select=key"
        let fullURLString = "\(baseURL)?\(queryString)"
        
        guard let url = URL(string: fullURLString) else {
            print("❌ [Supabase][\(requestId)] Failed to create URL for service: \(service)")
            print("❌ [Supabase][\(requestId)] URL string was: \(fullURLString)")
            throw APIKeyError.httpError(0, service: service, details: "Invalid URL format: \(fullURLString)")
        }
        
        print("🔗 [Supabase][\(requestId)] Request URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        print("📤 [Supabase][\(requestId)] Headers: apikey=\(supabaseAnonKey.prefix(20))..., Authorization=Bearer \(supabaseAnonKey.prefix(20))...")
        
        let requestStartTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let requestDuration = Date().timeIntervalSince(requestStartTime)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [Supabase][\(requestId)] Invalid HTTP response")
            throw APIKeyError.httpError(0, service: service, details: "Invalid HTTP response type")
        }
        
        print("📥 [Supabase][\(requestId)] Response status: \(httpResponse.statusCode) in \(String(format: "%.2f", requestDuration))s")
        
        guard httpResponse.statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            let totalDuration = Date().timeIntervalSince(startTime)
            print("❌ [Supabase][\(requestId)] Failed to fetch \(service) key: HTTP \(httpResponse.statusCode) after \(String(format: "%.2f", totalDuration))s")
            print("📦 [Supabase][\(requestId)] Response body: \(responseBody)")
            print("🔗 [Supabase][\(requestId)] Requested URL: \(url.absoluteString)")
            print("📤 Headers sent: apikey=\(supabaseAnonKey.prefix(20))..., Authorization=Bearer \(supabaseAnonKey.prefix(20))...")
            
            var diagnosticMessage: String?
            if httpResponse.statusCode == 400 {
                diagnosticMessage = "HTTP 400 Bad Request - Most likely RLS policy issue. Check: 1) Run SETUP_RLS.sql in Supabase 2) Service name matches exactly: '\(service)' 3) Verify policy allows 'anon' role SELECT access"
                print("💡 HTTP 400 Bad Request - Most common causes:")
                print("   ❌ RLS policy not allowing 'anon' SELECT access")
                print("   ❌ Service name mismatch (case-sensitive: '\(service)')")
                print("   ❌ Table structure or column name incorrect")
                print("   💡 SOLUTION: Run SETUP_RLS.sql in Supabase SQL Editor")
            } else if httpResponse.statusCode == 401 {
                diagnosticMessage = "HTTP 401 Unauthorized - Supabase anon key invalid or expired. Check the anon key in SupabaseAPIKeyService.swift"
                print("💡 HTTP 401 Unauthorized - Check Supabase anon key is correct and not expired")
            } else if httpResponse.statusCode == 404 {
                diagnosticMessage = "HTTP 404 Not Found - Table or row missing. Check: 1) api_keys table exists 2) Row exists for service '\(service)'"
                print("💡 HTTP 404 Not Found - Check api_keys table exists and has row for '\(service)'")
            } else {
                diagnosticMessage = "HTTP \(httpResponse.statusCode) - Unexpected error. Response: \(responseBody.prefix(200))"
            }
            
            throw APIKeyError.httpError(httpResponse.statusCode, service: service, details: diagnosticMessage)
        }
        
        // Parse the response array
        let results = try JSONDecoder().decode([APIKeyRecord].self, from: data)
        
        guard let record = results.first else {
            print("❌ No API key found for service: \(service)")
            throw APIKeyError.missingKey(service: service)
        }
        
        // Cache the key
        keyCache[service] = record.key
        
        let totalDuration = Date().timeIntervalSince(startTime)
        print("✅ [Supabase][\(requestId)] Successfully fetched \(service) key (\(record.key.prefix(20))...) in \(String(format: "%.2f", totalDuration))s")
        return record.key
    }
    
    /// Fetch API key using a more injectable approach for pipeline modules
    /// - Parameter service: Service name (e.g. "Kling", "DeepSeek")
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
    case httpError(Int, service: String, details: String?)
    case missingKey(service: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, let service, let details):
            var message = "Failed to fetch \(service) API key from Supabase (HTTP \(code))"
            if let details = details, !details.isEmpty {
                message += ": \(details)"
            }
            return message
        case .missingKey(let service):
            return "\(service) API key not found in Supabase database"
        }
    }
}

