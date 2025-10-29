//
//  MonetizationAnalysisView.swift
//  DirectorStudio
//
//  PURPOSE: Comprehensive monetization analysis and cost calculator tool
//

import SwiftUI

struct MonetizationAnalysisView: View {
    @State private var duration: Double = 10.0
    @State private var selectedQuality: VideoQualityTier = .basic
    @State private var hasEnhancement: Bool = false
    @State private var hasContinuity: Bool = false
    @State private var upstreamCostPerSecond: Double = 0.08
    @State private var availableTokens: Int = 150
    @State private var apiAccountBalance: Double = 0.0 // Your real API account balance
    
    private var costBreakdown: CostBreakdown {
        var enabledStages: Set<PipelineStage> = []
        if hasEnhancement {
            enabledStages.insert(.enhancement)
        }
        if hasContinuity {
            enabledStages.insert(.continuityInjection)
        }
        
        return CostCalculator.calculateVideoCost(
            duration: duration,
            quality: selectedQuality,
            enabledStages: enabledStages
        )
    }
    
    private var monetizationAnalysis: MonetizationAnalysis {
        CostCalculator.analyzeMonetization(
            costBreakdown: costBreakdown,
            upstreamCostPerSecond: upstreamCostPerSecond
        )
    }
    
    private var videoEstimate: VideoEstimate {
        var enabledStages: Set<PipelineStage> = []
        if hasEnhancement {
            enabledStages.insert(.enhancement)
        }
        if hasContinuity {
            enabledStages.insert(.continuityInjection)
        }
        
        return CostCalculator.estimateVideosPossible(
            availableTokens: availableTokens,
            duration: duration,
            quality: selectedQuality,
            enabledStages: enabledStages
        )
    }
    
    private var realAPICost: RealAPICost {
        CostCalculator.calculateRealAPICost(
            duration: duration,
            quality: selectedQuality
        )
    }
    
    private var realAPIMonetization: RealAPIMonetizationAnalysis {
        let customerRevenue = Double(costBreakdown.priceInCents) / 100.0
        return CostCalculator.analyzeRealAPIMonetization(
            customerRevenue: customerRevenue,
            duration: duration,
            quality: selectedQuality
        )
    }
    
    private var videosPossibleWithAPIBalance: Int {
        guard realAPICost.totalCost > 0 else { return 0 }
        return Int(apiAccountBalance / realAPICost.totalCost)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Input Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Cost Calculator")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration: \(Int(duration)) seconds")
                                .font(.headline)
                            Slider(value: $duration, in: 1...60, step: 1)
                        }
                        
                        // Quality Tier
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quality Tier")
                                .font(.headline)
                            Picker("Quality", selection: $selectedQuality) {
                                ForEach(VideoQualityTier.allCases, id: \.self) { tier in
                                    Text(tier.displayName).tag(tier)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // Pipeline Features
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pipeline Features")
                                .font(.headline)
                            Toggle("AI Enhancement (+20%)", isOn: $hasEnhancement)
                            Toggle("Continuity (+10%)", isOn: $hasContinuity)
                        }
                        
                        // Upstream Cost
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Upstream Cost: $\(String(format: "%.3f", upstreamCostPerSecond))/sec")
                                .font(.headline)
                            Slider(value: $upstreamCostPerSecond, in: 0.01...0.20, step: 0.01)
                        }
                        
                        // Available Tokens (Customer-facing)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Customer Tokens Available")
                                .font(.headline)
                            TextField("Tokens", value: $availableTokens, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                        
                        Divider()
                        
                        // Real API Account Balance
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your API Account Balance ($)")
                                .font(.headline)
                                .foregroundColor(.blue)
                            TextField("API Balance", value: $apiAccountBalance, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.decimalPad)
                            Text("Enter your actual Pollo AI account balance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Cost Breakdown Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cost Breakdown")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Tokens Required")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(costBreakdown.formattedTokens)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Price")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(costBreakdown.formattedPrice)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duration: \(Int(duration))s")
                            Text("Base Tokens: \(costBreakdown.baseTokens)")
                            if costBreakdown.multiplier > 1.0 {
                                Text("Multiplier: \(String(format: "%.1fx", costBreakdown.multiplier))")
                            }
                            if !costBreakdown.pipelineFeatures.isEmpty {
                                Text("Features:")
                                    .fontWeight(.semibold)
                                ForEach(costBreakdown.pipelineFeatures, id: \.self) { feature in
                                    Text("  • \(feature)")
                                        .font(.caption)
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Monetization Analysis Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monetization Analysis")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Revenue")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(monetizationAnalysis.formattedRevenue)
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Cost")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(String(format: "%.2f", monetizationAnalysis.upstreamCost))")
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Profit")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(monetizationAnalysis.formattedProfit)
                                    .font(.headline)
                                    .foregroundColor(monetizationAnalysis.isProfitable ? .green : .red)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Margin")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(monetizationAnalysis.formattedMargin)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(monetizationAnalysis.marginAtRisk ? .orange : .green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Status")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(monetizationAnalysis.isProfitable ? "✅ Profitable" : "❌ Loss")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if monetizationAnalysis.marginAtRisk {
                            Text("⚠️ Margin below 50% target")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Real API Cost Card (YOUR ACTUAL COSTS)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔴 Your Real API Costs")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("You Pay API")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(realAPICost.formattedCost)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Rate")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(String(format: "%.4f", realAPICost.costPerSecond))/sec")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Videos Possible")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(videosPossibleWithAPIBalance)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Balance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("$\(String(format: "%.2f", apiAccountBalance))")
                                    .font(.headline)
                            }
                        }
                        
                        if apiAccountBalance > 0 {
                            Text("With $\(String(format: "%.2f", apiAccountBalance)) API balance, you can generate \(videosPossibleWithAPIBalance) videos")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 2)
                    )
                    
                    // Real API Profit Analysis Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💰 Your Real Profit Analysis")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Customer Pays")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(realAPIMonetization.formattedRevenue)
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("You Pay API")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(realAPIMonetization.formattedAPICost)
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Your Profit")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(realAPIMonetization.formattedProfit)
                                    .font(.headline)
                                    .foregroundColor(realAPIMonetization.isProfitable ? .green : .red)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Margin")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(realAPIMonetization.formattedMargin)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(realAPIMonetization.marginAtRisk ? .orange : .green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Status")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(realAPIMonetization.isProfitable ? "✅ Profitable" : "❌ Loss")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if realAPIMonetization.marginAtRisk {
                            Text("⚠️ Margin below 50% target - consider adjusting pricing")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Customer Token Estimate Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("👥 Customer Token Estimate")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Videos Possible")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(videoEstimate.videosPossible)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Tokens Remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(videoEstimate.tokensRemaining)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        Divider()
                        
                        Text("Cost per video: \(videoEstimate.formattedCost)")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Detailed Breakdown (Collapsible)
                    DisclosureGroup("Detailed Breakdown") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(costBreakdown.detailedBreakdown)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Text(monetizationAnalysis.summary)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Monetization Calculator")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    MonetizationAnalysisView()
}

