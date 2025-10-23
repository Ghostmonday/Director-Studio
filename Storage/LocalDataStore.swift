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
        loadData()
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
