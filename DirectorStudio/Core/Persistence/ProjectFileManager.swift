// MODULE: ProjectFileManager
// VERSION: 1.0.0
// PURPOSE: Persistence layer for project prompt lists

import Foundation

/// Manages saving and loading prompt lists for projects
public class ProjectFileManager {
    public static let shared = ProjectFileManager()
    
    private let documentsURL: URL
    private let promptsDirectory = "Prompts"
    
    private init() {
        self.documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        createDirectoryIfNeeded()
    }
    
    /// Save a list of prompts for a project
    /// - Parameters:
    ///   - prompts: Array of prompts to save
    ///   - projectId: The project identifier
    /// - Throws: Encoding or file system errors
    public func savePromptList(_ prompts: [ProjectPrompt], for projectId: UUID) throws {
        let url = promptsFileURL(for: projectId)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(prompts)
        try data.write(to: url)
    }
    
    /// Load a list of prompts for a project
    /// - Parameter projectId: The project identifier
    /// - Returns: Array of prompts, empty if file doesn't exist
    /// - Throws: Decoding or file system errors
    public func loadPromptList(for projectId: UUID) throws -> [ProjectPrompt] {
        let url = promptsFileURL(for: projectId)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
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
    @MainActor
    public func updatePromptStatus(
        _ promptId: UUID,
        status: ProjectPrompt.GenerationStatus,
        for projectId: UUID
    ) async throws {
        var prompts = try loadPromptList(for: projectId)
        guard let index = prompts.firstIndex(where: { $0.id == promptId }) else {
            return
        }
        prompts[index].status = status
        prompts[index].updatedAt = Date()
        try savePromptList(prompts, for: projectId)
    }
    
    /// Get the file URL for a project's prompts
    /// - Parameter projectId: The project identifier
    /// - Returns: File URL for the prompts JSON file
    private func promptsFileURL(for projectId: UUID) -> URL {
        documentsURL
            .appendingPathComponent(promptsDirectory)
            .appendingPathComponent("\(projectId.uuidString)_prompts.json")
    }
    
    /// Create the prompts directory if it doesn't exist
    private func createDirectoryIfNeeded() {
        let url = documentsURL.appendingPathComponent(promptsDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}

