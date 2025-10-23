// MODULE: DirectorStudioTests
// VERSION: 1.0.0
// PURPOSE: Basic test suite for app functionality

import XCTest
@testable import DirectorStudio

final class DirectorStudioTests: XCTestCase {
    
    func testPromptJobCreation() {
        let prompt = "A beautiful sunset"
        let job = PromptJob(prompt: prompt)
        
        XCTAssertEqual(job.prompt, prompt)
        XCTAssertEqual(job.status, .pending)
        XCTAssertNotNil(job.id)
    }
    
    func testClipAssetCreation() {
        let title = "Test Clip"
        let prompt = "Test prompt"
        let clip = ClipAsset(title: title, prompt: prompt)
        
        XCTAssertEqual(clip.title, title)
        XCTAssertEqual(clip.prompt, prompt)
        XCTAssertEqual(clip.status, .processing)
        XCTAssertNotNil(clip.id)
    }
    
    func testCoordinatorNavigation() {
        let coordinator = Coordinator()
        XCTAssertEqual(coordinator.currentView, .promptInput)
        
        coordinator.navigateTo(.clipPreview)
        XCTAssertEqual(coordinator.currentView, .clipPreview)
    }
}
