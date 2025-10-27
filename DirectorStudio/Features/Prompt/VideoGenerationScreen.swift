// MODULE: VideoGenerationScreen
// VERSION: 1.0.0
// PURPOSE: Main screen managing the segmented video generation flow

import SwiftUI

/// Generation flow state machine
enum GenerationStep {
    case segmenting
    case reviewPrompts
    case selectDurations
    case costConfirmation
    case generating
}

struct VideoGenerationScreen: View {
    @StateObject private var segmentCollection = MultiClipSegmentCollection()
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var currentStep: GenerationStep = .segmenting
    @State private var showError = false
    @State private var errorMessage = ""
    @Binding var isPresented: Bool
    
    let initialScript: String
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .segmenting:
                SegmentingView(
                    script: initialScript,
                    onComplete: { segments in
                        #if DEBUG
                        print("🎬 [VideoGeneration] Segmentation complete:")
                        print("   - Generated \(segments.count) segments")
                        for (i, seg) in segments.enumerated() {
                            print("   - Segment \(i+1): \(seg.text.prefix(50))... (\(seg.duration)s)")
                        }
                        #endif
                        segmentCollection.segments = segments
                        withAnimation(.spring()) {
                            currentStep = .reviewPrompts
                        }
                    },
                    onCancel: {
                        isPresented = false
                    }
                )
                
            case .reviewPrompts:
                PromptReviewView(
                    segmentCollection: segmentCollection,
                    isPresented: Binding(
                        get: { currentStep == .reviewPrompts },
                        set: { if !$0 { currentStep = .segmenting } }
                    ),
                    onContinue: {
                        #if DEBUG
                        print("🎬 [VideoGeneration] Prompts reviewed:")
                        print("   - Total segments: \(segmentCollection.segments.count)")
                        print("   - Moving to duration selection")
                        #endif
                        withAnimation(.spring()) {
                            currentStep = .selectDurations
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .selectDurations:
                DurationSelectionView(
                    segmentCollection: segmentCollection,
                    isPresented: Binding(
                        get: { currentStep == .selectDurations },
                        set: { if !$0 { currentStep = .reviewPrompts } }
                    ),
                    onContinue: {
                        #if DEBUG
                        print("🎬 [VideoGeneration] Durations set:")
                        for (i, seg) in segmentCollection.segments.enumerated() {
                            print("   - Segment \(i+1): \(seg.duration)s")
                        }
                        let total = segmentCollection.segments.reduce(0.0) { $0 + $1.duration }
                        print("   - Total duration: \(total)s")
                        print("   - Moving to cost confirmation")
                        #endif
                        withAnimation(.spring()) {
                            currentStep = .costConfirmation
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .costConfirmation:
                CostConfirmationView(
                    segmentCollection: segmentCollection,
                    isPresented: Binding(
                        get: { currentStep == .costConfirmation },
                        set: { if !$0 { currentStep = .selectDurations } }
                    ),
                    onGenerate: {
                        withAnimation(.spring()) {
                            currentStep = .generating
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .generating:
                MultiClipGenerationView(
                    segments: segmentCollection.segments.filter { $0.isEnabled },
                    segmentCollection: segmentCollection
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

/// View shown during initial segmentation
struct SegmentingView: View {
    let script: String
    let onComplete: ([MultiClipSegment]) -> Void
    let onCancel: () -> Void
    
    @State private var isProcessing = true
    @State private var progress: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Animation
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: progress)
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
                            .animation(.linear(duration: 0.5), value: progress)
                        
                        Image(systemName: "scissors")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(progress * 360))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isProcessing)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Segmenting Your Script")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Breaking down into individual clips...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
        .onAppear {
            performSegmentation()
        }
    }
    
    private func performSegmentation() {
        // Simulate progress
        withAnimation(.linear(duration: 1.5)) {
            progress = 1.0
        }
        
        // Perform actual segmentation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            #if DEBUG
            print("🎬 [VideoGeneration] Starting segmentation")
            print("   - Script length: \(script.count) characters")
            print("   - Strategy: byScenes")
            #endif
            
            let segments = MultiClipSegmentCollection.createSegments(
                from: script,
                strategy: .byScenes
            )
            
            #if DEBUG
            print("🎬 [VideoGeneration] Segmentation complete:")
            print("   - Generated \(segments.count) segments")
            for (i, seg) in segments.enumerated() {
                print("   - Segment \(i+1): \(seg.text.prefix(50))... (\(seg.duration)s)")
            }
            #endif
            
            onComplete(segments)
        }
    }
}
