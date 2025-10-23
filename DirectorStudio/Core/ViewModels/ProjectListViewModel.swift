// MODULE: ProjectListViewModel
// VERSION: 1.0.0
// PURPOSE: ViewModel for project list with local-first pattern

import Foundation
import SwiftUI

class ProjectListViewModel: ObservableObject {
    @Published var items: [ProjectOverview] = []
    @Published var status: LoadStatus = .idle
    @Published var error: String?
    @Published var lastLoadedAt: Date?
    
    private let localStorage = LocalStorageService.shared
    private let syncService = SyncService.shared
    
    enum LoadStatus {
        case idle
        case loading
        case loaded
        case error
    }
    
    // MARK: - Local-First Load
    
    func loadList(userId: UUID) {
        // Render local cache immediately (≤150ms requirement)
        let startTime = Date()
        items = localStorage.getProjectOverviews(userId: userId)
        lastLoadedAt = Date()
        
        let renderTime = Date().timeIntervalSince(startTime) * 1000
        print("✅ Local render in \(Int(renderTime))ms")
        
        // Then sync with remote
        Task {
            await syncWithRemote(userId: userId)
        }
    }
    
    private func syncWithRemote(userId: UUID) async {
        status = .loading
        
        do {
            // Fetch from Supabase
            // For now, just mark as loaded
            status = .loaded
            lastLoadedAt = Date()
        } catch {
            status = .error
            self.error = error.localizedDescription
        }
    }
    
    // MARK: - Optimistic Create
    
    func createProjectQuick(prompt: String?) -> String {
        let tempProjectId = UUID().uuidString
        let project = ProjectOverview(
            projectId: tempProjectId,
            userId: nil, // Will be set after auth
            sceneCount: 0,
            totalDuration: 0,
            projectCreatedAt: Date(),
            lastUpdated: Date()
        )
        
        // Local optimistic insert
        localStorage.upsertProjectOverview(project)
        items.append(project)
        
        // Enqueue remote sync
        Task {
            await enqueueProjectSync(project)
        }
        
        return tempProjectId
    }
    
    private func enqueueProjectSync(_ project: ProjectOverview) async {
        do {
            let payload: [String: Any] = [
                "project_id": project.projectId,
                "user_id": project.userId?.uuidString ?? "",
                "scene_count": project.sceneCount ?? 0,
                "total_duration": project.totalDuration ?? 0
            ]
            
            try await syncService.enqueueRemoteUpsert(
                tableName: "project_overview",
                record: payload
            )
        } catch {
            print("⚠️ Failed to sync project: \(error)")
        }
    }
    
    // MARK: - Quick Actions
    
    func rename(id: String, name: String) {
        // TODO: Implement rename
    }
    
    func duplicate(id: String) {
        // TODO: Implement duplicate
    }
    
    func archive(id: String) {
        // TODO: Implement archive
    }
}

