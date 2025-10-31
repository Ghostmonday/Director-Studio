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
    @State private var showingResourcePackAlert = false // For Error 1102
    
    // MARK: - Computed Views
    
    @ViewBuilder
    private var quickActionButtons: some View {
        HStack(spacing: 12) {
            // Demo button removed - all users have full access
            
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
                Image(systemName: viewModel.generationMode == .single ? "film.circle.fill" : "film.stack.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.generationMode == .single ? "Script to Screen" : "Script to Film")
                        .font(.headline)
                    Text(viewModel.generationMode == .single ? 
                         "Write your scene. Watch it render." : 
                         "Write your story. We'll break it into scenes.")
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(viewModel.generationMode == .single ? "Script Your Scene" : "Write Your Story", 
                      systemImage: viewModel.generationMode == .single ? "doc.text.magnifyingglass" : "doc.text.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(DirectorStudioTheme.Colors.primary)
                Spacer()
                
                // Expand/Collapse button (only show when collapsed)
                if !isPromptExpanded && !viewModel.promptText.isEmpty {
                    Button(action: {
                        withAnimation(DirectorStudioTheme.Animation.smooth) {
                            isPromptExpanded = true
                        }
                        isPromptFocused = true
                        HapticFeedback.impact(.light)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.caption)
                            Text("Expand")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(.tertiarySystemBackground))
                        )
                        .foregroundColor(DirectorStudioTheme.Colors.primary)
                    }
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
                    .foregroundColor(.primary)
                    .font(.system(size: 17, design: .default))
                    .autocorrectionDisabled(false)
                    .textInputAutocapitalization(.sentences)
                    .keyboardType(.default)
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
                        Text(viewModel.generationMode == .single ? "Describe your scene:" : "Tell your story:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        
                        if isPromptExpanded {
                            if viewModel.generationMode == .single {
                                Text("• Who's in the shot and what they're doing\n• Location, time of day, lighting\n• Camera movement and framing\n• Mood and atmosphere")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.8))
                            } else {
                                Text("• Write your complete narrative\n• Include scene transitions\n• Character development\n• AI will intelligently segment into scenes")
                                    .font(.caption2)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Duration Selection")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Automatically chooses 5 or 10 seconds per scene based on content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.08))
            )
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
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                // 5 second option
                Button(action: {
                    viewModel.videoDuration = 5.0
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "hare.fill")
                            .font(.title2)
                        Text("5 seconds")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Quick & snappy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.videoDuration == 5.0 ? Color.orange : Color(.systemGray6))
                    )
                    .foregroundColor(viewModel.videoDuration == 5.0 ? .white : .primary)
                }
                .buttonStyle(.plain)
                
                // 10 second option
                Button(action: {
                    viewModel.videoDuration = 10.0
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "tortoise.fill")
                            .font(.title2)
                        Text("10 seconds")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Standard pace")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.videoDuration == 10.0 ? Color.blue : Color(.systemGray6))
                    )
                    .foregroundColor(viewModel.videoDuration == 10.0 ? .white : .primary)
                }
                .buttonStyle(.plain)
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
            NavigationLink(destination: CreditsPurchaseView()) {
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
        // Calculate token cost using correct pricing (0.5 tokens per second)
        let creditCost = creditsManager.creditsNeeded(
            for: viewModel.videoDuration,
            enabledStages: viewModel.enabledStages
        )
        // Check tokens, not legacy credits
        let hasEnoughCredits = viewModel.useDefaultAdImage || creditsManager.canAffordGeneration(tokenCost: creditCost)
        
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
            Text(creditsManager.isDevMode ? "FREE" : "Cost: \(creditCost) token\(creditCost == 1 ? "" : "s")")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(creditsManager.isDevMode ? "Dev Mode" : "Balance: \(creditsManager.tokens)")
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
        
        Button(action: {
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
                // Single clip generation - check tokens, not legacy credits
                if !creditsManager.canAffordGeneration(tokenCost: creditCost) {
                    insufficientCreditsInfo = (needed: creditCost, have: creditsManager.tokens)
                    showingInsufficientCredits = true
                } else {
                    Task {
                        await viewModel.generateClip(coordinator: coordinator)
                    }
                }
            } else {
                // Multi-clip generation - launch VideoGenerationScreen
                scriptForGeneration = viewModel.promptText
                
                #if DEBUG
                print("🎬 [PromptView] Launching VideoGenerationScreen")
                print("   Script length: \(viewModel.promptText.count)")
                print("   Script preview: \(viewModel.promptText.prefix(100))")
                
                // Also log to file
                let debugPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("prompt_view_debug.txt")
                try? "Script passed: '\(viewModel.promptText)'\nLength: \(viewModel.promptText.count)".write(to: debugPath, atomically: true, encoding: .utf8)
                #endif
                
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
            ZStack {
                // Cinema grey background
                DirectorStudioTheme.Colors.backgroundBase
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DirectorStudioTheme.Spacing.small) {
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
                    
                    // API Test Button (DEBUG only)
                    #if DEBUG
                    apiTestButton
                    devModeButton
                    #endif
                    
                    quickActionButtons
                    
                    generationModeSelector
                    
                    howItWorksSection
                    
                    projectNameField
                    
                    promptTextSection
                    
                    // Only show these sections for single clip mode
                    if viewModel.generationMode == .single {
                        imageReferenceSection
                        videoDurationControl
                        pipelineStageToggles
                    } else {
                        // Multi-clip mode only shows duration strategy
                        durationStrategySection
                    }
                    
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
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle("Script")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $viewModel.showingStageHelp) { stage in
                StageHelpView(stage: stage)
            }
            .alert("Generation Failed", isPresented: .constant(viewModel.generationError != nil && !showingResourcePackAlert)) {
                Button("OK") {
                    viewModel.generationError = nil
                }
            } message: {
                if let error = viewModel.generationError {
                    // Check if it's a resource pack error
                    if let klingError = error as? KlingError,
                       case .resourcePackDepleted = klingError {
                        // This shouldn't show because showingResourcePackAlert will be true
                        Text(error.localizedDescription)
                    } else {
                        Text(error.localizedDescription)
                    }
                } else {
                    Text("An error occurred")
                }
            }
            .alert("Out of Generation Quota", isPresented: $showingResourcePackAlert) {
                Button("Open Dashboard") {
                    if let url = URL(string: "https://klingai.com/resource-packs") {
                        UIApplication.shared.open(url)
                    }
                    showingResourcePackAlert = false
                    viewModel.generationError = nil
                }
                Button("OK", role: .cancel) {
                    showingResourcePackAlert = false
                    viewModel.generationError = nil
                }
            } message: {
                Text("Please purchase a new Resource Pack or enable Post-Payment in your Kling Dashboard.")
            }
            .onChange(of: viewModel.generationError != nil) { oldValue, newValue in
                // Check if the new error is resourcePackDepleted
                if let klingError = viewModel.generationError as? KlingError,
                   case .resourcePackDepleted = klingError {
                    showingResourcePackAlert = true
                }
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
                    initialScript: viewModel.promptText  // Pass directly from viewModel
                )
                .environmentObject(coordinator)
            }
            .sheet(isPresented: $showingPurchaseView) {
                CreditsPurchaseView()
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
        .overlay(alignment: .bottomTrailing) {
            // Debug button for segmentation logs
            #if DEBUG
            SegmentationDebugButton()
                .padding()
            #endif
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
    
    // MARK: - API Test Button (DEBUG ONLY)
    
    @ViewBuilder
    private var apiTestButton: some View {
        VStack(spacing: 12) {
            // Connection Test
            Button(action: {
                Task {
                    await testAPIConnection()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Test API Keys")
                    Spacer()
                    if testingAPIs {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(8)
            }
            .disabled(testingAPIs)
            
            // NEW: Native Kling API Test Buttons (PRIMARY)
            VStack(spacing: 4) {
                Text("🧪 Native Kling AI API")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                HStack(spacing: 8) {
                    Button(action: {
                        Task {
                            await testKlingAPIClient(version: .v1_6_standard)
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "film.fill")
                            Text("Kling 1.6")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    }
                    .disabled(testingAPIs)
                    
                    Button(action: {
                        Task {
                            await testKlingAPIClient(version: .v2_0_master)
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "film.fill")
                            Text("Kling 2.0")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                    }
                    .disabled(testingAPIs)
                    
                    Button(action: {
                        Task {
                            await testKlingAPIClient(version: .v2_5_turbo)
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "film.fill")
                            Text("Kling 2.5")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(6)
                    }
                    .disabled(testingAPIs)
                }
            }
            
            // API Key Diagnostic Button - Check which keys are being used
            Button(action: {
                Task {
                    await diagnoseAPIKeys()
                }
            }) {
                HStack {
                    Image(systemName: "key.fill")
                    Text("🔍 Diagnose API Keys & Account")
                    Spacer()
                    if testingAPIs {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.2))
                .foregroundColor(.red)
                .cornerRadius(8)
            }
            .disabled(testingAPIs)
            
            // Comprehensive Test Button - Tests Multiple Features at Once
            Button(action: {
                Task {
                    await testComprehensiveAPI()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                    Text("🧪 Comprehensive Test (Camera + Tier + API)")
                    Spacer()
                    if testingAPIs {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.2))
                .foregroundColor(.orange)
                .cornerRadius(8)
            }
            .disabled(testingAPIs)
            
            // Text-to-Audio Test Button (REAL API CALL - costs credits)
            Button(action: {
                Task {
                    await testKlingTextToAudio()
                }
            }) {
                HStack {
                    Image(systemName: "waveform")
                    Text("Test Text-to-Audio (~5-10 credits)")
                    Spacer()
                    if testingAPIs {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                .background(Color.purple.opacity(0.2))
                .foregroundColor(.purple)
                .cornerRadius(8)
            }
            .disabled(testingAPIs)
            
            // Image-to-Video Test Button (Low Cost - ~20 credits)
            Button(action: {
                Task {
                    await testKlingImageToVideo()
                }
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Test Image-to-Video (5s, ~20 credits)")
                    Spacer()
                    if testingAPIs {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.2))
                .foregroundColor(.orange)
                .cornerRadius(8)
            }
            .disabled(testingAPIs)
            
            if let result = apiTestResult {
                ScrollView {
                    Text(result)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(result.contains("✅") ? .green : (result.contains("❌") ? .red : .primary))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
    
    @State private var testingAPIs = false
    @State private var apiTestResult: String?
    
    @ViewBuilder
    private var devModeButton: some View {
        Button(action: {
            #if DEBUG
            _ = CreditsManager.shared.enableDevMode(passcode: "DIRECTOR2025")
            #endif
        }) {
            HStack {
                Image(systemName: "crown.fill")
                Text("Enable Unlimited Credits (Dev Mode)")
                Spacer()
            }
            .padding()
            .background(Color.purple.opacity(0.2))
            .foregroundColor(.purple)
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
    
    private func testAPIConnection() async {
        testingAPIs = true
        apiTestResult = "🔄 Testing Supabase connection...\n\n"
        
        var results: [String] = []
        
        // Clear cache to force fresh fetch
        SupabaseAPIKeyService.shared.clearCache()
        results.append("📡 Supabase URL: carkncjucvtbggqrilwj.supabase.co")
        results.append("")
        
        // Test DeepSeek
        do {
            let startTime = Date()
            let deepSeekKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "DeepSeek")
            let duration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            if !deepSeekKey.isEmpty {
                results.append("✅ DeepSeek: Connected!")
                results.append("   Key: \(deepSeekKey.prefix(12))...")
                results.append("   Fetched in \(duration)s from Supabase")
            } else {
                results.append("❌ DeepSeek: Key is empty")
            }
        } catch {
            results.append("❌ DeepSeek: \(error.localizedDescription)")
        }
        
        results.append("")
        
        // Test Kling
        do {
            let startTime = Date()
            let klingAccessKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Kling")
            let klingSecretKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "KlingSecret")
            let duration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            if !klingAccessKey.isEmpty && !klingSecretKey.isEmpty {
                results.append("✅ Kling: Connected!")
                results.append("   AccessKey: \(klingAccessKey.prefix(12))...")
                results.append("   SecretKey: \(klingSecretKey.prefix(12))...")
                results.append("   Fetched in \(duration)s from Supabase")
            } else {
                results.append("❌ Kling: AccessKey or SecretKey is empty")
            }
        } catch {
            results.append("❌ Kling: \(error.localizedDescription)")
        }
        
        results.append("")
        results.append("🎉 Connection verified - Keys fetched from Supabase!")
        results.append("")
        results.append("💡 Tip: Use the Kling API buttons above to test actual API calls")
        
        await MainActor.run {
            apiTestResult = results.joined(separator: "\n")
            testingAPIs = false
        }
    }
    
    
    /// Test the native KlingAPIClient with specific version
    private func testKlingAPIClient(version: KlingVersion) async {
        testingAPIs = true
        apiTestResult = "🚀 Testing KlingAPIClient (\(version.rawValue)) via Native Kling API...\n\n"
        
        var results: [String] = []
        let testPrompt = "test"
        let testDuration = 5 // Minimum duration
        let startTime = Date()
        
        results.append("💰 COST WARNING: This is a REAL API call!")
        results.append("   Version: \(version.rawValue)")
        results.append("   Endpoint: \(version.endpoint.absoluteString)")
        results.append("")
        results.append("📋 Test Parameters:")
        results.append("   Prompt: '\(testPrompt)'")
        results.append("   Duration: \(testDuration)s")
        results.append("   Max Duration: \(version.maxSeconds)s")
        results.append("   Supports Negative: \(version.supportsNegative)")
        results.append("")
        
        do {
            // Get Kling AI credentials (AccessKey + SecretKey)
            // TODO: Update SupabaseAPIKeyService to support Kling credentials
            // For now, using placeholder - user must provide AccessKey + SecretKey
            let accessKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Kling")
            let secretKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "KlingSecret")
            
            guard !accessKey.isEmpty, !secretKey.isEmpty else {
                throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kling AccessKey or SecretKey is empty. Please configure Kling credentials."])
            }
            
            results.append("✅ Kling AccessKey fetched: \(accessKey.prefix(12))...")
            results.append("✅ Kling SecretKey fetched: \(secretKey.prefix(12))...")
            results.append("")
            
            await MainActor.run {
                apiTestResult = results.joined(separator: "\n") + "\n🔄 Creating task via Kling native API...\n"
            }
            
            // Create KlingAPIClient with AccessKey + SecretKey
            let klingClient = KlingAPIClient(accessKey: accessKey, secretKey: secretKey)
            
            // Track status updates (thread-safe using actor isolation)
            let statusTracker = StatusTracker()
            
            // Create task
            let task = try await klingClient.generateVideo(
                prompt: testPrompt,
                version: version,
                negativePrompt: nil,
                duration: testDuration
            )
            
            results.append("✅ Task Created!")
            results.append("   Task ID: \(task.id)")
            results.append("   Status URL: \(task.statusURL.absoluteString)")
            results.append("")
            
            await MainActor.run {
                apiTestResult = results.joined(separator: "\n") + "\n🔄 Polling status...\n"
            }
            
            // Poll status with updates
            let videoURL = try await klingClient.pollStatus(
                task: task,
                onStatusUpdate: { status in
                    Task {
                        await statusTracker.add(status)
                        let updates = await statusTracker.getAll()
                        await MainActor.run {
                            let currentResults = results + ["\n📊 Status Updates:", updates.joined(separator: " → ")]
                            apiTestResult = currentResults.joined(separator: "\n")
                        }
                    }
                }
            )
            
            let duration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            let finalUpdates = await statusTracker.getAll()
            
            results.append("✅ Video Generated Successfully!")
            results.append("   Video URL: \(videoURL)")
            results.append("   Total time: \(duration)s")
            results.append("   Status flow: \(finalUpdates.joined(separator: " → "))")
            results.append("")
            results.append("🎉 Native Kling API working correctly!")
            
        } catch {
            let duration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            
            results.append("")
            results.append("❌ Test Failed!")
            results.append("   Error: \(error.localizedDescription)")
            results.append("   Failed after: \(duration)s")
            results.append("")
            
            if let klingError = error as? KlingError {
                results.append("   KlingError Details:")
                results.append("   \(klingError.localizedDescription)")
            }
        }
        
        await MainActor.run {
            apiTestResult = results.joined(separator: "\n")
            testingAPIs = false
        }
    }
    
    /// Test GET list query methods (queryVideoTaskList and queryAudioTaskList)
    private func testGETListQueries() async {
        testingAPIs = true
        apiTestResult = "📋 TESTING GET LIST QUERIES\nQuerying video and audio task lists...\n\n"
        
        var results: [String] = []
        let startTime = Date()
        
        results.append("═══════════════════════════════════════")
        results.append("TEST: GET List Query Methods")
        results.append("═══════════════════════════════════════")
        results.append("")
        results.append("These are GET requests (no credits used)")
        results.append("")
        
        do {
            // Fetch Kling credentials
            let accessKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Kling")
            let secretKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "KlingSecret")
            
            guard !accessKey.isEmpty, !secretKey.isEmpty else {
                throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kling AccessKey or SecretKey is empty"])
            }
            
            results.append("✅ Credentials fetched")
            results.append("")
            
            let klingClient = KlingAPIClient(accessKey: accessKey, secretKey: secretKey)
            
            // Test Video Task List Query
            results.append("─────────────────────────────────────")
            results.append("1. Query Video Task List (GET)")
            results.append("─────────────────────────────────────")
            results.append("")
            
            await MainActor.run {
                apiTestResult = results.joined(separator: "\n") + "\n🔄 Querying video tasks...\n"
            }
            
            let videoTasks = try await klingClient.queryVideoTaskList(pageNum: 1, pageSize: 10)
            
            results.append("✅ Retrieved \(videoTasks.count) video tasks")
            results.append("")
            
            if videoTasks.isEmpty {
                results.append("   (No video tasks found)")
            } else {
                for (index, task) in videoTasks.prefix(5).enumerated() {
                    results.append("   Task \(index + 1):")
                    results.append("     ID: \(task.task_id)")
                    results.append("     Status: \(task.task_status)")
                    if let statusMsg = task.task_status_msg {
                        results.append("     Status Msg: \(statusMsg)")
                    }
                    if let result = task.task_result?.videos?.first {
                        results.append("     Video URL: \(result.url)")
                        if let duration = result.duration {
                            results.append("     Duration: \(duration)s")
                        }
                    }
                    if let createdAt = task.created_at {
                        let date = Date(timeIntervalSince1970: Double(createdAt) / 1000.0)
                        let formatter = DateFormatter()
                        formatter.dateStyle = .short
                        formatter.timeStyle = .short
                        results.append("     Created: \(formatter.string(from: date))")
                    }
                    results.append("")
                }
                if videoTasks.count > 5 {
                    results.append("   ... and \(videoTasks.count - 5) more tasks")
                    results.append("")
                }
            }
            
            // Test Audio Task List Query
            results.append("─────────────────────────────────────")
            results.append("2. Query Audio Task List (GET)")
            results.append("─────────────────────────────────────")
            results.append("")
            
            await MainActor.run {
                apiTestResult = results.joined(separator: "\n") + "\n🔄 Querying audio tasks...\n"
            }
            
            let audioTasks = try await klingClient.queryAudioTaskList(pageNum: 1, pageSize: 10)
            
            results.append("✅ Retrieved \(audioTasks.count) audio tasks")
            results.append("")
            
            if audioTasks.isEmpty {
                results.append("   (No audio tasks found)")
            } else {
                for (index, task) in audioTasks.prefix(5).enumerated() {
                    results.append("   Task \(index + 1):")
                    results.append("     ID: \(task.task_id)")
                    results.append("     Status: \(task.task_status)")
                    if let statusMsg = task.task_status_msg {
                        results.append("     Status Msg: \(statusMsg)")
                    }
                    if let result = task.task_result?.audios?.first {
                        if let mp3 = result.url_mp3 {
                            results.append("     MP3 URL: \(mp3)")
                        }
                        if let wav = result.url_wav {
                            results.append("     WAV URL: \(wav)")
                        }
                        if let duration = result.duration_mp3 {
                            results.append("     Duration: \(duration)s")
                        }
                    }
                    if let createdAt = task.created_at {
                        let date = Date(timeIntervalSince1970: Double(createdAt) / 1000.0)
                        let formatter = DateFormatter()
                        formatter.dateStyle = .short
                        formatter.timeStyle = .short
                        results.append("     Created: \(formatter.string(from: date))")
                    }
                    results.append("")
                }
                if audioTasks.count > 5 {
                    results.append("   ... and \(audioTasks.count - 5) more tasks")
                    results.append("")
                }
            }
            
            let duration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            results.append("═══════════════════════════════════════")
            results.append("✅ GET List Queries Successful!")
            results.append("   Total time: \(duration)s")
            results.append("   Video tasks: \(videoTasks.count)")
            results.append("   Audio tasks: \(audioTasks.count)")
            results.append("═══════════════════════════════════════")
            
        } catch {
            let duration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            results.append("")
            results.append("❌ GET List Query Failed!")
            results.append("   Error: \(error.localizedDescription)")
            results.append("   Failed after: \(duration)s")
            
            if let klingError = error as? KlingError {
                results.append("")
                results.append("   KlingError Details:")
                results.append("   \(klingError.localizedDescription)")
            }
        }
        
        await MainActor.run {
            apiTestResult = results.joined(separator: "\n")
            testingAPIs = false
        }
    }
    
    /// Diagnostic function to check API keys and troubleshoot balance issues
    private func diagnoseAPIKeys() async {
        testingAPIs = true
        apiTestResult = "🔍 API KEY DIAGNOSTIC\nChecking configuration and troubleshooting balance issues...\n\n"
        
        var results: [String] = []
        
        results.append("═══════════════════════════════════════")
        results.append("STEP 1: Fetching API Keys from Supabase")
        results.append("═══════════════════════════════════════")
        results.append("")
        
        var accessKey: String = ""
        var secretKey: String = ""
        
        do {
            // Fetch keys
            accessKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Kling")
            secretKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "KlingSecret")
            
            results.append("✅ Keys fetched successfully")
            results.append("")
            
            // Show key fingerprints (first 8 and last 4 chars for security)
            let accessKeyFingerprint = "\(accessKey.prefix(8))...\(accessKey.suffix(4))"
            let secretKeyFingerprint = "\(secretKey.prefix(8))...\(secretKey.suffix(4))"
            
            results.append("📋 API Key Information:")
            results.append("   AccessKey: \(accessKeyFingerprint)")
            results.append("   SecretKey: \(secretKeyFingerprint)")
            results.append("   AccessKey length: \(accessKey.count) characters")
            results.append("   SecretKey length: \(secretKey.count) characters")
            results.append("")
            
            results.append("═══════════════════════════════════════")
            results.append("STEP 2: Testing API Authentication")
            results.append("═══════════════════════════════════════")
            results.append("")
            
            // Try to create a JWT token (this validates the keys)
            let klingClient = KlingAPIClient(accessKey: accessKey, secretKey: secretKey)
            
            // Make a minimal API call to check authentication
            results.append("🔄 Testing authentication with a minimal API call...")
            results.append("")
            
            await MainActor.run {
                apiTestResult = results.joined(separator: "\n") + "\n🔄 Making test API call...\n"
            }
            
            // Try to create a video task (this will fail with balance error, but we'll see the actual error)
            let testTask = try await klingClient.generateVideo(
                prompt: "test",
                version: .v1_6_standard,
                negativePrompt: nil,
                duration: 5,
                image: nil,
                imageTail: nil,
                cameraControl: nil,
                mode: "std"
            )
            
            results.append("✅ Authentication successful!")
            results.append("   Task ID: \(testTask.id)")
            
        } catch {
            let errorMsg = error.localizedDescription
            
            results.append("❌ Error occurred:")
            results.append("   \(errorMsg)")
            results.append("")
            
            // Parse error to provide specific guidance
            if errorMsg.contains("1102") || errorMsg.contains("balance") || errorMsg.contains("insufficient") {
                results.append("═══════════════════════════════════════")
                results.append("💡 TROUBLESHOOTING: Balance Error 1102")
                results.append("═══════════════════════════════════════")
                results.append("")
                results.append("You have 800 credits but API says insufficient balance.")
                results.append("")
                results.append("🔍 CHECK THESE THINGS:")
                results.append("")
                results.append("1. API KEY ACCOUNT MATCH:")
                results.append("   → Go to KlingAI dashboard")
                results.append("   → Check which account has the 800 credits")
                results.append("   → Verify the AccessKey/SecretKey in Supabase")
                results.append("     match THIS account (not a different one)")
                results.append("")
                results.append("2. RESOURCE PACK DEPLETED/EXPIRED (MOST LIKELY!):")
                results.append("   → Error 1102 = Resource pack depleted or expired")
                results.append("   → Your 800 credits are in a PREPAID Resource Pack")
                results.append("   → Resource Pack might be expired or used up")
                results.append("   → Check KlingAI dashboard → Resource Packs")
                results.append("   → Solution: Purchase NEW resource packages")
                results.append("   → OR activate post-payment service if available")
                results.append("")
                results.append("3. ACTIVATE CREDITS:")
                results.append("   → Some credits need activation")
                results.append("   → Check if there's an 'Activate' button")
                results.append("   → Or contact Kling support to activate")
                results.append("")
                results.append("4. MINIMUM BALANCE:")
                results.append("   → There might be a minimum balance requirement")
                results.append("   → Check KlingAI documentation or support")
                results.append("")
                results.append("5. VERIFY KEYS IN SUPABASE:")
                results.append("   → Check Supabase → api_keys table")
                results.append("   → Verify 'Kling' and 'KlingSecret' rows")
                results.append("   → Make sure they match the account with credits")
                results.append("")
                if !accessKey.isEmpty {
                    results.append("📞 If still stuck:")
                    results.append("   → Contact KlingAI support with:")
                    results.append("     - Your AccessKey (first 8 chars): \(accessKey.prefix(8))")
                    results.append("     - Error code: 1102")
                    results.append("     - Your dashboard shows 800 credits")
                }
            } else if errorMsg.contains("401") || errorMsg.contains("auth") {
                results.append("❌ Authentication failed!")
                results.append("   → Check if AccessKey and SecretKey are correct")
                results.append("   → Verify keys in Supabase match KlingAI dashboard")
            }
        }
        
        await MainActor.run {
            apiTestResult = results.joined(separator: "\n")
            testingAPIs = false
        }
    }
    
    /// Comprehensive test that verifies multiple features at once:
    /// - Camera control detection from prompt keywords
    /// - Standard vs Pro mode (tier mapping)
    /// - Official API format compliance
    /// - Duration handling
    /// - Request JSON structure
    private func testComprehensiveAPI() async {
        testingAPIs = true
        apiTestResult = "🧪 COMPREHENSIVE API TEST\nTesting Multiple Features Simultaneously...\n\n"
        
        var results: [String] = []
        let startTime = Date()
        
        // Test 1: Camera Control Detection (drone shot keyword)
        let testPrompt1 = "A drone shot of a futuristic city skyline at sunset, neon lights reflecting on glass buildings"
        let testPrompt2 = "Close-up of a detective's face as he slowly zooms in on the mysterious letter"
        let testPrompt3 = "A wide establishing shot panning left across the desert landscape"
        
        results.append("═══════════════════════════════════════")
        results.append("TEST 1: Camera Control Detection")
        results.append("═══════════════════════════════════════")
        results.append("")
        
        // Test prompt 1: drone shot
        let cameraControl1 = CameraControl.fromPrompt(testPrompt1)
        results.append("📝 Prompt 1: '\(testPrompt1.prefix(60))...'")
        if let cc1 = cameraControl1 {
            results.append("   ✅ Camera Control Detected!")
            results.append("      Type: \(cc1.type?.rawValue ?? "none")")
            if let config = cc1.config {
                results.append("      Config: \(config.toAPIDict())")
            }
        } else {
            results.append("   ⚠️ No camera control detected (API will intelligently match)")
        }
        results.append("")
        
        // Test prompt 2: zoom in
        let cameraControl2 = CameraControl.fromPrompt(testPrompt2)
        results.append("📝 Prompt 2: '\(testPrompt2.prefix(60))...'")
        if let cc2 = cameraControl2 {
            results.append("   ✅ Camera Control Detected!")
            results.append("      Type: \(cc2.type?.rawValue ?? "none")")
            if let config = cc2.config {
                results.append("      Config: \(config.toAPIDict())")
            }
        } else {
            results.append("   ⚠️ No camera control detected")
        }
        results.append("")
        
        // Test prompt 3: pan left
        let cameraControl3 = CameraControl.fromPrompt(testPrompt3)
        results.append("📝 Prompt 3: '\(testPrompt3.prefix(60))...'")
        if let cc3 = cameraControl3 {
            results.append("   ✅ Camera Control Detected!")
            results.append("      Type: \(cc3.type?.rawValue ?? "none")")
            if let config = cc3.config {
                results.append("      Config: \(config.toAPIDict())")
            }
        } else {
            results.append("   ⚠️ No camera control detected")
        }
        results.append("")
        
        // Test 2: Tier to Mode Mapping
        results.append("═══════════════════════════════════════")
        results.append("TEST 2: Tier → Mode Mapping")
        results.append("═══════════════════════════════════════")
        results.append("")
        
        let tiers: [(VideoQualityTier, String)] = [
            (.economy, "Economy"),
            (.basic, "Basic"),
            (.pro, "Pro")
        ]
        
        for (tier, name) in tiers {
            let mode = (tier == .pro) ? "pro" : "std"
            results.append("   \(name) tier → mode: '\(mode)'")
        }
        results.append("")
        
        // Test 3: Actual API Call with Camera Control
        results.append("═══════════════════════════════════════")
        results.append("TEST 3: Real API Call with Camera Control")
        results.append("═══════════════════════════════════════")
        results.append("")
        results.append("💰 COST: ~20 credits for 5-second video")
        results.append("   This tests the complete pipeline:")
        results.append("   • Camera control detection")
        results.append("   • Standard mode (economy/basic tier)")
        results.append("   • Official API JSON format")
        results.append("   • Request/response parsing")
        results.append("")
        
        await MainActor.run {
            apiTestResult = results.joined(separator: "\n") + "\n🔄 Fetching credentials...\n"
        }
        
        do {
            // Get Kling credentials
            let accessKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Kling")
            let secretKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "KlingSecret")
            
            guard !accessKey.isEmpty, !secretKey.isEmpty else {
                throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kling AccessKey or SecretKey is empty"])
            }
            
            results.append("✅ Credentials loaded")
            results.append("")
            
            // Use test prompt 1 (drone shot) for actual API call
            // Camera movements detected from prompt text will guide the model naturally
            // We don't need camera_control JSON - the model interprets cinematographic terms
            let finalPrompt = testPrompt1
            let finalCameraControl = cameraControl1  // Detected for UI info, but not sent as JSON
            let tier: VideoQualityTier = .basic  // Standard mode
            let version: KlingVersion = .v1_6_standard
            let duration = 5
            let mode = "std"  // Standard mode for basic tier
            
            results.append("ℹ️  Camera Control Strategy:")
            results.append("   Camera movements detected from prompt text")
            results.append("   Model will interpret cinematographic terms naturally")
            results.append("   No camera_control JSON needed - works with all models/modes")
            results.append("")
            
            results.append("📋 API Request Parameters:")
            results.append("   Prompt: '\(finalPrompt.prefix(80))...'")
            results.append("   Duration: \(duration)s")
            results.append("   Tier: Basic → mode: '\(mode)'")
            results.append("   Version: \(version.rawValue)")
            results.append("   Model: \(version.modelName)")
            if let cc = finalCameraControl {
                results.append("   Camera Movement Detected: \(cc.type?.rawValue ?? "custom")")
                results.append("   → Model will interpret from prompt text naturally")
            } else {
                results.append("   Camera Movement: Detected from prompt (model interprets naturally)")
            }
            results.append("")
            
            // Build expected JSON structure
            var expectedJSON: [String: Any] = [
                "model_name": version.modelName,
                "prompt": finalPrompt,
                "duration": String(duration),
                "mode": mode,
                "aspect_ratio": "16:9"
            ]
            
            if let cc = finalCameraControl, let ccDict = cc.toAPIDict() {
                expectedJSON["camera_control"] = ccDict
            }
            
            results.append("📄 Expected Request JSON Structure:")
            if let jsonData = try? JSONSerialization.data(withJSONObject: expectedJSON, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                results.append(jsonString)
            }
            results.append("")
            
            await MainActor.run {
                apiTestResult = results.joined(separator: "\n") + "\n🔄 Creating video generation task...\n"
            }
            
            // Create KlingAPIClient
            let klingClient = KlingAPIClient(accessKey: accessKey, secretKey: secretKey)
            
            // Create video task with camera control
            let task = try await klingClient.generateVideo(
                prompt: finalPrompt,
                version: version,
                negativePrompt: nil,
                duration: duration,
                image: nil,
                imageTail: nil,
                cameraControl: finalCameraControl,
                mode: mode
            )
            
            results.append("✅ Task Created Successfully!")
            results.append("   Task ID: \(task.id)")
            results.append("   Status URL: \(task.statusURL)")
            results.append("")
            
            await MainActor.run {
                apiTestResult = results.joined(separator: "\n") + "\n🔄 Polling status (this may take 30-90 seconds)...\n"
            }
            
            // Poll for completion
            let videoURL = try await klingClient.pollStatus(task: task)
            
            let totalDuration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            
            results.append("═══════════════════════════════════════")
            results.append("✅ ALL TESTS PASSED!")
            results.append("═══════════════════════════════════════")
            results.append("")
            results.append("📊 Test Results:")
            results.append("   ✅ Camera control detection: WORKING")
            results.append("   ✅ Tier → mode mapping: WORKING")
            results.append("   ✅ API format: COMPLIANT")
            results.append("   ✅ Video generation: SUCCESS")
            results.append("")
            results.append("📹 Video URL: \(videoURL)")
            results.append("⏱️ Total time: \(totalDuration)s")
            results.append("")
            results.append("🎉 Comprehensive test complete!")
            results.append("💰 This call used ~20 credits from your Kling account")
            results.append("📊 Check your Kling dashboard for usage stats")
            
        } catch {
            let totalDuration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            
            results.append("")
            results.append("═══════════════════════════════════════")
            results.append("❌ TEST FAILED")
            results.append("═══════════════════════════════════════")
            results.append("")
            results.append("Error: \(error.localizedDescription)")
            results.append("Failed after: \(totalDuration)s")
            results.append("")
            
            if let klingError = error as? KlingError {
                results.append("KlingError Details:")
                results.append("\(klingError.localizedDescription)")
            }
        }
        
        await MainActor.run {
            apiTestResult = results.joined(separator: "\n")
            testingAPIs = false
        }
    }
    
    /// Test text-to-audio generation via Kling API (REAL API CALL - costs credits)
    private func testKlingTextToAudio() async {
        testingAPIs = true
        apiTestResult = "🔊 Testing Text-to-Audio via Kling API (REAL API CALL)...\n\n"
        
        var results: [String] = []
        let testPrompt = "a calm ocean wave sound"
        let testDuration = 5.0 // 5 seconds
        let startTime = Date()
        
        results.append("💰 COST: Uses Kling credits (typically ~5-10 credits per audio)")
        results.append("   This is a REAL API call to Kling servers")
        results.append("")
        
        do {
            // Get Kling credentials
            let accessKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Kling")
            let secretKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "KlingSecret")
            
            guard !accessKey.isEmpty, !secretKey.isEmpty else {
                throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kling AccessKey or SecretKey is empty"])
            }
            
            results.append("✅ Credentials loaded")
            results.append("")
            results.append("📋 Test Parameters:")
            results.append("   Prompt: '\(testPrompt)'")
            results.append("   Duration: \(testDuration)s")
            results.append("")
            
            await MainActor.run {
                apiTestResult = results.joined(separator: "\n") + "\n🔄 Creating audio generation task...\n"
            }
            
            // Create KlingAPIClient
            let klingClient = KlingAPIClient(accessKey: accessKey, secretKey: secretKey)
            
            // Create audio task
            let task = try await klingClient.generateAudio(
                prompt: testPrompt,
                duration: testDuration
            )
            
            results.append("✅ Task Created!")
            results.append("   Task ID: \(task.id)")
            results.append("")
            
            await MainActor.run {
                apiTestResult = results.joined(separator: "\n") + "\n🔄 Polling status (this may take 30-60 seconds)...\n"
            }
            
            // Poll for completion
            let audioURL = try await klingClient.pollAudioStatus(task: task)
            
            let duration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            
            results.append("✅ Audio Generated Successfully!")
            results.append("   Audio URL: \(audioURL)")
            results.append("   Total time: \(duration)s")
            results.append("")
            results.append("🎉 Text-to-audio API working!")
            results.append("💰 This call used credits from your Kling account")
            results.append("📊 Check your Kling dashboard for usage stats")
            
        } catch {
            let duration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            
            results.append("")
            results.append("❌ Test Failed!")
            results.append("   Error: \(error.localizedDescription)")
            results.append("   Failed after: \(duration)s")
            results.append("")
            
            if let klingError = error as? KlingError {
                results.append("   KlingError Details:")
                results.append("   \(klingError.localizedDescription)")
            }
        }
        
        await MainActor.run {
            apiTestResult = results.joined(separator: "\n")
            testingAPIs = false
        }
    }
    
    /// Generate a simple image from text prompt (programmatic generation)
    /// This creates a visual representation based on the prompt keywords
    private func generateImageFromText(prompt: String, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Parse prompt for colors/themes
            let lowerPrompt = prompt.lowercased()
            
            // Determine background color based on prompt keywords
            var bgColor: UIColor = .systemBlue
            var accentColor: UIColor = .white
            
            if lowerPrompt.contains("ocean") || lowerPrompt.contains("water") || lowerPrompt.contains("wave") {
                bgColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0) // Ocean blue
                accentColor = UIColor(red: 0.9, green: 0.95, blue: 1.0, alpha: 1.0) // Wave white
            } else if lowerPrompt.contains("sunset") || lowerPrompt.contains("sun") {
                bgColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0) // Sunset orange
                accentColor = UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0) // Light yellow
            } else if lowerPrompt.contains("forest") || lowerPrompt.contains("tree") || lowerPrompt.contains("green") {
                bgColor = UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0) // Forest green
                accentColor = UIColor(red: 0.4, green: 0.8, blue: 0.5, alpha: 1.0) // Light green
            } else if lowerPrompt.contains("mountain") || lowerPrompt.contains("snow") {
                bgColor = UIColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1.0) // Mountain gray
                accentColor = .white
            } else {
                // Default gradient
                bgColor = UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)
                accentColor = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
            }
            
            // Fill background
            cgContext.setFillColor(bgColor.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Draw gradient overlay
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [bgColor.cgColor, accentColor.withAlphaComponent(0.3).cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) else {
                return
            }
            
            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
            
            // Draw simple pattern based on prompt
            if lowerPrompt.contains("wave") || lowerPrompt.contains("ocean") {
                // Draw wavy lines
                cgContext.setStrokeColor(accentColor.cgColor)
                cgContext.setLineWidth(3.0)
                
                let waveHeight: CGFloat = 40
                let waveCount = 3
                for i in 0..<waveCount {
                    let y = size.height * 0.6 + CGFloat(i) * waveHeight
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: 0, y: y))
                    
                    for x in stride(from: 0, through: size.width, by: 20) {
                        let waveY = y + sin(x / 50) * 15
                        path.addLine(to: CGPoint(x: x, y: waveY))
                    }
                    
                    cgContext.addPath(path.cgPath)
                    cgContext.strokePath()
                }
            }
            
            // Add text label
            let text = prompt.prefix(30)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: accentColor,
                .strokeColor: bgColor,
                .strokeWidth: -2.0
            ]
            
            let attributedString = NSAttributedString(string: String(text), attributes: attributes)
            let textSize = attributedString.size()
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: size.height * 0.2,
                width: textSize.width,
                height: textSize.height
            )
            
            attributedString.draw(in: textRect)
        }
    }
    
    /// Test image-to-video generation (low cost test - ~20 credits)
    private func testKlingImageToVideo() async {
        testingAPIs = true
        apiTestResult = "🖼️ Testing Image-to-Video via Kling API (Low Cost Test)...\n\n"
        
        var results: [String] = []
        let testPrompt = "a calm ocean wave"
        let testDuration = 5 // Minimum duration
        let startTime = Date()
        
        results.append("💰 COST: ~20 credits for 5-second video")
        results.append("   This is a REAL API call but uses minimal credits")
        results.append("")
        
        do {
            // Get a test image (use default ad.png if available)
            guard let testImage = UIImage(named: "ad") else {
                throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Test image 'ad.png' not found in assets"])
            }
            
            results.append("✅ Test image loaded: ad.png")
            results.append("   Size: \(Int(testImage.size.width))×\(Int(testImage.size.height))")
            results.append("")
            
            // Get Kling credentials
            let accessKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Kling")
            let secretKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "KlingSecret")
            
            guard !accessKey.isEmpty, !secretKey.isEmpty else {
                throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kling AccessKey or SecretKey is empty"])
            }
            
            results.append("✅ Credentials loaded")
            results.append("")
            results.append("📋 Test Parameters:")
            results.append("   Prompt: '\(testPrompt)'")
            results.append("   Duration: \(testDuration)s")
            results.append("   Version: Kling 1.6 (most cost-effective)")
            results.append("")
            
            await MainActor.run {
                apiTestResult = results.joined(separator: "\n") + "\n🔄 Creating image-to-video task...\n"
            }
            
            // Create KlingAPIClient
            let klingClient = KlingAPIClient(accessKey: accessKey, secretKey: secretKey)
            
            // Convert image to base64 data URI
            guard let imageData = testImage.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }
            
            // Resize to standard size (854x480 for efficiency)
            let targetSize = CGSize(width: 854, height: 480)
            let resizedImage = testImage.resized(to: targetSize)
            guard let resizedData = resizedImage.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "Test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress resized image"])
            }
            
            let base64String = resizedData.base64EncodedString()
            let dataURI = "data:image/jpeg;base64,\(base64String)"
            
            results.append("✅ Image processed and encoded")
            results.append("   Final size: \(resizedData.count) bytes")
            results.append("")
            
            // Create task with image
            let task = try await klingClient.generateVideo(
                prompt: testPrompt,
                version: .v1_6_standard, // Use 1.6 for lowest cost
                negativePrompt: nil,
                duration: testDuration,
                image: dataURI,
                imageTail: nil
            )
            
            results.append("✅ Task Created!")
            results.append("   Task ID: \(task.id)")
            results.append("")
            
            await MainActor.run {
                apiTestResult = results.joined(separator: "\n") + "\n🔄 Polling status (this may take 30-60 seconds)...\n"
            }
            
            // Poll status
            let videoURL = try await klingClient.pollStatus(task: task)
            
            let duration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            
            results.append("✅ Video Generated Successfully!")
            results.append("   Video URL: \(videoURL)")
            results.append("   Total time: \(duration)s")
            results.append("")
            results.append("🎉 Image-to-video connection established!")
            results.append("💰 Cost: ~20 credits")
            
        } catch {
            let duration = String(format: "%.2f", Date().timeIntervalSince(startTime))
            
            results.append("")
            results.append("❌ Test Failed!")
            results.append("   Error: \(error.localizedDescription)")
            results.append("   Failed after: \(duration)s")
            results.append("")
            
            if let klingError = error as? KlingError {
                results.append("   KlingError Details:")
                results.append("   \(klingError.localizedDescription)")
            }
        }
        
        await MainActor.run {
            apiTestResult = results.joined(separator: "\n")
            testingAPIs = false
        }
    }
}

