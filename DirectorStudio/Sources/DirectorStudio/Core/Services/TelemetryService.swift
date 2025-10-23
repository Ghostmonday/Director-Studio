// MODULE: TelemetryService
// VERSION: 1.0.0
// PURPOSE: Telemetry service for event tracking and analytics

import Foundation

class TelemetryService: ObservableObject {
    nonisolated(unsafe) static let shared = TelemetryService()
    
    private var eventQueue: [TelemetryEvent] = []
    private let syncService = SyncService.shared
    private var batchTimer: Timer?
    
    private init() {
        startBatchTimer()
    }
    
    // MARK: - Event Emission
    
    func emitEvent(_ event: TelemetryEvent) {
        eventQueue.append(event)
        print("📊 Telemetry: \(event.name)")
    }
    
    // MARK: - Telemetry Events
    
    func storageOpen() {
        emitEvent(TelemetryEvent(
            name: "storage.open",
            userId: nil,
            metadata: [:]
        ))
    }
    
    func storageSyncStarted() {
        emitEvent(TelemetryEvent(
            name: "storage.sync.started",
            userId: nil,
            metadata: [:]
        ))
    }
    
    func storageSyncCompleted(duration: TimeInterval) {
        emitEvent(TelemetryEvent(
            name: "storage.sync.completed",
            userId: nil,
            metadata: ["duration": duration]
        ))
    }
    
    func storageConflictResolved(table: String, resolution: String) {
        emitEvent(TelemetryEvent(
            name: "storage.conflict.resolved",
            userId: nil,
            metadata: [
                "table": table,
                "resolution": resolution
            ]
        ))
    }
    
    func createInitiated(type: String) {
        emitEvent(TelemetryEvent(
            name: "create.initiated",
            userId: nil,
            metadata: ["type": type]
        ))
    }
    
    func createConfirmed(type: String) {
        emitEvent(TelemetryEvent(
            name: "create.confirmed",
            userId: nil,
            metadata: ["type": type]
        ))
    }
    
    func createFailed(type: String, error: String) {
        emitEvent(TelemetryEvent(
            name: "create.failed",
            userId: nil,
            metadata: [
                "type": type,
                "error": error
            ]
        ))
    }
    
    func clipJobSubmitted(jobId: UUID) {
        emitEvent(TelemetryEvent(
            name: "clip_job.submitted",
            userId: nil,
            metadata: ["job_id": jobId.uuidString]
        ))
    }
    
    func clipJobCompleted(jobId: UUID) {
        emitEvent(TelemetryEvent(
            name: "clip_job.completed",
            userId: nil,
            metadata: ["job_id": jobId.uuidString]
        ))
    }
    
    // MARK: - Batch Processing
    
    private func startBatchTimer() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.flushQueue()
        }
    }
    
    private func flushQueue() {
        guard !eventQueue.isEmpty else { return }
        
        let batch = eventQueue
        eventQueue.removeAll()
        
        Task {
            await batchWriteTelemetry(batch)
        }
    }
    
    private func batchWriteTelemetry(_ events: [TelemetryEvent]) async {
        // Batch write to continuity_telemetry table
        for event in events {
            do {
                try await syncService.enqueueRemoteUpsert(
                    tableName: "continuity_telemetry",
                    record: [
                        "element": event.name,
                        "attempts": 1,
                        "successes": 1,
                        "rate": 1.0,
                        "timestamp": ISO8601DateFormatter().string(from: Date())
                    ]
                )
            } catch {
                print("⚠️ Failed to write telemetry: \(error)")
            }
        }
    }
}

struct TelemetryEvent {
    let name: String
    let userId: UUID?
    let metadata: [String: Any]
}

