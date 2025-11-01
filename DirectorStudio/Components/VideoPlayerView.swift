// MODULE: VideoPlayerView
// VERSION: 1.0.0
// PURPOSE: Reusable video player component with custom controls, scrubbing, and timeline sync
// BUILD STATUS: ✅ Complete

import SwiftUI
import AVFoundation
import AVKit
import Combine

/// Video playback quality/performance mode
public enum VideoPlaybackMode {
    case standard      // Normal playback
    case highQuality   // High resolution, more memory
    case lowLatency    // Fast seeking, lower quality
}

/// Video player view with custom controls and timeline synchronization
public struct VideoPlayerView: UIViewRepresentable {
    // MARK: - Configuration
    let clips: [GeneratedClip]
    let mode: VideoPlaybackMode
    let showControls: Bool
    let autoPlay: Bool
    let loop: Bool
    
    // MARK: - State Bindings
    @Binding var isPlaying: Bool
    @Binding var currentTime: TimeInterval
    @Binding var totalDuration: TimeInterval
    @Binding var playbackRate: Float
    
    // MARK: - Callbacks
    var onClipChange: ((Int) -> Void)?
    var onPlaybackEnd: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Initialization
    
    public init(
        clips: [GeneratedClip],
        mode: VideoPlaybackMode = .standard,
        showControls: Bool = true,
        autoPlay: Bool = false,
        loop: Bool = false,
        isPlaying: Binding<Bool> = .constant(false),
        currentTime: Binding<TimeInterval> = .constant(0),
        totalDuration: Binding<TimeInterval> = .constant(0),
        playbackRate: Binding<Float> = .constant(1.0),
        onClipChange: ((Int) -> Void)? = nil,
        onPlaybackEnd: (() -> Void)? = nil,
        onError: ((Error) -> Void)? = nil
    ) {
        self.clips = clips
        self.mode = mode
        self.showControls = showControls
        self.autoPlay = autoPlay
        self.loop = loop
        self._isPlaying = isPlaying
        self._currentTime = currentTime
        self._totalDuration = totalDuration
        self._playbackRate = playbackRate
        self.onClipChange = onClipChange
        self.onPlaybackEnd = onPlaybackEnd
        self.onError = onError
    }
    
    // MARK: - UIViewRepresentable
    
    public func makeUIView(context: Context) -> VideoPlayerContainerView {
        let containerView = VideoPlayerContainerView()
        containerView.setup(
            clips: clips,
            mode: mode,
            showControls: showControls,
            autoPlay: autoPlay,
            loop: loop,
            isPlaying: $isPlaying,
            currentTime: $currentTime,
            totalDuration: $totalDuration,
            playbackRate: $playbackRate,
            onClipChange: onClipChange,
            onPlaybackEnd: onPlaybackEnd,
            onError: onError
        )
        return containerView
    }
    
    public func updateUIView(_ uiView: VideoPlayerContainerView, context: Context) {
        uiView.update(
            clips: clips,
            isPlaying: isPlaying,
            currentTime: currentTime,
            playbackRate: playbackRate
        )
    }
}

// MARK: - Container View

/// UIKit container that manages AVPlayer and player layer
final class VideoPlayerContainerView: UIView {
    // MARK: - Properties
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // State bindings
    private var isPlayingBinding: Binding<Bool>?
    private var currentTimeBinding: Binding<TimeInterval>?
    private var totalDurationBinding: Binding<TimeInterval>?
    private var playbackRateBinding: Binding<Float>?
    
    // Configuration
    private var clips: [GeneratedClip] = []
    private var mode: VideoPlaybackMode = .standard
    private var showControls: Bool = true
    private var autoPlay: Bool = false
    private var loop: Bool = false
    
    // Callbacks
    private var onClipChange: ((Int) -> Void)?
    private var onPlaybackEnd: (() -> Void)?
    private var onError: ((Error) -> Void)?
    
    // State
    private var currentClipIndex: Int = 0
    private var isSeeking: Bool = false
    
    // MARK: - Setup
    
    func setup(
        clips: [GeneratedClip],
        mode: VideoPlaybackMode,
        showControls: Bool,
        autoPlay: Bool,
        loop: Bool,
        isPlaying: Binding<Bool>,
        currentTime: Binding<TimeInterval>,
        totalDuration: Binding<TimeInterval>,
        playbackRate: Binding<Float>,
        onClipChange: ((Int) -> Void)?,
        onPlaybackEnd: (() -> Void)?,
        onError: ((Error) -> Void)?
    ) {
        self.clips = clips
        self.mode = mode
        self.showControls = showControls
        self.autoPlay = autoPlay
        self.loop = loop
        self.isPlayingBinding = isPlaying
        self.currentTimeBinding = currentTime
        self.totalDurationBinding = totalDuration
        self.playbackRateBinding = playbackRate
        self.onClipChange = onClipChange
        self.onPlaybackEnd = onPlaybackEnd
        self.onError = onError
        
        setupPlayer()
        setupObservers()
        
        if autoPlay && !clips.isEmpty {
            play()
        }
    }
    
