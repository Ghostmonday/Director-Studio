//
//  TaxonomyModule.swift
//  DirectorStudio
//
//  MODULE: Taxonomy
//  VERSION: 2.0.0
//  PURPOSE: Advanced cinematic enrichment with shot types, camera movements, lighting
//

import Foundation

// MARK: - Cinematic Taxonomy Module

/// Advanced cinematic enrichment with shot types, camera movements, lighting, and mood
/// Transforms segments into production-ready visual specifications
public struct CinematicTaxonomyModule: PipelineModule {
    public typealias Input = CinematicTaxonomyInput
    public typealias Output = CinematicTaxonomyOutput
    
    public let id = "taxonomy"
    public let name = "Cinematic Taxonomy"
    public let version = "2.0.0"
    public var isEnabled: Bool = true
    
    private let logger = Loggers.taxonomy
    
    public init() {}
    
    public func execute(input: CinematicTaxonomyInput) async throws -> CinematicTaxonomyOutput {
        let context = PipelineContext()
        let result = await execute(input: input, context: context)
        switch result {
        case .success(let output):
            return output
        case .failure(let error):
            throw error
        }
    }
    
    public func execute(
        input: CinematicTaxonomyInput,
        context: PipelineContext
    ) async -> Result<CinematicTaxonomyOutput, PipelineError> {
        logger.info("🎬 Starting cinematic taxonomy enrichment [v2.0] for \(input.segments.count) segments")
        
        await Telemetry.shared.logEvent(
            "TaxonomyModuleStarted",
            metadata: ["segmentCount": "\(input.segments.count)"]
        )
        
        let startTime = Date()
        var enrichedSegments: [PromptSegment] = []
        
        // Analyze overall narrative arc for consistent visual treatment
        let narrativeArc = analyzeNarrativeArc(input.segments)
        logger.debug("📊 Narrative arc: \(narrativeArc.summary)")
        
        // Enrich each segment with cinematic metadata
        for (index, segment) in input.segments.enumerated() {
            let position = Double(index) / Double(max(input.segments.count - 1, 1))
            
            // Determine cinematic treatment based on content and position
            let treatment = determineCinematicTreatment(
                segment: segment,
                position: position,
                narrativeArc: narrativeArc
            )
            
            // Apply cinematic metadata
            var enriched = PromptSegment(
                id: segment.id,
                index: segment.index,
                duration: segment.duration,
                content: enhanceWithCinematicDescription(
                    segment.content,
                    treatment: treatment
                ),
                characters: segment.characters,
                setting: segment.setting,
                action: segment.action,
                continuityNotes: segment.continuityNotes,
                location: segment.location,
                props: segment.props,
                tone: segment.tone
            )
            
            // Add structured metadata to cinematic tags
            enriched.cinematicTags = CinematicTaxonomy(
                shotType: treatment.shotType.rawValue,
                cameraAngle: treatment.cameraAngle.rawValue,
                framing: "Standard",
                lighting: treatment.lighting.rawValue,
                colorPalette: treatment.colorPalette,
                lensType: "Standard",
                cameraMovement: treatment.cameraMovement.rawValue,
                emotionalTone: treatment.mood,
                visualStyle: "Cinematic",
                actionCues: ["Position: \(String(format: "%.2f", position))"]
            )
            
            enrichedSegments.append(enriched)
            
            logger.debug("🎥 Segment \(index + 1): \(treatment.shotType.rawValue), \(treatment.cameraMovement.rawValue), \(treatment.lighting.rawValue)")
        }
        
        let executionTime = Date().timeIntervalSince(startTime)
        
        let output = CinematicTaxonomyOutput(
            enrichedSegments: enrichedSegments,
            totalProcessed: enrichedSegments.count,
            narrativeArc: narrativeArc
        )
        
        logger.info("✅ Cinematic enrichment completed in \(String(format: "%.2f", executionTime))s")
        
        await Telemetry.shared.logEvent(
            "TaxonomyModuleCompleted",
            metadata: [
                "duration": String(format: "%.2f", executionTime),
                "segmentsProcessed": "\(enrichedSegments.count)"
            ]
        )
        
        return .success(output)
    }
    
    public func validate(input: CinematicTaxonomyInput) -> Bool {
        return !input.segments.isEmpty
    }
    
