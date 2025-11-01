// MODULE: ShimmerView
// VERSION: 1.0.0
// PURPOSE: Elegant loading placeholder with shimmer animation

import SwiftUI

/// A view that displays a shimmer loading animation
struct ShimmerView: View {
    @State private var startPoint = UnitPoint(x: -1, y: 0.5)
    @State private var endPoint = UnitPoint(x: 0, y: 0.5)
    
    let gradientColors = [
        Color(.systemGray5),
        Color(.systemGray6),
        Color(.systemGray5)
    ]
    
    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                startPoint = UnitPoint(x: 1, y: 0.5)
                endPoint = UnitPoint(x: 2, y: 0.5)
            }
        }
    }
}

/// A skeleton loading view for common UI patterns
struct SkeletonView: View {
    let type: SkeletonType
    
    enum SkeletonType {
        case text(lines: Int = 1)
        case card
        case thumbnail
        case button
    }
    
    var body: some View {
        switch type {
        case .text(let lines):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<lines, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 16)
                        .frame(maxWidth: index == lines - 1 ? 200 : .infinity)
                        .overlay(ShimmerView())
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            
        case .card:
            RoundedRectangle(cornerRadius: DirectorStudioTheme.CornerRadius.large)
                .fill(Color(.systemGray6))
                .frame(height: 120)
                .overlay(ShimmerView())
                .clipShape(RoundedRectangle(cornerRadius: DirectorStudioTheme.CornerRadius.large))
            
        case .thumbnail:
            RoundedRectangle(cornerRadius: DirectorStudioTheme.CornerRadius.medium)
                .fill(Color(.systemGray6))
                .aspectRatio(16/9, contentMode: .fit)
                .overlay(ShimmerView())
                .clipShape(RoundedRectangle(cornerRadius: DirectorStudioTheme.CornerRadius.medium))
            
        case .button:
            RoundedRectangle(cornerRadius: DirectorStudioTheme.CornerRadius.large)
                .fill(Color(.systemGray6))
                .frame(height: 50)
                .overlay(ShimmerView())
                .clipShape(RoundedRectangle(cornerRadius: DirectorStudioTheme.CornerRadius.large))
        }
    }
}

// MARK: - Preview

struct ShimmerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SkeletonView(type: .text(lines: 3))
            SkeletonView(type: .card)
            SkeletonView(type: .thumbnail)
            SkeletonView(type: .button)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
