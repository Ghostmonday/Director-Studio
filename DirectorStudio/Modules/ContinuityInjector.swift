//
//  ContinuityInjector.swift
//  DirectorStudio
//
//  MODULE: ContinuityInjector
//  VERSION: 2.0.0
//  PURPOSE: Fixes continuity violations by injecting corrections into prompts
//

import Foundation

// MARK: - Continuity Injector (Fixer)

/// Takes violations from ContinuityEngine and injects corrections into prompts
/// This is the "rewrite department" - it fixes what the Engine detected
public struct ContinuityInjector: PipelineModule {
    public typealias Input = ContinuityInjectorInput
    public typealias Output = ContinuityInjectorOutput
    
    public let id = "continuity-injector"
    public let name = "Continuity Injector"
    public let version = "2.0.0"
    public var isEnabled: Bool = true
    
    private let logger = Loggers.continuity
    
    public init() {}
    
    public func execute(input: ContinuityInjectorInput) async throws -> ContinuityInjectorOutput {
        let context = PipelineContext()
        let result = await execute(input: input, context: context)
        switch result {
        case .success(let output):
            return output
        case .failure(let error):
            throw error
        }
    }
    
    public func execute(
        input: ContinuityInjectorInput,
        context: PipelineContext
    ) async -> Result<ContinuityInjectorOutput, PipelineError> {
        logger.info("💉 Continuity Injector fixing \(input.issues.count) issues across \(input.segments.count) segments")
        
        await Telemetry.shared.logEvent(
            "ContinuityInjectorStarted",
            metadata: [
                "segmentCount": "\(input.segments.count)",
                "issueCount": "\(input.issues.count)"
            ]
        )
        
        let startTime = Date()
        var correctedSegments: [PromptSegment] = []
        var injectionsApplied: [InjectionRecord] = []
        
        // Create issue map for quick lookup
        var issueMap: [Int: ContinuityIssue] = [:]
        for issue in input.issues {
            issueMap[issue.segmentIndex] = issue
        }
        
        // Process each segment
        for (index, segment) in input.segments.enumerated() {
            let sceneState = input.sceneStates[index]
            let previousState = index > 0 ? input.sceneStates[index - 1] : nil
            let issue = issueMap[index]
            
            // Inject corrections based on issues
            let enhanced = injectCorrections(
                segment: segment,
                sceneState: sceneState,
                previousState: previousState,
                issue: issue,
                manifestationScores: input.manifestationScores
            )
            
            correctedSegments.append(enhanced.segment)
            if let injection = enhanced.injection {
                injectionsApplied.append(injection)
            }
        }
        
        let executionTime = Date().timeIntervalSince(startTime)
        
        let output = ContinuityInjectorOutput(
            correctedSegments: correctedSegments,
            injectionsApplied: injectionsApplied,
            issuesFixed: input.issues.count
        )
        
        logger.info("✅ Continuity injection completed in \(String(format: "%.2f", executionTime))s")
        logger.info("💉 Applied \(injectionsApplied.count) corrections")
        
        await Telemetry.shared.logEvent(
            "ContinuityInjectorCompleted",
            metadata: [
                "duration": String(format: "%.2f", executionTime),
                "injectionsApplied": "\(injectionsApplied.count)",
                "issuesFixed": "\(input.issues.count)"
            ]
        )
        
        return .success(output)
    }
    
    public func validate(input: ContinuityInjectorInput) -> Bool {
        return !input.segments.isEmpty && input.segments.count == input.sceneStates.count
    }
    
    // MARK: - Injection Logic
    
