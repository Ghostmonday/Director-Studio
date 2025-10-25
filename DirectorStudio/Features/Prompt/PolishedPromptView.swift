// MODULE: PolishedPromptView
// VERSION: 2.0.0
// PURPOSE: Refined prompt input view with enhanced UX and visual polish

import SwiftUI
import PhotosUI

struct PolishedPromptView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = PromptViewModel()
    @ObservedObject private var creditsManager = CreditsManager.shared
    @State private var showImagePicker = false
    @State private var showTemplates = false
    @State private var showSegmentEditor = false
    @StateObject private var segmentCollection = MultiClipSegmentCollection()
    @State private var showingInsufficientCredits = false
    @State private var insufficientCreditsInfo: (needed: Int, have: Int) = (0, 0)
    @State private var showingPurchaseView = false
    @State private var animateIn = false
    
    private let theme = DirectorStudioTheme.self
    
    var creditCost: Int {
        viewModel.calculateCreditCost(creditsManager: creditsManager)
    }
    
    var hasEnoughCredits: Bool {
        creditsManager.isDevMode || creditsManager.credits >= creditCost
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.Colors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: theme.Spacing.large) {
                        // Hero section
                        heroSection
                            .padding(.top, theme.Spacing.large)
                        
                        // Main prompt input
                        promptInputSection
                        
                        // Reference image section
                        if viewModel.useReferenceImage || viewModel.referenceImage != nil {
                            referenceImageSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                        
                        // Pipeline options (if not in guest mode)
                        if !coordinator.isGuestMode {
                            pipelineOptionsSection
                                .transition(.opacity)
                        }
                        
                        // Action section with credit info
                        actionSection
                        
                        // Multi-clip option
                        if viewModel.promptText.count > 200 {
                            multiClipOption
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, theme.Spacing.medium)
                    .padding(.bottom, theme.Spacing.xxxLarge)
                }
            }
            .navigationTitle("Create")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Template button
                    Button(action: { showTemplates = true }) {
                        Image(systemName: "doc.text")
                            .foregroundColor(theme.Colors.primary)
                    }
                    
                    // Help button
                    Button(action: { viewModel.showingPromptHelp = true }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(theme.Colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showTemplates) {
            TemplatesSheet(viewModel: viewModel, isPresented: $showTemplates)
        }
        .sheet(isPresented: $viewModel.showingPromptHelp) {
            PromptHelpSheet()
        }
        .sheet(isPresented: $showSegmentEditor) {
            SegmentEditorView(
                segmentCollection: segmentCollection,
                isPresented: $showSegmentEditor,
                onGenerate: { _ in }
            )
        }
        .sheet(isPresented: $showingPurchaseView) {
            EnhancedCreditsPurchaseView()
        }
        .overlay {
            if showingInsufficientCredits {
                InsufficientCreditsOverlay(
                    isShowing: $showingInsufficientCredits,
                    creditsNeeded: insufficientCreditsInfo.needed,
                    creditsHave: insufficientCreditsInfo.have,
                    onPurchase: { showingPurchaseView = true }
                )
            }
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.generationError?.localizedDescription ?? "An error occurred")
        }
        .onAppear {
            withAnimation(theme.Animation.gentle) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Components
    
    private var heroSection: some View {
        VStack(spacing: theme.Spacing.small) {
            // Welcome message based on time of day
            Text(getGreeting())
                .font(theme.Typography.title2)
                .foregroundColor(.primary)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 10)
                .animation(theme.Animation.smooth.delay(0.1), value: animateIn)
            
            Text("What would you like to create today?")
                .font(theme.Typography.subheadline)
                .foregroundColor(.secondary)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 10)
                .animation(theme.Animation.smooth.delay(0.2), value: animateIn)
        }
    }
    
    private var promptInputSection: some View {
        VStack(alignment: .leading, spacing: theme.Spacing.medium) {
            // Quick action pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.Spacing.small) {
                    QuickActionPill(
                        title: "Demo",
                        icon: "play.circle.fill",
                        color: theme.Colors.secondary
                    ) {
                        viewModel.loadDemoContent()
                        HapticFeedback.impact(.light)
                    }
                    
                    QuickActionPill(
                        title: "Templates",
                        icon: "doc.text.fill",
                        color: theme.Colors.primary
                    ) {
                        showTemplates = true
                        HapticFeedback.impact(.light)
                    }
                    
                    QuickActionPill(
                        title: "From Image",
                        icon: "photo.fill",
                        color: theme.Colors.accent
                    ) {
                        withAnimation(theme.Animation.smooth) {
                            viewModel.useReferenceImage.toggle()
                        }
                        HapticFeedback.impact(.light)
                    }
                }
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
            .animation(theme.Animation.smooth.delay(0.3), value: animateIn)
            
            // Main prompt input
            VStack(alignment: .leading, spacing: theme.Spacing.xSmall) {
                HStack {
                    Label("Your Prompt", systemImage: "text.quote")
                        .font(theme.Typography.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !viewModel.promptText.isEmpty {
                        Text("\(viewModel.promptText.count) characters")
                            .font(theme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                TextEditor(text: $viewModel.promptText)
                    .font(theme.Typography.body)
                    .padding(theme.Spacing.small)
                    .frame(minHeight: 120, maxHeight: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(theme.CornerRadius.large)
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.CornerRadius.large)
                            .stroke(viewModel.promptText.isEmpty ? Color.clear : theme.Colors.primary.opacity(0.3), lineWidth: 1)
                    )
                    .disabled(coordinator.isGuestMode)
                    .animation(theme.Animation.quick, value: viewModel.promptText.isEmpty)
                
                if viewModel.promptText.isEmpty && !coordinator.isGuestMode {
                    Text("Describe the video you want to create...")
                        .font(theme.Typography.callout)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, theme.Spacing.small)
                }
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
            .animation(theme.Animation.smooth.delay(0.4), value: animateIn)
        }
        .cardStyle()
        .padding(.horizontal, theme.Spacing.xxSmall)
    }
    
    private var referenceImageSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            HStack {
                Label("Reference Image", systemImage: "photo")
                    .font(theme.Typography.headline)
                
                Spacer()
                
                Toggle("Use Ad", isOn: $viewModel.useDefaultAdImage)
                    .toggleStyle(SwitchToggleStyle(tint: theme.Colors.primary))
                    .scaleEffect(0.8)
            }
            
            if let image = viewModel.referenceImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(theme.CornerRadius.large)
                    
                    Button(action: { 
                        viewModel.referenceImage = nil
                        viewModel.useReferenceImage = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(theme.Spacing.small)
                }
            } else {
                ImagePicker(
                    selectedImage: $viewModel.referenceImage,
                    useDefaultAd: $viewModel.useDefaultAdImage
                )
                .frame(height: 200)
            }
        }
        .cardStyle()
        .padding(.horizontal, theme.Spacing.xxSmall)
    }
    
    private var pipelineOptionsSection: some View {
        VStack(alignment: .leading, spacing: theme.Spacing.medium) {
            Label("Enhancement Options", systemImage: "sparkles")
                .font(theme.Typography.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: theme.Spacing.small) {
                ForEach(viewModel.availableStages, id: \.self) { stage in
                    PipelineToggle(
                        stage: stage,
                        isEnabled: binding(for: stage),
                        creditCost: viewModel.creditCostForStage(stage)
                    )
                }
            }
        }
        .cardStyle()
        .padding(.horizontal, theme.Spacing.xxSmall)
    }
    
    private var actionSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            // Credit display
            CreditStatusBar(
                creditCost: creditCost,
                currentBalance: creditsManager.credits,
                isDevMode: creditsManager.isDevMode,
                hasEnoughCredits: hasEnoughCredits
            )
            
            // Generate button
            Button(action: generateAction) {
                HStack(spacing: theme.Spacing.small) {
                    if viewModel.isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18))
                    }
                    
                    Text(viewModel.isGenerating ? "Creating Magic..." : "Generate Video")
                        .font(theme.Typography.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .primaryButton()
            .disabled(!canGenerate)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
            .animation(theme.Animation.bouncy.delay(0.5), value: animateIn)
            
            // Purchase prompt
            if creditsManager.shouldPromptPurchase && !viewModel.useDefaultAdImage {
                Button(action: { showingPurchaseView = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Get More Credits")
                            .font(theme.Typography.callout)
                    }
                }
                .foregroundColor(theme.Colors.primary)
                .opacity(animateIn ? 1 : 0)
                .animation(theme.Animation.smooth.delay(0.6), value: animateIn)
            }
        }
    }
    
    private var multiClipOption: some View {
        Button(action: {
            prepareSegments()
            showSegmentEditor = true
            HapticFeedback.impact(.medium)
        }) {
            HStack(spacing: theme.Spacing.medium) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 24))
                    .foregroundColor(theme.Colors.secondary)
                
                VStack(alignment: .leading, spacing: theme.Spacing.xxSmall) {
                    HStack {
                        Text("Generate Multiple Clips")
                            .font(theme.Typography.headline)
                        
                        Pill(text: "NEW", color: theme.Colors.secondary)
                    }
                    
                    Text("Create a series with perfect continuity")
                        .font(theme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(theme.Colors.secondary)
            }
            .padding(theme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: theme.CornerRadius.large)
                    .fill(theme.Colors.secondary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.CornerRadius.large)
                            .strokeBorder(theme.Colors.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .disabled(viewModel.isGenerating || viewModel.promptText.isEmpty)
    }
    
    // MARK: - Helpers
    
    private var canGenerate: Bool {
        !coordinator.isGuestMode && 
        !viewModel.isGenerating && 
        !viewModel.promptText.isEmpty && 
        hasEnoughCredits
    }
    
    private func generateAction() {
        if !creditsManager.canAfford(credits: creditCost) {
            insufficientCreditsInfo = (needed: creditCost, have: creditsManager.credits)
            showingInsufficientCredits = true
            HapticFeedback.notification(.warning)
        } else {
            Task {
                await viewModel.generateClip(coordinator: coordinator)
                HapticFeedback.notification(.success)
            }
        }
    }
    
    private func prepareSegments() {
        let segments = MultiClipSegmentCollection.createSegments(
            from: viewModel.promptText,
            strategy: determineSegmentationStrategy()
        )
        
        segmentCollection.segments.removeAll()
        for segment in segments {
            segmentCollection.addSegment(segment)
        }
    }
    
    private func determineSegmentationStrategy() -> MultiClipSegmentationStrategy {
        let text = viewModel.promptText
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        if text.contains("INT.") || text.contains("EXT.") || text.contains("SCENE:") {
            return .byScenes
        } else if wordCount > 300 {
            return .byDuration(5.0)
        } else {
            return .byParagraphs
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
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return "Good morning!"
        case 12..<17:
            return "Good afternoon!"
        case 17..<22:
            return "Good evening!"
        default:
            return "Welcome back!"
        }
    }
}

