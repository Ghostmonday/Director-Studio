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
}
