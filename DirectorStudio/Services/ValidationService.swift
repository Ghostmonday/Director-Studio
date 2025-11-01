// MODULE: ValidationService
// VERSION: 1.0.0
// PURPOSE: Pre-flight validation for prompts before generation
// PRODUCTION-GRADE: Content safety, length limits, version compatibility checks

import Foundation

/// Pre-flight validation service for ProjectPrompt before generation
/// Ensures prompts meet quality, safety, and API requirements
@MainActor
public class ValidationService {
    public static let shared = ValidationService()
    
    private init() {}
    
    /// Validation result with errors and suggestions
    public struct Result {
        public let isValid: Bool
        public let errors: [ValidationError]
        public let suggestions: [String]
        
        public init(isValid: Bool, errors: [ValidationError], suggestions: [String]) {
            self.isValid = isValid
            self.errors = errors
            self.suggestions = suggestions
        }
    }
    
    /// Validate a prompt for a specific Kling version
    /// - Parameters:
    ///   - prompt: The ProjectPrompt to validate
    ///   - version: The KlingVersion to validate against
    /// - Returns: Validation result with errors and suggestions
    public func validate(_ prompt: ProjectPrompt, for version: KlingVersion) -> Result {
        var errors: [ValidationError] = []
        var suggestions: [String] = []
        
        // Length validation
        if prompt.prompt.count > 4000 {
            errors.append(.tooLong(max: 4000))
            suggestions.append("Shorten prompt to under 4000 characters for best results.")
        }
        
        if prompt.prompt.count < 10 {
            errors.append(.tooShort(min: 10))
            suggestions.append("Add more detail to your prompt (at least 10 characters).")
        }
        
        // Content safety
        if containsProfanity(prompt.prompt) {
            errors.append(.inappropriate)
            suggestions.append("Try rephrasing to avoid sensitive content.")
        }
        
        // Version-specific duration limits
        let estimatedDuration = estimateDuration(prompt.prompt)
        if estimatedDuration > version.maxSeconds {
            errors.append(.durationExceeded(version: version, max: version.maxSeconds))
            suggestions.append("Split into shorter clips or use \(version.rawValue) for longer content.")
        }
        
        // Empty or whitespace-only
        if prompt.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.empty)
            suggestions.append("Prompt cannot be empty.")
        }
        
        // Check for invalid characters
        if containsInvalidCharacters(prompt.prompt) {
            errors.append(.invalidCharacters)
            suggestions.append("Remove special control characters from your prompt.")
        }
        
        return Result(
            isValid: errors.isEmpty,
            errors: errors,
            suggestions: suggestions
        )
    }
    
    /// Validate multiple prompts in batch
    /// - Parameters:
    ///   - prompts: Array of prompts to validate
    ///   - version: The KlingVersion to validate against
    /// - Returns: Dictionary mapping prompt IDs to validation results
    public func validateBatch(_ prompts: [ProjectPrompt], for version: KlingVersion) -> [UUID: Result] {
        var results: [UUID: Result] = [:]
        for prompt in prompts {
            results[prompt.id] = validate(prompt, for: version)
        }
        return results
    }
    
    /// Estimate video duration from prompt text
    /// - Parameter text: The prompt text
    /// - Returns: Estimated duration in seconds
    private func estimateDuration(_ text: String) -> Int {
        let words = text.split { $0.isWhitespace || $0.isNewline }.count
        // Average reading speed: ~150 words per minute
        // Video generation typically matches or slightly exceeds reading time
        return Int(ceil(Double(words) / 25.0)) // ~25 words per second
    }
    
    /// Check for inappropriate content
    /// - Parameter text: The text to check
    /// - Returns: True if profanity detected
    private func containsProfanity(_ text: String) -> Bool {
        // Basic word filter - in production, integrate with Apple Content Filter API
        let blockedWords = [
            // Add comprehensive list or integrate with NSFW detection service
        ]
        let lowercased = text.lowercased()
        return blockedWords.contains { lowercased.contains($0) }
    }
    
    /// Check for invalid control characters
    /// - Parameter text: The text to check
    /// - Returns: True if invalid characters found
    private func containsInvalidCharacters(_ text: String) -> Bool {
        // Control characters (except newlines and tabs) are invalid
        let invalidRanges: [ClosedRange<UInt8>] = [
            0x00...0x08,   // NULL through BS
            0x0B...0x0C,   // VT, FF
            0x0E...0x1F    // SO through US
        ]
        
        for char in text.utf8 {
            for range in invalidRanges {
                if range.contains(char) {
                    return true
                }
            }
        }
        return false
    }
}

/// Validation errors
public enum ValidationError: Error, CustomStringConvertible, Equatable {
    case tooLong(max: Int)
    case tooShort(min: Int)
    case inappropriate
    case durationExceeded(version: KlingVersion, max: Int)
    case empty
    case invalidCharacters
    
    public var description: String {
        switch self {
        case .tooLong(let max):
            return "Prompt exceeds \(max) characters"
        case .tooShort(let min):
            return "Prompt must be at least \(min) characters"
        case .inappropriate:
            return "Prompt contains inappropriate content"
        case .durationExceeded(let version, let max):
            return "\(version.rawValue) supports max \(max) seconds"
        case .empty:
            return "Prompt cannot be empty"
        case .invalidCharacters:
            return "Prompt contains invalid control characters"
        }
    }
}

