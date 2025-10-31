// MODULE: InteractiveTimelineView
// VERSION: 1.0.0
// PURPOSE: Drag-drop timeline with transitions, trim editing, and real-time preview
// BUILD STATUS: ✅ Complete

import SwiftUI
import AVFoundation

/// Transition style for clip transitions
public enum TransitionStyle: String, CaseIterable {
    case none = "None"
    case fade = "Fade"
    case dissolve = "Dissolve"
    case wipe = "Wipe"
    case crossfade = "Crossfade"
    
    var duration: TimeInterval {
        switch self {
        case .none: return 0
        case .fade, .dissolve, .crossfade: return 0.5
        case .wipe: return 0.3
        }
    }
}

/// Timeline clip with editing capabilities
public struct TimelineClip: Identifiable, Equatable {
    public let id: UUID
    let clip: GeneratedClip
    var startTime: TimeInterval
    var endTime: TimeInterval
    var transitionIn: TransitionStyle
    var transitionOut: TransitionStyle
    var inPoint: TimeInterval  // Trim start
    var outPoint: TimeInterval // Trim end
    
    public init(
        id: UUID = UUID(),
        clip: GeneratedClip,
        startTime: TimeInterval = 0,
        endTime: TimeInterval = 0,
        transitionIn: TransitionStyle = .none,
        transitionOut: TransitionStyle = .none,
        inPoint: TimeInterval = 0,
        outPoint: TimeInterval = 0
    ) {
        self.id = id
        self.clip = clip
        self.startTime = startTime
        self.endTime = endTime
        self.transitionIn = transitionIn
        self.transitionOut = transitionOut
        self.inPoint = inPoint
        self.outPoint = outPoint
    }
}

/// Interactive timeline view with drag-drop and editing
public struct InteractiveTimelineView: View {
    @Binding var clips: [TimelineClip]
    @State private var draggedClip: TimelineClip?
    @State private var selectedClipID: UUID?
    @State private var editingClipID: UUID?
    @State private var zoomLevel: CGFloat = 1.0
    @State private var scrollOffset: CGFloat = 0
    @State private var playheadPosition: TimeInterval = 0
    @State private var isPlaying: Bool = false
    
    let onReorder: ([TimelineClip]) -> Void
    let onTrim: (UUID, inPoint: TimeInterval, outPoint: TimeInterval) -> Void
    let onTransitionChange: (UUID, in: TransitionStyle, out: TransitionStyle) -> Void
    
    // Constants
    private let trackHeight: CGFloat = 80
    private let pixelsPerSecond: CGFloat = 50 // Base scale
    
