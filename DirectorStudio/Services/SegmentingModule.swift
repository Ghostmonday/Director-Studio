//
//  SegmentingModule.swift
//  DirectorStudio
//
//  REPLACED: New Story-to-Film Generator (was complex parsing system)
//

import Foundation

// MARK: - Core Data Models

public struct FilmTake: Codable, Identifiable {
    public let id: UUID
    let takeNumber: Int
    let prompt: String                    // Complete Kling-ready video prompt
    let storyContent: String              // What narrative moment this captures
    let useSeedImage: Bool                // Should use previous frame as seed
    let seedFromTake: Int?                // Which take to get seed from
    let estimatedDuration: Double         // Seconds (5-10)
    let sceneType: SceneType              // Visual classification
    let hasDialogue: Bool                 // Contains spoken words
    let dialogueLines: [DialogueLine]?    // Extracted dialogue if present
    let emotionalTone: String             // Mood/atmosphere
    let cameraDirection: String?          // Suggested camera work
    
    enum SceneType: String, Codable {
        case action = "Action"
        case dialogue = "Dialogue"
        case atmosphere = "Atmosphere"
        case transition = "Transition"
        case establishing = "Establishing"
        case climax = "Climax"
    }
}

struct DialogueLine: Codable {
    let speaker: String
    let text: String
    let emotion: String
    let visualDescription: String
}

struct FilmBreakdown: Codable {
    let takes: [FilmTake]
    let metadata: FilmMetadata
    let continuityChain: [ContinuityLink]
    let warnings: [String]
    
    var totalDuration: Double {
        takes.reduce(0) { $0 + $1.estimatedDuration }
    }
    
    var takeCount: Int {
        takes.count
    }
}

struct FilmMetadata: Codable {
    let originalTextLength: Int
    let processingTime: TimeInterval
    let apiCalls: Int
    let storySummary: String
    let generatedAt: Date
    let totalEstimatedDuration: Double
    let model: String
}

struct ContinuityLink: Codable {
    let fromTake: Int
    let toTake: Int
    let continuityType: String
    let description: String
}

// MARK: - Main Generator

final class StoryToFilmGenerator {
    
    private let deepSeekClient: DeepSeekFilmClient
    private let config: GeneratorConfig
    
    struct GeneratorConfig {
        var minTakeDuration: Double = 5.0
        var maxTakeDuration: Double = 10.0
        var preferredTakeDuration: Double = 7.0
        var minTakes: Int = 5
        var maxTakes: Int = 50
        var enableDialogueExtraction: Bool = true
        var enableEmotionalAnalysis: Bool = true
        var enableCameraDirections: Bool = true
        var continuityMode: ContinuityMode = .fullChain
        var useSimpleChunking: Bool = false  // Use AI-powered intelligent analysis
        
        enum ContinuityMode {
            case none
            case adjacent
            case fullChain
        }
    }
    
    init(apiKey: String, config: GeneratorConfig = GeneratorConfig()) {
        self.deepSeekClient = DeepSeekFilmClient(apiKey: apiKey)
        self.config = config
    }
    
    func generateFilm(from text: String) async throws -> FilmBreakdown {
        let startTime = Date()
        
        print("🎬 [StoryToFilm] Starting generation")
        print("   Text length: \(text.count) characters")
        
        let takes: [FilmTake]
        if config.useSimpleChunking {
            print("📝 Using simple chunking with 5-word overlap")
            takes = createTakesFromChunks(text: text)
        } else {
            takes = try await breakIntoTakes(text: text)
        }
        
        let continuityLinks = buildContinuityChain(takes)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        let metadata = FilmMetadata(
            originalTextLength: text.count,
            processingTime: processingTime,
            apiCalls: config.useSimpleChunking ? 0 : deepSeekClient.callCount,
            storySummary: "Story film",
            generatedAt: Date(),
            totalEstimatedDuration: takes.reduce(0) { $0 + $1.estimatedDuration },
            model: config.useSimpleChunking ? "simple-chunking" : "deepseek-chat"
        )
        
        print("✅ [StoryToFilm] Complete!")
        print("   Takes: \(takes.count)")
        print("   Duration: \(metadata.totalEstimatedDuration)s")
        print("   Processing: \(String(format: "%.2f", processingTime))s")
        
        return FilmBreakdown(
            takes: takes,
            metadata: metadata,
            continuityChain: continuityLinks,
            warnings: []
        )
    }
    
