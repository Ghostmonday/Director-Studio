// MODULE: EnhancedClipRow
// VERSION: 2.0.0
// PURPOSE: List-style clip row with thumbnail and quick actions

import SwiftUI
import AVKit

struct EnhancedClipRow: View {
    let clip: GeneratedClip
    let isSelected: Bool
    var onDelete: ((GeneratedClip) -> Void)?
    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    @State private var showingMenu = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 45)
                
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 45)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: "film")
                            .foregroundColor(.gray)
                            .font(.system(size: 20))
                    }
                }
                
                // Play overlay
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
                    .opacity(0.8)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(clip.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    // Demo badges removed - all clips are real
                }
                
                HStack(spacing: 12) {
                    // Date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(formatDate(clip.createdAt))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.caption2)
                        Text(formatDuration(clip.duration))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    // Image source indicator
                    if clip.isGeneratedFromImage {
                        Image(systemName: "photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Sync status and actions
            HStack(spacing: 16) {
                syncStatusIndicator
                
                // Quick action buttons
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
                
                Menu {
                    menuItems
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 3, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .onAppear {
            loadThumbnail()
        }
        .alert("Delete Clip?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete?(clip)
            }
        } message: {
            Text("This will permanently delete '\(clip.name)'. This action cannot be undone.")
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private var syncStatusIndicator: some View {
        Group {
            switch clip.syncStatus {
            case .notUploaded:
                Image(systemName: "icloud.slash")
                    .foregroundColor(.orange)
            case .uploading:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.7)
            case .synced:
                Image(systemName: "checkmark.icloud")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.red)
            }
        }
        .font(.system(size: 16))
    }
    
    @ViewBuilder
    private var menuItems: some View {
        Button(action: {}) {
            Label("Preview", systemImage: "play.circle")
        }
        
        Button(action: {}) {
            Label("Edit in Studio", systemImage: "wand.and.stars")
        }
        
        Divider()
        
        Button(action: {}) {
            Label("Rename", systemImage: "pencil")
        }
        
        Button(action: {}) {
            Label("Duplicate", systemImage: "doc.on.doc")
        }
        
        Button(action: {}) {
            Label("Export", systemImage: "square.and.arrow.down")
        }
        
        if clip.syncStatus == .notUploaded {
            Divider()
            Button(action: {}) {
                Label("Upload to iCloud", systemImage: "icloud.and.arrow.up")
            }
        }
        
        Divider()
        
        Button(role: .destructive, action: {
            showingDeleteConfirmation = true
        }) {
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
        imageGenerator.maximumSize = CGSize(width: 160, height: 90)
        
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
