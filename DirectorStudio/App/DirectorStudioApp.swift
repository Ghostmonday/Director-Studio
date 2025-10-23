// MODULE: DirectorStudioApp
// VERSION: 1.0.0
// PURPOSE: Main app entry point for DirectorStudio - Script → Video → Voiceover → Storage

import SwiftUI

@main
struct DirectorStudioApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "HasCompletedOnboarding")
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                }
        }
    }
}

/// Main content view with tab navigation
struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showingSettings = false
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            PromptView()
                .tabItem {
                    Label("Prompt", systemImage: "text.bubble")
                }
                .tag(AppTab.prompt)
            
            StudioView()
                .tabItem {
                    Label("Studio", systemImage: "film")
                }
                .tag(AppTab.studio)
            
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "folder")
                }
                .tag(AppTab.library)
        }
        .overlay(alignment: .topTrailing) {
            // Settings button
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Circle().fill(Color(UIColor.systemBackground)))
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            }
            .padding()
            .padding(.top, 40) // Account for status bar
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

