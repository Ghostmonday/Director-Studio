// MODULE: CreditsService
// VERSION: 1.0.0
// PURPOSE: Service for managing credits with idempotent consumption

import Foundation

class CreditsService: ObservableObject {
    nonisolated(unsafe) static let shared = CreditsService()
    
    @Published var credits: Int = 0
    @Published var firstClipGranted: Bool = false
    @Published var firstClipConsumed: Bool = false
    
    private let localStorage = LocalStorageService.shared
    private let syncService = SyncService.shared
    
    private init() {}
    
    // MARK: - Credits Operations
    
    func getCredits(userKey: String) async throws -> CreditsLedger? {
        if let ledger = localStorage.creditsLedger {
            return ledger
        }
        
        // Fetch from Supabase
        return nil
    }
    
    func adjustCredits(userKey: String, delta: Int) async throws -> Int {
        let transactionId = UUID().uuidString
        
        // Idempotent upsert
        let payload: [String: Any] = [
            "user_key": userKey,
            "delta": delta,
            "transaction_id": transactionId
        ]
        
        try await syncService.enqueueRemoteUpsert(
            tableName: "credits_ledger",
            record: payload
        )
        
        credits += delta
        return credits
    }
    
    func consumeCredits(userKey: String, amount: Int) async throws -> Bool {
        guard credits >= amount else {
            throw CreditsError.insufficientCredits
        }
        
        _ = try await adjustCredits(userKey: userKey, delta: -amount)
        return true
    }
    
    func grantFirstClip(userKey: String) async throws {
        guard !firstClipGranted else { return }
        
        _ = try await adjustCredits(userKey: userKey, delta: 100)
        firstClipGranted = true
        
        // Update first_clip_granted flag
        try await syncService.enqueueRemoteUpsert(
            tableName: "credits_ledger",
            record: [
                "user_key": userKey,
                "first_clip_granted": true
            ]
        )
    }
    
    func checkFirstClipConsumed(userKey: String) -> Bool {
        return firstClipConsumed
    }
    
    func markFirstClipConsumed(userKey: String) async throws {
        guard !firstClipConsumed else { return }
        
        firstClipConsumed = true
        
        try await syncService.enqueueRemoteUpsert(
            tableName: "credits_ledger",
            record: [
                "user_key": userKey,
                "first_clip_consumed": true
            ]
        )
    }
}

enum CreditsError: Error {
    case insufficientCredits
    case transactionFailed
}

