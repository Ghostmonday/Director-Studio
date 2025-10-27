// MODULE: AIClipDurator
// VERSION: 1.0.0
// PURPOSE: AI service for auto-detecting optimal clip durations

import Foundation

class AIClipDurator {
    static let shared = AIClipDurator()
    
    private let deepSeekService = DeepSeekAIService()
    
    private init() {}
    
    /// Analyze prompts and return suggested durations in seconds
    func detectDurations(for prompts: [String]) async throws -> [Int] {
        let systemPrompt = """
        You are a video duration analyzer. Given video clip prompts, suggest optimal durations in seconds.
        
        Consider:
        - Action complexity and pacing
        - Dialog length if present
        - Scene transitions
        - Visual detail requirements
        - Viewer engagement
        
        Respond with ONLY a comma-separated list of integers (seconds).
        Example: 3,5,4,6,3
        
        Guidelines:
        - Minimum: 2 seconds (quick cuts)
        - Maximum: 10 seconds (longer scenes)
        - Default to 3-5 seconds for most clips
        - Action scenes: 2-4 seconds
        - Dialog scenes: 4-8 seconds
        - Establishing shots: 3-6 seconds
        """
        
        let userPrompt = prompts.enumerated().map { index, prompt in
            "Clip \(index + 1): \(prompt)"
        }.joined(separator: "\n\n")
        
        let response = try await deepSeekService.processText(
            prompt: userPrompt,
            systemPrompt: systemPrompt
        )
        
        // Parse the response
        let durations = parseDurations(from: response, count: prompts.count)
        
        return durations
    }
    
    private func parseDurations(from response: String, count: Int) -> [Int] {
        // Clean the response and extract numbers
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = cleaned.split(separator: ",").compactMap { component in
            Int(component.trimmingCharacters(in: .whitespaces))
        }
        
        // Validate and ensure we have the right count
        var durations = components
        
        // If we got fewer durations than prompts, fill with default (3 seconds)
        while durations.count < count {
            durations.append(3)
        }
        
        // If we got more, truncate
        if durations.count > count {
            durations = Array(durations.prefix(count))
        }
        
        // Ensure all durations are within bounds
        durations = durations.map { duration in
            max(2, min(10, duration))
        }
        
        return durations
    }
}
