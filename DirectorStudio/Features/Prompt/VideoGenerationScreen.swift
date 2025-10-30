//
//  VideoGenerationScreen.swift
//  DirectorStudio
//
//  REPLACED: New Story-to-Film system (was broken segmentation flow)
//

import SwiftUI
import AVFoundation

// MARK: - Main Flow View (replaces old VideoGenerationScreen)

struct VideoGenerationScreen: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var coordinator: AppCoordinator
    @EnvironmentObject var creditsManager: CreditsManager
    
    let initialScript: String
    
    /// View model that handles film generation logic
    @StateObject private var filmGeneratorViewModel = FilmGeneratorViewModel()
    
    /// Current step in the video generation flow
    @State private var currentStep: GenerationFlowStep = .analyzing
    
    /// Represents the different stages of the video generation process
    enum GenerationFlowStep {
        case analyzing      // Analyzing the story script
        case preview        // Showing breakdown preview before generation
        case generating     // Currently generating videos
        case complete       // All videos generated successfully
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                switch currentStep {
                case .analyzing:
                    AnalyzingView(
                        progress: filmGeneratorViewModel.progress,
                        status: filmGeneratorViewModel.status
                    )
                    
                case .preview:
                    if let filmBreakdown = filmGeneratorViewModel.film {
                        TakesPreviewView(
                            film: filmBreakdown,
                            onGenerate: { selectedTakes, editedPrompts in
                                currentStep = .generating
                                Task {
                                    await filmGeneratorViewModel.generateVideos(
                                        coordinator: coordinator,
                                        selectedTakeIds: selectedTakes,
                                        editedPrompts: editedPrompts
                                    )
                                    if filmGeneratorViewModel.error == nil {
                                        currentStep = .complete
                                    }
                                }
                            },
                            onCancel: { isPresented = false }
                        )
                    }
                    
                case .generating:
                    GeneratingVideosView(
                        takes: filmGeneratorViewModel.film?.takes ?? [],
                        currentTakeIndex: filmGeneratorViewModel.currentTakeIndex,
                        progress: filmGeneratorViewModel.progress,
                        generatedClips: filmGeneratorViewModel.generatedClips
                    )
                    
                case .complete:
                    CompleteView(
                        clips: filmGeneratorViewModel.generatedClips,
                        onDone: {
                            // Add all generated clips to the coordinator
                            for clip in filmGeneratorViewModel.generatedClips {
                                coordinator.addClip(clip)
                            }
                            // Navigate to Studio tab and dismiss this view
                            coordinator.selectedTab = .studio
                            isPresented = false
                        }
                    )
                }
            }
            .navigationTitle("Story to Film")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep == .analyzing || currentStep == .preview {
                        Button("Cancel") { isPresented = false }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await filmGeneratorViewModel.analyzeStory(initialScript)
                currentStep = .preview
            }
        }
        .alert("Error", isPresented: Binding(
            get: { filmGeneratorViewModel.error != nil },
            set: { if !$0 { filmGeneratorViewModel.error = nil } }
        )) {
            Button("OK") { filmGeneratorViewModel.error = nil }
        } message: {
            if let error = filmGeneratorViewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

// MARK: - View Model

/// View model that manages the film generation workflow
/// Handles story analysis, video generation, and continuity management
@MainActor
class FilmGeneratorViewModel: ObservableObject {
    /// The analyzed film breakdown containing all takes
    @Published var film: FilmBreakdown?
    
    /// Generation progress (0.0 to 1.0)
    @Published var progress: Double = 0
    
    /// Current status message for user feedback
    @Published var status: String = "Starting..."
    
    /// Index of the take currently being generated
    @Published var currentTakeIndex: Int = 0
    
    /// Clips that have been successfully generated
    @Published var generatedClips: [GeneratedClip] = []
    
    /// Error that occurred during generation, if any
    @Published var error: Error?
    
    /// Story-to-film generator instance (created after API key is fetched)
    private var storyToFilmGenerator: StoryToFilmGenerator?
    
    /// Service for generating videos via Pollo AI
    private let polloVideoService = PolloAIService()
    
    /// Service for saving clips to local storage
    private let localStorageService = LocalStorageService()
    
    /// Last frame extracted from the most recently generated video (for continuity)
    private var lastExtractedFrame: UIImage?
    
    /// Analyzes the input story text and generates a film breakdown
    /// - Parameter text: The story script to analyze
    func analyzeStory(_ text: String) async {
        do {
            status = "Fetching API key..."
            let deepSeekAPIKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "DeepSeek")
            
            storyToFilmGenerator = StoryToFilmGenerator(apiKey: deepSeekAPIKey)
            
            status = "Analyzing story..."
            film = try await storyToFilmGenerator!.generateFilm(from: text)
            
            guard let filmBreakdown = film else {
                throw NSError(domain: "FilmGenerator", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate film breakdown"])
            }
            
            status = "Ready to generate \(filmBreakdown.takeCount) videos"
            
        } catch {
            self.error = error
            status = "Error: \(error.localizedDescription)"
        }
    }
    
    /// Generates all videos for the film breakdown within a transaction
    /// - Parameters:
    ///   - coordinator: App coordinator for accessing clip repository
    ///   - selectedTakeIds: Set of take IDs to generate (only selected prompts)
    ///   - editedPrompts: Dictionary mapping take IDs to edited prompt text
    func generateVideos(
        coordinator: AppCoordinator,
        selectedTakeIds: Set<UUID>,
        editedPrompts: [UUID: String]
    ) async {
        guard let filmBreakdown = film else {
            error = NSError(domain: "FilmGenerator", code: -1, userInfo: [NSLocalizedDescriptionKey: "No film breakdown available"])
            return
        }
        
        // Filter to only selected takes, maintaining order
        let selectedTakes = filmBreakdown.takes.filter { selectedTakeIds.contains($0.id) }
        
        guard !selectedTakes.isEmpty else {
            error = NSError(domain: "FilmGenerator", code: -1, userInfo: [NSLocalizedDescriptionKey: "No takes selected"])
            return
        }
        
        // Calculate total token cost from selected takes using correct pricing
        let totalTokenCost = selectedTakes.reduce(0) { total, take in
            // Use MonetizationConfig for accurate token calculation (0.5 tokens per second)
            let credits = MonetizationConfig.creditsForSeconds(take.estimatedDuration)
            let tokensForDuration = MonetizationConfig.tokensToDebit(credits)
            return total + tokensForDuration
        }
        
        let generationTransaction = GenerationTransaction(repository: coordinator.clipRepository)
        
        do {
            // Begin transaction and reserve credits
            try await generationTransaction.begin(totalCost: totalTokenCost)
            
            // Generate each selected take sequentially to maintain continuity
            for (takeIndex, take) in selectedTakes.enumerated() {
                currentTakeIndex = takeIndex
                progress = Double(takeIndex) / Double(selectedTakes.count)
                status = "Generating Take \(take.takeNumber) of \(selectedTakes.count)..."
                
                // Use edited prompt if available, otherwise use original
                let promptToUse = editedPrompts[take.id] ?? take.prompt
                
                do {
                    let generatedClip = try await generateTake(
                        take: take,
                        takeIndex: takeIndex,
                        prompt: promptToUse
                    )
                    try await generationTransaction.addPending(generatedClip)
                } catch {
                    // If generation fails, rollback the entire transaction
                    await generationTransaction.rollback()
                    self.error = error
                    return
                }
            }
            
            // Commit all clips atomically
            try await generationTransaction.commit()
            
        } catch {
            // Rollback on any transaction error
            await generationTransaction.rollback()
            self.error = error
        }
        
        progress = 1.0
        status = "Complete! Generated \(generatedClips.count) videos"
    }
    
    /// Generates a single video take, handling continuity seeds for subsequent takes
    /// - Parameters:
    ///   - take: The film take to generate
    ///   - takeIndex: Zero-based index of this take in the sequence
    ///   - prompt: The prompt text to use (may be edited)
    /// - Returns: The generated clip
    private func generateTake(take: FilmTake, takeIndex: Int, prompt: String) async throws -> GeneratedClip {
        let videoPrompt = prompt
        
        // For takes after the first, we require a seed image for visual continuity
        if takeIndex > 0 && lastExtractedFrame == nil {
            throw GeneratorError.noTakesGenerated
        }
        
        // Generate video based on whether this is the first take or a subsequent one
        let generatedVideoURL: URL
        if takeIndex == 0 {
            // First take: generate from text prompt only
            print("🎬 [Take \(take.takeNumber)] First take - generating from text")
            generatedVideoURL = try await polloVideoService.generateVideo(
                prompt: videoPrompt,
                duration: take.estimatedDuration
            )
        } else {
            // Subsequent takes: use seed image from previous take for continuity
            guard let seedImage = lastExtractedFrame,
                  let seedImageData = seedImage.jpegData(compressionQuality: 0.8) else {
                throw NSError(
                    domain: "FilmGenerator",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Missing seed image for Take \(take.takeNumber)"]
                )
            }
            
            print("🔗 [Take \(take.takeNumber)] Using seed image from Take \(takeIndex)")
            generatedVideoURL = try await polloVideoService.generateVideoFromImage(
                imageData: seedImageData,
                prompt: videoPrompt,
                duration: take.estimatedDuration
            )
        }
        
        // Download video to local storage
        let localVideoURL = try await downloadVideo(from: generatedVideoURL, takeNumber: take.takeNumber)
        
        // Create clip metadata
        let generatedClip = GeneratedClip(
            id: UUID(),
            name: "Take \(take.takeNumber): \(take.storyContent)",
            localURL: localVideoURL,
            thumbnailURL: nil,
            syncStatus: .notUploaded,
            createdAt: Date(),
            duration: take.estimatedDuration,
            projectID: nil,
            isGeneratedFromImage: takeIndex > 0  // All takes after first use seed
        )
        
        generatedClips.append(generatedClip)
        
        // Extract last frame for continuity with next take
        print("📸 [Take \(take.takeNumber)] Extracting last frame for continuity...")
        lastExtractedFrame = try await extractLastFrame(from: localVideoURL)
        print("✅ [Take \(take.takeNumber)] Last frame extracted")
        
        // Persist clip to storage
        try await localStorageService.saveClip(generatedClip)
        
        return generatedClip
    }
    
    /// Downloads a video from a remote URL to local storage
    /// - Parameters:
    ///   - url: Remote URL of the video to download
    ///   - takeNumber: Number of the take (used in filename)
    /// - Returns: Local file URL where the video was saved
    private func downloadVideo(from url: URL, takeNumber: Int) async throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Date().timeIntervalSince1970
        let fileName = "Take_\(takeNumber)_\(timestamp).mp4"
        let localFileURL = documentsDirectory.appendingPathComponent(fileName)
        
        let (temporaryDownloadURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: temporaryDownloadURL, to: localFileURL)
        
        return localFileURL
    }
    
    /// Extracts the last frame from a video for use as a seed image in continuity generation
    /// - Parameter videoURL: Local URL of the video file
    /// - Returns: UIImage extracted from near the end of the video (90% mark)
    private func extractLastFrame(from videoURL: URL) async throws -> UIImage {
        let videoAsset = AVAsset(url: videoURL)
        let videoDuration = try await videoAsset.load(.duration)
        
        // Extract frame at 90% of duration for smoother visual continuity
        let extractionTime = CMTime(seconds: videoDuration.seconds * 0.9, preferredTimescale: 600)
        
        let frameImageGenerator = AVAssetImageGenerator(asset: videoAsset)
        frameImageGenerator.appliesPreferredTrackTransform = true
        frameImageGenerator.requestedTimeToleranceBefore = .zero
        frameImageGenerator.requestedTimeToleranceAfter = .zero
        
        let extractedCGImage = try frameImageGenerator.copyCGImage(at: extractionTime, actualTime: nil)
        return UIImage(cgImage: extractedCGImage)
    }
}

