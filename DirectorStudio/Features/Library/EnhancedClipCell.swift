// MODULE: EnhancedClipCell
// VERSION: 2.0.0
// PURPOSE: Beautiful clip cell with thumbnail, animations, and metadata

import SwiftUI
import AVKit

struct EnhancedClipCell: View {
    let clip: GeneratedClip
    let isSelected: Bool
    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    @State private var showingMenu = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail with overlay
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .aspectRatio(16/9, contentMode: .fit)
                
                // Thumbnail or placeholder
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fit)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    // Loading or placeholder
                    VStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "film")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Overlays
                VStack {
                    // Top bar with badges
                    HStack {
                        // Demo badge
                        if clip.isFeaturedDemo {
                            Label("Demo", systemImage: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.9))
                                .cornerRadius(6)
                        }
                        
                        Spacer()
                        
                        // Sync status
                        syncStatusBadge
                    }
                    .padding(8)
                    
                    Spacer()
                    
                    // Bottom gradient with duration
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 40)
                        
                        HStack {
                            // Duration badge
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.caption2)
                                Text(formatDuration(clip.duration))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            
                            Spacer()
                            
                            // Play button (on hover)
                            if isHovered {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .shadow(color: .black.opacity(isHovered ? 0.15 : 0.05), radius: isHovered ? 10 : 5, y: isHovered ? 5 : 2)
            .scaleEffect(isHovered ? 1.02 : 1)
            .animation(.spring(response: 0.3), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(clip.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text(formatDate(clip.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if clip.isGeneratedFromImage {
                        Spacer()
                        Image(systemName: "photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
        .contextMenu {
            contextMenuItems
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private var syncStatusBadge: some View {
        Group {
            switch clip.syncStatus {
            case .notUploaded:
                Image(systemName: "icloud.slash")
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.orange.opacity(0.9))
                    .clipShape(Circle())
            case .uploading:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.7)
                    .frame(width: 24, height: 24)
                    .background(Color.blue.opacity(0.9))
                    .clipShape(Circle())
            case .synced:
                Image(systemName: "checkmark.icloud")
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.green.opacity(0.9))
                    .clipShape(Circle())
            case .failed:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.red.opacity(0.9))
                    .clipShape(Circle())
            }
        }
        .font(.caption)
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        Button(action: {}) {
            Label("Preview", systemImage: "play.circle")
        }
        
        Button(action: {}) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        
        Button(action: {}) {
            Label("Rename", systemImage: "pencil")
        }
        
        Divider()
        
        Button(action: {}) {
            Label("Export", systemImage: "square.and.arrow.down")
        }
        
        if clip.syncStatus == .notUploaded {
            Button(action: {}) {
                Label("Upload to iCloud", systemImage: "icloud.and.arrow.up")
            }
        }
        
        Divider()
        
        Button(role: .destructive, action: {}) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Helpers
    
    private func loadThumbnail() {
        guard thumbnail == nil else { return }
        
        Task {
            if let url = clip.localURL {
                if let thumb = await generateThumbnail(from: url) {
                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.thumbnail = thumb
                            self.isLoading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func generateThumbnail(from url: URL) async -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 320, height: 180)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Failed to generate thumbnail: \(error)")
            return nil
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
