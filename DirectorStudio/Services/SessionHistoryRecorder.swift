// MODULE: SessionHistoryRecorder
// VERSION: 1.0.0
// PURPOSE: Actor-isolated session history recording with trace ID support
// BUILD STATUS: ✅ Complete

import Foundation

/// Session history entry
public struct SessionHistoryEntry: Codable, Identifiable, Sendable {
    public let id: UUID
    public let traceId: String
    public let eventType: String
    public let timestamp: Date
    public let metadata: [String: String]
    
    public init(
        id: UUID = UUID(),
        traceId: String,
        eventType: String,
        timestamp: Date = Date(),
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.traceId = traceId
        self.eventType = eventType
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

/// Actor-isolated session history recorder
public actor SessionHistoryRecorder {
    public static let shared = SessionHistoryRecorder()
    
    private var history: [SessionHistoryEntry] = []
    private let maxHistorySize = 1000
    
    private init() {}
    
    /// Record a session event
    /// - Parameters:
    ///   - eventType: Event type
    ///   - traceId: Trace ID for correlation
    ///   - metadata: Event metadata
    public func record(eventType: String, traceId: String, metadata: [String: String] = [:]) {
        let entry = SessionHistoryEntry(
            traceId: traceId,
            eventType: eventType,
            metadata: metadata
        )
        
        history.append(entry)
        
        // Trim history if exceeds max size
        if history.count > maxHistorySize {
            history.removeFirst(history.count - maxHistorySize)
        }
    }
    
    /// Get history entries for a trace ID
    /// - Parameter traceId: Trace ID to filter by
    /// - Returns: Array of history entries
    public func getHistory(for traceId: String) -> [SessionHistoryEntry] {
        return history.filter { $0.traceId == traceId }
    }
    
    /// Get all history
    /// - Returns: All history entries
    public func getAllHistory() -> [SessionHistoryEntry] {
        return history
    }
    
    /// Clear history
    public func clear() {
        history.removeAll()
    }
    
    /// Export history as JSON
    /// - Returns: JSON data
    public func exportJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(history)
    }
}

