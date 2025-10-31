// MODULE: KlingAPIClient
// VERSION: 1.0.0
// PURPOSE: Single source of truth for Kling AI API (v1.6/2.0/2.5)
// PRODUCTION-GRADE: Actor-based, exponential backoff, typed errors

import Foundation

/// Actor-isolated Kling AI API client supporting all versions
public actor KlingAPIClient {
    public static let base = URL(string: "https://api.klingai.com")!
    
    private let apiKey: String
    private let session = URLSession(configuration: .ephemeral)
    private let decoder: JSONDecoder
    
    public init(apiKey: String) {
        self.apiKey = apiKey
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    /// Generate a video using Kling AI
    /// - Parameters:
    ///   - prompt: The video generation prompt
    ///   - version: Kling version to use (1.6/2.0/2.5)
    ///   - negativePrompts: Optional negative prompts (v2.0+ only)
    ///   - duration: Video duration in seconds
    /// - Returns: VideoTask with task ID and status URL
    /// - Throws: KlingError on API failure
    public func generateVideo(
        prompt: String,
        version: KlingVersion,
        negativePrompts: [String]? = nil,
        duration: Int = 5
    ) async throws -> VideoTask {
        let endpoint = version.endpoint
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = VideoRequest(
            prompt: prompt,
            negative_prompt: version.supportsNegative ? negativePrompts : nil,
            duration: min(duration, version.maxSeconds),
            resolution: version.resolution
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        
        let result = try decoder.decode(VideoResponse.self, from: data)
        return VideoTask(id: result.task_id, statusURL: result.status_url)
    }
    
    /// Poll for video generation status with exponential backoff
    /// - Parameters:
    ///   - task: The VideoTask from generateVideo
    ///   - timeout: Maximum time to wait (default 300s)
    /// - Returns: URL to the generated video
    /// - Throws: KlingError on timeout or failure
    public func pollStatus(task: VideoTask, timeout: TimeInterval = 300) async throws -> URL {
        let start = Date()
        var backoff: Double = 1.0
        
        while Date().timeIntervalSince(start) < timeout {
            try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
            
            var request = URLRequest(url: task.statusURL)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await session.data(for: request)
            try validate(response: response)
            
            let status = try decoder.decode(VideoStatus.self, from: data)
            
            switch status.status {
            case "completed":
                guard let videoURL = status.video_url else {
                    throw KlingError.generationFailed("Video URL missing")
                }
                return videoURL
            case "failed":
                throw KlingError.generationFailed(status.error ?? "Unknown error")
            case "processing", "queued":
                backoff = min(backoff * 2, 8.0) // Exponential backoff, max 8s
            default:
                break
            }
        }
        throw KlingError.timeout
    }
    
    /// Validate HTTP response status code
    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw KlingError.invalidResponse
        }
        guard 200..<300 ~= http.statusCode else {
            throw KlingError.httpError(http.statusCode)
        }
    }
}

// MARK: - Request/Response Models

public struct VideoRequest: Codable, Sendable {
    let prompt: String
    let negative_prompt: [String]?
    let duration: Int
    let resolution: String
}

public struct VideoResponse: Codable, Sendable {
    let task_id: String
    let status_url: URL
}

public struct VideoStatus: Codable, Sendable {
    let status: String
    let video_url: URL?
    let error: String?
}

public struct VideoTask: Sendable {
    public let id: String
    public let statusURL: URL
}

// MARK: - Errors

public enum KlingError: LocalizedError, Sendable {
    case invalidResponse
    case httpError(Int)
    case generationFailed(String)
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid API response"
        case .httpError(let code):
            return "HTTP error \(code)"
        case .generationFailed(let message):
            return "Generation failed: \(message)"
        case .timeout:
            return "Generation timeout"
        }
    }
}

