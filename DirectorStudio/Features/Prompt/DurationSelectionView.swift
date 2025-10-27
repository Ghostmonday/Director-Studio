// MODULE: DurationSelectionView
// VERSION: 2.0.0
// PURPOSE: Select clip durations - 5/10 seconds with AI auto-selection

import SwiftUI

struct DurationSelectionView: View {
    @ObservedObject var segmentCollection: MultiClipSegmentCollection
    @Binding var isPresented: Bool
    @State private var durationType: DurationType = .aiAutoSelect
    @State private var uniformDuration: Double = 10.0 // Only 5 or 10
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var showDurationOverrides = false
    
    let onContinue: () -> Void
    
    enum DurationType: String, CaseIterable {
        case aiAutoSelect = "AI Auto-Select"
        case uniform5s = "All 5 seconds"
        case uniform10s = "All 10 seconds"
        case manual = "Manual Override"
        
        var icon: String {
            switch self {
            case .aiAutoSelect: return "sparkles"
            case .uniform5s: return "5.circle.fill"
            case .uniform10s: return "10.circle.fill"
            case .manual: return "slider.horizontal.3"
            }
        }
        
        var description: String {
            switch self {
            case .aiAutoSelect: return "AI analyzes content and chooses 5 or 10 seconds per clip"
            case .uniform5s: return "All clips will be 5 seconds (fast-paced)"
            case .uniform10s: return "All clips will be 10 seconds (standard pace)"
            case .manual: return "Override AI suggestions for specific clips"
            }
        }
    }
    
    var totalDuration: Double {
        segmentCollection.segments.reduce(0) { $0 + $1.duration }
    }
    
    var totalCost: Int {
        CreditsManager.shared.creditsNeeded(for: totalDuration, enabledStages: [])
    }
    
    /// Guardrail: Ensure prompts are ready
    var promptsAreReady: Bool {
        !segmentCollection.segments.isEmpty
    }
    
