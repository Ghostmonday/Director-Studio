import Foundation
import UIKit

/// Service that bridges the AI services with the pipeline stages
class PipelineServiceBridge {
    private let polloService: PolloAIService
    private let deepSeekService: DeepSeekAIService
    
    init() {
        self.polloService = PolloAIService()
        self.deepSeekService = DeepSeekAIService()
    }
    
    /// Generate a clip using the full pipeline
    func generateClip(
        prompt: String,
        clipName: String,
        enabledStages: Set<PipelineStage>,
        referenceImageData: Data? = nil,
        isFeaturedDemo: Bool = false,
        duration: TimeInterval = 10.0
    ) async throws -> GeneratedClip {
        print("🎬 Starting clip generation...")
        print("   Clip: \(clipName)")
        print("   Prompt: \(prompt)")
        print("   Image: \(referenceImageData != nil ? "Yes (\(referenceImageData!.count / 1024)KB)" : "No")")
        print("   Featured: \(isFeaturedDemo)")
        
        // Check credits for non-demo generation
        let creditsManager = CreditsManager.shared
        if !creditsManager.shouldUseDemoMode && !isFeaturedDemo {
            guard creditsManager.useCredit() else {
                print("❌ No credits available - switching to demo mode")
                throw PipelineError.configurationError("No credits available. Purchase credits to generate videos.")
            }
        }
        
        print("🔄 Progress: Initializing pipeline... (0%)")
        
        // Stage 1: Analyze continuity
        var continuityAnalysis: ContinuityAnalysis?
        var processedPrompt = prompt
        
        if enabledStages.contains(.continuityAnalysis) {
            print("🔄 Progress: Analyzing continuity... (10%)")
            print("🎬 Analyzing continuity...")
            continuityAnalysis = ContinuityManager.shared.analyzeContinuity(
                prompt: prompt,
                isFirstClip: false, // TODO: Track if this is the first clip in a project
                referenceImage: referenceImageData
            )
            print("✅ Continuity analysis complete")
            print("   Detected: \(continuityAnalysis?.detectedElements ?? "none")")
            print("   Score: \(continuityAnalysis?.continuityScore ?? 0)")
            print("🔄 Progress: Continuity analyzed (20%)")
        }
        
        // Stage 2: Inject continuity elements
        if enabledStages.contains(.continuityInjection), let analysis = continuityAnalysis {
            print("🔄 Progress: Injecting continuity elements... (30%)")
            print("🎬 Injecting continuity elements...")
            processedPrompt = ContinuityManager.shared.injectContinuity(
                prompt: prompt,
                analysis: analysis,
                referenceImage: referenceImageData
            )
            print("✅ Continuity injection complete")
            print("🔄 Progress: Continuity injected (40%)")
        }
        
        // Then enhance prompt if needed (using DeepSeek)
        var enhancedPrompt = processedPrompt
        if enabledStages.contains(.enhancement) {
            print("🔄 Progress: Enhancing prompt with AI... (50%)")
            print("🔧 Enhancing prompt with DeepSeek...")
            do {
                enhancedPrompt = try await deepSeekService.enhancePrompt(
                    prompt: processedPrompt
                )
                print("✅ Enhanced prompt: \(enhancedPrompt.prefix(100))...")
                print("🔄 Progress: Prompt enhanced (60%)")
            } catch {
                print("⚠️  Enhancement failed, using original prompt: \(error)")
            }
        }
        
        // Generate video
        var videoURL: URL
        
        if let imageData = referenceImageData {
            // Image-to-video generation using Pollo
            print("🔄 Progress: Generating video from image... (70%)")
            print("🖼️ Generating video from image...")
            videoURL = try await polloService.generateVideoFromImage(
                imageData: imageData,
                prompt: enhancedPrompt,
                duration: duration
            )
            print("🔄 Progress: Video generated (85%)")
        } else {
            // Text-to-video generation using Pollo
            print("🔄 Progress: Generating video from text... (70%)")
            print("📝 Generating video from text...")
            videoURL = try await polloService.generateVideo(
                prompt: enhancedPrompt,
                duration: duration
            )
            print("🔄 Progress: Video generated (85%)")
        }
        
        // Download video to local storage
        print("🔄 Progress: Downloading video... (90%)")
        print("⬇️ Downloading video...")
        let localVideoURL = try await downloadVideo(from: videoURL, clipName: clipName)
        print("🔄 Progress: Video downloaded (95%)")
        
        // Create clip
        let clip = GeneratedClip(
            id: UUID(),
            name: clipName,
            localURL: localVideoURL,
            thumbnailURL: nil,
            syncStatus: .notUploaded,
            createdAt: Date(),
            duration: duration,
            projectID: nil,
            isGeneratedFromImage: referenceImageData != nil,
            isFeaturedDemo: isFeaturedDemo
        )
        
        print("✅ Generated clip: \(clipName)")
        print("   Local URL: \(localVideoURL.path)")
        print("   Enabled stages: \(enabledStages.map { $0.rawValue }.joined(separator: ", "))")
        print("🔄 Progress: Complete! (100%)")
        print("🎉 Video generation successful!")
        
        return clip
    }
    
    private func downloadVideo(from url: URL, clipName: String) async throws -> URL {
        // Create local file URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(clipName.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).mp4"
        let localURL = documentsPath.appendingPathComponent(fileName)
        
        // Download file
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        
        // Move to permanent location
        try FileManager.default.moveItem(at: tempURL, to: localURL)
        
        return localURL
    }
}

// Backward compatibility typealias is now in PipelineService.swift