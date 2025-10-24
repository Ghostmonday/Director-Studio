// MODULE: PromptViewModel
// VERSION: 1.2.0
// PURPOSE: Business logic for prompt input and clip generation with demo mode & auto-save

import Foundation
import SwiftUI
import Combine

/// Pipeline stages that can be toggled
enum PipelineStage: String, CaseIterable {
    case segmentation = "Segmentation"
    case continuityAnalysis = "Continuity Analysis"
    case continuityInjection = "Continuity Injection"
    case enhancement = "Enhancement"
    case cameraDirection = "Camera Direction"
    case lighting = "Lighting"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
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
    @Published var showingStageHelp: PipelineStage? = nil
    @Published var generationError: Error? = nil
    @Published var showingDemoAlert = false
    @Published var showingCreditsAlert = false
    
    private let pipelineService = PipelineServiceBridge()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load saved drafts
        self.promptText = UserDefaults.standard.string(forKey: "draftPrompt") ?? ""
        self.projectName = UserDefaults.standard.string(forKey: "draftProject") ?? ""
        
        // Set up auto-save
        setupAutoSave()
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
    
    /// Load demo content for quick testing
    func loadDemoContent() {
        projectName = "My Cinematic Journey"
        promptText = """
        A lone detective enters a dimly lit warehouse at dusk. 
        Rain drums against broken windows. His red jacket catches 
        the last rays of sunlight as he searches for clues.
        The atmosphere is tense, mysterious, with long shadows 
        stretching across the dusty concrete floor.
        """
        selectedImage = UIImage(named: "ad")
        useDefaultAdImage = true
        videoDuration = 10.0
        enabledStages = [.continuityAnalysis, .continuityInjection, .enhancement, .lighting]
        
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
    
    /// Generate a clip from the current prompt
    func generateClip(coordinator: AppCoordinator) async {
        guard !promptText.isEmpty else { return }
        
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
            let clip = try await pipelineService.generateClip(
                prompt: promptText,
                clipName: clipName,
                enabledStages: enabledStages,
                referenceImageData: imageData,
                isFeaturedDemo: useDefaultAdImage,
                duration: videoDuration
            )
            
            // Add to coordinator
            coordinator.addClip(clip)
            
            // Update project clip count
            coordinator.currentProject?.clipCount += 1
            
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

// MARK: - Prompt Templates

struct PromptTemplate: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let prompt: String
    let suggestedDuration: Double
    let suggestedStages: Set<PipelineStage>
}

extension PromptViewModel {
    static let promptTemplates = [
        PromptTemplate(
            category: "Action",
            title: "Epic Chase Scene",
            prompt: "An intense motorcycle chase through neon-lit Tokyo streets at night. The protagonist weaves between traffic as rain reflects the city lights. Sparks fly as metal scrapes asphalt.",
            suggestedDuration: 15,
            suggestedStages: [.enhancement, .cameraDirection, .lighting]
        ),
        PromptTemplate(
            category: "Drama",
            title: "Emotional Farewell",
            prompt: "A tearful goodbye at a rain-soaked train station. Two silhouettes embrace on the platform as steam rises from the tracks. The departure bell echoes through the misty air.",
            suggestedDuration: 10,
            suggestedStages: [.continuityAnalysis, .continuityInjection, .enhancement, .lighting]
        ),
        PromptTemplate(
            category: "Sci-Fi",
            title: "Space Discovery",
            prompt: "A massive alien spacecraft emerges from a swirling purple nebula. Its crystalline hull reflects distant stars as smaller ships scatter like fireflies.",
            suggestedDuration: 12,
            suggestedStages: [.enhancement, .cameraDirection]
        ),
        PromptTemplate(
            category: "Horror",
            title: "Abandoned Hospital",
            prompt: "Flickering fluorescent lights illuminate a long hospital corridor. Shadows move between doorways as a wheelchair slowly rolls past, its wheels squeaking eerily.",
            suggestedDuration: 8,
            suggestedStages: [.enhancement, .lighting]
        ),
        PromptTemplate(
            category: "Fantasy",
            title: "Dragon's Awakening",
            prompt: "An ancient dragon stirs in its mountain lair. Golden eyes open as treasure cascades from its scales. Smoke curls from its nostrils, illuminated by pools of molten gold.",
            suggestedDuration: 10,
            suggestedStages: [.enhancement, .cameraDirection, .lighting]
        )
    ]
    
    func applyTemplate(_ template: PromptTemplate) {
        promptText = template.prompt
        videoDuration = template.suggestedDuration
        enabledStages = template.suggestedStages
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

