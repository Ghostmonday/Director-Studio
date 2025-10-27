// DirectorStudio/Services/APIClient.swift
import Foundation
import os.log

enum APIError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse(statusCode: Int)
    case decodingError(Error)
    case networkError(Error)
    case authError(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let msg): return "Invalid URL: \(msg)"
        case .invalidResponse(let code): return "HTTP \(code): Check API key/endpoint"
        case .decodingError(let err): return "JSON Decode: \(err.localizedDescription)"
        case .networkError(let err): return "Network: \(err.localizedDescription)"
        case .authError(let msg): return "Auth: \(msg)"
        case .unknown(let err): return "Unknown: \(err.localizedDescription)"
        }
    }
}

public protocol APIClientProtocol {
    func performRequest<T: Codable>(_ request: URLRequest, expectedType: T.Type) async throws -> T
}

public class APIClient: APIClientProtocol {
    private let session: URLSession
    private let logger = Logger(subsystem: "DirectorStudio.API", category: "Network")
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 2.0
    
    public init(configuration: URLSessionConfiguration = .default) {
        configuration.timeoutIntervalForRequest = 60.0
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)
    }
    
    public func performRequest<T: Codable>(_ request: URLRequest, expectedType: T.Type) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                logger.debug("🔄 Attempt \(attempt) for \(request.url?.absoluteString ?? "unknown")")
                
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse(statusCode: 0)
                }
                
                logger.debug("📡 Response Status: \(httpResponse.statusCode)")
                
                // Log response body for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    logger.debug("📦 Response Body: \(responseString.prefix(500))...")
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    logger.error("❌ HTTP Error \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 401 {
                        throw APIError.authError("Invalid API key or unauthorized")
                    }
                    throw APIError.invalidResponse(statusCode: httpResponse.statusCode)
                }
                
                logger.debug("✅ Success: \(httpResponse.statusCode) bytes: \(data.count)")
                
                let decoded = try JSONDecoder().decode(expectedType, from: data)
                return decoded
                
            } catch let decodingError as DecodingError {
                lastError = APIError.decodingError(decodingError)
                logger.error("🔍 Decoding Error: \(decodingError)")
            } catch let urlError as URLError {
                lastError = APIError.networkError(urlError)
                logger.error("🌐 Network Error: \(urlError.localizedDescription)")
            } catch {
                lastError = error
                logger.error("❌ Attempt \(attempt) failed: \(error.localizedDescription)")
            }
            
            if attempt < maxRetries {
                let delay = baseDelay * pow(2.0, Double(attempt - 1))
                logger.debug("⏳ Retrying in \(delay) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? APIError.unknown(NSError(domain: "RetryExhausted", code: 0))
    }
}
