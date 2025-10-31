// MODULE: GenerationMetrics
// VERSION: 1.0.0
// PURPOSE: Track performance metrics for video generation

import Foundation

/// Metrics collected during video generation for performance analysis
public struct GenerationMetrics: Codable, Sendable {
    public let taskId: String
    public let klingVersion: String
    public let queueWaitTime: TimeInterval
    public let generationTime: TimeInterval
    public let networkLatency: TimeInterval
    public let localProcessingTime: TimeInterval
    public let peakMemoryUsage: Int64
    public let apiResponseSize: Int64
    public let cacheHitRate: Double
    public let negativePromptsUsed: [String]?
    public let experimentGroup: String?
    public let timestamp: Date
    
    public init(
        taskId: String,
        klingVersion: String,
        queueWaitTime: TimeInterval = 0,
        generationTime: TimeInterval = 0,
        networkLatency: TimeInterval = 0,
        localProcessingTime: TimeInterval = 0,
        peakMemoryUsage: Int64 = 0,
        apiResponseSize: Int64 = 0,
        cacheHitRate: Double = 0,
        negativePromptsUsed: [String]? = nil,
        experimentGroup: String? = nil,
        timestamp: Date = Date()
    ) {
        self.taskId = taskId
        self.klingVersion = klingVersion
        self.queueWaitTime = queueWaitTime
        self.generationTime = generationTime
        self.networkLatency = networkLatency
        self.localProcessingTime = localProcessingTime
        self.peakMemoryUsage = peakMemoryUsage
        self.apiResponseSize = apiResponseSize
        self.cacheHitRate = cacheHitRate
        self.negativePromptsUsed = negativePromptsUsed
        self.experimentGroup = experimentGroup
        self.timestamp = timestamp
    }
}

