// MODULE: MultiClipGenerationView
// VERSION: 1.0.0
// PURPOSE: Beautiful multi-clip generation progress view with continuity visualization

import SwiftUI
import AVFoundation

struct MultiClipGenerationView: View {
    let segments: [MultiClipSegment]
    @ObservedObject var segmentCollection: MultiClipSegmentCollection
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) var dismiss
    
    @State private var currentSegmentIndex = 0
    @State private var overallProgress: Double = 0
    @State private var isGenerating = false
    @State private var hasError = false
    @State private var errorMessage = ""
    @State private var generatedClips: [GeneratedClip] = []
    @State private var continuityFrames: [UUID: UIImage] = [:]
    
    private let pipelineService = PipelineServiceBridge()
    private let storageService = LocalStorageService()
    
    var currentSegment: MultiClipSegment? {
        guard currentSegmentIndex < segments.count else { return nil }
        return segments[currentSegmentIndex]
    }
    
    var progressPercentage: Int {
        Int(overallProgress * 100)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                AnimatedBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Progress header
                    progressHeader
                    
                    // Current segment display
                    if let segment = currentSegment {
                        CurrentSegmentCard(
                            segment: segment,
                            segmentNumber: currentSegmentIndex + 1,
                            totalSegments: segments.count,
                            previousFrame: continuityFrames[segment.previousSegmentId ?? UUID()]
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    
                    // Progress visualization
                    progressVisualization
                    
                    Spacer()
                    
                    // Action buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Generating Clips")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isGenerating {
                        ProgressView()
                    }
                }
            }
        }
        .interactiveDismissDisabled(isGenerating)
        .onAppear {
            startGeneration()
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Overall progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: overallProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: overallProgress)
                
                VStack(spacing: 4) {
                    Text("\(progressPercentage)%")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(currentSegmentIndex) of \(segments.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(getStatusMessage())
                .font(.headline)
                .multilineTextAlignment(.center)
                .animation(.easeInOut, value: currentSegmentIndex)
        }
    }
    
    private var progressVisualization: some View {
        VStack(spacing: 16) {
            // Segment progress dots
            HStack(spacing: 8) {
                ForEach(0..<segments.count, id: \.self) { index in
                    SegmentProgressDot(
                        state: getSegmentState(at: index),
                        hasContinuity: index > 0
                    )
                }
            }
            .padding(.horizontal)
            
            // Continuity chain visualization
            if currentSegmentIndex > 0 {
                ContinuityChainView(
                    completedCount: currentSegmentIndex,
                    totalCount: segments.count
                )
            }
        }
    }
    
    private var actionButtons: some View {
        Group {
            if hasError {
                VStack(spacing: 12) {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        Button("Retry") {
                            retryCurrentSegment()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Skip") {
                            skipCurrentSegment()
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                    }
                }
            } else if !isGenerating && currentSegmentIndex >= segments.count {
                VStack(spacing: 16) {
                    Label("All clips generated successfully!", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Button(action: navigateToStudio) {
                        Label("View in Studio", systemImage: "play.rectangle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func getStatusMessage() -> String {
        if hasError {
            return "Generation Failed"
        } else if isGenerating {
            switch currentSegment?.generationState ?? .idle {
            case .generating:
                return "Creating your video..."
            case .extractingFrame:
                return "Extracting continuity frame..."
            default:
                return "Processing..."
            }
        } else if currentSegmentIndex >= segments.count {
            return "Complete! 🎉"
        } else {
            return "Ready to generate"
        }
    }
    
    private func getSegmentState(at index: Int) -> SegmentProgressDot.State {
        if index < currentSegmentIndex {
            return .completed
        } else if index == currentSegmentIndex {
            if hasError {
                return .error
            } else if isGenerating {
                return .active
            } else {
                return .pending
            }
        } else {
            return .pending
        }
    }
    
    private func startGeneration() {
        Task {
            await generateAllSegments()
        }
    }
    
    @MainActor
    private func generateAllSegments() async {
        isGenerating = true
        hasError = false
        
        for (index, segment) in segments.enumerated() {
            currentSegmentIndex = index
            overallProgress = Double(index) / Double(segments.count)
            
            // Update segment state
            segmentCollection.updateSegmentState(id: segment.id, state: .generating)
            
            do {
                // Get previous frame for continuity
                let previousFrame = continuityFrames[segment.previousSegmentId ?? UUID()]
                let referenceImageData = previousFrame?.jpegData(compressionQuality: 0.8)
                
                // Build prompt with continuity
                var prompt = segment.text
                if index > 0 {
                    prompt += "\n\n[CONTINUITY NOTE: This scene continues from the previous clip. Maintain visual consistency and flow.]"
                }
                
                // Generate the clip
                let clip = try await pipelineService.generateClip(
                    prompt: prompt,
                    clipName: "Segment_\(index + 1)",
                    enabledStages: Set<PipelineStage>(),
                    referenceImageData: referenceImageData,
                    duration: segment.duration
                )
                
                // Save the clip
                try await storageService.saveClip(clip)
                generatedClips.append(clip)
                
                // Extract last frame for next segment's continuity
                if index < segments.count - 1 {
                    segmentCollection.updateSegmentState(id: segment.id, state: .extractingFrame)
                    
                    if let videoURL = clip.localURL {
                        // Extract frame at 90% of video duration for best continuity
                        let frameTime = CMTime(seconds: segment.duration * 0.9, preferredTimescale: 600)
                        if let lastFrame = try? await extractFrame(from: videoURL, at: frameTime) {
                            continuityFrames[segment.id] = lastFrame
                            segmentCollection.updateSegmentLastFrame(
                                id: segment.id,
                                image: lastFrame,
                                data: lastFrame.jpegData(compressionQuality: 0.8) ?? Data()
                            )
                        }
                    }
                }
                
                // Update state to completed
                segmentCollection.updateSegmentState(id: segment.id, state: .completed)
                
            } catch {
                hasError = true
                errorMessage = error.localizedDescription
                segmentCollection.updateSegmentState(id: segment.id, state: .failed(errorMessage))
                return
            }
        }
        
        // All complete
        currentSegmentIndex = segments.count
        overallProgress = 1.0
        isGenerating = false
    }
    
    private func extractFrame(from videoURL: URL, at time: CMTime) async throws -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        
        let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: cgImage)
    }
    
    private func retryCurrentSegment() {
        hasError = false
        Task {
            await generateAllSegments()
        }
    }
    
    private func skipCurrentSegment() {
        currentSegmentIndex += 1
        hasError = false
        Task {
            await generateAllSegments()
        }
    }
    
    private func navigateToStudio() {
        // Add all clips to coordinator
        for clip in generatedClips {
            coordinator.addClip(clip)
        }
        
        // Navigate to studio
        coordinator.selectedTab = .studio
        dismiss()
    }
}

// MARK: - Supporting Views

struct AnimatedBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.1),
                Color.purple.opacity(0.1),
                Color.blue.opacity(0.1)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .animation(
            .linear(duration: 8)
            .repeatForever(autoreverses: true),
            value: animateGradient
        )
        .onAppear {
            animateGradient = true
        }
    }
}

