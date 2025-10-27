// MODULE: DurationSelectionView
// VERSION: 1.0.0
// PURPOSE: Select clip durations - fixed or AI auto-detect

import SwiftUI

struct DurationSelectionView: View {
    @ObservedObject var segmentCollection: MultiClipSegmentCollection
    @Binding var isPresented: Bool
    @State private var durationType: DurationType = .fixed
    @State private var fixedDuration: Double = 3.0
    @State private var isAutoDetecting = false
    @State private var autoDetectError: String?
    @State private var detectedDurations: [UUID: Double] = [:]
    
    let onContinue: () -> Void
    
    enum DurationType {
        case fixed
        case autoDetect
    }
    
    var totalDuration: Double {
        if durationType == .fixed {
            return Double(segmentCollection.segments.count) * fixedDuration
        } else {
            return detectedDurations.values.reduce(0, +)
        }
    }
    
    /// Guardrail: Ensure prompts are ready
    var promptsAreReady: Bool {
        !segmentCollection.segments.isEmpty
    }
    
    /// Guardrail: Ensure durations are set
    var durationsAreSet: Bool {
        if durationType == .fixed {
            return segmentCollection.segments.count > 0 && fixedDuration > 0
        } else {
            return !detectedDurations.isEmpty && detectedDurations.count == segmentCollection.segments.count
        }
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
                    // Guardrail warning if prompts not ready
                    if !promptsAreReady {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No prompts available")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                Text("Please go back and complete prompt review first")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                    }
                    
                    // Header
                    headerView
                        .padding()
                        .background(.regularMaterial)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Duration type selector
                            durationTypeSelector
                            
                            // Duration configuration
                            if durationType == .fixed {
                                fixedDurationConfig
                            } else {
                                autoDetectConfig
                            }
                            
                            // Preview
                            if !detectedDurations.isEmpty || durationType == .fixed {
                                durationPreview
                            }
                        }
                        .padding()
                    }
                    
