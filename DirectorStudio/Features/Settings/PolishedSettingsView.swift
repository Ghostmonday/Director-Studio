// MODULE: PolishedSettingsView
// VERSION: 2.0.0
// PURPOSE: Refined settings view with enhanced organization and visual polish

import SwiftUI
import StoreKit

struct PolishedSettingsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @ObservedObject private var creditsManager = CreditsManager.shared
    @State private var showingCreditsPurchase = false
    @State private var showingAbout = false
    @State private var animateIn = false
    @State private var devOptionsUnlocked = false
    @State private var tapCount = 0
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.Colors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: theme.Spacing.large) {
                        // Profile section
                        profileSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(theme.Animation.smooth.delay(0.1), value: animateIn)
                        
                        // Credits section
                        creditsSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(theme.Animation.smooth.delay(0.2), value: animateIn)
                        
                        // Preferences section
                        preferencesSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(theme.Animation.smooth.delay(0.3), value: animateIn)
                        
                        // Developer section (if unlocked)
                        if devOptionsUnlocked {
                            developerSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                        }
                        
                        // About section
                        aboutSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(theme.Animation.smooth.delay(0.4), value: animateIn)
                    }
                    .padding(.horizontal, theme.Spacing.medium)
                    .padding(.vertical, theme.Spacing.large)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Dismiss settings
                    }
                    .foregroundColor(theme.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showingCreditsPurchase) {
            EnhancedCreditsPurchaseView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .onAppear {
            withAnimation(theme.Animation.gentle) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Sections
    
    private var profileSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            // Profile header
            HStack(spacing: theme.Spacing.medium) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(theme.Colors.primaryGradient)
                        .frame(width: 60, height: 60)
                    
                    Text("DS")
                        .font(theme.Typography.title3)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: theme.Spacing.xxSmall) {
                    Text("DirectorStudio User")
                        .font(theme.Typography.headline)
                    
                    if coordinator.isAuthenticated {
                        Label("iCloud Connected", systemImage: "checkmark.icloud")
                            .font(theme.Typography.caption)
                            .foregroundColor(theme.Colors.success)
                    } else {
                        Label("Guest Mode", systemImage: "person.crop.circle.badge.questionmark")
                            .font(theme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Quick stats
            HStack(spacing: theme.Spacing.medium) {
                ProfileStat(value: "\(coordinator.clips.count)", label: "Clips")
                Divider().frame(height: 30)
                ProfileStat(value: formatStorage(), label: "Storage")
                Divider().frame(height: 30)
                ProfileStat(value: "\(creditsManager.credits)", label: "Credits")
            }
            .padding(.vertical, theme.Spacing.small)
        }
        .cardStyle()
    }
    
    private var creditsSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            SettingsSectionHeader(title: "Credits & Billing", icon: "creditcard")
            
            // Current balance card
            HStack {
                VStack(alignment: .leading, spacing: theme.Spacing.xxSmall) {
                    Text("Current Balance")
                        .font(theme.Typography.callout)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: theme.Spacing.xxSmall) {
                        Text("\(creditsManager.credits)")
                            .font(theme.Typography.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(creditColor)
                        
                        Text("credits")
                            .font(theme.Typography.body)
                            .foregroundColor(.secondary)
                    }
                    
                    if creditsManager.isDevMode {
                        Pill(text: "DEV MODE", color: theme.Colors.creditsFree)
                    }
                }
                
                Spacer()
                
                // Purchase button
                Button(action: { showingCreditsPurchase = true }) {
                    VStack(spacing: theme.Spacing.xxSmall) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add")
                            .font(theme.Typography.caption)
                    }
                }
                .foregroundColor(theme.Colors.primary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: theme.CornerRadius.large)
                    .fill(creditColor.opacity(0.1))
            )
            
            // Purchase history
            SettingsRow(
                title: "Purchase History",
                subtitle: "View all transactions",
                icon: "clock.arrow.circlepath",
                action: {}
            )
            
            // Restore purchases
            SettingsRow(
                title: "Restore Purchases",
                subtitle: "Recover previous purchases",
                icon: "arrow.clockwise",
                action: restorePurchases
            )
        }
    }
    
    private var preferencesSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            SettingsSectionHeader(title: "Preferences", icon: "gearshape")
            
            // Export quality
            SettingsRow(
                title: "Export Quality",
                subtitle: "1080p HD",
                icon: "video",
                action: {}
            )
            
            // Auto-save
            SettingsToggle(
                title: "Auto-save to Photos",
                subtitle: "Save generated clips to camera roll",
                icon: "photo.on.rectangle",
                isOn: .constant(true)
            )
            
            // iCloud sync
            SettingsToggle(
                title: "iCloud Sync",
                subtitle: "Sync clips across devices",
                icon: "icloud",
                isOn: .constant(true)
            )
            
            // Haptic feedback
            SettingsToggle(
                title: "Haptic Feedback",
                subtitle: "Vibration on interactions",
                icon: "hand.tap",
                isOn: .constant(true)
            )
        }
    }
    
    private var developerSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            SettingsSectionHeader(title: "Developer Options", icon: "hammer")
                .foregroundColor(theme.Colors.creditsFree)
            
            // Dev mode toggle
            SettingsToggle(
                title: "Developer Mode",
                subtitle: "Free API usage for testing",
                icon: "testtube.2",
                isOn: .init(
                    get: { creditsManager.isDevMode },
                    set: { _ in toggleDevMode() }
                )
            )
            
            // Test credits
            SettingsRow(
                title: "Add Test Credits",
                subtitle: "Add 50 credits for testing",
                icon: "plus.circle",
                action: addTestCredits
            )
            
            // Reset credits
            SettingsRow(
                title: "Reset Credits",
                subtitle: "Set credits to 0",
                icon: "arrow.counterclockwise",
                action: resetCredits
            )
            
            // Clear cache
            SettingsRow(
                title: "Clear Cache",
                subtitle: "Remove temporary files",
                icon: "trash",
                action: {}
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme.CornerRadius.large)
                .fill(theme.Colors.creditsFree.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.CornerRadius.large)
                        .strokeBorder(theme.Colors.creditsFree.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var aboutSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            SettingsSectionHeader(title: "About", icon: "info.circle")
            
            // Version
            SettingsRow(
                title: "DirectorStudio",
                subtitle: "Version 1.0.0 (Build 1)",
                icon: "app.badge",
                action: {
                    tapCount += 1
                    if tapCount >= 5 {
                        withAnimation(theme.Animation.bouncy) {
                            devOptionsUnlocked = true
                        }
                        HapticFeedback.notification(.success)
                        tapCount = 0
                    }
                }
            )
            
            // Privacy policy
            SettingsRow(
                title: "Privacy Policy",
                subtitle: "View our privacy practices",
                icon: "hand.raised",
                action: {}
            )
            
            // Terms of service
            SettingsRow(
                title: "Terms of Service",
                subtitle: "View terms and conditions",
                icon: "doc.text",
                action: {}
            )
            
            // Support
            SettingsRow(
                title: "Get Support",
                subtitle: "Contact our team",
                icon: "questionmark.circle",
                action: {}
            )
            
            // Rate app
            SettingsRow(
                title: "Rate DirectorStudio",
                subtitle: "Share your feedback",
                icon: "star",
                action: requestReview
            )
        }
    }
    
    // MARK: - Helpers
    
    private var creditColor: Color {
        if creditsManager.isDevMode {
            return theme.Colors.creditsFree
        } else if creditsManager.credits == 0 {
            return theme.Colors.creditsEmpty
        } else if creditsManager.credits < 10 {
            return theme.Colors.creditsLow
        } else {
            return theme.Colors.creditsSufficient
        }
    }
    
    private func formatStorage() -> String {
        let totalSize = coordinator.clips.count * 50 // Assume 50MB per clip
        if totalSize > 1000 {
            return "\(totalSize / 1000)GB"
        } else {
            return "\(totalSize)MB"
        }
    }
    
    private func restorePurchases() {
        // Restore purchases logic
        HapticFeedback.impact(.medium)
    }
    
    private func toggleDevMode() {
        if creditsManager.isDevMode {
            creditsManager.disableDevMode()
        } else {
            creditsManager.enableDevMode(passcode: generateMonthlyPasscode())
        }
        HapticFeedback.impact(.medium)
    }
    
    private func generateMonthlyPasscode() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMyyyy"
        let dateString = formatter.string(from: Date())
        
        var hash = 0
        for char in dateString {
            hash = hash &* 31 &+ Int(char.asciiValue ?? 0)
        }
        
        return String(format: "%06d", abs(hash) % 1000000)
    }
    
    private func addTestCredits() {
        creditsManager.addCredits(50, fromPurchase: false)
        HapticFeedback.notification(.success)
    }
    
    private func resetCredits() {
        // Reset credits to 0
        creditsManager.useCredits(amount: creditsManager.credits)
        HapticFeedback.notification(.warning)
    }
    
    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Supporting Components

