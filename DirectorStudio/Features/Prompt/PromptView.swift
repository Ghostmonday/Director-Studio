// MODULE: PromptView
// VERSION: 1.1.0
// PURPOSE: User interface for text prompt input and pipeline configuration

import SwiftUI
import PhotosUI


/// Main prompt input view
struct PromptView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = PromptViewModel()
    @ObservedObject private var creditsManager = CreditsManager.shared
    @State private var showImagePicker = false
    @State private var showTemplates = false
    @State private var showSegmentEditor = false
    @State private var showVideoGenerationScreen = false
    @State private var scriptForGeneration = ""
    @State private var showingInsufficientCredits = false
    @State private var insufficientCreditsInfo: (needed: Int, have: Int) = (0, 0)
    @State private var showingPurchaseView = false
    
    // UX State
    @State private var isPromptExpanded = true
    @FocusState private var isPromptFocused: Bool
    @State private var isPromptConfirmed = false // Tracks if user has confirmed their prompt
    
    // MARK: - Computed Views
    
    @ViewBuilder
    private var quickActionButtons: some View {
        HStack(spacing: 12) {
            // Demo button removed - all users have full access
            
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
    }
    
    @ViewBuilder
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "film.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Script to Screen")
                        .font(.headline)
                    Text("Write your scene. Watch it render.")
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
    }
    
    @ViewBuilder
    private var generationModeSelector: some View {
        VStack(spacing: 12) {
            Text("What are you creating?")
                .font(.headline)
            
            Picker("Generation Mode", selection: $viewModel.generationMode) {
                ForEach(GenerationMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Text(viewModel.generationMode.description)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var projectNameField: some View {
        TextField("Project Name", text: $viewModel.projectName)
            .textFieldStyle(.roundedBorder)
            .padding(.horizontal)
    }
    
    @ViewBuilder
    private var promptTextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Script Your Scene", systemImage: "doc.text.magnifyingglass")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                
                // Expand/Collapse button (only show when collapsed)
                if !isPromptExpanded && !viewModel.promptText.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isPromptExpanded = true
                        }
                        isPromptFocused = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                            Text("Expand")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
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
                    .frame(minHeight: isPromptExpanded ? 150 : 60)
                    .frame(maxHeight: isPromptExpanded ? .infinity : 60)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isPromptFocused ? Color.blue : (viewModel.promptText.isEmpty ? Color.gray.opacity(0.3) : Color.blue.opacity(0.5)), lineWidth: isPromptFocused ? 2 : 1)
                    )
                    .focused($isPromptFocused)
                    .onChange(of: isPromptFocused) { _, isFocused in
                        if !isFocused && !viewModel.promptText.isEmpty {
                            // Auto-collapse when focus is lost
                            withAnimation(.spring(response: 0.3)) {
                                isPromptExpanded = false
                            }
                        } else if isFocused {
                            // Auto-expand when focused
                            withAnimation(.spring(response: 0.3)) {
                                isPromptExpanded = true
                            }
                        }
                    }
                    .onChange(of: viewModel.promptText) { _, _ in
                        // Reset confirmation if prompt changes
                        if isPromptConfirmed {
                            isPromptConfirmed = false
                            #if DEBUG
                            print("⚠️ [PromptView] Prompt changed - confirmation reset")
                            #endif
                        }
                    }
                
                if viewModel.promptText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Describe your scene:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        if isPromptExpanded {
                            Text("• Who's in the shot and what they're doing\n• Location, time of day, lighting\n• Camera movement and framing\n• Mood and atmosphere")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    .padding(12)
                    .allowsHitTesting(false)
                }
                
                // Show truncated text when collapsed
                if !isPromptExpanded && !viewModel.promptText.isEmpty {
                    Text(viewModel.promptText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(12)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal)
            .animation(.spring(response: 0.3), value: isPromptExpanded)
        }
    }
    
    @ViewBuilder
    private var imageReferenceSection: some View {
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
            
            Text("Upload a reference to guide style, tone, and composition")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if let image = viewModel.selectedImage {
                imagePreview(image: image)
            } else {
                imagePickerButton
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func imagePreview(image: UIImage) -> some View {
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
    }
    
    @ViewBuilder
    private var imagePickerButton: some View {
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
    }
    
    @ViewBuilder
    private var durationStrategySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Clip Duration Strategy")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 8) {
                // Uniform duration option
                HStack {
                    Image(systemName: viewModel.durationStrategy == .uniform(viewModel.uniformDuration) ? "circle.fill" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            viewModel.durationStrategy = .uniform(viewModel.uniformDuration)
                        }
                    
                    Text("All clips same length")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    if case .uniform = viewModel.durationStrategy {
                        HStack {
                            Text("\(Int(viewModel.uniformDuration))s")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Stepper("", value: $viewModel.uniformDuration, in: 3...30, step: 1)
                                .labelsHidden()
                        }
                    }
                }
                .padding(.horizontal)
                
                // Custom duration option
                HStack {
                    Image(systemName: viewModel.durationStrategy == .custom ? "circle.fill" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            viewModel.durationStrategy = .custom
                        }
                    
                    Text("Custom per clip")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    if case .custom = viewModel.durationStrategy {
                        Text("Set in editor")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                
                // Auto duration option
                HStack {
                    Image(systemName: viewModel.durationStrategy == .auto ? "circle.fill" : "circle")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            viewModel.durationStrategy = .auto
                        }
                    
                    Text("Auto-detect from content")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    if case .auto = viewModel.durationStrategy {
                        Text("AI decides")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var videoDurationControl: some View {
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
                
                Text("20s")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var qualityTierSection: some View {
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
            
            Text("Quality tiers launching soon")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private var pipelineStageToggles: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Pipeline Controls", systemImage: "cpu")
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
            
            Text("Toggle stages to balance quality, speed, and cost")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ForEach(viewModel.availableStages, id: \.self) { stage in
                pipelineStageRow(for: stage)
            }
            
            // Info about auto-enabled stages for multi-clip
            if viewModel.generationMode == .multiClip {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Segmentation & continuity are automatically applied for films")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    @ViewBuilder
    private func pipelineStageRow(for stage: PipelineStage) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Toggle(isOn: binding(for: stage)) {
                    HStack {
                        Text(stage.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if stage == .enhancement {
                            creditBadge("+2", color: .orange)
                        } else if stage == .continuityAnalysis || stage == .continuityInjection || stage == .cameraDirection || stage == .lighting {
                            creditBadge("+1", color: .blue)
                        }
                    }
                }
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
    
    @ViewBuilder
    private func creditBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
    
    @ViewBuilder
    private var creditsAndCostDisplay: some View {
        VStack(spacing: 8) {
            currentCreditsRow
            
            // Only show cost for single-clip mode (multi-clip shows cost in its own flow)
            if !viewModel.promptText.isEmpty && viewModel.generationMode == .single {
                costEstimationRow
            } else if viewModel.generationMode == .multiClip && !viewModel.promptText.isEmpty {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Cost will be calculated after you review prompts and set durations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var currentCreditsRow: some View {
        HStack {
            if CreditsManager.shared.credits == 0 {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Preview mode — Purchase credits to render")
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
            NavigationLink(destination: EnhancedCreditsPurchaseView()) {
                Text("Get Credits")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
    }
    
    @ViewBuilder
    private var costEstimationRow: some View {
        HStack {
            Image(systemName: isPromptConfirmed ? "info.circle" : "clock.badge.questionmark")
                .font(.caption)
                .foregroundColor(isPromptConfirmed ? .primary : .orange)
            
            if isPromptConfirmed {
                // Show actual cost only after prompt is confirmed
                let duration = viewModel.generationMode == .single ? viewModel.videoDuration : estimateTotalDuration()
                let priceCents = MonetizationConfig.priceForSeconds(duration)
                let tokens = creditsManager.creditsNeeded(for: duration, enabledStages: viewModel.enabledStages)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(duration))s • \(tokens) tokens • \(MonetizationConfig.formatPrice(priceCents))")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("$0.15 per second")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                // Show pending state
                VStack(alignment: .leading, spacing: 2) {
                    Text("Cost: Pending...")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    
                    Text("Confirm your prompt to see final cost")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Optional: Show live preview if enabled
            if !isPromptConfirmed && viewModel.generationMode == .single {
                Button(action: {
                    // Show live preview tooltip
                }) {
                    Text("Preview")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var confirmPromptButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                isPromptConfirmed = true
            }
            #if DEBUG
            print("✅ [PromptView] Prompt confirmed - cost calculation enabled")
            #endif
        }) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Confirm Prompt")
                        .font(.headline)
                    Text("Lock in your script to see final cost")
                        .font(.caption)
                        .opacity(0.8)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [.green, .teal],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var generateSection: some View {
        let creditCost = creditsManager.creditsNeeded(
            for: viewModel.videoDuration,
            enabledStages: viewModel.enabledStages
        )
        let hasEnoughCredits = viewModel.useDefaultAdImage || creditsManager.canGenerate(cost: creditCost)
        
        VStack(spacing: 8) {
            if creditsManager.isDevMode {
                devModeIndicator
            }
            
            creditStatusRow(creditCost: creditCost, hasEnoughCredits: hasEnoughCredits)
            
            generateButton(creditCost: creditCost, hasEnoughCredits: hasEnoughCredits)
            
            if creditsManager.shouldPromptPurchase && !viewModel.useDefaultAdImage {
                purchasePromptButton
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var devModeIndicator: some View {
        HStack {
            Image(systemName: "hammer.fill")
                .foregroundColor(.purple)
            Text("DEV MODE - Free Usage")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.purple)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func creditStatusRow(creditCost: Int, hasEnoughCredits: Bool) -> some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundColor(creditsManager.isDevMode ? .purple : (hasEnoughCredits ? .green : .orange))
            Text(creditsManager.isDevMode ? "FREE" : "Cost: \(creditCost) credit\(creditCost == 1 ? "" : "s")")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(creditsManager.isDevMode ? "Dev Mode" : "Balance: \(creditsManager.credits)")
                .font(.subheadline)
                .foregroundColor(creditsManager.isDevMode ? .purple : (hasEnoughCredits ? .primary : .red))
                .fontWeight(.semibold)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func generateButton(creditCost: Int, hasEnoughCredits: Bool) -> some View {
        // Guardrails for generation readiness
        let promptReady = !viewModel.promptText.isEmpty
        let singleClipReady = viewModel.generationMode == .single ? isPromptConfirmed : true
        let multiClipReady = viewModel.generationMode == .multiClip ? true : false // Multi-clip has its own flow
        let canGenerate = promptReady && hasEnoughCredits && (singleClipReady || multiClipReady)
        
        // Determine why generation is blocked
        let blockReason: String? = {
            if !promptReady { return "Enter a prompt first" }
            if viewModel.generationMode == .single && !isPromptConfirmed { return "Confirm your prompt to continue" }
            if !hasEnoughCredits { return "Insufficient credits" }
            return nil
        }()
        
        return Button(action: {
            // Guardrail: Check if prompt exists
            guard promptReady else {
                #if DEBUG
                print("⚠️ [Generate] Blocked: No prompt text")
                #endif
                return
            }
            
            // Guardrail: Check if prompt is confirmed (single-clip only)
            if viewModel.generationMode == .single && !isPromptConfirmed {
                #if DEBUG
                print("⚠️ [Generate] Blocked: Prompt not confirmed")
                #endif
                return
            }
            
            if viewModel.generationMode == .single {
                // Single clip generation
                if !creditsManager.canGenerate(cost: creditCost) {
                    insufficientCreditsInfo = (needed: creditCost, have: creditsManager.credits)
                    showingInsufficientCredits = true
                } else {
                    Task {
                        await viewModel.generateClip(coordinator: coordinator)
                    }
                }
            } else {
                // Multi-clip generation - launch VideoGenerationScreen
                scriptForGeneration = viewModel.promptText
                showVideoGenerationScreen = true
            }
        }) {
            HStack(spacing: 12) {
                if viewModel.isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: canGenerate ? 
                          (viewModel.generationMode == .single ? "wand.and.stars" : "film.stack.fill") : 
                          "lock.fill")
                        .font(.system(size: 20))
                }
                
                VStack(spacing: 2) {
                    if viewModel.isGenerating {
                        Text("Generating...")
                            .font(.headline)
                    } else if let reason = blockReason {
                        Text(reason)
                            .font(.headline)
                    } else {
                        Text(viewModel.generationMode == .single ? "Generate Video" : "Generate Multiple Clips")
                            .font(.headline)
                    }
                    
                    if !viewModel.isGenerating {
                        if viewModel.generationMode == .multiClip && canGenerate {
                            Text("Review prompts, set durations, confirm cost")
                                .font(.caption)
                                .opacity(0.8)
                        } else if !canGenerate && viewModel.generationMode == .single && !isPromptConfirmed {
                            Text("Use 'Confirm Prompt' button above")
                                .font(.caption)
                                .opacity(0.8)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: !canGenerate ? [.gray] : (viewModel.generationMode == .single ? [.blue, .cyan] : [.purple, .pink]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: canGenerate ? (viewModel.generationMode == .single ? .blue.opacity(0.3) : .purple.opacity(0.3)) : .clear, radius: 8, y: 4)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isGenerating)
        }
        .disabled(viewModel.isGenerating || !canGenerate)
        .opacity(viewModel.isGenerating ? 0.8 : 1.0)
    }
    
    @ViewBuilder
    private var multiClipButton: some View {
        Button(action: {
            scriptForGeneration = viewModel.promptText
            showVideoGenerationScreen = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Generate Multiple Clips")
                            .font(.headline)
                        
                        Label("NEW", systemImage: "sparkle")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .cornerRadius(6)
                    }
                    
            Text("Break your script into scenes with automatic continuity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.purple)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.purple.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(viewModel.isGenerating || viewModel.promptText.isEmpty)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var purchasePromptButton: some View {
        Button(action: {
            showingPurchaseView = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Get More Credits")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
        }
        .padding(.top, 4)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Testing mode banner
                    if let bannerText = TestingMode.bannerText {
                        HStack(spacing: 12) {
                            Image(systemName: "flask.fill")
                                .foregroundColor(.orange)
                            Text(bannerText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    quickActionButtons
                    
                    generationModeSelector
                    
                    howItWorksSection
                    
                    projectNameField
                    
                    promptTextSection
                    
                    imageReferenceSection
                    
                    if viewModel.generationMode == .single {
                        videoDurationControl
                    } else {
                        durationStrategySection
                    }
                    
                    pipelineStageToggles
                    
                    Spacer()
                    
                    creditsAndCostDisplay
                    
                    // Prompt confirmation button (only for single-clip mode)
                    if viewModel.generationMode == .single && !viewModel.promptText.isEmpty && !isPromptConfirmed {
                        confirmPromptButton
                    }
                    
                    generateSection
                    
                    if false { // Guest mode removed
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
            .fullScreenCover(isPresented: $showVideoGenerationScreen) {
                VideoGenerationScreen(
                    isPresented: $showVideoGenerationScreen,
                    initialScript: scriptForGeneration
                )
                .environmentObject(coordinator)
            }
            .sheet(isPresented: $showingPurchaseView) {
                EnhancedCreditsPurchaseView()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $viewModel.selectedImage, useDefaultAd: $viewModel.useDefaultAdImage)
            }
            .overlay {
                if showingInsufficientCredits {
                    InsufficientCreditsOverlay(
                        isShowing: $showingInsufficientCredits,
                        creditsNeeded: insufficientCreditsInfo.needed,
                        creditsHave: insufficientCreditsInfo.have,
                        onPurchase: {
                            showingPurchaseView = true
                        }
                    )
                }
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
    
    private func estimateTotalDuration() -> TimeInterval {
        // Estimate based on prompt length and duration strategy
        let wordCount = viewModel.promptText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let estimatedSegments = max(1, wordCount / 50) // Roughly 50 words per segment
        
        switch viewModel.durationStrategy {
        case .uniform(let duration):
            return duration * Double(estimatedSegments)
        case .custom:
            // Assume average 10s per segment
            return 10.0 * Double(estimatedSegments)
        case .auto:
            // AI will determine, estimate conservatively
            return 8.0 * Double(estimatedSegments)
        }
    }
    
    
    private func determineSegmentationStrategy() -> MultiClipSegmentationStrategy {
        let text = viewModel.promptText
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        // Use different strategies based on content
        if text.contains("INT.") || text.contains("EXT.") || text.contains("SCENE:") {
            return .byScenes
        } else if wordCount > 300 {
            return .byDuration(5.0) // 5 second segments
        } else {
            return .byParagraphs
        }
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
                .onChange(of: selectedItem) { _, newItem in
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
                                    Text("Write Your Scene")
                                        .font(.headline)
                                    Text("Describe who, where, when, and what's happening")
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
                                    Text("Pipeline Processing")
                                        .font(.headline)
                                    Text("Each stage refines your script with cinematic detail")
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
                                    Text("Render and Export")
                                        .font(.headline)
                                    Text("Your scene is generated frame-by-frame")
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
                        Text("Writing Better Scripts")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Think Visually", systemImage: "eye")
                                .font(.subheadline)
                            Text("Describe what can be filmed: faces, actions, locations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 28)
                            
                            Label("Set the Atmosphere", systemImage: "cloud.sun")
                                .font(.subheadline)
                            Text("Specify time of day, lighting conditions, and weather")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 28)
                            
                            Label("Direct the Camera", systemImage: "figure.walk")
                                .font(.subheadline)
                            Text("Call out camera angles, movement, and framing")
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

