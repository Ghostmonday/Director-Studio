//
//  AIServiceFactory.swift
//  DirectorStudio
//
//  PURPOSE: Factory for creating AI service instances based on configuration
//

import Foundation

public enum AIProvider: String, CaseIterable {
    case mock = "mock"
    case pollo = "pollo"
    case deepseek = "deepseek"
    case openai = "openai"
    case anthropic = "anthropic"
}

public final class AIServiceFactory {
    public static func createService(provider: AIProvider, apiKey: String? = nil) -> AIServiceProtocol {
        switch provider {
        case .mock:
            return MockAIService()
            
        case .pollo:
            return PolloAIService(apiKey: apiKey)
            
        case .deepseek:
            return DeepSeekAIService(apiKey: apiKey)
            
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
        if let polloKey = Bundle.main.infoDictionary?["POLLO_API_KEY"] as? String,
           !polloKey.isEmpty, !polloKey.contains("YOUR_") {
            return PolloAIService(apiKey: polloKey)
        }
        
        if let deepseekKey = Bundle.main.infoDictionary?["DEEPSEEK_API_KEY"] as? String,
           !deepseekKey.isEmpty, !deepseekKey.contains("YOUR_") {
            return DeepSeekAIService(apiKey: deepseekKey)
        }
        
        // Fallback to mock
        print("⚠️ No valid API keys found in configuration. Using mock AI service.")
        return MockAIService()
    }
}
