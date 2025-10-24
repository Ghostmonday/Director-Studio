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
    @State private var showTemplates = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Quick action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.loadDemoContent()
                    }) {
                        Label("Demo", systemImage: "play.circle.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                    
                    Button(action: {
                        showTemplates = true
                    }) {
                        Label("Templates", systemImage: "doc.text.fill")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    Button(action: {
                        viewModel.applyOptimalSettings()
                    }) {
                        Label("Optimal", systemImage: "wand.and.stars")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    
                    Spacer()
                    
                    if !viewModel.promptText.isEmpty {
                        Button(action: {
                            viewModel.clearAll()
                        }) {
                            Image(systemName: "trash")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding(.horizontal)
                
                // Project name input
                TextField("Project Name (e.g., Dante's Inferno)", text: $viewModel.projectName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
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
                
                // Credits Display
                HStack {
                    if CreditsManager.shared.credits == 0 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Demo Mode - Purchase credits for real AI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                        Text("\(CreditsManager.shared.credits) credits remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    NavigationLink(destination: CreditsPurchaseView()) {
                        Text("Get Credits")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
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
            .sheet(isPresented: $showTemplates) {
                TemplatesSheet(viewModel: viewModel, isPresented: $showTemplates)
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

// MARK: - Templates Sheet

struct TemplatesSheet: View {
    @ObservedObject var viewModel: PromptViewModel
    @Binding var isPresented: Bool
    @State private var selectedCategory: String = "All"
    
    var categories: [String] {
        ["All"] + Array(Set(PromptViewModel.promptTemplates.map { $0.category })).sorted()
    }
    
    var filteredTemplates: [PromptTemplate] {
        if selectedCategory == "All" {
            return PromptViewModel.promptTemplates
        }
        return PromptViewModel.promptTemplates.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category picker
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTemplates) { template in
                            TemplateCard(template: template) {
                                viewModel.applyTemplate(template)
                                isPresented = false
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Prompt Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct TemplateCard: View {
    let template: PromptTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Label(template.category, systemImage: "tag.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Label("\(Int(template.suggestedDuration))s", systemImage: "timer")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Text(template.prompt)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Suggested stages
                HStack {
                    ForEach(Array(template.suggestedStages.prefix(3)), id: \.self) { stage in
                        Text(stage.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    if template.suggestedStages.count > 3 {
                        Text("+\(template.suggestedStages.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

