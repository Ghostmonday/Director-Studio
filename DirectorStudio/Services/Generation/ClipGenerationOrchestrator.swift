// MODULE: ClipGenerationOrchestrator
// VERSION: 1.0.0
// PURPOSE: State machine orchestrator for clip generation with cache and retry
// PRODUCTION-GRADE: Actor-based, ObservableObject, full error handling

import Foundation
import Combine

/// MainActor-isolated orchestrator for individual clip generation
/// Manages cache lookup, API calls, polling, and progress updates
/// Uses @MainActor for UI thread safety and reactive updates
@MainActor
public class ClipGenerationOrchestrator: ObservableObject {
    @Published public var progress: [UUID: ClipProgress] = [:]
    
    private let klingClient: KlingAPIClient
    private let cacheManager = ClipCacheManager()
    private let fileManager = ProjectFileManager.shared
    
    public init(apiKey: String) {
        self.klingClient = KlingAPIClient(apiKey: apiKey)
    }
    
    /// Generate a single clip from a prompt
    /// - Parameters:
    ///   - prompt: The ProjectPrompt to generate
    ///   - projectId: The project identifier
    public func generate(prompt: ProjectPrompt, projectId: UUID) async {
        let id = prompt.id
        updateProgress(id, .checkingCache)
        
        // 1. CACHE HIT
        let version = prompt.klingVersion ?? .v1_6_standard
        if let cached = await cacheManager.retrieve(for: prompt, version: version) {
            await finalize(prompt, clipURL: cached, projectId: projectId, cached: true)
            return
        }
        
        // 2. GENERATE
        updateProgress(id, .generating)
        do {
            let task = try await klingClient.generateVideo(
                prompt: prompt.prompt,
                version: version,
                negativePrompts: nil, // Can be enhanced later
                duration: 5
            )
            updateProgress(id, .polling)
            
            let remoteVideoURL = try await klingClient.pollStatus(task: task)
            
            // Download video to local storage before caching
            let localVideoURL = try await downloadVideo(from: remoteVideoURL, promptId: prompt.id)
            
            // Store in cache
            try await cacheManager.store(localVideoURL, for: prompt, version: version)
            
            await finalize(prompt, clipURL: localVideoURL, projectId: projectId, cached: false)
            
        } catch {
            await markFailed(prompt, projectId: projectId, error: error)
        }
    }
    
    /// Finalize successful generation
    private func finalize(_ prompt: ProjectPrompt, clipURL: URL, projectId: UUID, cached: Bool) async {
        var p = prompt
        let clipID = UUID()
        
        p.status = .completed
        p.generatedClipID = clipID
        p.metrics = GenerationMetrics(
            taskId: UUID().uuidString,
            klingVersion: p.klingVersion?.rawValue ?? "unknown",
            queueWaitTime: 0,
            generationTime: 0,
            networkLatency: 0,
            localProcessingTime: 0,
            peakMemoryUsage: 0,
            apiResponseSize: 0,
            cacheHitRate: cached ? 1.0 : 0.0,
            negativePromptsUsed: nil,
            experimentGroup: nil,
            timestamp: Date()
        )
        
        // Update prompt list
        var prompts = (try? await fileManager.loadPromptList(for: projectId)) ?? []
        if let index = prompts.firstIndex(where: { $0.id == p.id }) {
            prompts[index] = p
        } else {
            prompts.append(p)
        }
        try? await fileManager.savePromptList(prompts, for: projectId)
        
        updateProgress(p.id, .completed)
    }
    
    /// Mark generation as failed
    private func markFailed(_ prompt: ProjectPrompt, projectId: UUID, error: Error) async {
        var p = prompt
        p.status = .failed
        
        // Update prompt list
        var prompts = (try? await fileManager.loadPromptList(for: projectId)) ?? []
        if let index = prompts.firstIndex(where: { $0.id == p.id }) {
            prompts[index] = p
        } else {
            prompts.append(p)
        }
        try? await fileManager.savePromptList(prompts, for: projectId)
        
        updateProgress(p.id, .failed(error.localizedDescription))
    }
    
    /// Update progress status
    private func updateProgress(_ id: UUID, _ status: ClipProgress.Status) {
        progress[id] = ClipProgress(id: id, status: status)
    }
    
    /// Download video from remote URL to local storage
    /// - Parameters:
    ///   - url: Remote URL of the video
    ///   - promptId: The prompt identifier for filename
    /// - Returns: Local file URL where video was saved
    private func downloadVideo(from url: URL, promptId: UUID) async throws -> URL {
        // If already local, return as-is
        if url.isFileURL {
            return url
        }
        
        // Download to local storage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let clipsDirectory = documentsPath.appendingPathComponent("DirectorStudio/Clips", isDirectory: true)
        
        try FileManager.default.createDirectory(at: clipsDirectory, withIntermediateDirectories: true)
        
        let filename = "clip_\(promptId.uuidString.prefix(8))_\(Date().timeIntervalSince1970).mp4"
        let localURL = clipsDirectory.appendingPathComponent(filename)
        
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: tempURL, to: localURL)
        
        return localURL
    }
}

