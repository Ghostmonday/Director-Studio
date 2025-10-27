// MODULE: MultiClipSegment
// VERSION: 1.0.0
// PURPOSE: Model for script segments with continuity tracking

import Foundation
import UIKit

/// Represents a segment of a script that will become a video clip
public struct MultiClipSegment: Identifiable, Equatable {
    public let id = UUID()
    public var text: String
    public var order: Int
    public var duration: TimeInterval
    public var isEnabled: Bool = true
    
    // Continuity tracking
    public var continuityNote: String?
    public var previousSegmentId: UUID?
    public var nextSegmentId: UUID?
    public var lastFrameImage: UIImage?
    public var lastFrameData: Data?
    
    // Generation state
    public var generationState: GenerationState = .idle
    public var generatedClipId: UUID?
    public var progress: Double = 0.0
    public var error: String?
    
    public init(text: String, order: Int, duration: TimeInterval = 5.0) {
        self.text = text
        self.order = order
        self.duration = duration
    }
    
    public enum GenerationState: Equatable {
        case idle
        case queued
        case generating
        case extractingFrame
        case completed
        case failed(String)
        
        public var isActive: Bool {
            switch self {
            case .queued, .generating, .extractingFrame:
                return true
            default:
                return false
            }
        }
    }
}

/// Collection of segments with continuity management
public class MultiClipSegmentCollection: ObservableObject {
    @Published public var segments: [MultiClipSegment] = []
    @Published public var totalDuration: TimeInterval = 0
    @Published public var estimatedCredits: Int = 0
    
    public init() {}
    
    /// Add a segment and update continuity links
    public func addSegment(_ segment: MultiClipSegment) {
        var newSegment = segment
        
        // Link to previous segment
        if let lastSegment = segments.last {
            newSegment.previousSegmentId = lastSegment.id
            
            // Update the previous segment's next link
            if let index = segments.firstIndex(where: { $0.id == lastSegment.id }) {
                segments[index].nextSegmentId = newSegment.id
            }
        }
        
        segments.append(newSegment)
        updateTotalDuration()
    }
    
    /// Remove a segment and update continuity links
    public func removeSegment(id: UUID) {
        guard let index = segments.firstIndex(where: { $0.id == id }) else { return }
        let segment = segments[index]
        
        // Update continuity links
        if let prevId = segment.previousSegmentId,
           let prevIndex = segments.firstIndex(where: { $0.id == prevId }) {
            segments[prevIndex].nextSegmentId = segment.nextSegmentId
        }
        
        if let nextId = segment.nextSegmentId,
           let nextIndex = segments.firstIndex(where: { $0.id == nextId }) {
            segments[nextIndex].previousSegmentId = segment.previousSegmentId
        }
        
        segments.remove(at: index)
        updateTotalDuration()
    }
    
    /// Reorder segments and update all continuity links
    public func reorderSegments() {
        for (index, _) in segments.enumerated() {
            segments[index].order = index
            segments[index].previousSegmentId = index > 0 ? segments[index - 1].id : nil
            segments[index].nextSegmentId = index < segments.count - 1 ? segments[index + 1].id : nil
        }
    }
    
    /// Toggle segment enabled state
    public func toggleSegment(id: UUID) {
        guard let index = segments.firstIndex(where: { $0.id == id }) else { return }
        segments[index].isEnabled.toggle()
        updateTotalDuration()
    }
    
    /// Update generation state for a segment
    public func updateSegmentState(id: UUID, state: MultiClipSegment.GenerationState, progress: Double = 0) {
        guard let index = segments.firstIndex(where: { $0.id == id }) else { return }
        segments[index].generationState = state
        segments[index].progress = progress
        
        if case .failed(let error) = state {
            segments[index].error = error
        }
    }
    
    /// Store the last frame for continuity
    public func updateSegmentLastFrame(id: UUID, image: UIImage, data: Data) {
        guard let index = segments.firstIndex(where: { $0.id == id }) else { return }
        segments[index].lastFrameImage = image
        segments[index].lastFrameData = data
    }
    
    /// Get the previous segment's last frame for continuity
    public func getPreviousFrame(for segmentId: UUID) -> (image: UIImage?, data: Data?) {
        guard let segment = segments.first(where: { $0.id == segmentId }),
              let prevId = segment.previousSegmentId,
              let prevSegment = segments.first(where: { $0.id == prevId }) else {
            return (nil, nil)
        }
        
        return (prevSegment.lastFrameImage, prevSegment.lastFrameData)
    }
    
