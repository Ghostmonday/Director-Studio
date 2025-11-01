// MODULE: TelemetryService
// VERSION: 2.0.0
// PURPOSE: Structured telemetry with trace ID correlation and event types
// BUILD STATUS: ✅ Complete

import Foundation

/// Telemetry event types for structured logging
public enum TelemetryEventType: String, Codable {
    case clipGenerationStart = "clip_generation_start"
    case clipGenerationSuccess = "clip_generation_success"
    case clipGenerationFailure = "clip_generation_failure"
    case clipGenerationRetry = "clip_generation_retry"
    case apiCall = "api_call"
    case creditDeduction = "credit_deduction"
    case syncFailure = "sync_failure"
    case cacheHit = "cache_hit"
    case cacheMiss = "cache_miss"
}

/// DirectorStudio Telemetry Service with trace ID correlation
/// Sends events directly to Supabase via REST API
public actor TelemetryService {
    public static let shared = TelemetryService()
    
    private let supabaseURL = "https://carkncjucvtbggqrilwj.supabase.co"
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhcmtuY2p1Y3Z0YmdncXJpbHdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1NjQ1NjIsImV4cCI6MjA3NjE0MDU2Mn0.Iksm_EIXh4UpBFRt7rXv08SuqfJYyJZbwB9yK0lGyes"
    
    // In-memory buffer for batched flushing
    private var eventBuffer: [[String: Any]] = []
    private let maxBufferSize = 50
    private var flushTask: Task<Void, Never>?
    
    private init() {}
    
    /// Session-wide trace ID for correlation
    public var sessionTraceId: String = UUID().uuidString
    
    /// Log a structured telemetry event with trace ID
    /// - Parameters:
    ///   - type: Event type
    ///   - traceId: Trace ID for correlation
    ///   - payload: Event-specific payload
    public func logEvent(_ type: TelemetryEventType, traceId: String, payload: [String: Any] = [:]) {
        let event: [String: Any] = [
            "event_name": type.rawValue,
            "trace_id": traceId,
            "session_trace_id": sessionTraceId,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "metadata": payload
        ]
        
        eventBuffer.append(event)
        
        // Auto-flush if buffer is full
        if eventBuffer.count >= maxBufferSize {
            flushBuffer()
        }
    }
    
    /// Log API call with status code and duration
    /// - Parameters:
    ///   - method: API method name
    ///   - traceId: Trace ID
    ///   - statusCode: HTTP status code
    ///   - duration: Request duration in seconds
    public func logApiCall(method: String, traceId: String, statusCode: Int, duration: TimeInterval) {
        logEvent(.apiCall, traceId: traceId, payload: [
            "method": method,
            "status_code": statusCode,
            "duration_ms": Int(duration * 1000)
        ])
    }
    
    /// Flush buffered events to Supabase
    private func flushBuffer() {
        guard !eventBuffer.isEmpty else { return }
        
        let eventsToFlush = eventBuffer
        eventBuffer.removeAll()
        
        flushTask?.cancel()
        flushTask = Task {
            await sendBatch(events: eventsToFlush)
        }
    }
    
    /// Send batch of events to Supabase
    private func sendBatch(events: [[String: Any]]) async {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/telemetry_events") else {
            print("❌ Invalid Supabase URL")
            return
        }
        
        for event in events {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
            request.setValue("public", forHTTPHeaderField: "apikey")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: event)
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299).contains(httpResponse.statusCode) {
                    print("❌ Telemetry failed: HTTP \(httpResponse.statusCode)")
                }
            } catch {
                print("❌ Telemetry error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Manually flush buffer (called on app background/termination)
    public func flush() async {
        flushBuffer()
        await flushTask?.value
    }
    
    /// Legacy method for backward compatibility
    public nonisolated func logEvent(_ eventName: String, metadata: [String: Any]? = nil, userId: String? = nil) {
        Task {
            await logEvent(
                .apiCall,
                traceId: await sessionTraceId,
                payload: metadata ?? [:]
            )
        }
    }
}