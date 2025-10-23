// MODULE: LocalDataStore
// VERSION: 1.0.0
// PURPOSE: Local data persistence for jobs and clips

import Foundation

class LocalDataStore: ObservableObject {
    @Published var jobs: [PromptJob] = []
    @Published var clips: [ClipAsset] = []
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        jobs = [
            PromptJob(prompt: "A beautiful sunset over mountains"),
            PromptJob(prompt: "A cat playing with a ball of yarn"),
            PromptJob(prompt: "Ocean waves crashing on rocks")
        ]
        
        clips = [
            ClipAsset(title: "Sunset Mountain", prompt: "A beautiful sunset over mountains", status: .completed),
            ClipAsset(title: "Playful Cat", prompt: "A cat playing with a ball of yarn", status: .processing),
            ClipAsset(title: "Ocean Waves", prompt: "Ocean waves crashing on rocks", status: .completed)
        ]
    }
    
    func saveJob(_ job: PromptJob) {
        jobs.append(job)
    }
    
    func saveClip(_ clip: ClipAsset) {
        clips.append(clip)
    }
}
