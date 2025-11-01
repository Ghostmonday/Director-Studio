// MODULE: StorageService
// VERSION: 1.0.0
// PURPOSE: Abstract storage interface and concrete implementations

import Foundation

/// Protocol for storage backends
protocol StorageServiceProtocol {
    func saveClip(_ clip: GeneratedClip) async throws
    func loadClips() async throws -> [GeneratedClip]
    func deleteClip(id: UUID) async throws
    func saveVoiceover(_ voiceover: VoiceoverTrack) async throws
    func loadVoiceovers() async throws -> [VoiceoverTrack]
}

// MARK: - Local Storage Implementation

/// Local filesystem storage using FileManager
class LocalStorageService: StorageServiceProtocol {
    private let fileManager = FileManager.default
    private let clipsDirectory: URL
    private let voiceoversDirectory: URL
    
    init() {
        // Set up directories in Documents
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        clipsDirectory = documentsURL.appendingPathComponent("DirectorStudio/Clips", isDirectory: true)
        voiceoversDirectory = documentsURL.appendingPathComponent("DirectorStudio/Voiceovers", isDirectory: true)
        
        // Create directories if needed
        try? fileManager.createDirectory(at: clipsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: voiceoversDirectory, withIntermediateDirectories: true)
    }
    
    func saveClip(_ clip: GeneratedClip) async throws {
        let clipMetadataURL = clipsDirectory.appendingPathComponent("\(clip.id.uuidString).json")
        let encoder = JSONEncoder()
        let data = try encoder.encode(clip)
        try data.write(to: clipMetadataURL)
    }
    
    func loadClips() async throws -> [GeneratedClip] {
        let files = try fileManager.contentsOfDirectory(at: clipsDirectory, includingPropertiesForKeys: nil)
        let decoder = JSONDecoder()
        
        var clips: [GeneratedClip] = []
        for fileURL in files where fileURL.pathExtension == "json" {
            if let data = try? Data(contentsOf: fileURL),
               let clip = try? decoder.decode(GeneratedClip.self, from: data) {
                clips.append(clip)
            }
        }
        return clips
    }
    
    func deleteClip(id: UUID) async throws {
        let clipMetadataURL = clipsDirectory.appendingPathComponent("\(id.uuidString).json")
        try fileManager.removeItem(at: clipMetadataURL)
    }
    
    func saveVoiceover(_ voiceover: VoiceoverTrack) async throws {
        let voiceoverMetadataURL = voiceoversDirectory.appendingPathComponent("\(voiceover.id.uuidString).json")
        let encoder = JSONEncoder()
        let data = try encoder.encode(voiceover)
        try data.write(to: voiceoverMetadataURL)
    }
    
    func loadVoiceovers() async throws -> [VoiceoverTrack] {
        let files = try fileManager.contentsOfDirectory(at: voiceoversDirectory, includingPropertiesForKeys: nil)
        let decoder = JSONDecoder()
        
        var voiceovers: [VoiceoverTrack] = []
        for fileURL in files where fileURL.pathExtension == "json" {
            if let data = try? Data(contentsOf: fileURL),
               let voiceover = try? decoder.decode(VoiceoverTrack.self, from: data) {
                voiceovers.append(voiceover)
            }
        }
        return voiceovers
    }
}

// MARK: - iCloud Storage Implementation (Stub)

/// iCloud storage using NSUbiquitousContainer
class CloudStorageService: StorageServiceProtocol {
    func saveClip(_ clip: GeneratedClip) async throws {
        // TODO: Implement iCloud storage
        print("📤 [iCloud] Saving clip: \(clip.name)")
    }
    
    func loadClips() async throws -> [GeneratedClip] {
        // TODO: Implement iCloud retrieval
        print("📥 [iCloud] Loading clips")
        return []
    }
    
    func deleteClip(id: UUID) async throws {
        // TODO: Implement iCloud deletion
        print("🗑️ [iCloud] Deleting clip: \(id)")
    }
    
    func saveVoiceover(_ voiceover: VoiceoverTrack) async throws {
        // TODO: Implement iCloud voiceover storage
        print("📤 [iCloud] Saving voiceover: \(voiceover.name)")
    }
    
    func loadVoiceovers() async throws -> [VoiceoverTrack] {
        // TODO: Implement iCloud voiceover retrieval
        print("📥 [iCloud] Loading voiceovers")
        return []
    }
}

// MARK: - Supabase Backend Implementation (Stub)

/// Supabase backend storage
class SupabaseService: StorageServiceProtocol {
    func saveClip(_ clip: GeneratedClip) async throws {
        // TODO: Implement Supabase storage
        print("📤 [Supabase] Saving clip: \(clip.name)")
    }
    
    func loadClips() async throws -> [GeneratedClip] {
        // TODO: Implement Supabase retrieval
        print("📥 [Supabase] Loading clips")
        return []
    }
    
    func deleteClip(id: UUID) async throws {
        // TODO: Implement Supabase deletion
        print("🗑️ [Supabase] Deleting clip: \(id)")
    }
    
    func saveVoiceover(_ voiceover: VoiceoverTrack) async throws {
        // TODO: Implement Supabase voiceover storage
        print("📤 [Supabase] Saving voiceover: \(voiceover.name)")
    }
    
    func loadVoiceovers() async throws -> [VoiceoverTrack] {
        // TODO: Implement Supabase voiceover retrieval
        print("📥 [Supabase] Loading voiceovers")
        return []
    }
}

