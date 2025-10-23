//
//  InfrastructureModules.swift
//  DirectorStudio
//
//  MODULE: Infrastructure Suite
//  VERSION: 1.0.0
//  PURPOSE: Persistence & Monetization (stub implementations)
//

import Foundation

// MARK: - Persistence Manager

/// Manages project and segment persistence (stub - file storage pending)
public protocol PersistenceManagerProtocol: Sendable {
    func saveProject(_ project: Project) throws -> Project
    func getProject(id: UUID) async throws -> Project?
    func getAllProjects() async throws -> [Project]
    func deleteProject(id: UUID) async throws
    func saveSegments(_ segments: [PromptSegment], projectId: UUID) async throws
    func getSegments(projectId: UUID) async throws -> [PromptSegment]
}

public final class FilePersistenceManager: PersistenceManagerProtocol, @unchecked Sendable {
    private let fileManager = FileManager.default
    private let documentsURL: URL
    
    public init() throws {
        documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("DirectorStudio", isDirectory: true)
        
        // Create directory if needed
        try? fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true)
    }
    
    public func saveProject(_ project: Project) throws -> Project {
        let projectURL = documentsURL.appendingPathComponent("Projects/\(project.id.uuidString).json")
        try? fileManager.createDirectory(at: projectURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(project)
        try data.write(to: projectURL)
        
        return project
    }
    
    public func getProject(id: UUID) async throws -> Project? {
        let projectURL = documentsURL.appendingPathComponent("Projects/\(id.uuidString).json")
        
        guard fileManager.fileExists(atPath: projectURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: projectURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Project.self, from: data)
    }
    
    public func getAllProjects() async throws -> [Project] {
        let projectsURL = documentsURL.appendingPathComponent("Projects")
        
        guard fileManager.fileExists(atPath: projectsURL.path) else {
            return []
        }
        
        let files = try fileManager.contentsOfDirectory(at: projectsURL, includingPropertiesForKeys: nil)
        var projects: [Project] = []
        
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let project = try? decoder.decode(Project.self, from: data) {
                    projects.append(project)
                }
            }
        }
        
        return projects.sorted { $0.createdAt > $1.createdAt }
    }
    
    public func deleteProject(id: UUID) async throws {
        let projectURL = documentsURL.appendingPathComponent("Projects/\(id.uuidString).json")
        try? fileManager.removeItem(at: projectURL)
        
        // Also delete associated segments
        let segmentsURL = documentsURL.appendingPathComponent("Segments/\(id.uuidString).json")
        try? fileManager.removeItem(at: segmentsURL)
    }
    
    public func saveSegments(_ segments: [PromptSegment], projectId: UUID) async throws {
        let segmentsURL = documentsURL.appendingPathComponent("Segments/\(projectId.uuidString).json")
        try? fileManager.createDirectory(at: segmentsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(segments)
        try data.write(to: segmentsURL)
    }
    
    public func getSegments(projectId: UUID) async throws -> [PromptSegment] {
        let segmentsURL = documentsURL.appendingPathComponent("Segments/\(projectId.uuidString).json")
        
        guard fileManager.fileExists(atPath: segmentsURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: segmentsURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([PromptSegment].self, from: data)
    }
}

// MARK: - Monetization Manager

/// Manages credits and in-app purchases (stub - StoreKit integration pending)
public protocol MonetizationManagerProtocol: Sendable {
    func getAvailableCredits() async -> Int
    func canAfford(_ credits: Int) async -> Bool
    func useCredits(_ credits: Int) async throws
    func addCredits(_ credits: Int) async throws
}

public final class MockMonetizationManager: MonetizationManagerProtocol, @unchecked Sendable {
    private let persistenceManager: PersistenceManagerProtocol
    private var credits: Int = 100 // Start with 100 free credits
    
    public init(persistenceManager: PersistenceManagerProtocol) {
        self.persistenceManager = persistenceManager
    }
    
    public func getAvailableCredits() async -> Int {
        return credits
    }
    
    public func canAfford(_ credits: Int) async -> Bool {
        return self.credits >= credits
    }
    
    public func useCredits(_ credits: Int) async throws {
        guard self.credits >= credits else {
            throw MonetizationError.insufficientCredits(required: credits, available: self.credits)
        }
        
        self.credits -= credits
        
        await Telemetry.shared.logEvent(
            "CreditsUsed",
            metadata: [
                "amount": "\(credits)",
                "remaining": "\(self.credits)"
            ]
        )
    }
    
    public func addCredits(_ credits: Int) async throws {
        self.credits += credits
        
        await Telemetry.shared.logEvent(
            "CreditsAdded",
            metadata: [
                "amount": "\(credits)",
                "total": "\(self.credits)"
            ]
        )
    }
}

// MARK: - Supporting Types

public enum MonetizationError: Error, LocalizedError {
    case insufficientCredits(required: Int, available: Int)
    case purchaseFailed(reason: String)
    case invalidProduct
    
    public var errorDescription: String? {
        switch self {
        case .insufficientCredits(let required, let available):
            return "Insufficient credits. Required: \(required), Available: \(available)"
        case .purchaseFailed(let reason):
            return "Purchase failed: \(reason)"
        case .invalidProduct:
            return "Invalid product"
        }
    }
}