struct SettingsSectionHeader: View {
    let title: String
    let icon: String
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.Colors.primary)
            
            Text(title)
                .font(theme.Typography.headline)
            
            Spacer()
        }
        .padding(.top, theme.Spacing.small)
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.Spacing.medium) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(theme.Colors.primary)
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: theme.Spacing.xxSmall) {
                    Text(title)
                        .font(theme.Typography.callout)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(theme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, theme.Spacing.small)
        }
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        HStack(spacing: theme.Spacing.medium) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.Colors.primary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: theme.Spacing.xxSmall) {
                Text(title)
                    .font(theme.Typography.callout)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(theme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(theme.Colors.primary)
        }
        .padding(.vertical, theme.Spacing.small)
    }
}

struct ProfileStat: View {
    let value: String
    let label: String
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        VStack(spacing: theme.Spacing.xxSmall) {
            Text(value)
                .font(theme.Typography.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(theme.Typography.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // App icon
                Image(systemName: "film.stack")
                    .font(.system(size: 80))
                    .foregroundColor(DirectorStudioTheme.Colors.primary)
                
                // App info
                VStack(spacing: 8) {
                    Text("DirectorStudio")
                        .font(DirectorStudioTheme.Typography.largeTitle)
                    
                    Text("Create Amazing Videos with AI")
                        .font(DirectorStudioTheme.Typography.body)
                        .foregroundColor(.secondary)
                    
                    Text("Version 1.0.0")
                        .font(DirectorStudioTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                // Credits
                VStack(spacing: 16) {
                    Text("Made with ❤️ by Your Team")
                        .font(DirectorStudioTheme.Typography.callout)
                    
                    Text("© 2024 DirectorStudio. All rights reserved.")
                        .font(DirectorStudioTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