    // MARK: - Narrative Arc Analysis
    
    /// Analyzes the overall narrative structure for visual consistency
    private func analyzeNarrativeArc(_ segments: [PromptSegment]) -> NarrativeArc {
        let totalSegments = segments.count
        
        // Detect act structure
        let act1End = totalSegments / 4
        let act2End = (totalSegments * 3) / 4
        
        // Analyze emotional progression
        var emotionalCurve: [Double] = []
        for segment in segments {
            let intensity = detectEmotionalIntensity(segment.content)
            emotionalCurve.append(intensity)
        }
        
        // Detect climax position
        let climaxPosition = emotionalCurve.enumerated()
            .max(by: { $0.element < $1.element })?.offset ?? (totalSegments * 3) / 4
        
        // Determine overall tone
        let overallTone = determineOverallTone(segments)
        
        return NarrativeArc(
            totalSegments: totalSegments,
            act1End: act1End,
            act2End: act2End,
            climaxPosition: climaxPosition,
            emotionalCurve: emotionalCurve,
            overallTone: overallTone
        )
    }
    
    // MARK: - Cinematic Treatment
    
    /// Determines appropriate cinematic treatment for a segment
    private func determineCinematicTreatment(
        segment: PromptSegment,
        position: Double,
        narrativeArc: NarrativeArc
    ) -> CinematicTreatment {
        
        let text = segment.content.lowercased()
        
        // Determine shot type based on content and position
        let shotType = determineShotType(
            text: text,
            position: position,
            narrativeArc: narrativeArc
        )
        
        // Determine camera movement
        let cameraMovement = determineCameraMovement(
            text: text,
            shotType: shotType,
            position: position
        )
        
        // Determine lighting style
        let lighting = determineLighting(
            text: text,
            position: position,
            tone: narrativeArc.overallTone
        )
        
        // Determine color palette
        let colorPalette = determineColorPalette(
            text: text,
            lighting: lighting,
            tone: narrativeArc.overallTone
        )
        
        // Determine mood/atmosphere
        let mood = determineMood(text: text, narrativeArc: narrativeArc)
        
        // Determine frame composition
        let composition = determineComposition(
            shotType: shotType,
            position: position
        )
        
        // Determine depth of field
        let depthOfField = determineDepthOfField(shotType: shotType)
        
        return CinematicTreatment(
            shotType: shotType,
            cameraMovement: cameraMovement,
            cameraAngle: determineCameraAngle(text: text, shotType: shotType),
            lighting: lighting,
            colorPalette: colorPalette,
            mood: mood,
            composition: composition,
            depthOfField: depthOfField,
            transitionSuggestion: determineTransition(position: position, text: text)
        )
    }
    
    // MARK: - Visual Element Determination
    
    private func determineShotType(
        text: String,
        position: Double,
        narrativeArc: NarrativeArc
    ) -> ShotType {
        // Opening and closing tend to be wider
        if position < 0.1 || position > 0.9 {
            return .wide
        }
        
        // Dialogue detection
        if text.contains("\"") || text.contains("said") || text.contains("asked") {
            return .medium
        }
        
        // Action detection
        if text.contains("ran") || text.contains("jumped") || text.contains("moved") {
            return .full
        }
        
        // Emotional moments
        let emotionalKeywords = ["tears", "smiled", "whispered", "stared"]
        if emotionalKeywords.contains(where: { text.contains($0) }) {
            return .closeUp
        }
        
        // Climax gets dramatic shots
        if abs(Double(narrativeArc.climaxPosition) / Double(narrativeArc.totalSegments) - position) < 0.1 {
            return .extremeCloseup
        }
        
        return .medium
    }
    
    private func determineCameraMovement(
        text: String,
        shotType: ShotType,
        position: Double
    ) -> CameraMovement {
        // Opening often has establishing movement
        if position < 0.05 {
            return .dollyIn
        }
        
        // Action sequences
        if text.contains("ran") || text.contains("chase") || text.contains("rushed") {
            return .tracking
        }
        
        // Revelation moments
        if text.contains("revealed") || text.contains("suddenly") || text.contains("appeared") {
            return .zoom
        }
        
        // Dramatic moments
        if text.contains("slowly") || text.contains("careful") {
            return .dolly
        }
        
        // Most shots are static for stability
        return .static
    }
    
