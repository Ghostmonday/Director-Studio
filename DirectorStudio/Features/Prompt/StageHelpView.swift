// MODULE: StageHelpView
// VERSION: 1.0.0
// PURPOSE: Help sheet for pipeline stages

import SwiftUI

struct StageHelpView: View {
    let stage: PipelineStage
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Icon and title
                HStack(spacing: 16) {
                    Image(systemName: stage.icon)
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    Text(stage.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .padding(.top)
                
                // Description
                Text(stage.description)
                    .font(.title3)
                    .foregroundColor(.primary)
                
                // Detailed explanation
                VStack(alignment: .leading, spacing: 16) {
                    Label("How it works", systemImage: "gearshape.fill")
                        .font(.headline)
                    
                    Text(stage.detailedExplanation)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if !stage.examples.isEmpty {
                        Label("Examples", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(stage.examples, id: \.self) { example in
                            HStack(alignment: .top) {
                                Text("•")
                                Text(example)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension PipelineStage: Identifiable {
    public var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .segmentation: return "scissors"
        case .enhancement: return "wand.and.stars"
        case .cameraDirection: return "video.fill"
        case .continuity: return "link.circle.fill"
        case .lighting: return "light.max"
        }
    }
    
    var detailedExplanation: String {
        switch self {
        case .segmentation:
            return "Intelligently breaks your story into optimal video segments. Each segment is analyzed for pacing, emotional beats, and natural transition points to create a cinematic flow."
            
        case .enhancement:
            return "Uses AI to enrich your prompts with vivid visual details, atmospheric elements, and cinematic language that video generation models understand best."
            
        case .cameraDirection:
            return "Adds professional camera movements like pans, zooms, and tracking shots. Considers the emotional tone of each scene to choose appropriate cinematography."
            
        case .continuity:
            return "Ensures visual consistency across your entire video. Tracks characters, objects, locations, and visual themes to maintain coherence from scene to scene."
            
        case .lighting:
            return "Optimizes lighting and mood for each scene. Considers time of day, emotional tone, and genre to create the perfect atmosphere."
        }
    }
    
    var examples: [String] {
        switch self {
        case .segmentation:
            return [
                "A 2-minute story becomes 3 clips of 40 seconds each",
                "Dialogue scenes are kept together",
                "Action sequences get their own segments"
            ]
            
        case .enhancement:
            return [
                "\"A dark room\" → \"A dimly lit room with shadows dancing on weathered walls\"",
                "\"She was sad\" → \"Tears glistened as she gazed through rain-streaked windows\""
            ]
            
        case .cameraDirection:
            return [
                "Intimate moments: Slow push-in close-ups",
                "Action scenes: Dynamic handheld movement",
                "Establishing shots: Wide angles with subtle drift"
            ]
            
        case .continuity:
            return [
                "Character clothing remains consistent",
                "Weather conditions match across scenes",
                "Props and objects maintain their positions"
            ]
            
        case .lighting:
            return [
                "Horror: Deep shadows and stark contrasts",
                "Romance: Soft, warm golden hour lighting",
                "Thriller: Cold blue tones with harsh highlights"
            ]
        }
    }
}
