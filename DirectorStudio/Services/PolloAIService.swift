//
//  PolloAIService.swift
//  DirectorStudio
//
//  PURPOSE: Pollo AI API integration for video generation
//

import Foundation
import os.log
import UIKit

// MARK: - Image Compression Extension

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

// MARK: - Pollo API Models

/// Pollo 1.6 input structure
struct PolloInput: Codable {
    let prompt: String
    let resolution: String
    let length: Int
    let mode: String
    let image: String? // Base64 image data with format prefix
    let imageTail: String? // Tail image for continuity
    let seed: Int? // Random seed for reproducibility
    
    init(
        prompt: String,
        resolution: String,
        length: Int,
        mode: String = "basic",
        image: String? = nil,
        imageTail: String? = nil,
        seed: Int? = nil
    ) {
        self.prompt = prompt
        self.resolution = resolution
        self.length = length
        self.mode = mode
        self.image = image
        self.imageTail = imageTail
        self.seed = seed
    }
}

/// Kling 1.6 input structure (matches API documentation)
struct KlingInput: Codable {
    let prompt: String
    let length: Int
    let mode: String
    let strength: Int? // Default 50, optional
    let image: String? // Base64 image data with format prefix
    let imageTail: String? // Tail image for continuity
    let negativePrompt: String? // Optional negative prompt
    
    init(
        prompt: String,
        length: Int,
        mode: String = "std",
        strength: Int? = 50,
        image: String? = nil,
        imageTail: String? = nil,
        negativePrompt: String? = nil
    ) {
        self.prompt = prompt
        self.length = length
        self.mode = mode
        self.strength = strength
        self.image = image
        self.imageTail = imageTail
        self.negativePrompt = negativePrompt
    }
}

/// Kling 2.5 Turbo input structure (matches API documentation)
/// Note: Does NOT include `mode` or `imageTail` fields
struct Kling25TurboInput: Codable {
    let prompt: String
    let length: Int
    let strength: Int? // Default 50, optional
    let image: String? // Image URL (HTTPS preferred, no base64)
    let negativePrompt: String? // Optional negative prompt
    
    init(
        prompt: String,
        length: Int,
        strength: Int? = 50,
        image: String? = nil,
        negativePrompt: String? = nil
    ) {
        self.prompt = prompt
        self.length = length
        self.strength = strength
        self.image = image
        self.negativePrompt = negativePrompt
    }
}

/// Pollo 1.6 request wrapper
struct PolloRequest: Codable {
    let input: PolloInput
    let webhookUrl: String? // Optional webhook URL
}

/// Kling 1.6 request wrapper
struct KlingRequest: Codable {
    let input: KlingInput
    let webhookUrl: String? // Optional webhook URL
}

/// Kling 2.5 Turbo request wrapper
struct Kling25TurboRequest: Codable {
    let input: Kling25TurboInput
    let webhookUrl: String? // Optional webhook URL
}

// MARK: - Pollo API Response Models (matching actual API documentation)

/// Successful response from Pollo API (flat structure, no wrapper)
struct PolloResponse: Codable {
    let taskId: String
    let status: String  // "waiting", "processing", "succeed", "failed"
    let videoUrl: String?  // Present when status is "succeed"
}

/// Kling API wrapped response structure (code, message, data)
struct KlingWrappedResponse: Codable {
    let code: String
    let message: String
    let data: PolloResponse  // The actual response data
    
    // Extract the inner response
    var response: PolloResponse {
        return data
    }
}

/// Error response from Pollo API
struct PolloErrorResponse: Codable {
    struct Issue: Codable {
        let message: String
    }
    let message: String
    let code: String
    let issues: [Issue]?
}

// MARK: - Pollo AI Service

/// Pollo AI service implementation
public final class PolloAIService: AIServiceProtocol, VideoGenerationProtocol, @unchecked Sendable {
    private let client: APIClientProtocol
    private let logger = Logger(subsystem: "DirectorStudio.API", category: "Pollo")
    
