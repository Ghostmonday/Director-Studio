//
//  DeepSeekAIService.swift
//  DirectorStudio
//
//  PURPOSE: DeepSeek AI integration for prompt enhancement
//

import Foundation
import os.log

// MARK: - DeepSeek API Models

struct DeepSeekMessage: Codable {
    let role: String
    let content: String
}

struct DeepSeekRequest: Codable {
    let model: String = "deepseek-chat"
    let messages: [DeepSeekMessage]
    let temperature: Double = 0.7
    let maxTokens: Int = 4096
    let topP: Double = 0.9
    let stream: Bool = false  // Ensure full response
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
        case topP = "top_p"
    }
}

struct DeepSeekResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: DeepSeekMessage
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
}

// MARK: - DeepSeek AI Service

/// DeepSeek AI service for prompt enhancement
public final class DeepSeekAIService: AIServiceProtocol, TextEnhancementProtocol, @unchecked Sendable {
    private let client: APIClientProtocol
    private let logger = Logger(subsystem: "DirectorStudio.API", category: "DeepSeek")
    private let endpoint: String = "https://api.deepseek.com/v1"
    
    // Store API key fetched from Supabase
    private var apiKey: String?
    
    public init(client: APIClientProtocol? = nil) {
        self.client = client ?? APIClient()
    }
    
    public init() {
        self.client = APIClient()
    }
    
    public var isAvailable: Bool {
        // Always available, key fetched on demand
        return true
    }
    
    /// Fetch API key if needed
    private func ensureAPIKey() async throws -> String {
        if let key = apiKey, !key.isEmpty {
            return key
        }
        
        logger.debug("🔑 Fetching DeepSeek API key from Supabase...")
        
        // In dev mode, we still need real API keys to make actual calls
        if CreditsManager.shared.isDevMode {
            logger.debug("🧑‍💻 DEV MODE: Fetching real DeepSeek API key for testing")
        }
        
        do {
            let fetchedKey = try await SupabaseAPIKeyService.shared.getAPIKey(service: "DeepSeek")
            self.apiKey = fetchedKey
            logger.debug("✅ DeepSeek API key fetched successfully")
            return fetchedKey
        } catch let error as APIKeyError {
            logger.error("❌ Failed to fetch DeepSeek API key: \(error.localizedDescription ?? "Unknown error")")
            throw APIError.authError("Failed to fetch DeepSeek API key from Supabase. \(error.localizedDescription ?? "Please verify your API keys are configured in Supabase.")")
        } catch {
            logger.error("❌ Failed to fetch DeepSeek API key: \(error.localizedDescription)")
            throw APIError.authError("Failed to fetch DeepSeek API key: \(error.localizedDescription)")
        }
    }
    
    /// Call DeepSeek API with messages
    public func callAPI(messages: [[String: String]]) async throws -> String {
        let apiKey = try await ensureAPIKey()
        
        let url = URL(string: "\(endpoint)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")  // Space after Bearer!
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let deepMessages = messages.map { DeepSeekMessage(role: $0["role"] ?? "user", content: $0["content"] ?? "") }
        let body = DeepSeekRequest(messages: deepMessages)
        request.httpBody = try JSONEncoder().encode(body)
        
        // Log request
        logger.debug("📤 DeepSeek Request to: \(url)")
        if let bodyData = request.httpBody,
           let bodyString = String(data: bodyData, encoding: .utf8) {
            logger.debug("📤 Request Body: \(bodyString.prefix(500))...")
        }
        
        let response: DeepSeekResponse = try await client.performRequest(request, expectedType: DeepSeekResponse.self)
        
        guard let content = response.choices.first?.message.content else {
            throw APIError.invalidResponse(statusCode: 200, message: "Unexpected response format")
        }
        
        logger.debug("✅ DeepSeek Response: \(content.prefix(200))...")
        
        return content
    }
    
