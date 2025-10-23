// MODULE: PromptViewModel
// VERSION: 1.1.0
// PURPOSE: Business logic for prompt input and clip generation

import Foundation
import SwiftUI

/// Pipeline stages that can be toggled
enum PipelineStage: String, CaseIterable {
    case segmentation = "Segmentation"
    case enhancement = "Enhancement"
    case cameraDirection = "Camera Direction"
    case continuity = "Continuity"
    case lighting = "Lighting"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .segmentation:
            return "Break script into logical segments"
        case .enhancement:
            return "Enhance visual descriptions"
        case .cameraDirection:
            return "Add camera movement and angles"
        case .continuity:
            return "Ensure visual consistency across clips"
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
    
    private let pipelineService = PipelineService()
    
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

