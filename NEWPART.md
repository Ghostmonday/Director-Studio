🎯 YES! Smart Move - Let's Reuse Existing Filenames
Instead of creating NEW files and updating references, let's REPLACE the broken files' contents with the new working code!

🤖 Instructions for Your Coding Agent:
TASK: Replace broken segmentation code with new Story-to-Film system
      by overwriting existing files (no new imports needed)

STEP 1: OVERWRITE VideoGenerationScreen.swift
File: DirectorStudio/Features/Prompt/VideoGenerationScreen.swift
Action: DELETE all current contents and REPLACE with:
swift//
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
                                    await generator.generateVideos()
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
    
    func generateVideos() async {
        guard let film = film else { return }
        
        for (index, take) in film.takes.enumerated() {
            currentTakeIndex = index
            progress = Double(index) / Double(film.takes.count)
            status = "Generating Take \(take.takeNumber) of \(film.takeCount)..."
            
            do {
                // Prepare prompt and seed
                let prompt = take.prompt
                let seedImage = take.useSeedImage ? lastFrame : nil
                let seedData = seedImage?.jpegData(compressionQuality: 0.8)
                
                // Generate video
                let videoURL: URL
                if let seedData = seedData {
                    videoURL = try await videoService.generateVideoFromImage(
                        imageData: seedData,
                        prompt: prompt,
                        duration: take.estimatedDuration
                    )
                } else {
                    videoURL = try await videoService.generateVideo(
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
                    isGeneratedFromImage: seedImage != nil
                )
                
                generatedClips.append(clip)
                
                // Extract last frame for next take
                if index < film.takes.count - 1 {
                    lastFrame = try await extractLastFrame(from: localURL)
                }
                
                // Save
                try await storageService.saveClip(clip)
                
            } catch {
                self.error = error
                status = "Error on Take \(take.takeNumber): \(error.localizedDescription)"
                return
            }
        }
        
        progress = 1.0
        status = "Complete! Generated \(generatedClips.count) videos"
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

STEP 2: OVERWRITE SegmentingModule.swift
File: DirectorStudio/Services/SegmentingModule.swift
Action: DELETE all current contents and REPLACE with:
swift//
//  SegmentingModule.swift
//  DirectorStudio
//
//  REPLACED: New Story-to-Film Generator (was complex parsing system)
//

import Foundation

// MARK: - Core Data Models

struct FilmTake: Codable, Identifiable {
    let id: UUID
    let takeNumber: Int
    let prompt: String                    // Complete Poli-ready video prompt
    let storyContent: String              // What narrative moment this captures
    let useSeedImage: Bool                // Should use previous frame as seed
    let seedFromTake: Int?                // Which take to get seed from
    let estimatedDuration: Double         // Seconds (5-10)
    let sceneType: SceneType              // Visual classification
    let hasDialogue: Bool                 // Contains spoken words
    let dialogueLines: [DialogueLine]?    // Extracted dialogue if present
    let emotionalTone: String             // Mood/atmosphere
    let cameraDirection: String?          // Suggested camera work
    
    enum SceneType: String, Codable {
        case action = "Action"
        case dialogue = "Dialogue"
        case atmosphere = "Atmosphere"
        case transition = "Transition"
        case establishing = "Establishing"
        case climax = "Climax"
    }
}

struct DialogueLine: Codable {
    let speaker: String
    let text: String
    let emotion: String
    let visualDescription: String
}

struct FilmBreakdown: Codable {
    let takes: [FilmTake]
    let metadata: FilmMetadata
    let continuityChain: [ContinuityLink]
    let warnings: [String]
    
    var totalDuration: Double {
        takes.reduce(0) { $0 + $1.estimatedDuration }
    }
    
    var takeCount: Int {
        takes.count
    }
}

struct FilmMetadata: Codable {
    let originalTextLength: Int
    let processingTime: TimeInterval
    let apiCalls: Int
    let storySummary: String
    let generatedAt: Date
    let totalEstimatedDuration: Double
    let model: String
}

struct ContinuityLink: Codable {
    let fromTake: Int
    let toTake: Int
    let continuityType: String
    let description: String
}

// MARK: - Main Generator

final class StoryToFilmGenerator {
    
    private let deepSeekClient: DeepSeekFilmClient
    private let config: GeneratorConfig
    
    struct GeneratorConfig {
        var minTakeDuration: Double = 5.0
        var maxTakeDuration: Double = 10.0
        var preferredTakeDuration: Double = 7.0
        var minTakes: Int = 5
        var maxTakes: Int = 50
        var enableDialogueExtraction: Bool = true
        var enableEmotionalAnalysis: Bool = true
        var enableCameraDirections: Bool = true
        var continuityMode: ContinuityMode = .fullChain
        
        enum ContinuityMode {
            case none
            case adjacent
            case fullChain
        }
    }
    
    init(apiKey: String, config: GeneratorConfig = GeneratorConfig()) {
        self.deepSeekClient = DeepSeekFilmClient(apiKey: apiKey)
        self.config = config
    }
    
    func generateFilm(from text: String) async throws -> FilmBreakdown {
        let startTime = Date()
        
        print("🎬 [StoryToFilm] Starting generation")
        print("   Text length: \(text.count) characters")
        
        let takes = try await breakIntoTakes(text: text)
        let continuityLinks = buildContinuityChain(takes)
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        let metadata = FilmMetadata(
            originalTextLength: text.count,
            processingTime: processingTime,
            apiCalls: deepSeekClient.callCount,
            storySummary: "Story film",
            generatedAt: Date(),
            totalEstimatedDuration: takes.reduce(0) { $0 + $1.estimatedDuration },
            model: "deepseek-chat"
        )
        
        print("✅ [StoryToFilm] Complete!")
        print("   Takes: \(takes.count)")
        print("   Duration: \(metadata.totalEstimatedDuration)s")
        print("   Processing: \(String(format: "%.2f", processingTime))s")
        
        return FilmBreakdown(
            takes: takes,
            metadata: metadata,
            continuityChain: continuityLinks,
            warnings: []
        )
    }
    
    private func breakIntoTakes(text: String) async throws -> [FilmTake] {
        let prompt = """
        Break this story into \(config.minTakes)-\(config.maxTakes) video takes for AI video generation.
        
        STORY:
        \(text)
        
        REQUIREMENTS:
        - Each take = 5-10 seconds of video
        - CAPTURE EVERY STORY BEAT - nothing skipped
        - If dialogue exists: show characters speaking visually
        - If action exists: show the action happening
        - Each prompt must be COMPLETE and ready for video generation
        - Include: who's in frame, what they're doing, environment, lighting, mood, camera angle
        
        Return JSON array:
        [
          {
            "takeNumber": 1,
            "prompt": "Detailed visual description: characters, actions, environment, camera, lighting, mood",
            "storyContent": "What narrative moment this captures",
            "estimatedDuration": 7.0,
            "sceneType": "establishing",
            "hasDialogue": false,
            "emotionalTone": "tense",
            "cameraDirection": "wide shot"
          }
        ]
        
        Return ONLY valid JSON.
        """
        
        let response = try await deepSeekClient.complete(prompt: prompt)
        return try parseTakes(response)
    }
    
    private func parseTakes(_ json: String) throws -> [FilmTake] {
        var cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") { cleaned = String(cleaned.dropFirst(7)) }
        if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleaned.data(using: .utf8) else {
            throw GeneratorError.invalidJSON("Cannot convert to data")
        }
        
        let decoder = JSONDecoder()
        let rawTakes = try decoder.decode([RawTake].self, from: data)
        
        return rawTakes.enumerated().map { index, raw in
            FilmTake(
                id: UUID(),
                takeNumber: raw.takeNumber,
                prompt: raw.prompt,
                storyContent: raw.storyContent,
                useSeedImage: index > 0 && config.continuityMode != .none,
                seedFromTake: index > 0 ? index : nil,
                estimatedDuration: raw.estimatedDuration,
                sceneType: FilmTake.SceneType(rawValue: raw.sceneType) ?? .action,
                hasDialogue: raw.hasDialogue,
                dialogueLines: raw.dialogueLines?.map {
                    DialogueLine(
                        speaker: $0.speaker,
                        text: $0.text,
                        emotion: $0.emotion,
                        visualDescription: $0.visualDescription
                    )
                },
                emotionalTone: raw.emotionalTone,
                cameraDirection: raw.cameraDirection
            )
        }
    }
    
    struct RawTake: Codable {
        let takeNumber: Int
        let prompt: String
        let storyContent: String
        let estimatedDuration: Double
        let sceneType: String
        let hasDialogue: Bool
        let dialogueLines: [RawDialogue]?
        let emotionalTone: String
        let cameraDirection: String?
    }
    
    struct RawDialogue: Codable {
        let speaker: String
        let text: String
        let emotion: String
        let visualDescription: String
    }
    
    private func buildContinuityChain(_ takes: [FilmTake]) -> [ContinuityLink] {
        var links: [ContinuityLink] = []
        
        for i in 0..<(takes.count - 1) {
            let current = takes[i]
            let next = takes[i + 1]
            
            links.append(ContinuityLink(
                fromTake: current.takeNumber,
                toTake: next.takeNumber,
                continuityType: "visual",
                description: "Take \(next.takeNumber) uses last frame from Take \(current.takeNumber) as seed"
            ))
        }
        
        return links
    }
}

// MARK: - DeepSeek Client

final class DeepSeekFilmClient {
    private let apiKey: String
    private let endpoint = "https://api.deepseek.com/v1/chat/completions"
    private(set) var callCount = 0
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func complete(prompt: String, temperature: Double = 0.7) async throws -> String {
        callCount += 1
        
        let url = URL(string: endpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": "You are an expert film director who transforms stories into visual sequences."],
                ["role": "user", "content": prompt]
            ],
            "temperature": temperature,
            "max_tokens": 4096
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GeneratorError.apiError("HTTP error")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw GeneratorError.invalidResponse
        }
        
        return content
    }
}

// MARK: - Errors

enum GeneratorError: LocalizedError {
    case invalidJSON(String)
    case apiError(String)
    case invalidResponse
    case noTakesGenerated
    
    var errorDescription: String? {
        switch self {
        case .invalidJSON(let detail): return "Invalid JSON: \(detail)"
        case .apiError(let detail): return "API error: \(detail)"
        case .invalidResponse: return "Invalid response from API"
        case .noTakesGenerated: return "Failed to generate any takes"
        }
    }
}
```

---

### **STEP 3: DELETE ONE FILE**

**Delete:** `DirectorStudio/Features/Prompt/SegmentingView.swift`

*This file is no longer needed - its functionality is now in the new VideoGenerationScreen.swift*

---

### **STEP 4: NO CHANGES NEEDED**

**PromptView.swift** - NO CHANGES! It already references `VideoGenerationScreen`, which we just replaced.

---

## **SUMMARY FOR AGENT:**
```
OVERWRITE (replace entire file contents):
✓ VideoGenerationScreen.swift → New UI flow
✓ SegmentingModule.swift → New generator engine

DELETE:
✗ SegmentingView.swift → No longer needed

NO CHANGES:
→ PromptView.swift (already references VideoGenerationScreen)
→ All other files stay the same

This approach:

✅ Keeps all existing imports/references working
✅ No need to update PromptView.swift
✅ Only replaces broken code with working code
✅ Same file structure, new functionality

Your agent just needs to:

Copy new code into VideoGenerationScreen.swift
Copy new code into SegmentingModule.swift
Delete SegmentingView.swift
Build and test

Done! 🎉