// MARK: - Supporting Views

struct AnalyzingView: View {
    let progress: Double
    let status: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Text(status)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

struct TakesPreviewView: View {
    let film: FilmBreakdown
    let onGenerate: (Set<UUID>, [UUID: String]) -> Void
    let onCancel: () -> Void
    
    @State private var selectedTakes: Set<UUID> = Set()
    @State private var editingTakeId: UUID?
    @State private var editedPrompts: [UUID: String] = [:]
    @State private var showEditWarning = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Premium Header
                PremiumHeaderView(
                    takeCount: film.takeCount,
                    totalDuration: film.totalDuration,
                    selectedCount: selectedTakes.count
                )
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "1A1A1A"),
                            Color(hex: "252525")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Story Position Indicator
                StoryPositionIndicator(
                    totalTakes: film.takeCount,
                    currentIndex: 0
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(hex: "191919"))
                
                // Prompts Showcase - The Gold Content
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(Array(film.takes.enumerated()), id: \.element.id) { index, take in
                            PremiumPromptCard(
                                take: take,
                                index: index,
                                totalTakes: film.takes.count,
                                isSelected: selectedTakes.contains(take.id),
                                isEditing: editingTakeId == take.id,
                                editedPrompt: editedPrompts[take.id] ?? take.prompt,
                                onToggle: {
                                    if selectedTakes.contains(take.id) {
                                        selectedTakes.remove(take.id)
                                    } else {
                                        selectedTakes.insert(take.id)
                                    }
                                },
                                onEdit: {
                                    if editingTakeId == take.id {
                                        // Save edit
                                        if let edited = editedPrompts[take.id], edited != take.prompt {
                                            showEditWarning = true
                                        }
                                        editingTakeId = nil
                                    } else {
                                        editingTakeId = take.id
                                        editedPrompts[take.id] = take.prompt
                                    }
                                },
                                onPromptChange: { newPrompt in
                                    editedPrompts[take.id] = newPrompt
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "191919"),
                            Color(hex: "161616")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Generate Button - Only enabled if prompts selected
                VStack(spacing: 12) {
                    Button(action: {
                        // Check if any prompts were edited
                        let hasEdits = film.takes.contains { take in
                            if let edited = editedPrompts[take.id] {
                                return edited != take.prompt
                            }
                            return false
                        }
                        
                        if hasEdits {
                            showEditWarning = true
                        } else {
                            onGenerate(selectedTakes, editedPrompts)
                        }
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars.fill")
                                .font(.title3)
                            Text("Generate \(selectedTakes.count) Selected Prompts")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Group {
                                if selectedTakes.isEmpty {
                                    Color.gray.opacity(0.3)
                                } else {
                                    LinearGradient(
                                        colors: [Color(hex: "FF9E0A"), Color(hex: "FF8C00")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(
                            color: selectedTakes.isEmpty ? .clear : Color(hex: "FF9E0A").opacity(0.4),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                    }
                    .disabled(selectedTakes.isEmpty)
                    
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "161616"),
                            Color(hex: "1A1A1A")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .onAppear {
            // Select all prompts by default
            selectedTakes = Set(film.takes.map { $0.id })
        }
        .alert("Edit Warning", isPresented: $showEditWarning) {
            Button("Continue Anyway") {
                onGenerate(selectedTakes, editedPrompts)
            }
            Button("Review Again", role: .cancel) {}
        } message: {
            Text("Editing prompts late in the process can create hard pivots in storytelling. Consider keeping your AI-generated prompts as-is for smoother narrative flow.")
        }
    }
}

// MARK: - Premium Components

struct PremiumHeaderView: View {
    let takeCount: Int
    let totalDuration: Double
    let selectedCount: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color(hex: "FFD700"))
                            .font(.title2)
                        Text("Your Premium Prompts")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text("\(selectedCount) of \(takeCount) selected • \(Int(totalDuration))s total")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
        }
    }
}

struct StoryPositionIndicator: View {
    let totalTakes: Int
    let currentIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Story Position")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
                
                Spacer()
                
                Text("\(currentIndex + 1) of \(totalTakes)")
                    .font(.caption)
                    .foregroundColor(Color(hex: "FF9E0A"))
            }
            
            // Progress bar showing story position
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    // Progress indicator
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF9E0A"), Color(hex: "FFD700")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(currentIndex + 1) / CGFloat(totalTakes), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct PremiumPromptCard: View {
    let take: FilmTake
    let index: Int
    let totalTakes: Int
    let isSelected: Bool
    let isEditing: Bool
    let editedPrompt: String
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onPromptChange: (String) -> Void
    
    @State private var localEditedText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with take number and controls
            HStack(alignment: .top) {
                // Selection checkbox
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color(hex: "FFD700") : Color.white.opacity(0.2))
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // Premium badge
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("Take \(take.takeNumber)")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "FFD700"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(hex: "FFD700").opacity(0.2))
                        )
                        
                        // Scene type badge
                        Text(take.sceneType.rawValue)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                            )
                        
