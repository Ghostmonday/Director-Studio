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
    var body: some View {
        VStack {
            Text("DirectorStudio")
                .font(.largeTitle)
                .padding()
            
            Text("Video Generation Pipeline")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}
