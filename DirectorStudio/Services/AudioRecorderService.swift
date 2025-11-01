// MODULE: AudioRecorderService
// VERSION: 1.0.0
// PURPOSE: Voice-over recording with waveform visualization and video sync
// BUILD STATUS: ✅ Complete

import Foundation
import AVFoundation
import Combine
import os.log

/// Audio recording configuration
public struct AudioRecordingConfig {
    let sampleRate: Double = 48000
    let bitDepth: Int = 16
    let channels: Int = 1
    let format: AVAudioFormat
    
    init() {
        format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: AVAudioChannelLayout.standard(stereo: channels == 2),
            interleaved: false
        ) ?? AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: AVAudioChannelCount(channels))!
    }
}

/// Service for recording voice-overs with real-time audio metering
@MainActor
public class AudioRecorderService: ObservableObject {
    public static let shared = AudioRecorderService()
    
    // MARK: - Published Properties
    @Published public var isRecording: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var recordingDuration: TimeInterval = 0
    @Published public var audioLevel: Float = 0.0
    @Published public var waveformData: [Float] = []
    @Published public var recordingURL: URL?
    @Published public var error: Error?
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private let logger = Logger(subsystem: "DirectorStudio.Audio", category: "Recorder")
    private let config = AudioRecordingConfig()
    
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            logger.info("Audio session configured")
        } catch {
            logger.error("Failed to setup audio session: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    // MARK: - Recording Control
    
    /// Request microphone permission and start recording
    public func requestPermissionAndStartRecording(for clipID: UUID) async throws {
        // Request permission
        let permission = await AVAudioApplication.requestRecordPermission()
        guard permission else {
            throw AudioRecorderError.permissionDenied
        }
        
        try startRecording(for: clipID)
    }
    
    /// Start recording audio
    /// - Parameter clipID: Unique identifier for the clip being recorded
    public func startRecording(for clipID: UUID) throws {
        guard !isRecording else {
            logger.warning("Recording already in progress")
            return
        }
        
        // Stop any existing playback
        setupAudioSession()
        
        // Create recording URL
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let voiceoversDir = documentsURL.appendingPathComponent("DirectorStudio/Voiceovers", isDirectory: true)
        
        try FileManager.default.createDirectory(at: voiceoversDir, withIntermediateDirectories: true)
        
        let filename = "voiceover_\(clipID.uuidString)_\(Date().timeIntervalSince1970).m4a"
        let recordingURL = voiceoversDir.appendingPathComponent(filename)
        
        // Configure recorder settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: config.sampleRate,
            AVNumberOfChannelsKey: config.channels,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000
        ]
        
        // Create recorder
        audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        audioRecorder?.prepareToRecord()
        audioRecorder?.isMeteringEnabled = true
        
        guard audioRecorder?.record() == true else {
            throw AudioRecorderError.recordingFailed
        }
        
        self.recordingURL = recordingURL
        self.isRecording = true
        self.isPaused = false
        self.recordingDuration = 0
        self.waveformData = []
        self.error = nil
        
        logger.info("Recording started: \(filename)")
        
        // Start timers
        startRecordingTimer()
        startLevelMetering()
    }
    
    /// Pause recording
    public func pauseRecording() {
        guard isRecording, !isPaused else { return }
        
        audioRecorder?.pause()
        isPaused = true
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        
        logger.info("Recording paused")
    }
    
    /// Resume recording
    public func resumeRecording() {
        guard isRecording, isPaused else { return }
        
        audioRecorder?.record()
        isPaused = false
        
        startRecordingTimer()
        startLevelMetering()
        
        logger.info("Recording resumed")
    }
    
    /// Stop recording and return the audio file URL
    /// - Returns: URL to the recorded audio file
    @discardableResult
    public func stopRecording() -> URL? {
        guard isRecording else { return recordingURL }
        
        audioRecorder?.stop()
        audioRecorder = nil
        
        isRecording = false
        isPaused = false
        
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        
        recordingTimer = nil
        levelTimer = nil
        
        let url = recordingURL
        logger.info("Recording stopped: \(url?.lastPathComponent ?? "unknown")")
        
        // Reset audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        
        return url
    }
    
    /// Cancel recording and delete the file
    public func cancelRecording() {
        guard let url = recordingURL else { return }
        
        stopRecording()
        
        // Delete file
        try? FileManager.default.removeItem(at: url)
        recordingURL = nil
        
        logger.info("Recording cancelled")
    }
    
    // MARK: - Private Helpers
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.recordingDuration += 0.1
            }
        }
    }
    
    private func startLevelMetering() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let recorder = self.audioRecorder else { return }
                
                recorder.updateMeters()
                
                // Get peak power and convert to linear scale (0.0 to 1.0)
                let peakPower = recorder.peakPower(forChannel: 0)
                let linearLevel = pow(10, peakPower / 20.0) // Convert dB to linear
                
                self.audioLevel = max(0.0, min(1.0, linearLevel))
                
                // Update waveform data (keep last 200 samples for visualization)
                self.waveformData.append(self.audioLevel)
                if self.waveformData.count > 200 {
                    self.waveformData.removeFirst()
                }
            }
        }
    }
}

// MARK: - Errors

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case recordingFailed
    case invalidConfiguration
    case fileWriteFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .recordingFailed:
            return "Failed to start recording"
        case .invalidConfiguration:
            return "Invalid audio configuration"
        case .fileWriteFailed:
            return "Failed to write audio file"
        }
    }
}

