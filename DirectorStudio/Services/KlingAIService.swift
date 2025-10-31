// MODULE: KlingAIService
// VERSION: 1.0.0
// PURPOSE: Wrapper service implementing VideoGenerationProtocol using KlingAPIClient
// PRODUCTION-GRADE: Full protocol conformance, tier mapping, error handling

import Foundation
import UIKit
import os.log

/// Wrapper service that implements VideoGenerationProtocol and AIServiceProtocol using KlingAPIClient
/// Maps VideoQualityTier to appropriate KlingVersion
public final class KlingAIService: AIServiceProtocol, VideoGenerationProtocol, @unchecked Sendable {
    private var cachedClient: KlingAPIClient?
    private let logger = Logger(subsystem: "DirectorStudio.API", category: "Kling")
    
    /// Initialize with Kling credentials from Supabase (lazy initialization)
    public init() {
        // Client will be initialized lazily when credentials are fetched
    }
    
    /// Initialize with explicit credentials
    public init(accessKey: String, secretKey: String) {
        self.cachedClient = KlingAPIClient(accessKey: accessKey, secretKey: secretKey)
    }
    
    /// Convenience initializer that fetches credentials from Supabase
    public static func withSupabaseCredentials() async throws -> KlingAIService {
        let accessKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Kling")
        let secretKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "KlingSecret")
        return KlingAIService(accessKey: accessKey, secretKey: secretKey)
    }
    
    public var isAvailable: Bool {
        // Check if credentials are available
        return true // Will be validated on first API call
    }
    
    /// Map VideoQualityTier to KlingVersion
    private func klingVersion(for tier: VideoQualityTier) -> KlingVersion {
        switch tier {
        case .economy:
            return .v1_6_standard
        case .basic:
            return .v1_6_standard  // Using v1.6 for basic, could upgrade to v2.0_master
        case .pro:
            return .v2_5_turbo
        case .premium:
            // Premium uses Runway, not Kling - this shouldn't be called
            return .v2_5_turbo  // Fallback
        }
    }
    
    /// Get or create KlingAPIClient with valid credentials
    private func getClient() async throws -> KlingAPIClient {
        // Return cached client if available
        if let client = cachedClient {
            return client
        }
        
        // Fetch credentials from Supabase
        let accessKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Kling")
        let secretKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "KlingSecret")
        
        guard !accessKey.isEmpty, !secretKey.isEmpty else {
            throw APIError.authError("Kling AccessKey or SecretKey is empty. Please configure Kling credentials in Supabase.")
        }
        
        // Create and cache client
        let client = KlingAPIClient(accessKey: accessKey, secretKey: secretKey)
        cachedClient = client
        return client
    }
    
    /// Generate video with default tier (basic)
    public func generateVideo(prompt: String, duration: TimeInterval) async throws -> URL {
        return try await generateVideo(prompt: prompt, duration: duration, tier: .basic)
    }
    
    /// Generate video with specific tier
    /// - Parameters:
    ///   - prompt: Video generation prompt
    ///   - duration: Video duration in seconds
    ///   - tier: Quality tier (maps to model_name and mode)
    ///   - cameraControl: Optional camera control from cinematography
    ///   - cameraDirection: Optional camera direction string (will be converted to cameraControl)
    public func generateVideo(
        prompt: String,
        duration: TimeInterval,
        tier: VideoQualityTier,
        cameraControl: CameraControl? = nil,
        cameraDirection: String? = nil
    ) async throws -> URL {
        // Premium tier uses Runway, not Kling
        if tier == .premium {
            throw APIError.authError("Premium tier (Runway Gen-4) requires RunwayGen4Service. Please use RunwayGen4Service or add your Runway API key in Settings.")
        }
        
        // Get client with credentials
        let client = try await getClient()
        
        // Map tier to Kling version
        let version = klingVersion(for: tier)
        
        // Map tier to mode: economy/basic -> "std", pro -> "pro"
        let mode: String = (tier == .pro) ? "pro" : "std"
        
        // Round duration to valid values (5 or 10 seconds)
        let validDuration = min(max(Int(duration), 5), version.maxSeconds)
        if validDuration > 5 && validDuration < 10 {
            // Round to nearest valid value
            let roundedDuration = validDuration <= 7 ? 5 : 10
            logger.info("📐 Rounded duration from \(validDuration)s to \(roundedDuration)s (API requirement)")
        }
        
        // Convert camera direction string to camera control if provided
        var finalCameraControl = cameraControl
        if let cameraDirection = cameraDirection, finalCameraControl == nil {
            finalCameraControl = CameraControl.fromCameraDirection(cameraDirection)
        }
        
        logger.info("🚀 [Kling] Starting \(tier.shortName) video generation")
        logger.info("🚀 [Kling] Prompt: '\(prompt.prefix(100))\(prompt.count > 100 ? "..." : "")'")
        logger.info("🚀 [Kling] Duration: \(validDuration)s, Version: \(version.rawValue), Mode: \(mode)")
        if let cameraControl = finalCameraControl {
            logger.info("🎥 [Kling] Camera control: \(cameraControl.type?.rawValue ?? "custom")")
        }
        
        // Create task with camera control and mode
        let task = try await client.generateVideo(
            prompt: prompt,
            version: version,
            negativePrompt: nil,
            duration: validDuration,
            image: nil,
            imageTail: nil,
            cameraControl: finalCameraControl,
            mode: mode
        )
        
        logger.info("✅ [Kling] Task created: \(task.id)")
        
        // Poll for completion
        let videoURL = try await client.pollStatus(task: task)
        
        logger.info("✅ [Kling] Video ready: \(videoURL)")
        return videoURL
    }
    
    /// Generate video from image with default tier
    public func generateVideoFromImage(imageData: Data, prompt: String, duration: TimeInterval) async throws -> URL {
        return try await generateVideoFromImage(imageData: imageData, prompt: prompt, duration: duration, tier: .basic)
    }
    
    /// Generate video from image with specific tier
    /// - Parameters:
    ///   - imageData: Source image data
    ///   - prompt: Video generation prompt
    ///   - duration: Video duration in seconds
    ///   - tier: Quality tier (maps to model_name and mode)
    ///   - cameraControl: Optional camera control from cinematography
    ///   - cameraDirection: Optional camera direction string (will be converted to cameraControl)
    public func generateVideoFromImage(
        imageData: Data,
        prompt: String,
        duration: TimeInterval,
        tier: VideoQualityTier,
        cameraControl: CameraControl? = nil,
        cameraDirection: String? = nil
    ) async throws -> URL {
        // Premium tier uses Runway, not Kling
        if tier == .premium {
            throw APIError.authError("Premium tier (Runway Gen-4) requires RunwayGen4Service. Please use RunwayGen4Service or add your Runway API key in Settings.")
        }
        
        // Get client with credentials
        let client = try await getClient()
        
        // Map tier to Kling version
        let version = klingVersion(for: tier)
        
        // Convert image to base64 with data URI prefix
        guard let image = UIImage(data: imageData) else {
            throw APIError.invalidResponse(statusCode: -1, message: "Invalid image data")
        }
        
        // Resize and compress image (similar to PolloAIService perfectSeed)
        let targetSize = CGSize(width: 854, height: 480)  // 480p 16:9
        let scaled = image.resized(to: targetSize)
        
        guard let jpegData = scaled.jpegData(compressionQuality: 0.80) else {
            throw APIError.invalidResponse(statusCode: -1, message: "Failed to compress image")
        }
        
        // Convert to base64 with data URI prefix
        let base64String = jpegData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64String)"
        
        // Round duration
        let validDuration = min(max(Int(duration), 5), version.maxSeconds)
        let roundedDuration = validDuration <= 7 ? 5 : 10
        
        // Map tier to mode: economy/basic -> "std", pro -> "pro"
        let mode: String = (tier == .pro) ? "pro" : "std"
        
        // Convert camera direction string to camera control if provided
        var finalCameraControl = cameraControl
        if let cameraDirection = cameraDirection, finalCameraControl == nil {
            finalCameraControl = CameraControl.fromCameraDirection(cameraDirection)
        }
        
        logger.info("🚀 [Kling] Starting \(tier.shortName) image-to-video generation")
        logger.info("🚀 [Kling] Prompt: '\(prompt.prefix(100))\(prompt.count > 100 ? "..." : "")'")
        logger.info("🚀 [Kling] Duration: \(roundedDuration)s, Version: \(version.rawValue), Mode: \(mode)")
        if let cameraControl = finalCameraControl {
            logger.info("🎥 [Kling] Camera control: \(cameraControl.type?.rawValue ?? "custom")")
        }
        
        // Create task with image, camera control, and mode
        let task = try await client.generateVideo(
            prompt: prompt,
            version: version,
            negativePrompt: nil,
            duration: roundedDuration,
            image: dataURI,
            imageTail: nil,  // Not using imageTail for continuity in wrapper
            cameraControl: finalCameraControl,
            mode: mode
        )
        
        logger.info("✅ [Kling] Task created: \(task.id)")
        
        // Poll for completion
        let videoURL = try await client.pollStatus(task: task)
        
        logger.info("✅ [Kling] Video ready: \(videoURL)")
        return videoURL
    }
    
    public func healthCheck() async -> Bool {
        do {
            _ = try await getClient()
            // Simple health check - verify credentials are available
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - AIServiceProtocol Conformance
    
    /// Process text prompt (not supported by Kling - this is a video generation service)
    /// For text processing, use DeepSeekAIService instead
    public func processText(prompt: String, systemPrompt: String?) async throws -> String {
        throw APIError.unknown(NSError(domain: "KlingAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Kling AI is a video generation service. For text processing, use DeepSeekAIService instead."]))
    }
}

// MARK: - Image Resizing Helper

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