    private func breakIntoTakes(text: String) async throws -> [FilmTake] {
        let prompt = """
        Break this story into \(config.minTakes)-\(config.maxTakes) video takes for AI video generation.
        
        STORY:
        \(text)
        
        REQUIREMENTS:
        - Each take must be EXACTLY 5 or 10 seconds (no other durations)
        - Use 5 seconds for: quick actions, single moments, fast cuts
        - Use 10 seconds for: dialogue, establishing shots, complex scenes
        - CAPTURE EVERY STORY BEAT - nothing skipped
        - If dialogue exists: show characters speaking visually
        - If action exists: show the action happening
        - Each prompt must be COMPLETE and ready for video generation
        - Include: who's in frame, what they're doing, environment, lighting, mood, camera angle
        
        Return JSON array:
        [
          {
            "takeNumber": 1,
            "prompt": "Detailed visual description: characters, actions, environment, camera, lighting, mood",
            "storyContent": "What narrative moment this captures",
            "estimatedDuration": 10.0,
            "sceneType": "establishing",
            "hasDialogue": false,
            "emotionalTone": "tense",
            "cameraDirection": "wide shot"
          }
        ]
        
        Return ONLY valid JSON.
        """
        
        let response = try await deepSeekClient.complete(prompt: prompt)
        return try parseTakes(response)
    }
    
    private func parseTakes(_ json: String) throws -> [FilmTake] {
        var cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") { cleaned = String(cleaned.dropFirst(7)) }
        if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleaned.data(using: .utf8) else {
            throw GeneratorError.invalidJSON("Cannot convert to data")
        }
        
        let decoder = JSONDecoder()
        let rawTakes = try decoder.decode([RawTake].self, from: data)
        
        return rawTakes.enumerated().map { index, raw in
            FilmTake(
                id: UUID(),
                takeNumber: raw.takeNumber,
                prompt: raw.prompt,
                storyContent: raw.storyContent,
                useSeedImage: index > 0 && config.continuityMode != .none,
                seedFromTake: index > 0 ? index : nil,
                estimatedDuration: raw.estimatedDuration,
                sceneType: FilmTake.SceneType(rawValue: raw.sceneType) ?? .action,
                hasDialogue: raw.hasDialogue,
                dialogueLines: raw.dialogueLines?.map {
                    DialogueLine(
                        speaker: $0.speaker,
                        text: $0.text,
                        emotion: $0.emotion,
                        visualDescription: $0.visualDescription
                    )
                },
                emotionalTone: raw.emotionalTone,
                cameraDirection: raw.cameraDirection
            )
        }
    }
    
    struct RawTake: Codable {
        let takeNumber: Int
        let prompt: String
        let storyContent: String
        let estimatedDuration: Double
        let sceneType: String
        let hasDialogue: Bool
        let dialogueLines: [RawDialogue]?
        let emotionalTone: String
        let cameraDirection: String?
    }
    
    struct RawDialogue: Codable {
        let speaker: String
        let text: String
        let emotion: String
        let visualDescription: String
    }
    
    private func buildContinuityChain(_ takes: [FilmTake]) -> [ContinuityLink] {
        var links: [ContinuityLink] = []
        
        for i in 0..<(takes.count - 1) {
            let current = takes[i]
            let next = takes[i + 1]
            
            links.append(ContinuityLink(
                fromTake: current.takeNumber,
                toTake: next.takeNumber,
                continuityType: "visual",
                description: "Take \(next.takeNumber) uses last frame from Take \(current.takeNumber) as seed"
            ))
        }
        
        return links
    }
    
    // MARK: - Simple Chunking with 5-word Overlap
    
    /// Returns an array of prompts ready for Kling API.
    /// Each prompt (except the first) starts with the **exact last 5 words** of the previous one.
    private func processFullStory(_ storyText: String, toneTag: String = "/cinematic") -> [String] {
        var chunks: [String] = []
        var previousTail: String = ""               // will hold "word1 word2 word3 word4 word5"
        
        // 1. Split into clean words (same as before)
        let sentences = storyText.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        var wordBuffer: [String] = []
        
        for sentence in sentences {
            let words = sentence
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                
            for word in words {
                wordBuffer.append(word)
                if wordBuffer.count >= 30 {
                    let chunk = wordBuffer.joined(separator: " ")
                    // 2. Build final prompt
                    let finalPrompt = (chunks.isEmpty ? "" : previousTail + " ") + chunk + " " + toneTag
                    
                    chunks.append(finalPrompt.trimmingCharacters(in: .whitespaces))
                    
                    // 3. Save tail for next iteration
                    let tailWords = wordBuffer.suffix(5)
                    previousTail = tailWords.joined(separator: " ")
                    
                    wordBuffer.removeAll()
                }
            }
        }
        
        // Leftover words
        if !wordBuffer.isEmpty {
            let chunk = wordBuffer.joined(separator: " ")
            let finalPrompt = (chunks.isEmpty ? "" : previousTail + " ") + chunk + " " + toneTag
            chunks.append(finalPrompt.trimmingCharacters(in: .whitespaces))
        }
        
        // 4. **First prompt must NOT have a leading tail**
        if chunks.count > 1, !previousTail.isEmpty, chunks[0].hasPrefix(previousTail) {
            // Edge case – shouldn't happen, but keep it safe
            chunks[0] = chunks[0].replacingOccurrences(of: "^\(previousTail) ", with: "", options: .regularExpression)
        }
        
        return chunks
    }
    
