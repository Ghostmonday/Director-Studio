// MODULE: EnhancedCreditsPurchaseView
// VERSION: 2.0.0
// PURPOSE: Beautiful credit purchase screen with packs, plans, and special offers

import SwiftUI
import StoreKit

struct EnhancedCreditsPurchaseView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var creditsManager = CreditsManager.shared
    @StateObject private var storeManager = StoreKitManager.shared
    @State private var selectedOption: PurchaseOption?
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var animateIn = false
    @State private var showingSuccessConfetti = false
    
    enum PurchaseOption: String, CaseIterable {
        case starter = "tokens_500"
        case pro = "tokens_2200"
        case unlimited = "tokens_6000"
        
        var bundle: TokenBundle {
            switch self {
            case .starter: return TokenBundle.bundles[0]
            case .pro: return TokenBundle.bundles[2]
            case .unlimited: return TokenBundle.bundles[3]
            }
        }
        
        var tokens: Int {
            bundle.tokens
        }
        
        var credits: Int { // Legacy support
            tokens / 100
        }
        
        var price: String {
            bundle.displayPrice
        }
        
        var savings: String? {
            bundle.savingsText
        }
        
        var badge: String? {
            bundle.badge
        }
        
        var color: Color {
            switch self {
            case .starter: return .blue
            case .pro: return .purple
            case .unlimited: return .orange
            }
        }
        
        var features: [String] {
            let quality = VideoQualityTier.medium
            let estimatedVideos = TokenCalculator.estimateVideos(tokens: tokens, duration: 10, quality: quality)
            
            switch self {
            case .starter:
                return ["Try it out", "~\(estimatedVideos) videos", "All quality tiers"]
            case .pro:
                return ["Most popular", "~\(estimatedVideos) videos", bundle.savingsText ?? "", "Priority support"]
            case .unlimited:
                return ["Best value", "~\(estimatedVideos) videos", bundle.savingsText ?? "", "Early access", "Premium support"]
            }
        }
    }
    
    var firstTimePurchaseBonus: Bool {
        !UserDefaults.standard.bool(forKey: "has_made_purchase")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color.purple.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerView
                            .padding(.top)
                        
                        // Current balance
                        currentBalanceCard
                        
                        // First-time bonus banner
                        if firstTimePurchaseBonus {
                            firstTimeBonusBanner
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Purchase options
                        VStack(spacing: 16) {
                            ForEach(Array(PurchaseOption.allCases.enumerated()), id: \.element) { index, option in
                                PurchaseOptionCard(
                                    option: option,
                                    isSelected: selectedOption == option,
                                    onTap: { selectedOption = option }
                                )
                                .scaleEffect(animateIn ? 1 : 0.9)
                                .opacity(animateIn ? 1 : 0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.1),
                                    value: animateIn
                                )
                            }
                        }
                        
                        // Features comparison
                        featuresSection
                        
                        // Purchase button
                        purchaseButton
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal)
                }
                
                // Success confetti overlay
                if showingSuccessConfetti {
                    ConfettiView()
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Get Credits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: restorePurchases) {
                        Label("Restore", systemImage: "arrow.clockwise")
                    }
                }
            }
        }
        .alert("Purchase Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            selectedOption = .pro // Default selection
            withAnimation {
                animateIn = true
            }
        }
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(animateIn ? 0 : -15))
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateIn)
            
            VStack(spacing: 8) {
                Text("Purchase Credits")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Choose your pack and start creating")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var currentBalanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Text("\(creditsManager.credits)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("credits")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if creditsManager.credits == 0 {
                Label("Empty", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Label("\(creditsManager.credits / 5) videos", systemImage: "film")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var firstTimeBonusBanner: some View {
        HStack {
            Image(systemName: "gift.fill")
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("First Purchase Bonus!")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("Get 2 extra credits with any pack")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.green, .blue],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Plans Include")
                .font(.headline)
                .padding(.bottom, 4)
            
            ForEach(commonFeatures, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(feature)
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var commonFeatures = [
        "AI-powered video generation",
        "All visual styles and effects",
        "Export in multiple formats",
        "Cloud storage sync",
        "No watermarks"
    ]
    
    private var purchaseButton: some View {
        Button(action: purchaseSelected) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "creditcard.fill")
                    Text(purchaseButtonText)
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: selectedOption != nil ? [.blue, .purple] : [.gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: selectedOption != nil ? .blue.opacity(0.3) : .clear, radius: 10, y: 5)
        }
        .disabled(selectedOption == nil || isPurchasing)
        .scaleEffect(selectedOption != nil ? 1 : 0.95)
        .animation(.spring(response: 0.3), value: selectedOption)
    }
    
    private var purchaseButtonText: String {
        guard let option = selectedOption else {
            return "Select a Plan"
        }
        
        let bonus = firstTimePurchaseBonus ? " + 2 Bonus" : ""
        return "Get \(option.credits)\(bonus) Credits • \(option.price)"
    }
    
    // MARK: - Actions
    
    private func purchaseSelected() {
        guard let option = selectedOption else { return }
        
        isPurchasing = true
        
        Task {
            do {
                // Simulate purchase for now
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                await MainActor.run {
                    // Add credits
                    var creditsToAdd = option.credits
                    if firstTimePurchaseBonus {
                        creditsToAdd += 2
                        UserDefaults.standard.set(true, forKey: "has_made_purchase")
                    }
                    
                    creditsManager.addCredits(creditsToAdd)
                    isPurchasing = false
                    
                    // Show success
                    showingSuccessConfetti = true
                    
                    // Haptic feedback
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    
                    // Dismiss after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func restorePurchases() {
        // Restore purchases logic
    }
}

// MARK: - Purchase Option Card

struct PurchaseOptionCard: View {
    let option: EnhancedCreditsPurchaseView.PurchaseOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(option.credits) Credits")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(option.price)
                        .font(.title3)
                        .foregroundColor(option.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let badge = option.badge {
                        Text(badge)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(option.color)
                            .cornerRadius(6)
                    }
                    
                    if let savings = option.savings {
                        Text(savings)
                            .font(.caption)
                            .foregroundColor(option.color)
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Features
            VStack(alignment: .leading, spacing: 8) {
                ForEach(option.features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(option.color)
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? option.color : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
        )
        .shadow(color: isSelected ? option.color.opacity(0.2) : .clear, radius: 10, y: 5)
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(.spring(response: 0.3), value: isSelected)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        let color: Color
        let x: CGFloat
        let startY: CGFloat = -50
        let endY: CGFloat = UIScreen.main.bounds.height + 50
        let rotation: Double
        let size: CGFloat
    }
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 2)
                    .rotationEffect(.degrees(piece.rotation))
                    .position(x: piece.x, y: piece.startY)
                    .animation(
                        .linear(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: false),
                        value: piece.startY
                    )
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    private func createConfetti() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        let screenWidth = UIScreen.main.bounds.width
        
        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                color: colors.randomElement()!,
                x: CGFloat.random(in: 0...screenWidth),
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 8...16)
            )
        }
    }
}
