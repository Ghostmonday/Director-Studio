//
//  TierSelectionView.swift
//  DirectorStudio
//
//  Beautiful tier selection interface with LensDepth design
//

import SwiftUI

// MARK: - Main Tier Selection View

public struct TierSelectionView: View {
    @Binding var selectedTier: VideoQualityTier
    @EnvironmentObject var creditsManager: CreditsManager
    let estimatedDuration: TimeInterval
    let takeCount: Int
    
    @State private var showingDetails = false
    @State private var hoveredTier: VideoQualityTier?
    @State private var hasRunwayKey = UserAPIKeysManager.shared.hasRunwayKey
    
    private let gradientColors = [
        Color(red: 0.18, green: 0.18, blue: 0.18),  // Dark base
        Color(red: 0.22, green: 0.22, blue: 0.24)   // Slightly lighter
    ]
    
    public var body: some View {
        VStack(spacing: 24) {
            // Header with cost estimate
            CostEstimateHeader(
                estimatedDuration: estimatedDuration,
                takeCount: takeCount,
                selectedTier: selectedTier
            )
            
            // Tier Cards
            VStack(spacing: 16) {
                ForEach(VideoQualityTier.allCases, id: \.self) { tier in
                    TierCard(
                        tier: tier,
                        isSelected: selectedTier == tier,
                        isHovered: hoveredTier == tier,
                        estimatedDuration: estimatedDuration,
                        takeCount: takeCount,
                        credits: creditsManager.tokens,
                        isAvailable: tier == .premium ? hasRunwayKey : true,
                        onTap: { 
                            // Premium tier requires Runway key
                            if tier == .premium && !hasRunwayKey {
                                return // Don't allow selection without key
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTier = tier
                            }
                        }
                    )
                    .onHover { isHovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            hoveredTier = isHovering ? tier : nil
                        }
                    }
                    .scaleEffect(selectedTier == tier ? 1.02 : 1.0)
                    .animation(.spring(response: 0.3), value: selectedTier)
                }
            }
            .onAppear {
                hasRunwayKey = UserAPIKeysManager.shared.hasRunwayKey
            }
            
            // Cost Summary
            AnimatedCostSummary(
                tier: selectedTier,
                duration: estimatedDuration,
                takeCount: takeCount,
                credits: creditsManager.tokens
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            LinearGradient(gradient: Gradient(colors: gradientColors), 
                         startPoint: .topLeading, 
                         endPoint: .bottomTrailing)
        )
    }
}

// MARK: - Cost Estimate Header

struct CostEstimateHeader: View {
    let estimatedDuration: TimeInterval
    let takeCount: Int
    let selectedTier: VideoQualityTier
    
    @State private var pulseAnimation = false
    
    var totalCost: (tokens: Int, dollars: String) {
        let totalDuration = estimatedDuration
        let tokens = Int(ceil(totalDuration * Double(selectedTier.tokensPerSecond)))
        let dollars = String(format: "$%.2f", Double(tokens) / 100.0)
        return (tokens, dollars)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(Color(hex: "FF9E0A"))  // Warm amber
                    .rotationEffect(.degrees(pulseAnimation ? 10 : -10))
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Text("Choose Your Quality")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(Color(hex: "FF9E0A"))
                    .rotationEffect(.degrees(pulseAnimation ? -10 : 10))
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
            }
            
