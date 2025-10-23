// MODULE: GeneratedClip
// VERSION: 1.0.0
// PURPOSE: Represents a generated video clip with sync status

import Foundation

/// Sync status for clips
enum SyncStatus: String, Codable {
    case notUploaded = "Not Uploaded"
    case uploading = "Uploading"
    case synced = "Synced"
    case failed = "Failed"
}

/// A generated video clip with metadata
struct GeneratedClip: Identifiable, Codable {
    let id: UUID
    var name: String
    var localURL: URL?
    var thumbnailURL: URL?
    var syncStatus: SyncStatus
    var createdAt: Date
    var duration: TimeInterval
    var projectID: UUID?
    
    init(
        id: UUID = UUID(),
        name: String,
        localURL: URL? = nil,
        thumbnailURL: URL? = nil,
        syncStatus: SyncStatus = .notUploaded,
        createdAt: Date = Date(),
        duration: TimeInterval = 0,
        projectID: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.localURL = localURL
        self.thumbnailURL = thumbnailURL
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.duration = duration
        self.projectID = projectID
    }
}

