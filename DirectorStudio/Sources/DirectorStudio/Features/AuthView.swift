// MODULE: AuthView
// VERSION: 1.0.0
// PURPOSE: Authentication view for sign in/sign up

import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager()
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("DirectorStudio")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Video Generation Pipeline")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if isLoading {
                    LoadingView()
                } else {
                    Button(isSignUp ? "Sign Up" : "Sign In") {
                        Task {
                            await authenticate()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty)
                }
                
                Button(isSignUp ? "Already have an account? Sign In" : "Need an account? Sign Up") {
                    isSignUp.toggle()
                    errorMessage = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()
        }
        .padding()
    }
    
    private func authenticate() async {
        isLoading = true
        errorMessage = ""
        
        do {
            if isSignUp {
                try await authManager.signUp(email: email, password: password)
            } else {
                try await authManager.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
