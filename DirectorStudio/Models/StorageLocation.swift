// MODULE: StorageLocation
// VERSION: 1.0.0
// PURPOSE: Defines storage backend options for user content

import Foundation

/// Available storage locations for clips and voiceovers
enum StorageLocation: String, CaseIterable {
    case local = "Local"
    case iCloud = "iCloud"
    case backend = "Backend"
    
    var displayName: String {
        return self.rawValue
    }
}

