import SwiftUI
import AVFoundation
import AVKit

struct EditRoomView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("lowDataMode") private var lowDataMode = false
    @StateObject private var viewModel = EditRoomViewModel()
    @StateObject var voiceoverVM = VoiceoverRecorderViewModel()
    @FocusState private var isSpaceFocused: Bool
    @State private var spaceTapCount = 0
    @State private var lastSpaceTapTime: Date = Date()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                videoPlayerSection
                    .frame(height: geometry.size.height * 0.4)
                
                scrubberSection
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                
                if !lowDataMode {
                    waveformSection
                        .frame(height: 120)
                        .padding(.horizontal, 20)
                }
                
                if viewModel.isRecording {
                    countdownBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
                
                controlsSection
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                
                rePromptSection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                Spacer()
            }
        }
        .background(adaptiveBackground)
        .navigationTitle("Voiceover")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setup(clips: coordinator.clipRepository.clips)
            if let firstClip = coordinator.clipRepository.clips.first {
                voiceoverVM.loadExisting(for: firstClip.id)
            }
        }
        .gesture(
            TapGesture(count: 3)
                .onEnded {
                    handleTripleTap()
                }
        )
        .onKeyPress(.space) {
            handleSpacePress()
            return .handled
        }
    }
    
    private func handleTripleTap() {
        if spaceTapCount >= 2 {
            viewModel.togglePlayback()
            spaceTapCount = 0
        } else {
            spaceTapCount += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                spaceTapCount = 0
            }
        }
    }
    
    private func handleSpacePress() {
        let now = Date()
        if now.timeIntervalSince(lastSpaceTapTime) < 0.5 {
            spaceTapCount += 1
        } else {
            spaceTapCount = 1
        }
        lastSpaceTapTime = now
        
        if spaceTapCount >= 3 {
            viewModel.togglePlayback()
            spaceTapCount = 0
        }
    }
    
    private var adaptiveBackground: Color {
        if UserDefaults.standard.string(forKey: "themeVariant") == "sepia" {
            return Color(red: 0.929, green: 0.894, blue: 0.827)
        }
        return colorScheme == .dark ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.949, green: 0.949, blue: 0.969)
    }
    
    private var videoPlayerSection: some View {
        ZStack {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .disabled(true)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        Image(systemName: "film")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var scrubberSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text(formatTime(viewModel.currentTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                
                Spacer()
                
                Text(formatTime(viewModel.totalDuration))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
            }
            
            VideoScrubber(
                currentTime: $viewModel.currentTime,
                duration: viewModel.totalDuration,
                isEnabled: !viewModel.isRecording,
                videoURL: viewModel.videoURL,
                colorScheme: colorScheme,
                lowDataMode: lowDataMode
            ) { time in
                viewModel.seek(to: time)
            }
        }
    }
    
    private var waveformSection: some View {
        RealWaveformView(
            audioLevels: viewModel.audioLevels,
            isRecording: viewModel.isRecording,
            currentTime: viewModel.currentTime,
            duration: viewModel.totalDuration,
            colorScheme: colorScheme,
            isClipping: viewModel.isClipping
        )
    }
    
    private var countdownBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Recording")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTime(viewModel.totalDuration - viewModel.currentTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(viewModel.remainingTime < 3 ? .red : .secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: geometry.size.width * CGFloat(viewModel.remainingTime / viewModel.totalDuration), height: 6)
                        .animation(.linear(duration: 0.1), value: viewModel.remainingTime)
                }
            }
            .frame(height: 6)
        }
    }
    
    private var controlsSection: some View {
        HStack(spacing: 40) {
            Button(action: {
                viewModel.togglePlayback()
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .disabled(viewModel.isRecording)
            
            Button(action: {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red : Color.green)
                        .frame(width: 64, height: 64)
                        .shadow(color: (viewModel.isRecording ? Color.red : Color.green).opacity(0.4), radius: 12, x: 0, y: 4)
                    
                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            
            Button(action: {
                viewModel.saveVoiceover(coordinator: coordinator, muteVoice: false)
            }) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(viewModel.hasRecording ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .white.opacity(0.3) : .black.opacity(0.3)))
            }
            .disabled(!viewModel.hasRecording)
            
            if viewModel.hasRecording {
                Menu {
                    Button(action: {
                        viewModel.saveVoiceover(coordinator: coordinator, muteVoice: true)
                    }) {
                        Label("Export Video Only (Mute Voice)", systemImage: "video.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                }
            }
        }
    }
    
    private var rePromptSection: some View {
        Button(action: {
            viewModel.rePromptCurrentClip(coordinator: coordinator)
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Regenerate This Clip")
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct VideoScrubber: View {
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    let isEnabled: Bool
    let videoURL: URL?
    let colorScheme: ColorScheme
    let lowDataMode: Bool
    let onSeek: (TimeInterval) -> Void
    
    @State private var isDragging = false
    @State private var isHovering = false
    @State private var previewTime: TimeInterval = 0
    @State private var previewFrame: UIImage?
    @State private var dragLocation: CGFloat = 0
    @State private var keyframes: [TimeInterval] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                trackBackground(geometry: geometry)
                keyframeMarkers(geometry: geometry)
                progressFill(geometry: geometry)
                scrubberHandle(geometry: geometry)
                
                if isDragging && previewFrame != nil && !lowDataMode {
                    framePreview(geometry: geometry)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value: value, geometry: geometry)
                    }
                    .onEnded { _ in
                        handleDragEnded()
                    }
            )
            .onHover { hovering in
                isHovering = hovering
            }
            .onAppear {
                loadKeyframes()
            }
        }
        .frame(height: 44)
    }
    
    private func trackBackground(geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.15))
            .frame(height: 4)
            .frame(width: geometry.size.width)
    }
    
    private func keyframeMarkers(geometry: GeometryProxy) -> some View {
        ForEach(keyframes, id: \.self) { keyframe in
            Rectangle()
                .fill(Color.blue.opacity(0.6))
                .frame(width: 2, height: 12)
                .offset(x: geometry.size.width * CGFloat(keyframe / max(duration, 0.001)) - 1, y: -4)
        }
    }
    
    private func progressFill(geometry: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(colorScheme == .dark ? Color.white : Color.blue)
            .frame(height: 4)
            .frame(width: max(0, min(geometry.size.width, geometry.size.width * CGFloat(currentTime / max(duration, 0.001)))))
    }
    
    private func scrubberHandle(geometry: GeometryProxy) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: isDragging ? 28 : (isHovering ? 24 : 20), height: isDragging ? 28 : (isHovering ? 24 : 20))
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.8), Color.blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovering || isDragging ? 2 : 0
                    )
            )
            .shadow(color: (isHovering || isDragging) ? Color.blue.opacity(0.5) : .clear, radius: isHovering ? 8 : 12, x: 0, y: 0)
            .offset(x: geometry.size.width * CGFloat(currentTime / max(duration, 0.001)) - (isDragging ? 14 : (isHovering ? 12 : 10)))
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovering)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
    }
    
    private func framePreview(geometry: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            if let frame = previewFrame {
                Image(uiImage: frame)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
            }
            
            Text(formatTime(previewTime))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.7))
                .clipShape(Capsule())
        }
        .offset(x: dragLocation - 60, y: -100)
    }
    
    private func handleDragChanged(value: DragGesture.Value, geometry: GeometryProxy) {
        guard isEnabled else { return }
        
        isDragging = true
        dragLocation = value.location.x
        let progress = max(0, min(1, value.location.x / geometry.size.width))
        var targetTime = progress * duration
        
        if let nearestKeyframe = findNearestKeyframe(to: targetTime) {
            let snapThreshold: TimeInterval = 0.5
            if abs(targetTime - nearestKeyframe) < snapThreshold {
                targetTime = nearestKeyframe
            }
        }
        
        previewTime = targetTime
        
        if !lowDataMode {
            Task {
                if let frame = await generateFrame(at: previewTime) {
                    await MainActor.run {
                        previewFrame = frame
                    }
                }
            }
        }
        
        currentTime = targetTime
    }
    
    private func handleDragEnded() {
        isDragging = false
        previewFrame = nil
        onSeek(currentTime)
    }
    
    private func findNearestKeyframe(to time: TimeInterval) -> TimeInterval? {
        guard !keyframes.isEmpty else { return nil }
        return keyframes.min(by: { abs($0 - time) < abs($1 - time) })
    }
    
    private func loadKeyframes() {
        guard let url = videoURL else { return }
        
        Task {
            await MainActor.run {
                keyframes = generateKeyframes(duration: duration)
            }
        }
    }
    
    private func generateKeyframes(duration: TimeInterval) -> [TimeInterval] {
        var frames: [TimeInterval] = []
        let interval: TimeInterval = 1.0
        var time: TimeInterval = 0
        while time < duration {
            frames.append(time)
            time += interval
        }
        return frames
    }
    
    private func generateFrame(at time: TimeInterval) async -> UIImage? {
        guard let url = videoURL else { return nil }
        
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        
        do {
            let cgImage = try await generator.image(at: CMTime(seconds: time, preferredTimescale: 600)).image
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct RealWaveformView: View {
    let audioLevels: [Float]
    let isRecording: Bool
    let currentTime: TimeInterval
    let duration: TimeInterval
    let colorScheme: ColorScheme
    let isClipping: Bool
    
    private let barCount = 60
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    bar(at: index, width: geometry.size.width / CGFloat(barCount))
                }
            }
            .frame(height: geometry.size.height)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05))
            )
        }
    }
    
    private func bar(at index: Int, width: CGFloat) -> some View {
        let level = index < audioLevels.count ? audioLevels[index] : 0.1
        let timePosition = CGFloat(index) / CGFloat(barCount) * CGFloat(duration)
        let isActive = abs(timePosition - currentTime) < 0.1
        
        return RoundedRectangle(cornerRadius: 2)
            .fill(isClipping ? Color.red : (isRecording ? Color.red : (isActive ? Color.blue : Color.gray.opacity(0.4))))
            .frame(width: max(2, width - 2))
            .frame(height: max(4, CGFloat(level) * 100))
    }
}
