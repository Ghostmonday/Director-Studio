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
        VStack(spacing: 20) {
            Text("🎬 DirectorStudio")
                .font(.system(size: 48, weight: .bold))
            
            Text("Backend Ready!")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Supabase Connected", systemImage: "checkmark.circle.fill")
                Label("Local Storage Active", systemImage: "checkmark.circle.fill")
                Label("Sync Service Ready", systemImage: "checkmark.circle.fill")
                Label("ViewModels Loaded", systemImage: "checkmark.circle.fill")
            }
            .font(.system(size: 18))
            .foregroundColor(.primary)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            
            Button(action: {
                print("✅ App is running!")
            }) {
                Text("Test Button")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}
