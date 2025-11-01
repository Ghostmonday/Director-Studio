//
//  StoreKitManager.swift
//  DirectorStudio
//
//  Handles real in-app purchases with StoreKit 2
//

import Foundation
import StoreKit

@MainActor
public final class StoreKitManager: ObservableObject {
    public static let shared = StoreKitManager()
    
    @Published public var products: [Product] = []
    @Published public var purchasedProductIDs = Set<String>()
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    // Product IDs - must match App Store Connect
    private let productIDs = [
        "com.directorstudio.credits.starter",     // 10 credits for $4.99
        "com.directorstudio.credits.popular",     // 30 credits for $9.99
        "com.directorstudio.credits.professional" // 100 credits for $24.99
    ]
    
    private var updates: Task<Void, Never>? = nil
    
    private init() {
        updates = observeTransactionUpdates()
    }
    
    deinit {
        updates?.cancel()
    }
    
    // Load products from App Store
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIDs)
            isLoading = false
        } catch {
            print("Failed to load products: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    // Purchase a product
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Add credits based on product ID
                addCreditsForProduct(transaction.productID)
                
                // Finish transaction
                await transaction.finish()
                
                return true
                
            case .userCancelled:
                return false
                
            case .pending:
                // Handle pending transactions (parental controls, etc)
                return false
                
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // Verify transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // Observe transaction updates
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    
                    // Add credits for any unfinished transactions
                    if transaction.revocationDate == nil {
                        addCreditsForProduct(transaction.productID)
                    }
                    
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // Add credits based on product
    private func addCreditsForProduct(_ productID: String) {
        let creditsToAdd: Int
        
        switch productID {
        case "com.directorstudio.credits.starter":
            creditsToAdd = 10
        case "com.directorstudio.credits.popular":
            creditsToAdd = 30
        case "com.directorstudio.credits.professional":
            creditsToAdd = 100
        default:
            return
        }
        
        CreditsManager.shared.addCredits(creditsToAdd)
        print("✅ Added \(creditsToAdd) credits for purchase: \(productID)")
    }
    
    // Restore purchases
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            print("Restore failed: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    enum StoreError: Error {
        case failedVerification
    }
}
