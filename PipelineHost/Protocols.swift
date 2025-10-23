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

/// Protocol for error reporting
protocol ErrorReportable {
    func reportError(_ error: Error, context: [String: Any])
}

/// Protocol for identifiable jobs
protocol IdentifiableJob {
    var id: UUID { get }
    var status: JobStatus { get }
}

/// Protocol for versioned models
protocol VersionedModel {
    var version: String { get }
}
