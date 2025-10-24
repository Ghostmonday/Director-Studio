// MODULE: CloudKitStorageService
// VERSION: 1.0.0
// PURPOSE: iCloud storage implementation using CloudKit for multi-device sync

import Foundation
import CloudKit

/// iCloud storage service using CloudKit
class CloudKitStorageService: StorageServiceProtocol {
    
    private let container: CKContainer
    private let database: CKDatabase
    private let fileManager = FileManager.default
    
    // Record types
    private let clipRecordType = "GeneratedClip"
    private let voiceoverRecordType = "VoiceoverTrack"
    
    init() {
        // Use the default container (requires CloudKit capability in project)
        self.container = CKContainer.default()
        self.database = container.privateCloudDatabase
        
        print("☁️ CloudKit storage initialized")
    }
    
    // MARK: - Clip Management
    
    func saveClip(_ clip: GeneratedClip) async throws {
        print("☁️ Saving clip to iCloud: \(clip.name)")
        
        // Create CloudKit record
        let record = CKRecord(recordType: clipRecordType, recordID: CKRecord.ID(recordName: clip.id.uuidString))
        
        // Set fields
        record["name"] = clip.name
        record["createdAt"] = clip.createdAt
        record["duration"] = clip.duration
        record["projectID"] = clip.projectID?.uuidString
        record["isGeneratedFromImage"] = clip.isGeneratedFromImage ? 1 : 0
        record["isFeaturedDemo"] = clip.isFeaturedDemo ? 1 : 0
        record["syncStatus"] = clip.syncStatus.rawValue
        
        // Upload video file if available
        if let localURL = clip.localURL {
            let asset = try await uploadFile(localURL, recordID: clip.id.uuidString, fieldName: "videoFile")
            record["videoFile"] = asset
        }
        
        // Upload thumbnail if available
        if let thumbnailURL = clip.thumbnailURL {
            let asset = try await uploadFile(thumbnailURL, recordID: clip.id.uuidString, fieldName: "thumbnailFile")
            record["thumbnailFile"] = asset
        }
        
        // Save record
        do {
            let savedRecord = try await database.save(record)
            print("✅ Clip saved to iCloud: \(savedRecord.recordID.recordName)")
            
            // Update sync status locally
            var updatedClip = clip
            updatedClip.syncStatus = .uploaded
            try await saveClipMetadataLocally(updatedClip)
            
        } catch {
            print("❌ Failed to save clip to iCloud: \(error)")
            throw CloudKitError.saveFailed(error)
        }
    }
    
