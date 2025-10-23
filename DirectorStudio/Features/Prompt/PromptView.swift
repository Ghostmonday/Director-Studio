// MODULE: PromptView
// VERSION: 1.0.0
// PURPOSE: User interface for text prompt input and pipeline configuration

import SwiftUI

/// Main prompt input view
struct PromptView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = PromptViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Project name input
                TextField("Project Name (e.g., Dante's Inferno)", text: $viewModel.projectName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .disabled(coordinator.isGuestMode)
                
                // Prompt text input
                TextEditor(text: $viewModel.promptText)
                    .frame(minHeight: 150)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .disabled(coordinator.isGuestMode)
                
                if viewModel.promptText.isEmpty {
                    Text("Enter your scene description...")
                        .foregroundColor(.gray)
                        .padding(.top, -160)
                }
                
                // Pipeline stage toggles
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pipeline Stages")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(PipelineStage.allCases, id: \.self) { stage in
                        HStack {
                            Toggle(stage.displayName, isOn: binding(for: stage))
                                .disabled(coordinator.isGuestMode)
                            
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .help(stage.description)
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Generate button
                Button(action: {
                    Task {
                        await viewModel.generateClip(coordinator: coordinator)
                    }
                }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Generate Clip")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(coordinator.isGuestMode ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .disabled(coordinator.isGuestMode || viewModel.isGenerating)
                .opacity(viewModel.isGenerating ? 0.6 : 1.0)
                
                if coordinator.isGuestMode {
                    Text("Sign in to iCloud to create content")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Prompt")
        }
    }
    
    private func binding(for stage: PipelineStage) -> Binding<Bool> {
        Binding(
            get: { viewModel.enabledStages.contains(stage) },
            set: { enabled in
                if enabled {
                    viewModel.enabledStages.insert(stage)
                } else {
                    viewModel.enabledStages.remove(stage)
                }
            }
        )
    }
}

