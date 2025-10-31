import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var currentPage = 0
    @State private var animateContent = false
    
    let pages: [OnboardingPageData] = [
        OnboardingPageData(
            title: "Welcome to DirectorStudio",
            description: "Transform your scripts into cinematic videos with AI-powered generation",
            icon: "wand.and.stars",
            color: DirectorStudioTheme.Colors.primary,
            pageType: .welcome
        ),
        OnboardingPageData(
            title: "AI-Powered Generation",
            description: "Write your scene. Watch it come to life in seconds.",
            icon: "sparkles",
            color: DirectorStudioTheme.Colors.accent,
            pageType: .features
        ),
        OnboardingPageData(
            title: "Record Voiceovers",
            description: "Sync your voice with perfect timing using our recording tools",
            icon: "mic.fill",
            color: DirectorStudioTheme.Colors.primary,
            pageType: .permissions
        ),
        OnboardingPageData(
            title: "Choose Your Plan",
            description: "Start free or unlock Pro features for unlimited creativity",
            icon: "star.fill",
            color: DirectorStudioTheme.Colors.secondary,
            pageType: .pricing
        ),
        OnboardingPageData(
            title: "Create Your First Project",
            description: "Let's get started with a sample script or start fresh",
            icon: "plus.circle.fill",
            color: DirectorStudioTheme.Colors.primary,
            pageType: .project
        )
    ]
    
    var body: some View {
        ZStack {
            // Cinema dark background matching app theme
            DirectorStudioTheme.Colors.backgroundGradient
                .ignoresSafeArea()
            
            tourView
        }
    }
    
    private var tourView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") {
                    completeOnboarding()
                }
                .foregroundColor(DirectorStudioTheme.Colors.accent.opacity(0.9))
                .font(DirectorStudioTheme.Typography.subheadline)
                .padding()
            }
            
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.5), value: currentPage)
            
            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? DirectorStudioTheme.Colors.accent : DirectorStudioTheme.Colors.accent.opacity(0.3))
                            .frame(width: currentPage == index ? 32 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 10)
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                        .font(DirectorStudioTheme.Typography.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DirectorStudioTheme.Colors.accent)
                        .cornerRadius(DirectorStudioTheme.CornerRadius.large)
                        .shadow(color: DirectorStudioTheme.Colors.accent.opacity(0.4), radius: 16, x: 0, y: 8)
                }
                .padding(.horizontal, 40)
            }
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animateContent = true
            }
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "HasCompletedOnboarding")
        dismiss()
    }
}

enum OnboardingPageType {
    case welcome
    case features
    case permissions
    case pricing
    case project
}

struct OnboardingPageData {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let pageType: OnboardingPageType
}

struct OnboardingPageView: View {
    let page: OnboardingPageData
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .scaleEffect(animate ? 1.0 : 0.8)
                    .opacity(animate ? 1.0 : 0.5)
                
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundColor(page.color)
                    .scaleEffect(animate ? 1.0 : 0.8)
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(DirectorStudioTheme.Typography.title)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(DirectorStudioTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animate = true
            }
        }
    }
}