    private func injectCorrections(
        segment: PromptSegment,
        sceneState: SceneState,
        previousState: SceneState?,
        issue: ContinuityIssue?,
        manifestationScores: [String: ManifestationScore]
    ) -> (segment: PromptSegment, injection: InjectionRecord?) {
        
        var enhanced = segment.content
        var enhancements: [String] = []
        var injectionType: InjectionType?
        
        // 1. Fix prop persistence issues
        for prop in sceneState.props {
            let rate = manifestationScores[prop.lowercased()]?.manifestationRate ?? 0.8
            if rate < 0.5 {
                enhancements.append("CLEARLY SHOWING \(prop)")
                injectionType = .propReinforcement
            }
        }
        
        // 2. Fix character consistency
        if let prev = previousState {
            for char in sceneState.characters where prev.characters.contains(char) {
                enhancements.append("\(char) with same appearance as previous scene")
                injectionType = .characterConsistency
            }
        }
        
        // 3. Fix disappearing props
        if let issue = issue {
            for issueDesc in issue.issues {
                if issueDesc.contains("disappeared") {
                    // Extract prop name
                    if let prop = issueDesc.components(separatedBy: " ").first {
                        enhancements.append("maintaining \(prop) from previous scene")
                        injectionType = .missingPropFix
                    }
                }
            }
        }
        
        // 4. Smooth tone transitions
        if let prev = previousState, prev.tone != sceneState.tone {
            let toneTransition = "transitioning from \(prev.tone.lowercased()) to \(sceneState.tone.lowercased()) mood"
            enhancements.append(toneTransition)
            injectionType = .toneSmoothing
        }
        
        // Apply enhancements
        var injectionRecord: InjectionRecord? = nil
        if !enhancements.isEmpty {
            enhanced += " [CONTINUITY: " + enhancements.joined(separator: ", ") + "]"
            
            injectionRecord = InjectionRecord(
                segmentIndex: segment.index - 1,
                type: injectionType ?? .general,
                corrections: enhancements,
                originalPrompt: segment.content,
                enhancedPrompt: enhanced
            )
            
            logger.debug("💉 Segment \(segment.index): injected \(enhancements.count) corrections")
        }
        
        // Create enhanced segment
        let enhancedSegment = PromptSegment(
            id: segment.id,
            index: segment.index,
            duration: segment.duration,
            content: enhanced,
            characters: segment.characters,
            setting: segment.setting,
            action: segment.action,
            continuityNotes: segment.continuityNotes,
            location: segment.location,
            props: segment.props,
            tone: segment.tone
        )
        
        return (enhancedSegment, injectionRecord)
    }
}

// MARK: - Supporting Types

public struct ContinuityInjectorInput: Sendable {
    public let segments: [PromptSegment]
    public let sceneStates: [SceneState]
    public let issues: [ContinuityIssue]
    public let manifestationScores: [String: ManifestationScore]
    
    public init(
        segments: [PromptSegment],
        sceneStates: [SceneState],
        issues: [ContinuityIssue],
        manifestationScores: [String: ManifestationScore]
    ) {
        self.segments = segments
        self.sceneStates = sceneStates
        self.issues = issues
        self.manifestationScores = manifestationScores
    }
}

public struct ContinuityInjectorOutput: Sendable {
    public let correctedSegments: [PromptSegment]
    public let injectionsApplied: [InjectionRecord]
    public let issuesFixed: Int
    
    public init(
        correctedSegments: [PromptSegment],
        injectionsApplied: [InjectionRecord],
        issuesFixed: Int
    ) {
        self.correctedSegments = correctedSegments
        self.injectionsApplied = injectionsApplied
        self.issuesFixed = issuesFixed
    }
}

public struct InjectionRecord: Sendable, Codable {
    public let segmentIndex: Int
    public let type: InjectionType
    public let corrections: [String]
    public let originalPrompt: String
    public let enhancedPrompt: String
    
    public init(
        segmentIndex: Int,
        type: InjectionType,
        corrections: [String],
        originalPrompt: String,
        enhancedPrompt: String
    ) {
        self.segmentIndex = segmentIndex
        self.type = type
        self.corrections = corrections
        self.originalPrompt = originalPrompt
        self.enhancedPrompt = enhancedPrompt
    }
}

public enum InjectionType: String, Sendable, Codable {
    case propReinforcement = "Prop Reinforcement"
    case characterConsistency = "Character Consistency"
    case missingPropFix = "Missing Prop Fix"
    case toneSmoothing = "Tone Smoothing"
    case general = "General Enhancement"
}


