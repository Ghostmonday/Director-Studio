//
//  CreditsPurchaseView.swift
//  DirectorStudio
//
//  PURPOSE: Credits purchase UI for monetization
//

import SwiftUI

struct CreditsPurchaseView: View {
    @StateObject private var creditsManager = CreditsManager.shared
    @State private var selectedOption: CreditsManager.PurchaseOption?
    @State private var showingPurchaseAlert = false
    @State private var showingSuccessAlert = false
    
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
                    ForEach(CreditsManager.PurchaseOption.allCases, id: \.self) { option in
                        PurchaseOptionCard(
                            option: option,
                            isSelected: selectedOption == option,
                            action: {
                                selectedOption = option
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Purchase Button
                Button(action: {
                    if let option = selectedOption {
                        showingPurchaseAlert = true
                    }
                }) {
                    HStack {
                        Text("Purchase Credits")
                            .fontWeight(.semibold)
                        
                        if creditsManager.isLoadingCredits {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.leading, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedOption != nil ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(selectedOption == nil || creditsManager.isLoadingCredits)
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
        .alert("Confirm Purchase", isPresented: $showingPurchaseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Purchase") {
                if let option = selectedOption {
                    purchaseCredits(option)
                }
            }
        } message: {
            if let option = selectedOption {
                Text("Purchase \(option.credits) credits for \(option.price)?")
            }
        }
        .alert("Success!", isPresented: $showingSuccessAlert) {
            Button("OK") { }
        } message: {
            if let option = selectedOption {
                Text("You've successfully purchased \(option.credits) credits!")
            }
        }
    }
    
    private func purchaseCredits(_ option: CreditsManager.PurchaseOption) {
        creditsManager.simulatePurchase(option)
        
        // Show success after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingSuccessAlert = true
            selectedOption = nil
        }
    }
}

struct PurchaseOptionCard: View {
    let option: CreditsManager.PurchaseOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(option.name)
                            .font(.headline)
                        
                        if option.isBestValue {
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
                    
                    Text(option.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(option.price)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("$\(String(format: "%.2f", Double(option.price.dropFirst())! / Double(option.credits))) per video")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
