// MODULE: VideoStitchingService
// VERSION: 1.0.0
// PURPOSE: Implements video stitching with AVFoundation for multi-clip productions

import Foundation
import AVFoundation
import UIKit

/// Service for stitching multiple video clips into a single output
class VideoStitchingService: VideoStitchingProtocol {
    
    /// Stitch multiple clips together with transitions
    func stitchClips(
        _ clips: [GeneratedClip],
        withTransitions transitionStyle: TransitionStyle,
        outputQuality: ExportQuality
    ) async throws -> URL {
        print("🎬 Starting video stitching...")
        print("   Clips: \(clips.count)")
        print("   Transition: \(transitionStyle.rawValue)")
        print("   Quality: \(outputQuality.rawValue)")
        
        // Validate input
        guard !clips.isEmpty else {
            throw VideoStitchingError.noClips
        }
        
        // Create composition
        let composition = AVMutableComposition()
        
        // Create video and audio tracks
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw VideoStitchingError.trackCreationFailed
        }
        
        let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        
        // Track timing
        var currentTime = CMTime.zero
        var videoAssets: [(asset: AVAsset, timeRange: CMTimeRange)] = []
        
        // Process each clip
        for (index, clip) in clips.enumerated() {
            guard let clipURL = clip.localURL else {
                print("⚠️ Skipping clip without local URL: \(clip.name)")
                continue
            }
            
            print("📎 Processing clip \(index + 1): \(clip.name)")
            
            let asset = AVAsset(url: clipURL)
            
            // Check if asset is readable
            guard asset.isReadable else {
                print("⚠️ Asset not readable: \(clipURL)")
                continue
            }
            
            // Get video and audio tracks from asset
            let assetVideoTracks = try await asset.loadTracks(withMediaType: .video)
            let assetAudioTracks = try await asset.loadTracks(withMediaType: .audio)
            
            guard let assetVideoTrack = assetVideoTracks.first else {
                print("⚠️ No video track in asset: \(clipURL)")
                continue
            }
            
            // Calculate time range
            let duration = try await asset.load(.duration)
            let timeRange = CMTimeRangeMake(start: .zero, duration: duration)
            
            // Insert video track
            do {
                try videoTrack.insertTimeRange(
                    timeRange,
                    of: assetVideoTrack,
                    at: currentTime
                )
                
                // Insert audio track if available
                if let assetAudioTrack = assetAudioTracks.first {
                    try audioTrack?.insertTimeRange(
                        timeRange,
                        of: assetAudioTrack,
                        at: currentTime
                    )
                }
                
                // Store for transitions
                let insertedRange = CMTimeRangeMake(start: currentTime, duration: duration)
                videoAssets.append((asset: asset, timeRange: insertedRange))
                
                // Update current time
                currentTime = CMTimeAdd(currentTime, duration)
                
                print("✅ Added clip at \(CMTimeGetSeconds(insertedRange.start))s - \(CMTimeGetSeconds(insertedRange.end))s")
                
            } catch {
                print("❌ Failed to insert clip: \(error)")
                throw VideoStitchingError.compositionFailed(error)
            }
        }
        
        // Apply transitions if requested and we have multiple clips
        let videoComposition: AVVideoComposition?
        if videoAssets.count > 1 && transitionStyle != .cut {
            videoComposition = try createVideoComposition(
                for: composition,
                videoAssets: videoAssets,
                transitionStyle: transitionStyle
            )
        } else {
            videoComposition = nil
        }
        
        // Export the composition
        let outputURL = try await exportComposition(
            composition,
            videoComposition: videoComposition,
            quality: outputQuality
        )
        
