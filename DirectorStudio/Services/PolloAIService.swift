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

struct PolloInput: Codable {
    let prompt: String
    let resolution: String
    let length: Int
    let mode: String
    let seed_image: String? // Base64 image data with format prefix
    
    init(prompt: String, resolution: String, length: Int, mode: String = "basic", seedImage: String? = nil) {
        self.prompt = prompt
        self.resolution = resolution
        self.length = length
        self.mode = mode
        self.seed_image = seedImage
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
        
        // Pollo API supports up to 5 seconds per clip (can chain for longer)
        // Enforce strict validation
        let validDuration: Int
        if duration <= 5.0 {
            validDuration = 5
        } else {
            // For longer durations, we'd need to chain multiple 5s clips
            logger.warning("⚠️ Duration \(duration)s > 5s requested, using 5s (chain for longer)")
            validDuration = 5
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
        // Log task ID for recovery
        logTaskID(taskId)
        
        let statusURL = URL(string: "https://pollo.ai/api/platform/generation/task/status/\(taskId)")!
        var request = URLRequest(url: statusURL)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let maxAttempts = 30 // As recommended
        var attempts = 0
        var backoffDelay = 1.0 // Start with 1 second
        
        while attempts < maxAttempts {
            attempts += 1
            logger.debug("🔄 Polling attempt \(attempts)/\(maxAttempts) for task: \(taskId)")
            
            do {
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
        // 1. Scale to Pollo-native 1024x576 (16:9) — NO CROPPING
        let targetSize = CGSize(width: 1024, height: 576)
        let scaled = image.resized(to: targetSize)
        
        // 2. 80% QUALITY JPEG = ~380KB — ZERO quality loss in video
        guard let jpegData = scaled.jpegData(compressionQuality: 0.80) else {
            throw APIError.invalidResponse(statusCode: -1)
        }
        
        // Verify size is under 400KB
        let sizeKB = Double(jpegData.count) / 1024.0
        logger.debug("📸 Compressed seed image: \(String(format: "%.1f", sizeKB))KB")
        
        if jpegData.count > 400_000 {
            logger.warning("⚠️ Compressed image exceeds 400KB: \(sizeKB)KB")
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
    
    /// Generate video from an image
    /// - Parameters:
    ///   - imageData: Image data to use as input
    ///   - prompt: Text prompt for generation
    ///   - duration: Duration of the video in seconds
    /// - Returns: URL to the generated video
    public func generateVideoFromImage(imageData: Data, prompt: String, duration: TimeInterval = 5.0) async throws -> URL {
        logger.debug("🎬 Starting image-to-video generation - Prompt: '\(prompt)', Duration: \(duration)s")
        
        // Ensure we have API key
        let apiKey = try await ensureAPIKey()
        
        // Convert data to UIImage for compression
        guard let image = UIImage(data: imageData) else {
            throw APIError.invalidResponse(statusCode: -1)
        }
        
        // Use perfectSeed to compress and prepare the image
        let seedImageData = try await perfectSeed(image)
        logger.debug("🔗 Seed image prepared as base64")
        
        // Validate duration (5s for chained clips as per user info)
        let validDuration = 5 // Force 5s for chained generation
        logger.debug("📊 Chained generation - Duration: \(validDuration)s, Using seed image")
        
        let finalResolution = TestingMode.isEnabled ? "480p" : "480p"
        
        // Create request with base64 seed image
        let url = URL(string: "https://pollo.ai/api/platform/generation/pollo/pollo-v1-6")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let body = PolloRequest(input: PolloInput(
            prompt: prompt,
            resolution: finalResolution,
            length: validDuration,
            mode: "basic",
            seedImage: seedImageData  // Base64 with data:image/jpeg;base64, prefix
        ))
        
        request.httpBody = try JSONEncoder().encode(body)
        
        logger.debug("📤 Image-to-video request with base64 seed (no upload needed!)")
        
        do {
            let response: PolloResponse = try await client.performRequest(request, expectedType: PolloResponse.self)
            
            guard response.code == "SUCCESS" else {
                logger.error("❌ Pollo API returned code: \(response.code)")
                throw APIError.authError("Pollo API error: \(response.code)")
            }
            
            // Log chain info for recovery
            logChainInfo(seedImage: seedImageData, taskId: response.data.taskId)
            
            return try await continueWithValidResponse(response, apiKey: apiKey)
        } catch let error as APIError {
            logger.error("❌ Pollo API Error: \(error.localizedDescription)")
            throw error
        } catch {
            logger.error("❌ Unexpected error: \(error)")
            throw error
        }
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