// MODULE: ClipPreviewSheet
// VERSION: 1.0.0
// PURPOSE: Full-screen preview sheet for video clips with player controls

import SwiftUI
import AVKit

struct ClipPreviewSheet: View {
    let clip: GeneratedClip
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    @State private var isPlaying = true
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var exportProgress: Double?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Video player
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
                    // Placeholder while loading
                    VStack {
                        ProgressView("Loading video...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                    }
                }
                
                // Control overlay
                if showControls {
                    VStack {
                        // Top bar
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            // Clip info
                            VStack(alignment: .trailing) {
                                Text(clip.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(formatDuration(clip.duration))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Bottom controls
                        VStack(spacing: 20) {
                            // Play controls
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
                            
                            // Action buttons
                            HStack(spacing: 20) {
                                // Share button
                                Button(action: { showingShareSheet = true }) {
                                    VStack {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.title2)
                                        Text("Share")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 60)
                                }
                                
                                // Export button
                                Button(action: exportVideo) {
                                    VStack {
                                        if exportProgress != nil {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "square.and.arrow.down")
                                                .font(.title2)
                                        }
                                        Text("Export")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 60)
                                }
                                .disabled(exportProgress != nil)
                                
                                // Edit in Studio
                                NavigationLink(destination: PolishedStudioView()) {
                                    VStack {
                                        Image(systemName: "wand.and.stars")
                                            .font(.title2)
                                        Text("Edit")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 60)
                                }
                                
                                // Delete button
                                Button(action: {}) {
                                    VStack {
                                        Image(systemName: "trash")
                                            .font(.title2)
                                        Text("Delete")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.red)
                                    .frame(width: 60)
                                }
                            }
                            .padding(.horizontal, 40)
                            
                            // Metadata
                            HStack(spacing: 30) {
                                // Demo badges removed - all clips are real
                                
                                Label(formatDate(clip.createdAt), systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                if clip.isGeneratedFromImage {
                                    Label("From Image", systemImage: "photo")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .transition(.opacity)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                setupPlayer()
                resetHideControlsTimer()
            }
            .onDisappear {
                player?.pause()
                hideControlsTask?.cancel()
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = clip.localURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    // MARK: - Player Setup
    
    private func setupPlayer() {
        guard let url = clip.localURL else { return }
        
        player = AVPlayer(url: url)
        player?.play()
        
        // Loop the video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
    
    // MARK: - Controls
    
    private func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
        resetHideControlsTimer()
    }
    
    private func skipBackward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTime(seconds: max(0, currentTime.seconds - 10), preferredTimescale: 1)
        player.seek(to: newTime)
        resetHideControlsTimer()
    }
    
    private func skipForward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTime(seconds: currentTime.seconds + 10, preferredTimescale: 1)
        player.seek(to: newTime)
        resetHideControlsTimer()
    }
    
    private func resetHideControlsTimer() {
        hideControlsTask?.cancel()
        showControls = true
        
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if !Task.isCancelled {
                withAnimation {
                    showControls = false
                }
            }
        }
    }
    
    private func exportVideo() {
        // Export functionality would go here
        exportProgress = 0.0
        
        Task {
            // Simulate export progress
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 200_000_000)
                exportProgress = Double(i) / 10.0
            }
            exportProgress = nil
            
            // Show success message or save to photos
        }
    }
    
    // MARK: - Helpers
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