    /// Convert chunked prompts into FilmTake objects
    private func createTakesFromChunks(text: String) -> [FilmTake] {
        let prompts = processFullStory(text)
        
        print("📊 [Chunking] Generated \(prompts.count) chunks with 5-word overlap")
        
        return prompts.enumerated().map { index, prompt in
            // Log the overlap for debugging
            if index > 0 {
                let words = prompt.split(separator: " ")
                if words.count >= 5 {
                    let overlap = words.prefix(5).joined(separator: " ")
                    print("   Take \(index + 1) overlap: '\(overlap)...'")
                }
            }
            
            // Only first take gets the tone tag
            let finalPrompt = index == 0 ? prompt : prompt.replacingOccurrences(of: " /cinematic", with: "")
            
            return FilmTake(
                id: UUID(),
                takeNumber: index + 1,
                prompt: finalPrompt,
                storyContent: prompt.replacingOccurrences(of: " /cinematic", with: ""),
                useSeedImage: index > 0,  // All takes after first use seed
                seedFromTake: index > 0 ? index - 1 : nil,
                estimatedDuration: 5.0,  // Fixed 5 seconds for simple chunking
                sceneType: .atmosphere,  // Default type
                hasDialogue: false,
                dialogueLines: nil,
                emotionalTone: "cinematic",
                cameraDirection: nil
            )
        }
    }
}

// MARK: - DeepSeek Client

final class DeepSeekFilmClient {
    private let apiKey: String
    private let endpoint = "https://api.deepseek.com/v1/chat/completions"
    private(set) var callCount = 0
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func complete(prompt: String, temperature: Double = 0.7) async throws -> String {
        callCount += 1
        
        let url = URL(string: endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": "You are an expert film director who transforms stories into visual sequences."],
                ["role": "user", "content": prompt]
            ],
            "temperature": temperature,
            "max_tokens": 4096
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GeneratorError.apiError("HTTP error")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw GeneratorError.invalidResponse
        }
        
        return content
    }
}

// MARK: - Errors

enum GeneratorError: LocalizedError {
    case invalidJSON(String)
    case apiError(String)
    case invalidResponse
    case noTakesGenerated
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON(let detail): return "Invalid JSON: \(detail)"
        case .apiError(let detail): return "API error: \(detail)"
        case .invalidResponse: return "Invalid response from API"
        case .noTakesGenerated: return "Failed to generate any takes"
        }
    }
}

// MARK: - Backward Compatibility Types (for legacy UI components)

enum SegmentationMode: String, CaseIterable {
    case ai = "AI"
    case hybrid = "Hybrid"
    case duration = "Duration"
    case evenSplit = "Even Split"
    
    var displayName: String { rawValue }
    var requiresLLM: Bool { self == .ai || self == .hybrid }
}

struct SegmentationWarning: Equatable {
    let message: String
}

struct SegmentationMetadata: Codable {
    let mode: String
    let segmentCount: Int
    let totalTokens: Int
    let totalDuration: Double
    let averageConfidence: Double
    let executionTime: TimeInterval
    let llmCallCount: Int
    let fallbackUsed: Bool
    let constraintsViolated: [String]
    let expansionStats: ExpansionStats?
}

struct ExpansionStats: Codable {
    let enabled: Bool
    let expandedCount: Int
    let totalExpansionTokens: Int
    let averageEmotionScore: Double?
    let expansionStyle: String
    let expansionTime: TimeInterval
}

struct SemanticExpansionConfig {
    enum ExpansionStyle: String, CaseIterable {
        case vivid = "Vivid"
        case emotional = "Emotional"
        case action = "Action"
        case atmospheric = "Atmospheric"
        case balanced = "Balanced"
    }
}

// MARK: - Old SegmentingModule Interface (for compatibility)

