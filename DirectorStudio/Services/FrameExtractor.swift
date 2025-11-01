//
//  FrameExtractor.swift
//  DirectorStudio
//
//  Extract frames from videos for PERFECT continuity!
//

import Foundation
import AVFoundation
import UIKit

public final class FrameExtractor {
    public static let shared = FrameExtractor()
    
    private init() {}
    
    /// Extract the last frame from a video
    public func extractLastFrame(from videoURL: URL) async throws -> UIImage {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        
        // Get video duration
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        // Get last frame (minus 0.1 seconds to ensure we get a valid frame)
        let timePoint = CMTime(seconds: durationSeconds - 0.1, preferredTimescale: 600)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: timePoint, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ Failed to extract frame: \(error)")
            throw error
        }
    }
    
    /// Extract first frame (for thumbnail or continuity from previous)
    public func extractFirstFrame(from videoURL: URL) async throws -> UIImage {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let timePoint = CMTime(seconds: 0.1, preferredTimescale: 600)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: timePoint, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ Failed to extract frame: \(error)")
            throw error
        }
    }
    
    /// Save continuity frame for next generation
    public func saveContinuityFrame(_ image: UIImage, for clipId: UUID) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw FrameError.compressionFailed
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let continuityFolder = documentsPath.appendingPathComponent("ContinuityFrames")
        
        // Create folder if needed
        try FileManager.default.createDirectory(at: continuityFolder, withIntermediateDirectories: true)
        
        let frameURL = continuityFolder.appendingPathComponent("\(clipId.uuidString)_continuity.jpg")
        try data.write(to: frameURL)
        
        print("💾 Saved continuity frame: \(frameURL.lastPathComponent)")
        return frameURL
    }
    
    enum FrameError: Error {
        case compressionFailed
        case extractionFailed
    }
}

// MARK: - Continuity Manager Extension
extension ContinuityManager {
    /// NEW: Use last frame for PERFECT continuity
    public func extractContinuityFrame(from clip: GeneratedClip) async throws -> UIImage? {
        guard let videoURL = clip.localURL else { return nil }
        
        do {
            let lastFrame = try await FrameExtractor.shared.extractLastFrame(from: videoURL)
            _ = try FrameExtractor.shared.saveContinuityFrame(lastFrame, for: clip.id)
            return lastFrame
        } catch {
            print("⚠️ Couldn't extract continuity frame: \(error)")
            return nil
        }
    }
}
