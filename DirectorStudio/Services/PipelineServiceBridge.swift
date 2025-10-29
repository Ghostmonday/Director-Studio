// MODULE: PipelineServiceBridge
// VERSION: 2.0.0
// PURPOSE: Service that bridges the AI services with the pipeline stages using dependency injection

import Foundation
import UIKit

/// Service that bridges the AI services with the pipeline stages
class PipelineServiceBridge {
    private let videoService: VideoGenerationProtocol
    private let textService: TextEnhancementProtocol
    private let continuityManager: ContinuityManagerProtocol
    private let storageService: StorageServiceProtocol
    private let stitchingService: VideoStitchingProtocol?
    private let voiceoverService: VoiceoverGenerationProtocol?
    
    /// Initialize with dependency injection
    init(
        videoService: VideoGenerationProtocol? = nil,
        textService: TextEnhancementProtocol? = nil,
        continuityManager: ContinuityManagerProtocol? = nil,
        storageService: StorageServiceProtocol? = nil,
        stitchingService: VideoStitchingProtocol? = nil,
        voiceoverService: VoiceoverGenerationProtocol? = nil
    ) {
        // Use factory to create default services if not provided
        self.videoService = videoService ?? AIServiceFactory.createVideoService()
        self.textService = textService ?? AIServiceFactory.createTextService()
        self.continuityManager = continuityManager ?? ContinuityManager.shared
        self.storageService = storageService ?? LocalStorageService()
        self.stitchingService = stitchingService
        self.voiceoverService = voiceoverService
    }
    