    func loadClips() async throws -> [GeneratedClip] {
        print("☁️ Loading clips from iCloud...")
        
        let query = CKQuery(recordType: clipRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = try await database.records(matching: query)
            var clips: [GeneratedClip] = []
            
            for (_, result) in results.matchResults {
                switch result {
                case .success(let record):
                    if let clip = try await clipFromRecord(record) {
                        clips.append(clip)
                    }
                case .failure(let error):
                    print("⚠️ Failed to fetch record: \(error)")
                }
            }
            
            print("✅ Loaded \(clips.count) clips from iCloud")
            return clips
            
        } catch {
            print("❌ Failed to load clips from iCloud: \(error)")
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    func deleteClip(id: UUID) async throws {
        print("☁️ Deleting clip from iCloud: \(id)")
        
        let recordID = CKRecord.ID(recordName: id.uuidString)
        
        do {
            try await database.deleteRecord(withID: recordID)
            print("✅ Clip deleted from iCloud")
            
            // Delete local cache
            try deleteClipMetadataLocally(id: id)
            
        } catch {
            print("❌ Failed to delete clip from iCloud: \(error)")
            throw CloudKitError.deleteFailed(error)
        }
    }
    
    // MARK: - Voiceover Management
    
    func saveVoiceover(_ voiceover: VoiceoverTrack) async throws {
        print("☁️ Saving voiceover to iCloud: \(voiceover.name)")
        
        let record = CKRecord(recordType: voiceoverRecordType, recordID: CKRecord.ID(recordName: voiceover.id.uuidString))
        
        // Set fields
        record["name"] = voiceover.name
        record["createdAt"] = voiceover.createdAt
        record["duration"] = voiceover.duration
        record["clipID"] = voiceover.clipID?.uuidString
        record["syncStatus"] = voiceover.syncStatus.rawValue
        
        // Save waveform data as binary
        if let waveformData = voiceover.waveformData {
            let data = waveformData.withUnsafeBytes { Data($0) }
            record["waveformData"] = data as CKRecordValue
        }
        
        // Upload audio file if available
        if let localURL = voiceover.localURL {
            let asset = try await uploadFile(localURL, recordID: voiceover.id.uuidString, fieldName: "audioFile")
            record["audioFile"] = asset
        }
        
        // Save record
        do {
            let savedRecord = try await database.save(record)
            print("✅ Voiceover saved to iCloud: \(savedRecord.recordID.recordName)")
            
            // Update sync status locally
            var updatedVoiceover = voiceover
            updatedVoiceover.syncStatus = .uploaded
            try await saveVoiceoverMetadataLocally(updatedVoiceover)
            
        } catch {
            print("❌ Failed to save voiceover to iCloud: \(error)")
            throw CloudKitError.saveFailed(error)
        }
    }
    
    func loadVoiceovers() async throws -> [VoiceoverTrack] {
        print("☁️ Loading voiceovers from iCloud...")
        
        let query = CKQuery(recordType: voiceoverRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = try await database.records(matching: query)
            var voiceovers: [VoiceoverTrack] = []
            
            for (_, result) in results.matchResults {
                switch result {
                case .success(let record):
                    if let voiceover = try await voiceoverFromRecord(record) {
                        voiceovers.append(voiceover)
                    }
                case .failure(let error):
                    print("⚠️ Failed to fetch voiceover record: \(error)")
                }
            }
            
            print("✅ Loaded \(voiceovers.count) voiceovers from iCloud")
            return voiceovers
            
        } catch {
            print("❌ Failed to load voiceovers from iCloud: \(error)")
            throw CloudKitError.fetchFailed(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Upload a file to CloudKit
    private func uploadFile(_ fileURL: URL, recordID: String, fieldName: String) async throws -> CKAsset {
        // Copy file to temporary location (CloudKit requires files in temp directory)
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent("\(recordID)_\(fieldName)_\(fileURL.lastPathComponent)")
        
        try fileManager.copyItem(at: fileURL, to: tempURL)
        
        return CKAsset(fileURL: tempURL)
    }
    
    /// Download a file from CloudKit
    private func downloadFile(from asset: CKAsset, to destinationURL: URL) async throws {
        guard let assetURL = asset.fileURL else {
            throw CloudKitError.noAssetURL
        }
        
        // Create destination directory if needed
        try fileManager.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        // Copy file from CloudKit cache to destination
        try fileManager.copyItem(at: assetURL, to: destinationURL)
    }
    
    /// Convert CloudKit record to GeneratedClip
    private func clipFromRecord(_ record: CKRecord) async throws -> GeneratedClip? {
        guard let name = record["name"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let duration = record["duration"] as? TimeInterval else {
            return nil
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let projectID = (record["projectID"] as? String).flatMap { UUID(uuidString: $0) }
        let isGeneratedFromImage = (record["isGeneratedFromImage"] as? Int) == 1
        let isFeaturedDemo = (record["isFeaturedDemo"] as? Int) == 1
        let syncStatus = SyncStatus(rawValue: record["syncStatus"] as? String ?? "") ?? .uploaded
        
        // Download video file if available
        var localURL: URL?
        if let videoAsset = record["videoFile"] as? CKAsset {
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let videoPath = documentsPath.appendingPathComponent("DirectorStudio/Clips/\(id.uuidString).mp4")
            try await downloadFile(from: videoAsset, to: videoPath)
            localURL = videoPath
        }
        
        // Download thumbnail if available
        var thumbnailURL: URL?
        if let thumbnailAsset = record["thumbnailFile"] as? CKAsset {
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let thumbnailPath = documentsPath.appendingPathComponent("DirectorStudio/Clips/\(id.uuidString)_thumb.jpg")
            try await downloadFile(from: thumbnailAsset, to: thumbnailPath)
            thumbnailURL = thumbnailPath
        }
        
        return GeneratedClip(
            id: id,
            name: name,
            localURL: localURL,
            thumbnailURL: thumbnailURL,
            syncStatus: syncStatus,
            createdAt: createdAt,
            duration: duration,
            projectID: projectID,
            isGeneratedFromImage: isGeneratedFromImage,
            isFeaturedDemo: isFeaturedDemo
        )
    }
    
    /// Convert CloudKit record to VoiceoverTrack
    private func voiceoverFromRecord(_ record: CKRecord) async throws -> VoiceoverTrack? {
        guard let name = record["name"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let duration = record["duration"] as? TimeInterval else {
            return nil
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let clipID = (record["clipID"] as? String).flatMap { UUID(uuidString: $0) }
        let syncStatus = SyncStatus(rawValue: record["syncStatus"] as? String ?? "") ?? .uploaded
        
        // Decode waveform data
        var waveformData: [Float]?
        if let data = record["waveformData"] as? Data {
            waveformData = data.withUnsafeBytes { bytes in
                Array(UnsafeBufferPointer<Float>(
                    start: bytes.assumingMemoryBound(to: Float.self),
                    count: data.count / MemoryLayout<Float>.size
                ))
            }
        }
        
        // Download audio file if available
        var localURL: URL?
        if let audioAsset = record["audioFile"] as? CKAsset {
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioPath = documentsPath.appendingPathComponent("DirectorStudio/Voiceovers/\(id.uuidString).m4a")
            try await downloadFile(from: audioAsset, to: audioPath)
            localURL = audioPath
        }
        
        return VoiceoverTrack(
            id: id,
            name: name,
            localURL: localURL,
            duration: duration,
            waveformData: waveformData,
            createdAt: createdAt,
            clipID: clipID,
            syncStatus: syncStatus
        )
    }
    
    /// Save clip metadata locally for offline access
    private func saveClipMetadataLocally(_ clip: GeneratedClip) throws {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let metadataPath = documentsPath.appendingPathComponent("DirectorStudio/Clips/\(clip.id.uuidString).json")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(clip)
        try data.write(to: metadataPath)
    }
    
    /// Save voiceover metadata locally for offline access
    private func saveVoiceoverMetadataLocally(_ voiceover: VoiceoverTrack) throws {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let metadataPath = documentsPath.appendingPathComponent("DirectorStudio/Voiceovers/\(voiceover.id.uuidString).json")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(voiceover)
        try data.write(to: metadataPath)
    }
    
    /// Delete clip metadata locally
    private func deleteClipMetadataLocally(id: UUID) throws {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let metadataPath = documentsPath.appendingPathComponent("DirectorStudio/Clips/\(id.uuidString).json")
        try? fileManager.removeItem(at: metadataPath)
    }
}

// MARK: - Error Types

enum CloudKitError: LocalizedError {
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case noAssetURL
    case downloadFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save to iCloud: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch from iCloud: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete from iCloud: \(error.localizedDescription)"
        case .noAssetURL:
            return "No asset URL available for download"
        case .downloadFailed(let error):
            return "Failed to download file: \(error.localizedDescription)"
        }
    }
}