struct CurrentSegmentCard: View {
    let segment: MultiClipSegment
    let segmentNumber: Int
    let totalSegments: Int
    let previousFrame: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Segment \(segmentNumber) of \(totalSegments)", systemImage: "film")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(segment.duration))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(6)
            }
            
            // Continuity reference
            if let previousFrame = previousFrame {
                HStack(spacing: 12) {
                    Image(uiImage: previousFrame)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 40)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple, lineWidth: 2)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Continuing from previous")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("Visual continuity maintained")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Script text
            ScrollView {
                Text(segment.text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 150)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

struct SegmentProgressDot: View {
    enum State {
        case pending, active, completed, error
    }
    
    let state: State
    let hasContinuity: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            if hasContinuity {
                Rectangle()
                    .fill(dotColor.opacity(0.3))
                    .frame(width: 20, height: 2)
            }
            
            Circle()
                .fill(dotColor)
                .frame(width: 16, height: 16)
                .overlay(
                    Group {
                        switch state {
                        case .active:
                            ProgressView()
                                .scaleEffect(0.5)
                                .tint(.white)
                        case .completed:
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        case .error:
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        default:
                            EmptyView()
                        }
                    }
                )
                .scaleEffect(state == .active ? 1.2 : 1)
                .animation(.spring(response: 0.3), value: state)
        }
    }
    
    private var dotColor: Color {
        switch state {
        case .pending:
            return .gray.opacity(0.3)
        case .active:
            return .blue
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
}

struct ContinuityChainView: View {
    let completedCount: Int
    let totalCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "link.circle.fill")
                .font(.title2)
                .foregroundColor(.purple)
            
            Text("Continuity Chain Active")
                .font(.caption)
                .fontWeight(.medium)
            
            Text("\(completedCount) clips linked")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
    }
}
