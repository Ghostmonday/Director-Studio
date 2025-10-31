// MODULE: WatermarkService
// VERSION: 1.0.0
// PURPOSE: Apply watermarks to video exports based on user tier
// BUILD STATUS: ✅ Complete

import Foundation
import AVFoundation
import UIKit
import CoreImage

/// Service for applying watermarks to video exports
public actor WatermarkService {
    public static let shared = WatermarkService()
    
    private init() {}
    
    /// Apply watermark to video if user is not on Pro tier
    /// - Parameters:
    ///   - videoURL: Source video URL
    ///   - isProUser: Whether user has Pro tier
    ///   - outputURL: Destination URL for watermarked video
    /// - Returns: URL of watermarked video (or original if Pro user)
    public func applyWatermarkIfNeeded(
        videoURL: URL,
        isProUser: Bool,
        outputURL: URL
    ) async throws -> URL {
        // Pro users don't get watermarks
        guard !isProUser else {
            return videoURL
        }
        
        return try await applyWatermark(to: videoURL, outputURL: outputURL)
    }
    
    /// Apply watermark to video
    /// - Parameters:
    ///   - videoURL: Source video URL
    ///   - outputURL: Destination URL
    /// - Returns: URL of watermarked video
    public func applyWatermark(to videoURL: URL, outputURL: URL) async throws -> URL {
        let asset = AVAsset(url: videoURL)
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw WatermarkError.noVideoTrack
        }
        
        let composition = AVMutableComposition()
        
        // Add video track
        guard let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw WatermarkError.trackCreationFailed
        }
        
        let duration = try await asset.load(.duration)
        let timeRange = CMTimeRange(start: .zero, duration: duration)
        
        try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        
        // Create watermark layer
        let watermarkLayer = createWatermarkLayer(videoSize: try await videoTrack.load(.naturalSize))
        
        // Create video composition with watermark
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = try await videoTrack.load(.naturalSize)
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = timeRange
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        // Add watermark animation layer
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: try await videoTrack.load(.naturalSize))
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(watermarkLayer)
        
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )
        
        // Export
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw WatermarkError.exportFailed
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition
        
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            throw WatermarkError.exportFailed
        }
        
        return outputURL
    }
    
    /// Create watermark CALayer
    private func createWatermarkLayer(videoSize: CGSize) -> CALayer {
        let watermarkText = "Director Studio"
        
        // Create text layer
        let textLayer = CATextLayer()
        textLayer.string = watermarkText
        textLayer.fontSize = max(24, videoSize.width * 0.03) // Scale with video size
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.alignmentMode = .center
        textLayer.opacity = 0.6 // Semi-transparent
        
        // Position in bottom-right corner
        let textSize = (watermarkText as NSString).size(
            withAttributes: [.font: UIFont.systemFont(ofSize: textLayer.fontSize)]
        )
        let margin: CGFloat = 20
        textLayer.frame = CGRect(
            x: videoSize.width - textSize.width - margin,
            y: margin,
            width: textSize.width + 10,
            height: textSize.height + 10
        )
        
        // Add subtle background
        let backgroundLayer = CALayer()
        backgroundLayer.backgroundColor = UIColor.black.withAlphaComponent(0.3).cgColor
        backgroundLayer.frame = textLayer.frame.insetBy(dx: -5, dy: -5)
        backgroundLayer.cornerRadius = 4
        
        let containerLayer = CALayer()
        containerLayer.addSublayer(backgroundLayer)
        containerLayer.addSublayer(textLayer)
        
        return containerLayer
    }
}

// MARK: - Errors

enum WatermarkError: LocalizedError {
    case noVideoTrack
    case trackCreationFailed
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            return "Video has no video track"
        case .trackCreationFailed:
            return "Failed to create composition track"
        case .exportFailed:
            return "Failed to export watermarked video"
        }
    }
}

