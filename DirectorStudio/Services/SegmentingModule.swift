//
//  SegmentingModule.swift
//  DirectorStudio
//
//  Advanced LLM-Integrated Segmentation System
//  Built for AI filmmaking pipeline with DeepSeek integration
//

import Foundation

// MARK: - Protocol Definition

/// Core protocol for LLM-integrated segmentation
protocol SegmentingModuleProtocol {
    func segment(
        script: String,
        mode: SegmentationMode,
        constraints: SegmentationConstraints,
        llmConfig: LLMConfiguration?
    ) async throws -> SegmentationResult
}

// MARK: - Segmentation Modes

enum SegmentationMode: String, CaseIterable {
    case ai             // LLM-powered cinematic analysis (primary)
    case duration       // Time-based splitting
    case evenSplit      // Equal token distribution
    case hybrid         // AI with fallback to duration
    
    var displayName: String {
        switch self {
        case .ai: return "AI (Cinematic)"
        case .duration: return "Duration-Based"
        case .evenSplit: return "Even Split"
        case .hybrid: return "Smart Hybrid"
        }
    }
    
    var requiresLLM: Bool {
        switch self {
        case .ai, .hybrid: return true
        case .duration, .evenSplit: return false
        }
    }
}

// MARK: - Constraints

struct SegmentationConstraints {
    var maxSegments: Int = 20
    var maxTokensPerSegment: Int = 200
    var maxDuration: Double = 10.0          // seconds
    var minDuration: Double = 1.0           // seconds
    var targetDuration: Double = 3.0        // preferred duration
    var enforceStrictLimits: Bool = true
    var allowAutoAdjustment: Bool = true
    
    static let `default` = SegmentationConstraints()
    
    /// Validates if constraints are internally consistent
    var isValid: Bool {
        maxSegments > 0 &&
        maxTokensPerSegment > 0 &&
        maxDuration > minDuration &&
        targetDuration >= minDuration &&
        targetDuration <= maxDuration
    }
}

// MARK: - LLM Configuration

struct LLMConfiguration {
    var provider: LLMProvider = .deepseek
    var model: String = "deepseek-chat"
    var apiKey: String
    var endpoint: String = "https://api.deepseek.com/v1/chat/completions"
    var temperature: Double = 0.3           // Lower for more consistent segmentation
    var maxRetries: Int = 3
    var timeoutSeconds: Double = 30.0
    
    // Semantic Expansion Configuration
    var enableSemanticExpansion: Bool = false
    var expansionConfig: SemanticExpansionConfig = .default
    
    enum LLMProvider: String {
        case deepseek = "DeepSeek"
        case openai = "OpenAI"
        case anthropic = "Anthropic"
        case custom = "Custom"
    }
}

// MARK: - Semantic Expansion Configuration

struct SemanticExpansionConfig {
    var enabled: Bool = true
    var expansionStyle: ExpansionStyle = .vivid
    var tokenBudgetPerSegment: Int = 100        // Additional tokens for expanded prompt
    var preserveOriginal: Bool = true           // Keep base prompt alongside expansion
    var expandShortSegments: Bool = true        // Expand segments < minLength
    var minLengthForExpansion: Int = 30         // Chars threshold for short segment
    var expandEmotionalSegments: Bool = true    // Expand high-emotion segments
    var emotionThreshold: Double = 0.6          // Emotion detection threshold (0.0-1.0)
    var maxExpansions: Int = 5                  // Limit expansions per script (cost control)
    var expansionTemperature: Double = 0.7      // Higher for creative expansion
    
    enum ExpansionStyle: String, CaseIterable {
        case vivid = "Vivid & Cinematic"        // Rich visual descriptions
        case emotional = "Emotionally Expressive" // Focus on feeling/tone
        case action = "Action-Oriented"         // Movement and dynamics
        case atmospheric = "Atmospheric"        // Mood and environment
        case balanced = "Balanced"              // Mix of all aspects
        
        var promptGuidance: String {
            switch self {
            case .vivid:
                return "Create a vivid, visually rich description that emphasizes colors, lighting, textures, and cinematic framing."
            case .emotional:
                return "Expand with emotional depth, focusing on character feelings, internal states, and psychological nuance."
            case .action:
                return "Emphasize movement, energy, and dynamic action with precise choreography and momentum."
            case .atmospheric:
                return "Build atmosphere through environmental details, mood, ambiance, and sensory elements."
            case .balanced:
                return "Blend visual richness, emotional depth, action, and atmosphere into a cohesive cinematic description."
            }
        }
    }
    
    static let `default` = SemanticExpansionConfig()
    
    /// Validates configuration consistency
    var isValid: Bool {
        tokenBudgetPerSegment > 0 &&
        minLengthForExpansion > 0 &&
        emotionThreshold >= 0.0 && emotionThreshold <= 1.0 &&
        maxExpansions > 0 &&
        expansionTemperature >= 0.0 && expansionTemperature <= 2.0
    }
}

// MARK: - Segment Object

struct CinematicSegment: Codable, Identifiable {
    let id: UUID
    let segmentIndex: Int
    let text: String                    // Base prompt text
    let estimatedTokens: Int
    let estimatedDuration: Double
    
    // Chronological positioning
    let globalStartToken: Int
    let globalEndToken: Int
    
    // Taxonomy preparation
    var taxonomyHints: TaxonomyHints
    
    // Semantic Expansion (optional)
    var expandedPrompt: ExpandedPrompt?
    
    // Metadata
    let splitReason: String?
    let confidence: Double              // 0.0-1.0, LLM confidence in boundary
    let fallbackNotes: String?
    
    // Generation state tracking
    var generationState: GenerationState = .pending
    var progress: Double = 0.0
    var videoURL: URL?
    
    enum GenerationState: String, Codable {
        case pending
        case generating
        case complete
        case failed
    }
    
    /// Returns the prompt to use for generation (expanded if available, else base)
    var effectivePrompt: String {
        expandedPrompt?.text ?? text
    }
    
    /// Total tokens including expansion
    var totalTokens: Int {
        estimatedTokens + (expandedPrompt?.additionalTokens ?? 0)
    }
}

