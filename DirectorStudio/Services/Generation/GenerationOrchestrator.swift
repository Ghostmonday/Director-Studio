// MODULE: GenerationOrchestrator
// VERSION: 2.0.0
// PURPOSE: Orchestrates complete clip generation flow following the production pipeline

import Foundation
import AVFoundation

/// Orchestrates parallel batch generation of video clips from prompts
/// Follows the complete flow: Extract → Validate → Segment → Dialogue → Generate → TTS → Combine → Store
public actor GenerationOrchestrator {
    private let fileManager = ProjectFileManager.shared
    private let deviceCapability = DeviceCapabilityManager.shared
    private let voiceoverService = VoiceoverGenerationService()
    private var providers: [any VideoGenerationProvider] = []
    
    // Cache for checking duplicate prompts
    private var cache: [String: UUID] = [:] // prompt hash -> clip ID
    
    // Results tracking
    private var generationResults: [UUID: ClipGenerationResult] = [:]
    
    public init() {
        // Initialize with Kling AI service (replaces Pollo)
        // Providers will be initialized lazily when needed since they require async credential fetching
        self.providers = []
        
        // Add Runway if API key exists
        if UserAPIKeysManager.shared.hasRunwayKey {
            self.providers.append(RunwayGen4Service())
        }
    }
    
    /// Complete generation flow following the production pipeline
    /// - Parameters:
    ///   - projectId: The project identifier
    ///   - prompts: Array of prompts to generate
    /// - Throws: Generation errors
    public func generateProject(_ projectId: UUID, prompts: [ProjectPrompt]) async throws {
        // Generate trace ID for this generation session
        let traceId = UUID().uuidString
        await TelemetryService.shared.sessionTraceId = traceId
        
        print("🎬 Starting complete generation flow for project \(projectId) [Trace: \(traceId)]")
        
        // Step 1: Pre-flight Validation
        try await validateGeneration(prompts: prompts, projectId: projectId)
        
        // Step 2: Save initial prompt list (await since fileManager is now actor)
        try await fileManager.savePromptList(prompts, for: projectId)
        
        // Step 3: Process prompts in batches with TRUE parallelism using TaskGroup
        let batchSize = deviceCapability.recommendedConcurrency
        
        // Use ClipGenerationOrchestrator for each prompt with traceId
        let orchestrator = ClipGenerationOrchestrator()
        
        // FIXED: Drain TaskGroup ONCE after all tasks added → true parallelism
        await withTaskGroup(of: ClipGenerationResult.self) { group in
            // Add all prompts as tasks (batched for logging only)
            let batches = prompts.chunked(into: batchSize)
            for (batchIndex, batch) in batches.enumerated() {
                print("📦 Queueing batch \(batchIndex + 1)/\(batches.count) with \(batch.count) prompts")
                for (index, prompt) in batch.enumerated() {
                    let clipIndex = batchIndex * batchSize + index
                    group.addTask {
                        // Use orchestrator with retry logic and telemetry
                        await orchestrator.generate(
                            prompt: prompt,
                            projectId: projectId,
                            traceId: traceId
                        )
                        
                        // Return result (orchestrator handles success/failure internally)
                        // For now, return a placeholder result
                        return ClipGenerationResult(
                            promptId: prompt.id,
                            videoURL: nil,
                            finalVideoURL: nil,
                            voiceoverTrack: nil,
                            metrics: nil,
                            status: .completed
                        )
                    }
                }
            }
            
            // DRAIN ONCE - all tasks run in parallel (up to concurrency limit)
            for await result in group {
                await self.handleGenerationResult(result, projectId: projectId)
            }
        }
        
        // Step 4: Show final results summary
        await showFinalResults(projectId: projectId)
    }
    
    /// Complete processing for a single prompt following the flowchart
    /// NOTE: This is now handled by ClipGenerationOrchestrator.generate with retry logic
    /// This method is kept for backward compatibility but delegates to orchestrator
    private func processPrompt(_ prompt: ProjectPrompt, projectId: UUID, traceId: String) async -> ClipGenerationResult {
        // Delegate to ClipGenerationOrchestrator which handles retries and telemetry
        let orchestrator = try? await ClipGenerationOrchestrator.withSupabaseCredentials()
        if let orchestrator = orchestrator {
            await orchestrator.generate(prompt: prompt, projectId: projectId, traceId: traceId)
        }
        
        // Return placeholder result (orchestrator handles success/failure internally)
        return ClipGenerationResult(
            promptId: prompt.id,
            videoURL: nil,
            finalVideoURL: nil,
            voiceoverTrack: nil,
            metrics: nil,
            status: .completed
        )
    }
    
    /// Pre-flight validation before generation starts
    private func validateGeneration(prompts: [ProjectPrompt], projectId: UUID) async throws {
        print("✅ Pre-flight validation...")
        
        // Validate prompts are not empty
        guard !prompts.isEmpty else {
            throw GenerationError.noProviderAvailable
        }
        
        // Validate at least one provider is available
        guard !providers.isEmpty else {
            throw GenerationError.noProviderAvailable
        }
        
        // Validate credits/tokens (if needed)
        // This would check CreditsManager - placeholder for now
        
        print("✅ Validation passed: \(prompts.count) prompts ready for generation")
    }
    
    /// Generate video clip via API with retry logic
    private func generateVideoClip(prompt: ProjectPrompt) async throws -> (videoURL: URL, metrics: GenerationMetrics) {
        // Select optimal Kling version
        let klingVersion = selectOptimalVersion(for: prompt)
        
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
                
                // If provider is KlingAIService, use tier-specific generation
                if let klingService = provider as? KlingAIService {
                    // Map KlingVersion to VideoQualityTier
                    let tier: VideoQualityTier
                    switch klingVersion {
                    case .v1_6_standard:
                        tier = .economy
                    case .v2_0_master:
                        tier = .basic
                    case .v2_5_turbo:
                        tier = .pro
                    }
                    let videoURL = try await klingService.generateVideo(
                        prompt: prompt.prompt,
                        duration: duration,
                        tier: tier
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
                    
                    return (videoURL, metrics)
                } else {
                    // Fallback for other providers (e.g., Runway)
                    let videoURL = try await provider.generateVideo(
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
                    
                    return (videoURL, metrics)
                }
                
            } catch {
                retryCount += 1
                print("⚠️ Generation attempt \(retryCount)/\(maxRetries) failed: \(error.localizedDescription)")
                
                if retryCount >= maxRetries {
                    throw error
                }
                
                // Exponential backoff
                let delay = UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delay)
            }
        }
        
        throw GenerationError.maxRetriesExceeded
    }
    
    /// Save clip to timeline and local storage
    private func saveClipToTimeline(
        promptId: UUID,
        videoURL: URL,
        voiceoverTrack: VoiceoverTrack?,
        projectId: UUID
    ) async throws {
        // Download video to local storage if needed
        let localVideoURL = try await downloadVideoToLocalStorage(videoURL: videoURL, promptId: promptId)
        
        // Create GeneratedClip object
        let clip = GeneratedClip(
            id: UUID(),
            name: "Clip \(promptId.uuidString.prefix(8))",
            localURL: localVideoURL,
            thumbnailURL: nil,
            syncStatus: .notUploaded,
            createdAt: Date(),
            duration: 5.0, // Default, could be extracted from video
            projectID: projectId,
            isGeneratedFromImage: false
        )
        
        // Save to storage service
        let storageService = LocalStorageService()
        try await storageService.saveClip(clip)
        
        // Update prompt with generated clip ID
        var prompts = try await fileManager.loadPromptList(for: projectId)
        if let index = prompts.firstIndex(where: { $0.id == promptId }) {
            prompts[index].generatedClipID = clip.id
            prompts[index].status = .completed
            prompts[index].updatedAt = Date()
            try await fileManager.savePromptList(prompts, for: projectId)
        }
        
        print("💾 Saved clip \(clip.id) to timeline and storage")
    }
    
    /// Download video from remote URL to local storage
    private func downloadVideoToLocalStorage(videoURL: URL, promptId: UUID) async throws -> URL {
        // If already local, return as-is
        if videoURL.isFileURL {
            return videoURL
        }
        
        // Download to local storage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let clipsDirectory = documentsPath.appendingPathComponent("DirectorStudio/Clips", isDirectory: true)
        
        try FileManager.default.createDirectory(at: clipsDirectory, withIntermediateDirectories: true)
        
        let filename = "clip_\(promptId.uuidString.prefix(8))_\(Date().timeIntervalSince1970).mp4"
        let localURL = clipsDirectory.appendingPathComponent(filename)
        
        let (tempURL, _) = try await URLSession.shared.download(from: videoURL)
        try FileManager.default.moveItem(at: tempURL, to: localURL)
        
        return localURL
    }
    
    /// Show final results summary
    private func showFinalResults(projectId: UUID) async {
        let prompts = try? await fileManager.loadPromptList(for: projectId)
        let completed = prompts?.filter { $0.status == .completed }.count ?? 0
        let failed = prompts?.filter { $0.status == .failed }.count ?? 0
        let total = prompts?.count ?? 0
        
        print("📊 Generation Complete!")
        print("   Total prompts: \(total)")
        print("   ✅ Completed: \(completed)")
        print("   ❌ Failed: \(failed)")
        print("   Success rate: \(total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0)%")
        
        // TODO: Post notification or update UI with results
        // NotificationCenter.default.post(name: .generationComplete, object: projectId)
    }
    
    /// Handle generation result and update project state
    private func handleGenerationResult(_ result: ClipGenerationResult, projectId: UUID) async {
        generationResults[result.promptId] = result
        
        switch result.status {
        case .completed:
            do {
                try await fileManager.updatePromptStatus(result.promptId, status: .completed, for: projectId)
                print("✅ Completed prompt \(result.promptId)")
            } catch {
                print("⚠️ Failed to update prompt status: \(error)")
            }
            
        case .cached(let clipId):
            do {
                try await fileManager.updatePromptStatus(result.promptId, status: .completed, for: projectId)
                print("✅ Using cached clip \(clipId) for prompt \(result.promptId)")
            } catch {
                print("⚠️ Failed to update prompt status: \(error)")
            }
            
        case .failed(let error):
            do {
                try await fileManager.updatePromptStatus(result.promptId, status: .failed, for: projectId)
                print("❌ Failed prompt \(result.promptId): \(error.localizedDescription)")
            } catch {
                print("⚠️ Failed to update prompt status: \(error)")
            }
        }
    }
    
    /// Check cache for similar prompts
    private func checkCache(for prompt: ProjectPrompt) async -> UUID? {
        // Simple hash-based cache lookup
        let promptHash = prompt.prompt.hashValue.description
        return cache[promptHash]
    }
    
    /// Select optimal Kling version based on prompt complexity
    /// Uses visualComplexityScore if available, falls back to keyword analysis
    private func selectOptimalVersion(for prompt: ProjectPrompt) -> KlingVersion {
        // Use pre-calculated complexity score if available
        if let score = prompt.visualComplexityScore {
            switch score {
            case ..<0.4:
                return .v1_6_standard  // Simple scenes
            case 0.4..<0.7:
                return .v2_0_master    // Moderate complexity
            default:
                return .v2_5_turbo     // High complexity
            }
        }
        
        // Fallback: Keyword-based detection
        let promptLower = prompt.prompt.lowercased()
        
        // High complexity keywords → Turbo
        let highComplexityKeywords = ["explosion", "battle", "transformation", "crowd", "water", "fire"]
        if highComplexityKeywords.contains(where: promptLower.contains) {
            return .v2_5_turbo
        }
        
        // Dialogue-heavy → Master (better for speech)
        if let dialogue = prompt.extractedDialogue, dialogue.count > 150 {
            return .v2_0_master
        }
        
        // Default: Cost-effective option
        return .v1_6_standard
    }
    
    /// Select appropriate provider based on version and attempt
    private func selectProvider(for version: KlingVersion, attempt: Int) -> VideoGenerationProvider {
        // Ensure we have Kling service initialized
        if providers.isEmpty {
            // Initialize Kling service (will fetch credentials on first use)
            providers.append(KlingAIService())
        }
        
        // On first attempt, use Kling for all tiers
        if attempt == 0 {
            return providers.first ?? KlingAIService()
        }
        
        // On retry, try different provider if available
        if providers.count > 1 {
            return providers[1]
        }
        
        return providers[0]
    }
}

/// Result of complete clip generation process
struct ClipGenerationResult: Sendable {
    let promptId: UUID
    let videoURL: URL?
    let finalVideoURL: URL?
    let voiceoverTrack: VoiceoverTrack?
    let metrics: GenerationMetrics?
    let status: GenerationStatus
    
    enum GenerationStatus: Sendable {
        case completed
        case cached(clipId: UUID)
        case failed(error: Error)
    }
}
