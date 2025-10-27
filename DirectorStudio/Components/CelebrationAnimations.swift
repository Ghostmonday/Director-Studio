// MODULE: CelebrationAnimations
// VERSION: 1.0.0
// PURPOSE: Success celebrations and delightful animations

import SwiftUI

// MARK: - Confetti System

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGSize
    let shape: ConfettiShape
    var position: CGPoint
    var velocity: CGVector
    var rotation: Double = 0
    var rotationSpeed: Double
    var opacity: Double = 1.0
    
    enum ConfettiShape {
        case circle
        case square
        case triangle
        case star
    }
    
    static func random(startPosition: CGPoint) -> ConfettiPiece {
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .yellow]
        let size = CGSize(
            width: CGFloat.random(in: 8...14),
            height: CGFloat.random(in: 8...14)
        )
        
        return ConfettiPiece(
            color: colors.randomElement()!,
            size: size,
            shape: ConfettiShape.allCases.randomElement()!,
            position: startPosition,
            velocity: CGVector(
                dx: CGFloat.random(in: -200...200),
                dy: CGFloat.random(in: -600...-300)
            ),
            rotationSpeed: Double.random(in: -360...360)
        )
    }
}

extension ConfettiPiece.ConfettiShape: CaseIterable {
    static var allCases: [ConfettiPiece.ConfettiShape] = [.circle, .square, .triangle, .star]
}

// MARK: - Confetti View

struct ConfettiCelebration: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var timer: Timer?
    let duration: TimeInterval = 3.0
    let particleCount: Int = 50
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                        .position(piece.position)
                        .opacity(piece.opacity)
                }
            }
            .onAppear {
                startCelebration(in: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
        .allowsHitTesting(false)
    }
    
    private func startCelebration(in size: CGSize) {
        // Generate initial burst
        for _ in 0..<particleCount {
            confettiPieces.append(
                ConfettiPiece.random(
                    startPosition: CGPoint(x: size.width / 2, y: size.height * 0.8)
                )
            )
        }
        
        // Animate particles
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateParticles()
        }
        
        // Stop after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            timer?.invalidate()
            withAnimation(.easeOut(duration: 1)) {
                confettiPieces.removeAll()
            }
        }
    }
    
    private func updateParticles() {
        for i in confettiPieces.indices {
            // Update position
            confettiPieces[i].position.x += confettiPieces[i].velocity.dx * 0.016
            confettiPieces[i].position.y += confettiPieces[i].velocity.dy * 0.016
            
            // Apply gravity
            confettiPieces[i].velocity.dy += 980 * 0.016
            
            // Apply air resistance
            confettiPieces[i].velocity.dx *= 0.99
            confettiPieces[i].velocity.dy *= 0.99
            
            // Update rotation
            confettiPieces[i].rotation += confettiPieces[i].rotationSpeed * 0.016
            
            // Fade out when falling
            if confettiPieces[i].velocity.dy > 0 {
                confettiPieces[i].opacity = max(0, confettiPieces[i].opacity - 0.01)
            }
        }
        
        // Remove invisible pieces
        confettiPieces.removeAll { $0.opacity <= 0 }
    }
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    
    var body: some View {
        shape
            .fill(piece.color)
            .frame(width: piece.size.width, height: piece.size.height)
            .rotationEffect(.degrees(piece.rotation))
    }
    
    @ViewBuilder
    private var shape: some Shape {
        switch piece.shape {
        case .circle:
            Circle()
        case .square:
            Rectangle()
        case .triangle:
            Triangle()
        case .star:
            Star()
        }
    }
}

// MARK: - Success Checkmark Animation

struct SuccessCheckmark: View {
    @State private var scale: CGFloat = 0.3
    @State private var checkmarkTrim: CGFloat = 0
    @State private var circleRotation: Double = -90
    @State private var showPulse = false
    
