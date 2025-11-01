//
//  SegmentationConfigView.swift
//  DirectorStudio
//
//  Configuration screen for segmentation settings
//

import SwiftUI

struct SegmentationConfigView: View {
    @Binding var isPresented: Bool
    let scriptLength: Int
    let onStart: (SegmentationConfig) -> Void
    
    @State private var selectedMode: SegmentationMode = .hybrid
    @State private var enableSemanticExpansion = true
    @State private var expansionStyle: SemanticExpansionConfig.ExpansionStyle = .vivid
    @State private var maxSegments: Double = 100
    @State private var targetDuration: Double = 3.0
    @State private var enableDialogueImplantation = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Generate Narrative List")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Configure how your story will be broken into scenes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // Script info
                        HStack(spacing: 16) {
                            Label("\(scriptLength) chars", systemImage: "doc.text")
                            Label("~\(scriptLength / 500) min", systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Segmentation Mode
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Segmentation Mode", systemImage: "wand.and.stars")
                            .font(.headline)
                        
                        ForEach([SegmentationMode.ai, .hybrid, .duration, .evenSplit], id: \.self) { mode in
                            ModeCard(
                                mode: mode,
                                isSelected: selectedMode == mode,
                                onSelect: { selectedMode = mode }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Semantic Expansion
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $enableSemanticExpansion) {
                            Label("Semantic Expansion", systemImage: "sparkles")
                                .font(.headline)
                        }
                        
                        if enableSemanticExpansion {
                            Text("Enhance prompts with vivid, emotional details")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Picker("Style", selection: $expansionStyle) {
                                Text("✨ Vivid").tag(SemanticExpansionConfig.ExpansionStyle.vivid)
                                Text("❤️ Emotional").tag(SemanticExpansionConfig.ExpansionStyle.emotional)
                                Text("⚡ Action").tag(SemanticExpansionConfig.ExpansionStyle.action)
                                Text("🌫️ Atmospheric").tag(SemanticExpansionConfig.ExpansionStyle.atmospheric)
                                Text("⚖️ Balanced").tag(SemanticExpansionConfig.ExpansionStyle.balanced)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Dialogue Implantation
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $enableDialogueImplantation) {
                            Label("Dialogue Implantation", systemImage: "text.bubble.fill")
                                .font(.headline)
                        }
                        
                        if enableDialogueImplantation {
                            Text("Add natural dialogue to scenes without any")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("AI will identify characters and create contextual dialogue")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Constraints
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Constraints", systemImage: "slider.horizontal.below.rectangle")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Max Segments")
                                Spacer()
                                Text("\(Int(maxSegments))")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $maxSegments, in: 5...100, step: 5)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Target Duration per Clip")
                                Spacer()
                                Text("\(Int(targetDuration))s")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $targetDuration, in: 1...20, step: 1)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Start Button
                    Button(action: {
                        let config = SegmentationConfig(
                            mode: selectedMode,
                            enableSemanticExpansion: enableSemanticExpansion,
                            expansionStyle: expansionStyle,
                            maxSegments: Int(maxSegments),
                            targetDuration: targetDuration,
                            enableDialogueImplantation: enableDialogueImplantation
                        )
                        onStart(config)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "scissors")
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Generate Narrative List")
                                    .font(.headline)
                                Text("Estimated: ~\(estimatedSegments) scenes")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    var estimatedSegments: Int {
        let wordsPerSecond = 2.5
        let targetWords = Int(targetDuration * wordsPerSecond)
        let totalWords = scriptLength / 5 // rough estimate
        return min(Int(maxSegments), max(1, totalWords / targetWords))
    }
}

struct ModeCard: View {
    let mode: SegmentationMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    var icon: String {
        switch mode {
        case .ai: return "brain.head.profile"
        case .hybrid: return "sparkles"
        case .duration: return "clock"
        case .evenSplit: return "equal.square"
        }
    }
    
    var description: String {
        switch mode {
        case .ai: return "LLM analyzes your script for natural scene breaks (requires API key)"
        case .hybrid: return "AI with automatic fallback to duration-based (recommended)"
        case .duration: return "Split based on time and word count (fast, no API needed)"
        case .evenSplit: return "Equal token distribution across segments"
        }
    }
}

// Configuration data structure
struct SegmentationConfig {
    let mode: SegmentationMode
    let enableSemanticExpansion: Bool
    let expansionStyle: SemanticExpansionConfig.ExpansionStyle
    let maxSegments: Int
    let targetDuration: Double
    let enableDialogueImplantation: Bool
}

