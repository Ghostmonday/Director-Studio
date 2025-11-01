// MODULE: ThumbnailGenerator
// VERSION: 1.0.0
// PURPOSE: Multi-resolution thumbnail generation system with disk caching
// BUILD STATUS: ✅ Complete

import Foundation
import AVFoundation
import UIKit
import os.log

/// Thumbnail resolution preset
public enum ThumbnailResolution: String, CaseIterable {
    case grid = "240p"      // For grid views (240x135)
    case preview = "480p"   // For preview sheets (480x270)
    case full = "720p"      // For full-screen preview (720x405)
    
    var size: CGSize {
        switch self {
        case .grid:
            return CGSize(width: 240, height: 135)
        case .preview:
            return CGSize(width: 480, height: 270)
        case .full:
            return CGSize(width: 720, height: 405)
        }
    }
    
    var cacheDirectory: String {
        return "thumbnails_\(rawValue)"
    }
}

/// Service for generating and caching video thumbnails at multiple resolutions
public actor ThumbnailGenerator {
    static let shared = ThumbnailGenerator()
    
    private let logger = Logger(subsystem: "DirectorStudio.Thumbnails", category: "Generator")
    private let maxMemoryCacheSize = 500 * 1024 * 1024 // 500MB
    private var memoryCache: [URL: [ThumbnailResolution: UIImage]] = [:]
    private var generatingTasks: [URL: Task<[ThumbnailResolution: UIImage], Error>] = [:]
    
    private init() {}
    
    /// Generate thumbnails for a clip at all resolutions
    /// - Parameter clip: The clip to generate thumbnails for
    /// - Returns: Dictionary mapping resolution to thumbnail image
    public func generateThumbnails(for clip: GeneratedClip) async throws -> [ThumbnailResolution: UIImage] {
        guard let videoURL = clip.localURL else {
            logger.warning("Clip \(clip.id.uuidString) has no video URL")
            throw ThumbnailError.missingVideoURL
        }
        
        // Check memory cache first
        if let cached = memoryCache[videoURL] {
            logger.debug("Memory cache hit for \(videoURL.lastPathComponent)")
            return cached
        }
        
        // Check if already generating
        if let existingTask = generatingTasks[videoURL] {
            logger.debug("Reusing existing generation task for \(videoURL.lastPathComponent)")
            return try await existingTask.value
        }
        
        // Create generation task
        let task = Task<[ThumbnailResolution: UIImage], Error> {
            // Check disk cache first
            if let diskCached = try? await loadFromDiskCache(videoURL: videoURL) {
                logger.debug("Disk cache hit for \(videoURL.lastPathComponent)")
                await updateMemoryCache(videoURL: videoURL, thumbnails: diskCached)
                generatingTasks.removeValue(forKey: videoURL)
                return diskCached
            }
            
            // Generate from video
            logger.info("Generating thumbnails for \(videoURL.lastPathComponent)")
            let thumbnails = try await generateFromVideo(videoURL: videoURL)
            
            // Save to disk cache
            try? await saveToDiskCache(videoURL: videoURL, thumbnails: thumbnails)
            
            // Update memory cache
            await updateMemoryCache(videoURL: videoURL, thumbnails: thumbnails)
            
            generatingTasks.removeValue(forKey: videoURL)
            return thumbnails
        }
        
        generatingTasks[videoURL] = task
        return try await task.value
    }
    
    /// Generate thumbnail for a specific resolution
    /// - Parameters:
    ///   - clip: The clip to generate thumbnail for
    ///   - resolution: The target resolution
    /// - Returns: Thumbnail image at requested resolution
    public func generateThumbnail(for clip: GeneratedClip, resolution: ThumbnailResolution) async throws -> UIImage {
        let thumbnails = try await generateThumbnails(for: clip)
        guard let thumbnail = thumbnails[resolution] else {
            throw ThumbnailError.generationFailed
        }
        return thumbnail
    }
    
    /// Batch generate thumbnails for multiple clips
    /// - Parameter clips: Array of clips to generate thumbnails for
    /// - Returns: Dictionary mapping clip ID to thumbnails
    public func generateThumbnailsBatch(for clips: [GeneratedClip]) async -> [UUID: [ThumbnailResolution: UIImage]] {
        var results: [UUID: [ThumbnailResolution: UIImage]] = [:]
        
        await withTaskGroup(of: (UUID, [ThumbnailResolution: UIImage]?).self) { group in
            for clip in clips {
                group.addTask {
                    do {
                        let thumbnails = try await self.generateThumbnails(for: clip)
                        return (clip.id, thumbnails)
                    } catch {
                        self.logger.error("Failed to generate thumbnails for clip \(clip.id): \(error.localizedDescription)")
                        return (clip.id, nil)
                    }
                }
            }
            
            for await (clipId, thumbnails) in group {
                if let thumbnails = thumbnails {
                    results[clipId] = thumbnails
                }
            }
        }
        
        return results
    }
    
    // MARK: - Private Methods
    
    private func generateFromVideo(videoURL: URL) async throws -> [ThumbnailResolution: UIImage] {
        let asset = AVAsset(url: videoURL)
        
        // Verify asset is readable
        let isReadable = try await asset.load(.isReadable)
        guard isReadable else {
            throw ThumbnailError.unreadableAsset
        }
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        
        // Determine best frame time (1 second or first frame with content)
        let duration = try await asset.load(.duration)
        let seekTime = min(CMTime(seconds: 1.0, preferredTimescale: 600), duration)
        
        var thumbnails: [ThumbnailResolution: UIImage] = [:]
        
        // Generate at each resolution
        for resolution in ThumbnailResolution.allCases {
            generator.maximumSize = resolution.size
            
            do {
                let cgImage = try await generator.image(at: seekTime).image
                let image = UIImage(cgImage: cgImage)
                
                // Scale to exact resolution if needed
                if let scaled = await scaleImage(image, to: resolution.size) {
                    thumbnails[resolution] = scaled
                } else {
                    thumbnails[resolution] = image
                }
            } catch {
                logger.error("Failed to generate \(resolution.rawValue) thumbnail: \(error.localizedDescription)")
                // Continue with other resolutions
            }
        }
        
        guard !thumbnails.isEmpty else {
            throw ThumbnailError.generationFailed
        }
        
        return thumbnails
    }
    
    private func scaleImage(_ image: UIImage, to size: CGSize) async -> UIImage? {
        return await Task.detached {
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            defer { UIGraphicsEndImageContext() }
            
            image.draw(in: CGRect(origin: .zero, size: size))
            return UIGraphicsGetImageFromCurrentImageContext()
        }.value
    }
    
    private func updateMemoryCache(videoURL: URL, thumbnails: [ThumbnailResolution: UIImage]) {
        memoryCache[videoURL] = thumbnails
        
        // Enforce memory limit (simple LRU - remove oldest if needed)
        let estimatedSize = estimateCacheSize()
        if estimatedSize > maxMemoryCacheSize {
            // Remove oldest entries (simple approach: remove first entry)
            if let firstKey = memoryCache.keys.first {
                memoryCache.removeValue(forKey: firstKey)
            }
        }
    }
    
    private func estimateCacheSize() -> Int {
        var totalSize = 0
        for thumbnails in memoryCache.values {
            for image in thumbnails.values {
                if let cgImage = image.cgImage {
                    let bytesPerPixel = 4
                    totalSize += cgImage.width * cgImage.height * bytesPerPixel
                }
            }
        }
        return totalSize
    }
    
    // MARK: - Disk Cache
    
    private func getCacheDirectory() -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let thumbnailsDir = cacheDir.appendingPathComponent("DirectorStudio/Thumbnails", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: thumbnailsDir, withIntermediateDirectories: true)
        
        return thumbnailsDir
    }
    
    private func getCacheURL(for videoURL: URL, resolution: ThumbnailResolution) -> URL {
        let cacheDir = getCacheDirectory()
        let resolutionDir = cacheDir.appendingPathComponent(resolution.cacheDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: resolutionDir, withIntermediateDirectories: true)
        
        // Use video URL hash as filename
        let filename = "\(abs(videoURL.path.hashValue))_\(videoURL.lastPathComponent).jpg"
        return resolutionDir.appendingPathComponent(filename)
    }
    
    private func saveToDiskCache(videoURL: URL, thumbnails: [ThumbnailResolution: UIImage]) async throws {
        for (resolution, image) in thumbnails {
            let cacheURL = getCacheURL(for: videoURL, resolution: resolution)
            
            guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
                logger.error("Failed to convert thumbnail to JPEG")
                continue
            }
            
            try jpegData.write(to: cacheURL)
            logger.debug("Saved \(resolution.rawValue) thumbnail to disk: \(cacheURL.lastPathComponent)")
        }
    }
    
    private func loadFromDiskCache(videoURL: URL) async throws -> [ThumbnailResolution: UIImage]? {
        var thumbnails: [ThumbnailResolution: UIImage] = [:]
        
        for resolution in ThumbnailResolution.allCases {
            let cacheURL = getCacheURL(for: videoURL, resolution: resolution)
            
            guard FileManager.default.fileExists(atPath: cacheURL.path),
                  let data = try? Data(contentsOf: cacheURL),
                  let image = UIImage(data: data) else {
                // If any resolution is missing, consider cache incomplete
                return nil
            }
            
            thumbnails[resolution] = image
        }
        
        return thumbnails.isEmpty ? nil : thumbnails
    }
    
    /// Clear all cached thumbnails
    public func clearCache() async {
        memoryCache.removeAll()
        
        let cacheDir = getCacheDirectory()
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        
        logger.info("Cleared thumbnail cache")
    }
    
    /// Get cache size on disk
    public func getCacheSize() async -> Int64 {
        let cacheDir = getCacheDirectory()
        guard let enumerator = FileManager.default.enumerator(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = resourceValues.fileSize {
                totalSize += Int64(size)
            }
        }
        
        return totalSize
    }
}

// MARK: - Errors

enum ThumbnailError: LocalizedError {
    case missingVideoURL
    case unreadableAsset
    case generationFailed
    case invalidResolution
    
    var errorDescription: String? {
        switch self {
        case .missingVideoURL:
            return "Video URL is missing"
        case .unreadableAsset:
            return "Video asset is not readable"
        case .generationFailed:
            return "Thumbnail generation failed"
        case .invalidResolution:
            return "Invalid thumbnail resolution"
        }
    }
}

