// MODULE: SceneEditorView
// VERSION: 1.0.0
// PURPOSE: Scene editor UI with optimistic creates

import SwiftUI

struct SceneEditorView: View {
    @StateObject private var viewModel = SceneEditorViewModel()
    @State private var projectId: String
    @State private var showingAddScene = false
    
    init(projectId: String) {
        self.projectId = projectId
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Scenes List
            scenesList
        }
        .background(Color(.systemBackground))
        .onAppear {
            viewModel.loadScenes(projectId: projectId)
        }
        .sheet(isPresented: $showingAddScene) {
            AddSceneView(projectId: projectId)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Scenes")
                .font(.system(size: 32, weight: .bold))
            
            Spacer()
            
            Button(action: {
                showingAddScene = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 44)
        .padding(.bottom, 16)
    }
    
    private var scenesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.scenes.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.scenes) { scene in
                        SceneRow(scene: scene, onDelete: {
                            viewModel.deleteScene(id: scene.id)
                        })
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Scenes Yet")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Add your first scene to begin")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 60)
    }
}

struct SceneRow: View {
    let scene: SceneDraft
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Scene Number
            Text("\(scene.orderIndex + 1)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.accentColor)
                .cornerRadius(12)
            
            // Scene Info
            VStack(alignment: .leading, spacing: 4) {
                Text(scene.promptText)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(2)
                
                Text("\(Int(scene.duration))s")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Delete Button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct AddSceneView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = SceneEditorViewModel()
    @State private var promptText = ""
    @State private var duration: Double = 10
    
    let projectId: String
    
    var body: some View {
        NavigationView {
            Form {
                Section("Scene Details") {
                    TextField("Prompt", text: $promptText)
                    Stepper("Duration: \(Int(duration))s", value: $duration, in: 5...60, step: 5)
                }
            }
            .navigationTitle("Add Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.createSceneOptimistic(prompt: promptText, duration: duration)
                        dismiss()
                    }
                    .disabled(promptText.isEmpty)
                }
            }
        }
    }
}

#Preview {
    SceneEditorView(projectId: "test-project")
}

