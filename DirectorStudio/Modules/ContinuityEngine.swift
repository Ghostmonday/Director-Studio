//
//  ContinuityEngine.swift
//  DirectorStudio
//
//  MODULE: ContinuityEngine
//  VERSION: 2.0.0
//  PURPOSE: Detects continuity violations across video segments (Analysis only)
//

import Foundation
import NaturalLanguage

// MARK: - Continuity Engine (Analysis Only)

/// Analyzes and detects continuity violations across segments
/// Returns issues WITHOUT modifying prompts (Injector handles fixes)
public struct ContinuityEngine: PipelineModule {
    public typealias Input = ContinuityEngineInput
    public typealias Output = ContinuityEngineOutput
    
    public let id = "continuity-engine"
    public let name = "Continuity Engine"
    public let version = "2.0.0"
    public var isEnabled: Bool = true
    
    private let logger = Loggers.continuity
    private let storage: ContinuityStorageProtocol
    
    public init(storage: ContinuityStorageProtocol = InMemoryContinuityStorage()) {
        self.storage = storage
    }
    
    public func execute(input: ContinuityEngineInput) async throws -> ContinuityEngineOutput {
        let context = PipelineContext()
        let result = await execute(input: input, context: context)
        switch result {
        case .success(let output):
            return output
        case .failure(let error):
            throw error
        }
    }
    
    public func execute(
        input: ContinuityEngineInput,
        context: PipelineContext
    ) async -> Result<ContinuityEngineOutput, PipelineError> {
        logger.info("🔍 Continuity Engine analyzing \(input.segments.count) segments")
        
        await Telemetry.shared.logEvent(
            "ContinuityEngineStarted",
            metadata: ["segmentCount": "\(input.segments.count)"]
        )
        
        let startTime = Date()
        var continuityIssues: [ContinuityIssue] = []
        var sceneStates: [SceneState] = []
        var overallConfidence: Double = 1.0
        
        // Load previous telemetry
        let manifestationScores = try? await storage.loadManifestationScores()
        var previousState: SceneState? = nil
        
        // Analyze each segment
        for (index, segment) in input.segments.enumerated() {
            let sceneState = extractSceneState(from: segment, index: index)
            sceneStates.append(sceneState)
            
            // Validate against previous state
            let validation = validateScene(
                current: sceneState,
                previous: previousState,
                manifestationScores: manifestationScores ?? [:]
            )
            
            // Log issues
            if !validation.issues.isEmpty {
                let issue = ContinuityIssue(
                    segmentIndex: index,
                    confidence: validation.confidence,
                    issues: validation.issues,
                    severity: validation.confidence < 0.6 ? .critical : .warning,
                    sceneState: sceneState,
                    previousState: previousState
                )
                continuityIssues.append(issue)
                
                logger.warning("⚠️ Segment \(index + 1): confidence=\(String(format: "%.2f", validation.confidence)), issues=\(validation.issues.count)")
                for issueDesc in validation.issues {
                    logger.debug("   - \(issueDesc)")
                }
            }
            
            // Update overall confidence (multiplicative)
            overallConfidence *= validation.confidence
            
            // Update for next iteration
            previousState = sceneState
        }
        
        // Generate continuity anchors
        let anchors = generateContinuityAnchors(from: input.segments)
        
        let executionTime = Date().timeIntervalSince(startTime)
        
        let output = ContinuityEngineOutput(
            sceneStates: sceneStates,
            continuityIssues: continuityIssues,
            continuityAnchors: anchors,
            overallConfidence: overallConfidence,
            requiresHumanReview: overallConfidence < 0.6,
            manifestationScores: manifestationScores ?? [:]
        )
        
        logger.info("✅ Continuity analysis completed in \(String(format: "%.2f", executionTime))s")
        logger.info("📊 Overall confidence: \(String(format: "%.2f%%", overallConfidence * 100))")
        logger.info("🔍 Found \(continuityIssues.count) potential issues")
        
        if output.requiresHumanReview {
            logger.warning("⚠️ Human review recommended - confidence below threshold")
        }
        
        await Telemetry.shared.logEvent(
            "ContinuityEngineCompleted",
            metadata: [
                "duration": String(format: "%.2f", executionTime),
                "issuesFound": "\(continuityIssues.count)",
                "confidence": String(format: "%.2f", overallConfidence)
            ]
        )
        
        return .success(output)
    }
    
    public func validate(input: ContinuityEngineInput) -> Bool {
        return !input.segments.isEmpty
    }
    
    // MARK: - Scene State Extraction
    
