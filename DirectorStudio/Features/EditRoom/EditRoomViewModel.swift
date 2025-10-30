// MODULE: EditRoomViewModel
// VERSION: 1.0.0
// PURPOSE: Business logic for voiceover recording and playback

import Foundation
import AVFoundation
import Combine

/// ViewModel for EditRoomView
@MainActor
class EditRoomViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var isRecording: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 10.0 // Stub duration
    @Published var audioLevel: CGFloat = 0.5
    @Published var audioLevels: [Float] = []
    @Published var hasRecording: Bool = false
    @Published var isClipping: Bool = false
    @Published var remainingTime: TimeInterval = 0
    
    var player: AVPlayer?
    var videoURL: URL?
    
    private var clips: [GeneratedClip] = []
    private var recordedAudioURL: URL?
    private var audioLevelTimer: Timer?
    
    // MARK: - Setup
    
    func setup(clips: [GeneratedClip]) {
        self.clips = clips
        
        // Calculate total duration from all clips
        totalDuration = clips.reduce(0) { $0 + $1.duration }
        
        if totalDuration == 0 {
            totalDuration = 10.0 // Fallback
        }
        
        // Setup video player if we have clips
        if let firstClip = clips.first,
           let url = firstClip.localURL {
            videoURL = url
            let asset = AVAsset(url: url)
            player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        }
        
        // Initialize audio levels array
        audioLevels = Array(repeating: 0.5, count: 100)
        
        // Initialize remaining time
        remainingTime = totalDuration
    }
    
    func seek(to time: TimeInterval) {
        currentTime = time
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }
    
    // MARK: - Playback
    
    func togglePlayback() {
        isPlaying.toggle()
        
        if isPlaying {
            startPlaybackTimer()
        } else {
            stopPlaybackTimer()
        }
    }
    
    private func startPlaybackTimer() {
        // Simulate playback progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                self.currentTime += 0.1
                
                if self.currentTime >= self.totalDuration {
                    self.currentTime = 0
                    self.isPlaying = false
                    timer.invalidate()
                }
            }
        }
    }
    
    private func stopPlaybackTimer() {
        // Timer will be invalidated by the timer itself
    }
    
    // MARK: - Recording
    
    func startRecording() {
        isRecording = true
        hasRecording = false
        remainingTime = totalDuration
        
        // Simulate recording
        print("🎙️ Recording started")
        
        // Simulate audio level changes
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                self.audioLevel = CGFloat.random(in: 0.3...1.0)
                self.remainingTime = max(0, self.remainingTime - 0.1)
                
                if self.remainingTime <= 0 {
                    self.stopRecording()
                    timer.invalidate()
                }
            }
        }
    }
    
    func stopRecording() {
        isRecording = false
        hasRecording = true
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        
        // Create stub audio file
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordedAudioURL = documentsURL.appendingPathComponent("DirectorStudio/Voiceovers/\(UUID().uuidString).m4a")
        
        // Stub: Create empty file
        try? "stub audio data".write(to: recordedAudioURL!, atomically: true, encoding: .utf8)
        
        print("🎙️ Recording stopped: \(recordedAudioURL?.lastPathComponent ?? "unknown")")
    }
    
    // MARK: - Save
    
    func saveVoiceover(coordinator: AppCoordinator, muteVoice: Bool) {
        guard let audioURL = recordedAudioURL else { return }
        
        let voiceover = VoiceoverTrack(
            name: "Voiceover \(coordinator.currentProject?.voiceoverCount ?? 0 + 1)",
            localURL: audioURL,
            duration: totalDuration,
            syncStatus: .notUploaded
        )
        
        // Save via storage service
        Task {
            do {
                if muteVoice {
                    // Save video only (mute voiceover)
                    try await coordinator.storageService.saveVoiceover(voiceover)
                } else {
                    try await coordinator.storageService.saveVoiceover(voiceover)
                }
                coordinator.currentProject?.voiceoverCount += 1
                print("✅ Voiceover saved: \(voiceover.name)")
            } catch {
                print("❌ Failed to save voiceover: \(error.localizedDescription)")
            }
        }
    }
    
    func rePromptCurrentClip(coordinator: AppCoordinator) {
        guard !clips.isEmpty else { return }
        let clip = clips[0] // Use first clip for now
        
        Task {
            await coordinator.generateClip(prompt: clip.prompt ?? "", duration: clip.duration)
        }
    }
}

