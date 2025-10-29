// File: Repositories/ClipRepository.swift
import Foundation
import Combine

protocol ClipRepositoryProtocol: ObservableObject {
    var clips: [GeneratedClip] { get }
    var clipsPublisher: AnyPublisher<[GeneratedClip], Never> { get }
    
    func loadAll() async throws
    func save(_ clip: GeneratedClip) async throws
    func delete(_ clip: GeneratedClip) async throws
    func cleanupOrphans() async throws
}

@MainActor
class ClipRepository: ClipRepositoryProtocol {
    @Published private(set) var clips: [GeneratedClip] = []
    var clipsPublisher: AnyPublisher<[GeneratedClip], Never> {
        $clips.eraseToAnyPublisher()
    }
    
    private let storage: StorageServiceProtocol
    private var cache: [UUID: GeneratedClip] = [:]
    
    init(storage: StorageServiceProtocol = LocalStorageService()) {
        self.storage = storage
    }
    
    func loadAll() async throws {
        let loaded = try await storage.loadClips()
        let valid = loaded.filter { $0.localURL.flatMap { url in FileManager.default.fileExists(atPath: url.path) } ?? false }
        clips = valid.sorted { $0.createdAt > $1.createdAt }
        cache = Dictionary(uniqueKeysWithValues: valid.map { ($0.id, $0) })
    }
    
    func save(_ clip: GeneratedClip) async throws {
        try await storage.saveClip(clip)
        cache[clip.id] = clip
        refreshInMemory()
    }
    
    func delete(_ clip: GeneratedClip) async throws {
        try await storage.deleteClip(id: clip.id)
        cache.removeValue(forKey: clip.id)
        refreshInMemory()
    }
    
    func cleanupOrphans() async throws {
        let metadata = try await storage.loadClips()
        for clip in metadata {
            if let url = clip.localURL, !FileManager.default.fileExists(atPath: url.path) {
                try await storage.deleteClip(id: clip.id)
            }
        }
        try await loadAll()
    }
    
    private func refreshInMemory() {
        let all = cache.values.sorted { $0.createdAt > $1.createdAt }
        clips = all
    }
}
