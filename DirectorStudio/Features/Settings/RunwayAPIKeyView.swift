// MODULE: RunwayAPIKeyView
// VERSION: 1.0.0
// PURPOSE: UI for users to enter their own Runway API key

import SwiftUI

struct RunwayAPIKeyView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userAPIKeysManager = UserAPIKeysManager.shared
    @State private var inputKey: String = ""
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.Spacing.large) {
                    // Header
                    VStack(alignment: .leading, spacing: theme.Spacing.small) {
                        Text("Runway API Key")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Use your own Runway API key to generate videos with Runway Gen-4. This is optional - the app works fine without it.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, theme.Spacing.medium)
                    
                    // Info Box
                    VStack(alignment: .leading, spacing: theme.Spacing.small) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("How to get your Runway API key:")
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Sign up at runwayml.com")
                            Text("2. Go to API Settings")
                            Text("3. Create a new API key")
                            Text("4. Copy and paste it here")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        Link("Open Runway Website", destination: URL(string: "https://runwayml.com")!)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .padding(.horizontal, theme.Spacing.medium)
                    
                    // Input Field
                    VStack(alignment: .leading, spacing: theme.Spacing.small) {
                        Text("API Key")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        SecureField("Enter your Runway API key", text: $inputKey)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onAppear {
                                inputKey = userAPIKeysManager.runwayAPIKey
                            }
                        
                        if userAPIKeysManager.hasRunwayKey {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Key is currently set")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, theme.Spacing.medium)
                    
                    // Privacy Note
                    VStack(alignment: .leading, spacing: theme.Spacing.small) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("Privacy & Security")
                                .fontWeight(.semibold)
                        }
                        
                        Text("Your API key is stored securely on your device only. It's never sent to our servers or shared with anyone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                    )
                    .padding(.horizontal, theme.Spacing.medium)
                    
                    Spacer()
                }
                .padding(.vertical, theme.Spacing.large)
            }
            .navigationTitle("Runway API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveKey()
                    }
                    .fontWeight(.semibold)
                    .disabled(inputKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && userAPIKeysManager.hasRunwayKey)
                }
            }
        }
        .alert("Key Saved", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your Runway API key has been saved successfully.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveKey() {
        let trimmed = inputKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate key format (basic check)
        if !trimmed.isEmpty && trimmed.count < 10 {
            errorMessage = "API key seems too short. Please check and try again."
            showingError = true
            return
        }
        
        userAPIKeysManager.setRunwayAPIKey(trimmed)
        showingSuccess = true
    }
}

#Preview {
    RunwayAPIKeyView()
}

