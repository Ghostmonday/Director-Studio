// MODULE: PromptView
// VERSION: 1.1.0
// PURPOSE: User interface for text prompt input and pipeline configuration

import SwiftUI
import PhotosUI


/// Main prompt input view
struct PromptView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = PromptViewModel()
    @State private var showImagePicker = false
    
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
                
                // Image reference section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Reference Image (Optional)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        if viewModel.selectedImage != nil {
                            Button(action: {
                                viewModel.selectedImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if let image = viewModel.selectedImage {
                        // Show thumbnail preview
                        HStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Image selected")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("Will be used as visual reference")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    } else {
                        // Show image picker button
                        Button(action: {
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 24))
                                Text("Add Reference Image")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .disabled(coordinator.isGuestMode)
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(selectedImage: $viewModel.selectedImage, useDefaultAd: $viewModel.useDefaultAdImage)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Video duration control
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Video Duration")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(viewModel.videoDuration))s")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        Text("3s")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        Slider(value: $viewModel.videoDuration, in: 3...20, step: 1)
                            .disabled(coordinator.isGuestMode)
                        
                        Text("20s")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Pipeline stage toggles
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pipeline Stages")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(PipelineStage.allCases, id: \.self) { stage in
                        HStack {
                            Toggle(stage.displayName, isOn: binding(for: stage))
                                .disabled(coordinator.isGuestMode)
                                .tint(.blue)
                            
                            Button(action: {
                                viewModel.showingStageHelp = stage
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Generate button with loading state
                Button(action: {
                    Task {
                        await viewModel.generateClip(coordinator: coordinator)
                    }
                }) {
                    HStack {
                        if viewModel.isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        Text(viewModel.isGenerating ? "Generating..." : "Generate Clip")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(coordinator.isGuestMode ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isGenerating)
                }
                .padding()
                .disabled(coordinator.isGuestMode || viewModel.isGenerating)
                .opacity(viewModel.isGenerating ? 0.8 : 1.0)
                
                if coordinator.isGuestMode {
                    Text("Sign in to iCloud to create content")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Prompt")
            .sheet(item: $viewModel.showingStageHelp) { stage in
                StageHelpView(stage: stage)
            }
            .alert("Generation Failed", isPresented: .constant(viewModel.generationError != nil)) {
                Button("OK") {
                    viewModel.generationError = nil
                }
            } message: {
                Text(viewModel.generationError?.localizedDescription ?? "An error occurred")
            }
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

/// Image picker for reference image selection
struct ImagePicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedImage: UIImage?
    @Binding var useDefaultAd: Bool
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Default ad.png option
                Button(action: {
                    if let adImage = UIImage(named: "ad") {
                        selectedImage = adImage
                        useDefaultAd = true
                        dismiss()
                    }
                }) {
                    HStack {
                        if let adImage = UIImage(named: "ad") {
                            Image(uiImage: adImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Use Default Demo Image")
                                .font(.headline)
                            Text("DirectorStudio promotional reference")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Photo library picker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 30))
                        
                        VStack(alignment: .leading) {
                            Text("Choose from Library")
                                .font(.headline)
                            Text("Select your own reference image")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImage = image
                            useDefaultAd = false
                            dismiss()
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Select Reference Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