    private func determineCameraAngle(text: String, shotType: ShotType) -> CameraAngle {
        // Power dynamics
        if text.contains("tower") || text.contains("above") || text.contains("looked down") {
            return .high
        }
        
        if text.contains("small") || text.contains("vulnerable") || text.contains("looked up") {
            return .low
        }
        
        // Disorientation
        if text.contains("dizzy") || text.contains("confused") || text.contains("dream") {
            return .dutch
        }
        
        // Default to eye level
        return .eyeLevel
    }
    
    private func determineLighting(
        text: String,
        position: Double,
        tone: String
    ) -> Lighting {
        // Time of day keywords
        if text.contains("night") || text.contains("dark") || text.contains("shadow") {
            return .lowKey
        }
        
        if text.contains("bright") || text.contains("sunlight") || text.contains("morning") {
            return .highKey
        }
        
        // Emotional tone
        if tone == "dark" || tone == "tense" {
            return .dramatic
        }
        
        // Dream sequences
        if text.contains("dream") || text.contains("surreal") {
            return .silhouette
        }
        
        return .natural
    }
    
    private func determineColorPalette(
        text: String,
        lighting: Lighting,
        tone: String
    ) -> String {
        if text.contains("warm") || text.contains("sunset") || text.contains("fire") {
            return "Warm (oranges, reds, yellows)"
        }
        
        if text.contains("cold") || text.contains("ice") || text.contains("blue") {
            return "Cool (blues, teals, silvers)"
        }
        
        if text.contains("dream") || text.contains("memory") {
            return "Desaturated (muted, nostalgic)"
        }
        
        if tone == "dark" {
            return "Dark (deep blues, blacks, minimal color)"
        }
        
        return "Natural (balanced, realistic)"
    }
    
    private func determineMood(text: String, narrativeArc: NarrativeArc) -> String {
        let moodKeywords: [String: String] = [
            "tense": "Tense, suspenseful",
            "peaceful": "Calm, serene",
            "chaotic": "Frenetic, overwhelming",
            "intimate": "Intimate, personal",
            "epic": "Epic, grand",
            "mysterious": "Mysterious, enigmatic",
            "joyful": "Joyful, uplifting",
            "melancholic": "Melancholic, bittersweet"
        ]
        
        for (keyword, mood) in moodKeywords {
            if text.contains(keyword) {
                return mood
            }
        }
        
        return "Neutral, observational"
    }
    
    private func determineComposition(
        shotType: ShotType,
        position: Double
    ) -> String {
        switch shotType {
        case .wide, .extremeWide:
            return "Rule of thirds, subject in lower third or asymmetric"
        case .full, .medium:
            return "Centered or slightly off-center, balanced"
        case .closeUp, .extremeCloseup:
            return "Face/subject fills frame, minimal negative space"
        case .twoShot:
            return "Two subjects balanced in frame"
        case .overShoulder:
            return "Over-shoulder perspective, depth layering"
        }
    }
    
    private func determineDepthOfField(shotType: ShotType) -> String {
        switch shotType {
        case .wide, .extremeWide:
            return "Deep focus (f/8-f/16)"
        case .medium, .full:
            return "Moderate depth (f/4-f/5.6)"
        case .closeUp, .extremeCloseup:
            return "Shallow focus (f/1.8-f/2.8)"
        default:
            return "Moderate depth (f/4-f/5.6)"
        }
    }
    
    private func determineTransition(position: Double, text: String) -> String {
        // Opening
        if position < 0.05 {
            return "Fade in from black"
        }
        
        // Closing
        if position > 0.95 {
            return "Fade to black"
        }
        
        // Scene transitions
        if text.contains("meanwhile") || text.contains("elsewhere") {
            return "Cross-dissolve"
        }
        
        if text.contains("suddenly") || text.contains("then") {
            return "Hard cut"
        }
        
        return "Standard cut"
    }
    
    // MARK: - Enhancement
    
    /// Enhances segment text with cinematic description
    private func enhanceWithCinematicDescription(
        _ text: String,
        treatment: CinematicTreatment
    ) -> String {
        // Build cinematic prefix
        let prefix = """
        [SHOT: \(treatment.shotType.rawValue) | CAMERA: \(treatment.cameraMovement.rawValue), \(treatment.cameraAngle.rawValue) | LIGHTING: \(treatment.lighting.rawValue) | MOOD: \(treatment.mood)]
        
        """
        
        return prefix + text
    }
    
