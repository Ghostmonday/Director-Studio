// MARK: - ClipRepository
// File: Repositories/ClipRepository.swift
// Purpose: Repository pattern implementation for managing GeneratedClip entities with caching

import Foundation
import Combine

/// Protocol defining the interface for clip repository operations
protocol ClipRepositoryProtocol: ObservableObject {
    /// Current list of all clips, sorted by creation date (newest first)
    var clips: [GeneratedClip] { get }
    
    /// Publisher for observing changes to the clips array
    var clipsPublisher: AnyPublisher<[GeneratedClip], Never> { get }
    
    /// Loads all clips from storage and updates the in-memory cache
    func loadAll() async throws
    
    /// Saves a clip to storage and updates the cache
    /// - Parameter clip: The clip to save
    func save(_ clip: GeneratedClip) async throws
    
    /// Deletes a clip from storage and removes it from the cache
    /// - Parameter clip: The clip to delete
    func delete(_ clip: GeneratedClip) async throws
    
    /// Removes clips from storage that have metadata but missing video files
    func cleanupOrphans() async throws
}

/// Main repository implementation for managing clips with in-memory caching
@MainActor
class ClipRepository: ClipRepositoryProtocol {
    /// Published clips array, sorted by creation date (newest first)
    @Published private(set) var clips: [GeneratedClip] = []
    
    /// Publisher exposing clips changes for reactive programming
    var clipsPublisher: AnyPublisher<[GeneratedClip], Never> {
        $clips.eraseToAnyPublisher()
    }
    
    /// Storage service for persisting clips
    private let storageService: StorageServiceProtocol
    
    /// In-memory cache mapping clip IDs to clip objects for fast lookups
    private var clipCache: [UUID: GeneratedClip] = [:]
    
    /// Initialize repository with a storage service
    /// - Parameter storage: Storage service implementation (defaults to LocalStorageService)
    init(storage: StorageServiceProtocol = LocalStorageService()) {
        self.storageService = storage
    }
    
    /// Loads all clips from storage, validates file existence, and updates cache
    func loadAll() async throws {
        let loadedClips = try await storageService.loadClips()
        
        // Filter out clips whose video files no longer exist
        let validClips = loadedClips.filter { clip in
            guard let videoURL = clip.localURL else { return false }
            return FileManager.default.fileExists(atPath: videoURL.path)
        }
        
        // Sort by creation date (newest first) and update published state
        clips = validClips.sorted { $0.createdAt > $1.createdAt }
        
        // Update cache for fast lookups
        clipCache = Dictionary(uniqueKeysWithValues: validClips.map { ($0.id, $0) })
    }
    
    /// Saves a clip to storage and updates the in-memory cache
    /// - Parameter clip: The clip to save
    func save(_ clip: GeneratedClip) async throws {
        try await storageService.saveClip(clip)
        clipCache[clip.id] = clip
        refreshInMemoryView()
    }
    
    /// Deletes a clip from storage and removes it from the cache
    /// - Parameter clip: The clip to delete
    func delete(_ clip: GeneratedClip) async throws {
        try await storageService.deleteClip(id: clip.id)
        clipCache.removeValue(forKey: clip.id)
        refreshInMemoryView()
    }
    
    /// Removes orphaned clips (metadata exists but video file is missing)
    func cleanupOrphans() async throws {
        let allMetadata = try await storageService.loadClips()
        
        for clip in allMetadata {
            if let videoURL = clip.localURL,
               !FileManager.default.fileExists(atPath: videoURL.path) {
                try await storageService.deleteClip(id: clip.id)
            }
        }
        
        // Reload to refresh cache after cleanup
        try await loadAll()
    }
    
    /// Refreshes the published clips array from the cache, maintaining sort order
    private func refreshInMemoryView() {
        let sortedClips = clipCache.values.sorted { $0.createdAt > $1.createdAt }
        clips = sortedClips
    }
}
