// MODULE: LocalStorageServiceTests
// VERSION: 1.0.0
// PURPOSE: Tests for local-first storage service

import XCTest
@testable import DirectorStudio

final class LocalStorageServiceTests: XCTestCase {
    
    func testProjectOverviewCreation() {
        let project = ProjectOverview(
            projectId: "test-project-1",
            userId: UUID(),
            sceneCount: 5,
            totalDuration: 120.0,
            projectCreatedAt: Date(),
            lastUpdated: Date()
        )
        
        XCTAssertEqual(project.projectId, "test-project-1")
        XCTAssertNotNil(project.userId)
    }
    
    func testSceneDraftCreation() {
        let draft = SceneDraft(
            id: UUID(),
            userId: UUID(),
            projectId: "test-project-1",
            orderIndex: 0,
            promptText: "Test scene",
            duration: 10.0,
            sceneType: "action",
            shotType: "wide",
            archived: false,
            deletedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        XCTAssertEqual(draft.promptText, "Test scene")
        XCTAssertEqual(draft.orderIndex, 0)
    }
    
    func testSyncQueueEnqueue() {
        let queue = SyncQueue()
        let entry = SyncEntry(
            id: UUID(),
            tableName: "scene_drafts",
            operation: .insert,
            payload: ["test": "data"],
            createdAt: Date()
        )
        
        queue.enqueue(entry)
        
        XCTAssertEqual(queue.pendingEntries.count, 1)
    }
}