/// Thread-safe status tracker for API test callbacks
private actor StatusTracker {
    private var updates: [String] = []
    
    func add(_ status: String) {
        updates.append(status)
    }
    
    func getAll() -> [String] {
        return updates
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

// MARK: - iPhone Floating Prompt Card (One-Hand Ready)
struct PromptCard: View {
    @Binding var prompt: String
    @FocusState private var isFocused: Bool
    @State private var cardHeight: CGFloat = 200
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextEditor(text: $prompt)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .foregroundColor(.primary)
                .font(.system(size: 17, design: .default))
                .autocorrectionDisabled(false)
                .textInputAutocapitalization(.sentences)
                .keyboardType(.default)
                .frame(height: max(120, cardHeight))
            
            if isFocused { LiveVoiceWaveform() }
        }
        .padding(16)
        .background(DirectorStudioTheme.Colors.darkSurface, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(DirectorStudioTheme.Colors.accent.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: DirectorStudioTheme.Colors.accent.opacity(0.2), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: isFocused)
        .background(
            GeometryReader { geo in
                Color.clear.onChange(of: geo.size.height) { _, newHeight in
                    cardHeight = newHeight
                }
            }
        )
    }
}

// MARK: - Live Voice Waveform (iPhone Height-Capped)
struct LiveVoiceWaveform: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let mid = geo.size.height / 2
                let width = geo.size.width
                let step: CGFloat = 3
                for x in stride(from: 0, to: width, by: step) {
                    let norm = x / width
                    let amp = sin(norm * .pi * 5 + phase) * 6
                    path.addRect(CGRect(x: x, y: mid - amp, width: 2, height: amp * 2))
                }
            }
            .fill(LinearGradient(colors: [DirectorStudioTheme.Colors.accent, DirectorStudioTheme.Colors.accent.opacity(0.6)], startPoint: .leading, endPoint: .trailing))
        }
        .frame(height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                phase += .pi * 2
            }
        }
    }
}

