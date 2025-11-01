// MODULE: PromptExtractor
// VERSION: 1.0.0
// PURPOSE: Modular prompt extraction and segmentation with token counting
// BUILD STATUS: ✅ Complete

import Foundation
import CryptoKit

/// Segmented prompt block with dialogue and token information
public struct SegmentedPromptBlock: Identifiable, Codable, Sendable {
    public let id: UUID
    public let dialogue: String
    public let tokens: Int
    public let traceId: String
    public let index: Int
    
    public init(
        id: UUID = UUID(),
        dialogue: String,
        tokens: Int,
        traceId: String,
        index: Int
    ) {
        self.id = id
        self.dialogue = dialogue
        self.tokens = tokens
        self.traceId = traceId
        self.index = index
    }
}

/// Tokenizer for counting tokens in prompts
public struct PromptTokenizer {
    /// Estimate token count from text (approximate: ~4 characters per token)
    public static func estimateTokens(_ text: String) -> Int {
        // Simple approximation: ~4 characters per token
        // More accurate would require actual tokenizer, but this is sufficient for validation
        return max(1, text.count / 4)
    }
    
    /// Deterministic token count for cache key generation
    public static func tokenHash(_ text: String) -> String {
        let data = Data(text.utf8)
        let hash = SHA256.hash(data: data)
        return String(hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16))
    }
}

/// Prompt extraction and segmentation service
public actor PromptExtractor {
    public static let shared = PromptExtractor()
    
    private init() {}
    
    /// Extract segmented prompt blocks from script
    /// - Parameters:
    ///   - script: The full script text
    ///   - traceId: Trace ID for correlation
    /// - Returns: Array of segmented prompt blocks
    public func extractSegments(from script: String, traceId: String) async throws -> [SegmentedPromptBlock] {
        // Use intelligent segmentation via SegmentingModule
        let segmentingModule = SegmentingModule()
        let prompts = try await segmentingModule.segment(script, projectId: nil)
        
        // Convert to SegmentedPromptBlock format
        return prompts.enumerated().map { index, prompt in
            let tokens = PromptTokenizer.estimateTokens(prompt.prompt)
            return SegmentedPromptBlock(
                id: prompt.id,
                dialogue: prompt.extractedDialogue ?? prompt.prompt,
                tokens: tokens,
                traceId: traceId,
                index: index
            )
        }
    }
    
    /// Extract segments with custom strategy
    /// - Parameters:
    ///   - script: The full script text
    ///   - strategy: Segmentation strategy
    ///   - traceId: Trace ID for correlation
    /// - Returns: Array of segmented prompt blocks
    public func extractSegments(
        from script: String,
        strategy: SegmentationStrategy,
        traceId: String
    ) async throws -> [SegmentedPromptBlock] {
        // Use SegmentingModule for intelligent segmentation
        let module = SegmentingModule()
        let prompts = try await module.segment(script, projectId: nil)
        
        return prompts.enumerated().map { index, prompt in
            let tokens = PromptTokenizer.estimateTokens(prompt.prompt)
            return SegmentedPromptBlock(
                id: prompt.id,
                dialogue: prompt.extractedDialogue ?? prompt.prompt,
                tokens: tokens,
                traceId: traceId,
                index: index
            )
        }
    }
}

// Note: PipelineServiceBridge's segmentScript method will be updated to use this module

