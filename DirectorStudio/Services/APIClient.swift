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
        let requestId = UUID().uuidString.prefix(8)
        let startTime = Date()
        var lastError: Error?
        
        // Log full request details
        let urlString = request.url?.absoluteString ?? "unknown"
        let method = request.httpMethod ?? "GET"
        
        logger.info("🚀 [\(requestId)] API Request Started")
        logger.info("🚀 [\(requestId)] Method: \(method)")
        logger.info("🚀 [\(requestId)] URL: \(urlString)")
        print("🚀 [APIClient][\(requestId)] \(method) \(urlString)")
        writeToLog("🚀 ====== REQUEST START [\(requestId)] ======")
        writeToLog("🚀 [\(requestId)] Method: \(method)")
        writeToLog("🚀 [\(requestId)] URL: \(urlString)")
        
        // Log all headers (except sensitive auth tokens)
        if let headers = request.allHTTPHeaderFields {
            var safeHeaders: [String: String] = [:]
            for (key, value) in headers {
                if key.lowercased().contains("authorization") || key.lowercased().contains("apikey") {
                    safeHeaders[key] = "\(value.prefix(20))...[REDACTED]"
                } else {
                    safeHeaders[key] = value
                }
            }
            logger.debug("🚀 [\(requestId)] Headers: \(safeHeaders)")
            writeToLog("🚀 [\(requestId)] Headers: \(safeHeaders)")
        }
        
        // Log request body
        if let bodyData = request.httpBody {
            let bodySize = bodyData.count
            if let bodyString = String(data: bodyData, encoding: .utf8) {
                // Truncate very large bodies but log first/last 500 chars
                if bodyString.count > 1000 {
                    let truncated = bodyString.prefix(500) + "\n...[TRUNCATED \(bodyString.count - 1000) chars]...\n" + bodyString.suffix(500)
                    logger.debug("🚀 [\(requestId)] Request Body (\(bodySize) bytes): \(truncated)")
                    writeToLog("🚀 [\(requestId)] REQUEST BODY (\(bodySize) bytes):\n\(truncated)")
                } else {
                    logger.debug("🚀 [\(requestId)] Request Body (\(bodySize) bytes): \(bodyString)")
                    writeToLog("🚀 [\(requestId)] REQUEST BODY (\(bodySize) bytes):\n\(bodyString)")
                }
                print("📤 [APIClient][\(requestId)] Request Body (\(bodySize) bytes)")
            } else {
                logger.debug("🚀 [\(requestId)] Request Body (\(bodySize) bytes): [BINARY DATA]")
                writeToLog("🚀 [\(requestId)] REQUEST BODY (\(bodySize) bytes): [BINARY DATA]")
            }
        }
        
        for attempt in 1...maxRetries {
            do {
                let attemptStartTime = Date()
                logger.info("🔄 [\(requestId)] Attempt \(attempt)/\(self.maxRetries)")
                writeToLog("🔄 [\(requestId)] Attempt \(attempt)/\(self.maxRetries)")
                
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    logger.error("❌ [\(requestId)] Invalid HTTP response type")
                    writeToLog("❌ [\(requestId)] Invalid HTTP response type")
                    throw APIError.invalidResponse(statusCode: 0, message: nil)
                }
                
                let attemptDuration = Date().timeIntervalSince(attemptStartTime)
                let totalDuration = Date().timeIntervalSince(startTime)
                
                logger.info("📡 [\(requestId)] Response Status: \(httpResponse.statusCode)")
                logger.info("📡 [\(requestId)] Duration: \(String(format: "%.2f", attemptDuration))s (total: \(String(format: "%.2f", totalDuration))s)")
                logger.info("📡 [\(requestId)] Response Size: \(data.count) bytes")
                
                print("📥 [APIClient][\(requestId)] HTTP \(httpResponse.statusCode) - \(data.count) bytes in \(String(format: "%.2f", attemptDuration))s")
                writeToLog("📡 [\(requestId)] Response Status: \(httpResponse.statusCode)")
                writeToLog("📡 [\(requestId)] Duration: \(String(format: "%.2f", attemptDuration))s (total: \(String(format: "%.2f", totalDuration))s)")
                writeToLog("📡 [\(requestId)] Response Size: \(data.count) bytes")
                
                // Log response headers
                let responseHeaders = httpResponse.allHeaderFields
                logger.debug("📡 [\(requestId)] Response Headers: \(responseHeaders)")
                writeToLog("📡 [\(requestId)] Response Headers: \(responseHeaders)")
                
                // Log response body for debugging - ALWAYS print full response
                if let responseString = String(data: data, encoding: .utf8) {
                    // Truncate very large responses but log first/last 1000 chars
                    if responseString.count > 2000 {
                        let truncated = responseString.prefix(1000) + "\n...[TRUNCATED \(responseString.count - 2000) chars]...\n" + responseString.suffix(1000)
                        logger.debug("📦 [\(requestId)] Response Body (truncated): \(truncated)")
                        print("📥 [APIClient][\(requestId)] Response (\(data.count) bytes, truncated): \(truncated.prefix(500))...")
                        writeToLog("📥 [\(requestId)] RESPONSE BODY (truncated):\n\(truncated)")
                    } else {
                        logger.debug("📦 [\(requestId)] Response Body: \(responseString)")
                        print("📥 [APIClient][\(requestId)] Response (\(data.count) bytes): \(responseString)")
                        writeToLog("📥 [\(requestId)] RESPONSE BODY:\n\(responseString)")
                    }
                } else {
                    logger.warning("📦 [\(requestId)] Response (\(data.count) bytes): [NOT UTF-8 ENCODED]")
                    print("📥 [APIClient][\(requestId)] Response (\(data.count) bytes): [NOT UTF-8 ENCODED]")
                    writeToLog("📥 [\(requestId)] RESPONSE: [NOT UTF-8 ENCODED, \(data.count) bytes]")
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    // Extract error message from response body for better debugging
                    var errorMessage = "HTTP \(httpResponse.statusCode)"
                    if let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
                        logger.error("❌ [\(requestId)] HTTP Error \(httpResponse.statusCode): \(responseString.prefix(500))")
                        writeToLog("❌ [\(requestId)] HTTP ERROR \(httpResponse.statusCode)")
                        writeToLog("❌ [\(requestId)] Error Response: \(responseString)")
                        
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
                
                // Check if data is empty before decoding
                guard !data.isEmpty else {
                    logger.error("❌ [\(requestId)] Empty response data received")
                    writeToLog("❌ [\(requestId)] Empty response data received")
                    throw APIError.invalidResponse(statusCode: httpResponse.statusCode, message: "Empty response from server - Check API endpoint and request format")
                }
                
                // Try to decode, but provide better error messages
                do {
                    let decodeStartTime = Date()
                    let decoded = try JSONDecoder().decode(expectedType, from: data)
                    let decodeDuration = Date().timeIntervalSince(decodeStartTime)
                    
                    let totalDuration = Date().timeIntervalSince(startTime)
                    logger.info("✅ [\(requestId)] Success: Decoded \(String(describing: expectedType)) in \(String(format: "%.3f", decodeDuration))s (total: \(String(format: "%.2f", totalDuration))s)")
                    print("✅ [APIClient][\(requestId)] Success - HTTP \(httpResponse.statusCode), \(data.count) bytes, decoded in \(String(format: "%.3f", decodeDuration))s")
                    writeToLog("✅ [\(requestId)] Successfully decoded as \(String(describing: expectedType))")
                    writeToLog("✅ [\(requestId)] Total request time: \(String(format: "%.2f", totalDuration))s")
                    writeToLog("✅ [\(requestId)] ====== REQUEST COMPLETE ======")
                    return decoded
                } catch let decodeError as DecodingError {
                    logger.error("❌ [\(requestId)] DECODE ERROR: \(decodeError)")
                    print("❌ [APIClient][\(requestId)] Decode Error: \(decodeError)")
                    writeToLog("❌ [\(requestId)] DECODE ERROR: \(decodeError)")
                    
                    // If decoding fails, try to parse as error response (any API error format)
                    // BUT: Check if code is "SUCCESS" - if so, this is a wrapped success response, not an error!
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let code = json["code"] as? String ?? ""
                        let message = json["message"] as? String ?? ""
                        
                        // Don't treat SUCCESS codes as errors!
                        if code.uppercased() == "SUCCESS" {
                            logger.warning("⚠️ [\(requestId)] Response has code=SUCCESS but failed to decode. This is likely a wrapped response format issue.")
                            writeToLog("⚠️ [\(requestId)] Response has code=SUCCESS but failed to decode. This is likely a wrapped response format issue.")
                            writeToLog("⚠️ [\(requestId)] Full JSON: \(json)")
                        } else if !message.isEmpty {
                            logger.error("❌ [\(requestId)] API returned error response: \(message) (code: \(code))")
                            print("❌ [APIClient][\(requestId)] Error Response: \(json)")
                            writeToLog("❌ [\(requestId)] API ERROR RESPONSE: message=\(message), code=\(code)")
                            writeToLog("❌ [\(requestId)] Full error JSON: \(json)")
                            throw APIError.invalidResponse(statusCode: httpResponse.statusCode, message: "API Error: \(message)")
                        }
                    }
                    
                    // Log the actual decoding error details
                    logger.error("❌ [\(requestId)] Failed to decode as \(expectedType): \(decodeError)")
                    
                    // Detailed decode error logging
                    if case .keyNotFound(let key, let context) = decodeError {
                        logger.error("❌ [\(requestId)] Missing key: '\(key.stringValue)' at \(context.debugDescription)")
                        logger.error("❌ [\(requestId)] Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                        writeToLog("❌ [\(requestId)] Missing key: '\(key.stringValue)' at \(context.debugDescription)")
                        writeToLog("❌ [\(requestId)] Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    } else if case .typeMismatch(let type, let context) = decodeError {
                        logger.error("❌ [\(requestId)] Type mismatch: expected \(type) at \(context.debugDescription)")
                        writeToLog("❌ [\(requestId)] Type mismatch: expected \(type) at \(context.debugDescription)")
                        writeToLog("❌ [\(requestId)] Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    } else if case .valueNotFound(let type, let context) = decodeError {
                        logger.error("❌ [\(requestId)] Value not found: \(type) at \(context.debugDescription)")
                        writeToLog("❌ [\(requestId)] Value not found: \(type) at \(context.debugDescription)")
                        writeToLog("❌ [\(requestId)] Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    } else if case .dataCorrupted(let context) = decodeError {
                        logger.error("❌ [\(requestId)] Data corrupted: \(context.debugDescription)")
                        writeToLog("❌ [\(requestId)] Data corrupted: \(context.debugDescription)")
                        writeToLog("❌ [\(requestId)] Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    }
                    
                    writeToLog("❌ [\(requestId)] ====== REQUEST FAILED (DECODE ERROR) ======")
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
                logger.error("🌐 [\(requestId)] Network Error: \(urlError.localizedDescription)")
                logger.error("🌐 [\(requestId)] URLError code: \(urlError.code.rawValue)")
                logger.error("🌐 [\(requestId)] URLError domain: \(urlError.localizedDescription)")
                print("🌐 [APIClient][\(requestId)] Network Error: \(urlError.localizedDescription) (code: \(urlError.code.rawValue))")
                writeToLog("🌐 [\(requestId)] Network Error: \(urlError.localizedDescription)")
                writeToLog("🌐 [\(requestId)] URLError code: \(urlError.code.rawValue)")
                writeToLog("🌐 [\(requestId)] URLError domain: \(urlError.localizedDescription)")
            } catch let apiError as APIError {
                lastError = apiError
                logger.error("❌ [\(requestId)] Attempt \(attempt) failed: \(apiError.localizedDescription)")
                print("❌ [APIClient][\(requestId)] Attempt \(attempt) failed: \(apiError.localizedDescription)")
                writeToLog("❌ [\(requestId)] Attempt \(attempt) failed: \(apiError.localizedDescription)")
            } catch {
                lastError = error
                logger.error("❌ [\(requestId)] Attempt \(attempt) failed: \(error.localizedDescription)")
                logger.error("❌ [\(requestId)] Error type: \(type(of: error))")
                print("❌ [APIClient][\(requestId)] Attempt \(attempt) failed: \(error.localizedDescription)")
                writeToLog("❌ [\(requestId)] Attempt \(attempt) failed: \(error.localizedDescription)")
                writeToLog("❌ [\(requestId)] Error type: \(type(of: error))")
            }
            
            if attempt < maxRetries {
                let delay = baseDelay * pow(2.0, Double(attempt - 1))
                logger.info("⏳ [\(requestId)] Retrying in \(String(format: "%.1f", delay)) seconds...")
                print("⏳ [APIClient][\(requestId)] Retrying in \(String(format: "%.1f", delay))s...")
                writeToLog("⏳ [\(requestId)] Retrying in \(String(format: "%.1f", delay)) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        let totalDuration = Date().timeIntervalSince(startTime)
        logger.error("❌ [\(requestId)] All retry attempts exhausted after \(String(format: "%.2f", totalDuration))s")
        print("❌ [APIClient][\(requestId)] All retries exhausted after \(String(format: "%.2f", totalDuration))s")
        writeToLog("❌ [\(requestId)] All retry attempts exhausted after \(String(format: "%.2f", totalDuration))s")
        writeToLog("❌ [\(requestId)] Final error: \(lastError?.localizedDescription ?? "Unknown")")
        writeToLog("❌ [\(requestId)] ====== REQUEST FAILED (RETRIES EXHAUSTED) ======")
        throw lastError ?? APIError.unknown(NSError(domain: "RetryExhausted", code: 0))
    }
}
