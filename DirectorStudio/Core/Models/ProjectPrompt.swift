// MODULE: ProjectPrompt
// VERSION: 2.0.0
// PURPOSE: Model for tracking individual prompts in a project with generation state
// PRODUCTION-GRADE: Equatable, helper methods, safe mutations

import Foundation

/// Represents a single prompt in a project with generation tracking
public struct ProjectPrompt: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let index: Int
    public let prompt: String
    
    public var status: GenerationStatus = .pending
    public var generatedClipID: UUID?
    public var extractedDialogue: String?
    public var klingVersion: KlingVersion?
    public var generationTier: VideoQualityTier?
    public var retryCount: Int = 0
    public var apiUsed: String?  // "pollo", "runway", "kling"
    public var metrics: GenerationMetrics?
    public var dialogueHash: String?  // For TTS caching
    public var visualComplexityScore: Float?  // For tier selection
    
    public let createdAt: Date
    public var updatedAt: Date
    
    public enum GenerationStatus: String, Codable, Sendable {
        case pending
        case generating
        case completed
        case failed
    }
    
    public init(
        id: UUID = UUID(),
        index: Int,
        prompt: String,
        status: GenerationStatus = .pending,
        extractedDialogue: String? = nil,
        visualComplexityScore: Float? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.index = index
        self.prompt = prompt
        self.status = status
        self.extractedDialogue = extractedDialogue
        self.visualComplexityScore = visualComplexityScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Mark prompt as generating and increment retry count
    public mutating func markGenerating() {
        status = .generating
        retryCount += 1
        updatedAt = Date()
    }
    
    /// Mark prompt as completed with clip ID and metrics
    /// - Parameters:
    ///   - clipID: The generated clip identifier
    ///   - metrics: Generation performance metrics
    public mutating func markCompleted(clipID: UUID, metrics: GenerationMetrics) {
        status = .completed
        generatedClipID = clipID
        self.metrics = metrics
        updatedAt = Date()
    }
    
    /// Mark prompt as failed
    public mutating func markFailed() {
        status = .failed
        updatedAt = Date()
    }
    
    // Equatable conformance (compares by id)
    public static func == (lhs: ProjectPrompt, rhs: ProjectPrompt) -> Bool {
        lhs.id == rhs.id
    }
}

/// Kling AI version tracking for API selection
public enum KlingVersion: String, Codable, Sendable {
    case v1_6_standard = "1.6-standard"
    case v2_0_master = "2.0-master"
    case v2_5_turbo = "2.5-turbo"
    
    /// Maps to VideoQualityTier for compatibility
    public var qualityTier: VideoQualityTier {
        switch self {
        case .v1_6_standard:
            return .economy
        case .v2_0_master:
            return .basic
        case .v2_5_turbo:
            return .pro
        }
    }
}
