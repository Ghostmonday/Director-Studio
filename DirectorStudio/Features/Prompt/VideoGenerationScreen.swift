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
                            onGenerate: {
                                currentStep = .generating
                                Task {
                                    await filmGeneratorViewModel.generateVideos(coordinator: coordinator)
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
    /// - Parameter coordinator: App coordinator for accessing clip repository
    func generateVideos(coordinator: AppCoordinator) async {
        guard let filmBreakdown = film else {
            error = NSError(domain: "FilmGenerator", code: -1, userInfo: [NSLocalizedDescriptionKey: "No film breakdown available"])
            return
        }
        
        // Calculate total token cost from all takes using correct pricing
        let totalTokenCost = filmBreakdown.takes.reduce(0) { total, take in
            // Use MonetizationConfig for accurate token calculation (0.5 tokens per second)
            let credits = MonetizationConfig.creditsForSeconds(take.estimatedDuration)
            let tokensForDuration = MonetizationConfig.tokensToDebit(credits)
            return total + tokensForDuration
        }
        
        let generationTransaction = GenerationTransaction(repository: coordinator.clipRepository)
        
        do {
            // Begin transaction and reserve credits
            try await generationTransaction.begin(totalCost: totalTokenCost)
            
            // Generate each take sequentially to maintain continuity
            for (takeIndex, take) in filmBreakdown.takes.enumerated() {
                currentTakeIndex = takeIndex
                progress = Double(takeIndex) / Double(filmBreakdown.takes.count)
                status = "Generating Take \(take.takeNumber) of \(filmBreakdown.takeCount)..."
                
                do {
                    let generatedClip = try await generateTake(take: take, takeIndex: takeIndex)
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
    /// - Returns: The generated clip
    private func generateTake(take: FilmTake, takeIndex: Int) async throws -> GeneratedClip {
        let videoPrompt = take.prompt
        
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
    let onGenerate: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Summary
            VStack(spacing: 8) {
                Text("Your Film")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 20) {
                    Label("\(film.takeCount) takes", systemImage: "film")
                    Label("\(Int(film.totalDuration))s", systemImage: "timer")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding()
            
            // Takes list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(film.takes) { take in
                        TakePreviewCard(take: take)
                    }
                }
                .padding()
            }
            
            // Actions
            VStack(spacing: 12) {
                Button(action: onGenerate) {
                    Label("Generate Film", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button("Cancel", action: onCancel)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

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
