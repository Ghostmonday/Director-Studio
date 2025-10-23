// MODULE: AuthManager
// VERSION: 1.0.0
// PURPOSE: Authentication management using Supabase Auth

import Foundation

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userCredits = 0
    
    private let supabaseSync = SupabaseSync()
    
    init() {
        loadMockAuthState()
    }
    
    private func loadMockAuthState() {
        isAuthenticated = true
        currentUser = User(
            id: UUID(),
            email: "user@example.com",
            userKey: "mock_user_key"
        )
        userCredits = 100
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        isAuthenticated = true
        currentUser = User(
            id: UUID(),
            email: email,
            userKey: "user_key_\(email.hashValue)"
        )
        userCredits = try await supabaseSync.fetchUserCredits()
    }
    
    @MainActor
    func signUp(email: String, password: String) async throws {
        isAuthenticated = true
        currentUser = User(
            id: UUID(),
            email: email,
            userKey: "user_key_\(email.hashValue)"
        )
        userCredits = 100
    }
    
    func signOut() async throws {
        isAuthenticated = false
        currentUser = nil
        userCredits = 0
    }
    
    func consumeCredits(amount: Int) async throws {
        guard userCredits >= amount else {
            throw AuthError.insufficientCredits
        }
        
        try await supabaseSync.decrementCredits(amount: amount)
        userCredits -= amount
    }
    
    func refreshCredits() async throws {
        userCredits = try await supabaseSync.fetchUserCredits()
    }
}

struct User {
    let id: UUID
    let email: String
    let userKey: String
}

enum AuthError: Error, LocalizedError {
    case insufficientCredits
    case authenticationFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .insufficientCredits:
            return "Insufficient credits to complete this action"
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}