    private func extractSceneState(from segment: PromptSegment, index: Int) -> SceneState {
        let text = segment.content.lowercased()
        
        // Extract location
        var location = "Unknown"
        let locationPatterns = ["in the", "at the", "inside", "outside", "at a"]
        for pattern in locationPatterns {
            if let range = text.range(of: pattern) {
                let afterPattern = String(text[range.upperBound...])
                location = afterPattern.prefix(while: { !$0.isWhitespace }).description
                break
            }
        }
        
        // Extract characters (simple name detection)
        var characters: [String] = []
        let namePatterns = ["\\b[A-Z][a-z]+\\b"]
        for pattern in namePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(location: 0, length: segment.content.utf16.count)
                let matches = regex.matches(in: segment.content, range: range)
                for match in matches {
                    if let range = Range(match.range, in: segment.content) {
                        let name = String(segment.content[range])
                        if !characters.contains(name) && name.count > 2 {
                            characters.append(name)
                        }
                    }
                }
            }
        }
        
        // Extract props
        var props: [String] = []
        let propPatterns = ["door", "window", "table", "chair", "car", "phone", "book", "key", "light"]
        for pattern in propPatterns {
            if text.contains(pattern) {
                props.append(pattern.capitalized)
            }
        }
        
        // Determine tone
        let tone = determineTone(text)
        
        return SceneState(
            id: index,
            location: location,
            characters: characters,
            props: props,
            prompt: segment.content,
            tone: tone
        )
    }
    
    // MARK: - Validation Rules
    
    private func validateScene(
        current: SceneState,
        previous: SceneState?,
        manifestationScores: [String: ManifestationScore]
    ) -> ValidationResult {
        
        guard let prev = previous else {
            // First scene - nothing to validate against
            return ValidationResult(confidence: 1.0, issues: [])
        }
        
        var confidence = 1.0
        var issues: [String] = []
        
        // Rule 1: Prop persistence
        for prop in prev.props where !current.props.contains(prop) {
            confidence *= 0.7
            issues.append("❌ \(prop) disappeared (was in scene \(prev.id + 1))")
        }
        
        // Rule 2: Character location logic
        if prev.location == current.location {
            for char in prev.characters where !current.characters.contains(char) {
                confidence *= 0.5
                issues.append("❌ \(char) vanished from \(current.location)")
            }
        }
        
        // Rule 3: Tone whiplash detection
        let toneDistance = calculateToneDistance(prev.tone, current.tone)
        if toneDistance > 0.8 {
            confidence *= 0.6
            issues.append("⚠️ Tone jumped: \(prev.tone) → \(current.tone)")
        }
        
        // Rule 4: Manifestation score check
        for prop in current.props {
            if let score = manifestationScores[prop.lowercased()],
               score.manifestationRate < 0.3 {
                confidence *= 0.9
                issues.append("⚠️ \(prop) has low manifestation rate (\(String(format: "%.0f%%", score.manifestationRate * 100)))")
            }
        }
        
        return ValidationResult(confidence: confidence, issues: issues)
    }
    
    // MARK: - Continuity Anchors
    
    private func generateContinuityAnchors(from segments: [PromptSegment]) -> [ContinuityAnchor] {
        var anchors: [ContinuityAnchor] = []
        var characterMap: [String: Set<String>] = [:]
        
        // Collect all character descriptions
        for (index, segment) in segments.enumerated() {
            let state = extractSceneState(from: segment, index: index)
            
            for character in state.characters {
                if characterMap[character] == nil {
                    characterMap[character] = []
                }
                characterMap[character]?.insert(segment.content)
            }
        }
        
        // Create anchors for each character
        for (character, descriptions) in characterMap {
            let anchor = ContinuityAnchor(
                anchorType: "Character",
                description: "\(character): \(descriptions.joined(separator: " | "))",
                segmentIndex: 0
            )
            anchors.append(anchor)
        }
        
        return anchors
    }
    
    // MARK: - Helper Methods
    
    private func determineTone(_ text: String) -> String {
        let toneKeywords: [String: String] = [
            "dark": "Dark",
            "scary": "Dark",
            "tense": "Tense",
            "peaceful": "Calm",
            "happy": "Joyful",
            "sad": "Melancholic",
            "exciting": "Exciting",
            "mysterious": "Mysterious"
        ]
        
        for (keyword, tone) in toneKeywords {
            if text.contains(keyword) {
                return tone
            }
        }
        
        return "Neutral"
    }
    
    private func calculateToneDistance(_ tone1: String, _ tone2: String) -> Double {
        func sentiment(_ s: String) -> Double {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count >= 2 else { return 0 }
            
            let tagger = NLTagger(tagSchemes: [.sentimentScore])
            tagger.string = trimmed
            var score: Double = 0
            
            let range = trimmed.startIndex..<trimmed.endIndex
            tagger.enumerateTags(in: range, unit: .paragraph, scheme: .sentimentScore) { tag, _ in
                if let raw = tag?.rawValue, let val = Double(raw) {
                    score = val
                } else {
                    score = 0
                }
                return false
            }
            
            return score
        }
        
        return abs(sentiment(tone1) - sentiment(tone2))
    }
}

