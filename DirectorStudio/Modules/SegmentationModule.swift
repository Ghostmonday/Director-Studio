//
//  SegmentationModule.swift
//  DirectorStudio
//
//  MODULE: Segmentation
//  VERSION: 1.0.0
//  PURPOSE: Basic text segmentation at natural breaks (NO emotion/narrative/dialogue detection)
//

import Foundation

// MARK: - Segmentation Module (Simplified)

/// Simple text segmentation based on natural breaks (paragraphs, sentences, scene transitions)
/// Does NOT include emotion-driven, narrative-based, or dialogue-based detection
public final class SegmentationModule: PipelineModule {
    public typealias Input = SegmentationInput
    public typealias Output = SegmentationOutput
    
    public let id = "segmentation"
    public let name = "Segmentation"
    public let version = "1.0.0"
    public var isEnabled = true
    
    private let logger = Loggers.pipeline
    
    public init() {
        Task {
            await Telemetry.shared.register(module: "segmentation")
            await Telemetry.shared.logEvent(
                "ModuleInitialized",
                metadata: ["module": "segmentation", "version": version]
            )
        }
    }
    
    public nonisolated func validate(input: SegmentationInput) -> Bool {
        let trimmed = input.story.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && input.maxDuration > 0 && input.maxDuration <= 60
    }
    
    public func execute(input: SegmentationInput) async throws -> SegmentationOutput {
        let startTime = Date()
        
        await Telemetry.shared.logEvent(
            "SegmentationExecutionStarted",
            metadata: [
                "storyLength": "\(input.story.count)",
                "maxDuration": "\(input.maxDuration)"
            ]
        )
        
        logger.info("📄 Segmenting story (\(input.story.count) chars) with max duration \(input.maxDuration)s")
        
        // Perform simple segmentation
        var segments = segmentStory(input.story, maxDuration: input.maxDuration)
        
        // Enforce max duration
        segments = enforceMaxDuration(segments, maxDuration: input.maxDuration)
        
        // Calculate basic metrics
        let metrics = calculateMetrics(segments, targetDuration: input.maxDuration)
        let processingTime = Date().timeIntervalSince(startTime)
        
        logger.info("✅ Segmentation complete: \(segments.count) segments in \(String(format: "%.2f", processingTime))s")
        
        await Telemetry.shared.logEvent(
            "SegmentationExecutionCompleted",
            metadata: [
                "segmentCount": "\(segments.count)",
                "processingTime": "\(processingTime)"
            ]
        )
        
        return SegmentationOutput(
            segments: segments,
            totalSegments: segments.count,
            averageDuration: metrics.averageDuration,
            metrics: metrics,
            processingTime: processingTime
        )
    }
    
    public func execute(
        input: SegmentationInput,
        context: PipelineContext
    ) async -> Result<SegmentationOutput, PipelineError> {
        do {
            let output = try await execute(input: input)
            return .success(output)
        } catch {
            return .failure(.executionFailed(error.localizedDescription))
        }
    }
    
    // MARK: - Segmentation Logic
    
    /// Simple paragraph/sentence-based segmentation
    private func segmentStory(_ story: String, maxDuration: TimeInterval) -> [PromptSegment] {
        var segments: [PromptSegment] = []
        var order = 1
        
        // Split by paragraphs
        let paragraphs = story.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var currentSegment = ""
        
        for paragraph in paragraphs {
            let testSegment = currentSegment.isEmpty ? paragraph : "\(currentSegment)\n\n\(paragraph)"
            let estimatedDuration = estimateDuration(for: testSegment)
            
            if estimatedDuration <= maxDuration {
                currentSegment = testSegment
            } else {
                // Save current segment if not empty
                if !currentSegment.isEmpty {
                    segments.append(createSegment(text: currentSegment, order: order))
                    order += 1
                }
                currentSegment = paragraph
            }
        }
        
        // Add final segment
        if !currentSegment.isEmpty {
            segments.append(createSegment(text: currentSegment, order: order))
        }
        
        return segments
    }
    
