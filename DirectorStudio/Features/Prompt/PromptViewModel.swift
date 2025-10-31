// MODULE: PromptViewModel
// VERSION: 1.2.0
// PURPOSE: Business logic for prompt input and clip generation with demo mode & auto-save

import Foundation
import SwiftUI
import Combine

// MARK: - User Expertise Tracking

enum UserExpertiseLevel: String, CaseIterable {
    case beginner = "Just Starting"
    case regular = "Getting Comfortable" 
    case power = "Power User"
    
    var maxVisibleOptions: Int {
        switch self {
        case .beginner: return 3
        case .regular: return 6
        case .power: return 100
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "Show essential features only"
        case .regular: return "Show common features"
        case .power: return "Show all advanced features"
        }
    }
    
    var icon: String {
        switch self {
        case .beginner: return "star"
        case .regular: return "star.fill"
        case .power: return "star.circle.fill"
        }
    }
}

/// Creative context states for context-aware UI
public enum CreativeContext {
    case ideation      // Just opened app
    case scripting     // Typing in prompt
    case reviewing     // Confirmed prompt
    case generating    // Video generating
    
    var headerMessage: String {
        switch self {
        case .ideation: return "What story will you tell today?"
        case .scripting: return "Crafting your vision..."
        case .reviewing: return "Review your masterpiece"
        case .generating: return "Bringing your story to life..."
        }
    }
    
    var icon: String {
        switch self {
        case .ideation: return "sparkles"
        case .scripting: return "pencil.circle.fill"
        case .reviewing: return "eye.fill"
        case .generating: return "wand.and.stars"
        }
    }
}

/// Generation mode for single video vs multi-clip film
public enum GenerationMode: String, CaseIterable {
    case single = "Single Video"
    case multiClip = "Film/Series"
    
    var icon: String {
        switch self {
        case .single: return "video"
        case .multiClip: return "film.stack"
        }
    }
    
    var description: String {
        switch self {
        case .single: return "Create one video (TikTok, Instagram Reel)"
        case .multiClip: return "Create a multi-part film or series"
        }
    }
}

/// Duration strategy for multi-clip generation
public enum DurationStrategy: Equatable {
    case uniform(TimeInterval)  // All clips same length
    case custom                 // Individual control per clip
    case auto                   // AI determines based on content
}

/// Pipeline stages that can be toggled
public enum PipelineStage: String, CaseIterable {
    case segmentation = "Segmentation"
    case continuityAnalysis = "Continuity Analysis"
    case continuityInjection = "Continuity Injection"
    case enhancement = "Enhancement"
    case cameraDirection = "Camera Direction"
    case lighting = "Lighting"
    
    public var displayName: String {
        return self.rawValue
    }
    
    public var description: String {
        switch self {
        case .segmentation:
            return "Break script into logical segments"
        case .continuityAnalysis:
            return "Analyze scene for elements that need consistency"
        case .continuityInjection:
            return "Apply continuity elements to maintain visual coherence"
        case .enhancement:
            return "Enhance visual descriptions"
        case .cameraDirection:
            return "Add camera movement and angles"
        case .lighting:
            return "Optimize lighting and mood"
        }
    }
}

/// ViewModel for PromptView
@MainActor
class PromptViewModel: ObservableObject {
    @Published var promptText: String = ""
    @Published var projectName: String = ""
    @Published var enabledStages: Set<PipelineStage> = Set(PipelineStage.allCases)
    @Published var isGenerating: Bool = false
    @Published var selectedImage: UIImage? = nil
    @Published var useDefaultAdImage: Bool = false
    @Published var videoDuration: Double = 10.0 // Default 10 seconds, range 3-20
    @Published var useContinuityFromLastClip = false
    @Published var lastClipContinuityImage: UIImage? = nil
    @Published var showingStageHelp: PipelineStage? = nil
    @Published var generationError: Error? = nil
    // Demo mode removed
    @Published var showingCreditsAlert = false
    @Published var showingCostBreakdown = false
    @Published var showingPromptHelp = false
    // @Published var selectedQualityTier: VideoQualityTier = .standard
    // @Published var selectedModelTier: PricingEngine.ModelTier = .standard
    
    // Generation mode
    @Published var generationMode: GenerationMode = .single
    @Published var durationStrategy: DurationStrategy = .auto  // Automated by default
    @Published var uniformDuration: TimeInterval = 10.0
    
