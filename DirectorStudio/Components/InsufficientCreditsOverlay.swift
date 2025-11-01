// MODULE: InsufficientCreditsOverlay
// VERSION: 1.0.0
// PURPOSE: Beautiful inline overlay for insufficient credits with CTA

import SwiftUI

struct InsufficientCreditsOverlay: View {
    @Binding var isShowing: Bool
    let creditsNeeded: Int
    let creditsHave: Int
    let onPurchase: () -> Void
    @State private var animateIn = false
    
    var creditsShort: Int {
        max(0, creditsNeeded - creditsHave)
    }
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isShowing = false
                    }
                }
            
            // Content card
            VStack(spacing: 24) {
                // Icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.2), Color.red.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateIn ? 1 : 0.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateIn)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                        .rotationEffect(.degrees(animateIn ? 0 : -15))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateIn)
                }
                
                // Title and message
                VStack(spacing: 12) {
                    Text("Need More Credits")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Required:")
                            Text("\(creditsNeeded)")
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            Text("credits")
                        }
                        .font(.body)
                        
                        HStack(spacing: 4) {
                            Text("Available:")
                            Text("\(creditsHave)")
                                .fontWeight(.bold)
                                .foregroundColor(creditsHave > 0 ? .blue : .red)
                            Text("credits")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
                
                // Quick purchase options
                VStack(spacing: 12) {
                    // Main CTA
                    Button(action: {
                        onPurchase()
                        withAnimation(.spring()) {
                            isShowing = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Purchase Credits")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    
                    // View all options
                    Button(action: {
                        onPurchase()
                        withAnimation(.spring()) {
                            isShowing = false
                        }
                    }) {
                        Text("See All Packs")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    // Cancel
                    Button(action: {
                        withAnimation(.spring()) {
                            isShowing = false
                        }
                    }) {
                        Text("Maybe Later")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .frame(maxWidth: 350)
            .scaleEffect(animateIn ? 1 : 0.8)
            .opacity(animateIn ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animateIn)
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
            
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

// MARK: - First Time Bonus Overlay

struct FirstTimeBonusOverlay: View {
    @Binding var isShowing: Bool
    let onClaim: () -> Void
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // Content card
            contentCard
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
            
            // Celebration haptic
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private var contentCard: some View {
        VStack(spacing: 24) {
            animatedGiftIcon
            welcomeMessage
            claimButton
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 20)
        .frame(maxWidth: 350)
        .scaleEffect(animateIn ? 1 : 0.8)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animateIn)
    }
    
    private var animatedGiftIcon: some View {
        ZStack {
            ForEach(0..<3) { index in
                animatedCircle(index: index)
            }
            
            Image(systemName: "gift.fill")
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(animateIn ? 0 : -20))
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateIn)
        }
    }
    
    private func animatedCircle(index: Int) -> some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .frame(width: 80 + CGFloat(index * 20),
                   height: 80 + CGFloat(index * 20))
            .scaleEffect(animateIn ? 1 : 0.5)
            .opacity(animateIn ? 1 - Double(index) * 0.3 : 0)
            .animation(
                .spring(response: 0.8, dampingFraction: 0.5)
                    .delay(Double(index) * 0.1),
                value: animateIn
            )
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 12) {
            Text("Welcome to DirectorStudio!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your first credit is on us")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var claimButton: some View {
        Button(action: {
            onClaim()
            withAnimation(.spring()) {
                isShowing = false
            }
        }) {
            HStack {
                Image(systemName: "sparkles")
                Text("Claim Your Free Credit")
                    .fontWeight(.semibold)
                Image(systemName: "sparkles")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
        }
    }
}

// MARK: - Credit Success Toast

struct CreditSuccessToast: View {
    let creditsAdded: Int
    @State private var animateIn = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Credits Added!")
                    .font(.headline)
                Text("+\(creditsAdded) credits")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
        .frame(maxWidth: 350)
        .scaleEffect(animateIn ? 1 : 0.8)
        .opacity(animateIn ? 1 : 0)
        .animation(.spring(response: 0.4), value: animateIn)
        .onAppear {
            withAnimation {
                animateIn = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