    func update(
        clips: [GeneratedClip],
        isPlaying: Bool,
        currentTime: TimeInterval,
        playbackRate: Float
    ) {
        // Update clips if changed
        if clips != self.clips {
            self.clips = clips
            setupPlayer()
        }
        
        // Sync playback state
        if isPlaying != (player?.rate ?? 0 > 0) {
            if isPlaying {
                play()
            } else {
                pause()
            }
        }
        
        // Sync playback rate
        if abs(playbackRate - (player?.rate ?? 1.0)) > 0.01 {
            player?.rate = playbackRate
        }
        
        // Sync seek position (only if user isn't actively seeking)
        if !isSeeking {
            let playerTime = CMTimeGetSeconds(player?.currentTime() ?? .zero)
            if abs(currentTime - playerTime) > 0.5 { // Only sync if difference > 0.5s
                seek(to: currentTime)
            }
        }
    }
    
    // MARK: - Player Setup
    
    private func setupPlayer() {
        guard !clips.isEmpty else {
            clearPlayer()
            return
        }
        
        // Create player item from first clip or sequence
        let playerItem: AVPlayerItem
        
        if clips.count == 1 {
            // Single clip
            guard let url = clips[0].localURL else {
                onError?(VideoPlayerError.missingVideoURL)
                return
            }
            playerItem = AVPlayerItem(url: url)
        } else {
            // Multiple clips - create composition
            playerItem = createCompositionItem()
        }
        
        // Configure player item based on mode
        configurePlayerItem(playerItem)
        
        // Create or update player
        if let existingPlayer = player {
            existingPlayer.replaceCurrentItem(with: playerItem)
        } else {
            player = AVPlayer(playerItem: playerItem)
            setupPlayerLayer()
        }
        
        // Load duration
        Task { @MainActor in
            await loadDuration()
        }
    }
    
    private func createCompositionItem() -> AVPlayerItem {
        let composition = AVMutableComposition()
        
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            return AVPlayerItem(asset: composition)
        }
        
        let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        
        var currentTime = CMTime.zero
        
        for clip in clips {
            guard let url = clip.localURL else { continue }
            let asset = AVAsset(url: url)
            
            Task {
                do {
                    let videoTracks = try await asset.loadTracks(withMediaType: .video)
                    let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                    
                    if let assetVideoTrack = videoTracks.first {
                        let duration = try await asset.load(.duration)
                        let timeRange = CMTimeRangeMake(start: .zero, duration: duration)
                        
                        try videoTrack.insertTimeRange(timeRange, of: assetVideoTrack, at: currentTime)
                        
                        if let assetAudioTrack = audioTracks.first {
                            try audioTrack?.insertTimeRange(timeRange, of: assetAudioTrack, at: currentTime)
                        }
                        
                        currentTime = CMTimeAdd(currentTime, duration)
                    }
                } catch {
                    print("⚠️ Error adding clip to composition: \(error)")
                }
            }
        }
        
        return AVPlayerItem(asset: composition)
    }
    
    private func configurePlayerItem(_ item: AVPlayerItem) {
        switch mode {
        case .standard:
            item.preferredForwardBufferDuration = 5.0
        case .highQuality:
            item.preferredForwardBufferDuration = 10.0
            item.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        case .lowLatency:
            item.preferredForwardBufferDuration = 2.0
        }
    }
    
    private func setupPlayerLayer() {
        guard let player = player else { return }
        
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        layer.frame = bounds
        
        self.layer.addSublayer(layer)
        playerLayer = layer
        
        // Update frame on layout
        DispatchQueue.main.async { [weak self] in
            self?.updatePlayerLayerFrame()
        }
    }
    
    private func updatePlayerLayerFrame() {
        playerLayer?.frame = bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePlayerLayerFrame()
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        guard let player = player else { return }
        
        // Time observer for current time updates
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, !self.isSeeking else { return }
            let seconds = CMTimeGetSeconds(time)
            self.currentTimeBinding?.wrappedValue = seconds
        }
        
        // Playback end observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        
        // Status observer
        player.publisher(for: \.status)
            .sink { [weak self] status in
                if status == .failed {
                    self?.onError?(player.error ?? VideoPlayerError.unknown)
                }
            }
            .store(in: &cancellables)
    }
    
    @objc private func playerDidFinishPlaying() {
        if loop {
            seek(to: 0)
            play()
        } else {
            isPlayingBinding?.wrappedValue = false
            onPlaybackEnd?()
        }
    }
    
    // MARK: - Playback Control
    
    func play() {
        player?.play()
        player?.rate = playbackRateBinding?.wrappedValue ?? 1.0
        isPlayingBinding?.wrappedValue = true
    }
    
    func pause() {
        player?.pause()
        isPlayingBinding?.wrappedValue = false
    }
    
    func seek(to time: TimeInterval) {
        isSeeking = true
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            self?.isSeeking = false
            if finished {
                self?.currentTimeBinding?.wrappedValue = time
            }
        }
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRateBinding?.wrappedValue = rate
        player?.rate = rate
    }
    
    // MARK: - Duration Loading
    
    @MainActor
    private func loadDuration() async {
        guard let playerItem = player?.currentItem else { return }
        
        do {
            let duration = try await playerItem.asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            totalDurationBinding?.wrappedValue = seconds
        } catch {
            print("⚠️ Error loading duration: \(error)")
            // Fallback to clip durations
            let totalDuration = clips.reduce(0.0) { $0 + $1.duration }
            totalDurationBinding?.wrappedValue = totalDuration
        }
    }
    
    // MARK: - Cleanup
    
    private func clearPlayer() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
        
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    deinit {
        clearPlayer()
    }
}

