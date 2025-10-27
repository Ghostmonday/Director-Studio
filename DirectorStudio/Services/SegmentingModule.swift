//
//  SegmentingModule.swift
//  DirectorStudio
//
//  Rebuilt: October 2025
//  Purpose: Transforms scripts into segmented prompts for multi-clip video generation
//  Architecture: Protocol-driven, strategy-based segmentation with full UX integration
//

import Foundation

// MARK: - Protocol Definition

/// Core protocol for segmentation module implementations
protocol SegmentingModuleProtocol {
    /// Segments a script into multiple clips based on strategy and constraints
    /// - Parameters:
    ///   - script: Raw script text to segment
    ///   - strategy: Primary segmentation strategy to apply
    ///   - constraints: Rules and limits for segmentation
    /// - Returns: Complete segmentation result with metadata and warnings
    func segment(
        script: String,
        strategy: SegmentingStrategy,
        constraints: SegmentationConstraints
    ) async throws -> SegmentationResult
}

// MARK: - Segmentation Strategy

public enum SegmentingStrategy: String, CaseIterable {
    case byScenes       // Primary: Scene markers (INT., EXT., FADE IN, etc.)
    case byParagraphs   // Fallback: Double line breaks
    case bySentences    // Fallback: Sentence boundaries
    case byDuration     // Fallback: Word pacing estimation
    case hybrid         // Intelligent combination of strategies
    
    public var displayName: String {
        switch self {
        case .byScenes: return "Scene Changes"
        case .byParagraphs: return "Paragraphs"
        case .bySentences: return "Sentences"
        case .byDuration: return "Duration-Based"
        case .hybrid: return "Smart Segmentation"
        }
    }
}

// MARK: - Constraints

public struct SegmentationConstraints {
    public var maxSegments: Int = 20
    public var minSegmentLength: Int = 10
    public var maxSegmentLength: Int = 500
    public var maxTokensPerSegment: Int = 200
    public var preserveLineBreaks: Bool = false
    public var language: String = "en"
    public var enforceTokenLimits: Bool = true
    public var allowEmptySegments: Bool = false
    
    public init(
        maxSegments: Int = 20,
        minSegmentLength: Int = 10,
        maxSegmentLength: Int = 500,
        maxTokensPerSegment: Int = 200,
        preserveLineBreaks: Bool = false,
        language: String = "en",
        enforceTokenLimits: Bool = true,
        allowEmptySegments: Bool = false
    ) {
        self.maxSegments = maxSegments
        self.minSegmentLength = minSegmentLength
        self.maxSegmentLength = maxSegmentLength
        self.maxTokensPerSegment = maxTokensPerSegment
        self.preserveLineBreaks = preserveLineBreaks
        self.language = language
        self.enforceTokenLimits = enforceTokenLimits
        self.allowEmptySegments = allowEmptySegments
    }
    
    public static let `default` = SegmentationConstraints()
    
    public static let directorStudioDefaults = SegmentationConstraints(
        maxSegments: 15,              // Reasonable for UX
        minSegmentLength: 20,         // Enough for meaningful content
        maxSegmentLength: 400,        // Readable in UI
        maxTokensPerSegment: 180,     // Leave buffer for API
        preserveLineBreaks: false,    // Clean output
        language: "en",               // Default
        enforceTokenLimits: true,     // Critical for API
        allowEmptySegments: false     // Data quality
    )
}

// MARK: - Results and Metadata

public struct SegmentationResult {
    public var segments: [MultiClipSegment]
    public var metadata: SegmentationMetadata
    public var warnings: [SegmentationWarning]
    
    public init(
        segments: [MultiClipSegment],
        metadata: SegmentationMetadata,
        warnings: [SegmentationWarning]
    ) {
        self.segments = segments
        self.metadata = metadata
        self.warnings = warnings
    }
    
    public var isValid: Bool {
        !segments.isEmpty && segments.allSatisfy { !$0.text.isEmpty }
    }
}

public struct SegmentationMetadata {
    public var strategy: SegmentingStrategy
    public var executionTime: TimeInterval
    public var fallbacksUsed: [String]
    public var confidence: Double  // 0.0 to 1.0
    public var segmentCount: Int
    public var averageTokenCount: Double
    public var totalCharacters: Int
    
