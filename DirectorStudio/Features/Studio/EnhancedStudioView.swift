// MODULE: EnhancedStudioView
// VERSION: 1.0.0
// PURPOSE: Beautiful studio interface with drag-and-drop support

import SwiftUI
import UniformTypeIdentifiers

/// Enhanced studio view with drag-and-drop and animations
struct EnhancedStudioView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedClipID: UUID?
    @State private var draggedClip: GeneratedClip?
    @State private var showingExportOptions = false
    @State private var animateIn = false
    
    var featuredClips: [GeneratedClip] {
        coordinator.generatedClips.filter { $0.isFeaturedDemo }
    }
    
    var regularClips: [GeneratedClip] {
        coordinator.generatedClips.filter { !$0.isFeaturedDemo }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with stats
                    StudioHeaderView(clipCount: coordinator.generatedClips.count)
                        .padding(.horizontal)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -20)
                        .animation(.easeOut(duration: 0.5), value: animateIn)
                    
                    // Featured Demo Section
                    if !featuredClips.isEmpty {
                        FeaturedSection(clips: featuredClips, selectedClipID: $selectedClipID)
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: animateIn)
                    }
                    
                    // My Clips Section with drag-and-drop
                    MyClipsSection(
                        clips: regularClips,
                        selectedClipID: $selectedClipID,
                        draggedClip: $draggedClip
                    )
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animateIn)
                    
                    // Empty state
                    if coordinator.generatedClips.isEmpty {
                        EmptyStudioView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Studio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingExportOptions = true }) {
                            Label("Export All", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { /* Preview action */ }) {
                            Label("Preview Timeline", systemImage: "play.rectangle")
                        }
                        
                        Divider()
                        
                        Button(action: { /* Sort action */ }) {
                            Label("Sort by Date", systemImage: "arrow.up.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView()
        }
    }
}

/// Studio header with statistics
struct StudioHeaderView: View {
    let clipCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Studio")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                StatCard(
                    icon: "film.stack",
                    value: "\(clipCount)",
                    label: "Clips",
                    color: .blue
                )
                
                StatCard(
                    icon: "clock",
                    value: formatDuration(totalDuration),
                    label: "Total",
                    color: .green
                )
                
                StatCard(
                    icon: "star.fill",
                    value: "4.8",
                    label: "Quality",
                    color: .orange
                )
            }
        }
    }
    
    private var totalDuration: TimeInterval {
        // Calculate total duration from clips
        30.0 // Placeholder
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

/// Stat card component
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Featured section
struct FeaturedSection: View {
    let clips: [GeneratedClip]
    @Binding var selectedClipID: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("Featured Demo")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(clips) { clip in
                        FeaturedClipCard(
                            clip: clip,
                            isSelected: selectedClipID == clip.id
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedClipID = clip.id
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

/// Featured clip card
struct FeaturedClipCard: View {
    let clip: GeneratedClip
    let isSelected: Bool
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 280, height: 160)
                
                Image(systemName: "film")
                    .font(.system(size: 50))
                    .foregroundColor(.white.opacity(0.8))
                
                // Star badge
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundColor(.yellow)
                            .padding(8)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .padding(8)
                    }
                    Spacer()
                }
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(color: .black.opacity(isSelected ? 0.3 : 0.1), radius: 10, y: 5)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(clip.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(formatDuration(clip.duration))
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("Featured")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.yellow.opacity(0.2)))
                        .foregroundColor(.orange)
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

/// My clips section with drag-and-drop
struct MyClipsSection: View {
    let clips: [GeneratedClip]
    @Binding var selectedClipID: UUID?
    @Binding var draggedClip: GeneratedClip?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Clips")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if clips.isEmpty {
                // Empty state
                Button(action: { /* Navigate to prompt */ }) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Create Your First Clip")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding(.horizontal)
            } else {
                // Clip grid with drag-and-drop
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150), spacing: 16)
                ], spacing: 16) {
                    ForEach(Array(clips.enumerated()), id: \.element.id) { index, clip in
                        DraggableClipCell(
                            clip: clip,
                            isSelected: selectedClipID == clip.id,
                            index: index
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedClipID = clip.id
                            }
                        }
                        .onDrag {
                            draggedClip = clip
                            return NSItemProvider(object: clip.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: ClipDropDelegate(
                            clips: clips,
                            draggedClip: $draggedClip,
                            currentIndex: index
                        ))
                    }
                    
                    // Add new clip button
                    AddClipButton()
                }
                .padding(.horizontal)
            }
        }
    }
}

/// Draggable clip cell
struct DraggableClipCell: View {
    let clip: GeneratedClip
    let isSelected: Bool
    let index: Int
    @State private var isDragging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(16/9, contentMode: .fit)
                
                Image(systemName: "film")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
                
                // Index badge
                VStack {
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Circle().fill(Color.blue))
                            .padding(8)
                        Spacer()
                    }
                    Spacer()
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .scaleEffect(isDragging ? 0.9 : 1.0)
            .opacity(isDragging ? 0.6 : 1.0)
            
            // Info
            Text(clip.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Text(formatDuration(clip.duration))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .animation(.spring(response: 0.3), value: isDragging)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        "\(Int(duration))s"
    }
}

/// Add clip button
struct AddClipButton: View {
    var body: some View {
        NavigationLink(destination: EmptyView()) { // Replace with actual navigation
            VStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                Text("Add Clip")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundColor(.blue.opacity(0.3))
            )
        }
    }
}

/// Drop delegate for reordering clips
struct ClipDropDelegate: DropDelegate {
    let clips: [GeneratedClip]
    @Binding var draggedClip: GeneratedClip?
    let currentIndex: Int
    
    func performDrop(info: DropInfo) -> Bool {
        draggedClip = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Handle reordering logic here
    }
}

/// Empty studio state
struct EmptyStudioView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "film.stack")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No clips yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first cinematic masterpiece")
                .font(.body)
                .foregroundColor(.secondary)
            
            NavigationLink(destination: EmptyView()) { // Replace with actual navigation
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            .padding(.top)
        }
    }
}

/// Export options view
struct ExportOptionsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Export Options")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    ExportOptionButton(
                        icon: "film",
                        title: "Export as Video",
                        subtitle: "Combine all clips into one video"
                    )
                    
                    ExportOptionButton(
                        icon: "folder",
                        title: "Export Individual Clips",
                        subtitle: "Save each clip separately"
                    )
                    
                    ExportOptionButton(
                        icon: "doc.zipper",
                        title: "Export Project",
                        subtitle: "Save entire project with all assets"
                    )
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Export option button
struct ExportOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}
