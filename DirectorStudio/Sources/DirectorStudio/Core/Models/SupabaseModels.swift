// MODULE: SupabaseModels
// VERSION: 1.0.0
// PURPOSE: Data models matching Supabase schema

import Foundation

// MARK: - Clip Jobs
struct ClipJob: Codable, Identifiable {
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

// MARK: - Credits Ledger
struct CreditsLedger: Codable, Identifiable {
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

// MARK: - User Statistics
struct UserStatistics: Codable {
    let userId: UUID?
    let email: String?
    let credits: Int?
    let totalScenes: Int?
    let totalScreenplays: Int?
    let completedVideos: Int?
    let lastActivity: Date?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case credits
        case totalScenes = "total_scenes"
        case totalScreenplays = "total_screenplays"
        case completedVideos = "completed_videos"
        case lastActivity = "last_activity"
    }
}

// MARK: - Scene Drafts
struct SceneDraft: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let projectId: String
    var orderIndex: Int
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

// MARK: - Screenplays
struct Screenplay: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let title: String
    let content: String
    let version: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case content
        case version
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Screenplay Sections
struct ScreenplaySection: Codable, Identifiable {
    let id: UUID
    let screenplayId: UUID
    let heading: String
    let content: String
    let orderIndex: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case screenplayId = "screenplay_id"
        case heading
        case content
        case orderIndex = "order_index"
        case createdAt = "created_at"
    }
}
