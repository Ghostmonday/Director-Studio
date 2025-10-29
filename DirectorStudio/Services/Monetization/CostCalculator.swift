//
//  CostCalculator.swift
//  DirectorStudio
//
//  PURPOSE: Comprehensive cost calculation and monetization analysis tool
//

import Foundation

/// Comprehensive cost calculator for monetization analysis
public struct CostCalculator {
    
    // MARK: - Single Video Cost Calculation
    
    /// Calculate the exact cost for a single video generation
    public static func calculateVideoCost(
        duration: TimeInterval,
        quality: VideoQualityTier = .basic,
        enabledStages: Set<PipelineStage> = [],
        modelTier: PricingEngine.ModelTier = .standard
    ) -> CostBreakdown {
        // Base token calculation (0.5 tokens per second)
        let baseTokens = MonetizationConfig.creditsForSeconds(duration)
        let baseTokensRounded = MonetizationConfig.tokensToDebit(baseTokens)
        
        // Apply quality multiplier
        let qualityMultiplier = quality.tokenMultiplier
        var totalTokens = Double(baseTokensRounded) * qualityMultiplier
        
        // Track pipeline features and their multipliers
        var features: [String] = []
        var featureMultiplier = 1.0
        
        // Enhancement adds 20%
        if enabledStages.contains(.enhancement) {
            features.append("AI Enhancement (+20%)")
            featureMultiplier *= 1.2
        }
        
        // Continuity adds 10%
        if enabledStages.contains(.continuityAnalysis) || enabledStages.contains(.continuityInjection) {
            features.append("Continuity (+10%)")
            featureMultiplier *= 1.1
        }
        
        // Camera direction (no extra cost, but tracked)
        if enabledStages.contains(.cameraDirection) {
            features.append("Camera Direction")
        }
        
        // Lighting (no extra cost, but tracked)
        if enabledStages.contains(.lighting) {
            features.append("Lighting")
        }
        
        // Apply feature multiplier
        totalTokens = totalTokens * featureMultiplier
        
        // Calculate price in cents
        let priceCents = MonetizationConfig.priceForSeconds(duration)
        
        // Apply quality multiplier to price
        let finalPriceCents = Int(Double(priceCents) * qualityMultiplier * featureMultiplier)
        
        return CostBreakdown(
            videoDuration: duration,
            baseTokens: baseTokensRounded,
            multiplier: qualityMultiplier * featureMultiplier,
            totalTokens: Int(ceil(totalTokens)),
            priceInCents: finalPriceCents,
            pipelineFeatures: features.isEmpty ? ["Base Quality"] : features
        )
    }
    
    // MARK: - Multi-Clip Film Cost Calculation
    
    /// Calculate cost for a film breakdown with multiple takes
    public static func calculateFilmCost(
        takes: [FilmTake],
        quality: VideoQualityTier = .basic,
        enabledStages: Set<PipelineStage> = []
    ) -> FilmCostBreakdown {
        var totalTokens = 0
        var totalDuration: TimeInterval = 0
        var takeCosts: [TakeCost] = []
        
        for take in takes {
            let duration = take.estimatedDuration
            totalDuration += duration
            
            // Calculate cost for this take
            let takeBreakdown = calculateVideoCost(
                duration: duration,
                quality: quality,
                enabledStages: enabledStages
            )
            
            totalTokens += takeBreakdown.totalTokens
            
            takeCosts.append(TakeCost(
                takeNumber: take.takeNumber,
                duration: duration,
                tokens: takeBreakdown.totalTokens,
                priceCents: takeBreakdown.priceInCents
            ))
        }
        
        let totalPriceCents = takeCosts.reduce(0) { $0 + $1.priceCents }
        
        return FilmCostBreakdown(
            totalTakes: takes.count,
            totalDuration: totalDuration,
            totalTokens: totalTokens,
            totalPriceCents: totalPriceCents,
            averageTokensPerTake: totalTokens / takes.count,
            takeCosts: takeCosts
        )
    }
    
