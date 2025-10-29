// DirectorStudio/Services/RunwayGen4Service.swift
import Foundation
import os.log
import UIKit

// MARK: - Request/Response Models

struct RunwayGen4Input: Codable {
    let image: String?  // Base64 image data with format prefix "data:image/jpeg;base64,..."
    let prompt: String
    let length: Int
    let aspectRatio: String
    let seed: Int
    
    init(prompt: String, image: String? = nil, length: Int = 5, aspectRatio: String = "16:9", seed: Int? = nil) {
        self.prompt = prompt
        self.image = image
        self.length = length
        self.aspectRatio = aspectRatio
        self.seed = seed ?? Int.random(in: 1...999999)
    }
}

struct RunwayGen4Request: Codable {
    let input: RunwayGen4Input
    let webhookUrl: String?
    
    init(input: RunwayGen4Input, webhookUrl: String? = nil) {
        self.input = input
        self.webhookUrl = webhookUrl ?? "https://placeholder.webhook.com/runway-gen4"
    }
}

struct RunwayGen4Response: Codable {
    let taskId: String
    let status: String  // "waiting"
}

struct RunwayGen4StatusResponse: Codable {
    let code: String?
    let data: StatusData?
    
    struct StatusData: Codable {
        let status: String  // "waiting", "processing", "succeed", "failed"
        let videoUrl: String?
    }
}

struct RunwayGen4Error: Codable {
    let message: String
    let code: String?
    let issues: [Issue]?
    
    struct Issue: Codable {
        let message: String
    }
}

// MARK: - Runway Gen-4 Service

/// Runway Gen-4 Turbo API service implementation
public final class RunwayGen4Service: AIServiceProtocol, VideoGenerationProtocol, @unchecked Sendable {
    private let client: APIClientProtocol
    private let logger = Logger(subsystem: "DirectorStudio.API", category: "RunwayGen4")
    
    // Store API key fetched from Supabase
    private var apiKey: String?
    
