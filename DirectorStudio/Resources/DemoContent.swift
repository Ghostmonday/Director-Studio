import Foundation

/// Sample content for demonstrating DirectorStudio capabilities
struct DemoContent {
    
    // MARK: - Sample Projects
    
    static let sampleProjects = [
        DemoProject(
            name: "Dante's Inferno",
            description: "A visual journey through the nine circles",
            prompt: """
            Through me you enter the city of woe,
            Through me you join the lost people.
            Abandon hope, all ye who enter here.
            
            The dark forest surrounds me, shadows dancing in crimson light.
            Souls drift like smoke across the river Styx.
            """,
            style: .cinematic
        ),
        DemoProject(
            name: "Tokyo Dreams",
            description: "Neon-lit cyberpunk narrative",
            prompt: """
            Rain falls on neon streets. The city breathes in pixels and light.
            A lone figure walks through Shibuya crossing, lost in the digital maze.
            Holographic advertisements paint the sky in impossible colors.
            """,
            style: .cyberpunk
        ),
        DemoProject(
            name: "Forest Meditation",
            description: "Peaceful nature visualization",
            prompt: """
            Ancient trees whisper secrets in the morning mist.
            Sunlight filters through emerald leaves, painting golden paths.
            A deer pauses by the crystal stream, time stands still.
            """,
            style: .nature
        )
    ]
    
    // MARK: - Sample Prompts
    
    static let samplePrompts = [
        "A lone astronaut floating above Earth, watching the sunrise paint continents in gold",
        "Victorian London streets shrouded in fog, gas lamps flickering like fireflies",
        "Desert sands shifting into glass cities under a binary sunset",
        "Deep ocean bioluminescence creating constellations in the abyss",
        "Cherry blossoms falling like snow in a forgotten samurai garden"
    ]
    
    // MARK: - Tutorial Content
    
    static let tutorialSteps = [
        TutorialStep(
            title: "Welcome to DirectorStudio",
            description: "Transform your words into cinematic experiences",
            prompt: "Let's create your first scene"
        ),
        TutorialStep(
            title: "Write Your Vision",
            description: "Describe a scene, emotion, or story",
            prompt: "A lighthouse standing against stormy seas"
        ),
        TutorialStep(
            title: "Choose Your Style",
            description: "Select cinematography and visual style",
            prompt: "Apply cinematic lighting and dramatic angles"
        ),
        TutorialStep(
            title: "Generate Magic",
            description: "Watch AI bring your vision to life",
            prompt: "Creating your masterpiece..."
        )
    ]
}

// MARK: - Demo Models

struct DemoProject {
    let id = UUID()
    let name: String
    let description: String
    let prompt: String
    let style: CinematographyStyle
    let createdAt = Date()
}

struct TutorialStep {
    let id = UUID()
    let title: String
    let description: String
    let prompt: String
}

enum CinematographyStyle: String, CaseIterable {
    case cinematic = "Cinematic"
    case cyberpunk = "Cyberpunk"
    case nature = "Nature Documentary"
    case noir = "Film Noir"
    case scifi = "Sci-Fi Epic"
    case fantasy = "Fantasy Adventure"
    
    var description: String {
        switch self {
        case .cinematic:
            return "Hollywood-quality cinematography with dramatic lighting"
        case .cyberpunk:
            return "Neon-soaked streets and digital dystopia"
        case .nature:
            return "BBC Planet Earth style nature footage"
        case .noir:
            return "High contrast black and white with shadows"
        case .scifi:
            return "Futuristic landscapes and alien worlds"
        case .fantasy:
            return "Magical realms and mythical creatures"
        }
    }
}

// MARK: - Welcome Messages

extension DemoContent {
    static let welcomeMessages = [
        "Ready to create something amazing?",
        "Your story awaits...",
        "Let's bring your vision to life",
        "Welcome back, director",
        "Time to create magic"
    ]
    
    static var randomWelcome: String {
        welcomeMessages.randomElement() ?? welcomeMessages[0]
    }
}
