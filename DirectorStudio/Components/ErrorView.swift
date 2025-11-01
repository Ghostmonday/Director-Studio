// MODULE: ErrorView
// VERSION: 1.0.0
// PURPOSE: User-friendly error display components

import SwiftUI

/// Error display with retry options
struct ErrorView: View {
    let error: Error
    let action: ErrorAction
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    @State private var showDetails = false
    
    init(
        error: Error,
        action: ErrorAction = .generic,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.error = error
        self.action = action
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: action.icon)
                .font(.system(size: 50))
                .foregroundColor(action.color)
            
            // Title
            Text(action.title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // User-friendly message
            Text(action.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Action buttons
            HStack(spacing: 16) {
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                
                if let onRetry = onRetry {
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Roll Again")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(action.color)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)
            
            // Technical details toggle
            Button(action: { showDetails.toggle() }) {
                HStack {
                    Text("Technical Details")
                        .font(.caption)
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            if showDetails {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
    }
}

/// Error action types
enum ErrorAction {
    case generic
    case network
    case apiKey
    case storage
    case permission
    
    var icon: String {
        switch self {
        case .generic: return "exclamationmark.triangle.fill"
        case .network: return "wifi.slash"
        case .apiKey: return "key.slash.fill"
        case .storage: return "externaldrive.badge.exclamationmark"
        case .permission: return "lock.shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .generic: return .orange
        case .network: return .red
        case .apiKey: return .purple
        case .storage: return .blue
        case .permission: return .yellow
        }
    }
    
    var title: String {
        switch self {
        case .generic: return "Scene Not Ready"
        case .network: return "Connection Lost"
        case .apiKey: return "Setup Required"
        case .storage: return "Storage Issue"
        case .permission: return "Permission Needed"
        }
    }
    
    var message: String {
        switch self {
        case .generic: 
            return "Something unexpected happened. Let's try that again."
        case .network: 
            return "We lost connection. Check your internet and roll again."
        case .apiKey: 
            return "Complete setup in Settings to start creating."
        case .storage: 
            return "Storage is full. Free up space to save your work."
        case .permission: 
            return "We need your permission to access this feature."
        }
    }
}

/// Inline error banner
struct ErrorBanner: View {
    let message: String
    let type: ErrorBannerType
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.body)
                
                Text(message)
                    .font(.subheadline)
                    .lineLimit(2)
                
                Spacer()
                
                Button(action: { 
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundColor(type.color.opacity(0.8))
                }
            }
            .padding()
            .background(type.backgroundColor)
            .foregroundColor(type.foregroundColor)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                // Auto-dismiss after 5 seconds for non-critical errors
                if type != .error {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
        }
    }
}

enum ErrorBannerType {
    case error
    case warning
    case info
    case success
    
    var icon: String {
        switch self {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        case .success: return .green
        }
    }
    
    var backgroundColor: Color {
        color.opacity(0.15)
    }
    
    var foregroundColor: Color {
        color.opacity(0.9)
    }
}

// Preview
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            ErrorView(
                error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Network timeout"]),
                action: .network,
                onRetry: {},
                onDismiss: {}
            )
            
            ErrorBanner(
                message: "API key not configured. Please check Settings.",
                type: .warning,
                isShowing: .constant(true)
            )
            .padding()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