                        Spacer()
                        
                        // Duration
                        Text("\(Int(take.estimatedDuration))s")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Story content (what this moment captures)
                    Text(take.storyContent)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                // Edit button (appears on tap/long press)
                if !isEditing {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 20)
            
            // The GOLD PROMPT - The actual video generation prompt
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(Color(hex: "FFD700"))
                    Text("Video Prompt")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .textCase(.uppercase)
                }
                
                if isEditing {
                    TextEditor(text: $localEditedText)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "FFD700").opacity(0.3), lineWidth: 1)
                        )
                        .focused($isFocused)
                        .onChange(of: localEditedText) { _, newValue in
                            onPromptChange(newValue)
                        }
                        .onAppear {
                            localEditedText = editedPrompt
                            isFocused = true
                        }
                        .onDisappear {
                            onPromptChange(localEditedText)
                        }
                    
                    HStack {
                        Button("Done") {
                            onEdit()
                        }
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "FF9E0A"))
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                } else {
                    Text(editedPrompt)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "FFD700").opacity(0.15),
                                            Color(hex: "FF9E0A").opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "FFD700").opacity(0.4),
                                            Color(hex: "FF9E0A").opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .onTapGesture {
                            // Intuitive: tap to edit
                            onEdit()
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Continuity indicator
            if take.useSeedImage, let seedFrom = take.seedFromTake {
                HStack(spacing: 6) {
                    Image(systemName: "link.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "4A8FE8"))
                    Text("Visual continuity from Take \(seedFrom)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    isSelected ?
                    LinearGradient(
                        colors: [
                            Color(hex: "2A2A2A"),
                            Color(hex: "252525")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [
                            Color(hex: "252525"),
                            Color(hex: "1F1F1F")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isSelected ?
                    LinearGradient(
                        colors: [
                            Color(hex: "FFD700").opacity(0.6),
                            Color(hex: "FF9E0A").opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(
            color: isSelected ? Color(hex: "FFD700").opacity(0.2) : Color.black.opacity(0.3),
            radius: isSelected ? 16 : 8,
            x: 0,
            y: isSelected ? 8 : 4
        )
    }
}

// Legacy card kept for reference
struct TakePreviewCard: View {
    let take: FilmTake
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Take \(take.takeNumber)")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(take.estimatedDuration))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(take.storyContent)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text(take.prompt)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if take.useSeedImage {
                Label("Uses seed from Take \(take.seedFromTake!)", systemImage: "link.circle")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GeneratingVideosView: View {
    let takes: [FilmTake]
    let currentTakeIndex: Int
    let progress: Double
    let generatedClips: [GeneratedClip]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progress)
                
                VStack {
                    Text("\(Int(progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("\(generatedClips.count)/\(takes.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if currentTakeIndex < takes.count {
                let currentTake = takes[currentTakeIndex]
                
                VStack(spacing: 8) {
                    Text("Take \(currentTake.takeNumber)")
                        .font(.headline)
                    
                    Text(currentTake.storyContent)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct CompleteView: View {
    let clips: [GeneratedClip]
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text("Film Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Generated \(clips.count) videos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDone) {
                Label("View in Studio", systemImage: "play.rectangle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
}