// MARK: - Expanded Prompt

struct ExpandedPrompt: Codable {
    let text: String                    // Expanded prompt text
    let additionalTokens: Int           // Tokens added by expansion
    let expansionReason: String         // Why expanded (short/emotional/etc)
    let emotionScore: Double?           // Detected emotion intensity (0.0-1.0)
    let expansionStyle: String          // Style used for expansion
    let llmConfidence: Double           // LLM confidence in expansion quality
    
    // Enhanced taxonomy from expansion
    var enhancedHints: TaxonomyHints?
    
    var summary: String {
        """
        Expanded (\(additionalTokens) tokens added)
        Reason: \(expansionReason)
        Style: \(expansionStyle)
        Confidence: \(Int(llmConfidence * 100))%
        """
    }
}

struct TaxonomyHints: Codable {
    var cameraAngle: String?        // "wide", "closeup", "medium", etc.
    var sceneType: String?          // "interior", "exterior", "transition"
    var emotion: String?            // "tense", "joyful", "melancholic"
    var pacing: String?             // "fast", "slow", "moderate"
    var visualComplexity: String?   // "simple", "moderate", "complex"
    var transitionType: String?     // "cut", "fade", "dissolve"
    
    static let empty = TaxonomyHints()
}

// MARK: - Segmentation Result

struct SegmentationResult {
    let segments: [CinematicSegment]
    let metadata: SegmentationMetadata
    let warnings: [SegmentationWarning]
    let llmUsage: LLMUsageStats?
    
    var isValid: Bool {
        !segments.isEmpty && segments.allSatisfy { !$0.text.isEmpty }
    }
    
    var totalTokens: Int {
        segments.reduce(0) { $0 + $1.estimatedTokens }
    }
    
    var totalDuration: Double {
        segments.reduce(0) { $0 + $1.estimatedDuration }
    }
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
    
    // Semantic Expansion Stats
    let expansionStats: ExpansionStats?
}

struct ExpansionStats: Codable {
    let enabled: Bool
    let expandedCount: Int              // Number of segments expanded
    let totalExpansionTokens: Int       // Total tokens added by expansion
    let averageEmotionScore: Double?    // Average emotion across expanded segments
    let expansionStyle: String
    let expansionTime: TimeInterval     // Time spent on expansion
    
    var summary: String {
        """
        Expansions: \(expandedCount)
        Added Tokens: \(totalExpansionTokens)
        Style: \(expansionStyle)
        Time: \(String(format: "%.2f", expansionTime))s
        """
    }
}

struct LLMUsageStats: Codable {
    let provider: String
    let model: String
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let cost: Double?
}

// MARK: - Warnings

enum SegmentationWarning: Equatable {
    case tokenLimitExceeded(segmentIndex: Int, tokens: Int, limit: Int)
    case durationExceeded(segmentIndex: Int, duration: Double, limit: Double)
    case tooManySegments(count: Int, limit: Int)
    case lowConfidence(segmentIndex: Int, confidence: Double)
    case llmFailed(reason: String)
    case fallbackUsed(from: String, to: String)
    case autoAdjusted(description: String)
    case ambiguousBoundary(segmentIndex: Int)
    
    // Expansion-specific warnings
    case expansionFailed(segmentIndex: Int, reason: String)
    case expansionBudgetExceeded(segmentIndex: Int, tokens: Int, budget: Int)
    case maxExpansionsReached(limit: Int)
    case lowExpansionQuality(segmentIndex: Int, confidence: Double)
    
    var severity: Severity {
        switch self {
        case .tokenLimitExceeded, .durationExceeded, .tooManySegments, .llmFailed:
            return .error
        case .lowConfidence, .fallbackUsed, .ambiguousBoundary, 
             .expansionFailed, .lowExpansionQuality:
            return .warning
        case .autoAdjusted, .expansionBudgetExceeded, .maxExpansionsReached:
            return .info
        }
    }
    
    enum Severity {
        case error, warning, info
    }
    
    var message: String {
        switch self {
        case .tokenLimitExceeded(let idx, let tokens, let limit):
            return "Segment #\(idx + 1): \(tokens) tokens exceeds limit of \(limit)"
        case .durationExceeded(let idx, let duration, let limit):
            return "Segment #\(idx + 1): \(String(format: "%.1f", duration))s exceeds limit of \(String(format: "%.1f", limit))s"
        case .tooManySegments(let count, let limit):
            return "\(count) segments exceeds maximum of \(limit)"
        case .lowConfidence(let idx, let confidence):
            return "Segment #\(idx + 1): Low boundary confidence (\(Int(confidence * 100))%)"
        case .llmFailed(let reason):
            return "LLM analysis failed: \(reason)"
        case .fallbackUsed(let from, let to):
            return "Fallback: \(from) → \(to)"
        case .autoAdjusted(let description):
            return "Auto-adjusted: \(description)"
        case .ambiguousBoundary(let idx):
            return "Segment #\(idx + 1): Boundary detection was ambiguous"
        case .expansionFailed(let idx, let reason):
            return "Segment #\(idx + 1): Expansion failed - \(reason)"
        case .expansionBudgetExceeded(let idx, let tokens, let budget):
            return "Segment #\(idx + 1): Expansion added \(tokens) tokens (budget: \(budget))"
        case .maxExpansionsReached(let limit):
            return "Reached maximum \(limit) expansions for cost control"
        case .lowExpansionQuality(let idx, let confidence):
            return "Segment #\(idx + 1): Low expansion quality (\(Int(confidence * 100))%)"
        }
    }
}

// MARK: - Errors

enum SegmentationError: LocalizedError {
    case emptyScript
    case invalidConstraints(String)
    case llmConnectionFailed(String)
    case llmResponseInvalid(String)
    case constraintViolationUnresolvable(String)
    case noValidSegments
    
    var errorDescription: String? {
        switch self {
        case .emptyScript:
            return "Cannot segment an empty script"
        case .invalidConstraints(let detail):
            return "Invalid constraints: \(detail)"
        case .llmConnectionFailed(let detail):
            return "LLM connection failed: \(detail)"
        case .llmResponseInvalid(let detail):
            return "LLM returned invalid response: \(detail)"
        case .constraintViolationUnresolvable(let detail):
            return "Cannot resolve constraint violation: \(detail)"
        case .noValidSegments:
            return "No valid segments could be created"
        }
    }
}

