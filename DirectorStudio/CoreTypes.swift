//
//  CoreTypes.swift
//  DirectorStudio
//
//  MODULE: CoreTypes
//  VERSION: 1.0.0
//  PURPOSE: Foundation types and protocols for DirectorStudio
//

import Foundation
import CoreGraphics

// MARK: - Logging

/// Simple cross-platform logging
public struct SimpleLogger: Sendable {
    public let subsystem: String
    public let category: String
    
    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }
    
    public func info(_ message: String) {
        log(level: "INFO", message: message)
    }
    
    public func warning(_ message: String) {
        log(level: "WARNING", message: message)
    }
    
    public func error(_ message: String) {
        log(level: "ERROR", message: message)
    }
    
    public func debug(_ message: String) {
        log(level: "DEBUG", message: message)
    }
    
    private func log(level: String, message: String) {
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        print("[\(timestamp)] \(level) [\(subsystem).\(category)]: \(message)")
    }
}

extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

/// Global logger instances
public enum Loggers {
    public static let pipeline = SimpleLogger(subsystem: "com.directorstudio.pipeline", category: "pipeline")
    public static let continuity = SimpleLogger(subsystem: "com.directorstudio.pipeline", category: "continuity")
    public static let taxonomy = SimpleLogger(subsystem: "com.directorstudio.pipeline", category: "taxonomy")
    public static let rewording = SimpleLogger(subsystem: "com.directorstudio.pipeline", category: "rewording")
}

// MARK: - Core Data Models

/// Prompt segment model
public struct PromptSegment: Codable, Identifiable, Sendable {
    public let id: UUID
    public let index: Int
    public let duration: TimeInterval
    public var content: String
    public let characters: [String]
    public let setting: String
    public let action: String
    public let continuityNotes: [String]
    public let location: String
    public let props: [String]
    public let tone: String
    public var cinematicTags: CinematicTaxonomy?

    private enum CodingKeys: String, CodingKey {
        case id, index, duration, content, characters, setting, action
        case continuityNotes, location, props, tone, cinematicTags
    }
    
    public init(
        id: UUID = UUID(),
        index: Int,
        duration: TimeInterval,
        content: String,
        characters: [String] = [],
        setting: String = "",
        action: String = "",
        continuityNotes: [String] = [],
        location: String = "",
        props: [String] = [],
        tone: String = ""
    ) {
        self.id = id
        self.index = index
        self.duration = duration
        self.content = content
        self.characters = characters
        self.setting = setting
        self.action = action
        self.continuityNotes = continuityNotes
        self.location = location
        self.props = props
        self.tone = tone
    }
}

/// Continuity anchor
public struct ContinuityAnchor: Codable, Identifiable, Sendable {
    public let id: UUID
    public let anchorType: String
    public let description: String
    public let segmentIndex: Int
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        anchorType: String,
        description: String,
        segmentIndex: Int,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.anchorType = anchorType
        self.description = description
        self.segmentIndex = segmentIndex
        self.timestamp = timestamp
    }
}

/// Cinematic taxonomy
public struct CinematicTaxonomy: Codable, Sendable {
    public let shotType: String
    public let cameraAngle: String
    public let framing: String
    public let lighting: String
    public let colorPalette: String
    public let lensType: String
    public let cameraMovement: String
    public let emotionalTone: String
    public let visualStyle: String
    public let actionCues: [String]
    
    public init(
        shotType: String,
        cameraAngle: String,
        framing: String,
        lighting: String,
        colorPalette: String,
        lensType: String,
        cameraMovement: String,
        emotionalTone: String,
        visualStyle: String,
        actionCues: [String]
    ) {
        self.shotType = shotType
        self.cameraAngle = cameraAngle
        self.framing = framing
        self.lighting = lighting
        self.colorPalette = colorPalette
        self.lensType = lensType
        self.cameraMovement = cameraMovement
        self.emotionalTone = emotionalTone
        self.visualStyle = visualStyle
        self.actionCues = actionCues
    }
}

/// Scene model for continuity
public struct SceneModel: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public let location: String
    public let characters: [String]
    public let props: [String]
    public let prompt: String
    public let tone: String
    
    public init(
        id: Int,
        location: String,
        characters: [String],
        props: [String],
        prompt: String,
        tone: String
    ) {
        self.id = id
        self.location = location
        self.characters = characters
        self.props = props
        self.prompt = prompt
        self.tone = tone
    }
}

/// Project model
public struct Project: Codable, Identifiable {
    public var id: UUID
    public var name: String
    public var description: String
    public let createdAt: Date
    public var lastModified: Date
    public var updatedAt: Date
    public var clipCount: Int
    public var voiceoverCount: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        updatedAt: Date = Date(),
        clipCount: Int = 0,
        voiceoverCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.updatedAt = updatedAt
        self.clipCount = clipCount
        self.voiceoverCount = voiceoverCount
    }
    
    /// Generate next clip name based on project name and count
    public func nextClipName() -> String {
        return "\(name) — Clip \(clipCount + 1)"
    }
}

// MARK: - Pipeline Protocols

/// Core pipeline module protocol
public protocol PipelineModule: ModuleProtocol where Input: Sendable, Output: Sendable {
    var version: String { get }
    
    func execute(
        input: Input,
        context: PipelineContext
    ) async -> Result<Output, PipelineError>
}

/// Base module protocol
public protocol ModuleProtocol: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable
    
    var id: String { get }
    var name: String { get }
    var isEnabled: Bool { get set }
    
    func validate(input: Input) -> Bool
    func execute(input: Input) async throws -> Output
}

