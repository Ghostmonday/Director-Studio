// MODULE: PromptJob
// VERSION: 1.0.0
// PURPOSE: Data model for video generation jobs

import Foundation

struct PromptJob: Identifiable, Codable {
    let id: UUID
    let prompt: String
    let status: JobStatus
    let createdAt: Date
    let completedAt: Date?
    
    init(prompt: String) {
        self.id = UUID()
        self.prompt = prompt
        self.status = .pending
        self.createdAt = Date()
        self.completedAt = nil
    }
}

enum JobStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}
