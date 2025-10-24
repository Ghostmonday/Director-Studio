//
//  CreditsPurchaseView.swift
//  DirectorStudio
//
//  PURPOSE: Credits purchase UI for monetization
//

import SwiftUI
import StoreKit

struct CreditsPurchaseView: View {
    @StateObject private var creditsManager = CreditsManager.shared
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var selectedProduct: Product?
    @State private var showingPurchaseAlert = false
    @State private var showingSuccessAlert = false
    @State private var isPurchasing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current Credits
                VStack(spacing: 8) {
                    Text("Current Credits")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(creditsManager.credits)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(creditsManager.credits > 0 ? .primary : .red)
                        
                        Text("credits")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                    }
                    
                    if creditsManager.credits == 0 {
                        Text("You're in Demo Mode")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Info Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Each credit = 1 video generation", systemImage: "film")
                    Label("Credits never expire", systemImage: "infinity")
                    Label("Use real AI models (not demo)", systemImage: "cpu")
                }
                .font(.subheadline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Purchase Options
                VStack(spacing: 16) {
                    if storeManager.isLoading {
                        ProgressView("Loading products...")
                            .padding()
                    } else if storeManager.products.isEmpty {
                        Text("No products available")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(storeManager.products, id: \.id) { product in
                            StoreProductCard(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                action: {
                                    selectedProduct = product
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                // Purchase Button
                Button(action: {
                    if let product = selectedProduct {
                        Task {
                            await purchaseProduct(product)
                        }
                    }
                }) {
                    HStack {
                        Text("Purchase Credits")
                            .fontWeight(.semibold)
                        
                        if isPurchasing {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.leading, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedProduct != nil && !isPurchasing ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(selectedProduct == nil || isPurchasing)
                .padding(.horizontal)
                .padding(.top)
                
                // Footer
                Text("All purchases are processed securely through the App Store")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Get Credits")
        .navigationBarTitleDisplayMode(.large)
        .alert("Purchase Complete!", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Credits have been added to your account!")
        }
        .onAppear {
            Task {
                await storeManager.loadProducts()
            }
        }
    }
    
    private func purchaseProduct(_ product: Product) async {
        isPurchasing = true
        
        let success = await storeManager.purchase(product)
        
        isPurchasing = false
        
        if success {
            showingSuccessAlert = true
            selectedProduct = nil
        }
    }
}

struct StoreProductCard: View {
    let product: Product
    let isSelected: Bool
    let action: () -> Void
    
    // Extract credits from product ID
    var creditCount: Int {
        if product.id.contains("starter") { return 10 }
        else if product.id.contains("popular") { return 30 }
        else if product.id.contains("professional") { return 100 }
        else { return 0 }
    }
    
    var isBestValue: Bool {
        product.id.contains("popular")
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        
                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                    }
                    
                    Text("\(creditCount) video generations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if creditCount > 0 {
                        let pricePerVideo = product.price / Decimal(creditCount)
                        Text("~$\(pricePerVideo, format: .currency(code: product.priceFormatStyle.currencyCode)) per video")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.05) : Color(.systemBackground))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        CreditsPurchaseView()
    }
}