    /// Enforce max duration by splitting oversized segments
    private func enforceMaxDuration(_ segments: [PromptSegment], maxDuration: TimeInterval) -> [PromptSegment] {
        var result: [PromptSegment] = []
        var order = 1
        
        for segment in segments {
            if Double(segment.duration) <= maxDuration {
                result.append(segment)
                order += 1
            } else {
                // Split by sentences
                let sentences = segment.content.components(separatedBy: CharacterSet(charactersIn: ".!?"))
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                var currentChunk = ""
                
                for sentence in sentences {
                    let testChunk = currentChunk.isEmpty ? sentence : "\(currentChunk). \(sentence)"
                    
                    if estimateDuration(for: testChunk) <= maxDuration {
                        currentChunk = testChunk
                    } else {
                        if !currentChunk.isEmpty {
                            result.append(createSegment(text: currentChunk, order: order))
                            order += 1
                        }
                        currentChunk = sentence
                    }
                }
                
                if !currentChunk.isEmpty {
                    result.append(createSegment(text: currentChunk, order: order))
                    order += 1
                }
            }
        }
        
        return result
    }
    
    // MARK: - Helper Methods
    
    private func estimateDuration(for text: String) -> TimeInterval {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let wordsPerSecond = 2.0 // Assume 2 words per second for reading/narration
        return Double(words.count) / wordsPerSecond
    }
    
    private func createSegment(text: String, order: Int) -> PromptSegment {
        let duration = estimateDuration(for: text)
        
        return PromptSegment(
            index: order,
            duration: duration,
            content: text.trimmingCharacters(in: .whitespacesAndNewlines),
            characters: [],
            setting: "",
            action: "",
            continuityNotes: [],
            location: "",
            props: [],
            tone: ""
        )
    }
    
    private func calculateMetrics(_ segments: [PromptSegment], targetDuration: TimeInterval) -> SegmentationMetrics {
        guard !segments.isEmpty else {
            return SegmentationMetrics()
        }
        
        let durations = segments.map { Double($0.duration) }
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let minDuration = durations.min() ?? 0
        let maxDuration = durations.max() ?? 0
        
        // Calculate standard deviation
        let variance = durations.reduce(0.0) { sum, duration in
            sum + pow(duration - avgDuration, 2)
        } / Double(durations.count)
        let stdDev = sqrt(variance)
        
        // Calculate boundary quality (how well segments align with target)
        let boundaryQuality = 1.0 - min(abs(avgDuration - targetDuration) / targetDuration, 1.0)
        
        // Calculate pacing consistency
        let pacingConsistency = 1.0 - min(stdDev / avgDuration, 1.0)
        
        return SegmentationMetrics(
            averageDuration: avgDuration,
            minDuration: minDuration,
            maxDuration: maxDuration,
            standardDeviation: stdDev,
            boundaryQuality: boundaryQuality,
            pacingConsistency: pacingConsistency
        )
    }
}

// MARK: - Supporting Types

public struct SegmentationInput: Sendable {
    public let story: String
    public let maxDuration: TimeInterval
    
    public init(story: String, maxDuration: TimeInterval = 4.0) {
        self.story = story
        self.maxDuration = maxDuration
    }
}

public struct SegmentationOutput: Sendable {
    public let segments: [PromptSegment]
    public let totalSegments: Int
    public let averageDuration: TimeInterval
    public let metrics: SegmentationMetrics
    public let processingTime: TimeInterval
    
    public init(
        segments: [PromptSegment],
        totalSegments: Int,
        averageDuration: TimeInterval,
        metrics: SegmentationMetrics,
        processingTime: TimeInterval
    ) {
        self.segments = segments
        self.totalSegments = totalSegments
        self.averageDuration = averageDuration
        self.metrics = metrics
        self.processingTime = processingTime
    }
}

public struct SegmentationMetrics: Codable, Sendable {
    public let averageDuration: TimeInterval
    public let minDuration: TimeInterval
    public let maxDuration: TimeInterval
    public let standardDeviation: TimeInterval
    public let boundaryQuality: Double
    public let pacingConsistency: Double
    
    public init(
        averageDuration: TimeInterval = 0,
        minDuration: TimeInterval = 0,
        maxDuration: TimeInterval = 0,
        standardDeviation: TimeInterval = 0,
        boundaryQuality: Double = 0,
        pacingConsistency: Double = 0
    ) {
        self.averageDuration = averageDuration
        self.minDuration = minDuration
        self.maxDuration = maxDuration
        self.standardDeviation = standardDeviation
        self.boundaryQuality = boundaryQuality
        self.pacingConsistency = pacingConsistency
    }
}

