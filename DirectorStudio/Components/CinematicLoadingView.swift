// MODULE: CinematicLoadingView
// VERSION: 1.0.0
// PURPOSE: Professional loading animation with narrative progress

import SwiftUI

struct CinematicLoadingView: View {
    @State private var currentPhrase = 0
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    let phrases = [
        "Setting up the scene...",
        "Adjusting the lighting...",
        "Directing the talent...",
        "Rolling camera...",
        "Capturing the magic..."
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Film reel animation
            ZStack {
                // Outer ring (film reel edge)
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                // Perforations
                ForEach(0..<8) { index in
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 3, height: 12)
                        .offset(y: -34)
                        .rotationEffect(.degrees(rotation + Double(index) * 45))
                }
                
                // Center film icon
                Image(systemName: "film")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 80, height: 80)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(pulseScale)
            .onAppear {
                // Rotation animation
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                
                // Pulse animation
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.1
                }
            }
            
            // Animated text
            Text(phrases[currentPhrase])
                .font(.headline)
                .foregroundColor(.white)
                .animation(.easeInOut, value: currentPhrase)
            
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<phrases.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentPhrase ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.spring(), value: currentPhrase)
                }
            }
        }
        .padding(40)
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        DirectorStudioTheme.Colors.backgroundBase,
                        DirectorStudioTheme.Colors.surfacePanel
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle film grain
                FilmGrainOverlay()
            }
        )
        .cornerRadius(20)
        .cinemaDepth(3)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                if currentPhrase < phrases.count - 1 {
                    currentPhrase += 1
                } else {
                    currentPhrase = 0
                }
            }
        }
    }
}

/// Subtle film grain overlay for cinematic feel
struct FilmGrainOverlay: View {
    var body: some View {
        // Simplified grain - just subtle noise
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.01),
                        Color.black.opacity(0.01)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

// MARK: - Preview

struct CinematicLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            DirectorStudioTheme.Colors.backgroundBase
                .ignoresSafeArea()
            
            CinematicLoadingView()
        }
    }
}

