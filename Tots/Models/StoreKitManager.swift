import Foundation
import StoreKit
import SwiftUI

// MARK: - Product Identifiers
struct ProductIdentifiers {
    static let adRemoval = "com.growwithtots.tots.ad_removal"
}

// MARK: - Purchase Status
enum PurchaseStatus {
    case notPurchased
    case purchased
    case pending
    case failed(Error)
    case restored
}

// MARK: - StoreKit Manager
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchaseStatus: PurchaseStatus = .notPurchased
    @Published var isLoading = false
    @Published var hasAdRemoval = false
    
    private var transactionListener: Task<Void, Error>?
    
    private init() {
        // Start listening for transactions
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
            await checkPurchaseStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Loading
    func loadProducts() async {
        isLoading = true
        
        do {
            let products = try await Product.products(for: [ProductIdentifiers.adRemoval])
            await MainActor.run {
                self.products = products
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.purchaseStatus = .failed(error)
            }
        }
    }
    
    // MARK: - Purchase Methods
    func purchase(_ product: Product) async {
        isLoading = true
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchaseStatus(for: transaction)
                await transaction.finish()
                
            case .userCancelled:
                await MainActor.run {
                    self.isLoading = false
                    // Don't change purchase status on cancellation
                }
                
            case .pending:
                await MainActor.run {
                    self.isLoading = false
                    self.purchaseStatus = .pending
                }
                
            @unknown default:
                await MainActor.run {
                    self.isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.purchaseStatus = .failed(error)
            }
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        
        do {
            try await AppStore.sync()
            await checkPurchaseStatus()
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.purchaseStatus = .failed(error)
            }
        }
    }
    
    // MARK: - Purchase Status Check
    func checkPurchaseStatus() async {
        var hasAdRemovalPurchase = false
        
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == ProductIdentifiers.adRemoval {
                    hasAdRemovalPurchase = true
                    break
                }
            } catch {
                // Handle verification failure
                continue
            }
        }
        
        await MainActor.run {
            self.hasAdRemoval = hasAdRemovalPurchase
            self.purchaseStatus = hasAdRemovalPurchase ? .purchased : .notPurchased
            self.isLoading = false
            
            // Save to UserDefaults for quick access
            UserDefaults.standard.set(hasAdRemovalPurchase, forKey: "ad_removal_purchased")
        }
    }
    
    // MARK: - Transaction Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Transaction Updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await updatePurchaseStatus(for: transaction)
                    await transaction.finish()
                } catch {
                    // Handle transaction update error
                }
            }
        }
    }
    
    private func updatePurchaseStatus(for transaction: StoreKit.Transaction) async {
        if transaction.productID == ProductIdentifiers.adRemoval {
            await MainActor.run {
                self.hasAdRemoval = true
                self.purchaseStatus = .purchased
                self.isLoading = false
                
                // Save to UserDefaults
                UserDefaults.standard.set(true, forKey: "ad_removal_purchased")
            }
        }
    }
}

// MARK: - Store Errors
enum StoreError: Error {
    case failedVerification
}

// MARK: - Convenience Methods
extension StoreKitManager {
    var adRemovalProduct: Product? {
        products.first { $0.id == ProductIdentifiers.adRemoval }
    }
    
    var shouldShowAds: Bool {
        return !hasAdRemoval
    }
    
    // Quick check from UserDefaults (for app launch performance)
    static var hasAdRemovalQuickCheck: Bool {
        return UserDefaults.standard.bool(forKey: "ad_removal_purchased")
    }
}
