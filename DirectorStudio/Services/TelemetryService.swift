import Foundation

/// DirectorStudio Telemetry Service
/// Sends events directly to Supabase via REST API
/// NO PACKAGE DEPENDENCIES REQUIRED
final class TelemetryService {
    static let shared = TelemetryService()
    
    private let supabaseURL = "https://carkncjucvtbggqrilwj.supabase.co"
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhcmtuY2p1Y3Z0YmdncXJpbHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1NjQ1NjIsImV4cCI6MjA3NjE0MDU2Mn0.Iksm_EIXh4UpBFRt7rXv08SuqfJYyJZbwB9yK0lGyes"
    
    private init() {}
    
    /// Log a telemetry event
    /// - Parameters:
    ///   - eventName: Event name (e.g., "app_opened", "clip_completed")
    ///   - metadata: Optional event-specific data
    ///   - userId: Optional user ID for authenticated users
    func logEvent(_ eventName: String, metadata: [String: Any]? = nil, userId: String? = nil) {
        Task {
            await sendEvent(eventName: eventName, metadata: metadata, userId: userId)
        }
    }
    
    private func sendEvent(eventName: String, metadata: [String: Any]?, userId: String?) async {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/telemetry_events") else {
            print("❌ Invalid Supabase URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.setValue("public", forHTTPHeaderField: "apikey")
        
        var payload: [String: Any] = [
            "event_name": eventName,
            "metadata": metadata ?? [:]
        ]
        
        if let userId = userId {
            payload["user_id"] = userId
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    print("✅ Telemetry logged: \(eventName)")
                } else {
                    print("❌ Telemetry failed: HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ Telemetry error: \(error.localizedDescription)")
        }
    }
}