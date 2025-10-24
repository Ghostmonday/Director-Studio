import Foundation

/// Result of continuity analysis
struct ContinuityAnalysis {
    let isFirstClip: Bool
    let detectedElements: String
    let suggestedElements: [String]
    let continuityScore: Double
}

/// Manages visual and narrative continuity across generated clips
class ContinuityManager {
    static let shared = ContinuityManager()
    
    // MARK: - Continuity State
    
    /// Tracks persistent elements across scenes
    private var sceneContext: SceneContext = SceneContext()
    
    /// History of all generated clips for reference
    private var clipHistory: [ClipContext] = []
    
    // MARK: - Main Continuity Methods (Two-Stage Process)
    
    /// Stage 1: Analyze the prompt and update continuity tracking
    func analyzeContinuity(
        prompt: String,
        isFirstClip: Bool = false,
        referenceImage: Data? = nil
    ) -> ContinuityAnalysis {
        
        // Extract elements from the current prompt
        extractSceneElements(from: prompt)
        
        // First clip establishes the baseline
        if isFirstClip || clipHistory.isEmpty {
            print("🎬 Establishing continuity baseline from first clip")
            return ContinuityAnalysis(
                isFirstClip: true,
                detectedElements: sceneContext.summary(),
                suggestedElements: [],
                continuityScore: 1.0
            )
        }
        
        // Analyze what elements need to be maintained
        let suggestedElements = analyzeSuggestedElements()
        let continuityScore = calculateContinuityScore(for: prompt)
        
        return ContinuityAnalysis(
            isFirstClip: false,
            detectedElements: sceneContext.summary(),
            suggestedElements: suggestedElements,
            continuityScore: continuityScore
        )
    }
    
    /// Stage 2: Inject continuity elements into the prompt
    func injectContinuity(
        prompt: String,
        analysis: ContinuityAnalysis,
        referenceImage: Data? = nil
    ) -> String {
        
        // First clip just needs establishing shot instructions
        if analysis.isFirstClip {
            let enhancedPrompt = establishBaseline(prompt: prompt)
            recordClipContext(prompt: enhancedPrompt, referenceImage: referenceImage)
            return enhancedPrompt
        }
        
        // Apply continuity enhancements
        var enhancedPrompt = prompt
        
        // Add continuity instructions
        enhancedPrompt = addContinuityInstructions(to: enhancedPrompt)
        
        // Inject persistent elements
        enhancedPrompt = injectPersistentElements(into: enhancedPrompt)
        
        // Maintain visual style
        enhancedPrompt = maintainVisualStyle(in: enhancedPrompt)
        
        // Add any suggested elements from analysis
        if !analysis.suggestedElements.isEmpty {
            let suggestions = analysis.suggestedElements.joined(separator: ". ")
            enhancedPrompt += " \(suggestions)"
        }
        
        // Record this clip's context
        recordClipContext(prompt: enhancedPrompt, referenceImage: referenceImage)
        
        print("🎬 Continuity Score: \(analysis.continuityScore)")
        
        return enhancedPrompt
    }
    
    // MARK: - Continuity Methods
    
    private func establishBaseline(prompt: String) -> String {
        // Extract key elements from the first prompt
        extractSceneElements(from: prompt)
        
        // Add instructions to establish consistent style
        let continuityPrefix = """
        [ESTABLISHING SHOT] Create a cinematic scene with consistent visual style throughout.
        Pay special attention to lighting, color palette, and camera angle as these will define the film's look.
        
        """
        
        return continuityPrefix + prompt
    }
    
    private func addContinuityInstructions(to prompt: String) -> String {
        let continuityInstructions = """
        [CONTINUITY] This is part of an ongoing film sequence.
        Maintain the established visual style, lighting, and color palette from previous scenes.
        \(sceneContext.getVisualStyleDescription())
        
        """
        
        return continuityInstructions + prompt
    }
    
    private func injectPersistentElements(into prompt: String) -> String {
        var enhancedPrompt = prompt
        
        // Add character continuity
        if !sceneContext.characters.isEmpty {
            let characterList = sceneContext.characters.joined(separator: ", ")
            enhancedPrompt = "Featuring the same \(characterList) from previous scenes. " + enhancedPrompt
        }
        
        // Add location continuity if same setting
        if let location = sceneContext.primaryLocation {
            if prompt.lowercased().contains(location.lowercased()) {
                enhancedPrompt = "In the same \(location) as established. " + enhancedPrompt
            }
        }
        
        // Add object continuity
        if !sceneContext.keyObjects.isEmpty {
            let objects = sceneContext.keyObjects.joined(separator: ", ")
            enhancedPrompt += " Include the \(objects) as visual continuity elements."
        }
        
        return enhancedPrompt
    }
    
