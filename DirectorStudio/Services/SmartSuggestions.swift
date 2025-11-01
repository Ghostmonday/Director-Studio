// MODULE: SmartSuggestions
// VERSION: 1.0.0
// PURPOSE: Context-aware suggestions for video creation

import SwiftUI
import Foundation

// MARK: - App Context

struct AppContext {
    let currentHour: Int
    let lastVideoDuration: TimeInterval?
    let recentGenres: [String]
    let totalVideosCreated: Int
    let lastPromptWords: Int
    let currentWeekday: Int
    let creditsRemaining: Int
    
    var isLateNight: Bool {
        currentHour >= 22 || currentHour <= 4
    }
    
    var isMorning: Bool {
        currentHour >= 5 && currentHour <= 11
    }
    
    var isWeekend: Bool {
        currentWeekday == 1 || currentWeekday == 7
    }
    
    var hasLowCredits: Bool {
        creditsRemaining < 50
    }
    
    var lastThreeGenresAreSimilar: Bool {
        guard recentGenres.count >= 3 else { return false }
        let lastThree = recentGenres.suffix(3)
        return Set(lastThree).count == 1
    }
}

// MARK: - Suggestion Types

enum SuggestionType {
    case timeBased
    case usageBased
    case patternBased
    case creditBased
    case creative
    
    var icon: String {
        switch self {
        case .timeBased: return "clock.fill"
        case .usageBased: return "chart.line.uptrend.xyaxis"
        case .patternBased: return "sparkles"
        case .creditBased: return "dollarsign.circle.fill"
        case .creative: return "lightbulb.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .timeBased: return .blue
        case .usageBased: return .green
        case .patternBased: return .purple
        case .creditBased: return .orange
        case .creative: return .pink
        }
    }
}

struct Suggestion {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let message: String
    let actionText: String?
    let action: (() -> Void)?
}

// MARK: - Smart Suggestions Engine

class SmartSuggestionsEngine: ObservableObject {
    static let shared = SmartSuggestionsEngine()
    
    @Published var currentSuggestion: Suggestion?
    @Published var recentSuggestions: [Suggestion] = []
    
    private init() {}
    
    func generateSuggestion(for context: AppContext) -> Suggestion? {
        var suggestions: [Suggestion] = []
        
        // Time-based suggestions
        if context.isLateNight {
            suggestions.append(Suggestion(
                type: .timeBased,
                title: "Night Owl Mode 🦉",
                message: "Late night creativity! Try our noir or horror templates for atmospheric scenes.",
                actionText: "Show Noir Templates",
                action: nil
            ))
        } else if context.isMorning {
            suggestions.append(Suggestion(
                type: .timeBased,
                title: "Morning Inspiration ☀️",
                message: "Start your day with bright, energetic scenes. Perfect for motivational content!",
                actionText: "Show Uplifting Templates",
                action: nil
            ))
        }
        
        if context.isWeekend {
            suggestions.append(Suggestion(
                type: .timeBased,
                title: "Weekend Project Mode 🎬",
                message: "Perfect time for longer projects! Try creating a multi-clip series.",
                actionText: "Create Series",
                action: nil
            ))
        }
        
        // Usage-based suggestions
        if let lastDuration = context.lastVideoDuration, lastDuration < 5 {
            suggestions.append(Suggestion(
                type: .usageBased,
                title: "Quick Clips Master 🎯",
                message: "Your short clips are perfect for social media! Keep them coming.",
                actionText: nil,
                action: nil
            ))
        }
        
        if context.totalVideosCreated == 1 {
            suggestions.append(Suggestion(
                type: .usageBased,
                title: "First Video Created! 🎉",
                message: "Congrats on your first creation! Try experimenting with different styles.",
                actionText: "Explore Styles",
                action: nil
            ))
        } else if context.totalVideosCreated % 10 == 0 {
            suggestions.append(Suggestion(
                type: .usageBased,
                title: "Milestone Reached! 🏆",
                message: "You've created \(context.totalVideosCreated) videos! You're on fire!",
                actionText: nil,
                action: nil
            ))
        }
        
        // Pattern-based suggestions
        if context.lastThreeGenresAreSimilar {
            suggestions.append(Suggestion(
                type: .patternBased,
                title: "Try Something New? 🎨",
                message: "You've been creating similar content. Ready to explore a different style?",
                actionText: "Show Different Genres",
                action: nil
            ))
        }
        
        if context.lastPromptWords > 100 {
            suggestions.append(Suggestion(
                type: .patternBased,
                title: "Detailed Storyteller 📝",
                message: "Your detailed prompts create rich scenes! Consider breaking into multiple clips.",
                actionText: "Try Multi-Clip",
                action: nil
            ))
        }
        
        // Credit-based suggestions
        if context.hasLowCredits {
            suggestions.append(Suggestion(
                type: .creditBased,
                title: "Credits Running Low 💰",
                message: "You have \(context.creditsRemaining) credits left. Consider shorter clips to save credits.",
                actionText: "Buy Credits",
                action: nil
            ))
        }
        
        // Creative suggestions
        let creativeSuggestions = [
            Suggestion(
                type: .creative,
                title: "Director's Challenge 🎬",
                message: "Try the one-shot challenge: Create a compelling story in a single 10-second clip!",
                actionText: nil,
                action: nil
            ),
            Suggestion(
                type: .creative,
                title: "Genre Fusion 🔄",
                message: "Mix two genres for unique results: Sci-fi Romance or Comedy Horror!",
                actionText: nil,
                action: nil
            ),
            Suggestion(
                type: .creative,
                title: "Silent Film Mode 🎞️",
                message: "Create a story without dialogue - let visuals do the talking!",
                actionText: nil,
                action: nil
            )
        ]
        
        if context.totalVideosCreated > 5 {
            suggestions.append(creativeSuggestions.randomElement()!)
        }
        
        // Return a random suggestion from available ones
        return suggestions.randomElement()
    }
    
