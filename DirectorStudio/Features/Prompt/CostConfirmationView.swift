// MODULE: CostConfirmationView
// VERSION: 1.0.0
// PURPOSE: Show token breakdown and cost before generation

import SwiftUI

struct CostConfirmationView: View {
    @ObservedObject var segmentCollection: MultiClipSegmentCollection
    @ObservedObject var creditsManager = CreditsManager.shared
    @Binding var isPresented: Bool
    @State private var showingInsufficientCredits = false
    
    let onGenerate: () -> Void
    
    var enabledSegments: [MultiClipSegment] {
        segmentCollection.segments.filter { $0.isEnabled }
    }
    
    var totalDuration: Double {
        enabledSegments.reduce(0) { $0 + $1.duration }
    }
    
    var totalTokens: Int {
        let tokens = Int(ceil(MonetizationConfig.creditsForSeconds(totalDuration)))
        #if DEBUG
        print("💰 [CostConfirmation] Calculating tokens:")
        print("   - Enabled segments: \(enabledSegments.count)")
        print("   - Total duration: \(totalDuration)s")
        print("   - Rate: \(MonetizationConfig.TOKENS_PER_SEC) tokens/sec")
        print("   - Total tokens: \(tokens)")
        #endif
        return tokens
    }
    
    var totalPriceCents: Int {
        MonetizationConfig.priceForSeconds(totalDuration)
    }
    
    var canAfford: Bool {
        creditsManager.isDevMode || creditsManager.credits >= totalTokens
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGray6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Guardrail: Show warning if segments have zero duration
                    if enabledSegments.isEmpty || totalDuration == 0 {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Invalid configuration")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text("No clips or zero duration detected. Go back and set durations.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                    }
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Summary header
                            summaryHeader
                            
                            // Clip breakdown
                            clipBreakdown
                            
                            // Token breakdown
                            tokenBreakdown
                            
                            // Credits status
                            creditsStatus
                        }
                        .padding()
                    }
                    
                    // Generate button
                    generateButton
                        .padding()
                        .background(.regularMaterial)
                }
            }
            .navigationTitle("Confirm Generation")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        isPresented = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingInsufficientCredits) {
            InsufficientCreditsOverlay(
                isShowing: $showingInsufficientCredits,
                creditsNeeded: totalTokens,
                creditsHave: creditsManager.credits,
                onPurchase: {
                    // Handle purchase
                }
            )
        }
    }
    
    private var summaryHeader: some View {
        VStack(spacing: 20) {
            // Visual summary
            HStack(spacing: 32) {
                // Clips count
                VStack(spacing: 8) {
                    Image(systemName: "film.stack")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    
                    Text("\(enabledSegments.count)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Clips")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Total duration
                VStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.largeTitle)
                        .foregroundColor(.purple)
                    
                    Text(formatDuration(totalDuration))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Total Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Total cost
                VStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text(MonetizationConfig.formatPrice(totalPriceCents))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(totalTokens) tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10)
        }
    }
    
    private var clipBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clip Breakdown")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(Array(enabledSegments.enumerated()), id: \.element.id) { index, segment in
                    HStack {
                        Label("Clip \(index + 1)", systemImage: "film")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(segment.duration, specifier: "%.1f")s")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        let clipTokens = Int(ceil(MonetizationConfig.creditsForSeconds(segment.duration)))
                        Text("\(clipTokens) tokens")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var tokenBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Token Calculation")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Base calculation
                HStack {
                    Text("Base rate")
                    Spacer()
                    Text("\(MonetizationConfig.TOKENS_PER_SEC, specifier: "%.1f") tokens/second")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Total duration")
                    Spacer()
                    Text("\(totalDuration, specifier: "%.1f") seconds")
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack {
                    Text("Total tokens")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(totalTokens) tokens")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Text("Cost")
                        .fontWeight(.medium)
                    Spacer()
                    Text(MonetizationConfig.formatPrice(totalPriceCents))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var creditsStatus: some View {
        VStack(spacing: 16) {
            if creditsManager.isDevMode {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("Developer Mode - Free Generation")
                        .font(.headline)
                        .foregroundColor(.purple)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Text("Your balance")
                        Spacer()
                        Text("\(creditsManager.credits) tokens")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Cost")
                        Spacer()
                        Text("-\(totalTokens) tokens")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Remaining after")
                        Spacer()
                        let remaining = creditsManager.credits - totalTokens
                        Text("\(max(0, remaining)) tokens")
                            .fontWeight(.bold)
                            .foregroundColor(remaining >= 0 ? .green : .red)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canAfford ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(canAfford ? Color.green : Color.red, lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var generateButton: some View {
        Button(action: {
            if canAfford {
                onGenerate()
            } else {
                showingInsufficientCredits = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: canAfford ? "wand.and.stars" : "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(canAfford ? "Generate Video" : "Insufficient Credits")
                        .font(.headline)
                    
                    if !creditsManager.isDevMode {
                        Text(canAfford ? 
                            "Charge \(totalTokens) tokens • \(MonetizationConfig.formatPrice(totalPriceCents))" :
                            "Need \(totalTokens - creditsManager.credits) more tokens"
                        )
                        .font(.caption)
                        .opacity(0.8)
                    }
                }
                
                Spacer()
                
                if canAfford {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                }
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: canAfford ? [.blue, .purple] : [.orange, .red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: canAfford ? .blue.opacity(0.3) : .red.opacity(0.3), radius: 10, y: 5)
        }
        .scaleEffect(canAfford ? 1 : 0.95)
        .animation(.spring(response: 0.3), value: canAfford)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