    // Context-aware UI state
    @Published var currentContext: CreativeContext = .ideation
    
    // Progressive disclosure
    @AppStorage("userExpertiseLevel") var expertiseLevel: UserExpertiseLevel = .beginner
    @AppStorage("videosGenerated") var videosGenerated: Int = 0
    @Published var showExpertiseUpgrade = false
    @Published var dismissedExpertiseUpgrade = false
    
    private let pipelineService = PipelineServiceBridge()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load saved drafts
        self.promptText = UserDefaults.standard.string(forKey: "draftPrompt") ?? ""
        self.projectName = UserDefaults.standard.string(forKey: "draftProject") ?? ""
        
        // Set up auto-save
        setupAutoSave()
    }
    
    // MARK: - Computed Properties
    
    /// Available stages based on generation mode
    var availableStages: [PipelineStage] {
        switch generationMode {
        case .single:
            // All except segmentation (not needed for single video)
            return PipelineStage.allCases.filter { $0 != .segmentation }
        case .multiClip:
            // Hide segmentation & continuity (auto-applied)
            return [.enhancement, .cameraDirection, .lighting]
        }
    }
    
    /// Auto-enabled stages for multi-clip mode
    var autoEnabledStages: Set<PipelineStage> {
        switch generationMode {
        case .single:
            return []
        case .multiClip:
            // Auto-enable these, don't show as toggles
            return [.segmentation, .continuityAnalysis, .continuityInjection]
        }
    }
    
    /// Get all enabled stages including auto-enabled ones
    var allEnabledStages: Set<PipelineStage> {
        enabledStages.union(autoEnabledStages)
    }
    
    /// Set up auto-save for drafts
    private func setupAutoSave() {
        // Auto-save prompt text
        $promptText
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { text in
                UserDefaults.standard.set(text, forKey: "draftPrompt")
            }
            .store(in: &cancellables)
        
        // Auto-save project name
        $projectName
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { name in
                UserDefaults.standard.set(name, forKey: "draftProject")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Progressive Disclosure
    
    /// Check if user should be upgraded to next expertise level
    func checkExpertiseUpgrade() {
        if videosGenerated >= 10 && expertiseLevel == .beginner && !dismissedExpertiseUpgrade {
            expertiseLevel = .regular
            showExpertiseUpgrade = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if videosGenerated >= 50 && expertiseLevel == .regular && !dismissedExpertiseUpgrade {
            expertiseLevel = .power
            showExpertiseUpgrade = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    /// Get filtered stages based on expertise level
    var filteredAvailableStages: [PipelineStage] {
        let stages = availableStages
        
        switch expertiseLevel {
        case .beginner:
            // Show only essential stages
            return stages.filter { 
                [.enhancement, .lighting].contains($0)
            }
        case .regular:
            // Show common stages
            return stages.filter {
                [.enhancement, .lighting, .cameraDirection].contains($0)
            }
        case .power:
            // Show all stages
            return stages
        }
    }
    
    /// Should show advanced features
    var shouldShowAdvancedFeatures: Bool {
        expertiseLevel != .beginner
    }
    
    /// Load demo content for quick testing
    func loadDemoContent() {
        projectName = "Detective Mystery"
        promptText = """
        A detective in a red leather jacket walks through an abandoned warehouse at sunset. Golden light streams through broken windows, creating dramatic shadows on the dusty floor. Rain begins to fall outside. He stops at a desk, picks up an old photograph, studies it carefully. Camera slowly pushes in on his concerned expression. Moody, film noir atmosphere.
        """
        selectedImage = UIImage(named: "reference_demo")
        useDefaultAdImage = true
        videoDuration = 10.0
        enabledStages = [.enhancement, .cameraDirection, .lighting]
        
        // Show success feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    /// Apply optimal settings for best results
    func applyOptimalSettings() {
        enabledStages = [.continuityAnalysis, .continuityInjection, .enhancement, .lighting]
        videoDuration = 10.0
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    /// Clear all inputs
    func clearAll() {
        promptText = ""
        projectName = ""
        selectedImage = nil
        useDefaultAdImage = false
        videoDuration = 10.0
        
        // Clear saved drafts
        UserDefaults.standard.removeObject(forKey: "draftPrompt")
        UserDefaults.standard.removeObject(forKey: "draftProject")
    }
    
    /// Generate clips using Phase 1 orchestration (for multi-clip projects)
    /// - Parameter coordinator: The app coordinator
    func generateClips(coordinator: AppCoordinator) async {
        guard !promptText.isEmpty else { return }
        
        // Create or update project
        if coordinator.currentProject == nil {
            coordinator.currentProject = Project(
                name: projectName.isEmpty ? "Untitled Project" : projectName,
                description: promptText
            )
        }
        
        guard let project = coordinator.currentProject else { return }
        
        // Update project description with script
        coordinator.currentProject?.description = promptText
        
        isGenerating = true
        defer { isGenerating = false }
        
        // Delegate to AppCoordinator's orchestration system
        await coordinator.startGeneration(for: project)
        
        // Navigate to Studio after generation starts
        coordinator.navigateTo(.studio)
    }
    
    /// Generate a clip from the current prompt (legacy single-clip method)
    func generateClip(coordinator: AppCoordinator) async {
        guard !promptText.isEmpty else { return }
        
        // Pre-flight credit check - use tokens, not legacy credits
        let cost = CreditsManager.shared.creditsNeeded(for: videoDuration, enabledStages: enabledStages)
        
        // Check tokens for all users
        if !useDefaultAdImage && !CreditsManager.shared.canAffordGeneration(tokenCost: cost) {
            generationError = CreditError.insufficientCredits(
                needed: cost,
                have: CreditsManager.shared.tokens
            )
            showingCreditsAlert = true
            return
        }
        
        isGenerating = true
        defer { isGenerating = false }
        
        // Create or update project
        if coordinator.currentProject == nil {
            coordinator.currentProject = Project(name: projectName.isEmpty ? "Untitled Project" : projectName)
        }
        
        guard let project = coordinator.currentProject else { return }
        
        // Generate clip using pipeline
        let clipName = project.nextClipName()
        
        // Convert image to data if present
        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        
        // Log analytics if image is used
        if imageData != nil {
            logImageUsageEvent(isDefaultAd: useDefaultAdImage)
        }
        
        do {
            // ===== NEW STORY-TO-FILM SYSTEM =====
            // User input passed directly - no enhancement here
            // Enhancement now happens in VideoGenerationScreen via StoryToFilmGenerator
            
            print("🎬 [PromptView] Passing user story directly to pipeline...")
            print("   Input: \(promptText.prefix(100))...")
            
            let enhancedPrompt = promptText  // Direct passthrough
            
            // Use all enabled stages including auto-enabled ones
            let finalStages = generationMode == .multiClip ? allEnabledStages : enabledStages
            
            // Generate with enhanced prompt
            let clip = try await pipelineService.generateClip(
                prompt: enhancedPrompt,
                clipName: clipName,
                enabledStages: finalStages,
                referenceImageData: imageData,
                duration: videoDuration
            )
            
            // Add to coordinator
            coordinator.addClip(clip)
            
            // 🖥️ SIMULATOR EXPORT: Auto-save to Desktop during development
            #if DEBUG
            if let videoURL = clip.localURL {
                SimulatorExportHelper.copyToDesktop(
                    from: videoURL,
                    clipName: "\(clipName)_\(clip.id.uuidString.prefix(8))"
                )
            }
            #endif
            
            // Update project clip count
            coordinator.currentProject?.clipCount += 1
            
            // Update videos generated count and check expertise
            videosGenerated += 1
            checkExpertiseUpgrade()
            
            // Navigate to Studio
            coordinator.navigateTo(.studio)
            
            // Clear prompt and image for next input
            promptText = ""
            selectedImage = nil
            useDefaultAdImage = false
            
        } catch {
            print("❌ Clip generation failed: \(error.localizedDescription)")
            generationError = error
            
            // Check if it's a credits error
            if let pipelineError = error as? PipelineError,
               case .configurationError(let message) = pipelineError,
               message.contains("No credits") {
                // Show credits purchase view
                showingCreditsAlert = true
            }
            
            // Haptic feedback for error
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
    
    /// Log analytics event for image usage
    private func logImageUsageEvent(isDefaultAd: Bool) {
        let eventType = isDefaultAd ? "image_generation_default_ad" : "image_generation_custom"
        print("📊 Analytics: \(eventType)")
        // TODO: Integrate with proper analytics service (Telemetry.shared.logEvent)
    }
}


