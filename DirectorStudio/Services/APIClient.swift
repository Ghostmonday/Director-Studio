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
    
    // File logging for debug - readable by agent
    // Write to both Desktop (if accessible) and Documents directory
    private let logFileURLs: [URL] = {
        var urls: [URL] = []
        
        // Try Desktop first (most accessible)
        if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            urls.append(desktop.appendingPathComponent("directorstudio_api_debug.log"))
        }
        
        // Also write to Documents (always accessible)
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            urls.append(documents.appendingPathComponent("api_debug.log"))
        }
        
        return urls
    }()
    
    private func writeToLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        let logLine = "[\(timestamp)] \(message)\n"
        
        guard let data = logLine.data(using: .utf8) else { return }
        
        // Write to all log file locations
        for logFileURL in logFileURLs {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                // Create file if it doesn't exist
                try? data.write(to: logFileURL)
            }
        }
    }
    
    public init(configuration: URLSessionConfiguration = .default) {
        configuration.timeoutIntervalForRequest = 60.0
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)
        
        // Initialize log file
        writeToLog("=== APIClient Started ===")
    }
    
    public func performRequest<T: Codable>(_ request: URLRequest, expectedType: T.Type) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                let urlString = request.url?.absoluteString ?? "unknown"
                logger.debug("🔄 Attempt \(attempt) for \(urlString)")
                writeToLog("🔄 Attempt \(attempt)/\(maxRetries) - \(urlString)")
                
                if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
                    writeToLog("📤 REQUEST BODY:\n\(bodyString)")
                }
                
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse(statusCode: 0, message: nil)
                }
                
                logger.debug("📡 Response Status: \(httpResponse.statusCode)")
                writeToLog("📡 Response Status: \(httpResponse.statusCode), Size: \(data.count) bytes")
                
                // Log response body for debugging - ALWAYS print full response
                if let responseString = String(data: data, encoding: .utf8) {
                    logger.debug("📦 Response Body: \(responseString)")
                    print("📥 [APIClient] Response (\(data.count) bytes): \(responseString)")
                    writeToLog("📥 RESPONSE BODY:\n\(responseString)")
                } else {
                    print("📥 [APIClient] Response (\(data.count) bytes): [NOT UTF-8 ENCODED]")
                    writeToLog("📥 RESPONSE: [NOT UTF-8 ENCODED, \(data.count) bytes]")
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    // Extract error message from response body for better debugging
                    var errorMessage = "HTTP \(httpResponse.statusCode)"
                    if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                        logger.error("❌ HTTP Error \(httpResponse.statusCode): \(responseString.prefix(200))")
                        
                        // Try to parse Pollo API error response structure
                        // PolloErrorResponse is defined in PolloAIService.swift - parse manually here
                        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = json["message"] as? String,
                           let code = json["code"] as? String {
                            var fullMessage = message
                            if let issuesArray = json["issues"] as? [[String: Any]],
                               !issuesArray.isEmpty {
                                let issueMessages = issuesArray.compactMap { $0["message"] as? String }.joined(separator: "; ")
                                if !issueMessages.isEmpty {
                                    fullMessage += " Issues: \(issueMessages)"
                                }
                            }
                            errorMessage = "HTTP \(httpResponse.statusCode): \(fullMessage) (code: \(code))"
                        } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
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
                
                // Check if data is empty before decoding
                guard !data.isEmpty else {
                    logger.error("❌ Empty response data received")
                    throw APIError.invalidResponse(statusCode: httpResponse.statusCode, message: "Empty response from server - Check API endpoint and request format")
                }
                
                // Log the raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    logger.debug("📦 Raw JSON Response: \(responseString)")
                    print("📦 [APIClient] Full Response: \(responseString)")
                }
                
                // Try to decode, but provide better error messages
                do {
                    let decoded = try JSONDecoder().decode(expectedType, from: data)
                    writeToLog("✅ Successfully decoded as \(String(describing: expectedType))")
                    return decoded
                } catch let decodeError as DecodingError {
                    writeToLog("❌ DECODE ERROR: \(decodeError)")
                    
                    // If decoding fails, try to parse as error response (any API error format)
                    // BUT: Check if code is "SUCCESS" - if so, this is a wrapped success response, not an error!
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let code = json["code"] as? String ?? ""
                        let message = json["message"] as? String ?? ""
                        
                        // Don't treat SUCCESS codes as errors!
                        if code.uppercased() == "SUCCESS" {
                            writeToLog("⚠️ Response has code=SUCCESS but failed to decode. This is likely a wrapped response format issue.")
                            writeToLog("⚠️ Full JSON: \(json)")
                        } else if !message.isEmpty {
                            logger.error("❌ API returned error response: \(message) (code: \(code))")
                            print("❌ [APIClient] Error Response: \(json)")
                            writeToLog("❌ API ERROR RESPONSE: message=\(message), code=\(code)")
                            throw APIError.invalidResponse(statusCode: httpResponse.statusCode, message: "API Error: \(message)")
                        }
                    }
                    
                    // Log the actual decoding error details
                    logger.error("❌ Failed to decode as \(expectedType): \(decodeError)")
                    print("❌ [APIClient] Decode Error: \(decodeError)")
                    
                    // Detailed decode error logging
                    if case .keyNotFound(let key, let context) = decodeError {
                        writeToLog("❌ Missing key: '\(key.stringValue)' at \(context.debugDescription)")
                    } else if case .typeMismatch(let type, let context) = decodeError {
                        writeToLog("❌ Type mismatch: expected \(type) at \(context.debugDescription)")
                    } else if case .valueNotFound(let type, let context) = decodeError {
                        writeToLog("❌ Value not found: \(type) at \(context.debugDescription)")
                    } else if case .dataCorrupted(let context) = decodeError {
                        writeToLog("❌ Data corrupted: \(context.debugDescription)")
                    }
                    
                    throw APIError.decodingError(decodeError)
                }
                
            } catch let decodingError as DecodingError {
                lastError = APIError.decodingError(decodingError)
                logger.error("🔍 Decoding Error: \(decodingError)")
                
                // Provide more detailed decoding error information
                if case .dataCorrupted(let context) = decodingError {
                    logger.error("📦 Data corrupted at: \(context.debugDescription)")
                } else if case .keyNotFound(let key, let context) = decodingError {
                    logger.error("🔑 Missing key '\(key.stringValue)' at: \(context.debugDescription)")
                } else if case .typeMismatch(let type, let context) = decodingError {
                    logger.error("⚠️ Type mismatch for \(type) at: \(context.debugDescription)")
                } else if case .valueNotFound(let type, let context) = decodingError {
                    logger.error("❌ Value not found for \(type) at: \(context.debugDescription)")
                }
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