/// Pipeline execution context
public struct PipelineContext: Sendable {
    public let executionID: String
    public let projectID: String
    public let startTime: Date
    public let metadata: [String: String]
    public let progressCallback: (@Sendable (Double) -> Void)?
    
    public init(
        executionID: String = UUID().uuidString,
        projectID: String = "default",
        startTime: Date = Date(),
        metadata: [String: String] = [:],
        progressCallback: (@Sendable (Double) -> Void)? = nil
    ) {
        self.executionID = executionID
        self.projectID = projectID
        self.startTime = startTime
        self.metadata = metadata
        self.progressCallback = progressCallback
    }
}

/// Pipeline error types
public enum PipelineError: Error, Sendable {
    case invalidInput(String)
    case executionFailed(String)
    case timeout(Double)
    case dependencyUnavailable(String)
    case configurationError(String)
    case resourceUnavailable(String)
    case networkError(String)
    case apiError(String)
    case unknown(String)
    
    public var localizedDescription: String {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .executionFailed(let message):
            return "Execution failed: \(message)"
        case .timeout(let duration):
            return "Timeout after \(duration) seconds"
        case .dependencyUnavailable(let dependency):
            return "Dependency unavailable: \(dependency)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .resourceUnavailable(let resource):
            return "Resource unavailable: \(resource)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - AI Service Protocol

/// AI service protocol
public protocol AIServiceProtocol: Sendable {
    var isAvailable: Bool { get }
    
    func processText(prompt: String, systemPrompt: String?) async throws -> String
    func healthCheck() async -> Bool
}

/// Mock AI service for testing
public final class MockAIService: AIServiceProtocol, @unchecked Sendable {
    public init() {}
    
    public var isAvailable: Bool { true }
    
    public func processText(prompt: String, systemPrompt: String?) async throws -> String {
        return "Mock processed: \(prompt)"
    }
    
    public func healthCheck() async -> Bool {
        return true
    }
}

// MARK: - Telemetry

/// Centralized telemetry
public actor Telemetry {
    public static let shared = Telemetry()
    
    private var registeredModules: Set<String> = []
    private var eventLog: [TelemetryEvent] = []
    private var isEnabled: Bool = true
    
    private init() {}
    
    public func register(module: String) {
        registeredModules.insert(module)
    }
    
    public func isRegistered(for module: String) -> Bool {
        return registeredModules.contains(module)
    }
    
    public func logEvent(_ name: String, metadata: [String: String] = [:]) {
        guard isEnabled else { return }
        
        let event = TelemetryEvent(
            name: name,
            timestamp: Date(),
            metadata: metadata
        )
        
        eventLog.append(event)
        
        #if DEBUG
        print("[TELEMETRY] \(name) - \(metadata)")
        #endif
    }
    
    public func getRecentEvents(count: Int = 100) -> [TelemetryEvent] {
        return Array(eventLog.suffix(count))
    }
    
    public func clearLog() {
        eventLog.removeAll()
    }
    
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}

public struct TelemetryEvent: Sendable, Codable {
    public let name: String
    public let timestamp: Date
    public let metadata: [String: String]
    
    public init(name: String, timestamp: Date, metadata: [String: String]) {
        self.name = name
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

// MARK: - Enums

public enum SegmentPacing: String, Sendable, Codable {
    case fast = "Fast"
    case moderate = "Moderate"
    case slow = "Slow"
    case building = "Building"
}

public enum TransitionType: String, Sendable, Codable {
    case cut = "Cut"
    case fade = "Fade"
    case temporal = "Temporal"
    case spatial = "Spatial"
    case dialogue = "Dialogue"
    case hard = "Hard"
}

public enum VideoQuality: String, Codable, Sendable {
    case low, medium, high, ultra
    
    public var resolution: CGSize {
        switch self {
        case .low: return CGSize(width: 640, height: 480)
        case .medium: return CGSize(width: 1280, height: 720)
        case .high: return CGSize(width: 1920, height: 1080)
        case .ultra: return CGSize(width: 3840, height: 2160)
        }
    }
    
    public var bitrate: Int {
        switch self {
        case .low: return 500_000
        case .medium: return 2_000_000
        case .high: return 8_000_000
        case .ultra: return 25_000_000
        }
    }
}

public enum VideoFormat: String, Codable, Sendable {
    case mp4, mov, avi, webm
    
    public var fileExtension: String { rawValue }
}

public enum VideoStyle: String, Codable, Sendable, CaseIterable {
    case cinematic, documentary, animated, artistic
}

public enum RewordingStyle: String, Codable, Sendable {
    case formal, casual, poetic, concise, descriptive
}

// MARK: - Story Analysis Output

public struct StoryAnalysisOutput: Codable, Sendable {
    public let themes: [String]
    public let characters: [String]
    public let settings: [String]
    public let emotions: [String]
    public let keyMoments: [String]
    public let tone: String
    public let genre: String?
    
    public init(
        themes: [String] = [],
        characters: [String] = [],
        settings: [String] = [],
        emotions: [String] = [],
        keyMoments: [String] = [],
        tone: String = "neutral",
        genre: String? = nil
    ) {
        self.themes = themes
        self.characters = characters
        self.settings = settings
        self.emotions = emotions
        self.keyMoments = keyMoments
        self.tone = tone
        self.genre = genre
    }
}

// MARK: - Video Metadata

public struct VideoMetadata: Sendable, Codable {
    public let duration: TimeInterval
    public let frameRate: Double
    public let resolution: CGSize
    public let bitrate: Int
    
    public init(duration: TimeInterval, frameRate: Double, resolution: CGSize, bitrate: Int) {
        self.duration = duration
        self.frameRate = frameRate
        self.resolution = resolution
        self.bitrate = bitrate
    }
}

