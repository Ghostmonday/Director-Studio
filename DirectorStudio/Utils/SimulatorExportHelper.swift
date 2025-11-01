// MODULE: SimulatorExportHelper
// VERSION: 1.0.0
// PURPOSE: Mac Simulator Export Failsafe - Auto-save to Desktop during development

import Foundation
import AVFoundation

#if DEBUG
/// Helper for exporting clips during simulator development
class SimulatorExportHelper {
    
    /// Get Desktop URL for simulator exports
    private static func getDesktopURL() -> URL? {
        #if targetEnvironment(simulator)
        guard let homeDir = ProcessInfo.processInfo.environment["HOME"] else {
            return nil
        }
        return URL(fileURLWithPath: homeDir).appendingPathComponent("Desktop/DirectorStudio_Exports")
        #else
        return nil
        #endif
    }
    
    /// Export a video clip to app storage and optionally to Desktop (simulator only)
    /// - Parameters:
    ///   - videoURL: URL of the generated video file
    ///   - clipID: Unique identifier for the clip
    /// - Returns: The app storage URL where the clip was saved
    @discardableResult
    static func exportClip(from videoURL: URL, clipID: String) -> URL? {
        do {
            // Read video data
            let data = try Data(contentsOf: videoURL)
            
            // Save to app Documents folder
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let appSaveURL = documentsURL.appendingPathComponent("Clip_\(clipID).mp4")
            try data.write(to: appSaveURL)
            
            print("✅ Saved to app storage: \(appSaveURL.path)")
            
            #if targetEnvironment(simulator)
            // Also save to Desktop for easy access during development
            if let desktopURL = getDesktopURL() {
                // Create exports folder if it doesn't exist
                try? FileManager.default.createDirectory(at: desktopURL, withIntermediateDirectories: true)
                
                let desktopFileURL = desktopURL.appendingPathComponent("Clip_\(clipID).mp4")
                try data.write(to: desktopFileURL)
                
                print("🖥️ SIMULATOR: Also saved to Desktop: \(desktopFileURL.path)")
                print("📂 Find your clip at: ~/Desktop/DirectorStudio_Exports/")
            }
            #endif
            
            return appSaveURL
            
        } catch {
            print("❌ Export failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Export a video clip using Data directly
    /// - Parameters:
    ///   - data: Video data
    ///   - clipID: Unique identifier for the clip
    /// - Returns: The app storage URL where the clip was saved
    @discardableResult
    static func exportClip(data: Data, clipID: String) -> URL? {
        do {
            // Save to app Documents folder
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let appSaveURL = documentsURL.appendingPathComponent("Clip_\(clipID).mp4")
            try data.write(to: appSaveURL)
            
            print("✅ Saved to app storage: \(appSaveURL.path)")
            
            #if targetEnvironment(simulator)
            // Also save to Desktop for easy access during development
            if let desktopURL = getDesktopURL() {
                // Create exports folder if it doesn't exist
                try? FileManager.default.createDirectory(at: desktopURL, withIntermediateDirectories: true)
                
                let desktopFileURL = desktopURL.appendingPathComponent("Clip_\(clipID).mp4")
                try data.write(to: desktopFileURL)
                
                print("🖥️ SIMULATOR: Also saved to Desktop: \(desktopFileURL.path)")
                print("📂 Find your clip at: ~/Desktop/DirectorStudio_Exports/")
            }
            #endif
            
            return appSaveURL
            
        } catch {
            print("❌ Export failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Copy an existing video file to Desktop (simulator only)
    /// - Parameters:
    ///   - sourceURL: Source video URL
    ///   - clipName: Name for the exported clip
    static func copyToDesktop(from sourceURL: URL, clipName: String) {
        #if targetEnvironment(simulator)
        guard let desktopURL = getDesktopURL() else {
            print("⚠️ Could not determine Desktop path")
            return
        }
        
        do {
            // Create exports folder if it doesn't exist
            try? FileManager.default.createDirectory(at: desktopURL, withIntermediateDirectories: true)
            
            let destinationURL = desktopURL.appendingPathComponent("\(clipName).mp4")
            
            // Remove existing file if present
            try? FileManager.default.removeItem(at: destinationURL)
            
            // Copy file
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            print("🖥️ SIMULATOR: Copied to Desktop: \(destinationURL.path)")
            print("📂 Find your clip at: ~/Desktop/DirectorStudio_Exports/")
            
        } catch {
            print("⚠️ Failed to copy to Desktop: \(error.localizedDescription)")
        }
        #endif
    }
    
    /// Log the app's Documents directory path for debugging
    static func logDocumentsPath() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("📁 App Documents: \(documentsURL.path)")
        
        #if targetEnvironment(simulator)
        if let desktopURL = getDesktopURL() {
            print("🖥️ Desktop Exports: \(desktopURL.path)")
        }
        #endif
    }
}
#endif