                    // Continue button
                    continueButton
                        .padding()
                        .background(.regularMaterial)
                }
            }
            .navigationTitle("Clip Durations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            // Set initial fixed duration for all segments
            applyFixedDuration()
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How long should each clip be?")
                .font(.headline)
            
            Text("Choose between a fixed duration for all clips or let AI analyze your script to suggest optimal durations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var durationTypeSelector: some View {
        VStack(spacing: 16) {
            // Fixed duration option
            Button(action: {
                withAnimation(.spring()) {
                    durationType = .fixed
                    applyFixedDuration()
                }
            }) {
                HStack(spacing: 16) {
                    Image(systemName: durationType == .fixed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(durationType == .fixed ? .blue : .gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Same duration per clip")
                            .font(.headline)
                        Text("All clips will have the same length")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(durationType == .fixed ? Color.blue.opacity(0.1) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(durationType == .fixed ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
            
            // Auto-detect option
            Button(action: {
                withAnimation(.spring()) {
                    durationType = .autoDetect
                    if detectedDurations.isEmpty {
                        autoDetectDurations()
                    }
                }
            }) {
                HStack(spacing: 16) {
                    Image(systemName: durationType == .autoDetect ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(durationType == .autoDetect ? .purple : .gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto-detect durations using AI")
                            .font(.headline)
                        Text("AI analyzes each prompt to suggest optimal timing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(durationType == .autoDetect ? Color.purple.opacity(0.1) : Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(durationType == .autoDetect ? Color.purple : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var fixedDurationConfig: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration per clip")
                .font(.headline)
            
            HStack(spacing: 16) {
                Slider(value: $fixedDuration, in: 1...10, step: 0.5) { editing in
                    if !editing {
                        applyFixedDuration()
                    }
                }
                
                Text("\(fixedDuration, specifier: "%.1f")s")
                    .font(.title3)
                    .fontWeight(.medium)
                    .frame(width: 60)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 12) {
                ForEach([1.0, 3.0, 5.0, 10.0], id: \.self) { duration in
                    Button(action: {
                        fixedDuration = duration
                        applyFixedDuration()
                    }) {
                        Text("\(Int(duration))s")
                            .font(.caption)
                            .fontWeight(fixedDuration == duration ? .bold : .regular)
                            .foregroundColor(fixedDuration == duration ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(fixedDuration == duration ? Color.blue : Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var autoDetectConfig: some View {
        VStack(spacing: 16) {
            if isAutoDetecting {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Analyzing prompts with AI...")
                        .font(.headline)
                    Text("This may take a moment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(.systemBackground))
                .cornerRadius(16)
            } else if let error = autoDetectError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Failed to auto-detect durations")
                        .font(.headline)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        autoDetectDurations()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
            } else if !detectedDurations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.purple)
                        Text("AI-Suggested Durations")
                            .font(.headline)
                    }
                    
                    Text("Based on content analysis and pacing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(16)
            } else {
                Button(action: autoDetectDurations) {
                    Label("Analyze Prompts", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var durationPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Preview")
                    .font(.headline)
                
                Spacer()
                
                Text("Total: \(formatDuration(totalDuration))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(Array(segmentCollection.segments.enumerated()), id: \.element.id) { index, segment in
                    HStack {
                        Text("Clip \(index + 1)")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(segment.duration, specifier: "%.1f")s")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var continueButton: some View {
        let canContinue = promptsAreReady && durationsAreSet && totalDuration > 0
        
        return Button(action: {
            if canContinue {
                onContinue()
            }
        }) {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: canContinue ? "arrow.right.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                    
                    Text(canContinue ? "Continue to Cost Confirmation" : "Set durations for all clips")
                        .font(.headline)
                    
                    Spacer()
                    
                    if canContinue {
                        Text(formatDuration(totalDuration))
                            .font(.subheadline)
                            .opacity(0.8)
                    }
                }
                
                // Debug info in development
                #if DEBUG
                if !canContinue {
                    Text("Clips: \(segmentCollection.segments.count) • Durations: \(durationsAreSet ? "✓" : "✗")")
                        .font(.caption2)
                        .opacity(0.7)
                }
                #endif
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: canContinue ? [.blue, .purple] : [.gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: canContinue ? .blue.opacity(0.3) : .clear, radius: 10, y: 5)
        }
        .disabled(!canContinue)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func applyFixedDuration() {
        for index in segmentCollection.segments.indices {
            segmentCollection.segments[index].duration = fixedDuration
        }
    }
    
    private func autoDetectDurations() {
        isAutoDetecting = true
        autoDetectError = nil
        
        Task {
            do {
                // Validate token limits before calling AI
                var tokenWarnings: [String] = []
                for (index, segment) in segmentCollection.segments.enumerated() {
                    let tokenCount = TokenEstimator.shared.estimate(segment.text)
                    if tokenCount > 180 {  // Leave buffer for API
                        tokenWarnings.append("Segment \(index + 1) has \(tokenCount) tokens (limit: 180)")
                        #if DEBUG
                        print("⚠️ Token limit warning: Segment \(index + 1) has \(tokenCount) tokens")
                        #endif
                    }
                }
                
                if !tokenWarnings.isEmpty {
                    await MainActor.run {
                        autoDetectError = "Some segments exceed token limits:\n" + tokenWarnings.joined(separator: "\n")
                    }
                }
                
                // Call AI service to analyze prompts
                let durations = try await AIClipDurator.shared.detectDurations(
                    for: segmentCollection.segments.map { $0.text }
                )
                
                await MainActor.run {
                    // Apply detected durations
                    for (index, segment) in segmentCollection.segments.enumerated() {
                        if index < durations.count {
                            segmentCollection.segments[index].duration = Double(durations[index])
                            detectedDurations[segment.id] = Double(durations[index])
                        }
                    }
                    isAutoDetecting = false
                }
            } catch {
                await MainActor.run {
                    autoDetectError = error.localizedDescription
                    isAutoDetecting = false
                    // Fall back to fixed duration
                    durationType = .fixed
                    applyFixedDuration()
                }
            }
        }
    }
}
