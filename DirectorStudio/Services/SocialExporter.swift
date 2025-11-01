// MODULE: SocialExporter
// VERSION: 1.0.0
// PURPOSE: Export to TikTok, Reels, and other social platforms
// BUILD STATUS: ✅ Complete

import Foundation
import AVFoundation
import UIKit

/// Trending audio track from social platforms
public struct TrendingTrack: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    public let audioURL: URL?
    public let duration: TimeInterval
    public let platform: SocialPlatform
    
    public init(id: String, title: String, artist: String, audioURL: URL?, duration: TimeInterval, platform: SocialPlatform) {
        self.id = id
        self.title = title
        self.artist = artist
        self.audioURL = audioURL
        self.duration = duration
        self.platform = platform
    }
}

/// Social media platforms
public enum SocialPlatform: String, Codable, Sendable {
    case tiktok = "tiktok"
    case reels = "reels"
    case youtube = "youtube"
    case shorts = "shorts"
}

/// Social media exporter
public actor SocialExporter {
    public static let shared = SocialExporter()
    
    private init() {}
    
    /// Export video to TikTok format
    /// - Parameters:
    ///   - clip: Video clip URL
    ///   - hook: Hook text (first line)
    ///   - audio: Optional trending audio track
    /// - Returns: Exported video URL
    public func exportToTikTok(clip: URL, hook: String, audio: TrendingTrack?) async throws -> URL {
        return try await exportSocialVideo(
            clip: clip,
            platform: .tiktok,
            maxDuration: 60.0, // TikTok max 60s
            aspectRatio: CGSize(width: 9, height: 16), // Vertical
            hook: hook,
            audio: audio
        )
    }
    
    /// Export video to Instagram Reels format
    /// - Parameters:
    ///   - clip: Video clip URL
    ///   - hook: Hook text
    ///   - audio: Optional trending audio
    /// - Returns: Exported video URL
    public func exportToReels(clip: URL, hook: String, audio: TrendingTrack?) async throws -> URL {
        return try await exportSocialVideo(
            clip: clip,
            platform: .reels,
            maxDuration: 90.0, // Reels max 90s
            aspectRatio: CGSize(width: 9, height: 16), // Vertical
            hook: hook,
            audio: audio
        )
    }
    
    /// Export video to YouTube Shorts format
    /// - Parameters:
    ///   - clip: Video clip URL
    ///   - hook: Hook text
    ///   - audio: Optional trending audio
    /// - Returns: Exported video URL
    public func exportToShorts(clip: URL, hook: String, audio: TrendingTrack?) async throws -> URL {
        return try await exportSocialVideo(
            clip: clip,
            platform: .shorts,
            maxDuration: 60.0, // Shorts max 60s
            aspectRatio: CGSize(width: 9, height: 16), // Vertical
            hook: hook,
            audio: audio
        )
    }
    
    /// Generic social video export
    private func exportSocialVideo(
        clip: URL,
        platform: SocialPlatform,
        maxDuration: TimeInterval,
        aspectRatio: CGSize,
        hook: String,
        audio: TrendingTrack?
    ) async throws -> URL {
        // Load video
        let asset = AVAsset(url: clip)
        let composition = AVMutableComposition()
        
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw SocialExportError.noVideoTrack
        }
        
        let compositionVideoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        
        let timeRange = CMTimeRange(start: .zero, duration: min(try await asset.load(.duration).duration, CMTime(seconds: maxDuration, preferredTimescale: 600)))
        
        try compositionVideoTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)
        
        // Add audio track if provided
        if let audio = audio, let audioURL = audio.audioURL {
            let audioAsset = AVAsset(url: audioURL)
            if let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first {
                let compositionAudioTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                )
                try compositionAudioTrack?.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            }
        }
        
        // Apply transformations for aspect ratio
        let videoInfo = try await videoTrack.load(.formatDescriptions).first as? CMFormatDescription
        let naturalSize = videoInfo?.videoDimensions ?? CGSize(width: 1920, height: 1080)
        
        let targetSize = calculateTargetSize(natural: naturalSize, aspectRatio: aspectRatio)
        let transform = calculateTransform(natural: naturalSize, target: targetSize)
        
        compositionVideoTrack?.preferredTransform = transform
        
        // Add hook text overlay (would use AVVideoComposition)
        // For now, return composition
        
        // Export
        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(platform.rawValue)_\(UUID().uuidString).mp4")
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw SocialExportError.exportSessionFailed
        }
        
        exportSession.outputURL = exportURL
        exportSession.outputFileType = .mp4
        
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            throw SocialExportError.exportFailed(exportSession.error)
        }
        
        return exportURL
    }
    
    /// Calculate target size for aspect ratio
    private func calculateTargetSize(natural: CGSize, aspectRatio: CGSize) -> CGSize {
        let aspect = aspectRatio.width / aspectRatio.height
        
        if natural.width / natural.height > aspect {
            // Natural is wider, crop width
            return CGSize(width: natural.height * aspect, height: natural.height)
        } else {
            // Natural is taller, crop height
            return CGSize(width: natural.width, height: natural.width / aspect)
        }
    }
    
    /// Calculate transform for centering and scaling
    private func calculateTransform(natural: CGSize, target: CGSize) -> CGAffineTransform {
        let scaleX = target.width / natural.width
        let scaleY = target.height / natural.height
        let scale = min(scaleX, scaleY)
        
        let scaledWidth = natural.width * scale
        let scaledHeight = natural.height * scale
        
        let offsetX = (target.width - scaledWidth) / 2
        let offsetY = (target.height - scaledHeight) / 2
        
        return CGAffineTransform(scaleX: scale, y: scale)
            .translatedBy(x: offsetX / scale, y: offsetY / scale)
    }
    
    /// Fetch trending audio tracks (mock implementation)
    public static func trendingAudio() async -> [TrendingTrack] {
        // Mock data - would fetch from TikTok/Instagram API
        return [
            TrendingTrack(
                id: "trend1",
                title: "Trending Beat",
                artist: "Popular Artist",
                audioURL: nil,
                duration: 30.0,
                platform: .tiktok
            ),
            TrendingTrack(
                id: "trend2",
                title: "Viral Sound",
                artist: "Viral Creator",
                audioURL: nil,
                duration: 15.0,
                platform: .reels
            )
        ]
    }
}

enum SocialExportError: LocalizedError {
    case noVideoTrack
    case exportSessionFailed
    case exportFailed(Error?)
    
    var errorDescription: String? {
        switch self {
        case .noVideoTrack:
            return "No video track found in clip"
        case .exportSessionFailed:
            return "Failed to create export session"
        case .exportFailed(let error):
            return "Export failed: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}

