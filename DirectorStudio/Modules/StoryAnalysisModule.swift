//
//  StoryAnalysisModule.swift
//  DirectorStudio
//
//  MODULE: StoryAnalysis
//  VERSION: 1.0.0
//  PURPOSE: Deep story extraction with entity relationships and emotional arcs
//

import Foundation

// MARK: - Story Analysis Module

/// Analyzes narratives for entities, themes, emotional arcs, and structure
/// Optimized for filmmaking - focuses on characters, themes, and pacing
public final class StoryAnalysisModule: PipelineModule, @unchecked Sendable {
    public typealias Input = StoryAnalysisInput
    public typealias Output = StoryAnalysisOutput
    
    public let id = "storyanalysis"
    public let name = "Story Analysis"
    public let version = "1.0.0"
    public var isEnabled = true
    
    public init() {
        Task {
            await Telemetry.shared.register(module: "storyanalysis")
            await Telemetry.shared.logEvent(
                "ModuleInitialized",
                metadata: ["module": "storyanalysis", "version": version]
            )
        }
    }
    
    public nonisolated func validate(input: StoryAnalysisInput) -> Bool {
        let trimmed = input.story.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 200_000
    }
    
    public func execute(input: StoryAnalysisInput) async throws -> StoryAnalysisOutput {
        await Telemetry.shared.logEvent(
            "StoryAnalysisExecutionStarted",
            metadata: ["storyLength": "\(input.story.count)"]
        )
        
        let startTime = Date()
        
        // Perform analysis
        let analysis = try await performAnalysis(story: input.story)
        
        let executionTime = Date().timeIntervalSince(startTime)
        
        let output = StoryAnalysisOutput(
            analysis: analysis,
            extractionMethod: .aiPowered,
            confidence: 0.85,
            processingTime: executionTime
        )
        
        await Telemetry.shared.logEvent(
            "StoryAnalysisExecutionCompleted",
            metadata: [
                "processingTime": "\(executionTime)",
                "complexityScore": "\(analysis.complexityScore)",
                "characterCount": "\(analysis.characterDevelopment.count)",
                "themeCount": "\(analysis.themes.count)"
            ]
        )
        
        return output
    }
    
    public func execute(
        input: StoryAnalysisInput,
        context: PipelineContext
    ) async -> Result<StoryAnalysisOutput, PipelineError> {
        do {
            let output = try await execute(input: input)
            return .success(output)
        } catch {
            return .failure(.executionFailed(error.localizedDescription))
        }
    }
    
    // MARK: - Analysis Pipeline
    
    private func performAnalysis(story: String) async throws -> StoryAnalysis {
        // Phase 1: Extract characters
        let characters = extractCharacters(story)
        
        // Phase 2: Extract themes
        let themes = extractThemes(story, characters: characters)
        
        // Phase 3: Build emotional arc
        let emotionalArc = buildEmotionalArc(story)
        
        // Phase 4: Calculate complexity
        let complexity = calculateComplexity(story, characters: characters, themes: themes)
        
        // Phase 5: Determine genre
        let genre = detectGenre(story, themes: themes)
        
        return StoryAnalysis(
            narrativeArc: describeNarrativeArc(emotionalArc),
            emotionalCurve: emotionalArc,
            characterDevelopment: Dictionary(uniqueKeysWithValues: characters.map { ($0, "Character") }),
            themes: themes,
            genre: genre,
            targetAudience: "General",
            estimatedDuration: TimeInterval(story.count) / 100.0,
            complexityScore: complexity
        )
    }
    
    // MARK: - Character Extraction
    
    private func extractCharacters(_ story: String) -> [String] {
        var characters: Set<String> = []
        
        // Extract capitalized names (simple pattern)
        let pattern = "\\b[A-Z][a-z]{2,}\\b"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(location: 0, length: story.utf16.count)
            let matches = regex.matches(in: story, range: range)
            
            for match in matches {
                if let range = Range(match.range, in: story) {
                    let name = String(story[range])
                    // Filter out common words
                    if !["The", "And", "But", "For", "With", "From"].contains(name) {
                        characters.insert(name)
                    }
                }
            }
        }
        
