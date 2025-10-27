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
        strategy: SegmentationStrategy,
        constraints: SegmentationConstraints
    ) async throws -> SegmentationResult
}

// MARK: - Segmentation Strategy

enum SegmentationStrategy: String, CaseIterable {
    case byScenes       // Primary: Scene markers (INT., EXT., FADE IN, etc.)
    case byParagraphs   // Fallback: Double line breaks
    case bySentences    // Fallback: Sentence boundaries
    case byDuration     // Fallback: Word pacing estimation
    case hybrid         // Intelligent combination of strategies
    
    var displayName: String {
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

struct SegmentationConstraints {
    var maxSegments: Int = 20
    var minSegmentLength: Int = 10
    var maxSegmentLength: Int = 500
    var maxTokensPerSegment: Int = 200
    var preserveLineBreaks: Bool = false
    var language: String = "en"
    var enforceTokenLimits: Bool = true
    var allowEmptySegments: Bool = false
    
    static let `default` = SegmentationConstraints()
}

// MARK: - Results and Metadata

struct SegmentationResult {
    var segments: [MultiClipSegment]
    var metadata: SegmentationMetadata
    var warnings: [SegmentationWarning]
    
    var isValid: Bool {
        !segments.isEmpty && segments.allSatisfy { !$0.text.isEmpty }
    }
}

struct SegmentationMetadata {
    var strategy: SegmentationStrategy
    var executionTime: TimeInterval
    var fallbacksUsed: [String]
    var confidence: Double  // 0.0 to 1.0
    var segmentCount: Int
    var averageTokenCount: Double
    var totalCharacters: Int
    
    var summary: String {
        """
        Strategy: \(strategy.displayName)
        Segments: \(segmentCount)
        Confidence: \(String(format: "%.1f%%", confidence * 100))
        Avg Tokens: \(String(format: "%.0f", averageTokenCount))
        Execution: \(String(format: "%.3fs", executionTime))
        """
    }
}

enum SegmentationWarning: Equatable {
    case segmentTooLong(index: Int, length: Int)
    case segmentTooShort(index: Int, length: Int)
    case tokenLimitExceeded(index: Int, tokens: Int)
    case emptySegmentDetected(index: Int)
    case fallbackStrategyUsed(from: SegmentationStrategy, to: SegmentationStrategy)
    case lowConfidence(confidence: Double)
    case noSceneMarkersFound
    case scripFormatAmbiguous
    
    var message: String {
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
        case .scripFormatAmbiguous:
            return "Script format could not be reliably determined"
        }
    }
}

// MARK: - Main Implementation

final class SegmentingModule: SegmentingModuleProtocol {
    
    // MARK: - Dependencies
    
    private let tokenEstimator: TokenEstimator
    private let sceneDetector: SceneDetector
    private let continuityAnalyzer: ContinuityAnalyzer
    
    // MARK: - Initialization
    
    init(
        tokenEstimator: TokenEstimator = .shared,
        sceneDetector: SceneDetector = .shared,
        continuityAnalyzer: ContinuityAnalyzer = .shared
    ) {
        self.tokenEstimator = tokenEstimator
        self.sceneDetector = sceneDetector
        self.continuityAnalyzer = continuityAnalyzer
    }
    
    // MARK: - Public API
    
    func segment(
        script: String,
        strategy: SegmentationStrategy,
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
        let avgTokens = segments.map { tokenEstimator.estimate($0.text) }
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
        let paragraphs = script.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Merge very short paragraphs
        return mergeShortSegments(paragraphs, minLength: constraints.minSegmentLength)
    }
    
