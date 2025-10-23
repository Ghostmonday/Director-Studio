// MODULE: PromptViewModel
// VERSION: 1.0.0
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
        
        do {
            let clip = try await pipelineService.generateClip(
                prompt: promptText,
                clipName: clipName,
                enabledStages: enabledStages
            )
            
            // Add to coordinator
            coordinator.addClip(clip)
            
            // Update project clip count
            coordinator.currentProject?.clipCount += 1
            
            // Navigate to Studio
            coordinator.navigateTo(.studio)
            
            // Clear prompt for next input
            promptText = ""
            
        } catch {
            print("❌ Clip generation failed: \(error.localizedDescription)")
        }
    }
}

