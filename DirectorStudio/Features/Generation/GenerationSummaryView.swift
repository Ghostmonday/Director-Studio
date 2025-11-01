// MODULE: GenerationSummaryView
// VERSION: 1.0.0
// PURPOSE: Live dashboard for clip generation progress
// PRODUCTION-GRADE: SwiftUI reactive, grid layout, status indicators

import SwiftUI

/// Live dashboard showing generation progress for all clips
public struct GenerationSummaryView: View {
    @ObservedObject var orchestrator: ClipGenerationOrchestrator
    
    public init(orchestrator: ClipGenerationOrchestrator) {
        self.orchestrator = orchestrator
    }
    
    public var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                ForEach(orchestrator.progress.values.sorted(by: { $0.id.uuidString < $1.id.uuidString })) { prog in
                    ClipCard(progress: prog)
                }
            }
            .padding()
        }
        .navigationTitle("Generation Progress")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Individual clip progress card with enhanced status display
struct ClipCard: View {
    let progress: ClipProgress
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with animation for progress states
            ZStack {
                if progress.status.isProgressState {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: progress.status.color))
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: progress.status.icon)
                        .font(.title2)
                        .foregroundColor(progress.status.color)
                }
            }
            .frame(height: 32)
            
            // Status title
            Text(progress.status.rawValue)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(progress.status.color)
                .multilineTextAlignment(.center)
                .lineLimit(1)
            
            // Description
            Text(progress.status.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Task ID (if available)
            if let taskId = progress.taskId {
                Text(taskId.prefix(8))
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 2)
    }
    
    private var background: some View {
        Group {
            if progress.status.isProgressState {
                // Animated gradient for progress states
                LinearGradient(
                    colors: [
                        progress.status.color.opacity(0.1),
                        progress.status.color.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color(.systemBackground)
                    .opacity(0.8)
            }
        }
    }
    
    private var borderColor: Color {
        progress.status.color.opacity(0.4)
    }
    
    private var borderWidth: CGFloat {
        progress.status.isProgressState ? 2 : 1
    }
    
    private var shadowColor: Color {
        progress.status.color.opacity(0.2)
    }
    
    private var shadowRadius: CGFloat {
        progress.status.isProgressState ? 8 : 4
    }
}

#Preview {
    let orchestrator = ClipGenerationOrchestrator(accessKey: "test", secretKey: "test")
    return NavigationView {
        GenerationSummaryView(orchestrator: orchestrator)
    }
}

