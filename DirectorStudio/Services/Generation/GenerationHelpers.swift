// MODULE: GenerationHelpers
// VERSION: 1.0.0
// PURPOSE: Helper types for generation orchestration

import Foundation

/// Result of a generation attempt
public enum GenerationResult: Sendable {
    case success(promptId: UUID, videoURL: URL, metrics: GenerationMetrics)
    case cached(promptId: UUID, clipId: UUID)
    case failure(promptId: UUID, error: Error)
}

/// Protocol for video generation providers (alias for compatibility)
public typealias VideoGenerationProvider = VideoGenerationProtocol

/// Manages device capabilities for parallel generation
public class DeviceCapabilityManager {
    public static let shared = DeviceCapabilityManager()
    
    private init() {}
    
    /// Recommended number of concurrent generation tasks based on device
    public var recommendedConcurrency: Int {
        #if os(iOS)
        // Use ProcessInfo to detect device capabilities
        let processorCount = ProcessInfo.processInfo.processorCount
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        
        // Conservative estimates based on memory and CPU
        if physicalMemory > 8_000_000_000 { // > 8GB RAM
            return min(processorCount, 5)
        } else if physicalMemory > 4_000_000_000 { // > 4GB RAM
            return min(processorCount, 3)
        } else {
            return 2 // Lower-end devices
        }
        #else
        // macOS - more aggressive
        return min(ProcessInfo.processInfo.processorCount, 8)
        #endif
    }
}

/// Generation errors
public enum GenerationError: LocalizedError, Sendable {
    case maxRetriesExceeded
    case noProviderAvailable
    case cacheLookupFailed
    
    public var errorDescription: String? {
        switch self {
        case .maxRetriesExceeded:
            return "Maximum retry attempts exceeded"
        case .noProviderAvailable:
            return "No video generation provider is available"
        case .cacheLookupFailed:
            return "Failed to check cache"
        }
    }
}

/// Array extension for chunking
extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