// MARK: - Main Implementation

final class SegmentingModule: SegmentingModuleProtocol {
    
    private let tokenEstimator: TokenEstimator
    private let llmClient: LLMClient
    private let expansionProcessor: SemanticExpansionProcessor
    
    init(
        tokenEstimator: TokenEstimator = .shared,
        llmClient: LLMClient = .shared,
        expansionProcessor: SemanticExpansionProcessor = .shared
    ) {
        self.tokenEstimator = tokenEstimator
        self.llmClient = llmClient
        self.expansionProcessor = expansionProcessor
    }
    
    // MARK: - Public API
    
    func segment(
        script: String,
        mode: SegmentationMode,
        constraints: SegmentationConstraints = .default,
        llmConfig: LLMConfiguration? = nil
    ) async throws -> SegmentationResult {
        
        let startTime = Date()
        
        // Validate input
        guard !script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SegmentationError.emptyScript
        }
        
        guard constraints.isValid else {
            throw SegmentationError.invalidConstraints("Constraints are internally inconsistent")
        }
        
        #if DEBUG
        LOG("\n" + String(repeating: "=", count: 60))
        LOG("🎬 [SegmentingModule] SEGMENTATION STARTED")
        LOG(String(repeating: "=", count: 60))
        LOG("📝 Script Length: \(script.count) characters")
        LOG("📝 Script Preview: \(script.prefix(200))...")
        LOG("🎯 Mode: \(mode.displayName)")
        LOG("⚙️  Constraints:")
        LOG("   - Max Segments: \(constraints.maxSegments)")
        LOG("   - Max Tokens/Segment: \(constraints.maxTokensPerSegment)")
        LOG("   - Max Duration: \(constraints.maxDuration)s")
        LOG("   - Target Duration: \(constraints.targetDuration)s")
        LOG("   - Enforce Strict Limits: \(constraints.enforceStrictLimits)")
        LOG("🔑 LLM Config: \(llmConfig != nil ? "Provided" : "None")")
        LOG(String(repeating: "=", count: 60) + "\n")
        #endif
        
        var warnings: [SegmentationWarning] = []
        var llmUsage: LLMUsageStats?
        var llmCallCount = 0
        var fallbackUsed = false
        var constraintsViolated: [String] = []
        
        // Execute segmentation based on mode
        var segments: [CinematicSegment]
        
        switch mode {
        case .ai:
            #if DEBUG
            LOG("🤖 [AI Mode] Starting LLM-based segmentation...")
            #endif
            
            // Primary LLM-based segmentation
            guard let config = llmConfig else {
                #if DEBUG
                LOG("❌ [AI Mode] FAILED: No LLM configuration provided")
                LOG("💡 User must provide API key for AI mode")
                #endif
                throw SegmentationError.llmConnectionFailed("LLM configuration required for AI mode")
            }
            
            #if DEBUG
            LOG("✅ [AI Mode] LLM config found, calling API...")
            #endif
            
            do {
                let result = try await segmentWithLLM(
                    script: script,
                    config: config,
                    constraints: constraints
                )
                segments = result.segments
                llmUsage = result.usage
                llmCallCount = result.callCount
                warnings.append(contentsOf: result.warnings)
                
                #if DEBUG
                LOG("✅ [AI Mode] Success: Generated \(segments.count) segments")
                #endif
                
            } catch {
                throw SegmentationError.llmConnectionFailed(error.localizedDescription)
            }
            
        case .hybrid:
            #if DEBUG
            LOG("🔀 [Hybrid Mode] Attempting AI with duration fallback...")
            #endif
            
            // Try LLM, fallback to duration on failure
            if let config = llmConfig {
                #if DEBUG
                LOG("✅ [Hybrid Mode] LLM config available, trying AI first...")
                #endif
                
                do {
                    let result = try await segmentWithLLM(
                        script: script,
                        config: config,
                        constraints: constraints
                    )
                    segments = result.segments
                    llmUsage = result.usage
                    llmCallCount = result.callCount
                    warnings.append(contentsOf: result.warnings)
                    
                    #if DEBUG
                    LOG("✅ [Hybrid Mode] AI succeeded: \(segments.count) segments")
                    #endif
                    
                } catch {
                    #if DEBUG
                    LOG("⚠️ [Hybrid Mode] AI failed: \(error.localizedDescription)")
                    LOG("🔄 [Hybrid Mode] Falling back to duration-based segmentation...")
                    #endif
                    
                    warnings.append(.llmFailed(reason: error.localizedDescription))
                    warnings.append(.fallbackUsed(from: "AI", to: "Duration"))
                    fallbackUsed = true
                    segments = segmentByDuration(script: script, constraints: constraints)
                    
                    #if DEBUG
                    LOG("✅ [Hybrid Mode] Fallback succeeded: \(segments.count) segments")
                    #endif
                }
            } else {
                #if DEBUG
                LOG("⚠️ [Hybrid Mode] No LLM config, using duration-based directly...")
                #endif
                
                warnings.append(.fallbackUsed(from: "AI", to: "Duration"))
                fallbackUsed = true
                segments = segmentByDuration(script: script, constraints: constraints)
                
                #if DEBUG
                LOG("✅ [Hybrid Mode] Duration-based: \(segments.count) segments")
                #endif
            }
            
        case .duration:
            #if DEBUG
            LOG("⏱️  [Duration Mode] Starting duration-based segmentation...")
            #endif
            
            segments = segmentByDuration(script: script, constraints: constraints)
            
            #if DEBUG
            LOG("✅ [Duration Mode] Generated \(segments.count) segments")
            #endif
            
        case .evenSplit:
            #if DEBUG
            LOG("📊 [Even Split Mode] Starting even token distribution...")
            #endif
            
            segments = segmentEvenly(script: script, constraints: constraints)
            
            #if DEBUG
            LOG("✅ [Even Split Mode] Generated \(segments.count) segments")
            #endif
        }
        