    // MARK: - Real API Cost Calculation
    
    /// Calculate the REAL API cost (what you pay Pollo AI) for a video generation
    public static func calculateRealAPICost(
        duration: TimeInterval,
        quality: VideoQualityTier = .basic
    ) -> RealAPICost {
        // Real cost per second from API provider (Pollo AI)
        let realCostPerSecond = quality.baseCostPerSecond
        let totalAPICost = duration * realCostPerSecond
        
        return RealAPICost(
            duration: duration,
            quality: quality,
            costPerSecond: realCostPerSecond,
            totalCost: totalAPICost,
            formattedCost: String(format: "$%.4f", totalAPICost)
        )
    }
    
    // MARK: - Monetization Analysis
    
    /// Analyze monetization metrics for a generation request
    public static func analyzeMonetization(
        costBreakdown: CostBreakdown,
        upstreamCostPerSecond: Double = MonetizationConfig.CURRENT_UPSTREAM_COST
    ) -> MonetizationAnalysis {
        let revenue = Double(costBreakdown.priceInCents) / 100.0
        let upstreamCost = costBreakdown.videoDuration * upstreamCostPerSecond
        let grossProfit = revenue - upstreamCost
        let margin = MonetizationConfig.calculateMargin(revenue: revenue, upstreamCost: upstreamCost)
        
        return MonetizationAnalysis(
            revenue: revenue,
            upstreamCost: upstreamCost,
            grossProfit: grossProfit,
            margin: margin,
            isProfitable: grossProfit > 0,
            marginAtRisk: margin < MonetizationConfig.TARGET_MARGIN,
            pricePerSecond: revenue / costBreakdown.videoDuration,
            costPerSecond: upstreamCost / costBreakdown.videoDuration
        )
    }
    
    /// Analyze monetization with REAL API costs from your account
    public static func analyzeRealAPIMonetization(
        customerRevenue: Double,
        duration: TimeInterval,
        quality: VideoQualityTier
    ) -> RealAPIMonetizationAnalysis {
        let realAPICost = calculateRealAPICost(duration: duration, quality: quality)
        let grossProfit = customerRevenue - realAPICost.totalCost
        let margin = MonetizationConfig.calculateMargin(revenue: customerRevenue, upstreamCost: realAPICost.totalCost)
        
        return RealAPIMonetizationAnalysis(
            customerRevenue: customerRevenue,
            realAPICost: realAPICost.totalCost,
            grossProfit: grossProfit,
            margin: margin,
            isProfitable: grossProfit > 0,
            marginAtRisk: margin < MonetizationConfig.TARGET_MARGIN,
            quality: quality
        )
    }
    
    // MARK: - Cost Estimation Helpers
    
    /// Estimate how many videos can be generated with given tokens
    public static func estimateVideosPossible(
        availableTokens: Int,
        duration: TimeInterval = 10.0,
        quality: VideoQualityTier = .basic,
        enabledStages: Set<PipelineStage> = []
    ) -> VideoEstimate {
        let costPerVideo = calculateVideoCost(
            duration: duration,
            quality: quality,
            enabledStages: enabledStages
        )
        
        let videosPossible = availableTokens / costPerVideo.totalTokens
        let tokensRemaining = availableTokens % costPerVideo.totalTokens
        
        return VideoEstimate(
            videosPossible: videosPossible,
            tokensPerVideo: costPerVideo.totalTokens,
            tokensRemaining: tokensRemaining,
            totalCostPerVideo: Double(costPerVideo.priceInCents) / 100.0
        )
    }
    
