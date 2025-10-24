//
//  PolloAIService.swift
//  DirectorStudio
//
//  PURPOSE: Pollo AI API integration for video generation
//

import Foundation

/// Pollo AI service implementation
public final class PolloAIService: AIServiceProtocol, @unchecked Sendable {
    private let apiKey: String
    private let endpoint: String
    private let session: URLSession
    private let isDemoMode: Bool
    
    public init(apiKey: String? = nil, endpoint: String? = nil) {
        // Get from Info.plist or use provided values
        self.apiKey = apiKey ?? Bundle.main.infoDictionary?["POLLO_API_KEY"] as? String ?? ""
        self.endpoint = endpoint ?? Bundle.main.infoDictionary?["POLLO_API_ENDPOINT"] as? String ?? "https://api.pollo.ai/v1"
        
        // Check if we're in demo mode (config or no credits)
        let configDemoMode = Bundle.main.infoDictionary?["DEMO_MODE"] as? String == "YES"
        self.isDemoMode = configDemoMode || CreditsManager.shared.shouldUseDemoMode
        
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
        // Demo mode - return a sample video URL
        if isDemoMode {
            print("🎬 DEMO MODE: Simulating video generation...")
            
            // Simulate processing delay
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Return a sample video URL (you can replace with actual sample video)
            return URL(string: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4")!
        }
        
        guard isAvailable else {
            throw PipelineError.configurationError("Pollo API key not configured")
        }
        
        let url = URL(string: "\(endpoint)/video/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "prompt": prompt,
            "duration": duration,
            "resolution": "1920x1080",
            "fps": 30
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PipelineError.apiError("Pollo video generation failed")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let videoURLString = json?["video_url"] as? String,
              let videoURL = URL(string: videoURLString) else {
            throw PipelineError.apiError("Invalid video URL from Pollo")
        }
        
        return videoURL
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
        // Demo mode - return a sample video URL
        if isDemoMode {
            print("🎬 DEMO MODE: Simulating image-to-video generation...")
            print("   Image size: \(imageData.count / 1024)KB")
            print("   Prompt: \(prompt)")
            
            // Simulate processing delay
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // Return a sample video URL
            return URL(string: "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_2mb.mp4")!
        }
        
        guard isAvailable else {
            throw PipelineError.configurationError("Pollo API key not configured")
        }
        
        // Convert image to base64
        let base64Image = imageData.base64EncodedString()
        
        let url = URL(string: "\(endpoint)/video/image-to-video")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
