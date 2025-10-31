// MODULE: ExportService
// VERSION: 1.0.0
// PURPOSE: Handles video export with quality options and ShareSheet integration

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import AVFoundation

/// Export quality options with resolution mapping
public enum ExportQuality: String, CaseIterable {
    case economy = "720p"      // Free tier
    case standard = "1080p"   // Pro tier
    case ultra = "4K"          // Pro tier
    
    var preset: String {
        switch self {
        case .economy:
            return AVAssetExportPresetMediumQuality  // 720p
        case .standard:
            return AVAssetExportPresetHighestQuality  // 1080p
        case .ultra:
            return AVAssetExportPresetHighestQuality  // 4K (requires custom settings)
        }
    }
    
    var resolution: CGSize {
        switch self {
        case .economy:
            return CGSize(width: 1280, height: 720)
        case .standard:
            return CGSize(width: 1920, height: 1080)
        case .ultra:
            return CGSize(width: 3840, height: 2160)
        }
    }
}

/// Export format options
public enum ExportFormat: String, CaseIterable {
    case mp4 = "MP4 (H.264)"
    case mov = "MOV (H.264)"
    case prores = "ProRes 422"  // Pro only
    
    var fileExtension: String {
        switch self {
        case .mp4: return "mp4"
        case .mov: return "mov"
        case .prores: return "mov"
        }
    }
    
    var fileType: AVFileType {
        switch self {
        case .mp4: return .mp4
        case .mov: return .mov
        case .prores: return .mov
        }
    }
}

/// Service for exporting and sharing videos with watermarking and format options
class ExportService {
    private let watermarkService = WatermarkService.shared
    
    /// Export a clip with quality, format, and watermark options
    func exportClip(
        _ clip: GeneratedClip,
        quality: ExportQuality,
        format: ExportFormat,
        isProUser: Bool,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        guard let videoURL = clip.localURL else {
            completion(.failure(ExportError.noVideoURL))
            return
        }
        
        Task {
            do {
                // Create output URL
                let outputFilename = "\(clip.name)_\(quality.rawValue).\(format.fileExtension)"
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let exportsDir = documentsURL.appendingPathComponent("DirectorStudio/Exports", isDirectory: true)
                try FileManager.default.createDirectory(at: exportsDir, withIntermediateDirectories: true)
                let outputURL = exportsDir.appendingPathComponent(outputFilename)
                
                // Apply watermark if needed
                let watermarkedURL = try await watermarkService.applyWatermarkIfNeeded(
                    videoURL: videoURL,
                    isProUser: isProUser,
                    outputURL: outputURL
                )
                
                // Transcode to desired format and quality
                let finalURL = try await transcodeVideo(
                    inputURL: watermarkedURL,
                    outputURL: outputURL,
                    quality: quality,
                    format: format
                )
                
                await MainActor.run {
                    completion(.success(finalURL))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Transcode video to desired format and quality
    private func transcodeVideo(
        inputURL: URL,
        outputURL: URL,
        quality: ExportQuality,
        format: ExportFormat
    ) async throws -> URL {
        let asset = AVAsset(url: inputURL)
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: quality.preset
        ) else {
            throw ExportError.exportFailed
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = format.fileType
        
        // Configure for ProRes if needed
        if format == .prores {
            exportSession.videoComposition = createProResComposition(for: asset, quality: quality)
        }
        
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            throw ExportError.exportFailed
        }
        
        return outputURL
    }
    
    private func createProResComposition(for asset: AVAsset, quality: ExportQuality) -> AVVideoComposition? {
        let composition = AVMutableVideoComposition()
        composition.renderSize = quality.resolution
        
        // Get video track
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            return nil
        }
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = try! await CMTimeRange(start: .zero, duration: asset.load(.duration))
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]
        
        return composition
    }
    
    /// Present ShareSheet for a video URL
    #if canImport(UIKit)
    func shareVideo(url: URL, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        // For iPad
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }
        
        viewController.present(activityVC, animated: true)
    }
    #endif
    
    /// Export multiple clips stitched together
    func exportStitchedVideo(
        clips: [GeneratedClip],
        quality: ExportQuality,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        print("📤 Exporting \(clips.count) stitched clips at \(quality.rawValue)")
        
        // Stub: Create a combined filename
        let outputFilename = "DirectorStudio_Export_\(Date().timeIntervalSince1970).mp4"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsURL.appendingPathComponent("DirectorStudio/Exports/\(outputFilename)")
        
        // Create exports directory
        try? FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        // Stub: Create dummy file
        try? "stitched video data".write(to: outputURL, atomically: true, encoding: .utf8)
        
        // Simulate export delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            completion(.success(outputURL))
        }
    }
}

/// Export errors
enum ExportError: LocalizedError {
    case noVideoURL
    case exportFailed
    case insufficientStorage
    
    var errorDescription: String? {
        switch self {
        case .noVideoURL:
            return "No video URL available for export"
        case .exportFailed:
            return "Export process failed"
        case .insufficientStorage:
            return "Not enough storage space to export"
        }
    }
}