    private func segmentBySentences(_ script: String, constraints: SegmentationConstraints) -> [String] {
        var sentences: [String] = []
        
        let detector = NLSentenceDetector()
        let range = NSRange(script.startIndex..., in: script)
        
        detector.string = script
        detector.enumerateRanges(in: range) { range, _ in
            if let swiftRange = Range(range, in: script) {
                let sentence = String(script[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !sentence.isEmpty {
                    sentences.append(sentence)
                }
            }
        }
        
        // Merge sentences to meet minimum length
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
            id: UUID(),
            text: trimmedText,
            order: order,
            duration: 3.0,  // Default duration, will be adjusted in DurationSelectionView
            continuityNote: nil,
            lastFrameImage: nil,
            progress: 0.0,
            generationState: .pending,
            videoURL: nil,
            thumbnailURL: nil,
            metadata: SegmentMetadata(
                tokenCount: tokenEstimator.estimate(trimmedText),
                characterCount: trimmedText.count,
                wordCount: trimmedText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
            )
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
        strategy: SegmentationStrategy,
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

// MARK: - Supporting Types

struct SegmentMetadata {
    var tokenCount: Int
    var characterCount: Int
    var wordCount: Int
}

extension MultiClipSegment {
    var metadata: SegmentMetadata {
        get {
            // This would normally be stored as a property
            SegmentMetadata(
                tokenCount: TokenEstimator.shared.estimate(text),
                characterCount: text.count,
                wordCount: text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
            )
        }
        set {
            // Would store if MultiClipSegment had this property
        }
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

final class TokenEstimator {
    static let shared = TokenEstimator()
    
    private init() {}
    
    /// Estimates token count using ~4 characters per token heuristic
    func estimate(_ text: String) -> Int {
        // GPT-style tokenization approximation
        return max(1, text.count / 4)
    }
    
    /// Truncates text to fit within token limit
    func truncate(_ text: String, maxTokens: Int) -> String {
        let maxChars = maxTokens * 4
        guard text.count > maxChars else { return text }
        
        let index = text.index(text.startIndex, offsetBy: maxChars)
        return String(text[..<index]) + "..."
    }
}

// MARK: - Scene Detector

final class SceneDetector {
    static let shared = SceneDetector()
    
    private let sceneMarkers = [
        "INT.", "EXT.", "INT/EXT", "EXT/INT",
        "FADE IN:", "FADE OUT.", "FADE TO:",
        "CUT TO:", "DISSOLVE TO:",
        "FLASHBACK:", "FLASHFORWARD:",
        "DREAM SEQUENCE:", "MONTAGE:"
    ]
    
    private init() {}
    
    func detectScenes(in script: String) async -> [String] {
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

final class ContinuityAnalyzer {
    static let shared = ContinuityAnalyzer()
    
    private init() {}
    
    /// Analyzes continuity between segments for bridging
    func analyzeContinuity(from: MultiClipSegment, to: MultiClipSegment) -> String? {
        // Placeholder for future continuity analysis
        // Could detect character continuity, location continuity, etc.
        return nil
    }
    
    /// Generates continuity note for a segment
    func generateContinuityNote(for segment: MultiClipSegment, context: [MultiClipSegment]) -> String? {
        // Placeholder for context-aware continuity notes
        return nil
    }
}

// MARK: - NLSentenceDetector Stub

// Note: In production, use NaturalLanguage framework's NLTokenizer
private class NLSentenceDetector {
    var string: String = ""
    
    func enumerateRanges(in range: NSRange, using block: (NSRange, UnsafeMutablePointer<ObjCBool>) -> Void) {
        // Simple sentence detection using punctuation
        let text = string as NSString
        let sentenceEnders = CharacterSet(charactersIn: ".!?")
        
        var currentStart = 0
        for i in 0..<text.length {
            let char = text.character(at: i)
            if sentenceEnders.contains(UnicodeScalar(char)!) {
                let sentenceRange = NSRange(location: currentStart, length: i - currentStart + 1)
                var stop: ObjCBool = false
                block(sentenceRange, &stop)
                currentStart = i + 1
                
                if stop.boolValue { break }
            }
        }
        
        // Handle remaining text
        if currentStart < text.length {
            let remaining = NSRange(location: currentStart, length: text.length - currentStart)
            var stop: ObjCBool = false
            block(remaining, &stop)
        }
    }
}

// MARK: - Integration Extensions

extension SegmentingModule {
    
    /// Convenience method matching existing VideoGenerationScreen usage
    static func createSegments(from script: String, mode: GenerationMode = .multiClip) async throws -> [MultiClipSegment] {
        let module = SegmentingModule()
        let strategy: SegmentationStrategy = mode == .multiClip ? .hybrid : .byScenes
        let result = try await module.segment(script: script, strategy: strategy)
        return result.segments
    }
}

enum GenerationMode {
    case singleClip
    case multiClip
}

// MARK: - Usage Example

#if DEBUG
extension SegmentingModule {
    static func runExample() async {
        let sampleScript = """
        INT. COFFEE SHOP - DAY
        
        A bustling café filled with the aroma of fresh coffee. JANE (30s) sits alone at a corner table, typing on her laptop.
        
        FADE TO:
        
        EXT. CITY STREET - CONTINUOUS
        
        Rain begins to fall. People hurry past with umbrellas. Jane exits the café, looking up at the darkening sky.
        """
        
        do {
            let module = SegmentingModule()
            let result = try await module.segment(
                script: sampleScript,
                strategy: .hybrid,
                constraints: .default
            )
            
            print("📊 Segmentation Result:")
            print(result.metadata.summary)
            print("\n🎬 Segments:")
            for (index, segment) in result.segments.enumerated() {
                print("\n[\(index + 1)] \(segment.text.prefix(60))...")
            }
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}
#endif