    // Task tracking for recovery
    private let taskLogURL: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("runway_gen4_tasks.log")
    }()
    
    // Chain tracking for continuity
    private static var currentChain: String?
    
    // Service availability
    public var isAvailable: Bool {
        return true  // Will check API key when called
    }
    
    public init(client: APIClientProtocol = APIClient()) {
        self.client = client
        logger.debug("🚀 RunwayGen4Service initialized")
    }
    
    // MARK: - API Key Management
    
    private func ensureAPIKey() async throws -> String {
        // Check if we already have a cached key
        if let apiKey = self.apiKey, !apiKey.isEmpty {
            return apiKey
        }
        
        // First, check if user has provided their own Runway API key
        if let userKey = UserAPIKeysManager.shared.getRunwayAPIKey() {
            logger.debug("🔑 Using user-provided Runway API key")
            self.apiKey = userKey
            return userKey
        }
        
        // Fallback to Supabase (if available)
        logger.debug("📱 Fetching API key from Supabase...")
        
        // In dev mode, we still need real API keys to make actual calls
        if CreditsManager.shared.isDevMode {
            logger.debug("🧑‍💻 DEV MODE: Fetching real Runway API key for testing")
        }
        
        do {
            let key = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Runway")
            self.apiKey = key
            logger.debug("✅ API key fetched successfully from Supabase")
            return key
        } catch {
            logger.error("❌ Failed to fetch API key: \(error.localizedDescription)")
            // If Supabase fails and user hasn't provided a key, throw helpful error
            throw APIError.authError("Runway API key not available. Please add your own Runway API key in Settings, or configure Runway key in Supabase.")
        }
    }
    
    // MARK: - Video Generation
    
    public func generateVideo(prompt: String, duration: TimeInterval) async throws -> URL {
        logger.debug("🎬 Starting video generation - Prompt: '\(prompt)', Duration: \(duration)s")
        
        // Ensure we have API key
        let apiKey = try await ensureAPIKey()
        
        // Validate duration (Gen-4 supports various lengths)
        let validDuration = min(max(Int(duration), 5), 10)  // 5-10 seconds
        
        logger.debug("📊 Final parameters - Duration: \(validDuration)s, Aspect Ratio: 16:9")
        
        // Create request
        let url = URL(string: "https://pollo.ai/api/platform/generation/runway/runway-gen-4-turbo")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let input = RunwayGen4Input(prompt: prompt, length: validDuration)
        let body = RunwayGen4Request(input: input)
        
        request.httpBody = try JSONEncoder().encode(body)
        
        // Log request details
        logger.debug("📤 Request URL: \(url)")
        logger.debug("📤 Seed: \(input.seed)")
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            logger.debug("📤 Request Body: \(bodyString)")
        }
        
        // Make request
        logger.debug("🔄 Making Runway Gen-4 API request...")
        
        do {
            let response: RunwayGen4Response = try await client.performRequest(request, expectedType: RunwayGen4Response.self)
            
            logger.debug("✅ Request successful - Task ID: \(response.taskId)")
            logger.debug("📊 Initial status: \(response.status)")
            
            // Poll for completion
            return try await pollForVideo(taskId: response.taskId, apiKey: apiKey)
            
        } catch {
            logger.error("❌ Request failed: \(error.localizedDescription)")
            
            // Try to decode as error response
            if let data = (error as? APIError).flatMap({ _ in request.httpBody }),
               let errorResponse = try? JSONDecoder().decode(RunwayGen4Error.self, from: data) {
                let issues = errorResponse.issues?.map { $0.message }.joined(separator: ", ") ?? ""
                throw APIError.authError("Runway API Error: \(errorResponse.message). Issues: \(issues)")
            }
            
            throw error
        }
    }
    
    private func pollForVideo(taskId: String, apiKey: String) async throws -> URL {
        // Log task ID for recovery
        logTaskID(taskId)
        
        let statusURL = URL(string: "https://pollo.ai/api/platform/generation/task/status/\(taskId)")!
        var request = URLRequest(url: statusURL)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let maxAttempts = 60 // Up to 2 minutes
        var attempts = 0
        var backoffDelay = 1.0 // Start with 1 second
        
        while attempts < maxAttempts {
            attempts += 1
            logger.debug("🔄 Polling attempt \(attempts)/\(maxAttempts) for task: \(taskId)")
            
            do {
                let status: RunwayGen4StatusResponse = try await client.performRequest(request, expectedType: RunwayGen4StatusResponse.self)
                
                guard let data = status.data else {
                    throw APIError.invalidResponse(statusCode: 200, message: "Unexpected response format")
                }
                
                logger.debug("📊 Status: \(data.status)")
                
                switch data.status {
                case "succeed":
                    guard let videoUrlString = data.videoUrl,
                          let videoURL = URL(string: videoUrlString) else {
                        throw APIError.invalidResponse(statusCode: 200, message: "Unexpected response format")
                    }
                    logger.debug("✅ Video ready: \(videoURL)")
                    removeTaskID(taskId) // Clear on success
                    return videoURL
                    
                case "failed":
                    removeTaskID(taskId) // Clear on failure
                    throw APIError.authError("Video generation failed")
                    
                case "processing", "waiting":
                    logger.debug("⏳ Still processing...")
                    // Poll every 2 seconds
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    
                default:
                    throw APIError.unknown(NSError(domain: "UnknownStatus", code: 0))
                }
            } catch let error as APIError {
                // Check for 503 (service unavailable)
                if case .networkError(let underlyingError as NSError) = error,
                   underlyingError.code == 503 {
                    logger.warning("⚠️ 503 Service Unavailable - backing off with exponential delay")
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                    backoffDelay = min(backoffDelay * 2, 60.0) // Double delay, max 60s
                    continue
                }
                throw error
            }
        }
        
        logger.error("❌ Polling timed out after \(maxAttempts) attempts")
        throw APIError.unknown(NSError(domain: "PollingTimeout", code: -1))
    }
    
    // MARK: - Image to Video Generation
    
    /// Generate video from image with Runway Gen-4 Turbo
    public func generateVideoFromImage(imageData: Data, prompt: String, duration: TimeInterval = 5.0) async throws -> URL {
        logger.debug("🎬 Starting image-to-video generation - Prompt: '\(prompt)', Duration: \(duration)s")
        
        // Ensure we have API key
        let apiKey = try await ensureAPIKey()
        
        // Convert data to UIImage for compression
        guard let image = UIImage(data: imageData) else {
            throw APIError.invalidResponse(statusCode: -1, message: "Invalid task ID or status")
        }
        
        // Compress and prepare the image
        let seedImageData = try await perfectSeed(image)
        logger.debug("🔗 Seed image prepared as base64")
        
        // Validate duration
        let validDuration = min(max(Int(duration), 5), 10)  // 5-10 seconds
        logger.debug("📊 Chained generation - Duration: \(validDuration)s, Using seed image")
        
        // Create request with base64 seed image
        let url = URL(string: "https://pollo.ai/api/platform/generation/runway/runway-gen-4-turbo")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let input = RunwayGen4Input(
            prompt: prompt,
            image: seedImageData,  // Base64 with data:image/jpeg;base64, prefix
            length: validDuration
        )
        let body = RunwayGen4Request(input: input)
        
        request.httpBody = try JSONEncoder().encode(body)
        
        logger.debug("📤 Image-to-video request with base64 seed")
        logger.debug("📤 Seed: \(input.seed)")
        
        do {
            let response: RunwayGen4Response = try await client.performRequest(request, expectedType: RunwayGen4Response.self)
            
            logger.debug("✅ Request successful - Task ID: \(response.taskId)")
            
            // Poll for completion
            return try await pollForVideo(taskId: response.taskId, apiKey: apiKey)
            
        } catch {
            logger.error("❌ Image-to-video request failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    /// Perfect seed image compression for Runway API
    private func perfectSeed(_ image: UIImage) async throws -> String {
        logger.debug("🖼️ [PerfectSeed] Starting seed image preparation")
        
        // Target specs for keeping under 600KB
        let targetWidth: CGFloat = 854   // 480p width (16:9)
        let targetHeight: CGFloat = 480  // 480p height
        let targetFileSize: Int = 600 * 1024  // 600KB max
        let targetQuality: CGFloat = 0.8  // 80% quality as requested
        
        // Step 1: Resize to target dimensions
        let resized = await resizeImage(image, targetSize: CGSize(width: targetWidth, height: targetHeight))
        
        // Step 2: Try target quality first
        if let compressed = resized.jpegData(compressionQuality: targetQuality),
           compressed.count <= targetFileSize {
            // Convert to base64 with data URI prefix
            let base64String = compressed.base64EncodedString()
            let dataURI = "data:image/jpeg;base64,\(base64String)"
            logger.debug("✅ [PerfectSeed] Complete - Quality: \(targetQuality), Size: \(compressed.count / 1024)KB")
            return dataURI
        }
        
        // Step 3: If still too large, binary search for optimal compression
        var low: CGFloat = 0.1
        var high: CGFloat = targetQuality
        var bestData: Data?
        var bestQuality: CGFloat = 0.5
        
        while high - low > 0.05 {
            let mid = (low + high) / 2
            
            guard let compressed = resized.jpegData(compressionQuality: mid) else {
                throw NSError(domain: "ImageCompression", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }
            
            if compressed.count <= targetFileSize {
                bestData = compressed
                bestQuality = mid
                low = mid
            } else {
                high = mid
            }
        }
        
        guard let finalData = bestData ?? resized.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "ImageCompression", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create final JPEG"])
        }
        
        // Convert to base64 with data URI prefix
        let base64String = finalData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64String)"
        
        logger.debug("✅ [PerfectSeed] Complete - Quality: \(bestQuality), Size: \(finalData.count / 1024)KB")
        
        return dataURI
    }
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) async -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // MARK: - Task Recovery
    
    private func logTaskID(_ taskId: String) {
        var logs = (try? String(contentsOf: taskLogURL)) ?? ""
        let entry = "\(Date().ISO8601Format()): \(taskId)\n"
        logs.append(entry)
        try? logs.write(to: taskLogURL, atomically: true, encoding: .utf8)
        logger.debug("📝 Logged task ID: \(taskId)")
    }
    
    private func removeTaskID(_ taskId: String) {
        guard var logs = try? String(contentsOf: taskLogURL) else { return }
        logs = logs.components(separatedBy: .newlines)
            .filter { !$0.contains(taskId) }
            .joined(separator: "\n")
        try? logs.write(to: taskLogURL, atomically: true, encoding: .utf8)
        logger.debug("🗑️ Removed task ID: \(taskId)")
    }
    
    // MARK: - Protocol Requirements
    
    public func enhancePrompt(prompt: String) async throws -> String {
        // Gen-4 doesn't need prompt enhancement, it handles cinematic style internally
        return prompt
    }
    
    public func processText(prompt: String, systemPrompt: String?) async throws -> String {
        // Not applicable for video generation
        return prompt
    }
    
    public func healthCheck() async -> Bool {
        do {
            _ = try await ensureAPIKey()
            return true
        } catch {
            return false
        }
    }
    
    public func enhancePrompt(_ prompt: String, style: VideoStyle) async throws -> String {
        // Gen-4 handles styles internally
        return prompt
    }
}