    // MARK: - Helper Methods
    
    private func detectEmotionalIntensity(_ text: String) -> Double {
        let intensityMarkers = text.filter { "!?".contains($0) }.count
        let emphasisWords = ["very", "extremely", "incredibly", "absolutely"]
        let emphasisCount = emphasisWords.filter { text.lowercased().contains($0) }.count
        
        return min((Double(intensityMarkers) + Double(emphasisCount) * 0.5) / 5.0, 1.0)
    }
    
    private func determineOverallTone(_ segments: [PromptSegment]) -> String {
        let allText = segments.map { $0.content.lowercased() }.joined(separator: " ")
        
        if allText.contains("dark") || allText.contains("scary") || allText.contains("fear") {
            return "dark"
        }
        
        if allText.contains("happy") || allText.contains("joy") || allText.contains("laugh") {
            return "light"
        }
        
        if allText.contains("dream") || allText.contains("surreal") {
            return "dreamlike"
        }
        
        return "neutral"
    }
}

// MARK: - Supporting Types

public struct CinematicTaxonomyInput: Sendable {
    public let segments: [PromptSegment]
    
    public init(segments: [PromptSegment]) {
        self.segments = segments
    }
}

public struct CinematicTaxonomyOutput: Sendable {
    public let enrichedSegments: [PromptSegment]
    public let totalProcessed: Int
    public let narrativeArc: NarrativeArc
    
    public init(
        enrichedSegments: [PromptSegment],
        totalProcessed: Int,
        narrativeArc: NarrativeArc = NarrativeArc()
    ) {
        self.enrichedSegments = enrichedSegments
        self.totalProcessed = totalProcessed
        self.narrativeArc = narrativeArc
    }
}

public struct NarrativeArc: Sendable {
    let totalSegments: Int
    let act1End: Int
    let act2End: Int
    let climaxPosition: Int
    let emotionalCurve: [Double]
    let overallTone: String
    
    public init(
        totalSegments: Int = 0,
        act1End: Int = 0,
        act2End: Int = 0,
        climaxPosition: Int = 0,
        emotionalCurve: [Double] = [],
        overallTone: String = "neutral"
    ) {
        self.totalSegments = totalSegments
        self.act1End = act1End
        self.act2End = act2End
        self.climaxPosition = climaxPosition
        self.emotionalCurve = emotionalCurve
        self.overallTone = overallTone
    }
    
    var summary: String {
        "total=\(totalSegments), climax@\(climaxPosition), tone=\(overallTone)"
    }
}

private struct CinematicTreatment {
    let shotType: ShotType
    let cameraMovement: CameraMovement
    let cameraAngle: CameraAngle
    let lighting: Lighting
    let colorPalette: String
    let mood: String
    let composition: String
    let depthOfField: String
    let transitionSuggestion: String
}

private enum ShotType: String {
    case extremeWide = "Extreme Wide Shot (EWS)"
    case wide = "Wide Shot (WS)"
    case full = "Full Shot (FS)"
    case medium = "Medium Shot (MS)"
    case closeUp = "Close-Up (CU)"
    case extremeCloseup = "Extreme Close-Up (ECU)"
    case twoShot = "Two Shot"
    case overShoulder = "Over-the-Shoulder (OTS)"
}

private enum CameraMovement: String {
    case `static` = "Static"
    case pan = "Pan"
    case tilt = "Tilt"
    case dolly = "Dolly"
    case dollyIn = "Dolly In"
    case dollyOut = "Dolly Out"
    case tracking = "Tracking"
    case crane = "Crane"
    case steadicam = "Steadicam"
    case handheld = "Handheld"
    case zoom = "Zoom"
}

private enum CameraAngle: String {
    case eyeLevel = "Eye Level"
    case high = "High Angle"
    case low = "Low Angle"
    case dutch = "Dutch Angle"
    case overhead = "Overhead"
    case aerial = "Aerial"
}

private enum Lighting: String {
    case natural = "Natural"
    case highKey = "High Key"
    case lowKey = "Low Key"
    case dramatic = "Dramatic"
    case silhouette = "Silhouette"
    case backlit = "Backlit"
    case practical = "Practical"
}