    func dismissSuggestion() {
        if let suggestion = currentSuggestion {
            recentSuggestions.append(suggestion)
            if recentSuggestions.count > 10 {
                recentSuggestions.removeFirst()
            }
        }
        currentSuggestion = nil
    }
}

// MARK: - Suggestion View

struct SmartSuggestionBanner: View {
    let suggestion: Suggestion
    @State private var isExpanded = false
    @State private var isDismissing = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: suggestion.type.icon)
                    .font(.title2)
                    .foregroundColor(suggestion.type.color)
                    .scaleEffect(isExpanded ? 1.2 : 1.0)
                    .animation(.spring(), value: isExpanded)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if isExpanded {
                        Text(suggestion.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.asymmetric(
                                insertion: .push(from: .top).combined(with: .opacity),
                                removal: .push(from: .bottom).combined(with: .opacity)
                            ))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Actions
                HStack(spacing: 8) {
                    if isExpanded, let actionText = suggestion.actionText {
                        Button(actionText) {
                            suggestion.action?()
                            withAnimation {
                                isDismissing = true
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(suggestion.type.color)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    Button(action: {
                        if isExpanded {
                            withAnimation {
                                isDismissing = true
                            }
                        } else {
                            withAnimation(.spring()) {
                                isExpanded.toggle()
                            }
                        }
                    }) {
                        Image(systemName: isExpanded ? "xmark" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 0 : 0))
                    }
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: suggestion.type.color.opacity(0.2), radius: 8)
        )
        .opacity(isDismissing ? 0 : 1)
        .scaleEffect(isDismissing ? 0.8 : 1)
        .onAppear {
            // Auto-expand after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if !isDismissing {
                    withAnimation(.spring()) {
                        isExpanded = true
                    }
                }
            }
            
            // Auto-dismiss after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                withAnimation {
                    isDismissing = true
                }
            }
        }
    }
}

// MARK: - Integration Helper

struct SmartSuggestionsView: View {
    @StateObject private var engine = SmartSuggestionsEngine.shared
    let context: AppContext
    
    var body: some View {
        VStack {
            if let suggestion = engine.currentSuggestion {
                SmartSuggestionBanner(suggestion: suggestion)
                    .padding(.horizontal)
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .onAppear {
            // Generate suggestion based on context
            engine.currentSuggestion = engine.generateSuggestion(for: context)
        }
    }
}
