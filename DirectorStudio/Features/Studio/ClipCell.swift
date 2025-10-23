// MODULE: ClipCell
// VERSION: 1.0.0
// PURPOSE: Grid cell displaying a generated clip with thumbnail and metadata

import SwiftUI

/// Individual clip cell in the studio grid
struct ClipCell: View {
    let clip: GeneratedClip
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail placeholder
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(16/9, contentMode: .fit)
                
                Image(systemName: "film")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                // Sync status indicator
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(syncStatusColor)
                            .frame(width: 12, height: 12)
                            .padding(8)
                    }
                    Spacer()
                }
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            
            // Clip name
            Text(clip.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
            
            // Duration
            Text(formatDuration(clip.duration))
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private var syncStatusColor: Color {
        switch clip.syncStatus {
        case .notUploaded:
            return .orange
        case .uploading:
            return .yellow
        case .synced:
            return .green
        case .failed:
            return .red
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