    /// Calculate tokens needed for a specific budget
    public static func tokensForBudget(
        budgetUSD: Double,
        duration: TimeInterval = 10.0,
        quality: VideoQualityTier = .basic
    ) -> Int {
        let pricePerVideo = Double(MonetizationConfig.priceForSeconds(duration)) / 100.0
        let priceWithQuality = pricePerVideo * quality.tokenMultiplier
        let videosPossible = Int(budgetUSD / priceWithQuality)
        let costPerVideo = calculateVideoCost(duration: duration, quality: quality)
        return videosPossible * costPerVideo.totalTokens
    }
}

// MARK: - Supporting Types

/// Detailed cost breakdown for a single video
public struct CostBreakdown {
    public let videoDuration: TimeInterval
    public let baseTokens: Int
    public let multiplier: Double
    public let totalTokens: Int
    public let priceInCents: Int
    public let pipelineFeatures: [String]
    
    public var priceUSD: Double {
        Double(priceInCents) / 100.0
    }
    
    public var formattedPrice: String {
        MonetizationConfig.formatPrice(priceInCents)
    }
    
    public var formattedTokens: String {
        TokenCalculator.formatTokens(totalTokens)
    }
    
    public var detailedBreakdown: String {
        var lines: [String] = []
        lines.append("╔═══════════════════════════════╗")
        lines.append("║   VIDEO GENERATION COST       ║")
        lines.append("╠═══════════════════════════════╣")
        lines.append("Duration: \(Int(videoDuration))s")
        lines.append("Base Tokens: \(baseTokens)")
        
        if multiplier > 1.0 {
            lines.append("Multiplier: \(String(format: "%.1fx", multiplier))")
        }
        
        if !pipelineFeatures.isEmpty {
            lines.append("")
            lines.append("Features:")
            for feature in pipelineFeatures {
                lines.append("  • \(feature)")
            }
        }
        
        lines.append("")
        lines.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        lines.append("Total Tokens: \(formattedTokens)")
        lines.append("Total Price: \(formattedPrice)")
        lines.append("╚═══════════════════════════════╝")
        
        return lines.joined(separator: "\n")
    }
}

/// Cost breakdown for a multi-take film
public struct FilmCostBreakdown {
    public let totalTakes: Int
    public let totalDuration: TimeInterval
    public let totalTokens: Int
    public let totalPriceCents: Int
    public let averageTokensPerTake: Int
    public let takeCosts: [TakeCost]
    
    public var totalPriceUSD: Double {
        Double(totalPriceCents) / 100.0
    }
    
    public var formattedPrice: String {
        MonetizationConfig.formatPrice(totalPriceCents)
    }
    
    public var formattedTokens: String {
        TokenCalculator.formatTokens(totalTokens)
    }
    
