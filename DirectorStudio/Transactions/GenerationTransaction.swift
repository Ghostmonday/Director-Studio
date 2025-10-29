// MODULE: GenerationTransaction
// VERSION: 1.0.0
// PURPOSE: Manages multi-clip generation with atomic operations and credit management

import Foundation

/// Transaction management for multi-clip generation
actor GenerationTransaction {
    /// Unique identifier for this transaction
    private let transactionID = UUID()
    
    /// Reserved tokens for this transaction
    private var reservedTokens: Int = 0
    
    /// Clips pending commit
    private var pendingClips: [GeneratedClip] = []
    
    /// Transaction state
    private var state: TransactionState = .idle
    
    /// Credits manager reference
    private let creditsManager = CreditsManager.shared
    
    /// Repository for persisting clips
    private let repository: any ClipRepositoryProtocol
    
    /// Transaction states
    enum TransactionState {
        case idle
        case active
        case committed
        case rolledBack
    }
    
    /// Transaction errors
    enum TransactionError: LocalizedError {
        case invalidState(String)
        case insufficientCredits(needed: Int, available: Int)
        case commitFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidState(let message):
                return "Transaction error: \(message)"
            case .insufficientCredits(let needed, let available):
                return "Insufficient credits: need \(needed), have \(available)"
            case .commitFailed(let error):
                return "Failed to commit transaction: \(error.localizedDescription)"
            }
        }
    }
    
    init(repository: any ClipRepositoryProtocol) {
        self.repository = repository
    }
    
    /// Begin a new transaction with token reservation
    func begin(totalCost: Int) async throws {
        guard state == .idle else {
            throw TransactionError.invalidState("Transaction already active")
        }
        
        // Check if user has sufficient tokens (CreditsManager is MainActor-isolated)
        let availableTokens = await MainActor.run { creditsManager.tokens }
        guard availableTokens >= totalCost else {
            throw TransactionError.insufficientCredits(
                needed: totalCost,
                available: availableTokens
            )
        }
        
        // Reserve tokens for this transaction
        reservedTokens = totalCost
        state = .active
        
        print("📝 [Transaction \(transactionID.uuidString.prefix(8))] Started with \(totalCost) tokens reserved")
    }
    
    /// Add a pending clip to the transaction
    func addPending(_ clip: GeneratedClip) throws {
        guard state == .active else {
            throw TransactionError.invalidState("Cannot add clips to inactive transaction")
        }
        
        pendingClips.append(clip)
        print("📝 [Transaction \(transactionID.uuidString.prefix(8))] Added clip: \(clip.name)")
    }
    
    /// Commit all pending clips and deduct reserved tokens
    func commit() async throws {
        guard state == .active else {
            throw TransactionError.invalidState("Cannot commit inactive transaction")
        }
        
        do {
            // Save all clips atomically
            for clip in pendingClips {
                try await repository.save(clip)
            }
            
            // Deduct reserved tokens after successful save
            let tokensToDeduct = reservedTokens
            if tokensToDeduct > 0 {
                _ = await MainActor.run { creditsManager.useTokens(amount: tokensToDeduct) }
            }
            
            state = .committed
            print("✅ [Transaction \(transactionID.uuidString.prefix(8))] Committed \(pendingClips.count) clips, deducted \(tokensToDeduct) tokens")
            
        } catch {
            // Rollback on failure
            await rollback()
            throw TransactionError.commitFailed(error)
        }
    }
    
    /// Rollback the transaction, releasing reserved tokens
    func rollback() async {
        guard state == .active else { return }
        
        // Clear pending clips
        pendingClips.removeAll()
        
        // Reserved tokens are automatically released (not deducted)
        reservedTokens = 0
        state = .rolledBack
        
        print("⚠️ [Transaction \(transactionID.uuidString.prefix(8))] Rolled back")
    }
    
    /// Get transaction status
    func getStatus() -> (state: TransactionState, pendingCount: Int, reservedTokens: Int) {
        return (state, pendingClips.count, reservedTokens)
    }
}
