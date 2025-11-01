// MODULE: SplashScreenView
// VERSION: 1.0.0
// PURPOSE: ARKit-enhanced splash screen with 3D logo animation
// BUILD STATUS: ✅ Complete

import SwiftUI
#if canImport(ARKit)
import ARKit
#endif

/// Splash screen with 3D logo animation
struct SplashScreenView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 3D Logo with rotation
                Image(systemName: "film.circle.fill")
                    .font(.system(size: 120))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotation3DEffect(
                        .degrees(rotation),
                        axis: (x: 1, y: 1, z: 0)
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .shadow(color: .blue.opacity(0.6), radius: 30)
                
                // App name
                Text("DirectorStudio")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
            
            // Simulated lens flare effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.3),
                            .blue.opacity(0.1),
                            .clear
                        ],
                        center: .topTrailing,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: 100, y: -150)
                .blur(radius: 20)
                .opacity(opacity * 0.5)
        }
        .onAppear {
            // Entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Continuous rotation
            withAnimation(
                .linear(duration: 4.0)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
            
            // Dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    isPresented = false
                }
            }
        }
    }
}

