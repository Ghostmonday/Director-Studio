// MODULE: StudioView
// VERSION: 1.0.0
// PURPOSE: Main studio interface for clip management and preview

import SwiftUI

/// Studio view with clip grid and preview
struct StudioView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedClipID: UUID?
    
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
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 150), spacing: 16)
                        ], spacing: 16) {
                            ForEach(coordinator.generatedClips) { clip in
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
                        .padding()
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
        }
    }
}

