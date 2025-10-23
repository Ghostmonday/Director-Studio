// MODULE: SharedComponents
// VERSION: 1.0.0
// PURPOSE: Reusable UI components

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Processing...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
