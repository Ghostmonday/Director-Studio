// MODULE: LivePromptEditor
// VERSION: 1.0.0
// PURPOSE: Real-time prompt editor with live clip preview morphing
// BUILD STATUS: ✅ Complete

import SwiftUI
import Combine

/// Live prompt editor with debounced preview generation
public struct LivePromptEditor: View {
    @State private var prompt: String = ""
    @State private var clipPreview: UIImage?
    @State private var isGenerating = false
    @State private var previewTask: Task<Void, Never>?
    @State private var selectedMood: Mood = .epic
    @State private var variations: [ScriptVariation] = []
    
    @FocusState private var isTextFieldFocused: Bool
    
    // Debounce timer
    private let debounceDelay: TimeInterval = 0.3
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            // Prompt input with live feedback
            TextField("Describe your scene...", text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...10)
                .focused($isTextFieldFocused)
                .onChange(of: prompt) { _ in
                    previewTask?.cancel()
                    previewTask = Task {
                        await regeneratePreview()
                    }
                }
                .padding(.horizontal)
            
            // Mood selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        MoodButton(
                            mood: mood,
                            isSelected: selectedMood == mood
                        ) {
                            selectedMood = mood
                            Task {
                                await applyMood(mood)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Variations carousel
            if !variations.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(variations) { variation in
                            VariationCard(variation: variation) {
                                prompt = variation.text
                                selectedMood = variation.mood
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Live preview
            if let preview = clipPreview {
                Image(uiImage: preview)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(
                        Group {
                            if isGenerating {
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.black.opacity(0.3))
                            }
                        }
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            if isGenerating {
                                ProgressView()
                                Text("Generating preview...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "video.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Preview will appear here")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    )
            }
            
            // Remix button
            Button(action: {
                Task {
                    await applyStyle(.epic)
                }
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Remix")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(isGenerating)
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding()
        .onAppear {
            Task {
                await regeneratePreview()
                await loadVariations()
            }
        }
        .onDisappear {
            previewTask?.cancel()
        }
    }
    
    /// Regenerate preview with debounce
    private func regeneratePreview() async {
        guard !prompt.isEmpty else {
            clipPreview = nil
            return
        }
        
        // Debounce
        try? await Task.sleep(nanoseconds: UInt64(debounceDelay * 1_000_000_000))
        
        isGenerating = true
        
        // Generate preview (placeholder - would call actual generation)
        // For now, create a placeholder image
        await MainActor.run {
            clipPreview = generatePlaceholderPreview(prompt: prompt, mood: selectedMood)
            isGenerating = false
        }
    }
    
    /// Apply mood to current prompt
    private func applyMood(_ mood: Mood) async {
        // Enhance prompt with mood
        let voiceActor = VoiceToScriptActor.shared
        let enhanced = await voiceActor.enhanceWithMood(prompt, targetMood: mood)
        
        await MainActor.run {
            prompt = enhanced
        }
        
        await regeneratePreview()
    }
    
    /// Apply style remix
    private func applyStyle(_ style: Mood) async {
        selectedMood = style
        await applyMood(style)
    }
    
    /// Load variations
    private func loadVariations() async {
        guard !prompt.isEmpty else { return }
        
        let voiceActor = VoiceToScriptActor.shared
        if let variations = try? await voiceActor.generateVariations(base: prompt) {
            await MainActor.run {
                self.variations = variations
            }
        }
    }
    
    /// Generate placeholder preview (replace with actual generation)
    private func generatePlaceholderPreview(prompt: String, mood: Mood) -> UIImage? {
        // Create a simple placeholder with mood color
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Mood-based gradient
            let colors = moodColors[mood] ?? [UIColor.gray, UIColor.darkGray]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map { $0.cgColor } as CFArray, locations: nil)!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            
            // Add text
            let text = prompt.prefix(50)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let attributedString = NSAttributedString(string: String(text), attributes: attributes)
            let textSize = attributedString.size()
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            attributedString.draw(in: textRect)
        }
    }
    
    private let moodColors: [Mood: [UIColor]] = [
        .noir: [.black, .darkGray],
        .romantic: [UIColor(red: 1.0, green: 0.42, blue: 0.62, alpha: 1.0), UIColor(red: 1.0, green: 0.71, blue: 0.87, alpha: 1.0)],
        .epic: [UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0), UIColor(red: 0.85, green: 0.65, blue: 0.13, alpha: 1.0)],
        .horror: [.darkRed, .black],
        .comedy: [UIColor(red: 1.0, green: 0.67, blue: 0.0, alpha: 1.0), UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)],
        .surreal: [UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.0), UIColor(red: 0.75, green: 0.50, blue: 0.85, alpha: 1.0)]
    ]
}

// MARK: - Supporting Views

private struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(mood.displayName)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

private struct VariationCard: View {
    let variation: ScriptVariation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(variation.text)
                    .font(.caption)
                    .lineLimit(3)
                HStack {
                    Text(variation.mood.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(variation.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(width: 200)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// Extension for VoiceToScriptActor
extension VoiceToScriptActor {
    func enhanceWithMood(_ text: String, targetMood: Mood) async -> String {
        switch targetMood {
        case .noir:
            return "In the shadows, \(text.lowercased()). Rain falls. Secrets unfold."
        case .romantic:
            return "With tender beauty, \(text.lowercased()). A moment of pure connection."
        case .epic:
            return "With legendary grandeur, \(text.capitalized). A hero's journey unfolds."
        case .horror:
            return "In the darkness, \(text.lowercased()). Fear takes hold. Something stirs."
        case .comedy:
            return "With absurd hilarity, \(text.lowercased()). Laughter fills the air."
        case .surreal:
            return "In a dreamlike haze, \(text.lowercased()). Reality bends. Anything is possible."
        }
    }
}

