// MODULE: ClipProgress
// VERSION: 1.1.0
// PURPOSE: Progress tracking model for UI updates with Kling API flow
// PRODUCTION-GRADE: Observable, thread-safe status, granular API status tracking

import Foundation
import SwiftUI

/// Progress status for a single clip generation
/// Reflects the Kling API flow: task creation → polling → downloading → completed
public struct ClipProgress: Identifiable, Sendable {
    public let id: UUID
    public let status: Status
    public let taskId: String?  // Kling task ID once created
    public let currentGenerationStatus: String?  // Current status from API: "waiting", "processing", "succeed", "failed"
    
    public enum Status: Sendable {
        case checkingCache
        case creatingTask      // POST request to create generation task
        case taskCreated       // Task created, waiting for first status check
        case waiting           // API status: "waiting" - task queued
        case processing        // API status: "processing" - video being generated
        case videoReady        // API status: "succeed" - video URL available, downloading
        case downloading       // Downloading video from remote URL
        case completed
        case failed(String)   // Error message from API or local error
        
        public var rawValue: String {
            switch self {
            case .checkingCache: return "Checking Cache"
            case .creatingTask: return "Creating Task"
            case .taskCreated: return "Task Created"
            case .waiting: return "Queued"
            case .processing: return "Generating Video"
            case .videoReady: return "Video Ready"
            case .downloading: return "Downloading"
            case .completed: return "Completed"
            case .failed(let message): return "Failed: \(message)"
            }
        }
        
        /// Returns a user-friendly description
        public var description: String {
            switch self {
            case .checkingCache:
                return "Checking if video already exists..."
            case .creatingTask:
                return "Submitting generation request..."
            case .taskCreated:
                return "Task submitted, checking status..."
            case .waiting:
                return "Your video is queued, waiting to start..."
            case .processing:
                return "AI is creating your video..."
            case .videoReady:
                return "Video generated! Preparing download..."
            case .downloading:
                return "Downloading video to your device..."
            case .completed:
                return "Video ready to use!"
            case .failed(let message):
                return "Error: \(message)"
            }
        }
        
        /// Returns an icon name for this status
        public var icon: String {
            switch self {
            case .checkingCache: return "magnifyingglass"
            case .creatingTask: return "paperplane.fill"
            case .taskCreated: return "checkmark.circle"
            case .waiting: return "clock.fill"
            case .processing: return "sparkles"
            case .videoReady: return "checkmark.circle.fill"
            case .downloading: return "arrow.down.circle.fill"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        /// Returns a color for this status
        public var color: Color {
            switch self {
            case .checkingCache, .creatingTask, .taskCreated:
                return .blue
            case .waiting:
                return .orange
            case .processing:
                return .purple
            case .videoReady, .downloading:
                return .green
            case .completed:
                return .green
            case .failed:
                return .red
            }
        }
        
        /// Whether this status indicates progress (animated)
        public var isProgressState: Bool {
            switch self {
            case .creatingTask, .waiting, .processing, .downloading:
                return true
            default:
                return false
            }
        }
    }
    
    public init(id: UUID, status: Status, taskId: String? = nil, currentGenerationStatus: String? = nil) {
        self.id = id
        self.status = status
        self.taskId = taskId
        self.currentGenerationStatus = currentGenerationStatus
    }
}

