// MODULE: ClipAsset
// VERSION: 1.0.0
// PURPOSE: Data model for generated video clips

import Foundation

struct ClipAsset: Identifiable, Codable {
    let id: UUID
    let title: String
    let prompt: String
    let status: ClipStatus
    let createdAt: Date
    let videoURL: String?
    let thumbnailURL: String?
    
    init(id: UUID = UUID(), title: String, prompt: String, status: ClipStatus = .processing) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.status = status
        self.createdAt = Date()
        self.videoURL = nil
        self.thumbnailURL = nil
    }
}

enum ClipStatus: String, Codable, CaseIterable {
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}
