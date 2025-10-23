// MODULE: Protocols
// VERSION: 1.0.0
// PURPOSE: Core protocols for pipeline modules

import Foundation

/// Core protocol that all pipeline modules must conform to
/// Follows "Decouple or Die" and "Plug, Don't Patch" protocols
protocol PipelineModule {
    /// Unique identifier for this module
    var id: String { get }
    
    /// Semantic version of this module
    var version: String { get }
    
    /// Human-readable description of module purpose
    var description: String { get }
    
    /// Process input data and return structured result
    /// - Parameter input: The input data to process
    /// - Returns: Processing result with success/failure/partial states
    func process(_ input: ModuleInput) async -> ModuleResult
}

/// Input contract for pipeline modules
protocol ModuleInput {
    /// Validate that this input is complete and ready for processing
    var isValid: Bool { get }
    
    /// Human-readable description of validation issues
    var validationErrors: [String] { get }
}

/// Output contract for pipeline modules
protocol ModuleOutput {
    /// Indicates if the output represents a successful operation
    var isSuccess: Bool { get }
    
    /// Additional context or metadata about the output
    var metadata: [String: Any] { get }
}

/// Result type for module processing operations
/// Follows "Fail Safe, Log Always" protocol
enum ModuleResult {
    case success(ModuleOutput)
    case failure(reason: String, context: [String: Any] = [:])
    case partial(results: ModuleOutput, warnings: [String])
    
    /// Convenience property to check if operation was successful
    var isSuccess: Bool {
        switch self {
        case .success, .partial:
            return true
        case .failure:
            return false
        }
    }
}

/// Protocol for modules that can validate their own state
protocol ValidatableModule {
    /// Validate the module's current state and configuration
    /// - Returns: Validation result with any issues found
    func validate() -> ValidationResult
}

/// Result of module validation
enum ValidationResult {
    case valid
    case invalid(reasons: [String])
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
}

// MARK: - Shared Types

/// Video segment with timing and content information
struct VideoSegment {
    let id: UUID
    let startTime: TimeInterval
    let endTime: TimeInterval
    let content: String
}

/// Transition between video segments
struct Transition {
    let fromSegment: UUID
    let toSegment: UUID
    let type: TransitionType
    let duration: TimeInterval
}

/// Types of transitions between segments
enum TransitionType: String, CaseIterable {
    case cut = "cut"
    case fade = "fade"
    case dissolve = "dissolve"
    case slide = "slide"
}

/// Output settings for video rendering
struct OutputSettings {
    let resolution: CGSize
    let frameRate: Double
    let bitrate: Int
    let format: VideoFormat
}

/// Video format options
enum VideoFormat: String, CaseIterable {
    case mp4 = "mp4"
    case mov = "mov"
    case avi = "avi"
}

/// Continuity rule for visual continuity enforcement
struct ContinuityRule {
    let type: ContinuityType
    let threshold: Double
}

/// Types of continuity checks
enum ContinuityType: String, CaseIterable {
    case color = "color"
    case lighting = "lighting"
    case motion = "motion"
    case composition = "composition"
}
