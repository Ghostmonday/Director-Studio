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
                .preferredColorScheme(.dark)
                .ignoresSafeArea(.keyboard) // Critical for Prompt input
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
        .overlay(alignment: .bottom) {
            CompactPillIndicator(selection: coordinator.selectedTab)
                .padding(.bottom, 6)
        }
    }
}

// MARK: - Compact Pill Indicator (iPhone-Optimized)
struct CompactPillIndicator: View {
    @Namespace private var ns
    let selection: AppTab
    
    var body: some View {
        HStack(spacing: 48) {
            ForEach([AppTab.prompt, AppTab.studio, AppTab.library], id: \.self) { tab in
                Capsule()
                    .fill(tab == selection ? DirectorStudioTheme.Colors.accent : Color.clear)
                    .frame(width: tab == selection ? 32 : 6, height: 6)
                    .matchedGeometryEffect(id: tab, in: ns)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: selection)
    }
}

