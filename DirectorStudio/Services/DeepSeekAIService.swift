//
//  DeepSeekAIService.swift
//  DirectorStudio
//
//  PURPOSE: DeepSeek AI API integration for advanced text processing
//

import Foundation

/// DeepSeek AI service implementation
public final class DeepSeekAIService: AIServiceProtocol, TextEnhancementProtocol, @unchecked Sendable {
    private let apiKey: String
    private let endpoint: String
    private let session: URLSession
    
    public init(apiKey: String? = nil, endpoint: String? = nil) {
        // Get from Info.plist or use provided values
        self.apiKey = apiKey ?? Bundle.main.infoDictionary?["DEEPSEEK_API_KEY"] as? String ?? ""
        self.endpoint = endpoint ?? Bundle.main.infoDictionary?["DEEPSEEK_API_ENDPOINT"] as? String ?? "https://api.deepseek.com/v1"
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }
    
    public var isAvailable: Bool {
        return !apiKey.isEmpty
    }
    
    public func processText(prompt: String, systemPrompt: String?) async throws -> String {
        guard isAvailable else {
            throw PipelineError.configurationError("DeepSeek API key not configured")
        }
        
        let url = URL(string: "\(endpoint)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var messages: [[String: String]] = []
        
        if let systemPrompt = systemPrompt {
            messages.append(["role": "system", "content": systemPrompt])
        }
        
        messages.append(["role": "user", "content": prompt])
        
        let body: [String: Any] = [
            "model": "deepseek-chat",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 4096
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // 🔍 DEBUG: Log the full request details
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📤 DEEPSEEK API REQUEST:")
        print("   URL: \(url.absoluteString)")
        print("   Method: POST")
        print("   Headers:")
        print("      Authorization: Bearer \(String(apiKey.prefix(15)))...")
        print("      Content-Type: application/json")
        print("   Body:")
        print("      model: deepseek-chat")
        print("      prompt: \(prompt)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        let (data, response) = try await session.data(for: request)
        
        // 🔍 DEBUG: Log the response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response from DeepSeek")
            throw PipelineError.apiError("Invalid HTTP response from DeepSeek")
        }
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📥 DEEPSEEK API RESPONSE:")
        print("   Status Code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("   Response Body: \(responseString)")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // ✅ Enhanced error handling
        guard httpResponse.statusCode == 200 else {
            let errorMessage = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? [String: Any]
            let errorText = errorMessage?["message"] as? String ?? "Unknown error"
            print("❌ DeepSeek API error - Status: \(httpResponse.statusCode), Message: \(errorText)")
            throw PipelineError.apiError("DeepSeek API error: \(errorText)")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"] as? String ?? ""
        
        print("✅ DeepSeek response received: \(content.prefix(100))...")
        return content
    }
    
    public func analyzeStory(text: String) async throws -> StoryAnalysisOutput {
        let systemPrompt = """
        You are a professional story analyst. Analyze the following story and extract:
        1. Main characters with descriptions
        2. Key themes
        3. Emotional arc
        4. Visual elements
        Return as structured JSON.
        """
        
        let result = try await processText(prompt: text, systemPrompt: systemPrompt)
        
        // Parse JSON response into StoryAnalysisOutput
        // This is simplified - you'd want proper JSON parsing
        return StoryAnalysisOutput(
            themes: [],
            characters: [],
            settings: [],
            emotions: [],
            keyMoments: [],
            tone: "neutral",
            genre: nil
        )
    }
    
    public func enhancePrompt(prompt: String) async throws -> String {
        let style = VideoStyle.cinematic // Default style
        // Always use real API - demo mode has been removed
        
        let systemPrompt = """
        You are a video prompt enhancement expert. Take the user's prompt and enhance it with:
        - Specific visual details
        - Camera movements
        - Lighting descriptions
        - Mood and atmosphere
        Style: \(style.rawValue)
        """
        
        return try await processText(prompt: prompt, systemPrompt: systemPrompt)
    }
    
    public func healthCheck() async -> Bool {
        do {
            _ = try await processText(prompt: "ping", systemPrompt: "Respond with 'pong'")
            return true
        } catch {
            return false
        }
    }
}
