// MODULE: GenerationOrchestrator
// VERSION: 1.0.0
// PURPOSE: Orchestrates parallel batch generation of video clips

import Foundation

/// Orchestrates parallel batch generation of video clips from prompts
public actor GenerationOrchestrator {
    private let fileManager = ProjectFileManager.shared
    private let deviceCapability = DeviceCapabilityManager.shared
    private var providers: [any VideoGenerationProvider] = []
    
    // Cache for checking duplicate prompts
    private var cache: [String: UUID] = [:] // prompt hash -> clip ID
    
    public init() {
        // Initialize with available providers
        self.providers = [
            PolloAIService()
        ]
        
        // Add Runway if API key exists
        if UserAPIKeysManager.shared.hasRunwayKey {
            self.providers.append(RunwayGen4Service())
        }
    }
    
    /// Generate all prompts for a project with parallel batching
    /// - Parameters:
    ///   - projectId: The project identifier
    ///   - prompts: Array of prompts to generate
    /// - Throws: Generation errors
    public func generateProject(_ projectId: UUID, prompts: [ProjectPrompt]) async throws {
        let batchSize = deviceCapability.recommendedConcurrency
        
        // Save initial prompt list
        try fileManager.savePromptList(prompts, for: projectId)
        
        // Process prompts in batches
        let batches = prompts.chunked(into: batchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            print("📦 Processing batch \(batchIndex + 1)/\(batches.count) with \(batch.count) prompts")
            
            // Process batch in parallel
            await withTaskGroup(of: GenerationResult.self) { group in
                for prompt in batch {
                    group.addTask {
                        await self.generateClip(prompt, projectId: projectId)
                    }
                }
                
                // Collect results
                for await result in group {
                    await self.handleGenerationResult(result, projectId: projectId)
                }
            }
        }
    }
    
    /// Generate a single clip from a prompt
    /// - Parameters:
    ///   - prompt: The prompt to generate
    ///   - projectId: The project identifier
    /// - Returns: Generation result
    private func generateClip(_ prompt: ProjectPrompt, projectId: UUID) async -> GenerationResult {
        // Update status to generating
        do {
            try await fileManager.updatePromptStatus(prompt.id, status: .generating, for: projectId)
        } catch {
            print("⚠️ Failed to update prompt status: \(error)")
        }
        
        // Check cache first
        if let cachedClipId = await checkCache(for: prompt) {
            return .cached(promptId: prompt.id, clipId: cachedClipId)
        }
        
        // Select optimal Kling version/tier
        let klingVersion = selectOptimalVersion(for: prompt)
        let tier = klingVersion.qualityTier
        
        // Try generation with retry logic
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount < maxRetries {
            do {
                let startTime = Date()
                
                // Select provider based on tier and attempt
                let provider = selectProvider(for: klingVersion, attempt: retryCount)
                
                // Generate video (default 5 seconds, could be made configurable)
                let duration: TimeInterval = 5.0
                let videoURL: URL
                
                // Use protocol method (both PolloAIService and RunwayGen4Service conform)
                // Default duration is 5 seconds
                videoURL = try await provider.generateVideo(
                    prompt: prompt.prompt,
                    duration: duration
                )
                
                let generationTime = Date().timeIntervalSince(startTime)
                
                // Track metrics
                let metrics = GenerationMetrics(
                    taskId: UUID().uuidString,
                    klingVersion: klingVersion.rawValue,
                    queueWaitTime: 0,
                    generationTime: generationTime,
                    networkLatency: 0,
                    localProcessingTime: 0,
                    peakMemoryUsage: 0,
                    apiResponseSize: 0,
                    cacheHitRate: 0,
                    negativePromptsUsed: nil,
                    experimentGroup: nil,
                    timestamp: Date()
                )
                
                return .success(promptId: prompt.id, videoURL: videoURL, metrics: metrics)
                
            } catch {
                retryCount += 1
                print("⚠️ Generation attempt \(retryCount)/\(maxRetries) failed: \(error.localizedDescription)")
                
                if retryCount >= maxRetries {
                    return .failure(promptId: prompt.id, error: error)
                }
                
                // Exponential backoff
                let delay = UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delay)
            }
        }
        
        return .failure(promptId: prompt.id, error: GenerationError.maxRetriesExceeded)
    }
    
    /// Handle generation result and update project state
    /// - Parameters:
    ///   - result: The generation result
    ///   - projectId: The project identifier
    private func handleGenerationResult(_ result: GenerationResult, projectId: UUID) async {
        switch result {
        case .success(let promptId, let videoURL, let metrics):
            // Update prompt status to completed
            do {
                try await fileManager.updatePromptStatus(promptId, status: .completed, for: projectId)
                print("✅ Generated clip for prompt \(promptId)")
            } catch {
                print("⚠️ Failed to update prompt status: \(error)")
            }
            
        case .cached(let promptId, let clipId):
            // Update prompt to use cached clip
            do {
                try await fileManager.updatePromptStatus(promptId, status: .completed, for: projectId)
                print("✅ Using cached clip \(clipId) for prompt \(promptId)")
            } catch {
                print("⚠️ Failed to update prompt status: \(error)")
            }
            
        case .failure(let promptId, let error):
            // Update prompt status to failed
            do {
                try await fileManager.updatePromptStatus(promptId, status: .failed, for: projectId)
                print("❌ Failed to generate clip for prompt \(promptId): \(error.localizedDescription)")
            } catch {
                print("⚠️ Failed to update prompt status: \(error)")
            }
        }
    }
    
    /// Check cache for similar prompts
    /// - Parameter prompt: The prompt to check
    /// - Returns: Cached clip ID if found, nil otherwise
    private func checkCache(for prompt: ProjectPrompt) async -> UUID? {
        // Simple hash-based cache lookup
        let promptHash = prompt.prompt.hashValue.description
        return cache[promptHash]
    }
    
    /// Select optimal Kling version based on prompt complexity
    /// - Parameter prompt: The prompt to analyze
    /// - Returns: Selected Kling version
    private func selectOptimalVersion(for prompt: ProjectPrompt) -> KlingVersion {
        // Use pre-calculated complexity score if available
        if let score = prompt.visualComplexityScore {
            if score > 0.7 {
                return .v2_5_turbo
            } else if score > 0.4 {
                return .v2_0_master
            }
        }
        
        // Check for complex keywords
        let complexKeywords = ["explosion", "crowd", "water", "transformation", "battle", "chase"]
        let promptLower = prompt.prompt.lowercased()
        if complexKeywords.contains(where: promptLower.contains) {
            return .v2_5_turbo
        }
        
        // Check for dialogue-heavy prompts
        if let dialogue = prompt.extractedDialogue, dialogue.count > 100 {
            return .v2_0_master
        }
        
        // Default to cost-effective option
        return .v1_6_standard
    }
    
    /// Select appropriate provider based on version and attempt
    /// - Parameters:
    ///   - version: The Kling version to use
    ///   - attempt: Retry attempt number
    /// - Returns: Selected provider
    private func selectProvider(for version: KlingVersion, attempt: Int) -> VideoGenerationProvider {
        // On first attempt, prefer Pollo for all tiers
        // On retry, could switch providers if available
        if attempt == 0 {
            return providers.first ?? providers[0]
        }
        
        // On retry, try different provider if available
        if providers.count > 1 {
            return providers[1]
        }
        
        return providers[0]
    }
}

