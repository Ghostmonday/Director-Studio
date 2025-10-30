import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var currentPage = 0
    @State private var animateContent = false
    
    let pages: [OnboardingPageData] = [
        OnboardingPageData(
            title: "Welcome to DirectorStudio",
            description: "Transform your words into cinematic video clips",
            icon: "wand.and.stars",
            color: .blue
        ),
        OnboardingPageData(
            title: "AI-Powered Generation",
            description: "Create videos from text prompts in seconds",
            icon: "sparkles",
            color: .purple
        ),
        OnboardingPageData(
            title: "Record Voiceovers",
            description: "Sync your voice with perfect timing",
            icon: "mic.fill",
            color: .red
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                .foregroundColor(.white.opacity(0.8))
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
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
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
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
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

struct OnboardingPageData {
    let title: String
    let description: String
    let icon: String
    let color: Color
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
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
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
