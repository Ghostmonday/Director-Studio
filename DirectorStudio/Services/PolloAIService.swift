//
//  PolloAIService.swift
//  DirectorStudio
//
//  PURPOSE: Pollo AI API integration for video generation
//

import Foundation
import os.log

// MARK: - Pollo API Models

struct PolloInput: Codable {
    let prompt: String
    let resolution: String
    let length: Int
    let mode: String
    
    init(prompt: String, resolution: String, length: Int, mode: String = "basic") {
        self.prompt = prompt
        self.resolution = resolution
        self.length = length
        self.mode = mode
    }
}

struct PolloRequest: Codable {
    let input: PolloInput
}

struct PolloResponse: Codable {
    struct Data: Codable {
        let taskId: String
        let status: String  // "waiting"
    }
    let code: String
    let data: Data
}

struct StatusResponse: Codable {
    struct Data: Codable {
        let status: String  // "processing", "succeed", "failed"
        let videoUrl: String?  // On "succeed"
    }
    let code: String
    let data: Data
}

// MARK: - Pollo AI Service

/// Pollo AI service implementation
public final class PolloAIService: AIServiceProtocol, VideoGenerationProtocol, @unchecked Sendable {
    private let client: APIClientProtocol
    private let logger = Logger(subsystem: "DirectorStudio.API", category: "Pollo")
    
    // Store API key fetched from Supabase
    private var apiKey: String?
    
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
        
        do {
            let fetchedKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Pollo")
            self.apiKey = fetchedKey
            logger.debug("✅ Pollo API key fetched successfully")
            return fetchedKey
        } catch {
            logger.error("❌ Failed to fetch Pollo API key: \(error.localizedDescription)")
            throw APIError.authError("Failed to fetch Pollo API key: \(error.localizedDescription)")
        }
    }
    
    public func generateVideo(prompt: String, duration: TimeInterval) async throws -> URL {
        logger.debug("🚀 Starting video generation - Prompt: '\(prompt)', Duration: \(duration)s")
        
        // Ensure we have API key
        let apiKey = try await ensureAPIKey()
        
        // Pollo API only accepts 5 or 10 seconds
        // Enforce strict validation
        let validDuration: Int
        if duration == 5.0 {
            validDuration = 5
        } else if duration == 10.0 {
            validDuration = 10
        } else {
            // Default to 10 seconds if not exactly 5 or 10
            logger.warning("⚠️ Invalid duration \(duration)s requested, defaulting to 10s")
            validDuration = 10
        }
        
        let finalResolution = TestingMode.isEnabled ? "480p" : "480p" // Already using 480p for cost
        
        logger.debug("📊 Final parameters - Duration: \(validDuration)s (requested: \(duration)s), Resolution: \(finalResolution)")
        
        // Create request
        let url = URL(string: "https://pollo.ai/api/platform/generation/pollo/pollo-v1-6")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")  // Case-sensitive!
        
        let body = PolloRequest(input: PolloInput(
            prompt: prompt,
            resolution: finalResolution,
            length: validDuration
        ))
        
        request.httpBody = try JSONEncoder().encode(body)
        
        // Log request details
        logger.debug("📤 Request URL: \(url)")
        logger.debug("📤 Request Headers: x-api-key: \(String(apiKey.prefix(8)))...")
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            logger.debug("📤 Request Body: \(bodyString)")
        }
        
        // Make request
        logger.debug("🔄 Making Pollo API request...")
        
        do {
            let response: PolloResponse = try await client.performRequest(request, expectedType: PolloResponse.self)
            
            guard response.code == "SUCCESS" else {
                logger.error("❌ Pollo API returned code: \(response.code)")
                throw APIError.authError("Pollo API error: \(response.code)")
            }
            
            return try await continueWithValidResponse(response, apiKey: apiKey)
        } catch let error as APIError {
            // Re-throw with more context
            logger.error("❌ Pollo API Error: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("❌ Unexpected error: \(error)")
            throw error
        }
    }
    
    private func continueWithValidResponse(_ response: PolloResponse, apiKey: String) async throws -> URL {
        
        guard response.data.status == "waiting" else {
            logger.error("❌ Unexpected init status: \(response.data.status)")
            throw APIError.authError("Unexpected init status: \(response.data.status)")
        }
        
        logger.debug("✅ Task created: \(response.data.taskId)")
        
        // Poll for completion
        return try await pollForVideo(taskId: response.data.taskId, apiKey: apiKey)
    }
    
    private func pollForVideo(taskId: String, apiKey: String) async throws -> URL {
        let statusURL = URL(string: "https://pollo.ai/api/platform/generation/task/status/\(taskId)")!
        var request = URLRequest(url: statusURL)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let maxAttempts = 60 // 5 minutes max
        var attempts = 0
        
        while attempts < maxAttempts {
            attempts += 1
            logger.debug("🔄 Polling attempt \(attempts)/\(maxAttempts) for task: \(taskId)")
            
            let status: StatusResponse = try await client.performRequest(request, expectedType: StatusResponse.self)
            
            guard status.code == "SUCCESS" else {
                throw APIError.authError("Status check failed: \(status.code)")
            }
            
            switch status.data.status {
            case "succeed":
                guard let videoUrlString = status.data.videoUrl,
                      let videoURL = URL(string: videoUrlString) else {
                    throw APIError.invalidResponse(statusCode: 200)
                }
                logger.debug("✅ Video ready: \(videoURL)")
                return videoURL
                
            case "failed":
                throw APIError.authError("Video generation failed")
                
            case "processing", "waiting":
                logger.debug("⏳ Still processing...")
                try await Task.sleep(nanoseconds: 5_000_000_000)  // 5s delay
                
            default:
                throw APIError.unknown(NSError(domain: "UnknownStatus", code: 0))
            }
        }
        
        throw APIError.unknown(NSError(domain: "PollingTimeout", code: 0))
    }
    
    /// Generate video from an image
    /// - Parameters:
    ///   - imageData: Image data to use as input
    ///   - prompt: Text prompt for generation
    ///   - duration: Duration of the video in seconds
    /// - Returns: URL to the generated video
    public func generateVideoFromImage(imageData: Data, prompt: String, duration: TimeInterval = 5.0) async throws -> URL {
        // For now, just use text-based generation
        // Image-to-video would require different endpoint/params
        logger.warning("⚠️ Image-to-video not implemented, using text-only generation")
        return try await generateVideo(prompt: prompt, duration: duration)
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