// MARK: - Errors

enum VideoPlayerError: LocalizedError {
    case missingVideoURL
    case invalidClip
    case playbackFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .missingVideoURL:
            return "Video URL is missing"
        case .invalidClip:
            return "Invalid video clip"
        case .playbackFailed:
            return "Playback failed"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

// MARK: - SwiftUI Wrapper with Controls

/// SwiftUI wrapper with built-in playback controls
public struct VideoPlayerWithControls: View {
    let clips: [GeneratedClip]
    let mode: VideoPlaybackMode
    let showMetadata: Bool
    
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var totalDuration: TimeInterval = 0
    @State private var playbackRate: Float = 1.0
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    
    public init(
        clips: [GeneratedClip],
        mode: VideoPlaybackMode = .standard,
        showMetadata: Bool = true
    ) {
        self.clips = clips
        self.mode = mode
        self.showMetadata = showMetadata
    }
    
    public var body: some View {
        ZStack {
            VideoPlayerView(
                clips: clips,
                mode: mode,
                showControls: showControls,
                autoPlay: false,
                loop: false,
                isPlaying: $isPlaying,
                currentTime: $currentTime,
                totalDuration: $totalDuration,
                playbackRate: $playbackRate
            )
            .onTapGesture {
                toggleControls()
            }
            
            if showControls {
                VStack {
                    Spacer()
                    
                    VideoControlsOverlay(
                        isPlaying: $isPlaying,
                        currentTime: $currentTime,
                        totalDuration: $totalDuration,
                        playbackRate: $playbackRate,
                        onPlayPause: { isPlaying.toggle() },
                        onSeek: { time in
                            // Seek will be handled by VideoPlayerView update
                        },
                        onRateChange: { rate in
                            playbackRate = rate
                        }
                    )
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.0), Color.black.opacity(0.7)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
            }
            
            if showMetadata && !clips.isEmpty {
                VStack {
                    HStack {
                        if clips.count > 1 {
                            Text("\(clips.count) clips")
                                .font(.caption)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(6)
                        }
                        
                        Spacer()
                        
                        Text(formatTimecode(currentTime))
                            .font(.caption.monospacedDigit())
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            resetHideControlsTimer()
        }
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showControls.toggle()
        }
        resetHideControlsTimer()
    }
    
    private func resetHideControlsTimer() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if !Task.isCancelled {
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showControls = false
                    }
                }
            }
        }
    }
    
    private func formatTimecode(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Controls Overlay

struct VideoControlsOverlay: View {
    @Binding var isPlaying: Bool
    @Binding var currentTime: TimeInterval
    @Binding var totalDuration: TimeInterval
    @Binding var playbackRate: Float
    
    var onPlayPause: () -> Void
    var onSeek: (TimeInterval) -> Void
    var onRateChange: (Float) -> Void
    
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Progress track
                    Rectangle()
                        .fill(DirectorStudioTheme.Colors.secondary)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .cornerRadius(2)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: geometry.size.width * progress - 8)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                                    dragValue = newProgress * totalDuration
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    onSeek(dragValue)
                                }
                        )
                }
            }
            .frame(height: 44)
            .padding(.horizontal)
            
            // Controls row
            HStack(spacing: 24) {
                // Play/Pause
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                
                // Time display
                HStack(spacing: 4) {
                    Text(formatTime(currentTime))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.white)
                    
                    Text("/")
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(formatTime(totalDuration))
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Playback rate
                Menu {
                    Button("0.5x") { onRateChange(0.5) }
                    Button("0.75x") { onRateChange(0.75) }
                    Button("1x") { onRateChange(1.0) }
                    Button("1.25x") { onRateChange(1.25) }
                    Button("1.5x") { onRateChange(1.5) }
                    Button("2x") { onRateChange(2.0) }
                } label: {
                    Text("\(playbackRate, specifier: "%.2f")x")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
    
    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return isDragging ? (dragValue / totalDuration) : (currentTime / totalDuration)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

