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
    
    private var continueButton: some View {
        Button(action: onContinue) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                
                Text("Continue to Duration Selection")
                    .font(.headline)
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
        }
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
