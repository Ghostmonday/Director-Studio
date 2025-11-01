// MODULE: SegmentEditorView
// VERSION: 1.0.0
// PURPOSE: Beautiful segment editor with continuity visualization

import SwiftUI

struct SegmentEditorView: View {
    @StateObject var segmentCollection: MultiClipSegmentCollection
    @ObservedObject var creditsManager = CreditsManager.shared
    @Binding var isPresented: Bool
    @State private var selectedSegmentId: UUID?
    @State private var showingGenerationView = false
    @State private var draggedSegment: MultiClipSegment?
    @State private var editingSegmentId: UUID?
    @State private var animateIntro = false
    
    let onGenerate: ([MultiClipSegment]) -> Void
    
    var enabledSegments: [MultiClipSegment] {
        segmentCollection.segments.filter { $0.isEnabled }
    }
    
    var estimatedCost: Int {
        // Calculate total duration across all enabled segments
        let totalDuration = enabledSegments.reduce(0.0) { $0 + $1.duration }
        // Use MonetizationConfig for consistent pricing
        let tokens = Int(ceil(MonetizationConfig.creditsForSeconds(totalDuration)))
        return tokens
    }
    
    var estimatedPriceCents: Int {
        let totalDuration = enabledSegments.reduce(0.0) { $0 + $1.duration }
        return MonetizationConfig.priceForSeconds(totalDuration)
    }
    
    var canGenerate: Bool {
        !enabledSegments.isEmpty && (creditsManager.isDevMode || creditsManager.tokens >= estimatedCost)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with stats
                    headerView
                        .padding()
                        .background(.regularMaterial)
                    
                    // Segments list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(segmentCollection.segments) { segment in
                                SegmentCard(
                                    segment: segment,
                                    isSelected: selectedSegmentId == segment.id,
                                    isEditing: editingSegmentId == segment.id,
                                    hasContinuityFrom: segment.previousSegmentId != nil,
                                    hasContinuityTo: segment.nextSegmentId != nil,
                                    onTap: { selectedSegmentId = segment.id },
                                    onToggle: { segmentCollection.toggleSegment(id: segment.id) },
                                    onEdit: { editingSegmentId = segment.id },
                                    onDelete: { 
                                        withAnimation(.spring()) {
                                            segmentCollection.removeSegment(id: segment.id)
                                        }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                                .scaleEffect(animateIntro ? 1 : 0.8)
                                .opacity(animateIntro ? 1 : 0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                        .delay(Double(segment.order) * 0.05),
                                    value: animateIntro
                                )
                            }
                        }
                        .padding()
                    }
                    