        // Validate and enforce constraints
        #if DEBUG
        LOG("\n🔍 [Validation] Enforcing constraints on \(segments.count) segments...")
        #endif
        
        segments = try enforceConstraints(
            segments: segments,
            constraints: constraints,
            warnings: &warnings,
            constraintsViolated: &constraintsViolated
        )
        
        #if DEBUG
        LOG("✅ [Validation] After enforcement: \(segments.count) segments")
        if !constraintsViolated.isEmpty {
            LOG("⚠️ [Validation] Constraints violated:")
            constraintsViolated.forEach { LOG("   - \($0)") }
        }
        #endif
        
        guard !segments.isEmpty else {
            #if DEBUG
            LOG("❌ [Validation] FATAL: No valid segments after enforcement!")
            LOG("💡 This usually means:")
            LOG("   - Script is too short for constraints")
            LOG("   - Token limits are too restrictive")
            LOG("   - Duration constraints can't be met")
            #endif
            throw SegmentationError.noValidSegments
        }
        
        // Apply semantic expansion if enabled
        var expansionStats: ExpansionStats?
        if let config = llmConfig, config.enableSemanticExpansion {
            #if DEBUG
            LOG("🎨 [SemanticExpansion] Starting expansion pass")
            #endif
            
            let expansionStartTime = Date()
            let expansionResult = try await expansionProcessor.expandSegments(
                segments,
                config: config,
                warnings: &warnings
            )
            
            segments = expansionResult.segments
            let expansionTime = Date().timeIntervalSince(expansionStartTime)
            
            let expandedCount = segments.filter { $0.expandedPrompt != nil }.count
            let totalExpansionTokens = segments.reduce(0) { $0 + ($1.expandedPrompt?.additionalTokens ?? 0) }
            let emotionScores = segments.compactMap { $0.expandedPrompt?.emotionScore }
            let avgEmotion = emotionScores.isEmpty ? nil : emotionScores.reduce(0, +) / Double(emotionScores.count)
            
            expansionStats = ExpansionStats(
                enabled: true,
                expandedCount: expandedCount,
                totalExpansionTokens: totalExpansionTokens,
                averageEmotionScore: avgEmotion,
                expansionStyle: config.expansionConfig.expansionStyle.rawValue,
                expansionTime: expansionTime
            )
            
            llmCallCount += expandedCount  // Count expansion LLM calls
            
            #if DEBUG
            LOG("✨ [SemanticExpansion] Complete")
            LOG("   Expanded: \(expandedCount) segments")
            LOG("   Added Tokens: \(totalExpansionTokens)")
            LOG("   Time: \(String(format: "%.2f", expansionTime))s")
            #endif
        }
        
        // Calculate metadata
        let executionTime = Date().timeIntervalSince(startTime)
        let avgConfidence = segments.reduce(0.0) { $0 + $1.confidence } / Double(segments.count)
        
        let metadata = SegmentationMetadata(
            mode: mode.displayName,
            segmentCount: segments.count,
            totalTokens: segments.reduce(0) { $0 + $1.estimatedTokens },
            totalDuration: segments.reduce(0) { $0 + $1.estimatedDuration },
            averageConfidence: avgConfidence,
            executionTime: executionTime,
            llmCallCount: llmCallCount,
            fallbackUsed: fallbackUsed,
            constraintsViolated: constraintsViolated,
            expansionStats: expansionStats
        )
        
        #if DEBUG
        LOG("\n" + String(repeating: "=", count: 60))
        LOG("✅ [SegmentingModule] SEGMENTATION COMPLETE")
        print(String(repeating: "=", count: 60))
        LOG("📊 Results:")
        LOG("   - Total Segments: \(segments.count)")
        LOG("   - Total Tokens: \(metadata.totalTokens)")
        LOG("   - Total Duration: \(String(format: "%.1f", metadata.totalDuration))s")
        LOG("   - Avg Confidence: \(Int(avgConfidence * 100))%")
        LOG("   - Execution Time: \(String(format: "%.2f", executionTime))s")
        LOG("   - LLM Calls: \(llmCallCount)")
        LOG("   - Fallback Used: \(fallbackUsed)")
        
        if !warnings.isEmpty {
            LOG("\n⚠️  Warnings (\(warnings.count)):")
            warnings.forEach { LOG("   - \($0.message)") }
        }
        
        if !constraintsViolated.isEmpty {
            LOG("\n🚨 Constraints Violated (\(constraintsViolated.count)):")
            constraintsViolated.forEach { LOG("   - \($0)") }
        }
        
        LOG("\n📝 Segment Preview:")
        for (i, segment) in segments.prefix(3).enumerated() {
            LOG("   [\(i+1)] \(segment.text.prefix(60))... (\(segment.estimatedTokens)t, \(String(format: "%.1f", segment.estimatedDuration))s)")
        }
        if segments.count > 3 {
            LOG("   ... and \(segments.count - 3) more segments")
        }
        
        print(String(repeating: "=", count: 60) + "\n")
        #endif
        
