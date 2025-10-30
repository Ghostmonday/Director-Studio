// MODULE: AdaptiveContentView
// VERSION: 1.0.0
// PURPOSE: iPhone-optimized navigation interface

import SwiftUI

/// Content view optimized for iPhone
struct AdaptiveContentView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showingSettings = false
    
    var body: some View {
        iPhoneLayout
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(coordinator)
            }
            .keyboardShortcuts()
    }
    
    // MARK: - iPhone Layout
    @ViewBuilder
    private var iPhoneLayout: some View {
        ZStack {
            DirectorStudioTheme.Colors.cinemaGrey
                .ignoresSafeArea()
            
            TabView(selection: $coordinator.selectedTab) {
                PromptView()
                    .tabItem {
                        Label("Create", systemImage: "wand.and.stars")
                    }
                    .tag(AppTab.prompt)
                
                StudioView()
                    .tabItem {
                        Label("Studio", systemImage: "film.stack")
                    }
                    .tag(AppTab.studio)
                
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "photo.stack")
                    }
                    .tag(AppTab.library)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(DirectorStudioTheme.Colors.primary)
                    .padding()
                    .background(Circle().fill(DirectorStudioTheme.Colors.stainlessSteel))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            }
            .padding()
            .padding(.top, 40)
        }
    }
}

// MARK: - iPad Views (Disabled for iPhone-only app)
/*
struct SidebarView: View {
    @Binding var selection: AppTab
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var creditsManager = CreditsManager.shared
    
    var body: some View {
        List {
            Section {
                Button(action: { selection = .prompt }) {
                    Label("Create", systemImage: "wand.and.stars")
                        .font(.headline)
                        .foregroundColor(selection == .prompt ? DirectorStudioTheme.Colors.primary : .primary)
                }
                .keyboardShortcut("1", modifiers: .command)
                .listRowBackground(selection == .prompt ? DirectorStudioTheme.Colors.primary.opacity(0.2) : Color.clear)
                
                Button(action: { selection = .studio }) {
                    Label("Studio", systemImage: "film.stack")
                        .font(.headline)
                        .foregroundColor(selection == .studio ? DirectorStudioTheme.Colors.primary : .primary)
                }
                .keyboardShortcut("2", modifiers: .command)
                .listRowBackground(selection == .studio ? DirectorStudioTheme.Colors.primary.opacity(0.2) : Color.clear)
                
                Button(action: { selection = .library }) {
                    Label("Library", systemImage: "photo.stack")
                        .font(.headline)
                        .foregroundColor(selection == .library ? DirectorStudioTheme.Colors.primary : .primary)
                }
                .keyboardShortcut("3", modifiers: .command)
                .listRowBackground(selection == .library ? DirectorStudioTheme.Colors.primary.opacity(0.2) : Color.clear)
            }
            
            Section("Account") {
                HStack {
                    Label("Credits", systemImage: "banknote")
                    Spacer()
                    Text("\(creditsManager.tokens)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.secondary.opacity(0.2)))
                }
                
                if creditsManager.isDevMode {
                    Label("Developer Mode", systemImage: "hammer.fill")
                        .foregroundColor(DirectorStudioTheme.Colors.primary)
                }
            }
            
            Section {
                Button(action: {
                    // Quick actions
                }) {
                    Label("New from Template", systemImage: "doc.badge.plus")
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                
                Button(action: {
                    // Recent prompts
                }) {
                    Label("Recent Prompts", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("DirectorStudio")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    // Refresh action
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}



struct iPadLibraryView: View {
    var body: some View {
        // Enhanced library with sidebar filters
        HStack(spacing: 0) {
            // Filter sidebar
            VStack(alignment: .leading) {
                Text("Filters")
                    .font(.title3.bold())
                    .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    FilterOption(title: "All Clips", systemImage: "film")
                    FilterOption(title: "Favorites", systemImage: "star.fill")
                    FilterOption(title: "Recent", systemImage: "clock")
                    FilterOption(title: "In Progress", systemImage: "hourglass")
                }
                .padding()
                
                Spacer()
            }
            .frame(width: 220)
            .background(Color.black.opacity(0.3))
            
            Divider()
            
            // Main library content
            LibraryView()
        }
    }
}

// MARK: - iPad Settings View
struct iPadSettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            SettingsView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                        .keyboardShortcut(.escape, modifiers: [])
                    }
                }
        }
        .frame(minWidth: 600, idealWidth: 800, minHeight: 600, idealHeight: 800)
    }
}

// MARK: - Helper Views

struct FilterOption: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(DirectorStudioTheme.Colors.primary)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Environment Extensions
private struct GridColumnsKey: EnvironmentKey {
    static let defaultValue: Int = 2
}

extension EnvironmentValues {
    var gridColumns: Int {
        get { self[GridColumnsKey.self] }
        set { self[GridColumnsKey.self] = newValue }
    }
}
*/
