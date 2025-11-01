import SwiftUI
import AVKit

struct EnhancedClipCell: View {
    let clip: GeneratedClip
    let isSelected: Bool
    var onDelete: ((GeneratedClip) -> Void)?
    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    @State private var showingMenu = false
    @State private var isHovered = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("lowDataMode") private var lowDataMode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                    .aspectRatio(16/9, contentMode: .fit)
                
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fit)
                        .clipped()
                        .cornerRadius(12)
                } else {
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
                
                VStack {
                    HStack {
                        Spacer()
                        if let syncStatus = clip.syncStatus as? SyncStatus, syncStatus == .synced {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    Spacer()
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(clip.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Label(formatDuration(clip.duration), systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if clip.isGeneratedFromImage {
                        Image(systemName: "photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contextMenu {
            Button(role: .destructive, action: {
                onDelete?(clip)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard let url = clip.localURL else {
            isLoading = false
            return
        }
        
        if let cached = ThumbnailCache.shared.getThumbnail(for: url) {
            thumbnail = cached
            isLoading = false
            return
        }
        
        Task {
            if let image = await ThumbnailCache.shared.generateThumbnail(for: url) {
                await MainActor.run {
                    thumbnail = image
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        }
        return String(format: "%ds", seconds)
    }
}
