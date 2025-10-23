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
                // Show storage launch screen first
                StorageLaunchView()
            } else {
                AuthView()
            }
        }
    }
}