    public init(
        strategy: SegmentingStrategy,
        executionTime: TimeInterval,
        fallbacksUsed: [String],
        confidence: Double,
        segmentCount: Int,
        averageTokenCount: Double,
        totalCharacters: Int
    ) {
        self.strategy = strategy
        self.executionTime = executionTime
        self.fallbacksUsed = fallbacksUsed
        self.confidence = confidence
        self.segmentCount = segmentCount
        self.averageTokenCount = averageTokenCount
        self.totalCharacters = totalCharacters
    }
    
    public var summary: String {
        """
        Strategy: \(strategy.displayName)
        Segments: \(segmentCount)
        Confidence: \(String(format: "%.1f%%", confidence * 100))
        Avg Tokens: \(String(format: "%.0f", averageTokenCount))
        Execution: \(String(format: "%.3fs", executionTime))
        """
    }
}

public enum SegmentationWarning: Equatable {
    case segmentTooLong(index: Int, length: Int)
    case segmentTooShort(index: Int, length: Int)
    case tokenLimitExceeded(index: Int, tokens: Int)
    case emptySegmentDetected(index: Int)
    case fallbackStrategyUsed(from: SegmentingStrategy, to: SegmentingStrategy)
    case lowConfidence(confidence: Double)
    case noSceneMarkersFound
    case scriptFormatAmbiguous
    
    public var message: String {
        switch self {
        case .segmentTooLong(let index, let length):
            return "Segment #\(index + 1) exceeds max length (\(length) chars)"
        case .segmentTooShort(let index, let length):
            return "Segment #\(index + 1) is very short (\(length) chars)"
        case .tokenLimitExceeded(let index, let tokens):
            return "Segment #\(index + 1) exceeds token limit (\(tokens) tokens)"
        case .emptySegmentDetected(let index):
            return "Segment #\(index + 1) is empty"
        case .fallbackStrategyUsed(let from, let to):
            return "Fallback: \(from.displayName) → \(to.displayName)"
        case .lowConfidence(let confidence):
            return "Low segmentation confidence: \(String(format: "%.1f%%", confidence * 100))"
        case .noSceneMarkersFound:
            return "No scene markers detected in script"
        case .scriptFormatAmbiguous:
            return "Script format could not be reliably determined"
        }
    }
}

// MARK: - Main Implementation

public final class SegmentingModule: SegmentingModuleProtocol {
    
    // MARK: - Dependencies
    
    private let tokenEstimator: TokenEstimator
    private let sceneDetector: SceneDetector
    private let continuityAnalyzer: ContinuityAnalyzer
    
    // MARK: - Initialization
    
    public init(
        tokenEstimator: TokenEstimator = .shared,
        sceneDetector: SceneDetector = .shared,
        continuityAnalyzer: ContinuityAnalyzer = .shared
    ) {
        self.tokenEstimator = tokenEstimator
        self.sceneDetector = sceneDetector
        self.continuityAnalyzer = continuityAnalyzer
    }
    
    // MARK: - Public API
    
    public func segment(
        script: String,
        strategy: SegmentingStrategy,
        constraints: SegmentationConstraints = .default
    ) async throws -> SegmentationResult {
        
        let startTime = Date()
        
        #if DEBUG
        print("🎬 [SegmentingModule] Starting segmentation")
        print("📝 Script length: \(script.count) characters")
        print("🎯 Strategy: \(strategy.displayName)")
        #endif
        
        // Validate input
        guard !script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SegmentationError.emptyScript
        }
        
        // Add UX polish delay (matches existing 1.5s delay)
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        var warnings: [SegmentationWarning] = []
        var fallbacksUsed: [String] = []
        var finalStrategy = strategy
        
        // Execute segmentation with fallback chain
        let rawSegments: [String]
        
