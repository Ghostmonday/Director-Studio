#!/usr/bin/swift

// Test script to verify Supabase connection
// Run with: swift test_supabase_connection.swift

import Foundation

// Copy of the service implementation for testing
class SupabaseAPIKeyService {
    private let supabaseURL = "https://xduwbxbulphvuqqfjrec.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhkdXdieGJ1bHBodnVxcWZqcmVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0MDcyMzIsImV4cCI6MjA3Njk4MzIzMn0.dtRj2vDMrLlJSeZ-5wvl-krQLn0IG9Wnzuqgm_AzwSw"
    
    func fetchAPIKey(for service: String) async throws -> String {
        print("🔑 Fetching \(service) key from hosted Supabase...")
        
        let url = URL(string: "\(supabaseURL)/rest/v1/api_keys?service=eq.\(service)&select=key")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid response", code: 0)
        }
        
        print("HTTP Status: \(httpResponse.statusCode)")
        print("Response: \(String(data: data, encoding: .utf8) ?? "nil")")
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "HTTP error: \(httpResponse.statusCode)", code: httpResponse.statusCode)
        }
        
        struct APIKeyRecord: Codable {
            let key: String
        }
        
        let results = try JSONDecoder().decode([APIKeyRecord].self, from: data)
        
        guard let record = results.first else {
            throw NSError(domain: "No key found for service: \(service)", code: 404)
        }
        
        return record.key
    }
}

// Test function
func testSupabaseConnection() async {
    let service = SupabaseAPIKeyService()
    
    print("🧪 Testing Supabase Connection...")
    print("=" * 50)
    
    // Test Pollo key
    do {
        let polloKey = try await service.fetchAPIKey(for: "Pollo")
        print("✅ Pollo API Key: \(String(polloKey.prefix(10)))...")
    } catch {
        print("❌ Failed to fetch Pollo key: \(error)")
    }
    
    print("")
    
    // Test DeepSeek key
    do {
        let deepSeekKey = try await service.fetchAPIKey(for: "DeepSeek")
        print("✅ DeepSeek API Key: \(String(deepSeekKey.prefix(10)))...")
    } catch {
        print("❌ Failed to fetch DeepSeek key: \(error)")
    }
    
    print("=" * 50)
    print("🎉 Test complete!")
}

// Extension for string multiplication
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Run the test
Task {
    await testSupabaseConnection()
    exit(0)
}

// Keep the script running
RunLoop.main.run()
