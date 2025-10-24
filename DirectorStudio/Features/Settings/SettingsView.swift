// MODULE: SettingsView
// VERSION: 1.0.0
// PURPOSE: Settings panel for app preferences and configuration

import SwiftUI

// VideoStyle is now in CoreTypes.swift
extension VideoStyle {
    var displayName: String {
        switch self {
        case .cinematic: return "Cinematic"
        case .documentary: return "Documentary"
        case .animated: return "Animated"
        case .artistic: return "Artistic"
        }
    }
}

/// Settings view with multiple sections
struct SettingsView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.dismiss) var dismiss
    @AppStorage("preferredVideoStyle") private var preferredVideoStyle = VideoStyle.cinematic.rawValue
    @AppStorage("defaultDuration") private var defaultDuration: Double = 10.0
    @AppStorage("autoEnhance") private var autoEnhance = true
    @AppStorage("autoSaveToPhotos") private var autoSaveToPhotos = false
    @AppStorage("enableHaptics") private var enableHaptics = true
    
    @State private var showingAPIKeyEntry = false
    @State private var showingClearCache = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            Form {
                // Video Generation Settings
                Section {
                    // Video Style
                    HStack {
                        Label("Default Style", systemImage: "paintbrush.fill")
                        Spacer()
                        Picker("Style", selection: $preferredVideoStyle) {
                            ForEach(VideoStyle.allCases, id: \.rawValue) { style in
                                Text(style.displayName).tag(style.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.blue)
                    }
                    
                    // Default Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Default Duration: \(Int(defaultDuration))s", systemImage: "timer")
                        Slider(value: $defaultDuration, in: 3...20, step: 1)
                            .tint(.blue)
                    }
                    
                    // Auto Enhance
                    Toggle(isOn: $autoEnhance) {
                        Label("Auto-Enhance Prompts", systemImage: "wand.and.stars")
                    }
                    .tint(.blue)
                    
                } header: {
                    Text("Video Generation")
                } footer: {
                    Text("These settings apply to all new video generations")
                }
                
                // Storage Settings
                Section {
                    // Auto Save
                    Toggle(isOn: $autoSaveToPhotos) {
                        Label("Auto-Save to Photos", systemImage: "photo.on.rectangle.angled")
                    }
                    .tint(.green)
                    
                    // Storage Location
                    NavigationLink(destination: StorageSettingsView()) {
                        Label("Storage Location", systemImage: "externaldrive.fill")
                    }
                    
                    // Clear Cache
                    Button(action: { showingClearCache = true }) {
                        Label("Clear Cache", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    
                } header: {
                    Text("Storage")
                }
                
                /* API Configuration - Disabled (managed via xcconfig files)
                Section {
                    NavigationLink(destination: APISettingsView()) {
                        HStack {
                            Label("API Keys", systemImage: "key.fill")
                            Spacer()
                            if coordinator.hasValidAPIKeys {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                } header: {
                    Text("Configuration")
                } footer: {
                    Text("Configure API keys for video generation services")
                }
                */
                
                // Credits & Monetization
                Section {
                    NavigationLink(destination: CreditsPurchaseView()) {
                        HStack {
                            Label("Credits", systemImage: "creditcard.fill")
                            Spacer()
                            Text("\(CreditsManager.shared.credits)")
                                .font(.headline)
                                .foregroundColor(CreditsManager.shared.credits > 0 ? .primary : .red)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Account")
                } footer: {
                    Text(CreditsManager.shared.credits == 0 ? "You're in Demo Mode - Purchase credits for real AI generation" : "Each credit = 1 video generation")
                }
                
                // Appearance
                Section {
                    // Haptics
                    Toggle(isOn: $enableHaptics) {
                        Label("Haptic Feedback", systemImage: "waveform")
                    }
                    .tint(.purple)
                    
                    // App Icon
                    NavigationLink(destination: AppIconSelectorView()) {
                        Label("App Icon", systemImage: "app.fill")
                    }
                    
                } header: {
                    Text("Appearance")
                }
                
                // About
                Section {
                    // Tutorial
                    Button(action: {
                        UserDefaults.standard.set(false, forKey: "HasCompletedOnboarding")
                        dismiss()
                    }) {
                        Label("Show Tutorial", systemImage: "questionmark.circle")
                    }
                    
                    // Support
                    Link(destination: URL(string: "https://directorstudio.app/support")!) {
                        Label("Support", systemImage: "lifepreserver")
                    }
                    
                    // Privacy Policy
                    Link(destination: URL(string: "https://directorstudio.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    
                    // About
                    NavigationLink(destination: AboutView()) {
                        Label("About DirectorStudio", systemImage: "info.circle")
                    }
                    
                } header: {
                    Text("Support")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Clear Cache", isPresented: $showingClearCache) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text("This will remove all temporary files and may free up storage space.")
        }
    }
    
    private func clearCache() {
        // Clear temporary files
        let fileManager = FileManager.default
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            try? fileManager.removeItem(at: cachesURL)
        }
        
        // Haptic feedback
        if enableHaptics {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

/// API Settings subview
struct APISettingsView: View {
    @State private var polloAPIKey = UserDefaults.standard.string(forKey: "POLLO_API_KEY") ?? ""
    @State private var deepSeekAPIKey = UserDefaults.standard.string(forKey: "DEEPSEEK_API_KEY") ?? ""
    @State private var showingSaveSuccess = false
    @State private var isValidating = false
    
    var body: some View {
        Form {
            /* API Keys Section - Disabled (managed via xcconfig files)
            Section {
                SecureField("Pollo API Key", text: $polloAPIKey)
                    .textContentType(.password)
                    .autocapitalization(.none)
                
                SecureField("DeepSeek API Key", text: $deepSeekAPIKey)
                    .textContentType(.password)
                    .autocapitalization(.none)
                
            } header: {
                Text("API Keys")
            } footer: {
                Text("Your API keys are stored securely on your device")
            }
            */
            
            Section {
                Button(action: validateAndSave) {
                    if isValidating {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Validating...")
                        }
                    } else {
                        Text("Save & Validate")
                    }
                }
                .frame(maxWidth: .infinity)
                .disabled(isValidating)
            }
        }
        .navigationTitle("API Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $showingSaveSuccess) {
            Button("OK") { }
        } message: {
            Text("API keys saved successfully")
        }
    }
    
    private func validateAndSave() {
        isValidating = true
        
        // Save keys
        UserDefaults.standard.set(polloAPIKey, forKey: "POLLO_API_KEY")
        UserDefaults.standard.set(deepSeekAPIKey, forKey: "DEEPSEEK_API_KEY")
        
        // Simulate validation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isValidating = false
            showingSaveSuccess = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

/// Storage settings subview
struct StorageSettingsView: View {
    @AppStorage("preferredStorage") private var preferredStorage = "local"
    
    var body: some View {
        Form {
            Section {
                Picker("Storage Location", selection: $preferredStorage) {
                    Label("Local Only", systemImage: "iphone").tag("local")
                    Label("iCloud Sync", systemImage: "icloud").tag("icloud")
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: {
                Text("Default Storage")
            } footer: {
                Text("Choose where to store your projects and videos")
            }
            
            Section {
                // Storage usage
                HStack {
                    Text("Local Storage Used")
                    Spacer()
                    Text("2.3 GB")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("iCloud Storage Used")
                    Spacer()
                    Text("1.1 GB")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Storage Usage")
            }
        }
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// App icon selector
struct AppIconSelectorView: View {
    @State private var selectedIcon = UIApplication.shared.alternateIconName ?? "AppIcon"
    
    let icons = [
        "AppIcon": "Default",
        "AppIcon-Dark": "Dark Mode",
        "AppIcon-Gradient": "Gradient"
    ]
    
    var body: some View {
        Form {
            ForEach(icons.sorted(by: { $0.key < $1.key }), id: \.key) { key, name in
                HStack {
                    Image(uiImage: UIImage(named: key) ?? UIImage())
                        .resizable()
                        .frame(width: 60, height: 60)
                        .cornerRadius(12)
                    
                    Text(name)
                        .font(.headline)
                    
                    Spacer()
                    
                    if selectedIcon == key || (selectedIcon == "AppIcon" && key == "AppIcon") {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    setIcon(key)
                }
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func setIcon(_ iconName: String) {
        selectedIcon = iconName
        
        UIApplication.shared.setAlternateIconName(iconName == "AppIcon" ? nil : iconName) { error in
            if let error = error {
                print("Error setting icon: \(error)")
            }
        }
    }
}

/// About view
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "film.stack")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            Text("DirectorStudio")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("From journal to cinema")
                .font(.title3)
                .italic()
                .padding(.top)
            
            Spacer()
            
            VStack(spacing: 12) {
                Text("Created with ❤️ for storytellers")
                    .font(.footnote)
                
                Text("© 2025 DirectorStudio")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Extension for computed properties
extension AppCoordinator {
    var hasValidAPIKeys: Bool {
        let polloKey = UserDefaults.standard.string(forKey: "POLLO_API_KEY") ?? ""
        let deepSeekKey = UserDefaults.standard.string(forKey: "DEEPSEEK_API_KEY") ?? ""
        return !polloKey.isEmpty || !deepSeekKey.isEmpty
    }
}

// Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AppCoordinator())
    }
}
