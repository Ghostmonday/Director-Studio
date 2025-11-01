import SwiftUI
import AVKit
import UniformTypeIdentifiers

struct ClipPreviewSheet: View {
    let clip: GeneratedClip
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    @State private var isPlaying = true
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var exportProgress: Double?
    @State private var showingShareSheet = false
    @State private var showingRating = false
    @State private var rating: Int = 0
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if let player = player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showControls.toggle()
                            }
                            resetHideControlsTimer()
                        }
                } else {
                    VStack {
                        ProgressView("Loading video...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                    }
                }
                
                if showControls {
                    VStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(clip.name)
                                    .font(.system(size: fontScale(16), weight: .semibold))
                                    .foregroundColor(.white)
                                Text(formatDuration(clip.duration))
                                    .font(.system(size: fontScale(12)))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                        }
                        .padding()
                        
                        Spacer()
                        
                        VStack(spacing: 20) {
                            HStack(spacing: 40) {
                                Button(action: skipBackward) {
                                    Image(systemName: "gobackward.10")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: togglePlayPause) {
                                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                }
                                
                                Button(action: skipForward) {
                                    Image(systemName: "goforward.10")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            HStack(spacing: 30) {
                                Button(action: { showingShareSheet = true }) {
                                    VStack {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.title2)
                                        Text("Share")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white)
                                }
                                
                                Button(action: { showingRating = true }) {
                                    VStack {
                                        Image(systemName: "star.fill")
                                            .font(.title2)
                                        Text("Rate")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.bottom, 50)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [clip.localURL].compactMap { $0 })
            }
            .alert("Rate This Clip", isPresented: $showingRating) {
                ForEach(1...5, id: \.self) { star in
                    Button("\(star) Star\(star > 1 ? "s" : "")") {
                        rating = star
                        saveRating()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                setupPlayer()
                resetHideControlsTimer()
            }
        }
    }
    
    private func fontScale(_ base: CGFloat) -> CGFloat {
        let scale: Double
        switch dynamicTypeSize {
        case .xSmall: scale = 0.8
        case .small: scale = 0.9
        case .medium: scale = 1.0
        case .large: scale = 1.1
        case .xLarge: scale = 1.2
        case .xxLarge: scale = 1.3
        case .xxxLarge: scale = 1.4
        case .accessibility1: scale = 1.5
        case .accessibility2: scale = 1.6
        case .accessibility3: scale = 1.7
        case .accessibility4: scale = 1.8
        case .accessibility5: scale = 1.9
        @unknown default: scale = 1.0
        }
        return base * CGFloat(scale)
    }
    
    private func setupPlayer() {
        guard let url = clip.localURL else { return }
        player = AVPlayer(url: url)
        player?.play()
    }
    
    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    private func skipBackward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 600))
        player.seek(to: newTime)
    }
    
    private func skipForward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 600))
        player.seek(to: newTime)
    }
    
    private func resetHideControlsTimer() {
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                showControls = false
            }
        }
    }
    
    private func saveRating() {
        UserDefaults.standard.set(rating, forKey: "clip_rating_\(clip.id.uuidString)")
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [URL]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.excludedActivityTypes = [.assignToContact, .addToReadingList]
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