        switch strategy {
        case .byScenes:
            rawSegments = try await segmentByScenes(script, constraints: constraints, warnings: &warnings, fallbacks: &fallbacksUsed)
            finalStrategy = fallbacksUsed.isEmpty ? .byScenes : .byParagraphs
            
        case .byParagraphs:
            rawSegments = segmentByParagraphs(script, constraints: constraints)
            
        case .bySentences:
            rawSegments = segmentBySentences(script, constraints: constraints)
            
        case .byDuration:
            rawSegments = segmentByDuration(script, constraints: constraints)
            
        case .hybrid:
            rawSegments = try await segmentHybrid(script, constraints: constraints, warnings: &warnings, fallbacks: &fallbacksUsed)
            finalStrategy = .hybrid
        }
        
        // Convert to MultiClipSegment objects
        var segments = rawSegments.enumerated().map { index, text in
            createSegment(text: text, order: index, constraints: constraints)
        }
        
        // Validate and warn about constraint violations
        validateSegments(&segments, constraints: constraints, warnings: &warnings)
        
        // Calculate confidence score
        let confidence = calculateConfidence(
            segments: segments,
            strategy: finalStrategy,
            fallbackCount: fallbacksUsed.count,
            warningCount: warnings.count
        )
        
        if confidence < 0.6 {
            warnings.append(.lowConfidence(confidence: confidence))
        }
        
        // Calculate metadata
        let executionTime = Date().timeIntervalSince(startTime)
        let avgTokens = segments.map { Double(tokenEstimator.estimate($0.text)) }
            .reduce(0, +) / Double(max(segments.count, 1))
        
        let metadata = SegmentationMetadata(
            strategy: finalStrategy,
            executionTime: executionTime,
            fallbacksUsed: fallbacksUsed,
            confidence: confidence,
            segmentCount: segments.count,
            averageTokenCount: avgTokens,
            totalCharacters: script.count
        )
        
        #if DEBUG
        print("✅ [SegmentingModule] Segmentation complete")
        print(metadata.summary)
        if !warnings.isEmpty {
            print("⚠️ Warnings: \(warnings.count)")
            warnings.forEach { print("  - \($0.message)") }
        }
        #endif
        
