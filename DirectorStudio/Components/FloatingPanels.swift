// MODULE: FloatingPanels
// VERSION: 1.0.0
// PURPOSE: Floating panels for iPad with quick actions and tools

import SwiftUI

// MARK: - Floating Action Panel
struct FloatingActionPanel: View {
    @State private var isExpanded = false
    @State private var offset = CGSize.zero
    @State private var position = CGPoint(x: UIScreen.main.bounds.width - 100, y: 200)
    @Binding var selectedTool: FloatingTool?
    
    private let theme = DirectorStudioTheme.self
    
    enum FloatingTool: String, CaseIterable {
        case capture = "camera.fill"
        case voiceover = "mic.fill"
        case effects = "sparkles"
        case timeline = "timeline.selection"
        case export = "square.and.arrow.up"
        
        var title: String {
            switch self {
            case .capture: return "Capture"
            case .voiceover: return "Voiceover"
            case .effects: return "Effects"
            case .timeline: return "Timeline"
            case .export: return "Export"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Expanded tools
                VStack(spacing: theme.Spacing.small) {
                    ForEach(FloatingTool.allCases, id: \.self) { tool in
                        ToolButton(
                            tool: tool,
                            isSelected: selectedTool == tool,
                            action: {
                                withAnimation(.spring()) {
                                    selectedTool = tool
                                    isExpanded = false
                                }
                            }
                        )
                    }
                }
                .padding(theme.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                )
                .shadow(radius: 20)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Main floating button
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                    if isExpanded {
                        selectedTool = nil
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(theme.Colors.primary)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                }
            }
            .shadow(color: theme.Colors.primary.opacity(0.3), radius: 10, y: 5)
        }
        .position(position)
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation
                }
                .onEnded { value in
                    withAnimation(.spring()) {
                        position.x += value.translation.width
                        position.y += value.translation.height
                        offset = .zero
                    }
                }
        )
    }
}

// MARK: - Tool Button
struct ToolButton: View {
    let tool: FloatingActionPanel.FloatingTool
    let isSelected: Bool
    let action: () -> Void
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tool.rawValue)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isSelected ? theme.Colors.primary : theme.Colors.stainlessSteel)
                    )
                    .foregroundColor(isSelected ? .white : theme.Colors.primary)
                
                Text(tool.title)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Stats Panel
struct QuickStatsPanel: View {
    @StateObject private var creditsManager = CreditsManager.shared
    @State private var isMinimized = false
    @State private var offset = CGSize.zero
    @State private var position = CGPoint(x: 100, y: 100)
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.Spacing.small) {
            // Header
            HStack {
                Label("Quick Stats", systemImage: "chart.bar.fill")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isMinimized.toggle()
                    }
                }) {
                    Image(systemName: isMinimized ? "chevron.down.circle" : "chevron.up.circle")
                        .foregroundColor(.secondary)
                }
            }
            
            if !isMinimized {
                Divider()
                
                // Stats
                VStack(alignment: .leading, spacing: theme.Spacing.small) {
                    StatRow(
                        icon: "banknote",
                        label: "Credits",
                        value: "\(creditsManager.tokens)",
                        color: theme.Colors.primary
                    )
                    
                    StatRow(
                        icon: "film.stack",
                        label: "Projects",
                        value: "12",
                        color: .blue
                    )
                    
                    StatRow(
                        icon: "clock",
                        label: "This Week",
                        value: "3h 24m",
                        color: .green
                    )
                    
                    StatRow(
                        icon: "arrow.up.circle",
                        label: "Exported",
                        value: "8",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .frame(width: 250)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .shadow(radius: 20)
        .position(position)
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation
                }
                .onEnded { value in
                    withAnimation(.spring()) {
                        position.x += value.translation.width
                        position.y += value.translation.height
                        offset = .zero
                    }
                }
        )
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Timeline Scrubber Panel
struct TimelineScrubberPanel: View {
    @Binding var currentTime: Double
    let duration: Double
    @State private var isDragging = false
    @State private var showingMarkers = true
    let onSeek: (Double) -> Void
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        VStack(spacing: theme.Spacing.medium) {
            // Time display
            HStack {
                Text(formatTime(currentTime))
                    .font(.system(.body, design: .monospaced))
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            // Scrubber
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.Colors.stainlessSteel)
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.Colors.primary)
                        .frame(width: geometry.size.width * (currentTime / duration), height: 8)
                    
                    // Markers
                    if showingMarkers {
                        ForEach(0..<Int(duration / 5), id: \.self) { index in
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 1, height: 12)
                                .position(
                                    x: geometry.size.width * (Double(index * 5) / duration),
                                    y: geometry.size.height / 2
                                )
                        }
                    }
                    
                    // Handle
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .shadow(radius: 4)
                        .position(
                            x: geometry.size.width * (currentTime / duration),
                            y: geometry.size.height / 2
                        )
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                }
                .frame(height: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let progress = max(0, min(1, value.location.x / geometry.size.width))
                            currentTime = progress * duration
                            onSeek(currentTime)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 20)
            
            // Controls
            HStack(spacing: theme.Spacing.medium) {
                Button(action: { onSeek(max(0, currentTime - 5)) }) {
                    Image(systemName: "gobackward.5")
                }
                
                Button(action: { /* Play/Pause */ }) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                }
                
                Button(action: { onSeek(min(duration, currentTime + 5)) }) {
                    Image(systemName: "goforward.5")
                }
                
                Spacer()
                
                Button(action: { showingMarkers.toggle() }) {
                    Image(systemName: showingMarkers ? "ruler.fill" : "ruler")
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(width: 400)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .shadow(radius: 20)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Floating Panels Container
struct FloatingPanelsContainer: View {
    @State private var selectedTool: FloatingActionPanel.FloatingTool?
    @State private var showStats = true
    @State private var showTimeline = false
    @State private var currentTime: Double = 0
    
    var body: some View {
        ZStack {
            // Content goes here
            Color.clear
            
            // Floating panels disabled for iPhone-only app
        }
    }
}

// MARK: - View Extension
extension View {
    func floatingPanels() -> some View {
        self.overlay(
            FloatingPanelsContainer()
                .allowsHitTesting(true)
        )
    }
}
