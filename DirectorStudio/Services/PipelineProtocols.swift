// MODULE: PipelineProtocols
// VERSION: 1.0.0
// PURPOSE: Define protocols for pipeline services to enable dependency injection

import Foundation
import UIKit

// MARK: - Core Pipeline Protocols

/// Protocol for video generation services
public protocol VideoGenerationProtocol: Sendable {
    var isAvailable: Bool { get }
    
    func generateVideo(prompt: String, duration: TimeInterval) async throws -> URL
    func generateVideoFromImage(imageData: Data, prompt: String, duration: TimeInterval) async throws -> URL
    func healthCheck() async -> Bool
}

/// Protocol for text enhancement services
public protocol TextEnhancementProtocol: Sendable {
    var isAvailable: Bool { get }
    
    func enhancePrompt(prompt: String) async throws -> String
    func processText(prompt: String, systemPrompt: String?) async throws -> String
    func healthCheck() async -> Bool
}

/// Protocol for continuity management
public protocol ContinuityManagerProtocol {
    func analyzeContinuity(prompt: String, isFirstClip: Bool, referenceImage: Data?) -> ContinuityAnalysis
    func injectContinuity(prompt: String, analysis: ContinuityAnalysis, referenceImage: Data?) -> String
}

/// Protocol for video stitching services
public protocol VideoStitchingProtocol {
    func stitchClips(_ clips: [GeneratedClip], withTransitions: TransitionStyle, outputQuality: ExportQuality) async throws -> URL
}

/// Protocol for voiceover generation services
public protocol VoiceoverGenerationProtocol {
    func generateVoiceover(script: String, style: VoiceoverStyle) async throws -> VoiceoverTrack
}

// MARK: - Supporting Types

/// Transition styles for video stitching
public enum TransitionStyle: String, CaseIterable {
    case cut = "Cut"
    case fadeIn = "Fade In"
    case fadeOut = "Fade Out"
    case crossfade = "Crossfade"
    case dissolve = "Dissolve"
    case wipe = "Wipe"
    
    var duration: TimeInterval {
        switch self {
        case .cut: return 0
        case .fadeIn, .fadeOut: return 0.5
        case .crossfade, .dissolve: return 1.0
        case .wipe: return 0.75
        }
    }
}

/// Voiceover generation styles
public enum VoiceoverStyle: String, CaseIterable {
    case automatic = "Automatic"
    case narrator = "Narrator"
    case conversational = "Conversational"
    case dramatic = "Dramatic"
    case documentary = "Documentary"
    case energetic = "Energetic"
}

/// Script segmentation strategies
public enum SegmentationStrategy {
    case automatic
    case byScenes
    case byDuration(seconds: TimeInterval)
    case byParagraphs
    case custom(segments: [ScriptSegment])
}

/// Represents a segment of a script
public struct ScriptSegment {
    public let id: UUID
    public let text: String
    public let name: String
    public let stages: Set<PipelineStage>
    public let estimatedDuration: TimeInterval
    
    public init(
        id: UUID = UUID(),
        text: String,
        name: String,
        stages: Set<PipelineStage> = Set(PipelineStage.allCases),
        estimatedDuration: TimeInterval = 10.0
    ) {
        self.id = id
        self.text = text
        self.name = name
        self.stages = stages
        self.estimatedDuration = estimatedDuration
    }
}

/// Complete production output
public struct ProductionOutput {
    public let videoURL: URL
    public let voiceoverTrack: VoiceoverTrack?
    public let clips: [GeneratedClip]
    public let totalDuration: TimeInterval
    
    public init(
        videoURL: URL,
        voiceoverTrack: VoiceoverTrack? = nil,
        clips: [GeneratedClip] = [],
        totalDuration: TimeInterval = 0
    ) {
        self.videoURL = videoURL
        self.voiceoverTrack = voiceoverTrack
        self.clips = clips
        self.totalDuration = totalDuration
    }
}

// MARK: - Pipeline Stage Protocol

/// Protocol for pluggable pipeline stages
public protocol PipelineStageProtocol {
    var id: String { get }
    var displayName: String { get }
    var isEnabled: Bool { get }
    
    func execute(input: StageInput) async throws -> StageOutput
    func validate(input: StageInput) -> Bool
}

/// Input for pipeline stages
public struct StageInput {
    public let prompt: String
    public let metadata: [String: Any]
    public let previousOutput: StageOutput?
    
    public init(prompt: String, metadata: [String: Any] = [:], previousOutput: StageOutput? = nil) {
        self.prompt = prompt
        self.metadata = metadata
        self.previousOutput = previousOutput
    }
}

/// Output from pipeline stages
public struct StageOutput {
    public let processedPrompt: String
    public let metadata: [String: Any]
    public let artifacts: [String: Any]
    
    public init(processedPrompt: String, metadata: [String: Any] = [:], artifacts: [String: Any] = [:]) {
        self.processedPrompt = processedPrompt
        self.metadata = metadata
        self.artifacts = artifacts
    }
}
