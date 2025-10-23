//
//  DirectorStudioCore.swift
//  DirectorStudio
//
//  MODULE: DirectorStudioCore
//  VERSION: 1.0.0
//  PURPOSE: Core integration and orchestration system
//

import Foundation
import Combine

// MARK: - Director Studio Core

/// Central orchestration system for all pipeline modules
public class DirectorStudioCore: ObservableObject {
    // MARK: - Singleton
    
    public static let shared = DirectorStudioCore()
    
    // MARK: - Core Modules
    
    public let segmentationModule: SegmentationModule
    public let storyAnalysisModule: StoryAnalysisModule
    public let taxonomyModule: CinematicTaxonomyModule
    public let continuityEngine: ContinuityEngine
    public let continuityInjector: ContinuityInjector
    public let videoGenerationModule: VideoGenerationModule
    public let videoEffectsModule: VideoEffectsModule
    public let videoAssemblyModule: VideoAssemblyModule
    
    // MARK: - Core Services
    
    public let persistenceManager: PersistenceManagerProtocol
    public let monetizationManager: MonetizationManagerProtocol
    public let aiService: AIServiceProtocol
    
    // MARK: - Core State
    
    @Published public private(set) var currentProject: Project?
    @Published public private(set) var currentSegments: [PromptSegment] = []
    @Published public private(set) var isProcessing: Bool = false
    @Published public private(set) var currentOperation: String = ""
    @Published public private(set) var progress: Double = 0.0
    
    // MARK: - Reactive Publishers
    
    public var projectPublisher: AnyPublisher<Project?, Never> {
        $currentProject.eraseToAnyPublisher()
    }
    
    public var segmentsPublisher: AnyPublisher<[PromptSegment], Never> {
        $currentSegments.eraseToAnyPublisher()
    }
    
    public var processingPublisher: AnyPublisher<Bool, Never> {
        $isProcessing.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize AI service from configuration (Pollo, DeepSeek, or Mock)
        self.aiService = AIServiceFactory.createFromEnvironment()
        
        // Initialize modules - many are designed for AI integration!
        self.segmentationModule = SegmentationModule()
        self.storyAnalysisModule = StoryAnalysisModule()
        self.taxonomyModule = CinematicTaxonomyModule()
        self.continuityEngine = ContinuityEngine()
        self.continuityInjector = ContinuityInjector()
        self.videoGenerationModule = VideoGenerationModule(aiService: aiService)  // Uses AI!
        self.videoEffectsModule = VideoEffectsModule()
        self.videoAssemblyModule = VideoAssemblyModule()
        
        // Initialize services
        do {
            self.persistenceManager = try FilePersistenceManager()
            self.monetizationManager = MockMonetizationManager(persistenceManager: persistenceManager)
        } catch {
            fatalError("Failed to initialize core services: \(error.localizedDescription)")
        }
        
        // Log which AI service is active
        let aiServiceName = String(describing: type(of: aiService))
        print("🚀 DirectorStudioCore initialized with AI service: \(aiServiceName)")
        
        // Telemetry
        Task {
            await Telemetry.shared.logEvent(
                "CoreInitializationCompleted",
                metadata: [
                    "moduleCount": "8",
                    "aiService": aiServiceName
                ]
            )
        }
    }
    
    // MARK: - Project Management
    
    @MainActor
    public func createProject(name: String, description: String = "") async throws -> Project {
        let project = try persistenceManager.saveProject(
            Project(name: name, description: description)
        )
        
        self.currentProject = project
        self.currentSegments = []
        
        return project
    }
    
    @MainActor
    public func loadProject(id: UUID) async throws -> Project {
        guard let project = try await persistenceManager.getProject(id: id) else {
            throw CoreError.projectNotFound(id: id)
        }
        
        self.currentProject = project
        self.currentSegments = try await persistenceManager.getSegments(projectId: id)
        
        return project
    }
    
    @MainActor
    public func saveProject() async throws {
        guard let project = currentProject else {
            throw CoreError.noActiveProject
        }
        
        var updatedProject = project
        updatedProject.updatedAt = Date()
        
        self.currentProject = try persistenceManager.saveProject(updatedProject)
        try await persistenceManager.saveSegments(currentSegments, projectId: updatedProject.id)
    }
    
