import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var creditsManager = CreditsManager.shared
    @State private var showingCreditsPurchase = false
    @State private var showingAbout = false
    @State private var animateIn = false
    @State private var devOptionsUnlocked = false
    @State private var tapCount = 0
    @State private var showingDevPasscode = false
    @State private var devPasscode = ""
    @State private var showingLogs = false
    @State private var showingMonetizationCalculator = false
    @State private var showingRunwayAPIKey = false
    @State private var hasRunwayKey = false
    @AppStorage("lowDataMode") private var lowDataMode = false
    @AppStorage("themeVariant") private var themeVariant = "default"
    @AppStorage("betaMode") private var betaMode = false
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        NavigationView {
            ZStack {
                adaptiveBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: theme.Spacing.large) {
                        profileSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(theme.Animation.smooth.delay(0.1), value: animateIn)
                        
                        creditsSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(theme.Animation.smooth.delay(0.2), value: animateIn)
                        
                        preferencesSection
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(theme.Animation.smooth.delay(0.3), value: animateIn)
                        
                        if devOptionsUnlocked {
                            developerSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                        }
                        
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
                        dismiss()
                    }
                    .foregroundColor(theme.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showingCreditsPurchase) {
            CreditsPurchaseView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingMonetizationCalculator) {
            MonetizationAnalysisView()
        }
        .sheet(isPresented: $showingRunwayAPIKey) {
            RunwayAPIKeyView()
        }
        .alert("Developer Mode", isPresented: $showingDevPasscode) {
            TextField("Enter passcode", text: $devPasscode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) {
                devPasscode = ""
            }
            Button("Enable") {
                if creditsManager.enableDevMode(passcode: devPasscode) {
                    AppHapticFeedback.notification(.success)
                } else {
                    AppHapticFeedback.notification(.error)
                }
                devPasscode = ""
            }
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }
    
    private var adaptiveBackground: Color {
        if themeVariant == "sepia" {
            return Color(red: 0.929, green: 0.894, blue: 0.827)
        }
        return colorScheme == .dark ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.949, green: 0.949, blue: 0.969)
    }
    
    private var profileSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            SettingsSectionHeader(title: "Profile", icon: "person.circle")
            
            HStack(spacing: 16) {
                Circle()
                    .fill(LinearGradient(
                        colors: [theme.Colors.primary, theme.Colors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(coordinator.currentProject?.name.prefix(1).uppercased() ?? "U"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(coordinator.currentProject?.name ?? "User")
                        .font(.headline)
                    Text(coordinator.isAuthenticated ? "iCloud Enabled" : "Local Only")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.02))
            )
        }
    }
    
    private var creditsSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            SettingsSectionHeader(title: "Credits", icon: "banknote")
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(creditsManager.tokens)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("tokens available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingCreditsPurchase = true }) {
                    Text("Buy More")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(theme.Colors.primary)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.02))
            )
        }
    }
    
    private var preferencesSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            SettingsSectionHeader(title: "Preferences", icon: "gearshape")
            
            SettingsToggle(
                title: "Auto-save to Photos",
                subtitle: "Save generated clips to camera roll",
                icon: "photo.on.rectangle",
                isOn: .constant(true)
            )
            
            SettingsToggle(
                title: "iCloud Sync",
                subtitle: "Sync clips across devices",
                icon: "icloud",
                isOn: .constant(true)
            )
            
            SettingsToggle(
                title: "Low Data Mode",
                subtitle: "Disable frame previews and waveform rendering",
                icon: "antenna.radiowaves.left.and.right",
                isOn: $lowDataMode
            )
            
            SettingsToggle(
                title: "Haptic Feedback",
                subtitle: "Vibration on interactions",
                icon: "hand.tap",
                isOn: .constant(true)
            )
            
            Picker("Theme", selection: $themeVariant) {
                Text("Default").tag("default")
                Text("Sepia").tag("sepia")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, theme.Spacing.medium)
            
            if hasRunwayKey {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Runway API")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    Text("Estimated: $0.08/sec")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.02))
                )
            }
            
            SettingsRow(
                title: "Runway API Key",
                subtitle: hasRunwayKey ? "Your key is set" : "Use your own Runway key (optional)",
                icon: "key",
                action: { showingRunwayAPIKey = true }
            )
            .onAppear {
                hasRunwayKey = UserAPIKeysManager.shared.hasRunwayKey
            }
            
            SettingsRow(
                title: "Monetization Calculator",
                subtitle: "Calculate costs and analyze pricing",
                icon: "calculator",
                action: { showingMonetizationCalculator = true }
            )
            
            Divider()
                .padding(.vertical, theme.Spacing.small)
            
            SettingsToggle(
                title: "Beta Mode",
                subtitle: "Enable AI features (may consume credits)",
                icon: "testtube.2",
                isOn: $betaMode
            )
            .alert("Beta Mode", isPresented: .constant(betaMode && !betaMode)) {
                Button("OK") {}
            } message: {
                Text("Beta features may consume additional credits. Enable at your own risk.")
            }
        }
    }
    
    private var developerSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            SettingsSectionHeader(title: "Developer Options", icon: "hammer")
                .foregroundColor(theme.Colors.creditsFree)
            
            SettingsToggle(
                title: "Developer Mode",
                subtitle: "Free API usage for testing",
                icon: "testtube.2",
                isOn: .init(
                    get: { creditsManager.isDevMode },
                    set: { _ in toggleDevMode() }
                )
            )
            
            SettingsRow(
                title: "Add Test Credits",
                subtitle: "Add 1000 tokens for testing",
                icon: "plus.circle",
                action: {
                    creditsManager.tokens += 1000
                    AppHapticFeedback.notification(.success)
                }
            )
            
            SettingsRow(
                title: "View Logs",
                subtitle: "Debug information",
                icon: "doc.text",
                action: { showingLogs = true }
            )
        }
    }
    
    private var aboutSection: some View {
        VStack(spacing: theme.Spacing.medium) {
            SettingsSectionHeader(title: "About", icon: "info.circle")
            
            SettingsRow(
                title: "Version",
                subtitle: "2.1.0",
                icon: "app.badge",
                action: {}
            )
            
            SettingsRow(
                title: "About DirectorStudio",
                subtitle: "Learn more",
                icon: "info.circle",
                action: { showingAbout = true }
            )
        }
    }
    
    private func toggleDevMode() {
        if !creditsManager.isDevMode {
            showingDevPasscode = true
        } else {
            creditsManager.tokens = 0
        }
    }
    
    private func restorePurchases() {
        Task {
            await StoreKitManager.shared.restorePurchases()
        }
    }
}

struct SettingsSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("DirectorStudio")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 2.1.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Transform text into cinematic video clips with AI-powered generation.")
                        .font(.body)
                    
                    Divider()
                    
                    Text("Built with care for creators.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

enum AppHapticFeedback {
    case success
    case error
    case warning
    
    static func notification(_ type: AppHapticFeedback) {
        let generator = UINotificationFeedbackGenerator()
        switch type {
        case .success:
            generator.notificationOccurred(.success)
        case .error:
            generator.notificationOccurred(.error)
        case .warning:
            generator.notificationOccurred(.warning)
        }
    }
}




