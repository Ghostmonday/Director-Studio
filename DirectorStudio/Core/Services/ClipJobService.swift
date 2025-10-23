// MODULE: ClipJobService
// VERSION: 1.0.0
// PURPOSE: Service for managing clip jobs with Supabase

import Foundation

class ClipJobService: ObservableObject {
    static let shared = ClipJobService()
    
    @Published var jobs: [ClipJob] = []
    
    private let localStorage = LocalStorageService.shared
    private let syncService = SyncService.shared
    
    private init() {}
    
    // MARK: - Clip Job Operations
    
    func enqueueClipJob(prompt: String, userId: UUID, userKey: String) async throws -> UUID {
        let jobId = UUID()
        let job = ClipJob(
            id: jobId,
            userId: userId,
            userKey: userKey,
            prompt: prompt,
            status: "queued",
            submittedAt: Date(),
            completedAt: nil,
            downloadUrl: nil,
            errorMessage: nil
        )
        
        // Local optimistic insert
        localStorage.upsertClipJob(job)
        jobs.append(job)
        
        // Enqueue remote sync
        try await syncService.enqueueRemoteUpsert(
            tableName: "clip_jobs",
            record: [
                "id": jobId.uuidString,
                "user_id": userId.uuidString,
                "user_key": userKey,
                "prompt": prompt,
                "status": "queued",
                "submitted_at": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        return jobId
    }
    
    func getClipJobStatus(userId: UUID, jobId: UUID) async throws -> ClipJob? {
        // Fetch from Supabase
        return jobs.first { $0.id == jobId && $0.userId == userId }
    }
    
    func listClipJobs(userId: UUID, limit: Int = 50, offset: Int = 0) async throws -> [ClipJob] {
        return Array(jobs.filter { $0.userId == userId }.dropFirst(offset).prefix(limit))
    }
    
    func subscribeToJobUpdates(jobId: UUID, callback: @escaping (ClipJob) -> Void) {
        // Implement Supabase Realtime subscription
        syncService.subscribeToRemote(tableName: "clip_jobs", userId: UUID()) { update in
            // Handle update
        }
    }
}

