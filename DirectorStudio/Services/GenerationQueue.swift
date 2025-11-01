// MODULE: GenerationQueue
// VERSION: 1.0.0
// PURPOSE: Actor-based queue for managing concurrent video generations with a maximum limit
// PRODUCTION-GRADE: Thread-safe, concurrent task management, error propagation

import Foundation
import os.log

/// Actor-based queue for managing concurrent video generation tasks
/// Limits concurrent executions to prevent API overload and resource exhaustion
public actor GenerationQueue {
    /// Maximum number of concurrent video generation tasks
    private let maxConcurrentTasks: Int = 3
    
    /// Currently active generation tasks
    private var activeTasks: [UUID: Task<URL, Error>] = [:]
    
    /// Queue of pending generation requests
    private var pendingQueue: [GenerationRequest] = []
    
    /// Logger for queue operations
    private let logger = Logger(subsystem: "DirectorStudio.Generation", category: "Queue")
    
    /// Shared singleton instance
    public static let shared = GenerationQueue()
    
    private init() {
        logger.info("🚀 GenerationQueue initialized with max concurrent tasks: \(maxConcurrentTasks)")
    }
    
    /// Enqueue a video generation task
    /// - Parameter request: The generation request to queue
    /// - Returns: The generated video URL
    /// - Throws: GenerationError if the task fails
    public func enqueue(_ request: GenerationRequest) async throws -> URL {
        let taskId = request.id
        
        logger.info("📥 [\(taskId)] Enqueuing generation request")
        
        // If we're under the limit, execute immediately
        if activeTasks.count < maxConcurrentTasks {
            logger.info("✅ [\(taskId)] Slot available, executing immediately")
            return try await executeTask(request)
        }
        
        // Otherwise, add to queue
        logger.info("⏳ [\(taskId)] Queue full (\(activeTasks.count)/\(maxConcurrentTasks)), waiting...")
        pendingQueue.append(request)
        
        // Wait for our turn and execute
        return try await waitAndExecute(request)
    }
    
    /// Execute a generation task immediately
    private func executeTask(_ request: GenerationRequest) async throws -> URL {
        let taskId = request.id
        
        // Create the actual generation task
        let generationTask = Task<URL, Error> {
            do {
                logger.info("🎬 [\(taskId)] Starting generation")
                let result = try await request.generator()
                logger.info("✅ [\(taskId)] Generation completed")
                return result
            } catch {
                logger.error("❌ [\(taskId)] Generation failed: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Store the task
        activeTasks[taskId] = generationTask
        
        // Wait for completion and clean up
        defer {
            activeTasks.removeValue(forKey: taskId)
            logger.debug("🧹 [\(taskId)] Task removed, active: \(activeTasks.count)/\(maxConcurrentTasks)")
            
            // Process next item in queue if available
            Task {
                await processNextInQueue()
            }
        }
        
        // Wait for the generation to complete
        return try await generationTask.value
    }
    
    /// Wait for a slot to become available and then execute
    private func waitAndExecute(_ request: GenerationRequest) async throws -> URL {
        let taskId = request.id
        
        // Poll until we get a slot
        while activeTasks.count >= maxConcurrentTasks {
            // Check if we've been cancelled
            try Task.checkCancellation()
            
            // Wait a bit before checking again
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Once we have a slot, remove from queue and execute
        if let index = pendingQueue.firstIndex(where: { $0.id == taskId }) {
            pendingQueue.remove(at: index)
        }
        
        logger.info("✅ [\(taskId)] Slot available, executing")
        return try await executeTask(request)
    }
    
    /// Process the next item in the queue
    private func processNextInQueue() async {
        guard !pendingQueue.isEmpty, activeTasks.count < maxConcurrentTasks else {
            return
        }
        
        let nextRequest = pendingQueue.removeFirst()
        logger.info("🔄 Processing next in queue: \(nextRequest.id)")
        
        // Execute in background - don't await here to avoid blocking
        Task {
            do {
                _ = try await executeTask(nextRequest)
            } catch {
                logger.error("❌ Queue task failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Cancel a specific generation task
    /// - Parameter taskId: The ID of the task to cancel
    public func cancelTask(_ taskId: UUID) async {
        if let task = activeTasks[taskId] {
            task.cancel()
            activeTasks.removeValue(forKey: taskId)
            logger.info("🚫 [\(taskId)] Task cancelled")
        }
        
        // Remove from pending queue if present
        pendingQueue.removeAll { $0.id == taskId }
        
        // Process next in queue
        await processNextInQueue()
    }
    
    /// Cancel all pending and active tasks
    public func cancelAll() async {
        logger.info("🚫 Cancelling all tasks")
        
        // Cancel all active tasks
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()
        
        // Clear pending queue
        pendingQueue.removeAll()
        
        logger.info("✅ All tasks cancelled")
    }
    
    /// Get current queue status
    public func getStatus() async -> QueueStatus {
        return QueueStatus(
            activeCount: activeTasks.count,
            pendingCount: pendingQueue.count,
            maxConcurrent: maxConcurrentTasks
        )
    }
}

// MARK: - Supporting Types

/// Represents a video generation request in the queue
public struct GenerationRequest: Sendable {
    public let id: UUID
    public let prompt: String
    public let generator: @Sendable () async throws -> URL
    
    public init(
        id: UUID = UUID(),
        prompt: String,
        generator: @escaping @Sendable () async throws -> URL
    ) {
        self.id = id
        self.prompt = prompt
        self.generator = generator
    }
}

/// Current status of the generation queue
public struct QueueStatus: Sendable {
    public let activeCount: Int
    public let pendingCount: Int
    public let maxConcurrent: Int
    
    public var isAtCapacity: Bool {
        activeCount >= maxConcurrent
    }
    
    public var hasPending: Bool {
        pendingCount > 0
    }
}

