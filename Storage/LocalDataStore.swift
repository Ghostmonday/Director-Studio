// MODULE: LocalDataStore
// VERSION: 1.0.0
// PURPOSE: Local data persistence for jobs and clips

import Foundation

class LocalDataStore: ObservableObject {
    @Published var jobs: [PromptJob] = []
    @Published var clips: [ClipAsset] = []
    
    private let jobsKey = "saved_jobs"
    private let clipsKey = "saved_clips"
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        // Add mock jobs
        jobs = [
            PromptJob(prompt: "A beautiful sunset over mountains"),
            PromptJob(prompt: "A cat playing with a ball of yarn"),
            PromptJob(prompt: "Ocean waves crashing on rocks")
        ]
        
        // Add mock clips
        clips = [
            ClipAsset(title: "Sunset Mountain", prompt: "A beautiful sunset over mountains", status: .completed),
            ClipAsset(title: "Playful Cat", prompt: "A cat playing with a ball of yarn", status: .processing),
            ClipAsset(title: "Ocean Waves", prompt: "Ocean waves crashing on rocks", status: .completed)
        ]
    }
    
    func saveJob(_ job: PromptJob) {
        jobs.append(job)
        saveData()
    }
    
    func saveClip(_ clip: ClipAsset) {
        clips.append(clip)
        saveData()
    }
    
    private func loadData() {
        // TODO: Implement UserDefaults loading
    }
    
    private func saveData() {
        // TODO: Implement UserDefaults saving
    }
}
