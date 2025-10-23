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
    
    var body: some View {
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
        }
        .environmentObject(dataStore)
        .environmentObject(pipelineConnector)
    }
}