// MARK: - Supporting Types

public struct ContinuityEngineInput: Sendable {
    public let segments: [PromptSegment]
    public let projectID: String
    
    public init(segments: [PromptSegment], projectID: String = "") {
        self.segments = segments
        self.projectID = projectID
    }
}

public struct ContinuityEngineOutput: Sendable {
    public let sceneStates: [SceneState]
    public let continuityIssues: [ContinuityIssue]
    public let continuityAnchors: [ContinuityAnchor]
    public let overallConfidence: Double
    public let requiresHumanReview: Bool
    public let manifestationScores: [String: ManifestationScore]
    
    public init(
        sceneStates: [SceneState],
        continuityIssues: [ContinuityIssue],
        continuityAnchors: [ContinuityAnchor],
        overallConfidence: Double,
        requiresHumanReview: Bool,
        manifestationScores: [String: ManifestationScore]
    ) {
        self.sceneStates = sceneStates
        self.continuityIssues = continuityIssues
        self.continuityAnchors = continuityAnchors
        self.overallConfidence = overallConfidence
        self.requiresHumanReview = requiresHumanReview
        self.manifestationScores = manifestationScores
    }
}

public struct ContinuityIssue: Sendable, Codable {
    public let segmentIndex: Int
    public let confidence: Double
    public let issues: [String]
    public let severity: Severity
    public let sceneState: SceneState
    public let previousState: SceneState?
    
    public enum Severity: String, Codable, Sendable {
        case warning = "Warning"
        case critical = "Critical"
    }
    
    public init(
        segmentIndex: Int,
        confidence: Double,
        issues: [String],
        severity: Severity,
        sceneState: SceneState,
        previousState: SceneState?
    ) {
        self.segmentIndex = segmentIndex
        self.confidence = confidence
        self.issues = issues
        self.severity = severity
        self.sceneState = sceneState
        self.previousState = previousState
    }
}

public struct SceneState: Sendable, Codable {
    public let id: Int
    public let location: String
    public let characters: [String]
    public let props: [String]
    public let prompt: String
    public let tone: String
    
    public init(id: Int, location: String, characters: [String], props: [String], prompt: String, tone: String) {
        self.id = id
        self.location = location
        self.characters = characters
        self.props = props
        self.prompt = prompt
        self.tone = tone
    }
}

private struct ValidationResult {
    let confidence: Double
    let issues: [String]
}

public struct ManifestationScore: Sendable, Codable {
    public let word: String
    public let manifestationRate: Double
    public let totalOccurrences: Int
    
    public init(word: String, manifestationRate: Double, totalOccurrences: Int) {
        self.word = word
        self.manifestationRate = manifestationRate
        self.totalOccurrences = totalOccurrences
    }
}

// MARK: - Storage Protocol

public protocol ContinuityStorageProtocol: Sendable {
    func saveState(_ state: SceneState) async throws
    func loadState() async throws -> SceneState?
    func saveTelemetry(_ word: String, appeared: Bool) async throws
    func loadManifestationScores() async throws -> [String: ManifestationScore]
}

public final class InMemoryContinuityStorage: ContinuityStorageProtocol, @unchecked Sendable {
    private var currentState: SceneState?
    private var telemetry: [String: (appeared: Int, total: Int)] = [:]
    
    public init() {}
    
    public func saveState(_ state: SceneState) async throws {
        currentState = state
    }
    
    public func loadState() async throws -> SceneState? {
        return currentState
    }
    
    public func saveTelemetry(_ word: String, appeared: Bool) async throws {
        let key = word.lowercased()
        let current = telemetry[key] ?? (appeared: 0, total: 0)
        telemetry[key] = (
            appeared: current.appeared + (appeared ? 1 : 0),
            total: current.total + 1
        )
    }
    
    public func loadManifestationScores() async throws -> [String: ManifestationScore] {
        var scores: [String: ManifestationScore] = [:]
        for (word, data) in telemetry {
            let rate = data.total > 0 ? Double(data.appeared) / Double(data.total) : 1.0
            scores[word] = ManifestationScore(
                word: word,
                manifestationRate: rate,
                totalOccurrences: data.total
            )
        }
        return scores
    }
}

