// MODULE: AppCoordinator
// VERSION: 1.0.0
// PURPOSE: Central coordination for app-wide state and navigation

import SwiftUI
import Combine

#if os(iOS)
import UIKit
import Photos
#endif

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
    @Published var isGuestMode: Bool = false  // Changed to false for testing - allows text input without auth
    @Published var showingCreditsPurchase: Bool = false
    
    // MARK: - Services
    let authService: AuthService
    let storageService: StorageServiceProtocol
    
    init() {
        self.authService = AuthService()
        self.storageService = LocalStorageService()
        
        // Check authentication on init
        Task {
            await checkAuthentication()
            // Uncomment to test API services (makes actual API calls - costs money!)
            // await testAPIServices()
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
        // Always allow full access - no guest mode restrictions
        isGuestMode = false
    }
    
    /// Test API services configuration
    /// WARNING: This makes actual API calls which may cost money!
    private func testAPIServices(runHealthCheck: Bool = false) async {
        print("🔧 Testing API Services Configuration...")
        
        let polloService = PolloAIService()
        let deepSeekService = DeepSeekAIService()
        
        print("🔑 Pollo API key configured: \(polloService.isAvailable)")
        print("🔑 DeepSeek API key configured: \(deepSeekService.isAvailable)")
        
        // Only run actual API health checks if explicitly requested
        if runHealthCheck {
            print("⚠️  Running health checks (this will make API calls and may cost money)...")
            
            let polloHealth = await polloService.healthCheck()
            let deepSeekHealth = await deepSeekService.healthCheck()
            
            if polloHealth {
                print("✅ Pollo API: Connected successfully!")
            } else {
                print("❌ Pollo API: Health check failed")
            }
            
            if deepSeekHealth {
                print("✅ DeepSeek API: Connected successfully!")
            } else {
                print("❌ DeepSeek API: Health check failed")
            }
        } else {
            print("💡 To test actual API connections, call testAPIServices(runHealthCheck: true)")
        }
    }
    
    /// Generate an App Store promo video from an image
    /// WARNING: This makes actual API calls and WILL COST MONEY!
    /// - Parameters:
    ///   - imageName: Name of the image in Assets.xcassets or a file path
    ///   - saveToLibrary: Whether to save the generated video to photo library
    public func generateAppStorePromoVideo(imageName: String = "AppIcon", saveToLibrary: Bool = true) async {
        print("🎬 Starting App Store Promo Video Generation...")
        print("⚠️  This will make a real API call to Pollo and will cost money!")
        
        // Get the image data
        guard let imageData = loadImageData(named: imageName) else {
            print("❌ Could not load image: \(imageName)")
            return
        }
        
        print("✅ Loaded image: \(imageData.count / 1024)KB")
        
        // Create the video generation prompt
        let prompt = """
        Create a stunning, professional App Store preview video showcasing DirectorStudio.
        Smooth camera zoom and pan across the interface showing:
        - The elegant dark interface with purple/blue accents
        - Three main sections: Prompt input, Video Studio, and Library
        - Text overlay: "DirectorStudio - AI-Powered Video Creation"
        - Smooth transitions and professional motion
        - Modern, clean aesthetic perfect for iOS App Store
        Add subtle glow effects and smooth camera movements to make it engaging.
        """
        
        do {
            let polloService = PolloAIService()
            
            print("📤 Sending request to Pollo API...")
            print("📝 Prompt: \(prompt)")
            
            let videoURL = try await polloService.generateVideoFromImage(
                imageData: imageData,
                prompt: prompt,
                duration: 15.0 // 15-second promo video
            )
            
            print("✅ Video generated successfully!")
            print("🔗 Video URL: \(videoURL.absoluteString)")
            
            // Download the video
            print("⬇️  Downloading video...")
            let (localURL, _) = try await URLSession.shared.download(from: videoURL)
            
            // Move to documents directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent("DirectorStudio_AppStore_Promo.mp4")
            
            // Remove old file if exists
            try? FileManager.default.removeItem(at: destinationURL)
            try FileManager.default.moveItem(at: localURL, to: destinationURL)
            
            print("💾 Video saved to: \(destinationURL.path)")
            
            #if os(iOS)
            if saveToLibrary {
                print("📱 Saving to photo library...")
                await saveVideoToLibrary(url: destinationURL)
            }
            #endif
            
            print("🎉 SUCCESS! Your App Store promo video is ready!")
            print("📍 Location: \(destinationURL.path)")
            
        } catch {
            print("❌ Error generating video: \(error.localizedDescription)")
        }
    }
    
    /// Load image data from assets or file path
    private func loadImageData(named name: String) -> Data? {
        #if os(iOS)
        // Try loading from Assets.xcassets
        if let image = UIImage(named: name) {
            return image.pngData()
        }
        
        // Try loading the app icon directly
        if name == "AppIcon", let appIconImage = UIImage(named: "icon-1024") {
            return appIconImage.pngData()
        }
        #endif
        
        // Try loading from file path
        if let data = try? Data(contentsOf: URL(fileURLWithPath: name)) {
            return data
        }
        
        return nil
    }
    
    #if os(iOS)
    /// Save video to photo library
    private func saveVideoToLibrary(url: URL) async {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
            print("✅ Video saved to photo library!")
        } catch {
            print("⚠️  Could not save to photo library: \(error.localizedDescription)")
        }
    }
    #endif
}

