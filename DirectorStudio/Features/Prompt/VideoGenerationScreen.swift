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
    
    @StateObject private var generator = FilmGeneratorViewModel()
    @State private var currentStep: FlowStep = .analyzing
    
    enum FlowStep {
        case analyzing
        case preview
        case generating
        case complete
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                switch currentStep {
                case .analyzing:
                    AnalyzingView(progress: generator.progress, status: generator.status)
                    
                case .preview:
                    if let film = generator.film {
                        TakesPreviewView(
                            film: film,
                            onGenerate: {
                                currentStep = .generating
                                Task {
                                    await generator.generateVideos(coordinator: coordinator)
                                    if generator.error == nil {
                                        currentStep = .complete
                                    }
                                }
                            },
                            onCancel: { isPresented = false }
                        )
                    }
                    
                case .generating:
                    GeneratingVideosView(
                        takes: generator.film?.takes ?? [],
                        currentTake: generator.currentTakeIndex,
                        progress: generator.progress,
                        generatedClips: generator.generatedClips
                    )
                    
                case .complete:
                    CompleteView(
                        clips: generator.generatedClips,
                        onDone: {
                            for clip in generator.generatedClips {
                                coordinator.addClip(clip)
                            }
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
                await generator.analyzeStory(initialScript)
                currentStep = .preview
            }
        }
        .alert("Error", isPresented: Binding(
            get: { generator.error != nil },
            set: { if !$0 { generator.error = nil } }
        )) {
            Button("OK") { generator.error = nil }
        } message: {
            if let error = generator.error {
                Text(error.localizedDescription)
            }
        }
    }
}

// MARK: - View Model

@MainActor
class FilmGeneratorViewModel: ObservableObject {
    @Published var film: FilmBreakdown?
    @Published var progress: Double = 0
    @Published var status: String = "Starting..."
    @Published var currentTakeIndex: Int = 0
    @Published var generatedClips: [GeneratedClip] = []
    @Published var error: Error?
    
    private var storyGenerator: StoryToFilmGenerator?
    private let videoService = PolloAIService()
    private let storageService = LocalStorageService()
    private var lastFrame: UIImage?
    
    func analyzeStory(_ text: String) async {
        do {
            status = "Fetching API key..."
            let apiKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "DeepSeek")
            
            storyGenerator = StoryToFilmGenerator(apiKey: apiKey)
            
            status = "Analyzing story..."
            film = try await storyGenerator!.generateFilm(from: text)
            
            status = "Ready to generate \(film!.takeCount) videos"
            
        } catch {
            self.error = error
            status = "Error: \(error.localizedDescription)"
        }
    }
    
    func generateVideos(coordinator: AppCoordinator) async {
        guard let film = film, let totalCost = film.totalTokenCost else { return }
        
        let transaction = GenerationTransaction(repository: coordinator.clipRepository)
        
        do {
            try transaction.begin(cost: totalCost)
            
            for (index, take) in film.takes.enumerated() {
                currentTakeIndex = index
                progress = Double(index) / Double(film.takes.count)
                status = "Generating Take \(take.takeNumber) of \(film.takeCount)..."
                
                do {
                    let clip = try await generateTake(take: take, index: index)
                    await transaction.addPending(clip)
                } catch {
                    // await showPartialSaveAlert(with: await transaction.pendingClips, error: error)
                    await transaction.rollback()
                    return
                }
            }
            
            try await transaction.commit()
            
        } catch {
            await transaction.rollback()
            self.error = error
        }
        
        progress = 1.0
        status = "Complete! Generated \(generatedClips.count) videos"
    }
    
    private func generateTake(take: FilmTake, index: Int) async throws -> GeneratedClip {
        // Prepare prompt and seed
        let prompt = take.prompt
        
        // For takes after the first, we MUST have a seed image for continuity
        if index > 0 && lastFrame == nil {
            throw GeneratorError.noTakesGenerated
        }
        
        // Generate video
        let videoURL: URL
        if index == 0 {
            // First take - no seed
            print("🎬 [Take \(take.takeNumber)] First take - generating from text")
            videoURL = try await videoService.generateVideo(
                prompt: prompt,
                duration: take.estimatedDuration
            )
        } else {
            // All subsequent takes MUST use seed for continuity
            guard let seedImage = lastFrame,
                  let seedData = seedImage.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "FilmGenerator", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Missing seed image for Take \(take.takeNumber)"])
            }
            
            print("🔗 [Take \(take.takeNumber)] Using seed image from Take \(index)")
            videoURL = try await videoService.generateVideoFromImage(
                imageData: seedData,
                prompt: prompt,
                duration: take.estimatedDuration
            )
        }
        
        // Download locally
        let localURL = try await downloadVideo(from: videoURL, takeNumber: take.takeNumber)
        
        // Create clip
        let clip = GeneratedClip(
            id: UUID(),
            name: "Take \(take.takeNumber): \(take.storyContent)",
            localURL: localURL,
            thumbnailURL: nil,
            syncStatus: .notUploaded,
            createdAt: Date(),
            duration: take.estimatedDuration,
            projectID: nil,
            isGeneratedFromImage: index > 0  // All takes after first use seed
        )
        
        generatedClips.append(clip)
        
        // ALWAYS extract last frame for continuity (even for last take)
        print("📸 [Take \(take.takeNumber)] Extracting last frame for continuity...")
        lastFrame = try await extractLastFrame(from: localURL)
        print("✅ [Take \(take.takeNumber)] Last frame extracted")
        
        // Save
        try await storageService.saveClip(clip)
        
        return clip
    }
    
    private func downloadVideo(from url: URL, takeNumber: Int) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "Take_\(takeNumber)_\(Date().timeIntervalSince1970).mp4"
        let localURL = documentsPath.appendingPathComponent(fileName)
        
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: tempURL, to: localURL)
        
        return localURL
    }
    
    private func extractLastFrame(from videoURL: URL) async throws -> UIImage {
        let asset = AVAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        
        // Extract at 90% of duration for smoother continuity
        let time = CMTime(seconds: duration.seconds * 0.9, preferredTimescale: 600)
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        
        let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: cgImage)
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
    let currentTake: Int
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
            
            if currentTake < takes.count {
                let take = takes[currentTake]
                
                VStack(spacing: 8) {
                    Text("Take \(take.takeNumber)")
                        .font(.headline)
                    
                    Text(take.storyContent)
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
