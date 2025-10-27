// MODULE: PromptReviewView
// VERSION: 1.0.0
// PURPOSE: Review and edit segmented prompts before generation

import SwiftUI

struct PromptReviewView: View {
    @ObservedObject var segmentCollection: MultiClipSegmentCollection
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
            
            Text("Each prompt will generate a separate video clip. Edit them to ensure they flow together naturally.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 24) {
                Label("\(segmentCollection.segments.count) Clips", systemImage: "film.stack")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Label("Tap to Edit", systemImage: "pencil.circle")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    let isEditing: Bool
    let onEdit: () -> Void
    let onDone: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Clip \(clipNumber)", systemImage: "film")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
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
            
            // Character count
            HStack {
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
    }
}
