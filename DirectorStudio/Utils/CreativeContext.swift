// MODULE: CreativeContext
// VERSION: 1.0.0
// PURPOSE: Track user's creative workflow stage for context-aware UI

import SwiftUI

/// Tracks the current stage of the creative workflow
enum CreativeContext {
    case ideation      // Just opened app, exploring
    case scripting     // Actively writing/editing prompt
    case reviewing     // Confirmed prompt, setting options
    case generating    // Video generation in progress
    case completed     // Generation complete, ready to view
    
    var headerMessage: String {
        switch self {
        case .ideation:
            return "What story will you tell today?"
        case .scripting:
            return "Crafting your vision..."
        case .reviewing:
            return "Review your masterpiece"
        case .generating:
            return "Bringing your story to life..."
        case .completed:
            return "Your story is ready!"
        }
    }
    
    var icon: String {
        switch self {
        case .ideation: return "lightbulb.fill"
        case .scripting: return "pencil.circle.fill"
        case .reviewing: return "checkmark.circle.fill"
        case .generating: return "film.circle.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .ideation: return DirectorStudioTheme.Colors.secondary
        case .scripting: return DirectorStudioTheme.Colors.primary
        case .reviewing: return DirectorStudioTheme.Colors.accent
        case .generating: return DirectorStudioTheme.Colors.success
        case .completed: return DirectorStudioTheme.Colors.success
        }
    }
}

/// Observable manager for tracking creative context
class CreativeContextManager: ObservableObject {
    @Published var currentContext: CreativeContext = .ideation
    
    func update(to context: CreativeContext) {
        withAnimation(DirectorStudioTheme.Animation.smooth) {
            currentContext = context
        }
    }
}

