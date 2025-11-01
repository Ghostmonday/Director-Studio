// MODULE: AuthService
// VERSION: 1.0.0
// PURPOSE: Handles iCloud authentication and user identity

import Foundation
import CloudKit

/// Manages user authentication via iCloud
class AuthService: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userID: String?
    
    // Lazy container to avoid crash on init in simulator
    private lazy var container: CKContainer? = {
        #if targetEnvironment(simulator)
        // In simulator, CloudKit might not be available
        return nil
        #else
        return CKContainer.default()
        #endif
    }()
    
    // MARK: - Authentication
    
    /// Check if user is logged into iCloud
    func checkiCloudStatus() async -> Bool {
        // Stub implementation for simulator
        #if targetEnvironment(simulator)
        print("ℹ️ Running in simulator - iCloud check skipped (Guest Mode)")
        return false
        #else
        guard let container = container else {
            print("❌ CloudKit container not available")
            return false
        }
        
        do {
            let status = try await container.accountStatus()
            
            switch status {
            case .available:
                await fetchUserID()
                return true
            case .noAccount, .restricted, .couldNotDetermine, .temporarilyUnavailable:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("❌ iCloud status check failed: \(error.localizedDescription)")
            return false
        }
        #endif
    }
    
    /// Fetch the user's iCloud record ID
    private func fetchUserID() async {
        guard let container = container else {
            print("❌ CloudKit container not available")
            return
        }
        
        do {
            let recordID = try await container.userRecordID()
            await MainActor.run {
                self.userID = recordID.recordName
                self.isAuthenticated = true
            }
        } catch {
            print("❌ Failed to fetch user ID: \(error.localizedDescription)")
        }
    }
}

