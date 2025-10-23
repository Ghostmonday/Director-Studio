// MODULE: LocalStorageService
// VERSION: 1.0.0
// PURPOSE: Local-first storage service mirroring Supabase tables

import Foundation

/// Local-first storage service that mirrors Supabase tables for offline resilience
class LocalStorageService: ObservableObject {
    static let shared = LocalStorageService()
    
    @Published var projects: [ProjectOverview] = []
    @Published var sceneDrafts: [SceneDraft] = []
    @Published var clipJobs: [ClipJob] = []
    @Published var creditsLedger: CreditsLedger?
    
    private let syncQueue = SyncQueue()
    
    private init() {
        loadLocalData()
    }
    
    // MARK: - Local-First CRUD Operations
    
    func getProjectOverviews(userId: UUID) -> [ProjectOverview] {
        return projects.filter { $0.userId == userId }
    }
    
    func getSceneDrafts(projectId: String) -> [SceneDraft] {
        return sceneDrafts.filter { $0.projectId == projectId && !$0.archived }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    func upsertProjectOverview(_ project: ProjectOverview) {
        if let index = projects.firstIndex(where: { $0.projectId == project.projectId }) {
            projects[index] = project
        } else {
            projects.append(project)
        }
        saveLocalData()
    }
    
    func upsertSceneDraft(_ draft: SceneDraft) {
        if let index = sceneDrafts.firstIndex(where: { $0.id == draft.id }) {
            sceneDrafts[index] = draft
        } else {
            sceneDrafts.append(draft)
        }
        saveLocalData()
    }
    
    func markSceneDraftArchived(_ id: UUID) {
        if let index = sceneDrafts.firstIndex(where: { $0.id == id }) {
            sceneDrafts[index].archived = true
            sceneDrafts[index].deletedAt = Date()
        }
        saveLocalData()
    }
    
    func upsertClipJob(_ job: ClipJob) {
        if let index = clipJobs.firstIndex(where: { $0.id == job.id }) {
            clipJobs[index] = job
        } else {
            clipJobs.append(job)
        }
        saveLocalData()
    }
    
    // MARK: - Sync Queue Management
    
    func getPendingSyncEntries() -> [SyncEntry] {
        return syncQueue.pendingEntries
    }
    
    func enqueueSync(_ entry: SyncEntry) {
        syncQueue.enqueue(entry)
    }
    
    func removeSyncEntry(_ entryId: UUID) {
        syncQueue.remove(entryId)
    }
    
    // MARK: - Local Data Persistence
    
    private func loadLocalData() {
        // Load from UserDefaults or CoreData
        // For now, just initialize empty
    }
    
    private func saveLocalData() {
        // Persist to UserDefaults or CoreData
    }
}

// MARK: - Data Models

struct ProjectOverview: Identifiable, Codable {
    let projectId: String
    let userId: UUID?
    let sceneCount: Int?
    let totalDuration: Double?
    let projectCreatedAt: Date?
    let lastUpdated: Date?
    
    var id: String { projectId }
    
    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case userId = "user_id"
        case sceneCount = "scene_count"
        case totalDuration = "total_duration"
        case projectCreatedAt = "project_created_at"
        case lastUpdated = "last_updated"
    }
}

struct SceneDraft: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let projectId: String
    let orderIndex: Int
    let promptText: String
    let duration: Double
    let sceneType: String?
    let shotType: String?
    var archived: Bool
    var deletedAt: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case projectId = "project_id"
        case orderIndex = "order_index"
        case promptText = "prompt_text"
        case duration
        case sceneType = "scene_type"
        case shotType = "shot_type"
        case archived
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ClipJob: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let userKey: String
    let prompt: String
    let status: String
    let submittedAt: Date
    let completedAt: Date?
    let downloadUrl: String?
    let errorMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userKey = "user_key"
        case prompt
        case status
        case submittedAt = "submitted_at"
        case completedAt = "completed_at"
        case downloadUrl = "download_url"
        case errorMessage = "error_message"
    }
}

struct CreditsLedger: Codable {
    let id: UUID
    let userKey: String
    let credits: Int
    let firstClipGranted: Bool?
    let firstClipConsumed: Bool?
    let grantedAt: Date?
    let updatedAt: Date?
    let userId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userKey = "user_key"
        case credits
        case firstClipGranted = "first_clip_granted"
        case firstClipConsumed = "first_clip_consumed"
        case grantedAt = "granted_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}

// MARK: - Sync Queue

struct SyncEntry: Identifiable {
    let id: UUID
    let tableName: String
    let operation: SyncOperation
    let payload: [String: Any]
    let createdAt: Date
    
    enum SyncOperation: String {
        case insert
        case update
        case delete
    }
}

class SyncQueue {
    private(set) var pendingEntries: [SyncEntry] = []
    
    func enqueue(_ entry: SyncEntry) {
        pendingEntries.append(entry)
    }
    
    func remove(_ entryId: UUID) {
        pendingEntries.removeAll { $0.id == entryId }
    }
    
    func clear() {
        pendingEntries.removeAll()
    }
}

