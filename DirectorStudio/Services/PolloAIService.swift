//
//  PolloAIService.swift
//  DirectorStudio
//
//  PURPOSE: Pollo AI API integration for video generation
//

import Foundation

/// Pollo AI service implementation
public final class PolloAIService: AIServiceProtocol, VideoGenerationProtocol, @unchecked Sendable {
    private let apiKey: String
    private let endpoint: String
    private let session: URLSession
    
    /// Log to file for persistent debugging
    private func logToFile(_ message: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logPath = documentsPath.appendingPathComponent("pollo_api_log.txt")
        
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)\n"
        
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logPath)
            }
        }
        
        print("📝 Log written to: \(logPath.path)")
    }
    
    public init(apiKey: String? = nil, endpoint: String? = nil) {
        // Get from Info.plist or use provided values
        self.apiKey = apiKey ?? Bundle.main.infoDictionary?["POLLO_API_KEY"] as? String ?? ""
        self.endpoint = endpoint ?? Bundle.main.infoDictionary?["POLLO_API_ENDPOINT"] as? String ?? "https://api.pollo.ai/v1"
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    public var isAvailable: Bool {
        return !apiKey.isEmpty
    }
    
    public func processText(prompt: String, systemPrompt: String?) async throws -> String {
        guard isAvailable else {
            throw PipelineError.configurationError("Pollo API key not configured")
        }
        
        let url = URL(string: "\(endpoint)/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "prompt": prompt,
            "system_prompt": systemPrompt ?? "You are a video generation assistant.",
            "model": "pollo-v1",
            "max_tokens": 2048
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PipelineError.apiError("Pollo API request failed")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["result"] as? String ?? ""
    }
    
    public func generateVideo(prompt: String, duration: TimeInterval) async throws -> URL {
        // COMPREHENSIVE DEBUG LOGGING
        print("\n🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀")
        print("🚀 POLLO VIDEO GENERATION START")
        print("🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀")
        print("📅 Timestamp: \(Date())")
        print("📝 Prompt: \(prompt)")
        print("⏱️ Duration: \(duration) seconds")
        print("💰 Credits: \(CreditsManager.shared.tokens) tokens")
        print("🔧 Dev Mode: \(CreditsManager.shared.isDevMode)")
        // Demo mode removed - all users have full access
        print("🔑 API Key Present: \(!apiKey.isEmpty)")
        print("🌐 Endpoint: \(endpoint)")
        print("🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀🚀\n")
        
        // Log to file for persistence
        logToFile("=== POLLO API REQUEST START ===\nPrompt: \(prompt)\nDuration: \(duration)\n")
        
        // Always use real API - demo mode has been removed
        
        // Fetch API key from Supabase (secure)
        let fetchedKey: String
        if !apiKey.isEmpty {
            // Use local key if available (for dev mode)
            fetchedKey = apiKey
            print("🔑 Using local Pollo key")
        } else {
            // Fetch from Supabase backend
            fetchedKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Pollo")
            print("🔑 Using Supabase Pollo key")
        }
        
        // ✅ FIX 1: Correct endpoint
        let url = URL(string: "https://pollo.ai/api/platform/generation/pollo/pollo-v1-6")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // ✅ FIX 2: Correct header
        request.setValue(fetchedKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // ✅ FIX 3: Correct payload structure
        let body: [String: Any] = [
            "input": [
                "prompt": prompt,
                "resolution": "480p",
                "length": Int(duration)
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // 🔍 DEBUG: Log the full request details
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📤 POLLO API REQUEST:")
        print("   URL: \(url.absoluteString)")
        print("   Method: POST")
        print("   Headers:")
        print("      x-api-key: \(String(fetchedKey.prefix(15)))...")
        print("      Content-Type: application/json")
        print("   Body:")
        print("      input.prompt: \(prompt)")
        print("      input.resolution: 480p")
        print("      input.length: \(Int(duration))")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        let (data, response) = try await session.data(for: request)
        
        // 🔍 DEBUG: Log the response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw PipelineError.apiError("Invalid HTTP response from Pollo")
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📥 POLLO API RESPONSE:")
        print("   Status Code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("   Response Body: \(responseString)")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // ✅ FIX 5: Surface API errors properly
        guard httpResponse.statusCode == 200 else {
            let errorMessage = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String ?? "Unknown error"
            print("❌ Pollo API error - Status: \(httpResponse.statusCode), Message: \(errorMessage)")
            throw PipelineError.apiError("Pollo API error: \(errorMessage)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // ✅ FIX 4: Handle task-based response and poll for status
        if let taskId = json?["data"] as? [String: Any],
           let taskIdString = taskId["taskId"] as? String {
            print("✅ Received taskId: \(taskIdString)")
            print("🔄 Polling for task completion...")
            
            // Poll for task status
            return try await pollTaskStatus(taskId: taskIdString, apiKey: fetchedKey)
        }
        
        // Fallback: try to get video URL directly
        if let videoURLString = json?["video_url"] as? String,
           let videoURL = URL(string: videoURLString) {
            print("✅ Received video URL: \(videoURL.absoluteString)")
            return videoURL
        }
        
        print("❌ No valid taskId or video_url in response")
        throw PipelineError.apiError("Invalid response from Pollo API")
    }
    
    /// ✅ FIX 4: Poll for task status until completion
    private func pollTaskStatus(taskId: String, apiKey: String) async throws -> URL {
        let statusURL = URL(string: "https://pollo.ai/api/platform/generation/task/status/\(taskId)")!
        var attempts = 0
        let maxAttempts = 60 // Maximum 60 checks (5 minutes for 5-second intervals)
        
        while attempts < maxAttempts {
            attempts += 1
            
            var request = URLRequest(url: statusURL)
            request.httpMethod = "GET"
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            print("🔄 Polling attempt \(attempts)/\(maxAttempts)...")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PipelineError.apiError("Invalid HTTP response from Pollo status check")
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Status check error: \(httpResponse.statusCode)")
                throw PipelineError.apiError("Status check failed")
            }
            
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            // Check status
            if let status = json?["data"] as? [String: Any],
               let taskStatus = status["status"] as? String {
                
                print("📊 Task status: \(taskStatus)")
                
                if taskStatus == "finished" || taskStatus == "completed" {
                    // Get the video URL
                    if let videoURLString = status["videoUrl"] as? String,
                       let videoURL = URL(string: videoURLString) {
                        print("✅ Video ready: \(videoURL.absoluteString)")
                        return videoURL
                    }
                    
                    // Try alternative field names
                    if let videoURLString = status["url"] as? String,
                       let videoURL = URL(string: videoURLString) {
                        print("✅ Video ready: \(videoURL.absoluteString)")
                        return videoURL
                    }
                    
                    print("❌ Task completed but no video URL found")
                    throw PipelineError.apiError("Task completed but no video URL")
                }
                
                if taskStatus == "failed" || taskStatus == "error" {
                    let errorMessage = status["error"] as? String ?? "Task failed"
                    print("❌ Task failed: \(errorMessage)")
                    throw PipelineError.apiError("Video generation failed: \(errorMessage)")
                }
                
                // Still processing - wait and retry
                print("⏳ Task still processing, waiting 5 seconds...")
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                continue
            }
            
            print("⚠️ Unexpected response format, retrying...")
            try await Task.sleep(nanoseconds: 5_000_000_000)
        }
        
        throw PipelineError.apiError("Video generation timed out after \(maxAttempts) attempts")
    }
    
    public func healthCheck() async -> Bool {
        do {
            _ = try await processText(prompt: "test", systemPrompt: nil)
            return true
        } catch {
            return false
        }
    }
    
    /// Generate video from an image with animation and motion
    /// - Parameters:
    ///   - imageData: The image data to animate
    ///   - prompt: Description of the video/animation to generate
    ///   - duration: Duration of the video in seconds
    /// - Returns: URL to the generated video
    public func generateVideoFromImage(imageData: Data, prompt: String, duration: TimeInterval = 5.0) async throws -> URL {
        // Always use real API - demo mode has been removed
        
        // Fetch API key from Supabase (secure)
        let fetchedKey: String
        if !apiKey.isEmpty {
            // Use local key if available (for dev mode)
            fetchedKey = apiKey
            print("🔑 Using local Pollo key")
        } else {
            // Fetch from Supabase backend
            fetchedKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "Pollo")
            print("🔑 Using Supabase Pollo key")
        }
        
        // Convert image to base64
        let base64Image = imageData.base64EncodedString()
        
        let url = URL(string: "\(endpoint)/video/image-to-video")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(fetchedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300 // 5 minutes for video generation
        
        let body: [String: Any] = [
            "image": base64Image,
            "prompt": prompt,
            "duration": duration,
            "resolution": "1920x1080",
            "fps": 30,
            "motion_strength": 0.8, // How much motion to add
            "interpolate": true      // Smooth animation
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        print("📤 Sending image-to-video request to Pollo...")
        print("   Prompt: \(prompt)")
        print("   Duration: \(duration)s")
        print("   Image size: \(imageData.count / 1024)KB")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PipelineError.apiError("Invalid response from Pollo")
        }
        
        print("📥 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? String {
                throw PipelineError.apiError("Pollo error: \(errorMessage)")
            }
            throw PipelineError.apiError("Pollo video generation failed with status \(httpResponse.statusCode)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        // Handle both direct URL and polling-based responses
        if let videoURLString = json?["video_url"] as? String,
           let videoURL = URL(string: videoURLString) {
            print("✅ Video generated: \(videoURLString)")
            return videoURL
        } else if let jobId = json?["job_id"] as? String {
            // Poll for completion
            print("⏳ Video generation in progress (job: \(jobId))...")
            return try await pollForVideoCompletion(jobId: jobId)
        } else {
            throw PipelineError.apiError("Invalid response format from Pollo")
        }
    }
    
    /// Poll for video generation completion
    private func pollForVideoCompletion(jobId: String, maxAttempts: Int = 60) async throws -> URL {
        let pollURL = URL(string: "\(endpoint)/video/status/\(jobId)")!
        
        for attempt in 1...maxAttempts {
            var request = URLRequest(url: pollURL)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw PipelineError.apiError("Failed to check video status")
            }
            
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let status = json?["status"] as? String
            
            switch status {
            case "completed":
                if let videoURLString = json?["video_url"] as? String,
                   let videoURL = URL(string: videoURLString) {
                    print("✅ Video generation completed after \(attempt * 5)s")
                    return videoURL
                }
                throw PipelineError.apiError("Video completed but no URL provided")
                
            case "failed":
                let error = json?["error"] as? String ?? "Unknown error"
                throw PipelineError.apiError("Video generation failed: \(error)")
                
            case "processing", "queued":
                print("⏳ Still processing... (\(attempt * 5)s elapsed)")
                try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                continue
                
            default:
                throw PipelineError.apiError("Unknown status: \(status ?? "nil")")
            }
        }
        
        throw PipelineError.apiError("Video generation timed out after \(maxAttempts * 5) seconds")
    }
}
