// MODULE: StudioView
// VERSION: 2.0.0
// PURPOSE: Refined studio view with enhanced organization and visual polish

import SwiftUI

struct StudioView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var selectedClips: Set<UUID> = []
    @State private var showingExportOptions = false
    @State private var searchText = ""
    @State private var filterMode: FilterMode = .all
    @State private var animateIn = false
    @State private var showingBatchActions = false
    
    private let theme = DirectorStudioTheme.self
    
    enum FilterMode: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case thisWeek = "This Week"
        case favorites = "Favorites"
        
        var systemImage: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .today: return "calendar.day.timeline.left"
            case .thisWeek: return "calendar"
            case .favorites: return "star.fill"
            }
        }
    }
    
    var filteredClips: [GeneratedClip] {
        var clips = coordinator.clipRepository.clips
        
        // Apply search
        if !searchText.isEmpty {
            clips = clips.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply filter
        switch filterMode {
        case .all:
            break
        case .today:
            clips = clips.filter { Calendar.current.isDateInToday($0.createdAt) }
        case .thisWeek:
            let weekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            clips = clips.filter { $0.createdAt > weekAgo }
        case .favorites:
            // Demo filter removed - all clips can be favorited
            break
        }
        
        return clips.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                theme.Colors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Enhanced header
                    headerView
                        .padding(.horizontal)
                        .padding(.top, theme.Spacing.small)
                        .background(.regularMaterial)
                    
                    // Main content
                    if filteredClips.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 160), spacing: theme.Spacing.medium)
                            ], spacing: theme.Spacing.medium) {
                                ForEach(Array(filteredClips.enumerated()), id: \.element.id) { index, clip in
                                    EnhancedStudioClipCell(
                                        clip: clip,
                                        isSelected: selectedClips.contains(clip.id),
                                        onTap: {
                                            withAnimation(theme.Animation.quick) {
                                                if selectedClips.contains(clip.id) {
                                                    selectedClips.remove(clip.id)
                                                } else {
                                                    selectedClips.insert(clip.id)
                                                }
                                            }
                                            HapticFeedback.selection()
                                        }
                                    )
                                    .scaleEffect(animateIn ? 1 : 0.8)
                                    .opacity(animateIn ? 1 : 0)
                                    .animation(
                                        theme.Animation.bouncy
                                            .delay(Double(index) * 0.03),
                                        value: animateIn
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                    
                    // Batch actions bar
                    if !selectedClips.isEmpty {
                        batchActionsBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Studio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(FilterMode.allCases, id: \.self) { mode in
                            Button(action: { 
                                filterMode = mode
                                HapticFeedback.selection()
                            }) {
                                Label(mode.rawValue, systemImage: mode.systemImage)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(theme.Colors.primary)
                    }
                }
            }
        }
        .onAppear {
            loadClips()
            withAnimation(theme.Animation.gentle) {
                animateIn = true
            }
        }
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        VStack(spacing: theme.Spacing.medium) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search clips...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(theme.Spacing.small)
            .background(Color(.systemGray6))
            .cornerRadius(theme.CornerRadius.medium)
            
            // Stats bar
            HStack(spacing: theme.Spacing.large) {
                StatBadge(
                    value: "\(coordinator.clipRepository.clips.count)",
                    label: "Total Clips",
                    icon: "film.stack",
                    color: theme.Colors.primary
                )
                
                StatBadge(
                    value: formatDuration(totalDuration),
                    label: "Total Duration",
                    icon: "timer",
                    color: theme.Colors.secondary
                )
                
                StatBadge(
                    value: "\(todayClipsCount)",
                    label: "Today",
                    icon: "calendar",
                    color: theme.Colors.accent
                )
                
                Spacer()
            }
        }
        .padding(.vertical, theme.Spacing.small)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: theme.Spacing.large) {
            Spacer()
            
            // Animated illustration
            ZStack {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: theme.CornerRadius.large)
                        .stroke(
                            theme.Colors.primaryGradient.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 100 + CGFloat(index * 30), 
                               height: 100 + CGFloat(index * 30))
                        .rotationEffect(.degrees(Double(index * 15)))
                        .scaleEffect(animateIn ? 1 : 0.5)
                        .opacity(animateIn ? 1 - Double(index) * 0.3 : 0)
                        .animation(
                            theme.Animation.bouncy
                                .delay(Double(index) * 0.1),
                            value: animateIn
                        )
                }
                
                Image(systemName: "film.stack")
                    .font(.system(size: 50))
                    .foregroundColor(theme.Colors.primary)
                    .scaleEffect(animateIn ? 1 : 0.5)
                    .animation(theme.Animation.bouncy.delay(0.3), value: animateIn)
            }
            
            VStack(spacing: theme.Spacing.small) {
                Text("Nothing Here Yet")
                    .font(theme.Typography.title2)
                    .fontWeight(.semibold)
                
                Text("Your rendered scenes will appear here")
                    .font(theme.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, theme.Spacing.xxxLarge)
            }
            
            NavigationLink(destination: PromptView()) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create First Scene")
                }
                .font(theme.Typography.headline)
            }
            .primaryButton()
            .padding(.top, theme.Spacing.large)
            
            Spacer()
        }
    }
    
    private var batchActionsBar: some View {
        HStack(spacing: theme.Spacing.large) {
            Text("\(selectedClips.count) selected")
                .font(theme.Typography.callout)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Export button
            Button(action: { showingExportOptions = true }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
            }
            
            // Delete button
            Button(action: deleteSelected) {
                Image(systemName: "trash")
                    .font(.title2)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(.regularMaterial)
    }
    
    // MARK: - Actions
    
    private func loadClips() {
        Task {
            // Load clips from storage
            try? await coordinator.clipRepository.loadAll()
        }
    }
    
    private func deleteSelected() {
        // Delete selected clips
        HapticFeedback.notification(.warning)
    }
    
    // MARK: - Computed Properties
    
    private var totalDuration: TimeInterval {
        coordinator.clipRepository.clips.reduce(0) { $0 + $1.duration }
    }
    
    private var todayClipsCount: Int {
        let calendar = Calendar.current
        return coordinator.clipRepository.clips.filter {
            calendar.isDateInToday($0.createdAt)
        }.count
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Supporting Components

struct EnhancedStudioClipCell: View {
    let clip: GeneratedClip
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovered = false
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: theme.CornerRadius.medium)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(16/9, contentMode: .fit)
                
                Image(systemName: "film")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.8))
                
                // Overlays
                VStack {
                    HStack {
                        // Selection indicator
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(theme.Colors.primary)
                                .background(Color.white)
                                .clipShape(Circle())
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer()
                        
                        // Demo badges removed - all clips are real
                    }
                    .padding(theme.Spacing.small)
                    
                    Spacer()
                    
                    // Duration overlay
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.caption2)
                            Text(formatDuration(clip.duration))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, theme.Spacing.small)
                        .padding(.vertical, theme.Spacing.xxSmall)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(theme.CornerRadius.small)
                    }
                    .padding(theme.Spacing.small)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: theme.CornerRadius.medium)
                    .stroke(isSelected ? theme.Colors.primary : Color.clear, lineWidth: 3)
            )
            
            // Info
            VStack(alignment: .leading, spacing: theme.Spacing.xxSmall) {
                Text(clip.name)
                    .font(theme.Typography.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(formatRelativeDate(clip.createdAt))
                    .font(theme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, theme.Spacing.xxSmall)
            .padding(.vertical, theme.Spacing.small)
        }
        .background(Color(.systemBackground))
        .cornerRadius(theme.CornerRadius.large)
        .shadow(
            color: theme.Shadow.medium.color,
            radius: isHovered ? theme.Shadow.large.radius : theme.Shadow.medium.radius,
            y: isHovered ? theme.Shadow.large.y : theme.Shadow.medium.y
        )
        .scaleEffect(isHovered ? 1.02 : 1)
        .animation(theme.Animation.quick, value: isHovered)
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct StatBadge: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    private let theme = DirectorStudioTheme.self
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.Spacing.xxSmall) {
            HStack(spacing: theme.Spacing.xxSmall) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(theme.Typography.headline)
                    .fontWeight(.bold)
            }
            
            Text(label)
                .font(theme.Typography.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Studio Grid – iPhone 3-Column (390pt Optimized)
struct StudioGrid: View {
    @Binding var clips: [GeneratedClip]
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(clips) { clip in
                ClipThumbnail(clip: clip)
                    .onTapGesture(count: 2) {
                        coordinator.path.append(.editRoom(clip: clip))
                    }
                    .onLongPressGesture {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        // Start drag reorder
                    }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Clip Thumbnail with Micro-Reflection
struct ClipThumbnail: View {
    let clip: GeneratedClip
    @State private var isSelected = false
    
    var body: some View {
        ZStack {
            // Use placeholder or thumbnail if available
            if let thumbnailURL = clip.thumbnailURL {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(DirectorStudioTheme.Colors.darkSurface)
                }
                .clipped()
            } else {
                Rectangle()
                    .fill(DirectorStudioTheme.Colors.darkSurface)
                    .overlay(
                        Image(systemName: "film")
                            .foregroundColor(.secondary)
                    )
            }
            
            // Micro-reflection
            LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 40)
            
            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DirectorStudioTheme.Colors.accent, lineWidth: 1)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture { isSelected.toggle() }
    }
}
