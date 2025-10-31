// MODULE: WaveformView
// VERSION: 1.0.0
// PURPOSE: Real-time waveform visualization for audio recording
// BUILD STATUS: ✅ Complete

import SwiftUI

/// Real-time waveform visualization component
public struct WaveformView: View {
    let data: [Float]
    let barWidth: CGFloat
    let barSpacing: CGFloat
    let color: Color
    let backgroundColor: Color
    
    public init(
        data: [Float],
        barWidth: CGFloat = 3,
        barSpacing: CGFloat = 2,
        color: Color = DirectorStudioTheme.Colors.secondary,
        backgroundColor: Color = Color.clear
    ) {
        self.data = data
        self.barWidth = barWidth
        self.barSpacing = barSpacing
        self.color = color
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor
                
                HStack(alignment: .center, spacing: barSpacing) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        RoundedRectangle(cornerRadius: barWidth / 2)
                            .fill(color)
                            .frame(
                                width: barWidth,
                                height: max(2, CGFloat(value) * geometry.size.height)
                            )
                            .animation(.easeOut(duration: 0.05), value: value)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

/// Animated waveform view with gradient
public struct AnimatedWaveformView: View {
    @State private var animationOffset: CGFloat = 0
    let data: [Float]
    let color: Color
    
    public init(data: [Float], color: Color = DirectorStudioTheme.Colors.secondary) {
        self.data = data
        self.color = color
    }
    
    public var body: some View {
        ZStack {
            WaveformView(
                data: data,
                barWidth: 3,
                barSpacing: 2,
                color: color.opacity(0.6)
            )
            
            // Animated gradient overlay
            LinearGradient(
                colors: [
                    color.opacity(0.8),
                    color.opacity(0.4),
                    color.opacity(0.8)
                ],
                startPoint: UnitPoint(x: animationOffset, y: 0),
                endPoint: UnitPoint(x: animationOffset + 0.5, y: 0)
            )
            .mask(
                WaveformView(
                    data: data,
                    barWidth: 3,
                    barSpacing: 2
                )
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                animationOffset = 1.0
            }
        }
    }
}

