// MODULE: VoiceoverTrack
// VERSION: 1.0.0
// PURPOSE: Represents a recorded voiceover track with timing information

import Foundation

/// A voiceover recording associated with video clips
public struct VoiceoverTrack: Identifiable, Codable {
    public let id: UUID
    var name: String
    var localURL: URL?
    var duration: TimeInterval
    var waveformData: [Float]? // Amplitude data for waveform visualization
    var createdAt: Date
    var clipID: UUID? // Associated clip if applicable
    var syncStatus: SyncStatus
    
    init(
        id: UUID = UUID(),
        name: String,
        localURL: URL? = nil,
        duration: TimeInterval = 0,
        waveformData: [Float]? = nil,
        createdAt: Date = Date(),
        clipID: UUID? = nil,
        syncStatus: SyncStatus = .notUploaded
    ) {
        self.id = id
        self.name = name
        self.localURL = localURL
        self.duration = duration
        self.waveformData = waveformData
        self.createdAt = createdAt
        self.clipID = clipID
        self.syncStatus = syncStatus
    }
}

