// MODULE: AnimatedEmptyState
// VERSION: 1.0.0
// PURPOSE: Smart empty states for Library/Studio views

import SwiftUI

struct AnimatedEmptyState: View {
    let title: String
    let message: String
    let actionTitle: String
    let systemImage: String
    let action: () -> Void
    
    @State private var bounce = false
    @State private var iconRotation: Double = 0
    
    init(
        title: String,
        message: String,
        actionTitle: String,
        systemImage: String = "film.stack",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.systemImage = systemImage
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated icon
            ZStack {
                // Background rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 2)
                        .frame(width: 80 + CGFloat(index * 20), height: 80 + CGFloat(index * 20))
                        .scaleEffect(bounce ? 1.1 : 0.9)
                        .animation(
                            Animation.easeInOut(duration: 2.5)
                                .repeatForever()
                                .delay(Double(index) * 0.3),
                            value: bounce
                        )
                }
                
                // Main icon
                Image(systemName: systemImage)
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                    .scaleEffect(bounce ? 1.1 : 0.9)
                    .rotationEffect(.degrees(iconRotation))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever()) {
                            bounce.toggle()
                        }
                        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                            iconRotation = 360
                        }
                    }
            }
            .frame(width: 140, height: 140)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            Button(action: {
                MicroHapticFeedback.light()
                action()
            }) {
                Label(actionTitle, systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 5)
            }
            .pressEffect(isPressed: false)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Specific empty states for different contexts

struct LibraryEmptyState: View {
    let onCreateVideo: () -> Void
    @State private var showHint = false
    
    var body: some View {
        VStack {
            AnimatedEmptyState(
                title: "Your Library is Empty",
                message: "Start creating amazing videos with AI. Your masterpieces will appear here.",
                actionTitle: "Create First Video",
                systemImage: "film.stack",
                action: onCreateVideo
            )
            
            // Helpful hint that appears after a delay
            if showHint {
                VStack(spacing: 8) {
                    Divider()
                        .frame(width: 200)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text("Tip: You can generate multiple clips at once!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.spring()) {
                    showHint = true
                }
            }
        }
    }
}

struct StudioEmptyState: View {
    let onImportVideo: () -> Void
    
    var body: some View {
        AnimatedEmptyState(
            title: "No Videos in Studio",
            message: "Import videos from your library or create new ones to start editing.",
            actionTitle: "Import from Library",
            systemImage: "square.and.arrow.down",
            action: onImportVideo
        )
    }
}

struct SearchEmptyState: View {
    let searchQuery: String
    let onClearSearch: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Results Found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("No videos match \"\(searchQuery)\"")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onClearSearch) {
                Text("Clear Search")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Loading skeleton for smoother transitions
struct EmptyStateLoadingSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 100, height: 100)
                .shimmer(isActive: isAnimating)
            
            // Text placeholders
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 200, height: 24)
                    .shimmer(isActive: isAnimating)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 250, height: 16)
                    .shimmer(isActive: isAnimating)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 180, height: 16)
                    .shimmer(isActive: isAnimating)
            }
            
            // Button placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 150, height: 44)
                .shimmer(isActive: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Preview
struct AnimatedEmptyState_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LibraryEmptyState(onCreateVideo: {})
                .frame(height: 400)
                .background(Color.gray.opacity(0.1))
            
            StudioEmptyState(onImportVideo: {})
                .frame(height: 400)
                .background(Color.gray.opacity(0.1))
        }
    }
}
