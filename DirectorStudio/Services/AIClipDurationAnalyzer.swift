// MODULE: AIClipDurationAnalyzer
// VERSION: 1.0.0
// PURPOSE: AI-powered clip duration selection (5 or 10 seconds) based on content analysis

import Foundation
import os.log

/// AI service that analyzes segment content to determine optimal duration (5 or 10 seconds)
@MainActor
public class AIClipDurationAnalyzer: ObservableObject {
    public static let shared = AIClipDurationAnalyzer()
    
    private let deepSeekService = DeepSeekAIService()
    private let logger = Logger(subsystem: "DirectorStudio", category: "AIClipDurationAnalyzer")
    
    private init() {}
    
    /// Analyze a segment and determine if it should be 5 or 10 seconds
    public func analyzeDuration(for segment: MultiClipSegment) async throws -> TimeInterval {
        logger.debug("🧠 Analyzing optimal duration for segment: \(segment.id)")
        
        let systemPrompt = """
        You are an expert video editor analyzing a script segment to determine optimal clip duration.
        
        TASK: Decide if this segment should be 5 or 10 seconds long.
        
        GUIDELINES FOR 5 SECONDS:
        - Simple actions or reactions
        - Single emotion or expression
        - Quick establishing shots
        - Fast-paced dialogue exchanges
        - Transitional moments
        - High energy or comedic beats
        
        GUIDELINES FOR 10 SECONDS:
        - Complex emotional moments
        - Multiple actions in sequence
        - Dialogue that needs time to breathe
        - Establishing atmosphere or mood
        - Character development moments
        - Scenic or contemplative shots
        
        Respond with ONLY "5" or "10" (the number of seconds).
        """
        
        let userPrompt = """
        Segment: "\(segment.text)"
        
        Determine if this should be 5 or 10 seconds.
        """
        
        do {
            let response = try await deepSeekService.processText(
                prompt: userPrompt,
                systemPrompt: systemPrompt
            )
            
            let duration: TimeInterval
            if response.trimmingCharacters(in: .whitespacesAndNewlines) == "5" {
                duration = 5.0
            } else {
                duration = 10.0 // Default to 10 if unclear
            }
            
            logger.debug("✅ AI determined duration: \(Int(duration))s")
            return duration
            
        } catch {
            logger.error("❌ Failed to analyze duration: \(error.localizedDescription)")
            // Default to 10 seconds on error
            return 10.0
        }
    }
    
    /// Batch analyze multiple segments with optional override
    public func analyzeDurations(
        for segments: [MultiClipSegment],
        defaultDuration: TimeInterval? = nil
    ) async throws -> [UUID: TimeInterval] {
        var durations: [UUID: TimeInterval] = [:]
        
        // If default duration is specified, use it for all
        if let defaultDuration = defaultDuration {
            logger.debug("Using default duration: \(Int(defaultDuration))s for all \(segments.count) segments")
            for segment in segments {
                durations[segment.id] = defaultDuration
            }
            return durations
        }
        
        // Otherwise, analyze each segment
        logger.debug("🧠 Analyzing durations for \(segments.count) segments...")
        
        for segment in segments {
            do {
                let duration = try await analyzeDuration(for: segment)
                durations[segment.id] = duration
            } catch {
                logger.error("Failed to analyze segment: \(error.localizedDescription)")
                durations[segment.id] = 10.0 // Default to 10s on error
            }
        }
        
        // Log summary
        let fiveSecCount = durations.values.filter { $0 == 5.0 }.count
        let tenSecCount = durations.values.filter { $0 == 10.0 }.count
        logger.debug("✅ Duration analysis complete: \(fiveSecCount) x 5s, \(tenSecCount) x 10s")
        
        return durations
    }
    
    /// Get a duration recommendation explanation
    public func explainDuration(for segment: MultiClipSegment, duration: TimeInterval) -> String {
        if duration == 5.0 {
            return "Quick moment - best as a 5 second clip"
        } else {
            return "Complex scene - needs 10 seconds to develop"
        }
    }
}

/// Extension for MultiClipSegmentCollection integration
extension MultiClipSegmentCollection {
    /// Apply AI-determined durations to all segments
    public func applyAIDurations() async throws {
        let analyzer = AIClipDurationAnalyzer.shared
        let durations = try await analyzer.analyzeDurations(for: segments)
        
        for (id, duration) in durations {
            if let index = segments.firstIndex(where: { $0.id == id }) {
                segments[index].duration = duration
            }
        }
    }
    
    /// Apply uniform duration (5 or 10) to all segments
    public func applyUniformDuration(_ duration: TimeInterval) {
        guard duration == 5.0 || duration == 10.0 else { return }
        
        for index in segments.indices {
            segments[index].duration = duration
        }
    }
}