        return SegmentationResult(
            segments: segments,
            metadata: metadata,
            warnings: warnings
        )
    }
    
    // MARK: - Segmentation Strategies
    
    private func segmentByScenes(
        _ script: String,
        constraints: SegmentationConstraints,
        warnings: inout [SegmentationWarning],
        fallbacks: inout [String]
    ) async throws -> [String] {
        
        let scenes = await sceneDetector.detectScenes(in: script)
        
        if scenes.isEmpty {
            warnings.append(.noSceneMarkersFound)
            fallbacks.append("No scene markers → paragraphs")
            return segmentByParagraphs(script, constraints: constraints)
        }
        
        if scenes.count == 1 && scenes[0].count < constraints.minSegmentLength {
            fallbacks.append("Single short scene → paragraphs")
            return segmentByParagraphs(script, constraints: constraints)
        }
        
        return scenes
    }
    
    private func segmentByParagraphs(_ script: String, constraints: SegmentationConstraints) -> [String] {
        let paragraphs = script.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Merge very short paragraphs
        return mergeShortSegments(paragraphs, minLength: constraints.minSegmentLength)
    }
    
    private func segmentBySentences(_ script: String, constraints: SegmentationConstraints) -> [String] {
        // Simple sentence detection using punctuation
        let sentences = script.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Group sentences to meet minimum length
        return mergeShortSegments(sentences, minLength: constraints.minSegmentLength)
    }
    
    private func segmentByDuration(_ script: String, constraints: SegmentationConstraints) -> [String] {
        // Estimate ~150 words per minute of speech, ~3 seconds per segment
        let wordsPerSegment = 8  // Approximately 3 seconds
        let words = script.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        var segments: [String] = []
        var currentSegment: [String] = []
        
        for word in words {
            currentSegment.append(word)
            if currentSegment.count >= wordsPerSegment {
                segments.append(currentSegment.joined(separator: " "))
                currentSegment = []
            }
        }
        
        if !currentSegment.isEmpty {
            segments.append(currentSegment.joined(separator: " "))
        }
        
        return segments
    }
    
    private func segmentHybrid(
        _ script: String,
        constraints: SegmentationConstraints,
        warnings: inout [SegmentationWarning],
        fallbacks: inout [String]
    ) async throws -> [String] {
        
        // Try scene detection first
        let scenes = await sceneDetector.detectScenes(in: script)
        
        if !scenes.isEmpty && scenes.count <= constraints.maxSegments {
            return scenes
        }
        
        // Fall back to paragraph-based with sentence awareness
        let paragraphs = segmentByParagraphs(script, constraints: constraints)
        
        if paragraphs.count <= constraints.maxSegments {
            return paragraphs
        }
        
        // If still too many segments, intelligently merge
        fallbacks.append("Hybrid merging applied")
        return intelligentMerge(paragraphs, maxSegments: constraints.maxSegments)
    }
    
    // MARK: - Helper Functions
    
    private func createSegment(text: String, order: Int, constraints: SegmentationConstraints) -> MultiClipSegment {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return MultiClipSegment(
            text: trimmedText,
            order: order,
            duration: 3.0  // Default duration, will be adjusted in DurationSelectionView
        )
    }
    
    private func validateSegments(
        _ segments: inout [MultiClipSegment],
        constraints: SegmentationConstraints,
        warnings: inout [SegmentationWarning]
    ) {
        for (index, segment) in segments.enumerated() {
            // Check length constraints
            if segment.text.count > constraints.maxSegmentLength {
                warnings.append(.segmentTooLong(index: index, length: segment.text.count))
            }
            
            if segment.text.count < constraints.minSegmentLength && segment.text.count > 0 {
                warnings.append(.segmentTooShort(index: index, length: segment.text.count))
            }
            
            // Check token limits
            if constraints.enforceTokenLimits {
                let tokens = tokenEstimator.estimate(segment.text)
                if tokens > constraints.maxTokensPerSegment {
                    warnings.append(.tokenLimitExceeded(index: index, tokens: tokens))
                    
                    // Auto-truncate if needed
                    segments[index].text = tokenEstimator.truncate(
                        segment.text,
                        maxTokens: constraints.maxTokensPerSegment
                    )
                }
            }
            
            // Check for empty segments
            if segment.text.isEmpty && !constraints.allowEmptySegments {
                warnings.append(.emptySegmentDetected(index: index))
            }
        }
        
        // Remove empty segments if not allowed
        if !constraints.allowEmptySegments {
            segments.removeAll { $0.text.isEmpty }
        }
    }
    
    private func mergeShortSegments(_ segments: [String], minLength: Int) -> [String] {
        guard !segments.isEmpty else { return [] }
        
        var merged: [String] = []
        var current = ""
        
        for segment in segments {
            if current.isEmpty {
                current = segment
            } else if current.count < minLength {
                current += " " + segment
            } else {
                merged.append(current)
                current = segment
            }
        }
        
        if !current.isEmpty {
            merged.append(current)
        }
        
        return merged
    }
    
    private func intelligentMerge(_ segments: [String], maxSegments: Int) -> [String] {
        guard segments.count > maxSegments else { return segments }
        
        var merged = segments
        
        while merged.count > maxSegments {
            // Find the two shortest consecutive segments to merge
            var minPairLength = Int.max
            var minPairIndex = 0
            
            for i in 0..<(merged.count - 1) {
                let pairLength = merged[i].count + merged[i + 1].count
                if pairLength < minPairLength {
                    minPairLength = pairLength
                    minPairIndex = i
                }
            }
            
            // Merge the pair
            let mergedText = merged[minPairIndex] + " " + merged[minPairIndex + 1]
            merged.remove(at: minPairIndex)
            merged[minPairIndex] = mergedText
        }
        
        return merged
    }
    
    private func calculateConfidence(
        segments: [MultiClipSegment],
        strategy: SegmentingStrategy,
        fallbackCount: Int,
        warningCount: Int
    ) -> Double {
        var confidence = 1.0
        
        // Reduce confidence for each fallback used
        confidence -= Double(fallbackCount) * 0.15
        
        // Reduce confidence for warnings
        confidence -= Double(warningCount) * 0.05
        
        // Boost confidence for optimal strategy
        if strategy == .byScenes {
            confidence += 0.1
        }
        
        // Penalize very few or very many segments
        let segmentCount = segments.count
        if segmentCount < 3 {
            confidence -= 0.1
        } else if segmentCount > 15 {
            confidence -= 0.05
        }
        
        return max(0.0, min(1.0, confidence))
    }
}