        print("✅ Video stitching complete: \(outputURL.lastPathComponent)")
        return outputURL
    }
    
    // MARK: - Private Methods
    
    /// Create video composition with transitions
    private func createVideoComposition(
        for composition: AVComposition,
        videoAssets: [(asset: AVAsset, timeRange: CMTimeRange)],
        transitionStyle: TransitionStyle
    ) throws -> AVVideoComposition {
        print("🎨 Creating video composition with \(transitionStyle.rawValue) transitions...")
        
        // Get the first video track to determine render size
        guard let videoTrack = composition.tracks(withMediaType: .video).first else {
            throw VideoStitchingError.noVideoTrack
        }
        
        // Create composition instructions
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(
            start: .zero,
            duration: composition.duration
        )
        
        // Create layer instructions for each clip
        var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        
        for (index, (_, timeRange)) in videoAssets.enumerated() {
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            
            // Apply transition if not the first clip
            if index > 0 {
                let transitionDuration = CMTimeMakeWithSeconds(
                    transitionStyle.duration,
                    preferredTimescale: 600
                )
                
                let fadeInStart = CMTimeSubtract(timeRange.start, transitionDuration)
                let fadeInEnd = timeRange.start
                
                switch transitionStyle {
                case .fadeIn, .crossfade:
                    // Fade in from transparent to opaque
                    layerInstruction.setOpacityRamp(
                        fromStartOpacity: 0.0,
                        toEndOpacity: 1.0,
                        timeRange: CMTimeRangeMake(start: fadeInStart, duration: transitionDuration)
                    )
                    
                case .dissolve:
                    // Similar to crossfade but with different timing
                    layerInstruction.setOpacityRamp(
                        fromStartOpacity: 0.0,
                        toEndOpacity: 1.0,
                        timeRange: CMTimeRangeMake(start: fadeInStart, duration: transitionDuration)
                    )
                    
                default:
                    break
                }
            }
            
            // Apply fade out for the previous clip if using crossfade
            if index < videoAssets.count - 1 && transitionStyle == .crossfade {
                let nextTimeRange = videoAssets[index + 1].timeRange
                let transitionDuration = CMTimeMakeWithSeconds(
                    transitionStyle.duration,
                    preferredTimescale: 600
                )
                
                let fadeOutStart = CMTimeSubtract(nextTimeRange.start, transitionDuration)
                let fadeOutEnd = nextTimeRange.start
                
                layerInstruction.setOpacityRamp(
                    fromStartOpacity: 1.0,
                    toEndOpacity: 0.0,
                    timeRange: CMTimeRangeMake(start: fadeOutStart, duration: transitionDuration)
                )
            }
            
            layerInstructions.append(layerInstruction)
        }
        
        instruction.layerInstructions = layerInstructions
        
        // Create video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30) // 30 fps
        
        // Set render size (1920x1080 for HD)
        videoComposition.renderSize = CGSize(width: 1920, height: 1080)
        
        print("✅ Created video composition with \(layerInstructions.count) layer instructions")
        
        return videoComposition
    }
    
    /// Export the composition to a file
    private func exportComposition(
        _ composition: AVComposition,
        videoComposition: AVVideoComposition?,
        quality: ExportQuality
    ) async throws -> URL {
        print("📤 Exporting composition...")
        
        // Create output URL
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportDirectory = documentsPath.appendingPathComponent("DirectorStudio/Exports", isDirectory: true)
        
        // Create directory if needed
        try FileManager.default.createDirectory(
            at: exportDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let outputFilename = "DirectorStudio_Stitched_\(Date().timeIntervalSince1970).mp4"
        let outputURL = exportDirectory.appendingPathComponent(outputFilename)
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: outputURL)
        
        // Create export session
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: quality.preset
        ) else {
            throw VideoStitchingError.exportSessionCreationFailed
        }
        
        // Configure export session
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = true
        
        // Track progress
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            print("📊 Export progress: \(Int(exportSession.progress * 100))%")
        }
        
        // Export
        await exportSession.export()
        progressTimer.invalidate()
        
        // Check result
        switch exportSession.status {
        case .completed:
            print("✅ Export completed successfully")
            return outputURL
            
        case .failed:
            let error = exportSession.error ?? VideoStitchingError.unknownExportError
            print("❌ Export failed: \(error)")
            throw VideoStitchingError.exportFailed(error)
            
        case .cancelled:
            print("❌ Export cancelled")
            throw VideoStitchingError.exportCancelled
            
        default:
            print("❌ Unexpected export status: \(exportSession.status.rawValue)")
            throw VideoStitchingError.unexpectedExportStatus
        }
    }
}

// MARK: - Error Types

enum VideoStitchingError: LocalizedError {
    case noClips
    case trackCreationFailed
    case noVideoTrack
    case compositionFailed(Error)
    case exportSessionCreationFailed
    case exportFailed(Error)
    case exportCancelled
    case unknownExportError
    case unexpectedExportStatus
    
    var errorDescription: String? {
        switch self {
        case .noClips:
            return "No clips provided for stitching"
        case .trackCreationFailed:
            return "Failed to create composition tracks"
        case .noVideoTrack:
            return "No video track found in composition"
        case .compositionFailed(let error):
            return "Failed to create composition: \(error.localizedDescription)"
        case .exportSessionCreationFailed:
            return "Failed to create export session"
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        case .exportCancelled:
            return "Export was cancelled"
        case .unknownExportError:
            return "Unknown export error occurred"
        case .unexpectedExportStatus:
            return "Export finished with unexpected status"
        }
    }
}
