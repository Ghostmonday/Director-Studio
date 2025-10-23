// MODULE: DirectorStudioApp
// VERSION: 1.0.0
// PURPOSE: Main app entry point for DirectorStudio - Script → Video → Voiceover → Storage

import SwiftUI

@main
struct DirectorStudioApp: App {
    @StateObject private var coordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coordinator)
        }
    }
}

/// Main content view with tab navigation
struct ContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
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
    }
}

