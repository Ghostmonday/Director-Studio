import SwiftUI

/// Content for the onboarding experience
struct OnboardingContent {
    
    static let pages = [
        OnboardingPage(
            title: "Direct the Impossible",
            subtitle: "Script to Screen",
            description: "Write your scene. Watch it come to life. Professional-quality video from nothing but words.",
            imageName: "film.fill",
            primaryColor: .blue,
            features: [
                "Write your scene",
                "Cinematic generation",
                "Export and share"
            ]
        ),
        
        OnboardingPage(
            title: "The Director's Pipeline",
            subtitle: "Frame-by-Frame Control",
            description: "Every stage refines your vision. From lighting to continuity, shape every detail before render.",
            imageName: "wand.and.stars",
            primaryColor: .purple,
            features: [
                "Scene breakdown",
                "Visual enhancement",
                "Seamless continuity"
            ]
        ),
        
        OnboardingPage(
            title: "Visual References",
            subtitle: "Show, Don't Tell",
            description: "Upload images to guide tone, style, and composition. Your vision stays consistent across every shot.",
            imageName: "photo.on.rectangle.angled",
            primaryColor: .orange,
            features: [
                "Style reference",
                "Visual consistency",
                "Mood control"
            ]
        ),
        
        OnboardingPage(
            title: "Your Project Library",
            subtitle: "Everything in One Place",
            description: "Organize scenes, manage projects, and export production-ready video. Your studio, your rules.",
            imageName: "play.rectangle.fill",
            primaryColor: .green,
            features: [
                "Scene organization",
                "Project management",
                "Ready to export"
            ]
        )
    ]
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let primaryColor: Color
    let features: [String]
}

// MARK: - Quick Tips

extension OnboardingContent {
    static let quickTips = [
        QuickTip(
            icon: "lightbulb.fill",
            title: "Think Like a Director",
            description: "Specify lighting, camera movement, and mood in your script"
        ),
        QuickTip(
            icon: "wand.and.stars",
            title: "Cinematic Pipeline",
            description: "Multi-stage enhancement turns rough drafts into polished scenes"
        ),
        QuickTip(
            icon: "photo.stack",
            title: "Style References",
            description: "Upload images to maintain visual consistency across your project"
        ),
        QuickTip(
            icon: "slider.horizontal.3",
            title: "Fine-Tune Processing",
            description: "Toggle pipeline stages to balance speed, cost, and quality"
        )
    ]
}

struct QuickTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}
