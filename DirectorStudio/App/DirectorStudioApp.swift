// MODULE: DirectorStudioApp
// VERSION: 1.0.0
// PURPOSE: Main app entry point for DirectorStudio - Script → Video → Voiceover → Storage

import SwiftUI
import UIKit

@main
struct DirectorStudioApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "HasCompletedOnboarding")
    
    init() {
        // Clear API key cache on app start to ensure fresh keys are fetched
        // This helps when keys are updated in Supabase
        SupabaseAPIKeyService.shared.clearCache()
        print("🔄 Cleared API key cache on app launch")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .preferredColorScheme(.dark)
                .ignoresSafeArea(.keyboard) // Critical for Prompt input
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                }
        }
    }
}

/// Root TabView – iPhone Compact
struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            PromptView().tabItem { Label("Prompt", systemImage: "lightbulb") }
            StudioView().tabItem { Label("Studio", systemImage: "film") }
            LibraryView().tabItem { Label("Library", systemImage: "folder") }
        }
        .tabViewStyle(.automatic)
        .background(DirectorStudioTheme.Colors.cinemaGrey)
        .onAppear {
            // Customize tab bar appearance with blue/orange theme
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 25/255, green: 25/255, blue: 25/255, alpha: 1.0) // Dark background
            
            // Selected tab color (blue)
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 74/255, green: 143/255, blue: 232/255, alpha: 1.0) // #4A8FE8
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(red: 74/255, green: 143/255, blue: 232/255, alpha: 1.0)]
            
            // Unselected tab color (gray)
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}