    public var formattedDuration: String {
        let minutes = Int(totalDuration) / 60
        let seconds = Int(totalDuration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
    
    public var detailedBreakdown: String {
        var lines: [String] = []
        lines.append("╔═══════════════════════════════╗")
        lines.append("║    FILM GENERATION COST      ║")
        lines.append("╠═══════════════════════════════╣")
        lines.append("Total Takes: \(totalTakes)")
        lines.append("Total Duration: \(formattedDuration)")
        lines.append("")
        lines.append("Breakdown by Take:")
        for takeCost in takeCosts {
            lines.append("  Take \(takeCost.takeNumber): \(Int(takeCost.duration))s - \(takeCost.tokens) tokens (\(MonetizationConfig.formatPrice(takeCost.priceCents)))")
        }
        lines.append("")
        lines.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        lines.append("Average per Take: \(averageTokensPerTake) tokens")
        lines.append("Total Tokens: \(formattedTokens)")
        lines.append("Total Price: \(formattedPrice)")
        lines.append("╚═══════════════════════════════╝")
        
        return lines.joined(separator: "\n")
    }
}

/// Cost for a single take in a film
public struct TakeCost {
    public let takeNumber: Int
    public let duration: TimeInterval
    public let tokens: Int
    public let priceCents: Int
}

/// Monetization analysis metrics
public struct MonetizationAnalysis {
    public let revenue: Double
    public let upstreamCost: Double
    public let grossProfit: Double
    public let margin: Double
    public let isProfitable: Bool
    public let marginAtRisk: Bool
    public let pricePerSecond: Double
    public let costPerSecond: Double
    
    public var formattedRevenue: String {
        String(format: "$%.2f", revenue)
    }
    
    public var formattedProfit: String {
        String(format: "$%.2f", grossProfit)
    }
    
    public var formattedMargin: String {
        String(format: "%.1f%%", margin * 100)
    }
    
    public var summary: String {
        var lines: [String] = []
        lines.append("╔═══════════════════════════════╗")
        lines.append("║  MONETIZATION ANALYSIS        ║")
        lines.append("╠═══════════════════════════════╣")
        lines.append("Revenue: \(formattedRevenue)")
        lines.append("Upstream Cost: $\(String(format: "%.2f", upstreamCost))")
        lines.append("Gross Profit: \(formattedProfit)")
        lines.append("Margin: \(formattedMargin)")
        lines.append("")
        lines.append("Status: \(isProfitable ? "✅ Profitable" : "❌ Loss")")
        if marginAtRisk {
            lines.append("⚠️  Margin below target (50%)")
        }
        lines.append("╚═══════════════════════════════╝")
        
        return lines.joined(separator: "\n")
    }
}

/// Estimate of videos possible with available tokens
public struct VideoEstimate {
    public let videosPossible: Int
    public let tokensPerVideo: Int
    public let tokensRemaining: Int
    public let totalCostPerVideo: Double
    
    public var formattedCost: String {
        String(format: "$%.2f", totalCostPerVideo)
    }
    
    public var summary: String {
        """
        With your current tokens, you can generate:
        • \(videosPossible) videos at \(Int(totalCostPerVideo * 100)) tokens each
        • \(tokensRemaining) tokens remaining
        • Total value: \(formattedCost) per video
        """
    }
}

/// Real API cost from your API provider account
public struct RealAPICost {
    public let duration: TimeInterval
    public let quality: VideoQualityTier
    public let costPerSecond: Double
    public let totalCost: Double
    public let formattedCost: String
    
    public var summary: String {
        """
        Real API Cost (What you pay Pollo AI):
        • Duration: \(Int(duration))s
        • Quality: \(quality.displayName)
        • Rate: $\(String(format: "%.4f", costPerSecond))/sec
        • Total: \(formattedCost)
        """
    }
}

/// Real API monetization analysis using actual API costs
public struct RealAPIMonetizationAnalysis {
    public let customerRevenue: Double
    public let realAPICost: Double
    public let grossProfit: Double
    public let margin: Double
    public let isProfitable: Bool
    public let marginAtRisk: Bool
    public let quality: VideoQualityTier
    
    public var formattedRevenue: String {
        String(format: "$%.2f", customerRevenue)
    }
    
    public var formattedAPICost: String {
        String(format: "$%.4f", realAPICost)
    }
    
    public var formattedProfit: String {
        String(format: "$%.2f", grossProfit)
    }
    
    public var formattedMargin: String {
        String(format: "%.1f%%", margin * 100)
    }
    
    public var summary: String {
        var lines: [String] = []
        lines.append("╔═══════════════════════════════╗")
        lines.append("║  REAL API MONETIZATION         ║")
        lines.append("╠═══════════════════════════════╣")
        lines.append("Customer Pays: \(formattedRevenue)")
        lines.append("You Pay API: \(formattedAPICost)")
        lines.append("Your Profit: \(formattedProfit)")
        lines.append("Margin: \(formattedMargin)")
        lines.append("")
        lines.append("Quality: \(quality.displayName)")
        lines.append("Status: \(isProfitable ? "✅ Profitable" : "❌ Loss")")
        if marginAtRisk {
            lines.append("⚠️  Margin below target (50%)")
        }
        lines.append("╚═══════════════════════════════╝")
        
        return lines.joined(separator: "\n")
    }
}