    /// Guardrail: Ensure durations are set
    var durationsAreSet: Bool {
        segmentCollection.segments.allSatisfy { $0.duration == 5.0 || $0.duration == 10.0 }
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
                    // Header
                    headerView
                        .padding()
                        .background(.regularMaterial)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Duration type selector
                            durationTypeSelector
                            
                            // AI Analysis or preview based on selection
                            switch durationType {
                            case .aiAutoSelect:
                                aiAutoSelectView
                            case .uniform5s, .uniform10s:
                                uniformDurationPreview
                            case .manual:
                                manualOverrideView
                            }
                            
                            // Cost summary
                            costSummaryView
                        }
                        .padding()
                    }
                    
                    // Continue button
                    continueButton
                        .padding()
                        .background(.regularMaterial)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: .constant(analysisError != nil)) {
                Button("OK") {
                    analysisError = nil
                }
            } message: {
                Text(analysisError ?? "")
            }
        }
        .onAppear {
            // Auto-run AI analysis if selected
            if durationType == .aiAutoSelect && !durationsAreSet {
                Task {
                    await runAIAnalysis()
                }
            }
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Step 3 of 4")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Set Clip Durations")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Choose 5 or 10 seconds per clip")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var durationTypeSelector: some View {
        VStack(spacing: 12) {
            ForEach(DurationType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation(.spring()) {
                        durationType = type
                        applyDurationType(type)
                    }
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: type.icon)
                            .font(.title2)
                            .foregroundColor(durationType == type ? .white : .blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(type.rawValue)
                                .font(.headline)
                                .foregroundColor(durationType == type ? .white : .primary)
                            
                            Text(type.description)
                                .font(.caption)
                                .foregroundColor(durationType == type ? .white.opacity(0.8) : .secondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        if durationType == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(durationType == type ? Color.blue : Color(.systemGray6))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private var aiAutoSelectView: some View {
        VStack(spacing: 16) {
            // AI Analysis status
            if isAnalyzing {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("AI is analyzing your clips...")
                        .font(.headline)
                    Text("Determining optimal duration for each scene")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            } else if durationsAreSet {
                // Show results
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("AI Analysis Complete")
                            .font(.headline)
                        Spacer()
                        Button("Re-analyze") {
                            Task {
                                await runAIAnalysis()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    // Summary stats
                    HStack(spacing: 24) {
                        VStack {
                            Text("\(segmentCollection.segments.filter { $0.duration == 5.0 }.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("5 sec clips")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack {
                            Text("\(segmentCollection.segments.filter { $0.duration == 10.0 }.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("10 sec clips")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text(formatDuration(totalDuration))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Clip list with durations
                clipDurationList
            }
        }
    }
    
    @ViewBuilder
    private var uniformDurationPreview: some View {
        VStack(spacing: 16) {
            // Summary
            VStack(spacing: 8) {
                Image(systemName: durationType == .uniform5s ? "hare.fill" : "tortoise.fill")
                    .font(.system(size: 40))
                    .foregroundColor(durationType == .uniform5s ? .orange : .blue)
                
                Text(durationType == .uniform5s ? "Fast-Paced Mode" : "Standard Mode")
                    .font(.headline)
                
                Text("All \(segmentCollection.segments.count) clips will be \(durationType == .uniform5s ? "5" : "10") seconds")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Total duration: \(formatDuration(totalDuration))")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Preview list
            clipDurationList
        }
    }
    
    @ViewBuilder
    private var manualOverrideView: some View {
        VStack(spacing: 16) {
            Text("Tap any clip to toggle between 5 and 10 seconds")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Interactive clip list
            LazyVStack(spacing: 8) {
                ForEach(Array(segmentCollection.segments.enumerated()), id: \.element.id) { index, segment in
                    Button(action: {
                        // Toggle between 5 and 10
                        let newDuration: Double = segment.duration == 5.0 ? 10.0 : 5.0
                        segmentCollection.segments[index].duration = newDuration
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Clip \(index + 1)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(segment.text)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            // Duration toggle button
                            Text("\(Int(segment.duration))s")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(segment.duration == 5.0 ? Color.orange : Color.blue)
                                )
                                .overlay(
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .offset(y: 18)
                                )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    @ViewBuilder
    private var clipDurationList: some View {
        LazyVStack(spacing: 8) {
            ForEach(Array(segmentCollection.segments.enumerated()), id: \.element.id) { index, segment in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clip \(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(segment.text)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Duration badge
                    HStack(spacing: 4) {
                        Image(systemName: segment.duration == 5.0 ? "hare.fill" : "tortoise.fill")
                            .font(.caption)
                        Text("\(Int(segment.duration))s")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(segment.duration == 5.0 ? Color.orange : Color.blue)
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    @ViewBuilder
    private var costSummaryView: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Cost Summary", systemImage: "dollarsign.circle.fill")
                    .font(.headline)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatDuration(totalDuration))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Credits Required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(totalCost)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var continueButton: some View {
        VStack(spacing: 12) {
            // Guardrail check
            if !promptsAreReady {
                Text("⚠️ Please complete prompt review first")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else if !durationsAreSet {
                Text("⚠️ Please set durations for all clips")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Button(action: {
                #if DEBUG
                print("🎬 [DurationSelection] Continuing with durations:")
                for (i, segment) in segmentCollection.segments.enumerated() {
                    let preview = String(segment.text.prefix(30))
                    print("   Clip \(i+1): \(Int(segment.duration))s - \(preview)...")
                }
                print("   Total: \(Int(totalDuration))s, Cost: \(totalCost) credits")
                #endif
                onContinue()
            }) {
                HStack {
                    Text("Continue to Cost Confirmation")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right.circle.fill")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(durationsAreSet ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!durationsAreSet || !promptsAreReady)
        }
    }
    
    // MARK: - Helper Methods
    
    private func applyDurationType(_ type: DurationType) {
        switch type {
        case .aiAutoSelect:
            // Run AI analysis
            Task {
                await runAIAnalysis()
            }
        case .uniform5s:
            // Apply 5s duration to all segments
            for i in segmentCollection.segments.indices {
                segmentCollection.segments[i].duration = 5.0
            }
            segmentCollection.objectWillChange.send()
        case .uniform10s:
            // Apply 10s duration to all segments
            for i in segmentCollection.segments.indices {
                segmentCollection.segments[i].duration = 10.0
            }
            segmentCollection.objectWillChange.send()
        case .manual:
            // If not already set, default to 10s
            if !durationsAreSet {
                for i in segmentCollection.segments.indices {
                    segmentCollection.segments[i].duration = 10.0
                }
                segmentCollection.objectWillChange.send()
            }
        }
    }
    
    private func runAIAnalysis() async {
        isAnalyzing = true
        analysisError = nil
        
        do {
            // For now, use simple heuristics based on text length
            // Short segments (< 50 words) = 5s, longer = 10s
            for i in segmentCollection.segments.indices {
                let wordCount = segmentCollection.segments[i].text.split(separator: " ").count
                segmentCollection.segments[i].duration = wordCount < 50 ? 5.0 : 10.0
            }
            segmentCollection.objectWillChange.send()
            
            // Simulate AI analysis delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            isAnalyzing = false
        } catch {
            isAnalyzing = false
            analysisError = "AI analysis failed: \(error.localizedDescription)"
            // Default to 10s on error
            for i in segmentCollection.segments.indices {
                segmentCollection.segments[i].duration = 10.0
            }
            segmentCollection.objectWillChange.send()
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(remainingSeconds)s"
        }
    }
}

// MARK: - Preview

struct DurationSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        DurationSelectionView(
            segmentCollection: MultiClipSegmentCollection(),
            isPresented: .constant(true),
            onContinue: {}
        )
    }
}