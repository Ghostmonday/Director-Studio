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

/// Individual clip progress card
struct ClipCard: View {
    let progress: ClipProgress
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    private var icon: String {
        switch progress.status {
        case .checkingCache:
            return "magnifyingglass"
        case .generating:
            return "film"
        case .polling:
            return "timer"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var color: Color {
        switch progress.status {
        case .completed:
            return .green
        case .failed:
            return .red
        default:
            return .blue
        }
    }
    
    private var title: String {
        switch progress.status {
        case .completed:
            return "Done"
        case .failed(let message):
            return "Failed\n\(message.prefix(20))"
        default:
            return progress.status.rawValue
        }
    }
    
    private var background: some View {
        Color(.systemBackground)
            .opacity(0.8)
    }
    
    private var borderColor: Color {
        switch progress.status {
        case .completed:
            return .green.opacity(0.5)
        case .failed:
            return .red.opacity(0.5)
        default:
            return .blue.opacity(0.3)
        }
    }
}

#Preview {
    let orchestrator = ClipGenerationOrchestrator(apiKey: "test")
    return NavigationView {
        GenerationSummaryView(orchestrator: orchestrator)
    }
}