    private func maintainVisualStyle(in prompt: String) -> String {
        var styledPrompt = prompt
        
        // Add lighting continuity
        if let lighting = sceneContext.lightingStyle {
            styledPrompt += " Use \(lighting) lighting to match previous scenes."
        }
        
        // Add color palette continuity
        if !sceneContext.colorPalette.isEmpty {
            let colors = sceneContext.colorPalette.joined(separator: ", ")
            styledPrompt += " Maintain the \(colors) color palette."
        }
        
        // Add camera style continuity
        if let cameraStyle = sceneContext.cameraStyle {
            styledPrompt += " Film with \(cameraStyle) to match the established cinematography."
        }
        
        return styledPrompt
    }
    
    // MARK: - Context Extraction
    
    private func extractSceneElements(from prompt: String) {
        let lowercased = prompt.lowercased()
        
        // Extract characters (basic detection)
        let characterKeywords = ["man", "woman", "person", "character", "hero", "protagonist", "girl", "boy"]
        for keyword in characterKeywords {
            if lowercased.contains(keyword) {
                // Find the descriptive phrase around the keyword
                if let range = lowercased.range(of: keyword) {
                    let startIndex = lowercased.index(range.lowerBound, offsetBy: -20, limitedBy: lowercased.startIndex) ?? lowercased.startIndex
                    let endIndex = lowercased.index(range.upperBound, offsetBy: 20, limitedBy: lowercased.endIndex) ?? lowercased.endIndex
                    let context = String(lowercased[startIndex..<endIndex])
                    sceneContext.characters.append(context.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
        
        // Extract locations
        let locationKeywords = ["in", "at", "inside", "outside", "near", "by", "on"]
        for keyword in locationKeywords {
            if let range = lowercased.range(of: " \(keyword) ") {
                let afterKeyword = lowercased[range.upperBound...]
                if let nextSpace = afterKeyword.firstIndex(of: " ") {
                    let location = String(afterKeyword[..<nextSpace])
                    if location.count > 2 && !location.contains("the") {
                        sceneContext.primaryLocation = location
                        break
                    }
                }
            }
        }
        
        // Extract visual style indicators
        extractVisualStyle(from: prompt)
    }
    
    private func extractVisualStyle(from prompt: String) {
        let lowercased = prompt.lowercased()
        
        // Lighting styles
        let lightingKeywords = [
            "dark": "dark, moody",
            "bright": "bright, high-key",
            "golden": "golden hour",
            "neon": "neon-lit",
            "natural": "natural",
            "dramatic": "dramatic, high contrast"
        ]
        
        for (keyword, style) in lightingKeywords {
            if lowercased.contains(keyword) {
                sceneContext.lightingStyle = style
                break
            }
        }
        
        // Color detection
        let colors = ["red", "blue", "green", "yellow", "orange", "purple", "cyan", "magenta", "gold", "silver"]
        sceneContext.colorPalette = colors.filter { lowercased.contains($0) }
        
        // Camera style
        if lowercased.contains("close") || lowercased.contains("closeup") {
            sceneContext.cameraStyle = "intimate close-ups"
        } else if lowercased.contains("wide") || lowercased.contains("establishing") {
            sceneContext.cameraStyle = "wide establishing shots"
        } else if lowercased.contains("dynamic") || lowercased.contains("moving") {
            sceneContext.cameraStyle = "dynamic camera movements"
        }
    }
    
    private func recordClipContext(prompt: String, referenceImage: Data?) {
        let context = ClipContext(
            prompt: prompt,
            timestamp: Date(),
            hasReferenceImage: referenceImage != nil,
            sceneElements: sceneContext.summary()
        )
        clipHistory.append(context)
        
        // Keep only last 10 clips for memory efficiency
        if clipHistory.count > 10 {
            clipHistory.removeFirst()
        }
    }
    
    // MARK: - Analysis Methods
    
    private func analyzeSuggestedElements() -> [String] {
        var suggestions: [String] = []
        
        // Suggest maintaining character consistency
        if !sceneContext.characters.isEmpty && clipHistory.count > 1 {
            suggestions.append("Ensure character appearances match previous scenes")
        }
        
        // Suggest maintaining time of day
        if let lastClip = clipHistory.last {
            if lastClip.prompt.lowercased().contains("night") || lastClip.prompt.lowercased().contains("evening") {
                suggestions.append("Maintain nighttime/evening setting")
            } else if lastClip.prompt.lowercased().contains("day") || lastClip.prompt.lowercased().contains("morning") {
                suggestions.append("Maintain daytime setting")
            }
        }
        
        // Suggest weather continuity
        if clipHistory.count > 1 {
            let weatherTerms = ["rain", "snow", "sunny", "cloudy", "storm", "fog"]
            for term in weatherTerms {
                if clipHistory.last?.prompt.lowercased().contains(term) ?? false {
                    suggestions.append("Continue \(term) weather conditions")
                    break
                }
            }
        }
        
        return suggestions
    }
    
    private func calculateContinuityScore(for prompt: String) -> Double {
        guard !clipHistory.isEmpty else { return 1.0 }
        
        var score = 0.0
        var factors = 0
        
        // Check character continuity
        if !sceneContext.characters.isEmpty {
            factors += 1
            let mentionedCharacters = sceneContext.characters.filter { character in
                prompt.lowercased().contains(character.lowercased())
            }
            score += Double(mentionedCharacters.count) / Double(sceneContext.characters.count)
        }
        
        // Check location continuity
        if let location = sceneContext.primaryLocation {
            factors += 1
            if prompt.lowercased().contains(location.lowercased()) {
                score += 1.0
            }
        }
        
        // Check visual style consistency
        if let lighting = sceneContext.lightingStyle {
            factors += 1
            if prompt.lowercased().contains(lighting.split(separator: ",").first?.lowercased() ?? "") {
                score += 1.0
            }
        }
        
        // Check color palette consistency
        if !sceneContext.colorPalette.isEmpty {
            factors += 1
            let mentionedColors = sceneContext.colorPalette.filter { color in
                prompt.lowercased().contains(color.lowercased())
            }
            score += Double(mentionedColors.count) / Double(sceneContext.colorPalette.count)
        }
        
        return factors > 0 ? score / Double(factors) : 0.5
    }
    
    // MARK: - Public Methods
    
    /// Resets continuity for a new project/film
    func resetContinuity() {
        sceneContext = SceneContext()
        clipHistory = []
        print("🎬 Continuity reset for new film")
    }
    
    /// Gets a summary of current continuity state
    func getContinuitySummary() -> String {
        return sceneContext.summary()
    }
    
    /// Updates continuity based on user feedback
    func updateContinuityElement(element: ContinuityElement, value: String) {
        switch element {
        case .character:
            sceneContext.characters.append(value)
        case .location:
            sceneContext.primaryLocation = value
        case .object:
            sceneContext.keyObjects.append(value)
        case .lighting:
            sceneContext.lightingStyle = value
        case .color:
            sceneContext.colorPalette.append(value)
        case .cameraStyle:
            sceneContext.cameraStyle = value
        }
    }
}

// MARK: - Supporting Types

private struct SceneContext {
    var characters: [String] = []
    var primaryLocation: String?
    var keyObjects: [String] = []
    var lightingStyle: String?
    var colorPalette: [String] = []
    var cameraStyle: String?
    var timeOfDay: String?
    
    func getVisualStyleDescription() -> String {
        var description = ""
        
        if let lighting = lightingStyle {
            description += "Lighting: \(lighting). "
        }
        
        if !colorPalette.isEmpty {
            description += "Colors: \(colorPalette.joined(separator: ", ")). "
        }
        
        if let camera = cameraStyle {
            description += "Camera: \(camera). "
        }
        
        return description.isEmpty ? "Maintain consistent visual style." : description
    }
    
    func summary() -> String {
        var summary = "🎬 Scene Continuity:\n"
        
        if !characters.isEmpty {
            summary += "Characters: \(characters.joined(separator: ", "))\n"
        }
        
        if let location = primaryLocation {
            summary += "Location: \(location)\n"
        }
        
        if !keyObjects.isEmpty {
            summary += "Key Objects: \(keyObjects.joined(separator: ", "))\n"
        }
        
        summary += getVisualStyleDescription()
        
        return summary
    }
}

private struct ClipContext {
    let prompt: String
    let timestamp: Date
    let hasReferenceImage: Bool
    let sceneElements: String
}

enum ContinuityElement {
    case character
    case location
    case object
    case lighting
    case color
    case cameraStyle
}