    /// Generate a clip using the full pipeline
    func generateClip(
        prompt: String,
        clipName: String,
        enabledStages: Set<PipelineStage>,
        referenceImageData: Data? = nil,
        duration: TimeInterval = 10.0,
        isFirstClip: Bool = false
    ) async throws -> GeneratedClip {
        print("🎬 Starting clip generation...")
        print("   Clip: \(clipName)")
        print("   Prompt: \(prompt)")
        print("   Image: \(referenceImageData != nil ? "Yes (\(referenceImageData!.count / 1024)KB)" : "No")")
        
        // Credit enforcement - calculate total cost
        let totalCost = CreditsManager.shared.creditsNeeded(for: duration, enabledStages: enabledStages)
        // let reservationID = CreditsManager.shared.reserveCredits(amount: cost)
        
        // defer {
        //     if Task.isCancelled || currentError != nil {
        //         CreditsManager.shared.cancelReservation(reservationID)
        //     }
        // }
        
        // Always use real API - demo mode has been removed
        
        print("🔄 Progress: Initializing pipeline... (0%)")
        
        // Stage 1: Analyze continuity
        var continuityAnalysis: ContinuityAnalysis?
        var processedPrompt = prompt
        
        if enabledStages.contains(.continuityAnalysis) {
            print("🔄 Progress: Analyzing continuity... (10%)")
            print("🎬 Analyzing continuity...")
            continuityAnalysis = continuityManager.analyzeContinuity(
                prompt: prompt,
                isFirstClip: isFirstClip,
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
            processedPrompt = continuityManager.injectContinuity(
                prompt: prompt,
                analysis: analysis,
                referenceImage: referenceImageData
            )
            print("✅ Continuity injection complete")
            print("🔄 Progress: Continuity injected (40%)")
        }
        
        // Enhancement stage removed - now handled by PromptGeneratorModule
        // The prompt will be processed by the new modular generator before reaching this point
        var enhancedPrompt = processedPrompt
        print("📝 [Pipeline] Using prompt as-is (enhancement handled by PromptGenerator)")
        print("🔄 Progress: Prompt ready (60%)")
        
        // Generate video
        var videoURL: URL
        
        if let imageData = referenceImageData {
            // Image-to-video generation
            print("🔄 Progress: Generating video from image... (70%)")
            print("🖼️ Generating video from image...")
            videoURL = try await videoService.generateVideoFromImage(
                imageData: imageData,
                prompt: enhancedPrompt,
                duration: duration
            )
            print("🔄 Progress: Video generated (85%)")
        } else {
            // Text-to-video generation
            print("🔄 Progress: Generating video from text... (70%)")
            print("📝 Generating video from text...")
            videoURL = try await videoService.generateVideo(
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
        )
        
        // Save clip to storage
        try await storageService.saveClip(clip)
        
        print("✅ Generated clip: \(clipName)")
        print("   Local URL: \(localVideoURL.path)")
        print("   Enabled stages: \(enabledStages.map { $0.rawValue }.joined(separator: ", "))")
        
        // Deduct credits for successful generation
        // CreditsManager.shared.commitReservation(reservationID)
        
        print("🔄 Progress: Complete! (100%)")
        print("🎉 Video generation successful!")
        
        return clip
    }
    
    /// Generate multiple clips from a segmented script
    func generateMultiClipSequence(
        script: String,
        segmentationStrategy: SegmentationStrategy = .automatic,
        enabledStages: Set<PipelineStage> = Set(PipelineStage.allCases),
    ) async throws -> [GeneratedClip] {
        print("🎬 Starting multi-clip sequence generation...")
        
        // 1. Segment script into scenes
        let segments = try await segmentScript(script, strategy: segmentationStrategy)
        print("📝 Script segmented into \(segments.count) clips")
        
        // 2. Generate clips with continuity
        var clips: [GeneratedClip] = []
        for (index, segment) in segments.enumerated() {
            let isFirst = index == 0
            print("\n🎬 Generating clip \(index + 1)/\(segments.count): \(segment.name)")
            
            let clip = try await generateClip(
                prompt: segment.text,
                clipName: segment.name,
                enabledStages: enabledStages,
                referenceImageData: nil,
                duration: segment.estimatedDuration,
                isFirstClip: isFirst
            )
            clips.append(clip)
        }
        
        print("\n✅ Generated \(clips.count) clips successfully")
        return clips
    }
    
    /// Generate a complete production with optional voiceover
    func generateCompleteProduction(
        script: String,
        includeVoiceover: Bool = true,
        voiceoverStyle: VoiceoverStyle? = nil,
        segmentationStrategy: SegmentationStrategy = .automatic,
        transitionStyle: TransitionStyle = .crossfade,
        exportQuality: ExportQuality = .high,
    ) async throws -> ProductionOutput {
        print("🎬 Starting complete production generation...")
        
        // 1. Generate video clips
        let clips = try await generateMultiClipSequence(
            script: script,
            segmentationStrategy: segmentationStrategy,
        )
        
        // 2. Generate voiceover if requested
        var voiceoverTrack: VoiceoverTrack?
        if includeVoiceover, let voiceoverService = voiceoverService {
            print("\n🎙️ Generating voiceover...")
            voiceoverTrack = try await voiceoverService.generateVoiceover(
                script: script,
                style: voiceoverStyle ?? .automatic
            )
            print("✅ Voiceover generated: \(voiceoverTrack?.duration ?? 0)s")
        }
        
        // 3. Stitch clips if we have a stitching service
        let finalVideoURL: URL
        if clips.count > 1, let stitchingService = stitchingService {
            print("\n🎬 Stitching \(clips.count) clips...")
            finalVideoURL = try await stitchingService.stitchClips(
                clips,
                withTransitions: transitionStyle,
                outputQuality: exportQuality
            )
            print("✅ Video stitched successfully")
        } else if let firstClip = clips.first?.localURL {
            // Single clip, use it directly
            finalVideoURL = firstClip
        } else {
            throw PipelineError.executionFailed("No video clips generated")
        }
        
        // 4. Mix audio if voiceover exists and we have a stitching service
        let outputURL: URL
        if let voiceover = voiceoverTrack,
           let voiceoverURL = voiceover.localURL,
           stitchingService != nil {
            print("\n🎵 Mixing audio with video...")
            outputURL = try await mixAudioWithVideo(
                video: finalVideoURL,
                audio: voiceoverURL
            )
            print("✅ Audio mixed successfully")
        } else {
            outputURL = finalVideoURL
        }
        
        // Calculate total duration
        let totalDuration = clips.reduce(0) { $0 + $1.duration }
        
        return ProductionOutput(
            videoURL: outputURL,
            voiceoverTrack: voiceoverTrack,
            clips: clips,
            totalDuration: totalDuration
        )
    }
    
    // MARK: - Private Methods
    
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
    
    private func segmentScript(_ script: String, strategy: SegmentationStrategy) async throws -> [ScriptSegment] {
        switch strategy {
        case .automatic:
            // Simple paragraph-based segmentation for now
            return segmentByParagraphs(script)
        case .byScenes:
            // TODO: Implement scene detection
            return segmentByParagraphs(script)
        case .byDuration(let seconds):
            return segmentByDuration(script, targetDuration: seconds)
        case .byParagraphs:
            return segmentByParagraphs(script)
        case .custom(let segments):
            return segments
        }
    }
    
    private func segmentByParagraphs(_ script: String) -> [ScriptSegment] {
        let paragraphs = script.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        return paragraphs.enumerated().map { index, paragraph in
            ScriptSegment(
                text: paragraph,
                name: "Scene \(index + 1)",
                stages: Set(PipelineStage.allCases),
                estimatedDuration: estimateDuration(for: paragraph)
            )
        }
    }
    
    private func segmentByDuration(_ script: String, targetDuration: TimeInterval) -> [ScriptSegment] {
        // Estimate words per second (roughly 2-3 words per second for video)
        let wordsPerSecond = 2.5
        let targetWords = Int(targetDuration * wordsPerSecond)
        
        let words = script.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var segments: [ScriptSegment] = []
        var currentWords: [String] = []
        var segmentIndex = 0
        
        for word in words {
            currentWords.append(word)
            
            if currentWords.count >= targetWords {
                let segmentText = currentWords.joined(separator: " ")
                segments.append(ScriptSegment(
                    text: segmentText,
                    name: "Segment \(segmentIndex + 1)",
                    stages: Set(PipelineStage.allCases),
                    estimatedDuration: targetDuration
                ))
                currentWords = []
                segmentIndex += 1
            }
        }
        
        // Add remaining words as final segment
        if !currentWords.isEmpty {
            let segmentText = currentWords.joined(separator: " ")
            segments.append(ScriptSegment(
                text: segmentText,
                name: "Segment \(segmentIndex + 1)",
                stages: Set(PipelineStage.allCases),
                estimatedDuration: estimateDuration(for: segmentText)
            ))
        }
        
        return segments
    }
    
    private func estimateDuration(for text: String) -> TimeInterval {
        // Estimate based on word count (roughly 2-3 words per second)
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        return max(5.0, Double(wordCount) / 2.5) // Minimum 5 seconds
    }
    
    private func mixAudioWithVideo(video videoURL: URL, audio audioURL: URL) async throws -> URL {
        // TODO: Implement actual audio mixing with AVFoundation
        // For now, return the video URL
        print("⚠️ Audio mixing not yet implemented, returning video without audio")
        return videoURL
    }
}

// Backward compatibility typealias is now in PipelineService.swift