// MODULE: DirectorStudioApp
// VERSION: 1.0.0
// PURPOSE: Main app entry point for DirectorStudio - Script → Video → Voiceover → Storage

import SwiftUI

@main
struct DirectorStudioApp: App {
    @StateObject private var coordinator = AppCoordinator()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "HasCompletedOnboarding")
    
    init() {
        // Clear API key cache on app launch to ensure fresh keys
        SupabaseAPIKeyService.shared.clearCache()
        
        // Test telemetry
        testTelemetry()
    }
    
    func testTelemetry() {
        TelemetryService.shared.logEvent("telemetry_test_event", metadata: [
            "test": true,
            "message": "Testing DirectorStudio telemetry",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            AdaptiveContentView()
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
        ZStack {
            // Cinema grey background
            DirectorStudioTheme.Colors.cinemaGrey
                .ignoresSafeArea()
            
            TabView(selection: $coordinator.selectedTab) {
                PromptView()
                    .tabItem {
                        Label("Create", systemImage: "wand.and.stars")
                    }
                    .tag(AppTab.prompt)
                
                StudioView()
                    .tabItem {
                        Label("Studio", systemImage: "film.stack")
                    }
                    .tag(AppTab.studio)
                
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "photo.stack")
                    }
                    .tag(AppTab.library)
            }
        }
        .overlay(alignment: .topTrailing) {
            // Settings button
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(DirectorStudioTheme.Colors.primary)
                    .padding()
                    .background(Circle().fill(DirectorStudioTheme.Colors.stainlessSteel))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            }
            .padding()
            .padding(.top, 40) // Account for status bar
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(coordinator)
        }
        .onAppear {
            // Auto-enable dev mode for testing
            let devModeEnabled = CreditsManager.shared.enableDevMode(passcode: "2025DS10")
            print("🔧 Dev Mode Auto-Enabled: \(devModeEnabled)")
            print("🔧 Dev Mode Status: \(CreditsManager.shared.isDevMode)")
            
            // Give unlimited tokens for testing
            CreditsManager.shared.tokens = 999999
            print("💰 Granted 999,999 tokens for testing")
            
            // Test API logging
            print("\n🔍🔍🔍 TESTING API DEBUG LOGGING 🔍🔍🔍")
            print("📱 App launched successfully")
            print("🔧 Dev Mode: \(CreditsManager.shared.isDevMode)")
            print("💰 Tokens: \(CreditsManager.shared.tokens)")
            print("🎬 Demo Mode: REMOVED - all users have full access")
            print("🔍🔍🔍 END TEST 🔍🔍🔍\n")
        }
    }
}

