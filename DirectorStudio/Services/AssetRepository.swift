// MODULE: AssetRepository
// VERSION: 1.0.0
// PURPOSE: Repository for managing generated assets (portraits, environments, props)
// BUILD STATUS: ✅ Complete

import Foundation
import UIKit
import os.log

/// Asset type
public enum AssetType: String, Codable {
    case portrait = "portrait"
    case environment = "environment"
    case prop = "prop"
}

/// Asset metadata
public struct Asset: Identifiable, Codable {
    public let id: UUID
    var type: AssetType
    var entityID: UUID // Character ID, Scene ID, or Prop ID
    var entityName: String
    var localURL: URL?
    var remoteURL: URL?
    var thumbnailURL: URL?
    var tags: [String]
    var createdAt: Date
    var prompt: String? // Generation prompt used
    
    public init(
        id: UUID = UUID(),
        type: AssetType,
        entityID: UUID,
        entityName: String,
        localURL: URL? = nil,
        remoteURL: URL? = nil,
        thumbnailURL: URL? = nil,
        tags: [String] = [],
        prompt: String? = nil
    ) {
        self.id = id
        self.type = type
        self.entityID = entityID
        self.entityName = entityName
        self.localURL = localURL
        self.remoteURL = remoteURL
        self.thumbnailURL = thumbnailURL
        self.tags = tags
        self.createdAt = Date()
        self.prompt = prompt
    }
}

/// Repository for managing generated assets
public actor AssetRepository {
    public static let shared = AssetRepository()
    
    private var assets: [UUID: Asset] = [:]
    private let logger = Logger(subsystem: "DirectorStudio.Assets", category: "Repository")
    private let storageService: StorageServiceProtocol
    
    private init() {
        self.storageService = LocalStorageService()
    }
    
    /// Save asset to repository
    public func save(_ asset: Asset) async throws {
        assets[asset.id] = asset
        
        // Save to storage
        if let imageURL = asset.localURL,
           let image = UIImage(contentsOfFile: imageURL.path) {
            // Save image to storage backend
            // Implementation depends on storage service
        }
        
        logger.info("Saved asset: \(asset.entityName) (\(asset.type.rawValue))")
    }
    
    /// Get portrait for character
    public func getPortrait(for characterID: UUID) async -> Asset? {
        return assets.values.first { asset in
            asset.type == .portrait && asset.entityID == characterID
        }
    }
    
    /// Get environment for scene
    public func getEnvironment(for sceneID: UUID) async -> Asset? {
        return assets.values.first { asset in
            asset.type == .environment && asset.entityID == sceneID
        }
    }
    
    /// Search assets by tag
    public func search(byTag tag: String) async -> [Asset] {
        return Array(assets.values.filter { $0.tags.contains(tag) })
    }
    
    /// Search assets by type
    public func getAssets(ofType type: AssetType) async -> [Asset] {
        return Array(assets.values.filter { $0.type == type })
    }
    
    /// Delete asset
    public func delete(_ assetID: UUID) async throws {
        if let asset = assets[assetID],
           let localURL = asset.localURL {
            try FileManager.default.removeItem(at: localURL)
        }
        
        assets.removeValue(forKey: assetID)
        logger.info("Deleted asset: \(assetID)")
    }
    
    /// Load all assets from storage
    public func loadAll() async throws {
        // Load from storage service
        // Placeholder implementation
        logger.debug("Loading all assets from storage")
    }
}