            Text("Your story will create \(takeCount) scenes • ~\(Int(estimatedDuration)) seconds total")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            // Estimated total cost
            HStack(spacing: 4) {
                Text("Estimated cost:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(totalCost.dollars)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "4A8FE8"))  // Cool blue
                
                Text("(\(totalCost.tokens) tokens)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .onAppear { pulseAnimation = true }
    }
}

// MARK: - Tier Card

struct TierCard: View {
    let tier: VideoQualityTier
    let isSelected: Bool
    let isHovered: Bool
    let estimatedDuration: TimeInterval
    let takeCount: Int
    let credits: Int
    let isAvailable: Bool
    let onTap: () -> Void
    
    private var cost: Int {
        Int(ceil(estimatedDuration * Double(tier.tokensPerSecond)))
    }
    
    private var canAfford: Bool {
        credits >= cost
    }
    
    private var isEnabled: Bool {
        canAfford && isAvailable
    }
    
    private var cardColor: Color {
        switch tier {
        case .economy:
            return Color(hex: "7FB3D5")  // Soft blue
        case .basic:
            return Color(hex: "FF9E0A")  // Warm amber
        case .pro:
            return Color(hex: "4A8FE8")  // Cool blue (most popular)
        case .premium:
            return Color(hex: "FFD700")  // Gold
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    // Icon with tier-specific styling
                    ZStack {
                        Circle()
                            .fill(cardColor.opacity(isSelected ? 0.3 : 0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: tier.icon)
                            .font(.title2)
                            .foregroundColor(isSelected ? .white : cardColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(tier.shortName)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            
                            if tier.isPopular {
                                Label("MOST POPULAR", systemImage: "star.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "FF9E0A"))
                                            .shadow(color: Color(hex: "FF9E0A").opacity(0.5), radius: 4)
                                    )
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text(tier.modelName)
                            .font(.caption)
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    // Price display
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(cost) tokens")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(canAfford ? (isSelected ? .white : .primary) : .red)
                        
                        Text("$\(String(format: "%.2f", Double(cost) / 100.0))")
                            .font(.caption)
                            .opacity(0.8)
                        
                        Text("\(tier.customerPricePerSecond, specifier: "%.2f")/sec")
                            .font(.system(size: 10))
                            .opacity(0.6)
                    }
                }
                
                // Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.description)
                        .font(.callout)
                        .opacity(0.9)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Premium tier warning if no Runway key
                    if tier == .premium && !isAvailable {
                        HStack(spacing: 6) {
                            Image(systemName: "key.fill")
                                .font(.caption2)
                            Text("Requires your own Runway API key")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.2))
                        )
                    }
                }
                
                // Features with checkmarks
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tier.features.prefix(3), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(isSelected ? .white : cardColor)
                            
                            Text(feature)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
                
                // Duration limit
                HStack {
                    Image(systemName: "timer")
                        .font(.caption)
                    Text("Max \(tier.maxDuration) seconds per scene")
                        .font(.caption2)
                        .opacity(0.7)
                }
            }
            .padding(20)
            .background(
                ZStack {
                    // Base layer
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? cardColor : Color(hex: "2A2A2A"))
                    
                    // Glass effect
                    if !isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.05),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color.clear : cardColor.opacity(0.3),
                            lineWidth: isHovered ? 2 : 1
                        )
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .shadow(
                color: isSelected ? cardColor.opacity(0.4) : Color.black.opacity(0.2),
                radius: isSelected ? 12 : 6,
                x: 0,
                y: isSelected ? 6 : 3
            )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.4)
    }
}

// MARK: - Animated Cost Summary

struct AnimatedCostSummary: View {
    let tier: VideoQualityTier
    let duration: TimeInterval
    let takeCount: Int
    let credits: Int
    
    @State private var showBreakdown = false
    
    private var totalCost: Int {
        Int(ceil(duration * Double(tier.tokensPerSecond)))
    }
    
    private var canAfford: Bool {
        credits >= totalCost
    }
    
    private var costPerTake: Int {
        totalCost / max(takeCount, 1)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Summary Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Cost")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$\(String(format: "%.2f", Double(totalCost) / 100.0))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(canAfford ? .white : .red)
                        
                        Text("(\(totalCost) tokens)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { withAnimation { showBreakdown.toggle() } }) {
                    Label(showBreakdown ? "Hide Details" : "Show Details", 
                          systemImage: showBreakdown ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "4A8FE8"))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "2A2A2A"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            
            // Breakdown (animated)
            if showBreakdown {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "film")
                        Text("\(takeCount) scenes")
                        Spacer()
                        Text("~\(costPerTake) tokens each")
                    }
                    .font(.caption)
                    
                    HStack {
                        Image(systemName: "timer")
                        Text("~\(Int(duration)) seconds total")
                        Spacer()
                        Text("\(tier.tokensPerSecond) tokens/sec")
                    }
                    .font(.caption)
                    
                    HStack {
                        Image(systemName: "dollarsign.circle")
                        Text("Rate: \(tier.customerPricePerSecond, specifier: "%.2f")/sec")
                        Spacer()
                        Text("\(tier.modelName)")
                    }
                    .font(.caption)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // Insufficient funds warning
            if !canAfford {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("You need \(totalCost - credits) more tokens")
                        .font(.caption)
                    
                    Spacer()
                    
                    Button("Get Tokens") {
                        // Navigate to purchase
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "FF9E0A"))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - Helper Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

struct TierSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        TierSelectionView(
            selectedTier: .constant(.basic),
            estimatedDuration: 25,
            takeCount: 5
        )
        .environmentObject(CreditsManager.shared)
        .preferredColorScheme(.dark)
    }
}
