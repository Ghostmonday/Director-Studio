// MODULE: PullToRevealStats
// VERSION: 1.0.0
// PURPOSE: Pull-to-reveal statistics for Library and Studio views

import SwiftUI

// MARK: - Stats Model

struct VideoStats {
    let totalVideos: Int
    let totalDuration: TimeInterval
    let creditsUsed: Int
    let storageUsed: Int64 // in bytes
    let favoriteCount: Int
    let averageDuration: TimeInterval
    
    var formattedDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        let seconds = Int(totalDuration) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    var formattedStorage: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: storageUsed)
    }
    
    var formattedAverageDuration: String {
        let avg = totalVideos > 0 ? averageDuration : 0
        return String(format: "%.1fs", avg)
    }
}

// MARK: - Pull to Reveal Modifier

struct PullToRevealStats: ViewModifier {
    @State private var pullProgress: CGFloat = 0
    @State private var isShowingStats = false
    @State private var hapticTriggered = false
    let stats: VideoStats
    let threshold: CGFloat = 100
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            // Stats view that reveals on pull
            if pullProgress > 0 || isShowingStats {
                StatsView(
                    stats: stats,
                    pullProgress: isShowingStats ? 1.0 : pullProgress
                )
                .frame(height: isShowingStats ? 120 : max(0, pullProgress * 120))
                .clipped()
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // Main content with gesture
            GeometryReader { geometry in
                content
                    .offset(y: max(0, pullProgress * 120))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let translation = value.translation.height
                                
                                if translation > 0 && !isShowingStats {
                                    // Pull down gesture
                                    pullProgress = min(1.0, translation / threshold)
                                    
                                    // Haptic feedback at threshold
                                    if pullProgress >= 1.0 && !hapticTriggered {
                                        HapticFeedback.impact(.medium)
                                        hapticTriggered = true
                                    }
                                }
                            }
                            .onEnded { value in
                                let translation = value.translation.height
                                
                                if translation > threshold && !isShowingStats {
                                    // Show stats
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        isShowingStats = true
                                        pullProgress = 0
                                    }
                                    
                                    // Auto-hide after 5 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                        withAnimation(.spring()) {
                                            isShowingStats = false
                                        }
                                    }
                                } else {
                                    // Reset
                                    withAnimation(.spring()) {
                                        pullProgress = 0
                                    }
                                }
                                
                                hapticTriggered = false
                            }
                    )
            }
        }
    }
}

// MARK: - Stats View Component

struct StatsView: View {
    let stats: VideoStats
    let pullProgress: CGFloat
    
    var body: some View {
        VStack(spacing: 16) {
            // Pull indicator
            if pullProgress < 1.0 {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(pullProgress * 180))
                    Text(pullProgress < 0.5 ? "Pull for stats" : "Release to reveal")
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(pullProgress * 180))
                }
                .foregroundColor(.secondary)
                .opacity(1.0 - pullProgress)
            }
            
            // Stats grid
            HStack(spacing: 24) {
                StatItem(
                    icon: "film.stack",
                    title: "Videos",
                    value: "\(stats.totalVideos)",
                    color: .blue
                )
                
                StatItem(
                    icon: "timer",
                    title: "Total Time",
                    value: stats.formattedDuration,
                    color: .green
                )
                
                StatItem(
                    icon: "sparkles",
                    title: "Credits Used",
                    value: "\(stats.creditsUsed)",
                    color: .orange
                )
                
                StatItem(
                    icon: "internaldrive",
                    title: "Storage",
                    value: stats.formattedStorage,
                    color: .purple
                )
            }
            .padding(.horizontal)
            .opacity(pullProgress)
            .scaleEffect(0.9 + (pullProgress * 0.1))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, pullProgress < 1.0 ? 8 : 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Stats View (Minimal)

struct QuickStatsBar: View {
    let stats: VideoStats
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapsed view
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                
                Text("\(stats.totalVideos) videos • \(stats.formattedDuration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Expanded stats
            if isExpanded {
                Divider()
                
                HStack(spacing: 20) {
                    QuickStatItem(label: "Avg Duration", value: stats.formattedAverageDuration)
                    QuickStatItem(label: "Favorites", value: "\(stats.favoriteCount)")
                    QuickStatItem(label: "Credits/Video", value: "\(stats.totalVideos > 0 ? stats.creditsUsed / stats.totalVideos : 0)")
                }
                .padding()
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct QuickStatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - View Extension

extension View {
    func pullToRevealStats(_ stats: VideoStats) -> some View {
        self.modifier(PullToRevealStats(stats: stats))
    }
}
