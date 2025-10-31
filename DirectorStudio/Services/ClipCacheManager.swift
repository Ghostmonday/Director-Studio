// MODULE: ClipCacheManager
// VERSION: 1.0.0
// PURPOSE: SHA256-based caching for generated video clips
// PRODUCTION-GRADE: Actor-isolated, deterministic keying, thread-safe

import Foundation
import CryptoKit

/// Actor-isolated cache manager for video clips using SHA256 fingerprinting
public actor ClipCacheManager {
    private let cacheURL: URL
    private let fileManager = FileManager.default
    
    public init() {
        let docs = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheURL = docs.appendingPathComponent("ClipCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
    }
    
    /// Generate cache key from prompt and version
    /// - Parameters:
    ///   - prompt: The ProjectPrompt
    ///   - version: The KlingVersion used
    /// - Returns: SHA256 hash string
    public func cacheKey(for prompt: ProjectPrompt, version: KlingVersion) -> String {
        let input = "\(prompt.prompt)\(version.rawValue)"
        return input.sha256
    }
    
    /// Store a video clip in cache
    /// - Parameters:
    ///   - url: Local URL of the video file
    ///   - prompt: The ProjectPrompt that generated it
    ///   - version: The KlingVersion used
    /// - Throws: File system errors
    public func store(_ url: URL, for prompt: ProjectPrompt, version: KlingVersion) async throws {
        let key = cacheKey(for: prompt, version: version)
        let dest = cacheURL.appendingPathComponent("\(key).mp4")
        
        // Remove existing file if present
        if fileManager.fileExists(atPath: dest.path) {
            try fileManager.removeItem(at: dest)
        }
        
        try fileManager.copyItem(at: url, to: dest)
    }
    
    /// Retrieve cached video clip if it exists
    /// - Parameters:
    ///   - prompt: The ProjectPrompt to check
    ///   - version: The KlingVersion used
    /// - Returns: Cached video URL if found, nil otherwise
    public func retrieve(for prompt: ProjectPrompt, version: KlingVersion) -> URL? {
        let key = cacheKey(for: prompt, version: version)
        let url = cacheURL.appendingPathComponent("\(key).mp4")
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }
    
    /// Clear all cached clips
    /// - Throws: File system errors
    public func clearCache() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
        for item in contents {
            try fileManager.removeItem(at: item)
        }
    }
    
    /// Get cache size in bytes
    /// - Returns: Total size of cached files
    public func cacheSize() throws -> Int64 {
        let contents = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey])
        return try contents.reduce(0) { total, url in
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            return total + Int64(resourceValues.fileSize ?? 0)
        }
    }
}

// MARK: - String SHA256 Extension

extension String {
    /// Compute SHA256 hash of the string
    var sha256: String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

