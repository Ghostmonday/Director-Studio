// MODULE: AutoPacingEngine
// VERSION: 1.0.0
// PURPOSE: Adjust clip duration based on emotional beats
// BUILD STATUS: ✅ Complete

import Foundation

/// Auto-pacing engine for emotional rhythm
public actor AutoPacingEngine {
    public static let shared = AutoPacingEngine()
    
    private init() {}
    
    /// Analyze script and suggest optimal clip durations
    /// - Parameter script: Script text to analyze
    /// - Returns: Array of suggested durations per segment
    public func analyzePacing(script: String) async -> [PacingSegment] {
        let sentences = script.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var segments: [PacingSegment] = []
        
        for (index, sentence) in sentences.enumerated() {
            let emotionalIntensity = calculateEmotionalIntensity(sentence)
            let suggestedDuration = mapIntensityToDuration(intensity: emotionalIntensity)
            
            segments.append(PacingSegment(
                index: index,
                text: sentence,
                suggestedDuration: suggestedDuration,
                intensity: emotionalIntensity,
                beatType: detectBeatType(sentence)
            ))
        }
        
        return segments
    }
    
    /// Calculate emotional intensity (0.0 - 1.0)
    private func calculateEmotionalIntensity(_ text: String) -> Float {
        let lowercase = text.lowercased()
        
        // High intensity keywords
        let highIntensity = ["explosive", "dramatic", "intense", "thrilling", "shocking", "powerful"]
        let mediumIntensity = ["emotional", "moving", "significant", "important", "moment"]
        let lowIntensity = ["calm", "peaceful", "gentle", "soft", "quiet"]
        
        var score: Float = 0.5 // Base
        
        if highIntensity.contains(where: lowercase.contains) {
            score += 0.3
        }
        if mediumIntensity.contains(where: lowercase.contains) {
            score += 0.15
        }
        if lowIntensity.contains(where: lowercase.contains) {
            score -= 0.2
        }
        
        // Punctuation intensity
        let exclamationCount = text.filter { $0 == "!" }.count
        score += Float(exclamationCount) * 0.1
        
        // Sentence length factor (shorter = higher intensity)
        let lengthFactor = max(0, 1.0 - Float(text.count) / 100.0)
        score += lengthFactor * 0.2
        
        return max(0.0, min(1.0, score))
    }
    
    /// Map intensity to duration
    private func mapIntensityToDuration(intensity: Float) -> TimeInterval {
        // High intensity = shorter (quick cuts)
        // Low intensity = longer (lingering shots)
        let baseDuration: TimeInterval = 5.0
        let variation: TimeInterval = 3.0
        
        return baseDuration + (variation * (1.0 - Double(intensity)))
    }
    
    /// Detect beat type (action, dialogue, transition, etc.)
    private func detectBeatType(_ text: String) -> BeatType {
        let lowercase = text.lowercased()
        
        if lowercase.contains("says") || lowercase.contains("said") || lowercase.contains("\"") {
            return .dialogue
        }
        if lowercase.contains("suddenly") || lowercase.contains("then") || lowercase.contains("finally") {
            return .action
        }
        if lowercase.contains("meanwhile") || lowercase.contains("later") || lowercase.contains("after") {
            return .transition
        }
        if lowercase.contains("feels") || lowercase.contains("thinks") || lowercase.contains("realizes") {
            return .emotional
        }
        
        return .narrative
    }
}

/// Pacing segment with duration recommendation
public struct PacingSegment: Identifiable, Sendable {
    public let id = UUID()
    public let index: Int
    public let text: String
    public let suggestedDuration: TimeInterval
    public let intensity: Float
    public let beatType: BeatType
}

/// Beat type for pacing analysis
public enum BeatType: String, Sendable {
    case action = "action"
    case dialogue = "dialogue"
    case transition = "transition"
    case emotional = "emotional"
    case narrative = "narrative"
}

