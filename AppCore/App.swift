// MODULE: App
// VERSION: 1.0.0
// PURPOSE: Main SwiftUI app entry point

import SwiftUI

@main
struct DirectorStudioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var coordinator = Coordinator()
    @StateObject private var dataStore = LocalDataStore()
    @StateObject private var pipelineConnector = PipelineConnector()
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                NavigationView {
                    Group {
                        switch coordinator.currentView {
                        case .promptInput:
                            PromptInputView(coordinator: coordinator)
                        case .clipPreview:
                            ClipPreviewView(coordinator: coordinator, clips: dataStore.clips)
                        case .settings:
                            SettingsView(coordinator: coordinator)
                        }
                    }
                    .navigationTitle("DirectorStudio")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Sign Out") {
                                Task {
                                    try? await authManager.signOut()
                                }
                            }
                        }
                    }
                }
                .environmentObject(dataStore)
                .environmentObject(pipelineConnector)
                .environmentObject(authManager)
            } else {
                AuthView()
            }
        }
    }
}
