// MODULE: KlingVersion+Config
// VERSION: 1.0.0
// PURPOSE: Configuration extension for KlingVersion enum
// PRODUCTION-GRADE: Version-specific API endpoints, resolution, duration limits

import Foundation

extension KlingVersion {
    /// API endpoint URL for this version (direct Kling API)
    /// Uses text2video endpoint: POST /v1/videos/text2video
    /// CORRECTED: Using Singapore API domain: https://api-singapore.klingai.com
    public var endpoint: URL {
        // All versions use the same endpoint, differentiated by model_name parameter
        return URL(string: "https://api-singapore.klingai.com/v1/videos/text2video")!
    }
    
    /// Model name string for API requests (official model names)
    /// Enum values per official API: kling-v1, kling-v1-6, kling-v2-master, kling-v2-1-master, kling-v2-5-turbo
    public var modelName: String {
        switch self {
        case .v1_6_standard:
            return "kling-v1-6"
        case .v2_0_master:
            return "kling-v2-master"  // Official model name per API docs
        case .v2_5_turbo:
            return "kling-v2-5-turbo"
        }
    }
    
    /// Status endpoint base URL for this version
    /// Official endpoint: GET /v1/videos/text2video/{task_id}
    /// CORRECTED: Using Singapore API domain: https://api-singapore.klingai.com
    public var statusBaseURL: URL {
        return URL(string: "https://api-singapore.klingai.com/v1/videos/text2video")!
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