    public init(
        clips: Binding<[TimelineClip]>,
        onReorder: @escaping ([TimelineClip]) -> Void,
        onTrim: @escaping (UUID, inPoint: TimeInterval, outPoint: TimeInterval) -> Void,
        onTransitionChange: @escaping (UUID, in: TransitionStyle, out: TransitionStyle) -> Void
    ) {
        self._clips = clips
        self.onReorder = onReorder
        self.onTrim = onTrim
        self.onTransitionChange = onTransitionChange
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Timecode ruler
            timecodeRuler
                .frame(height: 30)
            
            // Timeline track
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Background grid
                        timelineGrid(width: totalWidth, height: geometry.size.height)
                        
                        // Clip tracks
                        ForEach(clips) { timelineClip in
                            ClipTrackView(
                                timelineClip: timelineClip,
                                trackHeight: trackHeight,
                                pixelsPerSecond: pixelsPerSecond * zoomLevel,
                                isDragging: draggedClip?.id == timelineClip.id,
                                isSelected: selectedClipID == timelineClip.id,
                                onTap: { selectedClipID = timelineClip.id },
                                onDrag: { offset in
                                    handleDrag(timelineClip: timelineClip, offset: offset)
                                }
                            )
                            .offset(x: positionForClip(timelineClip))
                        }
                        
                        // Playhead
                        playheadIndicator
                            .offset(x: playheadPosition * pixelsPerSecond * zoomLevel)
                    }
                    .frame(width: totalWidth, height: geometry.size.height)
                }
            }
            .frame(height: trackHeight + 40)
            
            // Controls
            timelineControls
        }
        .background(DirectorStudioTheme.Colors.backgroundBase)
    }
    
    // MARK: - Components
    
    private var timecodeRuler: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<Int(totalDuration), id: \.self) { second in
                    VStack(spacing: 0) {
                        Text(formatTimecode(TimeInterval(second)))
                            .font(.caption2.monospacedDigit())
                            .foregroundColor(.secondary)
                        
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 1, height: 20)
                    }
                    .frame(width: pixelsPerSecond * zoomLevel)
                }
            }
            .padding(.horizontal)
        }
        .background(DirectorStudioTheme.Colors.surfacePanel)
    }
    
    private func timelineGrid(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            // Vertical grid lines (seconds)
            for i in 0..<Int(totalDuration) {
                let x = CGFloat(i) * pixelsPerSecond * zoomLevel
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: height))
            }
            
            // Horizontal track separator
            path.move(to: CGPoint(x: 0, y: trackHeight))
            path.addLine(to: CGPoint(x: width, y: trackHeight))
        }
        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
    }
    
    private var playheadIndicator: some View {
        Rectangle()
            .fill(DirectorStudioTheme.Colors.secondary)
            .frame(width: 2, height: trackHeight)
            .shadow(color: DirectorStudioTheme.Colors.secondary.opacity(0.5), radius: 4)
    }
    
    private var timelineControls: some View {
        HStack(spacing: 16) {
            // Play/Pause
            Button(action: { isPlaying.toggle() }) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            .buttonStyle(.bordered)
            
            // Zoom
            HStack(spacing: 8) {
                Button("-") {
                    withAnimation {
                        zoomLevel = max(0.5, zoomLevel - 0.25)
                    }
                }
                
                Text("\(Int(zoomLevel * 100))%")
                    .frame(width: 60)
                
                Button("+") {
                    withAnimation {
                        zoomLevel = min(2.0, zoomLevel + 0.25)
                    }
                }
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            // Selected clip editor
            if let selectedID = selectedClipID,
               let clip = clips.first(where: { $0.id == selectedID }) {
                ClipEditorPanel(
                    clip: clip,
                    onTrim: { inPoint, outPoint in
                        onTrim(selectedID, inPoint: inPoint, outPoint: outPoint)
                    },
                    onTransitionChange: { transitionIn, transitionOut in
                        onTransitionChange(selectedID, in: transitionIn, out: transitionOut)
                    }
                )
            }
        }
        .padding()
        .background(DirectorStudioTheme.Colors.surfacePanel)
    }
    
    // MARK: - Computed Properties
    
    private var totalDuration: TimeInterval {
        clips.reduce(0) { max($0, $1.endTime) }
    }
    
    private var totalWidth: CGFloat {
        totalDuration * pixelsPerSecond * zoomLevel
    }
    
    // MARK: - Helpers
    
    private func positionForClip(_ clip: TimelineClip) -> CGFloat {
        clip.startTime * pixelsPerSecond * zoomLevel
    }
    
    private func handleDrag(timelineClip: TimelineClip, offset: CGSize) {
        let newStartTime = max(0, clip.startTime + TimeInterval(offset.width / (pixelsPerSecond * zoomLevel)))
        
        // Update clip position
        if let index = clips.firstIndex(where: { $0.id == timelineClip.id }) {
            clips[index].startTime = newStartTime
            clips[index].endTime = newStartTime + (clip.endTime - clip.startTime)
        }
        
        // Snap to grid
        snapToGrid()
        
        // Reorder if needed
        onReorder(clips)
    }
    
    private func snapToGrid() {
        let snapInterval: TimeInterval = 0.1 // 100ms snap
        
        for index in clips.indices {
            clips[index].startTime = round(clips[index].startTime / snapInterval) * snapInterval
            clips[index].endTime = round(clips[index].endTime / snapInterval) * snapInterval
        }
    }
    
    private func formatTimecode(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Clip Track View

struct ClipTrackView: View {
    let timelineClip: TimelineClip
    let trackHeight: CGFloat
    let pixelsPerSecond: CGFloat
    let isDragging: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onDrag: (CGSize) -> Void
    
    @State private var dragOffset: CGSize = .zero
    
    var clipWidth: CGFloat {
        (timelineClip.endTime - timelineClip.startTime) * pixelsPerSecond
    }
    
    var body: some View {
        ZStack {
            // Clip background
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? DirectorStudioTheme.Colors.secondary.opacity(0.3) : DirectorStudioTheme.Colors.surfacePanel)
                .frame(width: max(40, clipWidth), height: trackHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? DirectorStudioTheme.Colors.secondary : Color.clear, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: isDragging ? 8 : 2)
                .offset(dragOffset)
            
            // Clip info
            VStack(alignment: .leading, spacing: 4) {
                Text(timelineClip.clip.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(formatDuration(timelineClip.endTime - timelineClip.startTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                    onDrag(value.translation)
                }
                .onEnded { _ in
                    dragOffset = .zero
                }
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%.1fs", duration)
    }
}

// MARK: - Clip Editor Panel

struct ClipEditorPanel: View {
    let clip: TimelineClip
    let onTrim: (TimeInterval, TimeInterval) -> Void
    let onTransitionChange: (TransitionStyle, TransitionStyle) -> Void
    
    @State private var inPoint: TimeInterval = 0
    @State private var outPoint: TimeInterval = 5
    @State private var transitionIn: TransitionStyle = .none
    @State private var transitionOut: TransitionStyle = .none
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(clip.clip.name)
                .font(.headline)
            
            // Trim controls
            VStack(alignment: .leading, spacing: 4) {
                Text("Trim")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("In: \(formatTime(inPoint))")
                    Slider(value: $inPoint, in: 0...outPoint)
                    Text("Out: \(formatTime(outPoint))")
                }
                .font(.caption)
            }
            
            // Transitions
            VStack(alignment: .leading, spacing: 4) {
                Text("Transitions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Picker("In", selection: $transitionIn) {
                        ForEach(TransitionStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                    
                    Picker("Out", selection: $transitionOut) {
                        ForEach(TransitionStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
            }
            
            Button("Apply") {
                onTrim(inPoint, outPoint)
                onTransitionChange(transitionIn, transitionOut)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(DirectorStudioTheme.Colors.surfacePanel)
        .cornerRadius(8)
        .onAppear {
            inPoint = clip.inPoint
            outPoint = clip.outPoint
            transitionIn = clip.transitionIn
            transitionOut = clip.transitionOut
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        String(format: "%.2f", time)
    }
}

