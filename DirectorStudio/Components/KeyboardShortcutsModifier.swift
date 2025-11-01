// MODULE: KeyboardShortcutsModifier
// VERSION: 1.0.0
// PURPOSE: Global keyboard shortcuts for iPad productivity

import SwiftUI

struct KeyboardShortcutsModifier: ViewModifier {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var creditsManager = CreditsManager.shared
    @State private var showingShortcutsOverlay = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                #if targetEnvironment(macCatalyst) || os(iOS)
                setupKeyCommands()
                #endif
            }
            .overlay(alignment: .center) {
                if showingShortcutsOverlay {
                    KeyboardShortcutsOverlay(isShowing: $showingShortcutsOverlay)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .keyboardShortcut("?", modifiers: .command) {
                withAnimation {
                    showingShortcutsOverlay.toggle()
                }
            }
            .keyboardShortcut("n", modifiers: .command) {
                coordinator.createNewProject()
            }
            .keyboardShortcut("g", modifiers: [.command, .shift]) {
                coordinator.selectedTab = .prompt
                coordinator.startGeneration()
            }
            .keyboardShortcut("e", modifiers: .command) {
                coordinator.openSelectedInEditRoom()
            }
            .keyboardShortcut("s", modifiers: .command) {
                coordinator.saveCurrentWork()
            }
            .keyboardShortcut("z", modifiers: .command) {
                coordinator.undo()
            }
            .keyboardShortcut("z", modifiers: [.command, .shift]) {
                coordinator.redo()
            }
    }
    
    private func setupKeyCommands() {
        // Additional setup for keyboard commands if needed
    }
}

// MARK: - Keyboard Shortcuts Overlay
struct KeyboardShortcutsOverlay: View {
    @Binding var isShowing: Bool
    private let theme = DirectorStudioTheme.self
    
    let shortcuts: [(category: String, items: [(keys: String, action: String)])] = [
        ("General", [
            ("⌘ N", "New Project"),
            ("⌘ S", "Save"),
            ("⌘ Z", "Undo"),
            ("⇧ ⌘ Z", "Redo"),
            ("⌘ ,", "Settings"),
            ("⌘ ?", "Show/Hide Shortcuts")
        ]),
        ("Navigation", [
            ("⌘ 1", "Create Tab"),
            ("⌘ 2", "Studio Tab"),
            ("⌘ 3", "Library Tab"),
            ("⌘ ⇧ [", "Previous Tab"),
            ("⌘ ⇧ ]", "Next Tab")
        ]),
        ("Creation", [
            ("⇧ ⌘ G", "Generate Video"),
            ("⌘ ⏎", "Confirm & Generate"),
            ("⌘ K", "Clear Prompt"),
            ("⇧ ⌘ L", "Load Last Prompt"),
            ("⌘ T", "Templates")
        ]),
        ("Studio", [
            ("⌘ E", "Edit Selected"),
            ("⌘ D", "Duplicate"),
            ("⌘ ⌫", "Delete Selected"),
            ("⌘ A", "Select All"),
            ("⌘ ⇧ A", "Deselect All"),
            ("Space", "Quick Preview")
        ]),
        ("View", [
            ("⌘ +", "Zoom In"),
            ("⌘ -", "Zoom Out"),
            ("⌘ 0", "Reset Zoom"),
            ("⌥ ⌘ I", "Toggle Inspector"),
            ("⌘ R", "Refresh")
        ])
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isShowing = false
                    }
                }
            
            // Content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Keyboard Shortcuts")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(theme.Colors.cinemaGrey)
                
                // Shortcuts grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], alignment: .leading, spacing: theme.Spacing.large) {
                        ForEach(shortcuts, id: \.category) { section in
                            VStack(alignment: .leading, spacing: theme.Spacing.medium) {
                                Text(section.category)
                                    .font(.title3.bold())
                                    .foregroundColor(theme.Colors.primary)
                                
                                VStack(alignment: .leading, spacing: theme.Spacing.small) {
                                    ForEach(section.items, id: \.action) { shortcut in
                                        HStack {
                                            Text(shortcut.keys)
                                                .font(.system(.body, design: .monospaced))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(theme.Colors.stainlessSteel)
                                                )
                                            
                                            Text(shortcut.action)
                                                .foregroundColor(.white.opacity(0.9))
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                        }
                    }
                    .padding()
                }
            }
            .frame(maxWidth: 800)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.Colors.cinemaGrey)
            )
            .shadow(radius: 30)
        }
    }
}

// MARK: - View Extension
extension View {
    func keyboardShortcuts() -> some View {
        self.modifier(KeyboardShortcutsModifier())
    }
    
    func keyboardShortcut<T>(_ key: KeyEquivalent, modifiers: EventModifiers = .command, action: @escaping () -> T) -> some View {
        self.background(
            Button("") { _ = action() }
                .keyboardShortcut(key, modifiers: modifiers)
                .hidden()
        )
    }
}

// MARK: - App Coordinator Extensions
extension AppCoordinator {
    func createNewProject() {
        // Implementation
        selectedTab = .prompt
        NotificationCenter.default.post(name: .createNewProject, object: nil)
    }
    
    func startGeneration() {
        NotificationCenter.default.post(name: .startGeneration, object: nil)
    }
    
    func openSelectedInEditRoom() {
        NotificationCenter.default.post(name: .openInEditRoom, object: nil)
    }
    
    func saveCurrentWork() {
        NotificationCenter.default.post(name: .saveWork, object: nil)
    }
    
    func undo() {
        NotificationCenter.default.post(name: .performUndo, object: nil)
    }
    
    func redo() {
        NotificationCenter.default.post(name: .performRedo, object: nil)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let createNewProject = Notification.Name("createNewProject")
    static let startGeneration = Notification.Name("startGeneration")
    static let openInEditRoom = Notification.Name("openInEditRoom")
    static let saveWork = Notification.Name("saveWork")
    static let performUndo = Notification.Name("performUndo")
    static let performRedo = Notification.Name("performRedo")
}
