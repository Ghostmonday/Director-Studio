// MODULE: SettingsView
// VERSION: 1.0.0
// PURPOSE: Settings and configuration view

import SwiftUI

struct SettingsView: View {
    @ObservedObject var coordinator: Coordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(title: "Video Quality", value: "1080p")
                SettingsRow(title: "Frame Rate", value: "30 fps")
                SettingsRow(title: "Output Format", value: "MP4")
                SettingsRow(title: "Credits Remaining", value: "100")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
            
            Button("Back to Prompt") {
                coordinator.navigateTo(.promptInput)
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .padding()
    }
}

struct SettingsRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
