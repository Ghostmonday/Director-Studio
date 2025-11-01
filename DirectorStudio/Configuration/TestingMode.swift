// MODULE: TestingMode
// VERSION: 1.0.0
// PURPOSE: Low-cost API testing configuration for UX validation

import Foundation

/// Testing mode configuration for cost-effective UX validation
struct TestingMode {
    
    /// Enable testing mode (set to false for production)
    static let isEnabled: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["TESTING_MODE"] == "1"
        #else
        return false
        #endif
    }()
    
    /// Testing mode settings
    struct Settings {
        /// Minimum duration for test clips (1 second = lowest cost)
        static let testClipDuration: Double = 1.0
        
        /// Maximum number of clips in multi-clip test
        static let maxTestClips: Int = 2
        
        /// Test resolution (lower = cheaper)
        static let testResolution: String = "480p"
        
        /// Test FPS (lower = cheaper)
        static let testFPS: Int = 24
        
        /// Override user-selected duration with test duration
        static func overrideDuration(_ userDuration: Double) -> Double {
            return isEnabled ? testClipDuration : userDuration
        }
        
        /// Limit number of clips for testing
        static func limitClips(_ clips: Int) -> Int {
            return isEnabled ? min(clips, maxTestClips) : clips
        }
        
        /// Get test-safe resolution
        static func getResolution(_ userResolution: String?) -> String {
            return isEnabled ? testResolution : (userResolution ?? "1920x1080")
        }
        
        /// Get test-safe FPS
        static func getFPS(_ userFPS: Int?) -> Int {
            return isEnabled ? testFPS : (userFPS ?? 30)
        }
    }
    
    /// Log testing mode status
    static func logStatus() {
        #if DEBUG
        if isEnabled {
            print("🧪 [TestingMode] ENABLED")
            print("   - Clip duration: \(Settings.testClipDuration)s")
            print("   - Max clips: \(Settings.maxTestClips)")
            print("   - Resolution: \(Settings.testResolution)")
            print("   - FPS: \(Settings.testFPS)")
            print("   - Purpose: Low-cost UX validation")
        } else {
            print("🚀 [TestingMode] DISABLED - Full production mode")
        }
        #endif
    }
    
    /// Show testing mode banner in UI
    static var bannerText: String? {
        return isEnabled ? "🧪 Testing Mode: Minimum-cost clips for UX validation" : nil
    }
}