    // Store API key fetched from Supabase
    private var apiKey: String?
    
    // Task tracking for recovery
    private let taskLogURL: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("pollo_tasks.log")
    }()
    
    // Chain tracking for continuity
    private let chainLogURL: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("chain_log.json")
    }()
    
    public init(client: APIClientProtocol? = nil) {
        self.client = client ?? APIClient()
    }
    
    public init() {
        self.client = APIClient()
    }
    
    public var isAvailable: Bool {
        // Check if we have an API key (will be fetched dynamically)
        return true // Always available, key fetched on demand
    }
    
    /// Fetch API key if needed
    private func ensureAPIKey() async throws -> String {
        if let key = apiKey, !key.isEmpty {
            return key
        }
        
        logger.debug("🔑 Fetching Pollo API key from Supabase...")
        print("🔑 [Pollo] Fetching API key from Supabase...")
        
        // In dev mode, we still need real API keys to make actual calls
        if CreditsManager.shared.isDevMode {
            logger.debug("🧑‍💻 DEV MODE: Fetching real API key for testing")
        }
        
        do {
            let fetchedKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Pollo")
            self.apiKey = fetchedKey
            logger.debug("✅ Pollo API key fetched successfully")
            print("✅ [Pollo] API key fetched successfully: \(fetchedKey.prefix(20))...")
            return fetchedKey
        } catch let error as APIKeyError {
            logger.error("❌ Failed to fetch Pollo API key: \(error.localizedDescription ?? "Unknown error")")
            print("❌ [Pollo] Failed to fetch API key: \(error.localizedDescription ?? "Unknown error")")
            throw APIError.authError("Failed to fetch Pollo API key from Supabase. \(error.localizedDescription ?? "Please verify your API keys are configured in Supabase.")")
        } catch {
            logger.error("❌ Failed to fetch Pollo API key: \(error.localizedDescription)")
            print("❌ [Pollo] Failed to fetch API key: \(error.localizedDescription)")
            throw APIError.authError("Failed to fetch Pollo API key: \(error.localizedDescription)")
        }
    }
    
    /// Generate video with specific quality tier
    /// - Parameters:
    ///   - prompt: Text prompt for video generation
    ///   - duration: Duration in seconds
    ///   - tier: Quality tier (Economy/Basic/Pro)
    ///   - imageTail: Optional last frame from previous video for continuity (for Kling 1.6/Pollo 1.6)
    public func generateVideo(
        prompt: String,
        duration: TimeInterval,
        tier: VideoQualityTier = .basic,
        imageTail: String? = nil
    ) async throws -> URL {
        // Premium tier (Runway Gen-4) requires user's own API key and uses RunwayGen4Service
        if tier == .premium {
            throw APIError.authError("Premium tier (Runway Gen-4) requires your own API key. Please use RunwayGen4Service or add your Runway API key in Settings.")
        }
        
        let operationId = UUID().uuidString.prefix(8)
        let startTime = Date()
        
        logger.info("🚀 [Pollo][\(operationId)] Starting \(tier.shortName) video generation")
        logger.info("🚀 [Pollo][\(operationId)] Prompt: '\(prompt.prefix(100))\(prompt.count > 100 ? "..." : "")'")
        logger.info("🚀 [Pollo][\(operationId)] Duration: \(duration)s, Tier: \(tier.shortName)")
        print("🚀 [Pollo][\(operationId)] Starting \(tier.shortName) generation - Prompt: '\(prompt.prefix(50))...'")
        
        // Ensure we have API key
        logger.debug("🔑 [Pollo][\(operationId)] Fetching API key...")
        let apiKeyFetchStart = Date()
        let apiKey = try await ensureAPIKey()
        let apiKeyFetchDuration = Date().timeIntervalSince(apiKeyFetchStart)
        logger.info("🔑 [Pollo][\(operationId)] API key fetched in \(String(format: "%.3f", apiKeyFetchDuration))s")
        print("🔑 [Pollo][\(operationId)] API key ready (\(apiKey.prefix(20))...)")
        
        // In dev mode, log but still make real API calls
        if CreditsManager.shared.isDevMode {
            logger.debug("🧑‍💻 DEV MODE: Making real API call (no credits charged)")
        }
        
        // Validate and round duration for tier-specific API constraints
        let maxDuration = Double(tier.maxDuration)
        let cappedDuration = min(duration, maxDuration)
        let validDurationSeconds = roundDurationForTier(Int(cappedDuration), tier: tier)
        
        if duration > maxDuration {
            logger.warning("⚠️ Duration \(duration)s exceeds \(tier.shortName) limit of \(maxDuration)s, capped to \(maxDuration)s")
        }
        if Int(cappedDuration) != validDurationSeconds {
            logger.info("📐 Rounded duration from \(Int(cappedDuration))s to \(validDurationSeconds)s (API requirement)")
        }
        
        logger.debug("📊 Using \(tier.modelName) - Duration: \(validDurationSeconds)s, Cost: $\(String(format: "%.2f", Double(validDurationSeconds) * tier.customerPricePerSecond))")
        
        // Create request for specific tier
        let url = URL(string: tier.apiEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        // Build tier-specific request body (with optional imageTail for continuity)
        request.httpBody = try buildRequestBody(for: tier, prompt: prompt, duration: validDurationSeconds, image: nil, imageTail: imageTail)
        
        // Log cost calculation
        let cost = Double(validDurationSeconds) * tier.customerPricePerSecond
        let profit = Double(validDurationSeconds) * (tier.customerPricePerSecond - tier.baseCostPerSecond)
        logger.debug("💰 Customer charge: $\(String(format: "%.2f", cost)), Profit: $\(String(format: "%.2f", profit))")
        
        // Make request
        logger.info("🔄 [Pollo][\(operationId)] Making \(tier.modelName) API request")
        logger.info("🔄 [Pollo][\(operationId)] Endpoint: \(url.absoluteString)")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            logger.debug("📋 [Pollo][\(operationId)] Request body (\(bodyData.count) bytes): \(bodyString.prefix(500))\(bodyString.count > 500 ? "..." : "")")
            print("📤 [Pollo][\(operationId)] Request Body (\(bodyData.count) bytes)")
        }
        logger.debug("🔑 [Pollo][\(operationId)] API Key present: \(!apiKey.isEmpty)")
        
        let apiCallStart = Date()
        do {
            // All Kling APIs (1.6 and 2.5 Turbo) return wrapped response structure
            // Pollo 1.6 returns flat structure
            let response: PolloResponse
            if tier == .economy || tier == .pro {
                // Kling 1.6 and 2.5 Turbo use wrapped format: {code, message, data: {taskId, status}}
                logger.info("📥 [Pollo][\(operationId)] Calling Kling API (wrapped format)")
                let wrappedResponse: KlingWrappedResponse = try await client.performRequest(request, expectedType: KlingWrappedResponse.self)
                
                let apiCallDuration = Date().timeIntervalSince(apiCallStart)
                logger.info("📥 [Pollo][\(operationId)] API call completed in \(String(format: "%.2f", apiCallDuration))s")
                print("📥 [Pollo][\(operationId)] API response received in \(String(format: "%.2f", apiCallDuration))s")
                
                // Check if wrapper indicates success
                guard wrappedResponse.code.uppercased() == "SUCCESS" else {
                    logger.error("❌ [Pollo][\(operationId)] \(tier.modelName) API returned error code: \(wrappedResponse.code)")
                    logger.error("❌ [Pollo][\(operationId)] Error message: \(wrappedResponse.message)")
                    print("❌ [Pollo][\(operationId)] API Error: \(wrappedResponse.code) - \(wrappedResponse.message)")
                    throw APIError.authError("\(tier.modelName) API error: \(wrappedResponse.message)")
                }
                
                response = wrappedResponse.response
                logger.info("✅ [Pollo][\(operationId)] Extracted response: taskId=\(response.taskId), status=\(response.status)")
                print("✅ [Pollo][\(operationId)] Task created: \(response.taskId)")
            } else {
                // Pollo 1.6 uses flat format: {taskId, status}
                logger.info("📥 [Pollo][\(operationId)] Calling Pollo API (flat format)")
                response = try await client.performRequest(request, expectedType: PolloResponse.self)
                
                let apiCallDuration = Date().timeIntervalSince(apiCallStart)
                logger.info("📥 [Pollo][\(operationId)] API call completed in \(String(format: "%.2f", apiCallDuration))s")
                print("📥 [Pollo][\(operationId)] API response received in \(String(format: "%.2f", apiCallDuration))s")
            }
            
            // Check if response indicates error status
            guard response.status != "failed" else {
                logger.error("❌ [Pollo][\(operationId)] \(tier.modelName) API returned failed status")
                throw APIError.authError("\(tier.modelName) API error: Video generation failed")
            }
            
            // Accept both "waiting" and "processing" as valid initial statuses
            guard response.status == "waiting" || response.status == "processing" else {
                logger.error("❌ [Pollo][\(operationId)] Unexpected init status: '\(response.status)'")
                logger.error("❌ [Pollo][\(operationId)] Expected: 'waiting' or 'processing', got: '\(response.status)'")
                print("❌ [Pollo][\(operationId)] Unexpected status: '\(response.status)'")
                throw APIError.authError("Unexpected init status: \(response.status)")
            }
            
            logger.info("✅ [Pollo][\(operationId)] Task created successfully with status: '\(response.status)'")
            return try await continueWithValidResponse(response, apiKey: apiKey)
        } catch let error as APIError {
            let totalDuration = Date().timeIntervalSince(startTime)
            logger.error("❌ [Pollo][\(operationId)] \(tier.shortName) (\(tier.modelName)) generation failed after \(String(format: "%.2f", totalDuration))s")
            logger.error("❌ [Pollo][\(operationId)] Error: \(error.localizedDescription ?? "Unknown")")
            print("❌ [Pollo][\(operationId)] Generation failed: \(error.localizedDescription ?? "Unknown")")
            
            // Provide specific guidance based on error type
            switch error {
            case .decodingError:
                logger.error("💡 [Pollo][\(operationId)] Decoding error - Check: Response format matches expected structure")
                logger.error("💡 [Pollo][\(operationId)] Endpoint: \(tier.apiEndpoint)")
                if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
                    logger.error("💡 [Pollo][\(operationId)] Request body: \(bodyString.prefix(200))")
                }
            case .invalidResponse(let code, let message):
                logger.error("💡 [Pollo][\(operationId)] HTTP \(code) - \(message ?? "No message")")
                logger.error("💡 [Pollo][\(operationId)] Check: 1) API key fetched from Supabase, 2) Endpoint URL correct, 3) Request body format valid")
            case .authError(let msg):
                logger.error("💡 Auth Error: \(msg)")
            default:
                break
            }
            throw error
        } catch {
            logger.error("❌ Unexpected error in \(tier.modelName): \(error)")
            throw APIError.unknown(error)
        }
    }
    
    /// Round duration to API-supported values for each tier
    /// - Pollo 1.6 (Basic): Only accepts 5 or 10 seconds
    /// - Kling 1.6 (Economy): Accepts 5 or 10 seconds
    /// - Kling 2.5 Turbo (Pro): Accepts 5 or 10 seconds
    private func roundDurationForTier(_ duration: Int, tier: VideoQualityTier) -> Int {
        switch tier {
        case .basic, .economy, .pro:
            // All these APIs only accept 5 or 10 seconds
            // Round to nearest valid value
            if duration <= 5 {
                return 5
            } else if duration <= 10 {
                return 10
            } else {
                // Cap at 10 if exceeds
                return 10
            }
        case .premium:
            // Runway accepts more values, but we don't handle it here
            return duration
        }
    }
    
    /// Build tier-specific request body matching API format (Pollo 1.6 or Kling 1.6)
    private func buildRequestBody(
        for tier: VideoQualityTier,
        prompt: String,
        duration: Int,
        image: String? = nil,
        imageTail: String? = nil,
        seed: Int? = nil
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        
        switch tier {
        case .economy:
            // Kling 1.6 (Economy tier) - matches API documentation
            // Build input dictionary manually to ensure correct field ordering and omit nil values
            var inputDict: [String: Any] = [
                "prompt": prompt,
                "length": duration,
                "mode": "std",
                "strength": 50
            ]
            
            // Only add optional fields if they have values
            if let image = image {
                inputDict["image"] = image
            }
            if let imageTail = imageTail {
                inputDict["imageTail"] = imageTail
            }
            // negativePrompt is omitted if nil
            
            let requestDict: [String: Any] = ["input": inputDict]
            // webhookUrl omitted if nil
            
            // Convert to JSON Data
            let jsonData = try JSONSerialization.data(withJSONObject: requestDict, options: [.prettyPrinted])
            logger.debug("📋 Kling 1.6 Request JSON: \(String(data: jsonData, encoding: .utf8) ?? "nil")")
            return jsonData
            
        case .pro:
            // Kling 2.5 Turbo - matches API documentation
            // Note: NO mode or imageTail fields for 2.5 Turbo
            let kling25Input = Kling25TurboInput(
                prompt: prompt,
                length: duration,
                strength: 50,
                image: image,
                negativePrompt: nil
            )
            let kling25Request = Kling25TurboRequest(input: kling25Input, webhookUrl: nil)
            return try encoder.encode(kling25Request)
            
        case .basic:
            // Pollo 1.6 model - correct format
            let polloInput = PolloInput(
                prompt: prompt,
                resolution: "480p",
                length: duration,
                mode: "basic",
                image: image,
                imageTail: imageTail,
                seed: seed
            )
            let polloRequest = PolloRequest(input: polloInput, webhookUrl: nil)
            return try encoder.encode(polloRequest)
            
        case .premium:
            // Premium tier should not reach here - it uses RunwayGen4Service
            throw APIError.authError("Premium tier requires RunwayGen4Service with user's own API key")
        }
    }
    
    // Keep existing method for backward compatibility
    public func generateVideo(prompt: String, duration: TimeInterval) async throws -> URL {
        // Default to Basic tier for backward compatibility
        return try await generateVideo(prompt: prompt, duration: duration, tier: .basic)
    }
    
    private func continueWithValidResponse(_ response: PolloResponse, apiKey: String) async throws -> URL {
        
        // Accept both "waiting" and "processing" as valid initial statuses
        guard response.status == "waiting" || response.status == "processing" else {
            logger.error("❌ Unexpected init status: '\(response.status)' (expected 'waiting' or 'processing')")
            throw APIError.authError("Unexpected init status: \(response.status)")
        }
        
        logger.debug("✅ Task created: \(response.taskId) with status: \(response.status)")
        
        // Poll for completion
        return try await pollForVideo(taskId: response.taskId, apiKey: apiKey)
    }
    
    private func pollForVideo(taskId: String, apiKey: String) async throws -> URL {
        // Log task ID for recovery
        logTaskID(taskId)
        
        let statusURL = URL(string: "https://pollo.ai/api/platform/generation/task/status/\(taskId)")!
        var request = URLRequest(url: statusURL)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let maxAttempts = 60 // Increased for longer generations (up to 2 minutes)
        var attempts = 0
        var backoffDelay = 1.0 // Start with 1 second
        
        while attempts < maxAttempts {
            attempts += 1
            logger.debug("🔄 Polling attempt \(attempts)/\(maxAttempts) for task: \(taskId)")
            
            do {
                // For status polling, we need to handle wrapped vs flat responses
                // Try wrapped first (Kling format), then fall back to flat (Pollo format)
                let status: PolloResponse
                if let wrapped: KlingWrappedResponse = try? await client.performRequest(request, expectedType: KlingWrappedResponse.self) {
                    status = wrapped.response
                } else {
                    status = try await client.performRequest(request, expectedType: PolloResponse.self)
                }
                
                switch status.status {
                case "succeed":
                    guard let videoUrlString = status.videoUrl,
                          let videoURL = URL(string: videoUrlString) else {
                        throw APIError.invalidResponse(statusCode: 200, message: "Unexpected response format - missing videoUrl")
                    }
                    logger.debug("✅ Video ready: \(videoURL)")
                    removeTaskID(taskId) // Clear on success
                    return videoURL
                    
                case "failed":
                    removeTaskID(taskId) // Clear on failure
                    throw APIError.authError("Video generation failed")
                    
                case "processing", "waiting":
                    logger.debug("⏳ Still processing... (40-50s typical)")
                    // Poll every 2 seconds as recommended
                    try await Task.sleep(nanoseconds: 2_000_000_000)  // 2s delay
                    
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
        
        throw APIError.unknown(NSError(domain: "PollingTimeout", code: 0))
    }
    
    // MARK: - Seed Image Compression & Upload
    
    /// Compress seed image for optimal Pollo performance
    /// - Parameter image: UIImage to use as seed
    /// - Returns: Base64 encoded image with data URI prefix
    private func perfectSeed(_ image: UIImage) async throws -> String {
        // 1. Scale to 480p (16:9) for consistent sizing across services
        let targetSize = CGSize(width: 854, height: 480)
        let scaled = image.resized(to: targetSize)
        
        // 2. 80% QUALITY JPEG - targeting under 600KB
        guard let jpegData = scaled.jpegData(compressionQuality: 0.80) else {
            throw APIError.invalidResponse(statusCode: -1, message: "Invalid task ID or status")
        }
        
        // Verify size is under 600KB
        let sizeKB = Double(jpegData.count) / 1024.0
        logger.debug("📸 Compressed seed image: \(String(format: "%.1f", sizeKB))KB")
        
        if jpegData.count > 600_000 {
            logger.warning("⚠️ Compressed image exceeds 600KB: \(sizeKB)KB")
            // Try lower quality if needed
            if let lowerQualityData = scaled.jpegData(compressionQuality: 0.60),
               lowerQualityData.count <= 600_000 {
                let base64String = lowerQualityData.base64EncodedString()
                let dataURI = "data:image/jpeg;base64,\(base64String)"
                logger.debug("✅ Recompressed to 60% quality: \(Double(lowerQualityData.count) / 1024.0)KB")
                return dataURI
            }
        }
        
        // 3. Convert to base64 with data URI prefix
        let base64String = jpegData.base64EncodedString()
        let dataURI = "data:image/jpeg;base64,\(base64String)"
        
        logger.debug("✅ Seed image compressed to base64 (no network needed!)")
        
        return dataURI
    }
    
    /// Log chain information for recovery
    private func logChainInfo(seedImage: String, taskId: String) {
        struct ChainEntry: Codable {
            let timestamp: Date
            let seedImageSize: Int  // Store size instead of full base64
            let taskId: String
        }
        
        do {
            var entries: [ChainEntry] = []
            
            // Load existing entries if file exists
            if FileManager.default.fileExists(atPath: chainLogURL.path) {
                let data = try Data(contentsOf: chainLogURL)
                entries = try JSONDecoder().decode([ChainEntry].self, from: data)
            }
            
            // Add new entry (store size for logging, not full base64)
            let seedSize = seedImage.count
            entries.append(ChainEntry(timestamp: Date(), seedImageSize: seedSize, taskId: taskId))
            
            // Save back
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entries)
            try data.write(to: chainLogURL)
            
            logger.debug("📝 Logged chain info - Seed size: \(seedSize) bytes, Task: \(taskId)")
        } catch {
            logger.warning("⚠️ Failed to log chain info: \(error)")
        }
    }
    
    // MARK: - Task ID Management
    
    private func logTaskID(_ taskId: String) {
        do {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let entry = "\(timestamp)\t\(taskId)\tpending\n"
            
            if FileManager.default.fileExists(atPath: taskLogURL.path) {
                let fileHandle = try FileHandle(forWritingTo: taskLogURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(entry.data(using: .utf8)!)
                fileHandle.closeFile()
            } else {
                try entry.write(to: taskLogURL, atomically: true, encoding: .utf8)
            }
            logger.debug("📝 Logged task ID: \(taskId)")
        } catch {
            logger.warning("⚠️ Failed to log task ID: \(error)")
        }
    }
    
    private func removeTaskID(_ taskId: String) {
        do {
            guard FileManager.default.fileExists(atPath: taskLogURL.path) else { return }
            
            let content = try String(contentsOf: taskLogURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            let filteredLines = lines.filter { !$0.contains(taskId) }
            let newContent = filteredLines.joined(separator: "\n")
            try newContent.write(to: taskLogURL, atomically: true, encoding: .utf8)
            
            logger.debug("✅ Removed completed task ID: \(taskId)")
        } catch {
            logger.warning("⚠️ Failed to remove task ID: \(error)")
        }
    }
    
    /// Get pending tasks for recovery
    private func getPendingTasks() -> [String] {
        do {
            guard FileManager.default.fileExists(atPath: taskLogURL.path) else { return [] }
            
            let content = try String(contentsOf: taskLogURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            var pendingTasks: [String] = []
            for line in lines where line.contains("pending") {
                let parts = line.components(separatedBy: "\t")
                if parts.count >= 3 {
                    pendingTasks.append(parts[1])
                }
            }
            
            return pendingTasks
        } catch {
            logger.warning("⚠️ Failed to read pending tasks: \(error)")
            return []
        }
    }
    
    /// Generate video from an image with specific quality tier
    /// - Parameters:
    ///   - imageData: Seed image data (first frame or continuity frame)
    ///   - prompt: Text prompt for video generation
    ///   - duration: Duration in seconds
    ///   - tier: Quality tier (Economy/Basic/Pro)
    ///   - imageTail: Optional last frame from previous video for continuity (for Kling 1.6/Pollo 1.6)
    public func generateVideoFromImage(
        imageData: Data,
        prompt: String,
        duration: TimeInterval = 5.0,
        tier: VideoQualityTier = .basic,
        imageTail: String? = nil
    ) async throws -> URL {
        logger.debug("🎬 Starting \(tier.shortName) image-to-video generation - Prompt: '\(prompt)', Duration: \(duration)s")
        
        // Ensure we have API key
        let apiKey = try await ensureAPIKey()
        
        // In dev mode, log but still make real API calls
        if CreditsManager.shared.isDevMode {
            logger.debug("🧑‍💻 DEV MODE: Making real image-to-video API call (no credits charged)")
        }
        
        // Convert data to UIImage for compression
        guard let image = UIImage(data: imageData) else {
            throw APIError.invalidResponse(statusCode: -1, message: "Invalid task ID or status")
        }
        
        // Use perfectSeed to compress and prepare the image
        let seedImageData = try await perfectSeed(image)
        logger.debug("🔗 Seed image prepared as base64")
        
        // Validate and round duration for tier-specific API constraints
        let maxDuration = Double(tier.maxDuration)
        let cappedDuration = min(duration, maxDuration)
        let validDurationSeconds = roundDurationForTier(Int(cappedDuration), tier: tier)
        
        if duration > maxDuration {
            logger.warning("⚠️ Duration \(duration)s exceeds \(tier.shortName) limit of \(maxDuration)s, capped to \(maxDuration)s")
        }
        if Int(cappedDuration) != validDurationSeconds {
            logger.info("📐 Rounded duration from \(Int(cappedDuration))s to \(validDurationSeconds)s (API requirement)")
        }
        
        logger.debug("📊 Using \(tier.modelName) - Duration: \(validDurationSeconds)s, With seed image")
        
        // Create request for specific tier
        let url = URL(string: tier.apiEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        // Build tier-specific request body with image and optional imageTail
        // For Kling 2.5 Turbo (Pro tier), imageTail parameter is ignored (not supported by API)
        // seedImageData IS the last frame from previous video (passed for continuity)
        let finalImage: String?
        let finalImageTail: String?
        
        if tier == .pro {
            // Kling 2.5 Turbo doesn't support imageTail - use seedImageData (last frame) as image for continuity
            finalImage = seedImageData // Last frame from previous video
            finalImageTail = nil // Not supported by API
            logger.debug("🔄 Kling 2.5 Turbo: Using last frame as image (continuity mode)")
        } else {
            // For Kling 1.6 and Pollo 1.6, use seedImageData as seed image and imageTail for last frame continuity
            finalImage = seedImageData // Seed/first frame
            finalImageTail = imageTail // Last frame from previous video (for continuity)
            if imageTail != nil {
                logger.debug("🔗 Using imageTail for continuity (last frame from previous video)")
            }
        }
        
        request.httpBody = try buildRequestBody(for: tier, prompt: prompt, duration: validDurationSeconds, image: finalImage, imageTail: finalImageTail)
        
        // Log cost calculation
        let cost = Double(validDurationSeconds) * tier.customerPricePerSecond
        let profit = Double(validDurationSeconds) * (tier.customerPricePerSecond - tier.baseCostPerSecond)
        logger.debug("💰 Customer charge: $\(String(format: "%.2f", cost)), Profit: $\(String(format: "%.2f", profit))")
        
        logger.debug("📤 Image-to-video request with base64 seed (no upload needed!)")
        
        do {
            // Handle wrapped response format for Kling APIs
            let response: PolloResponse
            if let wrapped: KlingWrappedResponse = try? await client.performRequest(request, expectedType: KlingWrappedResponse.self) {
                response = wrapped.response
            } else {
                response = try await client.performRequest(request, expectedType: PolloResponse.self)
            }
            
            // Check if response indicates error status
            guard response.status != "failed" else {
                logger.error("❌ Pollo API returned failed status")
                throw APIError.authError("Pollo API error: Video generation failed")
            }
            
            // Accept both "waiting" and "processing" as valid initial statuses
            guard response.status == "waiting" || response.status == "processing" else {
                logger.error("❌ Unexpected init status: '\(response.status)' (expected 'waiting' or 'processing')")
                throw APIError.authError("Unexpected init status: \(response.status)")
            }
            
            // Log chain info for recovery
            logChainInfo(seedImage: seedImageData, taskId: response.taskId)
            
            return try await continueWithValidResponse(response, apiKey: apiKey)
        } catch let error as APIError {
            logger.error("❌ Pollo API Error: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("❌ Unexpected error: \(error)")
            throw error
        }
    }
    
    // Keep existing method for backward compatibility
    public func generateVideoFromImage(imageData: Data, prompt: String, duration: TimeInterval = 5.0) async throws -> URL {
        // Default to Basic tier for backward compatibility
        return try await generateVideoFromImage(imageData: imageData, prompt: prompt, duration: duration, tier: .basic)
    }
    
    // MARK: - Protocol Requirements
    
    public func processText(prompt: String, systemPrompt: String?) async throws -> String {
        // Pollo doesn't process text - it's a video generation service
        throw APIError.unknown(NSError(domain: "NotSupported", code: 0))
    }
    
    public func healthCheck() async -> Bool {
        // Simple health check - try to ensure API key
        do {
            _ = try await ensureAPIKey()
            return true
        } catch {
            return false
        }
    }
}