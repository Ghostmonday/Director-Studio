// MODULE: LibraryViewModel
// VERSION: 1.0.0
// PURPOSE: Business logic for library management and storage operations

import Foundation

/// ViewModel for LibraryView
@MainActor
class LibraryViewModel: ObservableObject {
    @Published var selectedLocation: StorageLocation = .local
    @Published var clips: [GeneratedClip] = []
    @Published var autoUploadEnabled: Bool = true
    @Published var storageUsed: String = "0 MB"
    @Published var storageAvailable: String = "Available"
    
    /// Load clips from the selected storage location
    func loadClips(from location: StorageLocation, coordinator: AppCoordinator) {
        Task {
            do {
                switch location {
                case .local:
                    clips = try await LocalStorageService().loadClips()
                case .iCloud:
                    clips = try await CloudStorageService().loadClips()
                case .backend:
                    clips = try await SupabaseService().loadClips()
                }
                
                updateStorageInfo()
                
            } catch {
                print("❌ Failed to load clips from \(location.displayName): \(error.localizedDescription)")
                clips = []
            }
        }
    }
    
    /// Update storage usage information
    private func updateStorageInfo() {
        // Calculate storage used (stub)
        let totalSize = clips.count * 50 // Assume 50MB per clip
        storageUsed = "\(totalSize) MB"
        
        // Calculate available storage (stub)
        let availableGB = 100 - (totalSize / 1024)
        storageAvailable = "\(max(0, availableGB)) GB"
    }
    
    /// Delete a clip from storage
    func deleteClip(_ clip: GeneratedClip) {
        Task {
            do {
                // Delete from file system if local URL exists
                if let localURL = clip.localURL {
                    try? FileManager.default.removeItem(at: localURL)
                    print("✅ Deleted local file: \(localURL.lastPathComponent)")
                }
                
                // Delete from iCloud if synced
                if clip.syncStatus == .synced {
                    // TODO: Implement CloudKit deletion
                    print("🗑️ Deleted from iCloud")
                }
                
                // Remove from clips array
                await MainActor.run {
                    if let index = clips.firstIndex(where: { $0.id == clip.id }) {
                        clips.remove(at: index)
                        updateStorageInfo()
                        print("✅ Clip deleted successfully")
                    }
                }
                
            } catch {
                print("❌ Failed to delete clip: \(error.localizedDescription)")
            }
        }
    }
}

