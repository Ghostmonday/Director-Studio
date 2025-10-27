// MODULE: LoadingView
// VERSION: 1.0.0
// PURPOSE: Reusable loading states and progress indicators

import SwiftUI

/// Modern loading view with progress
struct LoadingView: View {
    let message: String
    let progress: Double?
    @State private var isAnimating = false
    
    init(message: String = "Rolling...", progress: Double? = nil) {
        self.message = message
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated circles
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isAnimating ? 1.3 : 0.8)
                        .opacity(isAnimating ? 0.0 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
                
                // Center icon
                Image(systemName: "film")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            .frame(width: 100, height: 100)
            
            // Message
            Text(message)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Progress bar if available
            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
                    .scaleEffect(x: 1, y: 2)
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

/// Inline loading indicator
struct InlineLoadingView: View {
    let message: String
    @State private var dots = ""
    
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text(message + dots)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .onAppear {
            animateDots()
        }
    }
    
    private func animateDots() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if dots.count >= 3 {
                dots = ""
            } else {
                dots += "."
            }
        }
    }
}

/// Filmmaking-specific loading messages
struct DirectorLoadingMessages {
    static let generating = "Creating your vision..."
    static let enhancing = "Polishing every frame..."
    static let stitching = "Editing together..."
    static let uploading = "Saving to library..."
    static let processing = "Working on your scene..."
}

/// Cinematic loading phrases for narrative progress
struct CinematicLoadingPhrases {
    static let phrases = [
        "Setting up the scene...",
        "Adjusting the lighting...",
        "Directing the talent...",
        "Rolling camera...",
        "Capturing the magic..."
    ]
}

/// Cinematic loading view with film reel animation
struct CinematicLoadingView: View {
    @State private var currentPhrase = 0
    @State private var rotation: Double = 0
    @State private var isTyping = false
    
    let phrases = CinematicLoadingPhrases.phrases
    
    var body: some View {
        VStack(spacing: 32) {
            // Film reel animation
            ZStack {
                ForEach(0..<8) { index in
                    Rectangle()
                        .fill(DirectorStudioTheme.Colors.accent.opacity(0.7))
                        .frame(width: 4, height: 40)
                        .offset(y: -20)
                        .rotationEffect(.degrees(rotation + Double(index) * 45))
                }
                
                // Center dot
                Circle()
                    .fill(DirectorStudioTheme.Colors.accent)
                    .frame(width: 16, height: 16)
            }
            .frame(width: 80, height: 80)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            
            // Animated text
            Text(phrases[currentPhrase])
                .font(.headline)
                .foregroundColor(.primary)
                .animation(.easeInOut, value: currentPhrase)
            
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<phrases.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentPhrase ? DirectorStudioTheme.Colors.accent : Color.gray)
                        .frame(width: 8, height: 8)
                        .animation(.spring(), value: currentPhrase)
                }
            }
        }
        .padding(40)
        .background(DirectorStudioTheme.Colors.surfacePanel)
        .cornerRadius(20)
        .shadow(color: DirectorStudioTheme.Shadow.medium.color, radius: DirectorStudioTheme.Shadow.medium.radius)
        .onAppear {
            startPhraseRotation()
        }
    }
    
    private func startPhraseRotation() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            if currentPhrase < phrases.count - 1 {
                currentPhrase += 1
            } else {
                currentPhrase = 0
            }
        }
    }
}

/// Success animation view
struct SuccessAnimationView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    @State private var checkmarkTrim: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
                .opacity(opacity)
            
            // Checkmark
            Path { path in
                path.move(to: CGPoint(x: 30, y: 50))
                path.addLine(to: CGPoint(x: 45, y: 65))
                path.addLine(to: CGPoint(x: 70, y: 35))
            }
            .trim(from: 0, to: checkmarkTrim)
            .stroke(Color.green, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .frame(width: 100, height: 100)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                checkmarkTrim = 1.0
            }
        }
    }
}

// Preview
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            LoadingView(message: "Creating your vision...", progress: 0.65)
            CinematicLoadingView()
            InlineLoadingView(message: "Working on your scene")
            SuccessAnimationView()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
