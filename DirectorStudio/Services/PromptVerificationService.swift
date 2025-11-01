// MODULE: PromptVerificationService
// VERSION: 1.0.0
// PURPOSE: Verifies continuity, dialogue logic, and prompt consistency using DeepSeek AI
// PRODUCTION-GRADE: Actor-isolated, structured JSON parsing, error handling

import Foundation
import os.log

/// A service that verifies continuity, dialogue logic, and prompt consistency across a list of prompts
/// Uses DeepSeek AI to analyze prompts for story coherence, dialogue continuity, and logical flow
public actor PromptVerificationService {
    private let deepSeekService: DeepSeekAIService
    private let logger = Logger(subsystem: "DirectorStudio.Verification", category: "PromptVerification")
    
    public static let shared = PromptVerificationService()
    
    private init() {
        self.deepSeekService = DeepSeekAIService()
    }
    
    /// Verification result for a single prompt
    public struct VerificationResult: Identifiable, Codable, Sendable {
        public let id: UUID
        public let index: Int
        public let issues: [String]
        public let isBlocking: Bool
        
        public init(id: UUID = UUID(), index: Int, issues: [String], isBlocking: Bool) {
            self.id = id
            self.index = index
            self.issues = issues
            self.isBlocking = isBlocking
        }
    }
    
    /// Verifies a sequence of prompts for dialogue and continuity logic
    /// - Parameter prompts: An array of strings representing segmented prompts
    /// - Returns: An array of `VerificationResult` with any issues found
    /// - Throws: API errors or parsing errors
    public func verify(prompts: [String]) async throws -> [VerificationResult] {
        guard !prompts.isEmpty else {
            logger.debug("⚠️ Empty prompts array provided")
            return []
        }
        
        logger.debug("🔍 Starting verification for \(prompts.count) prompts")
        
        // Compose verification input
        let numberedPrompts = prompts.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n\n")
        
        let systemDirective = """
        You are a professional film continuity editor analyzing a sequence of video generation prompts.
        Your job is to identify issues that would break the story flow, confuse viewers, or create inconsistencies.
        
        Check for:
        1. **Dialogue Continuity**: Are character names consistent? Do dialogue lines match their speakers?
        2. **Logical Flow**: Do scenes transition smoothly? Are there abrupt jumps that don't make sense?
        3. **Visual Continuity**: Do descriptions match between adjacent prompts? (e.g., character positions, settings)
        4. **Story Coherence**: Does the narrative make sense? Are there plot holes or contradictions?
        5. **Speaker Identity**: Are characters speaking consistently? No sudden character swaps?
        
        Return ONLY valid JSON array. Each object must have:
        - "index": Int (1-based prompt number)
        - "issues": Array of Strings (specific problems found)
        - "isBlocking": Bool (true if this prevents generation, false if just a warning)
        
        If no issues found for a prompt, include it with empty issues array.
        """
        
        let userPrompt = """
        Analyze these prompts for continuity and logic errors:
        
        \(numberedPrompts)
        
        Return JSON array with verification results. Only include prompts that have issues.
        """
        
        // Call DeepSeek API
        let response = try await callDeepSeek(systemPrompt: systemDirective, userPrompt: userPrompt)
        
        // Parse and return results
        let results = parseResults(response, totalPrompts: prompts.count)
        
        let issueCount = results.reduce(0) { $0 + $1.issues.count }
        let blockingCount = results.filter { $0.isBlocking }.count
        
        logger.debug("✅ Verification complete: \(issueCount) issues found (\(blockingCount) blocking)")
        
        return results
    }
    
    /// Call DeepSeek API with system and user prompts
    /// - Parameters:
    ///   - systemPrompt: The system directive
    ///   - userPrompt: The user input with prompts to verify
    /// - Returns: JSON string response from DeepSeek
    /// - Throws: API errors
    private func callDeepSeek(systemPrompt: String, userPrompt: String) async throws -> String {
        logger.debug("📤 Calling DeepSeek API for prompt verification...")
        
        do {
            let response = try await deepSeekService.processText(
                prompt: userPrompt,
                systemPrompt: systemPrompt
            )
            
            logger.debug("📥 DeepSeek response received: \(response.prefix(200))...")
            return response
        } catch {
            logger.error("❌ DeepSeek API call failed: \(error.localizedDescription)")
            throw VerificationError.apiError("Failed to verify prompts: \(error.localizedDescription)")
        }
    }
    
    /// Parses the DeepSeek JSON response into `VerificationResult`s
    /// - Parameters:
    ///   - json: The JSON string response from DeepSeek
    ///   - totalPrompts: Total number of prompts being verified
    /// - Returns: Array of verification results
    private func parseResults(_ json: String, totalPrompts: Int) -> [VerificationResult] {
        // Clean JSON - remove markdown code blocks if present
        var cleanedJSON = json.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks
        if cleanedJSON.hasPrefix("```json") {
            cleanedJSON = String(cleanedJSON.dropFirst(7))
        } else if cleanedJSON.hasPrefix("```") {
            cleanedJSON = String(cleanedJSON.dropFirst(3))
        }
        
        if cleanedJSON.hasSuffix("```") {
            cleanedJSON = String(cleanedJSON.dropLast(3))
        }
        
        cleanedJSON = cleanedJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to extract JSON array from response if it's embedded in text
        if let jsonStart = cleanedJSON.range(of: "["),
           let jsonEnd = cleanedJSON.range(of: "]", options: .backwards, range: jsonStart.upperBound..<cleanedJSON.endIndex) {
            cleanedJSON = String(cleanedJSON[jsonStart.lowerBound...jsonEnd.upperBound])
        }
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            logger.error("❌ Failed to convert JSON string to data")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let results = try decoder.decode([VerificationResult].self, from: data)
            
            // Validate indices are within bounds
            let validatedResults = results.filter { result in
                result.index >= 1 && result.index <= totalPrompts
            }
            
            if validatedResults.count != results.count {
                logger.warning("⚠️ Some verification results had invalid indices and were filtered")
            }
            
            return validatedResults
        } catch {
            logger.error("❌ Failed to parse verification results: \(error.localizedDescription)")
            logger.debug("Raw JSON was: \(cleanedJSON.prefix(500))")
            
            // Try to provide helpful error
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    logger.error("Missing key: \(key.stringValue) at \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    logger.error("Type mismatch: expected \(type) at \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    logger.error("Value not found: \(type) at \(context.codingPath)")
                case .dataCorrupted(let context):
                    logger.error("Data corrupted at \(context.codingPath): \(context.debugDescription)")
                @unknown default:
                    logger.error("Unknown decoding error: \(decodingError)")
                }
            }
            
            return []
        }
    }
    
    /// Quick verification - returns true if all prompts pass verification
    /// - Parameter prompts: Array of prompts to verify
    /// - Returns: True if no blocking issues found
    /// - Throws: API errors
    public func verifyQuick(prompts: [String]) async throws -> Bool {
        let results = try await verify(prompts: prompts)
        return !results.contains { $0.isBlocking }
    }
    
    /// Get summary of verification issues
    /// - Parameter prompts: Array of prompts to verify
    /// - Returns: Summary string with issue counts
    /// - Throws: API errors
    public func getVerificationSummary(prompts: [String]) async throws -> String {
        let results = try await verify(prompts: prompts)
        
        let totalIssues = results.reduce(0) { $0 + $1.issues.count }
        let blockingIssues = results.filter { $0.isBlocking }.count
        let warningIssues = results.count - blockingIssues
        
        if totalIssues == 0 {
            return "✅ All prompts verified successfully - no issues found"
        }
        
        var summary = "⚠️ Verification found \(totalIssues) issue(s)"
        if blockingIssues > 0 {
            summary += " (\(blockingIssues) blocking)"
        }
        if warningIssues > 0 {
            summary += " (\(warningIssues) warnings)"
        }
        
        return summary
    }
}

/// Verification-specific errors
public enum VerificationError: LocalizedError, Sendable {
    case apiError(String)
    case parsingError(String)
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "API Error: \(message)"
        case .parsingError(let message):
            return "Parsing Error: \(message)"
        case .invalidResponse:
            return "Invalid response from verification service"
        }
    }
}

