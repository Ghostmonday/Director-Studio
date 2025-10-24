// MODULE: StudioView
// VERSION: 1.1.0
// PURPOSE: Main studio interface for clip management and preview with auto-play

import SwiftUI
import AVKit

/// Studio view with clip grid and preview
struct StudioView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedClipID: UUID?
    @State private var hasAutoPlayed = false
    @State private var showVideoPlayer = false
    @AppStorage("isFirstLaunch") private var isFirstLaunch = true
    
    var featuredClips: [GeneratedClip] {
        coordinator.generatedClips.filter { $0.isFeaturedDemo }
    }
    
    var regularClips: [GeneratedClip] {
        coordinator.generatedClips.filter { !$0.isFeaturedDemo }
    }
    
    var selectedClip: GeneratedClip? {
        coordinator.generatedClips.first { $0.id == selectedClipID }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if coordinator.generatedClips.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No clips yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Generate your first clip in the Prompt tab")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    // Clip grid
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Featured Demo Section
                            if !featuredClips.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "star.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.yellow)
                                        Text("Featured Demo")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    
                                    Text("DirectorStudio promotional video")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.adaptive(minimum: 150), spacing: 16)
                                    ], spacing: 16) {
                                        ForEach(featuredClips) { clip in
                                            ClipCell(clip: clip, isSelected: selectedClipID == clip.id, isFeatured: true)
                                                .onTapGesture {
                                                    selectedClipID = clip.id
                                                }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.vertical)
                                
                                Divider()
                            }
                            
                            // Regular Clips Section
                            if !regularClips.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("My Clips")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.adaptive(minimum: 150), spacing: 16)
                                    ], spacing: 16) {
                                        ForEach(regularClips) { clip in
                                            ClipCell(clip: clip, isSelected: selectedClipID == clip.id)
                                                .onTapGesture {
                                                    selectedClipID = clip.id
                                                }
                                        }
                                        
                                        // Add new clip button
                                        Button(action: {
                                            coordinator.navigateTo(.prompt)
                                        }) {
                                            VStack {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 50))
                                                    .foregroundColor(.blue)
                                                Text("Add Clip")
                                                    .font(.caption)
                                            }
                                            .frame(height: 120)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(10)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            } else if featuredClips.isEmpty {
                                // Add new clip button (when no clips at all)
                                Button(action: {
                                    coordinator.navigateTo(.prompt)
                                }) {
                                    VStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.blue)
                                        Text("Add Clip")
                                            .font(.caption)
                                    }
                                    .frame(height: 120)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                }
                                .padding()
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            // TODO: Preview all clips stitched together
                            print("Preview all clips")
                        }) {
                            Label("Preview All", systemImage: "play.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        NavigationLink(destination: EditRoomView()) {
                            Label("Record Voiceover", systemImage: "mic.circle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Studio")
            .onAppear {
                autoPlayFeaturedDemo()
            }
            .sheet(isPresented: $showVideoPlayer) {
                if let clip = selectedClip {
                    VideoPlayerSheet(clip: clip, isPresented: $showVideoPlayer)
                }
            }
        }
    }
    
    private func autoPlayFeaturedDemo() {
        // Auto-play featured demo on first launch ONLY if video already exists
        // NEVER auto-generate videos (that would use API credits!)
        if isFirstLaunch && !hasAutoPlayed && !featuredClips.isEmpty {
            hasAutoPlayed = true
            
            // Only play if the video file actually exists
            if let firstFeatured = featuredClips.first,
               let localURL = firstFeatured.localURL,
               FileManager.default.fileExists(atPath: localURL.path) {
                
                // Small delay for better UX
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    selectedClipID = firstFeatured.id
                    showVideoPlayer = true
                    
                    // Mark first launch as complete
                    isFirstLaunch = false
                }
            }
        }
    }
}

// MARK: - Video Player Sheet

struct VideoPlayerSheet: View {
    let clip: GeneratedClip
    @Binding var isPresented: Bool
    @State private var player: AVPlayer?
    
    var body: some View {
        NavigationView {
            VStack {
                if let player = player {
                    VideoPlayer(player: player)
                        .onAppear {
                            player.play()
                        }
                        .onDisappear {
                            player.pause()
                        }
                } else {
                    ProgressView("Loading video...")
                        .padding()
                }
                
                // Video info
                VStack(alignment: .leading, spacing: 8) {
                    Text(clip.name)
                        .font(.headline)
                    
                    HStack {
                        Label("\(Int(clip.duration))s", systemImage: "timer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if clip.isFeaturedDemo {
                            Label("Featured Demo", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationTitle("Video Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            loadVideo()
        }
    }
    
    private func loadVideo() {
        if let localURL = clip.localURL {
            player = AVPlayer(url: localURL)
        }
    }
}

