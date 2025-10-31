// MODULE: KlingVersion+Config
// VERSION: 1.0.0
// PURPOSE: Configuration extension for KlingVersion enum
// PRODUCTION-GRADE: Version-specific API endpoints, resolution, duration limits

import Foundation

extension KlingVersion {
    /// API endpoint URL for this version
    public var endpoint: URL {
        switch self {
        case .v1_6_standard:
            return KlingAPIClient.base.appendingPathComponent("/v1/videos")
        case .v2_0_master:
            return KlingAPIClient.base.appendingPathComponent("/v2/videos")
        case .v2_5_turbo:
            return KlingAPIClient.base.appendingPathComponent("/v2.5/videos/turbo")
        }
    }
    
    /// Maximum resolution supported by this version
    public var resolution: String {
        switch self {
        case .v2_5_turbo:
            return "1080p"
        default:
            return "720p"
        }
    }
    
    /// Maximum duration in seconds for this version
    public var maxSeconds: Int {
        switch self {
        case .v2_0_master:
            return 10
        default:
            return 5
        }
    }
    
    /// Whether this version supports negative prompts
    public var supportsNegative: Bool {
        self != .v1_6_standard
    }
}