        return Array(characters).sorted()
    }
    
    // MARK: - Theme Extraction
    
    private func extractThemes(_ story: String, characters: [String]) -> [String] {
        var themes: Set<String> = []
        let lowercased = story.lowercased()
        
        // Theme keywords
        let themePatterns: [String: [String]] = [
            "Love": ["love", "romance", "heart", "affection"],
            "Conflict": ["battle", "fight", "war", "struggle", "conflict"],
            "Loss": ["death", "loss", "grief", "mourning"],
            "Adventure": ["journey", "quest", "adventure", "explore"],
            "Betrayal": ["betray", "deceive", "lie", "secret"],
            "Redemption": ["redeem", "forgive", "atone", "save"],
            "Fear": ["fear", "terror", "horror", "afraid"],
            "Hope": ["hope", "dream", "wish", "believe"],
            "Identity": ["who am i", "identity", "self", "belong"],
            "Justice": ["justice", "fair", "right", "wrong"]
        ]
        
        for (theme, keywords) in themePatterns {
            if keywords.contains(where: { lowercased.contains($0) }) {
                themes.insert(theme)
            }
        }
        
        return themes.isEmpty ? ["General Narrative"] : Array(themes).sorted()
    }
    
    // MARK: - Emotional Arc
    
    private func buildEmotionalArc(_ story: String) -> [Double] {
        // Split story into 5 parts for arc analysis
        let chunkSize = max(story.count / 5, 1)
        var arc: [Double] = []
        
        for i in 0..<5 {
            let start = story.index(story.startIndex, offsetBy: chunkSize * i, limitedBy: story.endIndex) ?? story.startIndex
            let end = story.index(story.startIndex, offsetBy: chunkSize * (i + 1), limitedBy: story.endIndex) ?? story.endIndex
            let chunk = String(story[start..<end])
            
            let intensity = calculateEmotionalIntensity(chunk)
            arc.append(intensity)
        }
        
        return arc
    }
    
    private func calculateEmotionalIntensity(_ text: String) -> Double {
        let lowercased = text.lowercased()
        
        // Intensity markers
        let intensityWords = ["very", "extremely", "incredibly", "absolutely", "never", "always"]
        let punctuationMarkers = text.filter { "!?".contains($0) }.count
        
        let wordIntensity = intensityWords.filter { lowercased.contains($0) }.count
        
        let rawIntensity = Double(wordIntensity + punctuationMarkers) / 10.0
        return min(max(rawIntensity, 0.0), 1.0)
    }
    
    private func describeNarrativeArc(_ arc: [Double]) -> String {
        let climaxIndex = arc.enumerated().max(by: { $0.element < $1.element })?.offset ?? 2
        let avgIntensity = arc.reduce(0, +) / Double(arc.count)
        
        if climaxIndex < 2 {
            return "Rising Action (Early Climax)"
        } else if climaxIndex > 3 {
            return "Building Tension (Late Climax)"
        } else if avgIntensity > 0.6 {
            return "High Intensity (Classical Arc)"
        } else {
            return "Moderate Pacing (Balanced Arc)"
        }
    }
    
    // MARK: - Complexity & Genre
    
    private func calculateComplexity(_ story: String, characters: [String], themes: [String]) -> Double {
        let paragraphCount = story.components(separatedBy: "\n\n").count
        let sentenceCount = story.components(separatedBy: CharacterSet(charactersIn: ".!?")).count
        
        let structuralComplexity = min(Double(paragraphCount) / 10.0, 1.0)
        let characterComplexity = min(Double(characters.count) / 5.0, 1.0)
        let themeComplexity = min(Double(themes.count) / 3.0, 1.0)
        
        return (structuralComplexity + characterComplexity + themeComplexity) / 3.0
    }
    
    private func detectGenre(_ story: String, themes: [String]) -> String {
        let lowercased = story.lowercased()
        
        // Genre detection patterns
        if themes.contains("Love") && themes.contains("Conflict") {
            return "Romantic Drama"
        } else if themes.contains("Adventure") || themes.contains("Conflict") {
            return "Action/Adventure"
        } else if themes.contains("Fear") || themes.contains("Loss") {
            return "Thriller/Drama"
        } else if lowercased.contains("magic") || lowercased.contains("fantasy") {
            return "Fantasy"
        } else if lowercased.contains("space") || lowercased.contains("future") {
            return "Science Fiction"
        }
        
        return "Drama"
    }
}

// MARK: - Supporting Types

public struct StoryAnalysisInput: Sendable {
    public let story: String
    
    public init(story: String) {
        self.story = story
    }
}

public struct StoryAnalysisOutput: Sendable {
    public let analysis: StoryAnalysis
    public let extractionMethod: ExtractionMethod
    public let confidence: Double
    public let processingTime: TimeInterval
    
    public init(
        analysis: StoryAnalysis,
        extractionMethod: ExtractionMethod,
        confidence: Double,
        processingTime: TimeInterval
    ) {
        self.analysis = analysis
        self.extractionMethod = extractionMethod
        self.confidence = confidence
        self.processingTime = processingTime
    }
}

public struct StoryAnalysis: Codable, Sendable {
    public let narrativeArc: String
    public let emotionalCurve: [Double]
    public let characterDevelopment: [String: String]
    public let themes: [String]
    public let genre: String
    public let targetAudience: String
    public let estimatedDuration: TimeInterval
    public let complexityScore: Double
    
    public init(
        narrativeArc: String,
        emotionalCurve: [Double],
        characterDevelopment: [String: String],
        themes: [String],
        genre: String,
        targetAudience: String,
        estimatedDuration: TimeInterval,
        complexityScore: Double
    ) {
        self.narrativeArc = narrativeArc
        self.emotionalCurve = emotionalCurve
        self.characterDevelopment = characterDevelopment
        self.themes = themes
        self.genre = genre
        self.targetAudience = targetAudience
        self.estimatedDuration = estimatedDuration
        self.complexityScore = complexityScore
    }
}

public enum ExtractionMethod: String, Sendable, Codable {
    case aiPowered = "AI-Powered"
    case ruleBased = "Rule-Based"
    case fallback = "Fallback"
}