    @MainActor
    public func closeProject() {
        self.currentProject = nil
        self.currentSegments = []
    }
    
    // MARK: - Pipeline Execution
    
    @MainActor
    public func segmentStory(_ story: String, maxDuration: TimeInterval = 4.0) async throws -> [PromptSegment] {
        guard currentProject != nil else {
            throw CoreError.noActiveProject
        }
        
        // Check credits
        let requiredCredits = 5
        guard await monetizationManager.canAfford(requiredCredits) else {
            let available = await monetizationManager.getAvailableCredits()
            throw CoreError.insufficientCredits(required: requiredCredits, available: available)
        }
        
        // Start processing
        isProcessing = true
        currentOperation = "Segmenting story"
        progress = 0.1
        
        do {
            // Segment
            let input = SegmentationInput(story: story, maxDuration: maxDuration)
            let result = try await segmentationModule.execute(input: input)
            
            self.currentSegments = result.segments
            try await monetizationManager.useCredits(requiredCredits)
            
            isProcessing = false
            currentOperation = ""
            progress = 1.0
            
            return result.segments
            
        } catch {
            isProcessing = false
            currentOperation = ""
            throw error
        }
    }
    
    @MainActor
    public func enrichWithTaxonomy() async throws -> [PromptSegment] {
        guard currentProject != nil else {
            throw CoreError.noActiveProject
        }
        
        guard !currentSegments.isEmpty else {
            throw CoreError.noSegmentsAvailable
        }
        
        isProcessing = true
        currentOperation = "Adding cinematic taxonomy"
        
        do {
            let input = CinematicTaxonomyInput(segments: currentSegments)
            let result = try await taxonomyModule.execute(input: input)
            
            self.currentSegments = result.enrichedSegments
            
            isProcessing = false
            return result.enrichedSegments
            
        } catch {
            isProcessing = false
            throw error
        }
    }
    
    @MainActor
    public func validateContinuity() async throws -> ContinuityEngineOutput {
        guard currentProject != nil else {
            throw CoreError.noActiveProject
        }
        
        guard !currentSegments.isEmpty else {
            throw CoreError.noSegmentsAvailable
        }
        
        isProcessing = true
        currentOperation = "Validating continuity"
        
        do {
            let input = ContinuityEngineInput(segments: currentSegments)
            let result = try await continuityEngine.execute(input: input)
            
            isProcessing = false
            return result
            
        } catch {
            isProcessing = false
            throw error
        }
    }
    
    @MainActor
    public func fixContinuity(engineOutput: ContinuityEngineOutput) async throws -> [PromptSegment] {
        guard currentProject != nil else {
            throw CoreError.noActiveProject
        }
        
        isProcessing = true
        currentOperation = "Fixing continuity issues"
        
        do {
            let input = ContinuityInjectorInput(
                segments: currentSegments,
                sceneStates: engineOutput.sceneStates,
                issues: engineOutput.continuityIssues,
                manifestationScores: engineOutput.manifestationScores
            )
            let result = try await continuityInjector.execute(input: input)
            
            self.currentSegments = result.correctedSegments
            
            isProcessing = false
            return result.correctedSegments
            
        } catch {
            isProcessing = false
            throw error
        }
    }
}

// MARK: - Errors

public enum CoreError: Error, LocalizedError {
    case noActiveProject
    case projectNotFound(id: UUID)
    case segmentNotFound(id: UUID)
    case noSegmentsAvailable
    case insufficientCredits(required: Int, available: Int)
    
    public var errorDescription: String? {
        switch self {
        case .noActiveProject:
            return "No active project. Create or load a project first."
        case .projectNotFound(let id):
            return "Project not found: \(id)"
        case .segmentNotFound(let id):
            return "Segment not found: \(id)"
        case .noSegmentsAvailable:
            return "No segments available. Segment a story first."
        case .insufficientCredits(let required, let available):
            return "Insufficient credits. Required: \(required), Available: \(available)"
        }
    }
}

