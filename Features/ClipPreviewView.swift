// MODULE: ClipPreviewView
// VERSION: 1.0.0
// PURPOSE: Preview view for generated video clips

import SwiftUI

struct ClipPreviewView: View {
    @ObservedObject var coordinator: Coordinator
    let clips: [ClipAsset]
    
    var body: some View {
        VStack {
            Text("Generated Clips")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
            
            if clips.isEmpty {
                Text("No clips generated yet")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(clips) { clip in
                            ClipThumbnailView(clip: clip)
                        }
                    }
                    .padding()
                }
            }
            
            Button("Back to Prompt") {
                coordinator.navigateTo(.promptInput)
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }
}

struct ClipThumbnailView: View {
    let clip: ClipAsset
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 120)
                .cornerRadius(8)
                .overlay(
                    Text("Clip Preview")
                        .foregroundColor(.secondary)
                )
            
            Text(clip.title)
                .font(.caption)
                .lineLimit(2)
        }
    }
}