        return SegmentationResult(
            segments: segments,
            metadata: metadata,
            warnings: warnings,
            llmUsage: llmUsage
        )
    }
    
    // MARK: - LLM Segmentation
    
    private func segmentWithLLM(
        script: String,
        config: LLMConfiguration,
        constraints: SegmentationConstraints
    ) async throws -> (segments: [CinematicSegment], usage: LLMUsageStats?, callCount: Int, warnings: [SegmentationWarning]) {
        
        let prompt = buildLLMPrompt(script: script, constraints: constraints)
        
        #if DEBUG
        LOG("🤖 [LLM] Sending segmentation request to \(config.provider.rawValue)")
        #endif
        
        let response = try await llmClient.complete(prompt: prompt, config: config)
        
        // Parse LLM response
        let parsed = try parseLLMResponse(response.content, script: script)
        
        // Build segments from parsed data
        var segments: [CinematicSegment] = []
        var currentToken = 0
        var warnings: [SegmentationWarning] = []
        
        for (index, boundary) in parsed.boundaries.enumerated() {
            let text = boundary.text
            let tokens = tokenEstimator.estimate(text)
            let duration = estimateDuration(text: text, targetDuration: constraints.targetDuration)
            
            let segment = CinematicSegment(
                id: UUID(),
                segmentIndex: index,
                text: text,
                estimatedTokens: tokens,
                estimatedDuration: duration,
                globalStartToken: currentToken,
                globalEndToken: currentToken + tokens,
                taxonomyHints: boundary.taxonomyHints,
                splitReason: boundary.reason,
                confidence: boundary.confidence,
                fallbackNotes: nil
            )
            
            segments.append(segment)
            currentToken += tokens
            
            // Check confidence
            if boundary.confidence < 0.6 {
                warnings.append(.lowConfidence(segmentIndex: index, confidence: boundary.confidence))
            }
            
            if boundary.ambiguous {
                warnings.append(.ambiguousBoundary(segmentIndex: index))
            }
        }
        
        let usage = LLMUsageStats(
            provider: config.provider.rawValue,
            model: config.model,
            promptTokens: response.usage.promptTokens,
            completionTokens: response.usage.completionTokens,
            totalTokens: response.usage.totalTokens,
            cost: response.usage.estimatedCost
        )
        
        return (segments, usage, 1, warnings)
    }
    
    private func buildLLMPrompt(script: String, constraints: SegmentationConstraints) -> String {
        """
        You are an expert film editor and cinematographer. Analyze the following script and divide it into cinematic segments suitable for AI video generation.

        CONSTRAINTS:
        - Maximum segments: \(constraints.maxSegments)
        - Maximum tokens per segment: \(constraints.maxTokensPerSegment)
        - Target duration per segment: \(constraints.targetDuration) seconds
        - Duration range: \(constraints.minDuration)-\(constraints.maxDuration) seconds

        SCRIPT:
        \(script)

        INSTRUCTIONS:
        1. Identify natural cinematic boundaries based on:
           - Scene changes (location, time, action)
           - Pacing shifts (slow to fast, calm to tense)
           - Narrative beats (introduction, conflict, resolution)
           - Visual transitions (cuts, fades, dissolves)

        2. For each segment, provide:
           - The exact text of the segment
           - Reason for the split (e.g., "scene change", "pacing shift", "dialogue break")
           - Confidence in the boundary (0.0-1.0)
           - Taxonomy hints: camera angle, scene type, emotion, pacing, visual complexity, transition type

        3. Ensure segments respect token and duration constraints
        4. Maintain chronological flow
        5. Mark ambiguous boundaries

        OUTPUT FORMAT (valid JSON):
        {
          "boundaries": [
            {
              "text": "segment text here",
              "reason": "scene change from interior to exterior",
              "confidence": 0.95,
              "ambiguous": false,
              "taxonomyHints": {
                "cameraAngle": "wide",
                "sceneType": "exterior",
                "emotion": "calm",
                "pacing": "slow",
                "visualComplexity": "moderate",
                "transitionType": "cut"
              }
            }
          ]
        }

        Return ONLY valid JSON. Do not include any other text.
        """
    }
    
    // MARK: - Duration-Based Segmentation
    
    private func segmentByDuration(script: String, constraints: SegmentationConstraints) -> [CinematicSegment] {
        #if DEBUG
        LOG("⏱️  [segmentByDuration] Starting...")
        LOG("   - Target duration per segment: \(constraints.targetDuration)s")
        #endif
        
        // ~150 words per minute of speech = ~2.5 words per second
        let wordsPerSecond = 2.5
        let targetWords = Int(constraints.targetDuration * wordsPerSecond)
        
        #if DEBUG
        LOG("   - Target words per segment: \(targetWords)")
        #endif
        
        let words = script.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        #if DEBUG
        LOG("   - Total words in script: \(words.count)")
        LOG("   - Estimated segments: ~\(words.count / max(targetWords, 1))")
        #endif
        
        var segments: [CinematicSegment] = []
        var currentChunk: [String] = []
        var currentToken = 0
        var segmentIndex = 0
        
        for word in words {
            currentChunk.append(word)
            
            if currentChunk.count >= targetWords || word == words.last {
                let text = currentChunk.joined(separator: " ")
                let tokens = tokenEstimator.estimate(text)
                let duration = Double(currentChunk.count) / wordsPerSecond
                
                #if DEBUG
                if segmentIndex < 3 {
                    LOG("   [Segment \(segmentIndex + 1)] \(currentChunk.count) words, \(tokens) tokens, \(String(format: "%.1f", duration))s")
                }
                #endif
                
                let segment = CinematicSegment(
                    id: UUID(),
                    segmentIndex: segmentIndex,
                    text: text,
                    estimatedTokens: tokens,
                    estimatedDuration: duration,
                    globalStartToken: currentToken,
                    globalEndToken: currentToken + tokens,
                    taxonomyHints: .empty,
                    splitReason: "duration-based split",
                    confidence: 0.7,
                    fallbackNotes: "Fallback: duration-based segmentation"
                )
                
                segments.append(segment)
                currentToken += tokens
                segmentIndex += 1
                currentChunk = []
            }
        }
        
        #if DEBUG
        LOG("✅ [segmentByDuration] Created \(segments.count) segments")
        #endif
        
        return segments
    }
    
    // MARK: - Even Split Segmentation
    
    private func segmentEvenly(script: String, constraints: SegmentationConstraints) -> [CinematicSegment] {
        let totalTokens = tokenEstimator.estimate(script)
        let targetSegments = min(constraints.maxSegments, max(1, totalTokens / constraints.maxTokensPerSegment))
        let tokensPerSegment = totalTokens / targetSegments
        
        let words = script.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let wordsPerSegment = words.count / targetSegments
        
        var segments: [CinematicSegment] = []
        var currentToken = 0
        
        for i in 0..<targetSegments {
            let start = i * wordsPerSegment
            let end = min((i + 1) * wordsPerSegment, words.count)
            let segmentWords = Array(words[start..<end])
            let text = segmentWords.joined(separator: " ")
            let tokens = tokenEstimator.estimate(text)
            let duration = estimateDuration(text: text, targetDuration: constraints.targetDuration)
            
            let segment = CinematicSegment(
                id: UUID(),
                segmentIndex: i,
                text: text,
                estimatedTokens: tokens,
                estimatedDuration: duration,
                globalStartToken: currentToken,
                globalEndToken: currentToken + tokens,
                taxonomyHints: .empty,
                splitReason: "even split",
                confidence: 0.8,
                fallbackNotes: "Even distribution split"
            )
            
            segments.append(segment)
            currentToken += tokens
        }
        
        return segments
    }
    
    // MARK: - Constraint Enforcement
    
    private func enforceConstraints(
        segments: [CinematicSegment],
        constraints: SegmentationConstraints,
        warnings: inout [SegmentationWarning],
        constraintsViolated: inout [String]
    ) throws -> [CinematicSegment] {
        
        var adjustedSegments = segments
        
        // Check segment count
        if adjustedSegments.count > constraints.maxSegments {
            warnings.append(.tooManySegments(count: adjustedSegments.count, limit: constraints.maxSegments))
            constraintsViolated.append("maxSegments")
            
            if constraints.allowAutoAdjustment {
                adjustedSegments = mergeSegments(adjustedSegments, targetCount: constraints.maxSegments)
                warnings.append(.autoAdjusted(description: "Merged to \(constraints.maxSegments) segments"))
            } else if constraints.enforceStrictLimits {
                throw SegmentationError.constraintViolationUnresolvable("Too many segments and auto-adjustment disabled")
            }
        }
        
        // Check token limits
        for (index, segment) in adjustedSegments.enumerated() {
            if segment.estimatedTokens > constraints.maxTokensPerSegment {
                warnings.append(.tokenLimitExceeded(
                    segmentIndex: index,
                    tokens: segment.estimatedTokens,
                    limit: constraints.maxTokensPerSegment
                ))
                constraintsViolated.append("maxTokensPerSegment[\(index)]")
                
                if constraints.allowAutoAdjustment {
                    let truncated = tokenEstimator.truncate(segment.text, maxTokens: constraints.maxTokensPerSegment)
                    adjustedSegments[index] = CinematicSegment(
                        id: segment.id,
                        segmentIndex: segment.segmentIndex,
                        text: truncated,
                        estimatedTokens: constraints.maxTokensPerSegment,
                        estimatedDuration: segment.estimatedDuration,
                        globalStartToken: segment.globalStartToken,
                        globalEndToken: segment.globalStartToken + constraints.maxTokensPerSegment,
                        taxonomyHints: segment.taxonomyHints,
                        splitReason: segment.splitReason,
                        confidence: segment.confidence * 0.8,
                        fallbackNotes: "Truncated to fit token limit"
                    )
                    warnings.append(.autoAdjusted(description: "Segment #\(index + 1) truncated"))
                } else if constraints.enforceStrictLimits {
                    throw SegmentationError.constraintViolationUnresolvable("Token limit exceeded and auto-adjustment disabled")
                }
            }
            
            // Check duration limits
            if segment.estimatedDuration > constraints.maxDuration {
                warnings.append(.durationExceeded(
                    segmentIndex: index,
                    duration: segment.estimatedDuration,
                    limit: constraints.maxDuration
                ))
                constraintsViolated.append("maxDuration[\(index)]")
            }
        }
        
        return adjustedSegments
    }
    
    private func mergeSegments(_ segments: [CinematicSegment], targetCount: Int) -> [CinematicSegment] {
        guard segments.count > targetCount else { return segments }
        
        var merged = segments
        
        while merged.count > targetCount {
            // Find two adjacent segments with lowest combined confidence to merge
            var minConfidencePairIndex = 0
            var minConfidence = Double.infinity
            
            for i in 0..<(merged.count - 1) {
                let pairConfidence = (merged[i].confidence + merged[i + 1].confidence) / 2
                if pairConfidence < minConfidence {
                    minConfidence = pairConfidence
                    minConfidencePairIndex = i
                }
            }
            
            // Merge the pair
            let first = merged[minConfidencePairIndex]
            let second = merged[minConfidencePairIndex + 1]
            
            let mergedSegment = CinematicSegment(
                id: UUID(),
                segmentIndex: first.segmentIndex,
                text: first.text + " " + second.text,
                estimatedTokens: first.estimatedTokens + second.estimatedTokens,
                estimatedDuration: first.estimatedDuration + second.estimatedDuration,
                globalStartToken: first.globalStartToken,
                globalEndToken: second.globalEndToken,
                taxonomyHints: first.taxonomyHints,
                splitReason: "merged segments",
                confidence: (first.confidence + second.confidence) / 2,
                fallbackNotes: "Auto-merged to meet segment limit"
            )
            
            merged.remove(at: minConfidencePairIndex)
            merged[minConfidencePairIndex] = mergedSegment
        }
        
        // Re-index
        return merged.enumerated().map { index, segment in
            CinematicSegment(
                id: segment.id,
                segmentIndex: index,
                text: segment.text,
                estimatedTokens: segment.estimatedTokens,
                estimatedDuration: segment.estimatedDuration,
                globalStartToken: segment.globalStartToken,
                globalEndToken: segment.globalEndToken,
                taxonomyHints: segment.taxonomyHints,
                splitReason: segment.splitReason,
                confidence: segment.confidence,
                fallbackNotes: segment.fallbackNotes
            )
        }
    }
    
    // MARK: - Helpers
    
    private func estimateDuration(text: String, targetDuration: Double) -> Double {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        return Double(wordCount) / 2.5  // ~2.5 words per second
    }
    
    private func parseLLMResponse(_ content: String, script: String) throws -> ParsedLLMResponse {
        // Clean response - remove markdown code blocks if present
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        }
        if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        if cleaned.hasSuffix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleaned.data(using: .utf8) else {
            throw SegmentationError.llmResponseInvalid("Cannot convert response to data")
        }
        
        let decoder = JSONDecoder()
        
        do {
            let response = try decoder.decode(ParsedLLMResponse.self, from: data)
            return response
        } catch {
            throw SegmentationError.llmResponseInvalid("JSON parsing failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - LLM Response Parsing

struct ParsedLLMResponse: Codable {
    let boundaries: [BoundaryInfo]
}

struct BoundaryInfo: Codable {
    let text: String
    let reason: String
    let confidence: Double
    let ambiguous: Bool
    let taxonomyHints: TaxonomyHints
}

// MARK: - Token Estimator

final class TokenEstimator {
    static let shared = TokenEstimator()
    private init() {}
    
    func estimate(_ text: String) -> Int {
        // GPT-style: ~4 characters per token
        max(1, text.count / 4)
    }
    
    func truncate(_ text: String, maxTokens: Int) -> String {
        let maxChars = maxTokens * 4
        guard text.count > maxChars else { return text }
        let index = text.index(text.startIndex, offsetBy: maxChars)
        return String(text[..<index]) + "..."
    }
}

// MARK: - LLM Client

final class LLMClient {
    static let shared = LLMClient()
    private init() {}
    
    func complete(prompt: String, config: LLMConfiguration) async throws -> LLMResponse {
        let url = URL(string: config.endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = config.timeoutSeconds
        
        let body: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": config.temperature,
            "max_tokens": 4000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SegmentationError.llmConnectionFailed("Invalid response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SegmentationError.llmConnectionFailed("HTTP \(httpResponse.statusCode): \(errorBody)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw SegmentationError.llmResponseInvalid("Missing content in response")
        }
        
        let usage = json?["usage"] as? [String: Any]
        let promptTokens = usage?["prompt_tokens"] as? Int ?? 0
        let completionTokens = usage?["completion_tokens"] as? Int ?? 0
        
        return LLMResponse(
            content: content,
            usage: UsageInfo(
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                totalTokens: promptTokens + completionTokens,
                estimatedCost: nil
            )
        )
    }
}

struct LLMResponse {
    let content: String
    let usage: UsageInfo
}

struct UsageInfo {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let estimatedCost: Double?
}

// MARK: - Semantic Expansion Processor

final class SemanticExpansionProcessor {
    static let shared = SemanticExpansionProcessor()
    
    private let llmClient: LLMClient
    private let tokenEstimator: TokenEstimator
    
    init(
        llmClient: LLMClient = .shared,
        tokenEstimator: TokenEstimator = .shared
    ) {
        self.llmClient = llmClient
        self.tokenEstimator = tokenEstimator
    }
    
    func expandSegments(
        _ segments: [CinematicSegment],
        config: LLMConfiguration,
        warnings: inout [SegmentationWarning]
    ) async throws -> (segments: [CinematicSegment], expandedCount: Int) {
        
        guard config.expansionConfig.isValid else {
            warnings.append(.llmFailed(reason: "Invalid expansion configuration"))
            return (segments, 0)
        }
        
        var expandedSegments = segments
        var expansionsPerformed = 0
        let expansionConfig = config.expansionConfig
        
        // Identify candidates for expansion
        let candidates = identifyExpansionCandidates(
            segments,
            config: expansionConfig
        )
        
        #if DEBUG
        LOG("   Expansion candidates: \(candidates.count)")
        #endif
        
        // Limit expansions for cost control
        let maxToExpand = min(candidates.count, expansionConfig.maxExpansions)
        
        if candidates.count > maxToExpand {
            warnings.append(.maxExpansionsReached(limit: maxToExpand))
        }
        
        // Expand each candidate
        for index in candidates.prefix(maxToExpand) {
            let segment = expandedSegments[index]
            
            do {
                let expanded = try await expandSegment(
                    segment,
                    config: config,
                    expansionConfig: expansionConfig
                )
                
                // Validate expansion
                if expanded.additionalTokens > expansionConfig.tokenBudgetPerSegment {
                    warnings.append(.expansionBudgetExceeded(
                        segmentIndex: index,
                        tokens: expanded.additionalTokens,
                        budget: expansionConfig.tokenBudgetPerSegment
                    ))
                }
                
                if expanded.llmConfidence < 0.6 {
                    warnings.append(.lowExpansionQuality(
                        segmentIndex: index,
                        confidence: expanded.llmConfidence
                    ))
                }
                
                // Update segment with expansion
                expandedSegments[index] = CinematicSegment(
                    id: segment.id,
                    segmentIndex: segment.segmentIndex,
                    text: segment.text,
                    estimatedTokens: segment.estimatedTokens,
                    estimatedDuration: segment.estimatedDuration,
                    globalStartToken: segment.globalStartToken,
                    globalEndToken: segment.globalEndToken,
                    taxonomyHints: expanded.enhancedHints ?? segment.taxonomyHints,
                    expandedPrompt: expanded,
                    splitReason: segment.splitReason,
                    confidence: segment.confidence,
                    fallbackNotes: segment.fallbackNotes
                )
                
                expansionsPerformed += 1
                
            } catch {
                warnings.append(.expansionFailed(
                    segmentIndex: index,
                    reason: error.localizedDescription
                ))
            }
        }
        
        return (expandedSegments, expansionsPerformed)
    }
    
    private func identifyExpansionCandidates(
        _ segments: [CinematicSegment],
        config: SemanticExpansionConfig
    ) -> [Int] {
        var candidates: [Int] = []
        
        for (index, segment) in segments.enumerated() {
            var shouldExpand = false
            
            // Check if segment is short
            if config.expandShortSegments {
                if segment.text.count < config.minLengthForExpansion {
                    shouldExpand = true
                }
            }
            
            // Check if segment is emotionally charged
            if config.expandEmotionalSegments {
                let emotionScore = detectEmotionalIntensity(segment.text)
                if emotionScore > config.emotionThreshold {
                    shouldExpand = true
                }
            }
            
            if shouldExpand {
                candidates.append(index)
            }
        }
        
        return candidates
    }
    
    
    private func expandSegment(
        _ segment: CinematicSegment,
        config: LLMConfiguration,
        expansionConfig: SemanticExpansionConfig
    ) async throws -> ExpandedPrompt {
        
        let prompt = buildExpansionPrompt(
            baseText: segment.text,
            expansionConfig: expansionConfig,
            existingHints: segment.taxonomyHints
        )
        
        // Use higher temperature for creative expansion
        var expansionLLMConfig = config
        expansionLLMConfig.temperature = expansionConfig.expansionTemperature
        
        let response = try await llmClient.complete(
            prompt: prompt,
            config: expansionLLMConfig
        )
        
        // Parse expansion response
        let parsed = try parseExpansionResponse(response.content)
        
        // Calculate additional tokens
        let baseTokens = tokenEstimator.estimate(segment.text)
        let expandedTokens = tokenEstimator.estimate(parsed.expandedText)
        let additionalTokens = expandedTokens - baseTokens
        
        // Detect emotion in original text
        let emotionScore = detectEmotionalIntensity(segment.text)
        
        // Determine expansion reason
        let reason: String
        if segment.text.count < expansionConfig.minLengthForExpansion {
            reason = "Short segment (\(segment.text.count) chars)"
        } else if emotionScore > expansionConfig.emotionThreshold {
            reason = "Emotionally charged (score: \(String(format: "%.2f", emotionScore)))"
        } else {
            reason = "Selected for enhancement"
        }
        
        return ExpandedPrompt(
            text: parsed.expandedText,
            additionalTokens: additionalTokens,
            expansionReason: reason,
            emotionScore: emotionScore,
            expansionStyle: expansionConfig.expansionStyle.rawValue,
            llmConfidence: parsed.confidence,
            enhancedHints: parsed.enhancedHints
        )
    }
    
    private func buildExpansionPrompt(
        baseText: String,
        expansionConfig: SemanticExpansionConfig,
        existingHints: TaxonomyHints
    ) -> String {
        """
        You are an expert cinematographer and creative writer. Expand the following prompt into a vivid, expressive, cinematic description suitable for AI video generation.

        ORIGINAL PROMPT:
        \(baseText)

        EXPANSION STYLE:
        \(expansionConfig.expansionStyle.promptGuidance)

        CONSTRAINTS:
        - Target expansion: ~\(expansionConfig.tokenBudgetPerSegment) additional tokens
        - Preserve core meaning and intent
        - Add sensory details, visual richness, and cinematic language
        - Enhance emotional resonance if present
        - Suggest improved camera angles and framing
        - Maintain compatibility with video generation

        EXISTING TAXONOMY HINTS (enhance these):
        \(formatTaxonomyHints(existingHints))

        OUTPUT FORMAT (valid JSON):
        {
          "expandedText": "Your expanded, vivid prompt here",
          "confidence": 0.95,
          "enhancedHints": {
            "cameraAngle": "improved or suggested camera angle",
            "sceneType": "enhanced scene type",
            "emotion": "detected or enhanced emotion",
            "pacing": "suggested pacing",
            "visualComplexity": "complexity assessment",
            "transitionType": "recommended transition"
          },
          "analysisNotes": "Brief explanation of your expansion choices"
        }

        Return ONLY valid JSON. Focus on cinematic quality and visual storytelling.
        """
    }
    
    private func formatTaxonomyHints(_ hints: TaxonomyHints) -> String {
        var parts: [String] = []
        if let angle = hints.cameraAngle { parts.append("Camera: \(angle)") }
        if let scene = hints.sceneType { parts.append("Scene: \(scene)") }
        if let emotion = hints.emotion { parts.append("Emotion: \(emotion)") }
        if let pacing = hints.pacing { parts.append("Pacing: \(pacing)") }
        return parts.isEmpty ? "None provided" : parts.joined(separator: ", ")
    }
    
    private func parseExpansionResponse(_ content: String) throws -> ParsedExpansion {
        // Clean response - remove markdown if present
        var cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        }
        if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        if cleaned.hasSuffix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleaned.data(using: .utf8) else {
            throw SegmentationError.llmResponseInvalid("Cannot convert expansion response to data")
        }
        
        let decoder = JSONDecoder()
        
        do {
            let response = try decoder.decode(ParsedExpansion.self, from: data)
            return response
        } catch {
            throw SegmentationError.llmResponseInvalid("Expansion JSON parsing failed: \(error.localizedDescription)")
        }
    }
    
    private func detectEmotionalIntensity(_ text: String) -> Double {
        // Simple emotion detection based on keywords
        // In production, this could use more sophisticated NLP or call LLM
        
        let lowercased = text.lowercased()
        
        let highEmotionWords = [
            "scream", "shout", "cry", "tears", "rage", "fury", "terror", "horror",
            "love", "passion", "hate", "despair", "agony", "ecstasy", "panic",
            "violent", "explosive", "devastating", "overwhelming", "intense"
        ]
        
        let mediumEmotionWords = [
            "angry", "sad", "happy", "excited", "worried", "nervous", "afraid",
            "surprised", "shocked", "confused", "frustrated", "anxious", "tense"
        ]
        
        var score = 0.0
        
        for word in highEmotionWords {
            if lowercased.contains(word) {
                score += 0.3
            }
        }
        
        for word in mediumEmotionWords {
            if lowercased.contains(word) {
                score += 0.15
            }
        }
        
        // Check for punctuation intensity
        let exclamationCount = text.filter { $0 == "!" }.count
        let questionCount = text.filter { $0 == "?" }.count
        score += Double(exclamationCount) * 0.1
        score += Double(questionCount) * 0.05
        
        // Check for capitalization (shouting)
        let uppercaseRatio = Double(text.filter { $0.isUppercase }.count) / Double(max(text.count, 1))
        if uppercaseRatio > 0.5 {
            score += 0.2
        }
        
        return min(score, 1.0)  // Cap at 1.0
    }
}

// MARK: - Expansion Response Parsing

struct ParsedExpansion: Codable {
    let expandedText: String
    let confidence: Double
    let enhancedHints: TaxonomyHints?
    let analysisNotes: String?
}

// MARK: - Convenience API

extension SegmentingModule {
    /// Convenience method for quick segmentation with defaults
    static func quickSegment(
        script: String,
        apiKey: String,
        mode: SegmentationMode = .hybrid
    ) async throws -> [CinematicSegment] {
        let module = SegmentingModule()
        let config = LLMConfiguration(apiKey: apiKey)
        let result = try await module.segment(
            script: script,
            mode: mode,
            constraints: .default,
            llmConfig: config
        )
        return result.segments
    }
}
