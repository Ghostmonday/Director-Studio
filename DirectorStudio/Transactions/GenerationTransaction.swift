import Foundation

actor GenerationTransaction {
    private var reservationID: String?
    private var pendingClips: [GeneratedClip] = []
    private let creditsManager = CreditsManager.shared
    private let repository: ClipRepositoryProtocol
    
    init(repository: ClipRepositoryProtocol) {
        self.repository = repository
    }
    
    func begin(cost: Int) throws {
        // reservationID = creditsManager.reserveCredits(amount: cost)
    }
    
    func addPending(_ clip: GeneratedClip) {
        pendingClips.append(clip)
    }
    
    func commit() async throws {
        guard let id = reservationID else { return }
        for clip in pendingClips {
            try await repository.save(clip)
        }
        // creditsManager.commitReservation(id)
    }
    
    func rollback() {
        guard let id = reservationID else { return }
        pendingClips.removeAll()
        // creditsManager.cancelReservation(id)
    }
}
