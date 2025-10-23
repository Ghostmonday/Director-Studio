// MODULE: SceneEditorViewModel
// VERSION: 1.0.0
// PURPOSE: ViewModel for scene editing with optimistic creates

import Foundation
import SwiftUI

@MainActor
class SceneEditorViewModel: ObservableObject {
    @Published var scenes: [SceneDraft] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let localStorage = LocalStorageService.shared
    private let syncService = SyncService.shared
    
    // MARK: - Load Scenes
    
    func loadScenes(projectId: String) {
        isLoading = true
        
        // Load local immediately
        scenes = localStorage.getSceneDrafts(projectId: projectId)
        isLoading = false
        
        // Sync with remote
        Task { @MainActor [weak self] in
            await self?.syncScenes(projectId: projectId)
        }
    }
    
    private func syncScenes(projectId: String) async {
        // Fetch from Supabase and reconcile
    }
    
    // MARK: - Optimistic Create
    
    func createSceneOptimistic(prompt: String, duration: Double) -> UUID {
        let tempId = UUID()
        let scene = SceneDraft(
            id: tempId,
            userId: UUID(), // Will be set from auth
            projectId: "", // Will be set from current project
            orderIndex: scenes.count,
            promptText: prompt,
            duration: duration,
            sceneType: nil,
            shotType: nil,
            archived: false,
            deletedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Local optimistic insert
        localStorage.upsertSceneDraft(scene)
        scenes.append(scene)
        
        // Enqueue remote sync
        Task { @MainActor [weak self] in
            await self?.enqueueSceneSync(scene)
        }
        
        return tempId
    }
    
    private func enqueueSceneSync(_ scene: SceneDraft) async {
        do {
            let payload: [String: Any] = [
                "id": scene.id.uuidString,
                "user_id": scene.userId.uuidString,
                "project_id": scene.projectId,
                "order_index": scene.orderIndex,
                "prompt_text": scene.promptText,
                "duration": scene.duration
            ]
            
            try await syncService.enqueueRemoteUpsert(
                tableName: "scene_drafts",
                record: payload
            )
        } catch {
            print("⚠️ Failed to sync scene: \(error)")
        }
    }
    
    // MARK: - Scene Management
    
    func reorderScenes(orderedIds: [UUID]) {
        for (index, id) in orderedIds.enumerated() {
            if let sceneIndex = scenes.firstIndex(where: { $0.id == id }) {
                scenes[sceneIndex].orderIndex = index
            }
        }
        
        // Persist reorder
        localStorage.saveLocalData()
    }
    
    func saveScene(id: UUID, patch: [String: Any]) {
        // Update scene with patch
        // Enqueue sync
    }
    
    func deleteScene(id: UUID) {
        localStorage.markSceneDraftArchived(id)
        scenes.removeAll { $0.id == id }
    }
}