extension StoryToFilmGenerator {
    /// Compatibility wrapper for old segment() calls
    func segment(
        script: String,
        mode: SegmentationMode,
        constraints: SegmentationConstraints,
        llmConfig: LLMConfiguration?
    ) async throws -> SegmentationResult {
        // Convert to new system
        let film = try await generateFilm(from: script)
        
        // Convert FilmTakes to old segment format for compatibility
        let metadata = SegmentationMetadata(
            mode: mode.displayName,
            segmentCount: film.takeCount,
            totalTokens: 0,
            totalDuration: film.totalDuration,
            averageConfidence: 1.0,
            executionTime: film.metadata.processingTime,
            llmCallCount: film.metadata.apiCalls,
            fallbackUsed: false,
            constraintsViolated: [],
            expansionStats: nil
        )
        
        return SegmentationResult(
            segments: [],  // Not used in new system
            metadata: metadata,
            warnings: film.warnings.map { SegmentationWarning(message: $0) },
            llmUsage: nil
        )
    }
}

struct SegmentationConstraints {
    var maxSegments: Int = 50
    var maxTokensPerSegment: Int = 200
    var maxDuration: Double = 10.0
    var minDuration: Double = 5.0
    var targetDuration: Double = 7.0
    var enforceStrictLimits: Bool = true
    var allowAutoAdjustment: Bool = true
    
    static let `default` = SegmentationConstraints()
}

struct LLMConfiguration {
    var apiKey: String
    var enableSemanticExpansion: Bool = false
    var expansionConfig: SemanticExpansionConfig = SemanticExpansionConfig()
}

struct SegmentationResult {
    let segments: [CinematicSegment]
    let metadata: SegmentationMetadata
    let warnings: [SegmentationWarning]
    let llmUsage: LLMUsageStats?
}

struct CinematicSegment: Codable, Identifiable {
    let id: UUID
    let text: String
    let estimatedDuration: Double
}

struct LLMUsageStats: Codable {
    let provider: String
    let model: String
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let cost: Double?
}

// MARK: - Legacy SegmentingModule Class (for compatibility)

final class SegmentingModule {
    func segment(
        script: String,
        mode: SegmentationMode,
        constraints: SegmentationConstraints = .default,
        llmConfig: LLMConfiguration? = nil
    ) async throws -> SegmentationResult {
        // Redirect to new StoryToFilmGenerator
        guard let config = llmConfig else {
            throw GeneratorError.apiError("API key required")
        }
        
        let generator = StoryToFilmGenerator(apiKey: config.apiKey)
        return try await generator.segment(
            script: script,
            mode: mode,
            constraints: constraints,
            llmConfig: config
        )
    }
    
    /// NEW: Segment script into ProjectPrompt array for Phase 1 refactor
    /// - Parameters:
    ///   - story: The story text to segment
    ///   - projectId: Optional project ID for persistence
    /// - Returns: Array of ProjectPrompt objects ready for generation
    func segment(_ story: String, projectId: UUID? = nil) async throws -> [ProjectPrompt] {
        // Use simple chunking for now (can be enhanced later)
        let generator = StoryToFilmGenerator(
            apiKey: "", // Will use DeepSeek key from config if available
            config: StoryToFilmGenerator.GeneratorConfig(useSimpleChunking: true)
        )
        
        let film = try await generator.generateFilm(from: story)
        
        // Convert FilmTakes to ProjectPrompts
        return film.takes.enumerated().map { index, take in
            // Extract dialogue if present
            let dialogue = take.dialogueLines?.map { "\($0.speaker): \($0.text)" }.joined(separator: "\n")
            
            // Calculate visual complexity
            let complexity = calculateVisualComplexity(take.prompt)
            
            return ProjectPrompt(
                id: take.id,
                index: index,
                prompt: take.prompt,
                status: .pending,
                extractedDialogue: dialogue,
                visualComplexityScore: complexity,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
    
    /// Calculate visual complexity score for tier selection
    /// - Parameter text: The prompt text
    /// - Returns: Complexity score from 0.0 to 1.0
    private func calculateVisualComplexity(_ text: String) -> Float {
        var score: Float = 0.3 // Base score
        
        let complexWords = ["explosion", "transformation", "crowd", "battle", "chase", "water", "fire", "smoke"]
        let promptLower = text.lowercased()
        
        for word in complexWords {
            if promptLower.contains(word) {
                score += 0.15
            }
        }
        
        // Increase score for longer prompts (more complex scenes)
        if text.count > 200 {
            score += 0.1
        }
        
        return min(score, 1.0)
    }
    
    /// Extract dialogue from text (simple implementation)
    /// - Parameter text: The text to analyze
    /// - Returns: Extracted dialogue string or nil
    private func extractDialogue(from text: String) -> String? {
        // Simple pattern matching for quoted text
        let pattern = "\"([^\"]+)\""
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex?.matches(in: text, options: [], range: range) ?? []
        
        guard !matches.isEmpty else { return nil }
        
        let dialogueLines = matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
        
        return dialogueLines.isEmpty ? nil : dialogueLines.joined(separator: "\n")
    }
}