// MARK: - Error Handling

enum SegmentationError: LocalizedError {
    case emptyScript
    case invalidStrategy
    case constraintViolation(String)
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyScript:
            return "Cannot segment an empty script"
        case .invalidStrategy:
            return "The selected segmentation strategy is not valid"
        case .constraintViolation(let detail):
            return "Constraint violation: \(detail)"
        case .processingFailed(let detail):
            return "Segmentation processing failed: \(detail)"
        }
    }
}

// MARK: - Token Estimator

public final class TokenEstimator {
    public static let shared = TokenEstimator()
    
    private init() {}
    
    /// Estimates token count using ~4 characters per token heuristic
    public func estimate(_ text: String) -> Int {
        // GPT-style tokenization approximation
        return max(1, text.count / 4)
    }
    
    /// Truncates text to fit within token limit
    public func truncate(_ text: String, maxTokens: Int) -> String {
        let maxChars = maxTokens * 4
        guard text.count > maxChars else { return text }
        
        let index = text.index(text.startIndex, offsetBy: maxChars)
        return String(text[..<index]) + "..."
    }
}

// MARK: - Scene Detector

public final class SceneDetector {
    public static let shared = SceneDetector()
    
    private let sceneMarkers = [
        "INT.", "EXT.", "INT/EXT", "EXT/INT",
        "FADE IN:", "FADE OUT.", "FADE TO:",
        "CUT TO:", "DISSOLVE TO:",
        "FLASHBACK:", "FLASHFORWARD:",
        "DREAM SEQUENCE:", "MONTAGE:"
    ]
    
    public init() {}
    
    public func detectScenes(in script: String) async -> [String] {
        let lines = script.components(separatedBy: .newlines)
        var scenes: [String] = []
        var currentScene: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let uppercase = trimmed.uppercased()
            
            // Check if line starts with a scene marker
            let isSceneHeader = sceneMarkers.contains { uppercase.hasPrefix($0) }
            
            if isSceneHeader && !currentScene.isEmpty {
                // Save previous scene
                let sceneText = currentScene.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if !sceneText.isEmpty {
                    scenes.append(sceneText)
                }
                currentScene = [trimmed]
            } else {
                currentScene.append(trimmed)
            }
        }
        
        // Add final scene
        if !currentScene.isEmpty {
            let sceneText = currentScene.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !sceneText.isEmpty {
                scenes.append(sceneText)
            }
        }
        
        return scenes
    }
}

// MARK: - Continuity Analyzer

public final class ContinuityAnalyzer {
    public static let shared = ContinuityAnalyzer()
    
    public init() {}
    
    /// Analyzes continuity between segments for bridging
    public func analyzeContinuity(from: MultiClipSegment, to: MultiClipSegment) -> String? {
        // Placeholder for future continuity analysis
        // Could detect character continuity, location continuity, etc.
        return nil
    }
    
    /// Generates continuity note for a segment
    public func generateContinuityNote(for segment: MultiClipSegment, context: [MultiClipSegment]) -> String? {
        // Placeholder for context-aware continuity notes
        return nil
    }
}

// MARK: - Integration Extensions

extension SegmentingModule {
    
    /// Convenience method matching existing VideoGenerationScreen usage
    public static func createSegments(from script: String, strategy: MultiClipSegmentationStrategy = .byScenes) async throws -> [MultiClipSegment] {
        let module = SegmentingModule()
        
        // Map old strategy enum to new one
        let newStrategy: SegmentingStrategy
        switch strategy {
        case .byScenes:
            newStrategy = .byScenes
        case .byParagraphs:
            newStrategy = .byParagraphs
        case .bySentences:
            newStrategy = .bySentences
        case .byDuration:
            newStrategy = .byDuration
        }
        
        let result = try await module.segment(
            script: script,
            strategy: newStrategy,
            constraints: .directorStudioDefaults
        )
        
        return result.segments
    }
}