    /// Enhance a prompt for video generation
    /// PASSTHROUGH: No longer enhanced - handled by new Story-to-Film generator
    public func enhancePrompt(prompt: String) async throws -> String {
        logger.debug("🎨 [DeepSeek] Passthrough mode - no enhancement")
        return prompt
    }
    
    /// Protocol requirement - process text with system prompt
    public func processText(prompt: String, systemPrompt: String?) async throws -> String {
        let messages: [[String: String]]
        
        if let systemPrompt = systemPrompt {
            messages = [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ]
        } else {
            messages = [
                ["role": "user", "content": prompt]
            ]
        }
        
        return try await callAPI(messages: messages)
    }
    
    /// Health check
    public func healthCheck() async -> Bool {
        do {
            _ = try await ensureAPIKey()
            return true
        } catch {
            return false
        }
    }
    
    /// Enhanced prompt method with style parameter
    /// PASSTHROUGH: No longer enhanced - handled by new Story-to-Film generator
    public func enhancePrompt(_ prompt: String, style: VideoStyle) async throws -> String {
        logger.debug("🎨 [DeepSeek] Passthrough mode with style: \(style.rawValue)")
        return prompt
    }
    
    /// Extract structured entities (Characters, Scenes, Props) from script
    public func extractEntities(from script: String) async throws -> ExtractedEntities {
        let apiKey = try await ensureAPIKey()
        
        let systemPrompt = """
        You are a script analysis assistant. Extract structured entities from the provided script.
        Return ONLY a JSON object with this exact structure:
        {
            "characters": [
                {
                    "name": "Character Name",
                    "description": "Brief description",
                    "relationships": ["Other Character 1"],
                    "visualDescription": "Detailed visual description for image generation"
                }
            ],
            "scenes": [
                {
                    "name": "Scene Name",
                    "environmentType": "indoor/outdoor/urban/natural",
                    "lighting": "bright/dim/golden hour/night",
                    "mood": "tense/peaceful/energetic/etc",
                    "description": "Brief description",
                    "visualDescription": "Detailed visual description for image generation"
                }
            ],
            "props": [
                {
                    "label": "Prop Name",
                    "category": "weapon/furniture/vehicle/etc",
                    "visualAttributes": ["red", "metallic"],
                    "description": "Brief description"
                }
            ]
        }
        Return only valid JSON, no markdown, no code blocks.
        """
        
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Extract entities from this script:\n\n\(script)"]
        ]
        
        let response = try await callAPI(messages: messages)
        
        // Parse JSON response
        guard let jsonData = response.data(using: .utf8) else {
            throw APIError.invalidResponse(statusCode: 200, message: "Failed to parse JSON")
        }
        
        // Try to extract JSON from markdown code blocks if present
        let cleanJSON: Data
        if let jsonString = extractJSON(from: response) {
            cleanJSON = jsonString.data(using: .utf8) ?? jsonData
        } else {
            cleanJSON = jsonData
        }
        
        do {
            let decoder = JSONDecoder()
            let entities = try decoder.decode(ExtractedEntities.self, from: cleanJSON)
            logger.info("✅ Extracted \(entities.characters.count) characters, \(entities.scenes.count) scenes, \(entities.props.count) props")
            return entities
        } catch {
            logger.error("❌ Failed to parse entities JSON: \(error.localizedDescription)")
            logger.error("Response was: \(response.prefix(500))")
            // Return empty entities rather than throwing
            return ExtractedEntities()
        }
    }
    
    /// Extract JSON from response (handles markdown code blocks)
    private func extractJSON(from response: String) -> String? {
        // Remove markdown code blocks
        var cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find JSON object boundaries
        if let startRange = cleaned.range(of: "{"),
           let endRange = cleaned.range(of: "}", options: .backwards) {
            let jsonRange = startRange.lowerBound...endRange.upperBound
            cleaned = String(cleaned[jsonRange])
        }
        
        return cleaned.isEmpty ? nil : cleaned
    }
}
