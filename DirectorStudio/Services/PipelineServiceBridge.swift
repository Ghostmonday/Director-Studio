//
//  PipelineServiceBridge.swift
//  DirectorStudio
//
//  PURPOSE: Temporary bridge until real modules are integrated
//

import Foundation
import UIKit

/// Temporary bridge service for pipeline operations
class PipelineService {
    private let polloService = PolloAIService()
    private let deepSeekService = DeepSeekAIService()
    
    /// Generate a clip with optional reference image
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
        
        // Enhance prompt if needed (using DeepSeek)
        var enhancedPrompt = prompt
        if enabledStages.contains(.enhancement) {
            print("🔧 Enhancing prompt with DeepSeek...")
            do {
                enhancedPrompt = try await deepSeekService.enhancePrompt(
                    prompt: prompt,
                    style: .cinematic
                )
                print("✅ Enhanced prompt: \(enhancedPrompt.prefix(100))...")
            } catch {
                print("⚠️  Enhancement failed, using original prompt: \(error)")
            }
        }
        
        // Generate video
        var videoURL: URL
        
        if let imageData = referenceImageData {
            // Image-to-video generation using Pollo
            print("🖼️ Generating video from image...")
            videoURL = try await polloService.generateVideoFromImage(
                imageData: imageData,
                prompt: enhancedPrompt,
                duration: duration
            )
        } else {
            // Text-to-video generation using Pollo
            print("📝 Generating video from text...")
            videoURL = try await polloService.generateVideo(
                prompt: enhancedPrompt,
                duration: duration
            )
        }
        
        // Download video to local storage
        print("⬇️ Downloading video...")
        let localVideoURL = try await downloadVideo(from: videoURL, clipName: clipName)
        
        // Create clip
        let clip = GeneratedClip(
            name: clipName,
            localURL: localVideoURL,
            thumbnailURL: nil,
            syncStatus: .notUploaded,
            duration: duration,
            isGeneratedFromImage: referenceImageData != nil,
            isFeaturedDemo: isFeaturedDemo
        )
        
        print("✅ Generated clip: \(clipName)")
        print("   Local URL: \(localVideoURL.path)")
        print("   Enabled stages: \(enabledStages.map { $0.rawValue }.joined(separator: ", "))")
        
        return clip
    }
    
    /// Download video from remote URL to local storage
    private func downloadVideo(from remoteURL: URL, clipName: String) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: remoteURL)
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localURL = documentsURL.appendingPathComponent("DirectorStudio/Clips/\(UUID().uuidString).mp4")
        
        // Create directory if needed
        try FileManager.default.createDirectory(
            at: localURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        try data.write(to: localURL)
        
        return localURL
    }
}