    var body: some View {
        ZStack {
            // Pulse effect
            if showPulse {
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                    .scaleEffect(showPulse ? 2 : 1)
                    .opacity(showPulse ? 0 : 1)
                    .animation(.easeOut(duration: 1), value: showPulse)
            }
            
            // Background circle
            Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
            
            // Animated circle border
            Circle()
                .trim(from: 0, to: checkmarkTrim)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 96, height: 96)
                .rotationEffect(.degrees(circleRotation))
                .scaleEffect(scale)
            
            // Checkmark
            Path { path in
                path.move(to: CGPoint(x: 30, y: 50))
                path.addLine(to: CGPoint(x: 45, y: 65))
                path.addLine(to: CGPoint(x: 70, y: 35))
            }
            .trim(from: 0, to: checkmarkTrim)
            .stroke(Color.green, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .frame(width: 100, height: 100)
            .scaleEffect(scale)
        }
        .onAppear {
            animate()
        }
    }
    
    private func animate() {
        // Scale in
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.0
        }
        
        // Draw circle and checkmark
        withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
            checkmarkTrim = 1.0
        }
        
        // Pulse effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showPulse = true
        }
        
        // Haptic feedback
        HapticFeedback.success()
    }
}

// MARK: - Fireworks Animation

struct FireworksCelebration: View {
    @State private var fireworks: [Firework] = []
    let burstCount = 5
    
    struct Firework: Identifiable {
        let id = UUID()
        let position: CGPoint
        let color: Color
        let particles: [Particle]
        
        struct Particle: Identifiable {
            let id = UUID()
            var position: CGPoint
            let angle: Double
            let speed: Double
            var opacity: Double = 1.0
        }
        
        static func create(at position: CGPoint) -> Firework {
            let colors: [Color] = [.blue, .purple, .orange, .pink, .yellow]
            var particles: [Particle] = []
            
            // Create burst pattern
            for i in 0..<24 {
                let angle = (Double(i) / 24) * 360
                let speed = Double.random(in: 100...200)
                particles.append(
                    Particle(
                        position: position,
                        angle: angle,
                        speed: speed
                    )
                )
            }
            
            return Firework(
                position: position,
                color: colors.randomElement()!,
                particles: particles
            )
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(fireworks) { firework in
                    FireworkView(firework: firework)
                }
            }
            .onAppear {
                launchFireworks(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func launchFireworks(in size: CGSize) {
        for i in 0..<burstCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                let position = CGPoint(
                    x: CGFloat.random(in: size.width * 0.2...size.width * 0.8),
                    y: CGFloat.random(in: size.height * 0.3...size.height * 0.7)
                )
                fireworks.append(Firework.create(at: position))
                
                // Remove after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if !fireworks.isEmpty {
                        fireworks.removeFirst()
                    }
                }
            }
        }
    }
}

struct FireworkView: View {
    let firework: FireworksCelebration.Firework
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            ForEach(firework.particles) { particle in
                Circle()
                    .fill(firework.color)
                    .frame(width: 4, height: 4)
                    .offset(
                        x: cos(particle.angle * .pi / 180) * particle.speed * animationProgress,
                        y: sin(particle.angle * .pi / 180) * particle.speed * animationProgress
                    )
                    .opacity(1.0 - animationProgress)
                    .position(firework.position)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animationProgress = 1.0
            }
        }
    }
}

// MARK: - Celebration Manager

class CelebrationManager: ObservableObject {
    static let shared = CelebrationManager()
    @Published var activeCelebration: CelebrationType?
    
    enum CelebrationType {
        case confetti
        case checkmark
        case fireworks
        case combined
    }
    
    func celebrate(_ type: CelebrationType, duration: TimeInterval = 3.0) {
        activeCelebration = type
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.activeCelebration = nil
        }
    }
}

// MARK: - Celebration Overlay

struct CelebrationOverlay: View {
    @StateObject private var manager = CelebrationManager.shared
    
    var body: some View {
        ZStack {
            if let celebration = manager.activeCelebration {
                switch celebration {
                case .confetti:
                    ConfettiCelebration()
                case .checkmark:
                    SuccessCheckmark()
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                case .fireworks:
                    FireworksCelebration()
                case .combined:
                    ZStack {
                        FireworksCelebration()
                        ConfettiCelebration()
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Custom Shapes

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        let points = 5
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        
        return Path { path in
            for i in 0..<points * 2 {
                let angle = (Double(i) * .pi) / Double(points) - (.pi / 2)
                let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
                let x = center.x + CGFloat(cos(angle)) * radius
                let y = center.y + CGFloat(sin(angle)) * radius
                
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            path.closeSubpath()
        }
    }
}
