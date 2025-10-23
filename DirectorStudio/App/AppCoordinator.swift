// MODULE: AppCoordinator
// VERSION: 1.0.0
// PURPOSE: Central coordination for app-wide state and navigation

import SwiftUI
import Combine

/// App-level tabs
enum AppTab {
    case prompt
    case studio
    case library
}

/// Coordinates app-wide state, navigation, and business logic
class AppCoordinator: ObservableObject {
    // MARK: - Navigation
    @Published var selectedTab: AppTab = .prompt
    
    // MARK: - App State
    @Published var currentProject: Project?
    @Published var generatedClips: [GeneratedClip] = []
    @Published var isAuthenticated: Bool = false
    @Published var isGuestMode: Bool = true
    
    // MARK: - Services
    let authService: AuthService
    let storageService: StorageServiceProtocol
    
    init() {
        self.authService = AuthService()
        self.storageService = LocalStorageService()
        
        // Check authentication on init
        Task {
            await checkAuthentication()
        }
    }
    
    // MARK: - Public Methods
    
    /// Navigate to specific tab
    func navigateTo(_ tab: AppTab) {
        selectedTab = tab
    }
    
    /// Add a generated clip to the current project
    func addClip(_ clip: GeneratedClip) {
        generatedClips.append(clip)
    }
    
    /// Check iCloud authentication status
    @MainActor
    private func checkAuthentication() async {
        isAuthenticated = await authService.checkiCloudStatus()
        isGuestMode = !isAuthenticated
    }
}

