// MODULE: PromptReviewView
// VERSION: 1.0.0
// PURPOSE: Review and edit segmented prompts before generation

import SwiftUI

struct PromptReviewView: View {
    @ObservedObject var segmentCollection: MultiClipSegmentCollection
    let segmentationWarnings: [SegmentationWarning]
    @Binding var isPresented: Bool
    @State private var editingSegmentId: UUID?
    @State private var animateIntro = false
    
    let onContinue: () -> Void
    
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
                    // Guardrail: Show error if no segments
                    if segmentCollection.segments.isEmpty {
                        emptyStateView
                    } else {
                        // Header
                        headerView
                            .padding()
                            .background(.regularMaterial)
                        
                        // Warnings
                        if !segmentationWarnings.isEmpty {
                            warningView
                                .padding()
                                .background(.regularMaterial)
                        }
                        
                        // Prompts list
                        ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(segmentCollection.segments.enumerated()), id: \.element.id) { index, segment in
                                PromptEditCard(
                                    segment: segment,
                                    clipNumber: index + 1,
                                    text: Binding(
                                        get: { segment.text },
                                        set: { newText in
                                            if let idx = segmentCollection.segments.firstIndex(where: { $0.id == segment.id }) {
                                                segmentCollection.segments[idx].text = newText
                                            }
                                        }
                                    ),
                                    isEnabled: Binding(
                                        get: { segment.isEnabled },
                                        set: { newValue in
                                            if let idx = segmentCollection.segments.firstIndex(where: { $0.id == segment.id }) {
                                                segmentCollection.segments[idx].isEnabled = newValue
                                            }
                                        }
                                    ),
                                    isEditing: editingSegmentId == segment.id,
                                    onEdit: { editingSegmentId = segment.id },
                                    onDone: { editingSegmentId = nil }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale.combined(with: .opacity),
                                    removal: .scale.combined(with: .opacity)
                                ))
                                .scaleEffect(animateIntro ? 1 : 0.8)
                                .opacity(animateIntro ? 1 : 0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.05),
                                    value: animateIntro
                                )
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
            }
            .navigationTitle("Review Prompts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            withAnimation {
                animateIntro = true
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review and Edit Your Clip Prompts")
                .font(.headline)
            
            Text("Select which clips to generate. Unselected clips will be skipped to save credits.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Selection controls
            let enabledCount = segmentCollection.segments.filter { $0.isEnabled }.count
            let totalCount = segmentCollection.segments.count
            
            HStack {
                // Stats
                HStack(spacing: 16) {
                    Label("\(totalCount) Total", systemImage: "film.stack")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Label("\(enabledCount) Selected", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    if enabledCount < totalCount {
                        Label("\(totalCount - enabledCount) Skipped", systemImage: "xmark.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Select all/none button
                Button(action: {
                    withAnimation(.spring()) {
                        let shouldSelectAll = enabledCount < totalCount
                        for index in segmentCollection.segments.indices {
                            segmentCollection.segments[index].isEnabled = shouldSelectAll
                        }
                    }
                }) {
                    Text(enabledCount == totalCount ? "Deselect All" : "Select All")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var warningView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text("Segmentation Notes")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(segmentationWarnings.enumerated()), id: \.offset) { _, warning in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.orange)
                        Text(warning.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("Segmentation Failed")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Unable to break down your script into clips. Please try again or use a different script format.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: { isPresented = false }) {
                Label("Go Back", systemImage: "arrow.left")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    private var continueButton: some View {
        let hasEmptyPrompts = segmentCollection.segments.contains { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let canContinue = !segmentCollection.segments.isEmpty && !hasEmptyPrompts
        
        return Button(action: {
            guard canContinue else {
                #if DEBUG
                print("⚠️ [PromptReview] Blocked: Empty prompts detected")
                #endif
                return
            }
            onContinue()
        }) {
            HStack(spacing: 12) {
                Image(systemName: canContinue ? "arrow.right.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(canContinue ? "Continue to Duration Selection" : "Fix Empty Prompts")
                        .font(.headline)
                    
                    if !canContinue && hasEmptyPrompts {
                        Text("Some prompts are empty - please add content")
                            .font(.caption)
                            .opacity(0.8)
                    }
                }
                
                Spacer()
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
}

struct PromptEditCard: View {
    let segment: MultiClipSegment
    let clipNumber: Int
    @Binding var text: String
    @Binding var isEnabled: Bool
    let isEditing: Bool
    let onEdit: () -> Void
    let onDone: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Checkbox for selection
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isEnabled.toggle()
                    }
                }) {
                    Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isEnabled ? .green : .gray)
                }
                
                Label("Clip \(clipNumber)", systemImage: "film")
                    .font(.headline)
                    .foregroundColor(isEnabled ? .blue : .gray)
                
                Spacer()
                
                if isEnabled {
                    if isEditing {
                        Button("Done") {
                            onDone()
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    } else {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            
            // Text content
            if isEditing {
                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            } else {
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onTapGesture {
                        onEdit()
                    }
            }
            
            // Character count and status
            HStack {
                if !isEnabled {
                    Label("Will be skipped", systemImage: "xmark.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Text("\(text.count) characters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .opacity(isEnabled ? 1.0 : 0.6)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isEnabled ? Color.clear : Color.gray.opacity(0.3), lineWidth: 2)
        )
    }
}
