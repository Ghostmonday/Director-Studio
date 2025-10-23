import SwiftUI

/// Content for the onboarding experience
struct OnboardingContent {
    
    static let pages = [
        OnboardingPage(
            title: "Welcome to DirectorStudio",
            subtitle: "Transform Words Into Cinema",
            description: "Turn your stories, journals, and ideas into stunning video sequences with AI-powered cinematography.",
            imageName: "film.fill",
            primaryColor: .blue,
            features: [
                "Write or paste any text",
                "AI enhances with cinematic vision",
                "Generate videos in seconds"
            ]
        ),
        
        OnboardingPage(
            title: "Intelligent Pipeline",
            subtitle: "Hollywood-Grade Processing",
            description: "Our multi-stage pipeline transforms your words through advanced AI models, ensuring cinematic quality.",
            imageName: "wand.and.stars",
            primaryColor: .purple,
            features: [
                "Story Analysis & Segmentation",
                "Cinematography Enhancement",
                "Visual Continuity Engine"
            ]
        ),
        
        OnboardingPage(
            title: "Visual References",
            subtitle: "Guide Your Vision",
            description: "Add reference images to influence the visual style and maintain consistency across your scenes.",
            imageName: "photo.on.rectangle.angled",
            primaryColor: .orange,
            features: [
                "Upload reference images",
                "Maintain visual consistency",
                "Style transfer capabilities"
            ]
        ),
        
        OnboardingPage(
            title: "Your Studio Awaits",
            subtitle: "Organize & Export",
            description: "Manage your clips, create projects, and export your cinematic creations with professional tools.",
            imageName: "play.rectangle.fill",
            primaryColor: .green,
            features: [
                "Project management",
                "Clip organization",
                "Professional export options"
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
            title: "Pro Tip: Scene Descriptions",
            description: "Be specific about lighting, mood, and camera angles for best results"
        ),
        QuickTip(
            icon: "wand.and.stars",
            title: "Enhancement Magic",
            description: "Let AI enhance your prompts with professional cinematography terms"
        ),
        QuickTip(
            icon: "photo.stack",
            title: "Reference Images",
            description: "Add images to maintain consistent visual style across scenes"
        ),
        QuickTip(
            icon: "slider.horizontal.3",
            title: "Pipeline Control",
            description: "Toggle stages on/off to customize your generation process"
        )
    ]
}

struct QuickTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}
