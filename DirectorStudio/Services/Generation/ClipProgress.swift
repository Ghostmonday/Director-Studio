// MODULE: ClipProgress
// VERSION: 1.0.0
// PURPOSE: Progress tracking model for UI updates
// PRODUCTION-GRADE: Observable, thread-safe status

import Foundation

/// Progress status for a single clip generation
public struct ClipProgress: Identifiable, Sendable {
    public let id: UUID
    public let status: Status
    
    public enum Status: Sendable {
        case checkingCache
        case generating
        case polling
        case completed
        case failed(String)
        
        public var rawValue: String {
            switch self {
            case .checkingCache: return "Checking Cache"
            case .generating: return "Generating"
            case .polling: return "Polling Status"
            case .completed: return "Completed"
            case .failed(let message): return "Failed: \(message)"
            }
        }
    }
    
    public init(id: UUID, status: Status) {
        self.id = id
        self.status = status
    }
}

