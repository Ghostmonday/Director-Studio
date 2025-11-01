// MODULE: KlingAPIClient
// VERSION: 3.0.0
// PURPOSE: Single source of truth for Kling AI API (direct native API, v1.6/2.0/2.5)
// PRODUCTION-GRADE: Actor-based, exponential backoff, typed errors, JWT authentication, Kling-native format

import Foundation
import CryptoKit
#if canImport(UIKit)
import UIKit
#endif

/// Actor-isolated Kling AI API client supporting all versions via direct Kling API
/// Uses direct Kling endpoints: POST /v1/videos/text2video
/// Authentication: JWT tokens (HS256) generated from AccessKey + SecretKey
public actor KlingAPIClient {
    private let accessKey: String
    private let secretKey: String
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // Cached JWT token (valid 30 mins, regenerated when needed)
    private var cachedToken: String?
    private var tokenExpiry: Date?
    
    // File logging for debug - readable by agent (same as APIClient)
    private let logFileURLs: [URL] = {
        var urls: [URL] = []
        if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            urls.append(desktop.appendingPathComponent("directorstudio_api_debug.log"))
        }
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            urls.append(documents.appendingPathComponent("api_debug.log"))
        }
        return urls
    }()
    
    nonisolated private func writeToLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        let logLine = "[\(timestamp)] [KlingAPIClient] \(message)\n"
        
        guard let data = logLine.data(using: .utf8) else { return }
        
        for logFileURL in logFileURLs {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
    
    /// Parse error response and throw specific KlingError
    /// Detects Error 1102 (resource pack depleted) and throws resourcePackDepleted error
    private func handleKlingError(_ data: Data, requestId: String) throws {
        // Try to decode as JSON and check for error code 1102
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let code = json["code"] as? Int, code == 1102 {
            writeToLog("❌ [\(requestId)] Error 1102 detected: Resource pack depleted")
            throw KlingError.resourcePackDepleted
        }
        
        // Try to decode using KlingErrorResponse struct
        if let errorResponse = try? decoder.decode(KlingErrorResponse.self, from: data),
           errorResponse.code == 1102 {
            writeToLog("❌ [\(requestId)] Error 1102 detected: Resource pack depleted")
            throw KlingError.resourcePackDepleted
        }
    }
    
    /// Initialize with AccessKey and SecretKey for JWT authentication
    /// - Parameters:
    ///   - accessKey: Kling AI AccessKey (issuer in JWT)
    ///   - secretKey: Kling AI SecretKey (for HMAC-SHA256 signing)
    public init(accessKey: String, secretKey: String) {
        // Configure URLSession with proper timeouts
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30.0  // 30 second request timeout
        config.timeoutIntervalForResource = 60.0  // 60 second resource timeout
        self.session = URLSession(configuration: config)
        self.accessKey = accessKey
        self.secretKey = secretKey
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        writeToLog("🚀 KlingAPIClient initialized with AccessKey: \(accessKey.prefix(8))...")
    }
    
    /// Generate JWT token for authentication (valid 30 mins)
    /// Uses HS256 algorithm with AccessKey as issuer and SecretKey for signing
    private func generateJWT() throws -> String {
        let now = Date()
        let expiry = now.addingTimeInterval(1800) // 30 minutes
        let notBefore = now.addingTimeInterval(-5) // 5 seconds buffer
        
        // JWT Header
        let header: [String: Any] = [
            "alg": "HS256",
            "typ": "JWT"
        ]
        
        // JWT Payload
        let payload: [String: Any] = [
            "iss": accessKey,
            "exp": Int(expiry.timeIntervalSince1970),
            "nbf": Int(notBefore.timeIntervalSince1970)
        ]
        
        // Encode header and payload
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        
        let headerBase64 = headerData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        let payloadBase64 = payloadData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        // Create signature with HMAC-SHA256
        let message = "\(headerBase64).\(payloadBase64)"
        guard let messageData = message.data(using: .utf8),
              let secretData = secretKey.data(using: .utf8) else {
            throw KlingError.generationFailed("Failed to encode JWT components")
        }
        
        let symmetricKey = SymmetricKey(data: secretData)
        let signature = HMAC<SHA256>.authenticationCode(for: messageData, using: symmetricKey)
        let signatureBase64 = Data(signature).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        return "\(headerBase64).\(payloadBase64).\(signatureBase64)"
    }
    
    /// Get valid JWT token (regenerates if expired or missing)
    private func getValidToken() throws -> String {
        let now = Date()
        
        // Check if cached token is still valid (with 5 min buffer)
        if let token = cachedToken,
           let expiry = tokenExpiry,
           expiry > now.addingTimeInterval(300) {
            return token
        }
        
        // Generate new token
        let token = try generateJWT()
        cachedToken = token
        tokenExpiry = now.addingTimeInterval(1800) // 30 minutes
        
        writeToLog("🔑 Generated new JWT token (expires in 30 mins)")
        return token
    }
    
    /// Validate request eligibility before API call
    /// - Parameter traceId: Trace ID for telemetry
    /// - Throws: KlingError if validation fails
    public func validateRequestEligibility(traceId: String) async throws {
        // 1. Confirm API token is non-empty
        guard !accessKey.isEmpty && !secretKey.isEmpty else {
            throw KlingError.generationFailed("API credentials are missing")
        }
        
        // 2. Check remaining credits
        let remaining = try await SupabaseSyncService.shared.remainingCredits()
        guard remaining > 0 else {
            await TelemetryService.shared.logEvent(
                .clipGenerationFailure,
                traceId: traceId,
                payload: ["error": "insufficient_credits", "remaining": remaining]
            )
            throw KlingError.generationFailed("Insufficient credits: \(remaining) remaining")
        }
        
        // 3. Tier-based quality caps (enforced at generation time, not here)
        // Free tier → 720p max is handled in version selection
    }
    
    /// Generate fallback portrait image from prompt (for failed clip generation)
    /// - Parameters:
    ///   - prompt: Text prompt
    ///   - traceId: Trace ID
    /// - Returns: Image data or nil if not supported
    public func fetchFallbackPortrait(prompt: String, traceId: String) async throws -> Data? {
        // TODO: Implement Kling text-to-image API call when available
        // For now, return nil (placeholder)
        writeToLog("⚠️ Fallback portrait generation not yet implemented")
        return nil
    }
    
    /// Generate a video using Kling AI (direct native API)
    /// - Parameters:
    ///   - prompt: The video generation prompt
    ///   - version: Kling version to use (1.6/2.0/2.5)
    ///   - traceId: Trace ID for telemetry correlation
    ///   - negativePrompt: Optional negative prompt string (v2.0+ only, single string not array)
    ///   - duration: Video duration in seconds
    ///   - image: Optional base64 image string with data URI prefix
    ///   - imageTail: Optional imageTail for continuity (v1.6 only)
    ///   - cameraControl: Optional camera control matching official API format
    ///   - mode: Optional mode ("std" or "pro") - if nil, uses version default
    /// - Returns: VideoTask with task ID and status URL
    /// - Throws: KlingError on API failure
    public func generateVideo(
        prompt: String,
        version: KlingVersion,
        traceId: String,
        negativePrompt: String? = nil,
        duration: Int = 5,
        image: String? = nil,
        imageTail: String? = nil,
        cameraControl: CameraControl? = nil,
        mode: String? = nil
    ) async throws -> VideoTask {
        // Validate request eligibility before proceeding
        try await validateRequestEligibility(traceId: traceId)
        
        let endpoint = version.endpoint
        let requestId = UUID().uuidString.prefix(8)
        
        // Add trace ID to request header
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(try getValidToken())", forHTTPHeaderField: "Authorization")
        request.setValue(traceId, forHTTPHeaderField: "X-Trace-ID")
        
        writeToLog("🚀 ====== REQUEST START [\(requestId)] [Trace: \(traceId)] ======")
        writeToLog("🚀 [\(requestId)] Method: POST")
        writeToLog("🚀 [\(requestId)] URL: \(endpoint.absoluteString)")
        writeToLog("🚀 [\(requestId)] Version: \(version.rawValue)")
        
        // Build request body matching Kling native API format
        let requestBody = try buildKlingRequest(
            version: version,
            prompt: prompt,
            negativePrompt: negativePrompt,
            duration: min(duration, version.maxSeconds),
            strength: 50,
            image: image,
            imageTail: imageTail,
            cameraControl: cameraControl,
            mode: mode
        )
        
        request.httpBody = requestBody
        
        // Log request body
        if let bodyString = String(data: requestBody, encoding: .utf8) {
            writeToLog("🚀 [\(requestId)] REQUEST BODY (\(requestBody.count) bytes):\n\(bodyString)")
        }
        
        let startTime = Date()
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            writeToLog("❌ [\(requestId)] Network request failed after \(String(format: "%.2f", duration))s")
            writeToLog("❌ [\(requestId)] Error: \(error.localizedDescription)")
            writeToLog("❌ [\(requestId)] Error type: \(type(of: error))")
            if let urlError = error as? URLError {
                writeToLog("❌ [\(requestId)] URLError code: \(urlError.code.rawValue)")
                writeToLog("❌ [\(requestId)] URLError description: \(urlError.localizedDescription)")
            }
            writeToLog("❌ [\(requestId)] ====== REQUEST FAILED (NETWORK ERROR) ======")
            
            // Log telemetry
            await TelemetryService.shared.logApiCall(
                method: "generateVideo",
                traceId: traceId,
                statusCode: 0,
                duration: duration
            )
            
            throw KlingError.generationFailed("Network error: \(error.localizedDescription)")
        }
        let duration = Date().timeIntervalSince(startTime)
        
        // Log response BEFORE validation (so we can see errors)
        if let httpResponse = response as? HTTPURLResponse {
            writeToLog("📡 [\(requestId)] Response Status: \(httpResponse.statusCode)")
            writeToLog("📡 [\(requestId)] Duration: \(String(format: "%.2f", duration))s")
            writeToLog("📡 [\(requestId)] Response Size: \(data.count) bytes")
            
            // Log raw response (especially important for errors)
            if let responseString = String(data: data, encoding: .utf8) {
                let truncated = responseString.count > 1000 ? String(responseString.prefix(1000)) + "..." : responseString
                writeToLog("📥 [\(requestId)] RESPONSE BODY:\n\(truncated)")
                print("📥 [KlingAPIClient] Raw response: \(responseString.prefix(500))")
            }
            
            // Check for error status codes BEFORE validation
            if httpResponse.statusCode != 200 {
                writeToLog("❌ [\(requestId)] HTTP ERROR \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    writeToLog("❌ [\(requestId)] Error Response: \(responseString)")
                    
                    // Handle HTTP 429 (rate limit) with Retry-After header
                    if httpResponse.statusCode == 429 {
                        var retryAfter: TimeInterval = 1.0
                        if let retryAfterHeader = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                           let retrySeconds = TimeInterval(retryAfterHeader) {
                            retryAfter = retrySeconds
                        }
                        
                        writeToLog("⏳ [\(requestId)] Rate limited, retry after \(retryAfter)s")
                        
                        // Log telemetry
                        await TelemetryService.shared.logApiCall(
                            method: "generateVideo",
                            traceId: traceId,
                            statusCode: 429,
                            duration: duration
                        )
                        
                        // Schedule delayed retry via Task.detached
                        throw KlingError.httpError(429) // Will be caught by retry logic
                    }
                    
                    // Handle HTTP 400 errors
                    if httpResponse.statusCode == 400 {
                        // Check for Error 1102 (resource pack depleted) first
                        do {
                            try handleKlingError(data, requestId: String(requestId))
                        } catch let error as KlingError {
                            // Re-throw if it's resourcePackDepleted
                            if case .resourcePackDepleted = error {
                                await TelemetryService.shared.logApiCall(
                                    method: "generateVideo",
                                    traceId: traceId,
                                    statusCode: 400,
                                    duration: duration
                                )
                                throw error
                            }
                            // Not Error 1102, continue with normal error handling
                        } catch {
                            // Not a KlingError, continue
                        }
                        
                        // Handle other error codes
                        if let errorResponse = try? decoder.decode(KlingErrorResponse.self, from: data) {
                            // Other error codes - show the actual API error message
                            let errorMsg = errorResponse.message ?? errorResponse.error ?? "Unknown error"
                            let errorCode = errorResponse.code != nil ? " (code: \(errorResponse.code!))" : ""
                            writeToLog("❌ [\(requestId)] API ERROR\(errorCode): \(errorMsg)")
                            throw KlingError.generationFailed("\(errorMsg)\(errorCode)")
                        } else {
                            // Can't decode error response - show raw response
                            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                            writeToLog("❌ [\(requestId)] HTTP \(httpResponse.statusCode) - Raw response: \(responseString)")
                            throw KlingError.httpError(httpResponse.statusCode)
                        }
                    }
                }
            }
        }
        
        // Now validate (will throw if status code is not 200-299)
        try validate(response: response)
        
        // Parse official Kling API response format: {code, message, request_id, data: {task_id, task_status, ...}}
        do {
            struct KlingVideoResponse: Codable {
                let code: Int
                let message: String?
                let request_id: String?
                let data: VideoTaskData?
            }
            
            struct VideoTaskData: Codable {
                let task_id: String
                let task_status: String
                let created_at: Int64?
                let updated_at: Int64?
            }
            
            let klingResponse = try decoder.decode(KlingVideoResponse.self, from: data)
            
            guard klingResponse.code == 0, let taskData = klingResponse.data else {
                throw KlingError.generationFailed(klingResponse.message ?? "Failed to create video task")
            }
            
            let taskId = taskData.task_id
            // Official status endpoint: GET /v1/videos/text2video/{task_id}
            // CORRECTED: Using Singapore API domain
            let statusURL = URL(string: "https://api-singapore.klingai.com/v1/videos/text2video/\(taskId)")!
            
            writeToLog("✅ [\(requestId)] Task Created: \(taskId)")
            writeToLog("✅ [\(requestId)] Status: \(taskData.task_status)")
            writeToLog("✅ [\(requestId)] Status URL: \(statusURL.absoluteString)")
            writeToLog("✅ [\(requestId)] ====== REQUEST COMPLETE ======")
            
            // Log successful API call
            await TelemetryService.shared.logApiCall(
                method: "generateVideo",
                traceId: traceId,
                statusCode: 200,
                duration: duration
            )
            
            // Deduct credits (estimate cost based on version and duration)
            let cost = estimateCost(version: version, duration: duration)
            try? await SupabaseSyncService.shared.deductCredits(amount: cost, traceId: traceId)
            
            return VideoTask(id: taskId, statusURL: statusURL)
        } catch {
            // Try error response format
            if let errorResponse = try? decoder.decode(KlingErrorResponse.self, from: data) {
                writeToLog("❌ [\(requestId)] API ERROR: \(errorResponse.message ?? errorResponse.error ?? "Unknown error")")
                throw KlingError.generationFailed(errorResponse.message ?? errorResponse.error ?? "API error")
            }
            
            // If both fail, provide detailed error
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            writeToLog("❌ [\(requestId)] DECODE ERROR: \(error.localizedDescription)")
            writeToLog("❌ [\(requestId)] Response: \(responseString.prefix(500))")
            writeToLog("❌ [\(requestId)] ====== REQUEST FAILED ======")
            print("❌ [KlingAPIClient] Decoding failed. Response: \(responseString)")
            throw KlingError.generationFailed("Failed to parse response: \(error.localizedDescription). Response: \(responseString.prefix(200))")
        }
    }
    
    /// Build Kling native API request body matching official spec
    /// POST /v1/videos/text2video
    /// Required: prompt
    /// Optional: model_name, negative_prompt, cfg_scale, mode, duration, aspect_ratio, camera_control
    private func buildKlingRequest(
        version: KlingVersion,
        prompt: String,
        negativePrompt: String?,
        duration: Int,
        strength: Int,
        image: String?,
        imageTail: String?,
        cameraControl: CameraControl? = nil,
        mode: String? = nil
    ) throws -> Data {
        var requestDict: [String: Any] = [
            "model_name": version.modelName,  // Optional but recommended: e.g. "kling-v2-5-turbo"
            "prompt": prompt  // Required: max 2500 characters
        ]
        
        // Duration: "5" or "10" as string (official API expects string)
        let validDuration = min(max(duration, 5), 10)
        requestDict["duration"] = String(validDuration)
        
        // Mode: "std" or "pro" (use provided mode, or default based on version)
        if let mode = mode {
            requestDict["mode"] = mode
        } else {
            // Default: v1.6 uses "std", v2.x uses "pro" for better quality
        if version == .v1_6_standard {
            requestDict["mode"] = "std"
        } else {
            requestDict["mode"] = "pro"
            }
        }
        
        // Negative prompt (v2.0+ only, max 2500 characters)
        if let negativePrompt = negativePrompt, version.supportsNegative {
            requestDict["negative_prompt"] = negativePrompt
        }
        
        // cfg_scale: [0.0 - 1.0] (v2.x doesn't support, but include for v1.6)
        if version == .v1_6_standard {
            requestDict["cfg_scale"] = Double(strength) / 100.0  // Convert 0-100 to 0.0-1.0
        }
        
        // Aspect ratio: default to 16:9 (options: 16:9, 9:16, 1:1)
        requestDict["aspect_ratio"] = "16:9"
        
        // Image (optional): base64 or URL for image-to-video
        if let image = image {
            requestDict["image"] = image
        }
        
        // imageTail (v1.6 only, for continuity)
        if version == .v1_6_standard, let imageTail = imageTail {
            requestDict["imageTail"] = imageTail
        }
        
        // Camera control: We detect camera movements from prompt text for UI/informational purposes,
        // but rely on the model's natural language understanding rather than camera_control JSON.
        // The API intelligently interprets cinematographic terms in the prompt (like "drone shot",
        // "zoom in", "pan left") without needing explicit camera_control parameters.
        // This approach works across all models and modes, making it more flexible than the
        // camera_control parameter which only works with kling-v1, std mode, 5s duration.
        if let cameraControl = cameraControl {
            // Log detected camera control for informational purposes
            if let cameraDict = cameraControl.toAPIDict() {
                if let jsonData = try? JSONSerialization.data(withJSONObject: cameraDict, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("🎥 [KlingAPIClient] Camera movement detected: \(cameraControl.type?.rawValue ?? "custom")")
                    print("   (Camera guidance will come from prompt text - more flexible than JSON)")
                }
            }
            // Intentionally NOT including camera_control in request - let prompt text guide the model
        }
        
        return try JSONSerialization.data(withJSONObject: requestDict, options: [])
    }
    
    /// Query video task list (GET /v1/videos/text2video?pageNum=1&pageSize=30)
    /// - Parameters:
    ///   - pageNum: Page number (1-1000)
    ///   - pageSize: Items per page (1-500)
    /// - Returns: Array of video tasks
    public func queryVideoTaskList(pageNum: Int = 1, pageSize: Int = 30) async throws -> [VideoTaskInfo] {
        let endpoint = URL(string: "https://api-singapore.klingai.com/v1/videos/text2video?pageNum=\(pageNum)&pageSize=\(pageSize)")!
        let requestId = UUID().uuidString.prefix(8)
        
        writeToLog("📋 [\(requestId)] Querying video task list (page \(pageNum), size \(pageSize))")
        
        let jwtToken = try getValidToken()
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KlingError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? decoder.decode(KlingErrorResponse.self, from: data) {
                throw KlingError.generationFailed(errorResponse.message ?? errorResponse.error ?? "API error")
            }
            throw KlingError.httpError(httpResponse.statusCode)
        }
        
        struct VideoListResponse: Codable {
            let code: Int
            let message: String?
            let request_id: String?
            let data: [VideoTaskInfo]?
        }
        
        let listResponse = try decoder.decode(VideoListResponse.self, from: data)
        guard listResponse.code == 0, let tasks = listResponse.data else {
            throw KlingError.generationFailed(listResponse.message ?? "Failed to get task list")
        }
        
        writeToLog("✅ [\(requestId)] Retrieved \(tasks.count) video tasks")
        return tasks
    }
    
    /// Query audio task list (GET /v1/audio/text-to-audio?pageNum=1&pageSize=30)
    /// - Parameters:
    ///   - pageNum: Page number (1-1000)
    ///   - pageSize: Items per page (1-500)
    /// - Returns: Array of audio tasks
    public func queryAudioTaskList(pageNum: Int = 1, pageSize: Int = 30) async throws -> [AudioTaskInfo] {
        let endpoint = URL(string: "https://api-singapore.klingai.com/v1/audio/text-to-audio?pageNum=\(pageNum)&pageSize=\(pageSize)")!
        let requestId = UUID().uuidString.prefix(8)
        
        writeToLog("📋 [\(requestId)] Querying audio task list (page \(pageNum), size \(pageSize))")
        
        let jwtToken = try getValidToken()
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw KlingError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? decoder.decode(KlingErrorResponse.self, from: data) {
                throw KlingError.generationFailed(errorResponse.message ?? errorResponse.error ?? "API error")
            }
            throw KlingError.httpError(httpResponse.statusCode)
        }
        
        struct AudioListResponse: Codable {
            let code: Int
            let message: String?
            let request_id: String?
            let data: [AudioTaskInfo]?
        }
        
        let listResponse = try decoder.decode(AudioListResponse.self, from: data)
        guard listResponse.code == 0, let tasks = listResponse.data else {
            throw KlingError.generationFailed(listResponse.message ?? "Failed to get task list")
        }
        
        writeToLog("✅ [\(requestId)] Retrieved \(tasks.count) audio tasks")
        return tasks
    }
    
    /// Poll for video generation status with exponential backoff
    /// Uses Kling native API status endpoint format: GET /v1/videos/text2video/{task_id}
    /// Response format: {code, message, data: {task_status, task_result: {videos: [{url}]}}}
    /// - Parameters:
    ///   - task: The VideoTask from generateVideo
    ///   - timeout: Maximum time to wait (default 300s)
    ///   - onStatusUpdate: Optional callback invoked when status changes ("pending", "processing", "completed", "failed")
    /// - Returns: URL to the generated video
    /// - Throws: KlingError on timeout or failure
    public func pollStatus(task: VideoTask, timeout: TimeInterval = 300, onStatusUpdate: (@Sendable (String) -> Void)? = nil) async throws -> URL {
        let start = Date()
        var backoff: Double = 1.0
        let requestId = UUID().uuidString.prefix(8)
        var pollCount = 0
        
        writeToLog("🔄 [\(requestId)] Starting status polling for task: \(task.id)")
        writeToLog("🔄 [\(requestId)] Status URL: \(task.statusURL.absoluteString)")
        
        while Date().timeIntervalSince(start) < timeout {
            try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
            pollCount += 1
            
            // Get valid JWT token
            let jwtToken = try getValidToken()
            
            var request = URLRequest(url: task.statusURL)
            request.httpMethod = "GET"
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization") // JWT Bearer token
            
            let pollStart = Date()
            let (data, response) = try await session.data(for: request)
            let pollDuration = Date().timeIntervalSince(pollStart)
            
            writeToLog("🔄 [\(requestId)] Poll #\(pollCount) - Duration: \(String(format: "%.2f", pollDuration))s")
            
            // Check for error response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorResponse = try? decoder.decode(KlingErrorResponse.self, from: data) {
                    let errorMsg = errorResponse.message ?? errorResponse.error ?? "HTTP \(httpResponse.statusCode)"
                    throw KlingError.generationFailed(errorMsg)
                }
                throw KlingError.httpError(httpResponse.statusCode)
            }
            
            try validate(response: response)
            
            // Log raw status response
            if let responseString = String(data: data, encoding: .utf8) {
                let truncated = responseString.count > 500 ? String(responseString.prefix(500)) + "..." : responseString
                writeToLog("📥 [\(requestId)] Status Response (poll #\(pollCount)):\n\(truncated)")
                print("📥 [KlingAPIClient] Status response: \(responseString.prefix(500))")
            }
            
            // Parse official Kling API status response format: {code, message, request_id, data: {task_status, task_result: {videos: [{url}]}}}
            struct VideoStatusResponse: Codable {
                let code: Int
                let message: String?
                let request_id: String?
                let data: VideoStatusData?
            }
            
            struct VideoStatusData: Codable {
                let task_id: String
                let task_status: String
                let task_status_msg: String?
                let task_result: VideoResult?
            }
            
            struct VideoResult: Codable {
                let videos: [VideoFile]?
            }
            
            struct VideoFile: Codable {
                let id: String
                let url: String
                let duration: String?
            }
            
            let statusResponse: VideoStatusResponse
            do {
                statusResponse = try decoder.decode(VideoStatusResponse.self, from: data)
            } catch {
                let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
                writeToLog("❌ [\(requestId)] Status decode failed: \(error.localizedDescription)")
                writeToLog("❌ [\(requestId)] Response: \(responseString.prefix(500))")
                print("❌ [KlingAPIClient] Status decode failed. Response: \(responseString)")
                throw KlingError.generationFailed("Failed to parse status response: \(error.localizedDescription). Response: \(responseString.prefix(200))")
            }
            
            guard statusResponse.code == 0, let statusData = statusResponse.data else {
                throw KlingError.generationFailed(statusResponse.message ?? "Failed to get video status")
            }
            
            // Process video generation status
            let currentStatus = statusData.task_status.lowercased()
            
            // Map Kling status to our callback format
            let callbackStatus: String
            switch currentStatus {
            case "submitted":
                callbackStatus = "waiting"
            case "processing":
                callbackStatus = "processing"
            case "succeed":
                callbackStatus = "succeed"
            case "failed":
                callbackStatus = "failed"
            default:
                callbackStatus = currentStatus
            }
            
            // Notify status update callback
            onStatusUpdate?(callbackStatus)
            
            switch currentStatus {
            case "succeed":
                // Official API format: data.task_result.videos[0].url
                guard let videoResult = statusData.task_result,
                      let videos = videoResult.videos,
                      let firstVideo = videos.first,
                      let videoURL = URL(string: firstVideo.url) else {
                    writeToLog("❌ [\(requestId)] Video URL missing or invalid")
                    throw KlingError.generationFailed("Video URL missing or invalid")
                }
                let totalDuration = Date().timeIntervalSince(start)
                writeToLog("✅ [\(requestId)] Video ready: \(videoURL)")
                writeToLog("✅ [\(requestId)] Total polling time: \(String(format: "%.2f", totalDuration))s")
                writeToLog("✅ [\(requestId)] Total polls: \(pollCount)")
                writeToLog("✅ [\(requestId)] ====== POLLING COMPLETE ======")
                return videoURL
                
            case "failed":
                let errorMsg = statusData.task_status_msg ?? "Video generation failed"
                throw KlingError.generationFailed(errorMsg)
                
            case "submitted", "processing":
                backoff = min(backoff * 2, 8.0)
                continue
                
            default:
                backoff = min(backoff * 2, 8.0)
                continue
            }
        }
        throw KlingError.timeout
    }
    
    /// Generate audio from text using Kling AI (direct native API)
    /// - Parameters:
    ///   - prompt: Text prompt (max 200 characters)
    ///   - duration: Audio duration in seconds (3.0-10.0, supports one decimal place)
    ///   - externalTaskId: Optional custom task ID
    /// - Returns: AudioTask with task ID and status URL
    /// - Throws: KlingError on API failure
    public func generateAudio(
        prompt: String,
        duration: Double,
        externalTaskId: String? = nil
    ) async throws -> AudioTask {
        // CORRECTED: Using Singapore API domain
        let endpoint = URL(string: "https://api-singapore.klingai.com/v1/audio/text-to-audio")!
        let requestId = UUID().uuidString.prefix(8)
        
        writeToLog("🚀 ====== AUDIO GENERATION REQUEST START [\(requestId)] ======")
        writeToLog("🚀 [\(requestId)] Method: POST")
        writeToLog("🚀 [\(requestId)] URL: \(endpoint.absoluteString)")
        writeToLog("🚀 [\(requestId)] Prompt: '\(prompt.prefix(100))\(prompt.count > 100 ? "..." : "")'")
        writeToLog("🚀 [\(requestId)] Duration: \(duration)s")
        
        // Validate prompt length
        guard prompt.count <= 200 else {
            throw KlingError.generationFailed("Prompt exceeds 200 character limit")
        }
        
        // Validate duration
        guard duration >= 3.0 && duration <= 10.0 else {
            throw KlingError.generationFailed("Duration must be between 3.0 and 10.0 seconds")
        }
        
        // Get valid JWT token
        let jwtToken = try getValidToken()
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        // Build request body
        var requestDict: [String: Any] = [
            "prompt": prompt,
            "duration": duration
        ]
        
        if let externalTaskId = externalTaskId {
            requestDict["external_task_id"] = externalTaskId
        }
        
        let requestBody = try JSONSerialization.data(withJSONObject: requestDict, options: [])
        request.httpBody = requestBody
        
        // Log request body
        if let bodyString = String(data: requestBody, encoding: .utf8) {
            writeToLog("🚀 [\(requestId)] REQUEST BODY (\(requestBody.count) bytes):\n\(bodyString)")
        }
        
        let startTime = Date()
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            writeToLog("❌ [\(requestId)] Network request failed after \(String(format: "%.2f", duration))s")
            writeToLog("❌ [\(requestId)] Error: \(error.localizedDescription)")
            throw KlingError.generationFailed("Network error: \(error.localizedDescription)")
        }
        let duration = Date().timeIntervalSince(startTime)
        
        // Log response
        if let httpResponse = response as? HTTPURLResponse {
            writeToLog("📡 [\(requestId)] Response Status: \(httpResponse.statusCode)")
            writeToLog("📡 [\(requestId)] Duration: \(String(format: "%.2f", duration))s")
            writeToLog("📡 [\(requestId)] Response Size: \(data.count) bytes")
            
            if let responseString = String(data: data, encoding: .utf8) {
                let truncated = responseString.count > 1000 ? String(responseString.prefix(1000)) + "..." : responseString
                writeToLog("📥 [\(requestId)] RESPONSE BODY:\n\(truncated)")
            }
            
            if httpResponse.statusCode != 200 {
                writeToLog("❌ [\(requestId)] HTTP ERROR \(httpResponse.statusCode)")
                
                // Check for Error 1102 (resource pack depleted) first
                do {
                    try handleKlingError(data, requestId: String(requestId))
                } catch let error as KlingError {
                    // Re-throw if it's resourcePackDepleted
                    if case .resourcePackDepleted = error {
                        throw error
                    }
                    // Not Error 1102, continue with normal error handling
                } catch {
                    // Not a KlingError, continue
                }
                
                if let errorResponse = try? decoder.decode(KlingErrorResponse.self, from: data) {
                    throw KlingError.generationFailed(errorResponse.message ?? errorResponse.error ?? "API error")
                }
            }
        }
        
        try validate(response: response)
        
        // Parse response
        do {
            struct KlingAudioResponse: Codable {
                let code: Int
                let message: String?
                let request_id: String?
                let data: AudioTaskData?
            }
            
            struct AudioTaskData: Codable {
                let task_id: String
                let task_status: String
                let created_at: Int64?
                let updated_at: Int64?
            }
            
            let audioResponse = try decoder.decode(KlingAudioResponse.self, from: data)
            
            guard audioResponse.code == 0, let taskData = audioResponse.data else {
                throw KlingError.generationFailed(audioResponse.message ?? "Failed to create audio task")
            }
            
            let taskId = taskData.task_id
            // CORRECTED: Using Singapore API domain
            let statusURL = URL(string: "https://api-singapore.klingai.com/v1/audio/text-to-audio/\(taskId)")!
            
            writeToLog("✅ [\(requestId)] Audio Task Created: \(taskId)")
            writeToLog("✅ [\(requestId)] Status URL: \(statusURL.absoluteString)")
            writeToLog("✅ [\(requestId)] ====== AUDIO TASK CREATED ======")
            
            return AudioTask(id: taskId, statusURL: statusURL)
            
        } catch {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
            writeToLog("❌ [\(requestId)] DECODE ERROR: \(error.localizedDescription)")
            writeToLog("❌ [\(requestId)] Response: \(responseString.prefix(500))")
            throw KlingError.generationFailed("Failed to parse audio response: \(error.localizedDescription). Response: \(responseString.prefix(200))")
        }
    }
    
    /// Poll for audio generation status with exponential backoff
    /// - Parameters:
    ///   - task: The AudioTask from generateAudio
    ///   - timeout: Maximum time to wait (default 300s)
    /// - Returns: URL to the generated audio (MP3 format)
    /// - Throws: KlingError on timeout or failure
    public func pollAudioStatus(task: AudioTask, timeout: TimeInterval = 300) async throws -> URL {
        let start = Date()
        var backoff: Double = 1.0
        let requestId = UUID().uuidString.prefix(8)
        var pollCount = 0
        
        writeToLog("🔄 [\(requestId)] Starting audio status polling for task: \(task.id)")
        
        while Date().timeIntervalSince(start) < timeout {
            try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
            pollCount += 1
            
            let jwtToken = try getValidToken()
            var request = URLRequest(url: task.statusURL)
            request.httpMethod = "GET"
            request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
            
            let pollStart = Date()
            let (data, response) = try await session.data(for: request)
            let pollDuration = Date().timeIntervalSince(pollStart)
            
            writeToLog("🔄 [\(requestId)] Poll #\(pollCount) - Duration: \(String(format: "%.2f", pollDuration))s")
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorResponse = try? decoder.decode(KlingErrorResponse.self, from: data) {
                    let errorMsg = errorResponse.message ?? errorResponse.error ?? "HTTP \(httpResponse.statusCode)"
                    throw KlingError.generationFailed(errorMsg)
                }
                throw KlingError.httpError(httpResponse.statusCode)
            }
            
            try validate(response: response)
            
            // Parse status response
            struct AudioStatusResponse: Codable {
                let code: Int
                let message: String?
                let data: AudioStatusData?
            }
            
            struct AudioStatusData: Codable {
                let task_id: String
                let task_status: String
                let task_status_msg: String?
                let task_result: AudioResult?
            }
            
            struct AudioResult: Codable {
                let audios: [AudioFile]?
            }
            
            struct AudioFile: Codable {
                let id: String
                let url_mp3: String?
                let url_wav: String?
                let duration_mp3: String?
                let duration_wav: String?
            }
            
            let statusResponse = try decoder.decode(AudioStatusResponse.self, from: data)
            
            guard statusResponse.code == 0, let statusData = statusResponse.data else {
                throw KlingError.generationFailed(statusResponse.message ?? "Failed to get audio status")
            }
            
            let currentStatus = statusData.task_status.lowercased()
            
            switch currentStatus {
            case "succeed":
                guard let audioResult = statusData.task_result,
                      let audios = audioResult.audios,
                      let firstAudio = audios.first,
                      let audioURLString = firstAudio.url_mp3 ?? firstAudio.url_wav,
                      let audioURL = URL(string: audioURLString) else {
                    throw KlingError.generationFailed("Audio URL missing from response")
                }
                
                let totalDuration = Date().timeIntervalSince(start)
                writeToLog("✅ [\(requestId)] Audio ready: \(audioURL)")
                writeToLog("✅ [\(requestId)] Total polling time: \(String(format: "%.2f", totalDuration))s")
                writeToLog("✅ [\(requestId)] Total polls: \(pollCount)")
                return audioURL
                
            case "failed":
                let errorMsg = statusData.task_status_msg ?? "Audio generation failed"
                throw KlingError.generationFailed(errorMsg)
                
            case "submitted", "processing":
                backoff = min(backoff * 2, 8.0)
                continue
                
            default:
                backoff = min(backoff * 2, 8.0)
                continue
            }
        }
        throw KlingError.timeout
    }
    
    /// Estimate credit cost for generation
    /// - Parameters:
    ///   - version: Kling version
    ///   - duration: Video duration in seconds
    /// - Returns: Estimated credit cost
    private func estimateCost(version: KlingVersion, duration: Int) -> Int {
        // Base rate: 4 credits per second for v1.6, 8 for v2.0, 16 for v2.5
        let baseRate: Int
        switch version {
        case .v1_6_standard:
            baseRate = 4
        case .v2_0_master:
            baseRate = 8
        case .v2_5_turbo:
            baseRate = 16
        }
        return baseRate * duration
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

// MARK: - Request/Response Models (Kling Native API Format)

/// Kling native API response structure for generation endpoints
/// POST /v1/videos/text2video returns: {task_id, status, created_at, updated_at, ...}
private struct KlingResponse: Codable {
    let task_id: String?  // Primary field name from API
    let taskId: String?  // Alternative camelCase
    let id: String?  // Alternative field name
    let status: String?
    let created_at: String?
    let updated_at: String?
    
    enum CodingKeys: String, CodingKey {
        case task_id
        case taskId
        case id
        case status
        case created_at
        case updated_at
    }
}

/// Kling native API status response structure
/// GET /v1/videos/{task_id} returns: {task_id, status, video_url, created_at, updated_at, ...}
private struct KlingStatusResponse: Codable {
    let task_id: String?  // Primary field name
    let taskId: String?  // Alternative camelCase
    let id: String?  // Alternative field name
    let status: String  // "pending", "processing", "completed", "failed"
    let video_url: String?  // Primary: Video URL when status is "completed" (valid 30 days)
    let videoUrl: String?  // Alternative camelCase
    let url: String?  // Alternative field name
    let error: String?  // Error message if status is "failed"
    let message: String?  // General message
    let created_at: String?  // ISO 8601 timestamp
    let updated_at: String?  // ISO 8601 timestamp
    
    enum CodingKeys: String, CodingKey {
        case task_id
        case taskId
        case id
        case status
        case video_url
        case videoUrl
        case url
        case error
        case message
        case created_at
        case updated_at
    }
}

/// Kling native API error response structure
private struct KlingErrorResponse: Codable {
    let error: String?
    let message: String?
    let code: Int?  // Error code can be Int (e.g., 1102) or String
    let codeString: String?  // Alternative if code comes as string
    
    enum CodingKeys: String, CodingKey {
        case error
        case message
        case code
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        error = try? container.decode(String.self, forKey: .error)
        message = try? container.decode(String.self, forKey: .message)
        
        // Try decoding code as Int first, then String
        if let codeInt = try? container.decode(Int.self, forKey: .code) {
            code = codeInt
            codeString = nil
        } else if let codeStr = try? container.decode(String.self, forKey: .code) {
            code = Int(codeStr)
            codeString = codeStr
        } else {
            code = nil
            codeString = nil
        }
    }
}

public struct VideoTask: Sendable {
    public let id: String
    public let statusURL: URL
}

public struct AudioTask: Sendable {
    public let id: String
    public let statusURL: URL
}

/// Video task info from list query
public struct VideoTaskInfo: Codable, Sendable {
    public let task_id: String
    public let task_status: String
    public let task_status_msg: String?
    public let task_info: TaskInfo?
    public let task_result: VideoTaskResult?
    public let created_at: Int64?
    public let updated_at: Int64?
    
    public struct TaskInfo: Codable, Sendable {
        public let external_task_id: String?
    }
    
    public struct VideoTaskResult: Codable, Sendable {
        public let videos: [VideoTaskFile]?
    }
    
    public struct VideoTaskFile: Codable, Sendable {
        public let id: String
        public let url: String
        public let duration: String?
    }
}

/// Audio task info from list query
public struct AudioTaskInfo: Codable, Sendable {
    public let task_id: String
    public let task_status: String
    public let task_status_msg: String?
    public let task_info: TaskInfo?
    public let task_result: AudioResult?
    public let created_at: Int64?
    public let updated_at: Int64?
    
    public struct TaskInfo: Codable, Sendable {
        public let external_task_id: String?
    }
    
    public struct AudioResult: Codable, Sendable {
        public let audios: [AudioFile]?
    }
    
    public struct AudioFile: Codable, Sendable {
        public let id: String
        public let url_mp3: String?
        public let url_wav: String?
        public let duration_mp3: String?
        public let duration_wav: String?
    }
}

// MARK: - Errors

public enum KlingError: LocalizedError, Sendable {
    case invalidResponse
    case httpError(Int)
    case generationFailed(String)
    case timeout
    case resourcePackDepleted
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Kling AI API. Please check your connection and try again."
        case .httpError(let code):
            switch code {
            case 401:
                return "Kling AI authentication failed. Please verify your AccessKey and SecretKey are correct."
            case 403:
                return "Kling AI access forbidden. Please check your API credentials and account status."
            case 404:
                return "Kling AI endpoint not found. The API may have changed or the endpoint is incorrect."
            case 429:
                return "Kling AI rate limit exceeded or insufficient balance. If you have credits, check: (1) Credits are in the correct account linked to these API keys, (2) Minimum balance requirement may apply, (3) Try a shorter duration (5 seconds minimum)."
            case 500...599:
                return "Kling AI server error. The service may be temporarily unavailable. Please try again later."
            default:
                return "Kling AI API error (HTTP \(code)). Please try again or contact support if the problem persists."
            }
        case .generationFailed(let message):
            return "Kling AI generation failed: \(message)"
        case .timeout:
            return "Kling AI request timed out. The service may be busy. Please try again."
        case .resourcePackDepleted:
            return "Your Kling AI resource pack has been depleted or expired. Please purchase a new Resource Pack or enable Post-Payment in your Kling Dashboard."
        }
    }
    
    /// User-friendly title for error display
    public var errorTitle: String {
        switch self {
        case .resourcePackDepleted:
            return "Out of Generation Quota"
        case .httpError(let code):
            switch code {
            case 401, 403:
                return "Authentication Failed"
            case 404:
                return "Service Not Found"
            case 429:
                return "Rate Limit Exceeded"
            case 500...599:
                return "Server Error"
            default:
                return "API Error"
            }
        case .generationFailed:
            return "Generation Failed"
        case .timeout:
            return "Request Timeout"
        case .invalidResponse:
            return "Invalid Response"
        }
    }
    
    /// Dashboard URL for resource pack errors
    public var dashboardURL: URL? {
        switch self {
        case .resourcePackDepleted:
            return URL(string: "https://klingai.com/resource-packs")
        default:
            return nil
        }
    }
}

