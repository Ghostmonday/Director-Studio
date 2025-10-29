// DirectorStudio/Services/APIClient.swift
import Foundation
import os.log

enum APIError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case authError(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let msg): return "Invalid URL: \(msg)"
        case .invalidResponse(let code, let message):
            if let message = message {
                return message
            }
            switch code {
            case 400:
                return "API request failed. Please check your API keys in Settings."
            case 401:
                return "Invalid API key. Please verify your API keys are set correctly."
            case 404:
                return "API endpoint not found. The service may be temporarily unavailable."
            case 500...599:
                return "Server error. Please try again later."
            default:
                return "HTTP \(code): Request failed"
            }
        case .decodingError(let err): return "JSON Decode: \(err.localizedDescription)"
        case .networkError(let err): return "Network: \(err.localizedDescription)"
        case .authError(let msg): return "Auth: \(msg)"
        case .unknown(let err): return "Unknown: \(err.localizedDescription)"
        }
    }
    
    /// User-friendly title for error display
    var userFriendlyTitle: String {
        switch self {
        case .invalidResponse(let code, _):
            switch code {
            case 400, 401: return "API Configuration Issue"
            case 404: return "Service Unavailable"
            case 500...599: return "Server Error"
            default: return "Request Failed"
            }
        case .authError: return "Authentication Failed"
        case .networkError: return "Connection Problem"
        default: return "Error"
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
                    throw APIError.invalidResponse(statusCode: 0, message: nil)
                }
                
                logger.debug("📡 Response Status: \(httpResponse.statusCode)")
                
                // Log response body for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    logger.debug("📦 Response Body: \(responseString.prefix(500))...")
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    // Extract error message from response body for better debugging
                    var errorMessage = "HTTP \(httpResponse.statusCode)"
                    if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                        logger.error("❌ HTTP Error \(httpResponse.statusCode): \(responseString.prefix(200))")
                        // Try to extract meaningful error message
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = json["message"] as? String ?? json["error"] as? String {
                            errorMessage = "HTTP \(httpResponse.statusCode): \(message)"
                        } else {
                            errorMessage = "HTTP \(httpResponse.statusCode): \(responseString.prefix(100))"
                        }
                    } else {
                        logger.error("❌ HTTP Error \(httpResponse.statusCode) - No response body")
                    }
                    
                    if httpResponse.statusCode == 401 {
                        throw APIError.authError("Invalid API key or unauthorized")
                    } else if httpResponse.statusCode == 400 {
                        // For 400 errors, provide helpful guidance
                        let helpfulMessage = errorMessage.contains("API key") || errorMessage.contains("endpoint") 
                            ? errorMessage 
                            : "Bad Request - Check API key/endpoint. Verify your API keys are configured in Supabase."
                        throw APIError.invalidResponse(statusCode: httpResponse.statusCode, message: helpfulMessage)
                    }
                    throw APIError.invalidResponse(statusCode: httpResponse.statusCode, message: errorMessage.isEmpty ? nil : errorMessage)
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