    private func updateTotalDuration() {
        totalDuration = segments
            .filter { $0.isEnabled }
            .reduce(0) { $0 + $1.duration }
    }
    
    /// Create segments from text using various strategies
    public static func createSegments(from text: String, strategy: MultiClipSegmentationStrategy) -> [MultiClipSegment] {
        switch strategy {
        case .byParagraphs:
            return segmentByParagraphs(text)
        case .byDuration(let targetDuration):
            return segmentByDuration(text, targetDuration: targetDuration)
        case .byScenes:
            return segmentByScenes(text)
        case .bySentences(let count):
            return segmentBySentences(text, sentencesPerSegment: count)
        }
    }
    
    private static func segmentByParagraphs(_ text: String) -> [MultiClipSegment] {
        let paragraphs = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return paragraphs.enumerated().map { index, paragraph in
            MultiClipSegment(text: paragraph, order: index)
        }
    }
    
    private static func segmentByDuration(_ text: String, targetDuration: TimeInterval) -> [MultiClipSegment] {
        // Estimate ~150 words per minute of speech
        let wordsPerSecond = 2.5
        let targetWords = Int(targetDuration * wordsPerSecond)
        
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var segments: [MultiClipSegment] = []
        var currentWords: [String] = []
        
        for word in words {
            currentWords.append(word)
            
            if currentWords.count >= targetWords {
                let segmentText = currentWords.joined(separator: " ")
                segments.append(MultiClipSegment(
                    text: segmentText,
                    order: segments.count,
                    duration: targetDuration
                ))
                currentWords = []
            }
        }
        
        // Add remaining words
        if !currentWords.isEmpty {
            let segmentText = currentWords.joined(separator: " ")
            let estimatedDuration = Double(currentWords.count) / wordsPerSecond
            segments.append(MultiClipSegment(
                text: segmentText,
                order: segments.count,
                duration: max(3.0, estimatedDuration) // Minimum 3 seconds
            ))
        }
        
        return segments
    }
    
    private static func segmentByScenes(_ text: String) -> [MultiClipSegment] {
        let sceneMarkers = ["INT.", "EXT.", "SCENE:", "CUT TO:", "FADE"]
        let lines = text.components(separatedBy: .newlines)
        
        var segments: [MultiClipSegment] = []
        var currentScene: [String] = []
        
        for line in lines {
            let upperLine = line.uppercased().trimmingCharacters(in: .whitespaces)
            let isNewScene = sceneMarkers.contains { upperLine.hasPrefix($0) }
            
            if isNewScene && !currentScene.isEmpty {
                let sceneText = currentScene.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if !sceneText.isEmpty {
                    segments.append(MultiClipSegment(
                        text: sceneText,
                        order: segments.count
                    ))
                }
                currentScene = [line]
            } else {
                currentScene.append(line)
            }
        }
        
        // Add final scene
        if !currentScene.isEmpty {
            let sceneText = currentScene.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !sceneText.isEmpty {
                segments.append(MultiClipSegment(
                    text: sceneText,
                    order: segments.count
                ))
            }
        }
        
        #if DEBUG
        print("🎬 [Segmentation] byScenes found \(segments.count) segments")
        #endif
        
        // Fallback to paragraphs if no scenes detected
        if segments.isEmpty {
            #if DEBUG
            print("🎬 [Segmentation] No scenes found, falling back to paragraphs")
            #endif
            let paragraphSegments = segmentByParagraphs(text)
            
            // If paragraphs also empty, try sentences
            if paragraphSegments.isEmpty {
                #if DEBUG
                print("🎬 [Segmentation] No paragraphs found, falling back to sentences")
                #endif
                return segmentBySentences(text, sentencesPerSegment: 2)
            }
            
            return paragraphSegments
        }
        
        return segments
    }
    
    private static func segmentBySentences(_ text: String, sentencesPerSegment: Int) -> [MultiClipSegment] {
        // Split by sentence-ending punctuation
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var segments: [MultiClipSegment] = []
        
        for i in stride(from: 0, to: sentences.count, by: sentencesPerSegment) {
            let endIndex = min(i + sentencesPerSegment, sentences.count)
            let segmentSentences = sentences[i..<endIndex]
            let segmentText = segmentSentences.joined(separator: ". ") + "."
            
            segments.append(MultiClipSegment(
                text: segmentText,
                order: segments.count
            ))
        }
        
        return segments
    }
}

public enum MultiClipSegmentationStrategy {
    case byParagraphs
    case byDuration(TimeInterval)
    case byScenes
    case bySentences(Int)
}
