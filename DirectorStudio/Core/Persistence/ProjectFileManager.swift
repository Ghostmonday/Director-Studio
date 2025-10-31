// MODULE: ProjectFileManager
// VERSION: 2.0.0
// PURPOSE: Thread-safe persistence layer for project prompt lists
// PRODUCTION-GRADE: Actor-based, atomic writes, per-project directories

import Foundation

/// Thread-safe manager for saving and loading prompt lists for projects
/// Uses actor isolation to prevent race conditions during concurrent access
public actor ProjectFileManager {
    public static let shared = ProjectFileManager()
    
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private init() {
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    /// Save a list of prompts for a project with atomic write
    /// - Parameters:
    ///   - prompts: Array of prompts to save
    ///   - projectId: The project identifier
    /// - Throws: Encoding or file system errors
    public func savePromptList(_ prompts: [ProjectPrompt], for projectId: UUID) async throws {
        let projectDir = try projectDirectory(for: projectId)
        let url = projectDir.appendingPathComponent("prompts.json")
        
        let data = try encoder.encode(prompts)
        
        // ATOMIC + COORDINATED write to prevent corruption
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var writeError: Error?
        
        coordinator.coordinate(writingItemAt: url, options: .forMerging, error: &coordinationError) { coordinatedURL in
            do {
                try data.write(to: coordinatedURL, options: .atomic)
            } catch {
                writeError = error
            }
        }
        
        if let coordinationError {
            throw coordinationError
        }
        if let writeError {
            throw writeError
        }
    }
    
    /// Load a list of prompts for a project
    /// - Parameter projectId: The project identifier
    /// - Returns: Array of prompts, empty if file doesn't exist
    /// - Throws: Decoding or file system errors
    public func loadPromptList(for projectId: UUID) async throws -> [ProjectPrompt] {
        let projectDir = try projectDirectory(for: projectId)
        let url = projectDir.appendingPathComponent("prompts.json")
        
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var readError: Error?
        var data: Data?
        
        coordinator.coordinate(readingItemAt: url, options: .withoutDeleting, error: &coordinationError) { coordinatedURL in
            do {
                data = try Data(contentsOf: coordinatedURL)
            } catch {
                readError = error
            }
        }
        
        if let coordinationError {
            throw coordinationError
        }
        if let readError {
            throw readError
        }
        
        guard let data else {
            return []
        }
        
        return try decoder.decode([ProjectPrompt].self, from: data)
    }
    
    /// Migrate legacy string prompts to ProjectPrompt format
    /// - Parameters:
    ///   - stringPrompts: Array of prompt strings from old system
    ///   - projectId: The project identifier
    /// - Returns: Array of ProjectPrompt objects
    public func migrateLegacyPrompts(_ stringPrompts: [String], for projectId: UUID) -> [ProjectPrompt] {
        return stringPrompts.enumerated().map { index, prompt in
            ProjectPrompt(
                id: UUID(),
                index: index,
                prompt: prompt,
                status: .pending,
                klingVersion: .v1_6_standard, // Default for legacy
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
    
    /// Update the status of a specific prompt
    /// - Parameters:
    ///   - promptId: The prompt identifier
    ///   - status: New status to set
    ///   - projectId: The project identifier
    /// - Throws: File system or encoding errors
    public func updatePromptStatus(
        _ promptId: UUID,
        status: ProjectPrompt.GenerationStatus,
        for projectId: UUID
    ) async throws {
        var prompts = try await loadPromptList(for: projectId)
        guard let index = prompts.firstIndex(where: { $0.id == promptId }) else {
            return
        }
        prompts[index].status = status
        prompts[index].updatedAt = Date()
        try await savePromptList(prompts, for: projectId)
    }
    
    /// Get the project directory for a specific project
    /// Creates directory structure: DirectorStudio/Projects/{projectId}/
    /// - Parameter projectId: The project identifier
    /// - Returns: URL to the project directory
    /// - Throws: File system errors
    private func projectDirectory(for projectId: UUID) throws -> URL {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("DirectorStudio/Projects/\(projectId.uuidString)", isDirectory: true)
        try ensureDirectoryExists(at: dir)
        return dir
    }
    
    /// Ensure directory exists, creating if necessary
    /// - Parameter url: Directory URL to ensure exists
    /// - Throws: File system errors
    private func ensureDirectoryExists(at url: URL) throws {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        if !exists {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } else if !isDirectory.boolValue {
            throw NSError(domain: "ProjectFileManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Path exists but is not a directory"])
        }
    }
}