                    // Generate button
                    generateButton
                        .padding()
                        .background(.regularMaterial)
                }
            }
            .navigationTitle("Script Segments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: addSegment) {
                            Label("Add Segment", systemImage: "plus.circle")
                        }
                        
                        Divider()
                        
                        Menu("Re-segment") {
                            Button("By Paragraphs") {
                                resegment(strategy: .byParagraphs)
                            }
                            Button("By Duration (5s)") {
                                resegment(strategy: .byDuration(5.0))
                            }
                            Button("By Scenes") {
                                resegment(strategy: .byScenes)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingGenerationView) {
            MultiClipGenerationView(
                segments: enabledSegments,
                segmentCollection: segmentCollection
            )
        }
        .sheet(item: Binding<EditingSegment?>(
            get: {
                if let id = editingSegmentId,
                   let segment = segmentCollection.segments.first(where: { $0.id == id }) {
                    return EditingSegment(id: id, segment: segment)
                }
                return nil
            },
            set: { _ in editingSegmentId = nil }
        )) { editingSegment in
            if let index = segmentCollection.segments.firstIndex(where: { $0.id == editingSegment.id }) {
                SegmentTextEditor(
                    text: Binding(
                        get: { segmentCollection.segments[index].text },
                        set: { segmentCollection.segments[index].text = $0 }
                    ),
                    duration: Binding(
                        get: { segmentCollection.segments[index].duration },
                        set: { segmentCollection.segments[index].duration = $0 }
                    ),
                    onSave: { editingSegmentId = nil }
                )
            }
        }
        .onAppear {
            withAnimation {
                animateIntro = true
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 20) {
            // Segment count
            VStack(alignment: .leading, spacing: 4) {
                Text("\(enabledSegments.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                Label("Segments", systemImage: "square.stack.3d.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            // Total duration
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDuration(segmentCollection.totalDuration))
                    .font(.title2)
                    .fontWeight(.bold)
                Label("Duration", systemImage: "timer")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
                .frame(height: 40)
            
            // Cost display
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(MonetizationConfig.formatPrice(estimatedPriceCents))
                        .font(.title2)
                        .fontWeight(.bold)
                    if creditsManager.isDevMode {
                        Text("FREE")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                Label("\(estimatedCost) tokens", systemImage: "dollarsign.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var generateButton: some View {
        Button(action: {
            showingGenerationView = true
            onGenerate(enabledSegments)
        }) {
            HStack(spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Generate All Clips")
                        .font(.headline)
                    
                    if !creditsManager.isDevMode {
                        Text("\(MonetizationConfig.formatPrice(estimatedPriceCents)) • \(estimatedCost) tokens • Balance: \(creditsManager.tokens)")
                            .font(.caption)
                            .opacity(0.8)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: canGenerate ? [.blue, .purple] : [.gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: canGenerate ? .blue.opacity(0.3) : .clear, radius: 10, y: 5)
        }
        .disabled(!canGenerate)
        .scaleEffect(canGenerate ? 1 : 0.95)
        .animation(.spring(response: 0.3), value: canGenerate)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func addSegment() {
        withAnimation(.spring()) {
            let newSegment = MultiClipSegment(
                text: "New segment text...",
                order: segmentCollection.segments.count
            )
            segmentCollection.addSegment(newSegment)
            editingSegmentId = newSegment.id
        }
    }
    
    private func resegment(strategy: MultiClipSegmentationStrategy) {
        // Get all current text
        let fullText = segmentCollection.segments
            .map { $0.text }
            .joined(separator: "\n\n")
        
        // Create new segments
        let newSegments = MultiClipSegmentCollection.createSegments(from: fullText, strategy: strategy)
        
        // Replace with animation
        withAnimation(.spring()) {
            segmentCollection.segments = []
            for segment in newSegments {
                segmentCollection.addSegment(segment)
            }
        }
    }
}

// MARK: - Segment Card

struct SegmentCard: View {
    let segment: MultiClipSegment
    let isSelected: Bool
    let isEditing: Bool
    let hasContinuityFrom: Bool
    let hasContinuityTo: Bool
    let onTap: () -> Void
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirm = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Continuity indicator from previous
            if hasContinuityFrom {
                ContinuityIndicator(direction: .from)
                    .padding(.bottom, -8)
                    .zIndex(1)
            }
            
            // Main card
            HStack(alignment: .top, spacing: 12) {
                // Enable toggle
                Toggle("", isOn: .init(
                    get: { segment.isEnabled },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .labelsHidden()
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    HStack {
                        Label("Segment \(segment.order + 1)", systemImage: "number.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDuration(segment.duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Text preview
                    Text(segment.text)
                        .font(.body)
                        .lineLimit(3)
                        .foregroundColor(segment.isEnabled ? .primary : .secondary)
                    
                    // Actions
                    HStack(spacing: 12) {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: { showingDeleteConfirm = true }) {
                            Label("Delete", systemImage: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        // Generation state indicator
                        GenerationStateIndicator(state: segment.generationState)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(segment.isEnabled ? Color(.systemBackground) : Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1)
            .animation(.spring(response: 0.3), value: isSelected)
            .onTapGesture(perform: onTap)
            
            // Continuity indicator to next
            if hasContinuityTo {
                ContinuityIndicator(direction: .to)
                    .padding(.top, -8)
            }
        }
        .confirmationDialog(
            "Delete this segment?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%.0fs", duration)
    }
}

// MARK: - Supporting Views

struct ContinuityIndicator: View {
    enum Direction { case from, to }
    let direction: Direction
    
    var body: some View {
        HStack(spacing: 4) {
            if direction == .from {
                Image(systemName: "arrow.down")
                    .font(.caption)
            }
            
            Text("Continuity")
                .font(.caption2)
                .fontWeight(.medium)
            
            if direction == .to {
                Image(systemName: "arrow.down")
                    .font(.caption)
            }
        }
        .foregroundColor(.purple)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct GenerationStateIndicator: View {
    let state: MultiClipSegment.GenerationState
    
    var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
            case .queued:
                Label("Queued", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.orange)
            case .generating:
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Generating...")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            case .extractingFrame:
                Label("Extracting frame", systemImage: "camera.viewfinder")
                    .font(.caption)
                    .foregroundColor(.purple)
            case .completed:
                Label("Complete", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            case .failed:
                Label("Failed", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

struct SegmentTextEditor: View {
    @Binding var text: String
    @Binding var duration: TimeInterval
    let onSave: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section("Segment Text") {
                    TextEditor(text: $text)
                        .focused($isFocused)
                        .frame(minHeight: 150)
                }
                
                Section("Duration") {
                    HStack {
                        Slider(value: $duration, in: 3...20, step: 1)
                        Text("\(Int(duration))s")
                            .monospacedDigit()
                            .frame(width: 40)
                    }
                }
            }
            .navigationTitle("Edit Segment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onSave)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onSave)
                        .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

// Helper struct for sheet presentation
struct EditingSegment: Identifiable {
    let id: UUID
    let segment: MultiClipSegment
}
