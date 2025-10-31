// MODULE: ExtractedEntities
// VERSION: 1.0.0
// PURPOSE: Structured entities extracted from scripts (Characters, Scenes, Props)
// BUILD STATUS: ✅ Complete

import Foundation

/// Represents a character extracted from script
public struct Character: Identifiable, Codable, Hashable {
    public let id: UUID
    var name: String
    var description: String
    var relationships: [String] // Names of other characters
    var visualDescription: String? // For portrait generation
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        relationships: [String] = [],
        visualDescription: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.relationships = relationships
        self.visualDescription = visualDescription
    }
}

/// Represents a scene/location extracted from script
public struct Scene: Identifiable, Codable, Hashable {
    public let id: UUID
    var name: String
    var environmentType: String // e.g., "indoor", "outdoor", "urban", "natural"
    var lighting: String // e.g., "bright", "dim", "golden hour"
    var mood: String // e.g., "tense", "peaceful", "energetic"
    var description: String
    var visualDescription: String? // For environment generation
    
    public init(
        id: UUID = UUID(),
        name: String,
        environmentType: String = "",
        lighting: String = "",
        mood: String = "",
        description: String = "",
        visualDescription: String? = nil
    ) {
        self.id = id
        self.name = name
        self.environmentType = environmentType
        self.lighting = lighting
        self.mood = mood
        self.description = description
        self.visualDescription = visualDescription
    }
}

/// Represents a prop/object extracted from script
public struct Prop: Identifiable, Codable, Hashable {
    public let id: UUID
    var label: String
    var category: String // e.g., "weapon", "furniture", "vehicle"
    var visualAttributes: [String] // e.g., ["red", "metallic", "large"]
    var description: String
    
    public init(
        id: UUID = UUID(),
        label: String,
        category: String = "",
        visualAttributes: [String] = [],
        description: String = ""
    ) {
        self.id = id
        self.label = label
        self.category = category
        self.visualAttributes = visualAttributes
        self.description = description
    }
}

/// Complete set of entities extracted from a script
public struct ExtractedEntities: Codable {
    var characters: [Character]
    var scenes: [Scene]
    var props: [Prop]
    
    public init(
        characters: [Character] = [],
        scenes: [Scene] = [],
        props: [Prop] = []
    ) {
        self.characters = characters
        self.scenes = scenes
        self.props = props
    }
    
    var isEmpty: Bool {
        characters.isEmpty && scenes.isEmpty && props.isEmpty
    }
}