// MARK: - Supporting Components

struct QuickActionPill: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DirectorStudioTheme.Spacing.xSmall) {
                Image(systemName: icon)
                Text(title)
                    .font(DirectorStudioTheme.Typography.callout)
            }
            .foregroundColor(.white)
            .padding(.horizontal, DirectorStudioTheme.Spacing.medium)
            .padding(.vertical, DirectorStudioTheme.Spacing.small)
            .background(color)
            .cornerRadius(DirectorStudioTheme.CornerRadius.round)
        }
    }
}

struct PipelineToggle: View {
    let stage: PipelineStage
    @Binding var isEnabled: Bool
    let creditCost: Int
    
    var body: some View {
        Toggle(isOn: $isEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stage.displayName)
                    .font(DirectorStudioTheme.Typography.footnote)
                    .fontWeight(.medium)
                Text("+\(creditCost) credit")
                    .font(DirectorStudioTheme.Typography.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: DirectorStudioTheme.Colors.primary))
        .padding(DirectorStudioTheme.Spacing.small)
        .background(Color(.systemGray6))
        .cornerRadius(DirectorStudioTheme.CornerRadius.medium)
    }
}

struct CreditStatusBar: View {
    let creditCost: Int
    let currentBalance: Int
    let isDevMode: Bool
    let hasEnoughCredits: Bool
    
