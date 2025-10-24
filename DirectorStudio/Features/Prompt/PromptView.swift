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
            ScrollView {
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
                
                // How it works section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "film.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Script to Screen")
                                .font(.headline)
                            Text("Transform your written script into cinematic videos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Project name input
                TextField("Project Name", text: $viewModel.projectName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .disabled(coordinator.isGuestMode)
                
                // Prompt text input with better guidance
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Script Your Scene", systemImage: "doc.text.magnifyingglass")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Button(action: {
                            showTemplates = true
                        }) {
                            Text("Use Template")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $viewModel.promptText)
                            .frame(minHeight: 150)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(viewModel.promptText.isEmpty ? Color.gray.opacity(0.3) : Color.blue.opacity(0.5), lineWidth: 1)
                            )
                            .disabled(coordinator.isGuestMode)
                        
                        if viewModel.promptText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Write your scene like a movie script:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                
                                Text("• Characters and their actions\n• Setting and environment\n• Dialogue or narration\n• Camera angles and mood")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            .padding(12)
                            .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Image reference section with explanation
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Reference Image", systemImage: "photo")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("(Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if viewModel.selectedImage != nil {
                            Button(action: {
                                viewModel.selectedImage = nil
                                viewModel.useDefaultAdImage = false
                            }) {
                                Label("Remove", systemImage: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("Add an image to guide the visual style, composition, or mood of your video")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                
                        // Quality Tier Selection (Coming Soon)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Video Quality", systemImage: "sparkles.tv")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("Coming Soon")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            Text("Multiple quality tiers will be available in the next update")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                
                // Pipeline stage toggles with better organization
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("AI Enhancement Options", systemImage: "cpu")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            viewModel.applyOptimalSettings()
                        }) {
                            Text("Optimal")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("Enable AI features to enhance your video quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ForEach(PipelineStage.allCases, id: \.self) { stage in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Toggle(isOn: binding(for: stage)) {
                                    HStack {
                                        Text(stage.displayName)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        if stage == .enhancement {
                                            Text("+2")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.2))
                                                .foregroundColor(.orange)
                                                .cornerRadius(8)
                                        } else if stage == .continuityAnalysis || stage == .continuityInjection || stage == .cameraDirection || stage == .lighting {
                                            Text("+1")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.2))
                                                .foregroundColor(.blue)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .disabled(coordinator.isGuestMode)
                                .tint(.blue)
                                
                                Text(stage.description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Button(action: {
                                viewModel.showingStageHelp = stage
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.blue.opacity(0.6))
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                
                Spacer()
                
                // Credits and Cost Display
                VStack(spacing: 8) {
                    // Current credits
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
                    
                    // Cost estimation with new billing
                    if !viewModel.promptText.isEmpty {
                        // Simplified cost calculation for launch
                        let estimatedCredits = Int(ceil(viewModel.videoDuration / 5.0))
                        let estimatedCost = Double(estimatedCredits) * 0.50 // $0.50 per credit estimate
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(estimatedCredits) credits • $\(String(format: "%.2f", estimatedCost))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                if estimatedCredits == 1 {
                                    Text("Minimum 1 credit")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                            
                            // Button(action: { viewModel.showingCostBreakdown = true }) {
                            //     Text("See breakdown")
                            //         .font(.caption2)
                            //         .underline()
                            // }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 4)
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
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle("Script")
            .navigationBarTitleDisplayMode(.large)
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
            // .sheet(isPresented: $viewModel.showingCostBreakdown) {
            //     CostBreakdownSheet(viewModel: viewModel)
            // }
            .sheet(isPresented: $viewModel.showingPromptHelp) {
                PromptHelpSheet()
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
                    if let adImage = UIImage(named: "reference_demo") {
                        selectedImage = adImage
                        useDefaultAd = true
                        dismiss()
                    }
                }) {
                    HStack {
                        if let adImage = UIImage(named: "reference_demo") {
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

// MARK: - Cost Breakdown Sheet

/*
struct CostBreakdownSheet: View {
    @ObservedObject var viewModel: PromptViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Simplified cost calculation for launch
                let estimatedCredits = Int(ceil(viewModel.videoDuration / 5.0))
                let totalCost = Double(estimatedCredits) * 0.50 // $0.50 per credit
                
                // Total Cost Header
                VStack(spacing: 8) {
                    Text("Total Cost")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("$\(String(format: "%.2f", totalCost))")
                            .font(.system(size: 48, weight: .bold))
                    }
                    
                    HStack(spacing: 12) {
                        Label("\(estimatedCredits) credits", systemImage: "circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Breakdown Details
                VStack(alignment: .leading, spacing: 16) {
                    // Pricing breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pricing Details")
                            .font(.headline)
                        
                        // Duration
                        HStack {
                            Label("Duration", systemImage: "timer")
                            Spacer()
                            Text("\(Int(viewModel.videoDuration)) seconds")
                                .fontWeight(.medium)
                        }
                        
                                // Quality (coming soon)
                                HStack {
                                    Label("Quality", systemImage: "sparkles.tv")
                                    Spacer()
                                    Text("Standard")
                                        .fontWeight(.medium)
                                }
                        
                        // Credit calculation
                        HStack {
                            Label("Credit Calculation", systemImage: "function")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(viewModel.videoDuration))s ÷ 5 = \(estimatedCredits) credits")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Rate
                        HStack {
                            Label("Rate", systemImage: "dollarsign.circle")
                            Spacer()
                            Text("$0.50/credit")
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                
                // Info
                Label("Credits are deducted when generation starts", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Cost Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
*/

// MARK: - Prompt Help Sheet

// MARK: - Quality Tier Button

/*
struct QualityTierButton: View {
    let tier: VideoQualityTier
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(tier.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(tier.resolution)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    Text("\(tier.tokenMultiplier, specifier: "%.1f")x")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .white : .orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(isSelected ? Color.orange : Color.orange.opacity(0.2))
                .cornerRadius(10)
            }
            .frame(minWidth: 80)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}
*/

struct PromptHelpSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // How it works diagram
                    VStack(spacing: 16) {
                        Text("How DirectorStudio Works")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            // Step 1
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: "1.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Describe Your Scene")
                                        .font(.headline)
                                    Text("Write what you want to see: characters, actions, setting, mood")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            
                            Image(systemName: "arrow.down")
                                .foregroundColor(.gray)
                            
                            // Step 2
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: "2.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI Enhancement")
                                        .font(.headline)
                                    Text("Your text is enhanced with cinematic details and visual elements")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            
                            Image(systemName: "arrow.down")
                                .foregroundColor(.gray)
                            
                            // Step 3
                            HStack(alignment: .top, spacing: 16) {
                                Image(systemName: "3.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Video Generation")
                                        .font(.headline)
                                    Text("AI creates a video matching your description")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Writing Great Prompts")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Be Visual", systemImage: "eye")
                                .font(.subheadline)
                            Text("Focus on what can be seen: appearance, actions, environment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 28)
                            
                            Label("Set the Mood", systemImage: "cloud.sun")
                                .font(.subheadline)
                            Text("Describe lighting, weather, time of day, atmosphere")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 28)
                            
                            Label("Add Movement", systemImage: "figure.walk")
                                .font(.subheadline)
                            Text("Include actions and camera movements for dynamic videos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 28)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    
                    // Reference image explanation
                    VStack(alignment: .leading, spacing: 12) {
                        Label("About Reference Images", systemImage: "photo")
                            .font(.headline)
                        
                        Text("Adding a reference image helps guide:")
                            .font(.subheadline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Visual style and aesthetic")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Color palette and mood")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Composition and framing")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("How It Works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

