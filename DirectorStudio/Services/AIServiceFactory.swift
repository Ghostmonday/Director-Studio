// MODULE: AIServiceFactory
// VERSION: 2.0.0
// PURPOSE: Factory for creating AI service instances based on configuration

import Foundation

public enum AIProvider: String, CaseIterable {
    case mock = "mock"
    case pollo = "pollo"
    case deepseek = "deepseek"
    case openai = "openai"
    case anthropic = "anthropic"
}

public final class AIServiceFactory {
    // MARK: - Legacy Support
    
    public static func createService(provider: AIProvider, apiKey: String? = nil) -> AIServiceProtocol {
        switch provider {
        case .mock:
            return MockAIService()
            
        case .pollo:
            return RunwayGen4Service()
            
        case .deepseek:
            return DeepSeekAIService()
            
        case .openai:
            // TODO: Implement OpenAI service
            return MockAIService()
            
        case .anthropic:
            // TODO: Implement Anthropic service
            return MockAIService()
        }
    }
    
    public static func createFromEnvironment() -> AIServiceProtocol {
        // Check which API keys are available
        // Services now fetch keys dynamically from Supabase
        return RunwayGen4Service()
    }
    
    // MARK: - Specialized Service Creation
    
    /// Create a video generation service based on available providers
    public static func createVideoService() -> VideoGenerationProtocol {
        // Using Runway Gen-4 Turbo for video generation
        print("🚀 Using Runway Gen-4 Turbo API for video generation")
        return RunwayGen4Service()
        
        /* OLD CODE - DISABLED FOR DEBUGGING
        // Check for Pollo first (primary video generation service)
        if let polloKey = Bundle.main.infoDictionary?["POLLO_API_KEY"] as? String,
           !polloKey.isEmpty, !polloKey.contains("YOUR_") {
            return PolloAIService(apiKey: polloKey)
        }
        
        // TODO: Add support for other video generation services (Runway, Sora, etc.)
        
        // Fallback to mock for testing
        print("⚠️ No video generation API keys found. Using mock video service.")
        return MockVideoService()
        */
    }
    
    /// Create a text enhancement service based on available providers
    public static func createTextService() -> TextEnhancementProtocol {
        // Check for DeepSeek first (optimized for text)
        // Services now fetch keys dynamically from Supabase
        return DeepSeekAIService()
    }
    
    /// Select optimal service based on task requirements
    public static func selectOptimalService(
        for task: AITask,
        considering factors: Set<ConsiderationFactor> = [.availability, .cost]
    ) -> AIServiceProtocol {
        switch task {
        case .videoGeneration:
            if factors.contains(.cost) {
                // Pollo is cost-effective for video
                if RunwayGen4Service().isAvailable {
                    return RunwayGen4Service()
                }
            }
            // TODO: Add other video services
            
        case .textEnhancement:
            if factors.contains(.quality) {
                // DeepSeek is good for quality text
                if DeepSeekAIService().isAvailable {
                    return DeepSeekAIService()
                }
            }
            // TODO: Add OpenAI/Anthropic
            
        case .imageAnalysis:
            // TODO: Implement image analysis services
            break
        }
        
        // Fallback to any available service
        return createFromEnvironment()
    }
}

// MARK: - Supporting Types

public enum AITask {
    case videoGeneration
    case textEnhancement
    case imageAnalysis
}

public enum ConsiderationFactor {
    case cost
    case speed
    case quality
    case availability
}

// MARK: - Mock Services for Testing

/// Mock video generation service
final class MockVideoService: VideoGenerationProtocol, @unchecked Sendable {
    var isAvailable: Bool { true }
    
    func generateVideo(prompt: String, duration: TimeInterval) async throws -> URL {
        print("⚠️⚠️⚠️ MOCK VIDEO SERVICE BEING USED ⚠️⚠️⚠️")
        print("⚠️ THIS SHOULD NOT HAPPEN - CHECK CONFIGURATION")
        print("⚠️ Prompt was: \(prompt)")
        
        // Simulate processing
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Return sample video URL
        return URL(string: "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4")!
    }
    
    func generateVideoFromImage(imageData: Data, prompt: String, duration: TimeInterval) async throws -> URL {
        // Simulate processing
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        // Return sample video URL
        return URL(string: "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4")!
    }
    
    func healthCheck() async -> Bool {
        return true
    }
}

/// Mock text enhancement service
final class MockTextService: TextEnhancementProtocol, @unchecked Sendable {
    var isAvailable: Bool { true }
    
    func enhancePrompt(prompt: String) async throws -> String {
        // Simple mock enhancement
        return "Enhanced: \(prompt) with cinematic details, vibrant colors, and professional quality."
    }
    
    func processText(prompt: String, systemPrompt: String?) async throws -> String {
        return "Processed: \(prompt)"
    }
    
    func healthCheck() async -> Bool {
        return true
    }
}