    private var statusColor: Color {
        if isDevMode {
            return DirectorStudioTheme.Colors.creditsFree
        } else if hasEnoughCredits {
            return DirectorStudioTheme.Colors.creditsSufficient
        } else if currentBalance > 0 {
            return DirectorStudioTheme.Colors.creditsLow
        } else {
            return DirectorStudioTheme.Colors.creditsEmpty
        }
    }
    
    var body: some View {
        HStack {
            // Cost display
            HStack(spacing: DirectorStudioTheme.Spacing.xSmall) {
                Image(systemName: "sparkles")
                    .foregroundColor(statusColor)
                
                if isDevMode {
                    Text("FREE")
                        .font(DirectorStudioTheme.Typography.headline)
                        .foregroundColor(statusColor)
                } else {
                    Text("Cost: \(creditCost)")
                        .font(DirectorStudioTheme.Typography.callout)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // Balance display
            HStack(spacing: DirectorStudioTheme.Spacing.xSmall) {
                if isDevMode {
                    Pill(text: "DEV MODE", color: DirectorStudioTheme.Colors.creditsFree)
                } else {
                    Text("Balance:")
                        .font(DirectorStudioTheme.Typography.callout)
                        .foregroundColor(.secondary)
                    
                    Text("\(currentBalance)")
                        .font(DirectorStudioTheme.Typography.creditDisplay)
                        .foregroundColor(statusColor)
                }
            }
        }
        .padding(DirectorStudioTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DirectorStudioTheme.CornerRadius.large)
                .fill(statusColor.opacity(0.1))
        )
    }
}

struct Pill: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(DirectorStudioTheme.Typography.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, DirectorStudioTheme.Spacing.small)
            .padding(.vertical, DirectorStudioTheme.Spacing.xxSmall)
            .background(color)
            .cornerRadius(DirectorStudioTheme.CornerRadius.small)
    }
}
