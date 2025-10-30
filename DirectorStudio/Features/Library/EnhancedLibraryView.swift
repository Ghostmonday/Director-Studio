import SwiftUI
import AVKit

struct LibraryView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = LibraryViewModel()
    @State private var viewMode: ViewMode = .grid
    @State private var sortOption: SortOption = .dateNewest
    @State private var filterOption: FilterOption = .all
    @State private var searchText = ""
    @State private var selectedClip: GeneratedClip?
    @State private var showingPreview = false
    @State private var animateIn = false
    @State private var showingOptions = false
    
    enum ViewMode: String, CaseIterable {
        case grid = "square.grid.2x2"
        case list = "list.bullet"
        
        var columns: [GridItem] {
            switch self {
            case .grid:
                return [GridItem(.adaptive(minimum: 160), spacing: 16)]
            case .list:
                return [GridItem(.flexible())]
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case dateNewest = "Newest First"
        case dateOldest = "Oldest First"
        case nameAZ = "Name A-Z"
        case nameZA = "Name Z-A"
        case duration = "Duration"
        
        var systemImage: String {
            switch self {
            case .dateNewest, .dateOldest: return "calendar"
            case .nameAZ, .nameZA: return "textformat.abc"
            case .duration: return "timer"
            }
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All Clips"
        case custom = "My Clips"
        case synced = "Synced"
        case local = "Local Only"
    }
    
    var filteredAndSortedClips: [GeneratedClip] {
        var clips = viewModel.clips
        
        switch filterOption {
        case .all:
            break
        case .custom:
            break
        case .synced:
            clips = clips.filter { $0.syncStatus == .synced }
        case .local:
            clips = clips.filter { $0.syncStatus == .notUploaded }
        }
        
        if !searchText.isEmpty {
            clips = clips.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch sortOption {
        case .dateNewest:
            clips.sort { $0.createdAt > $1.createdAt }
        case .dateOldest:
            clips.sort { $0.createdAt < $1.createdAt }
        case .nameAZ:
            clips.sort { $0.name < $1.name }
        case .nameZA:
            clips.sort { $0.name > $1.name }
        case .duration:
            clips.sort { $0.duration > $1.duration }
        }
        
        return clips
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                adaptiveBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerControls
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    storageLocationPicker
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    
                    Divider()
                        .background(adaptiveDividerColor)
                    
                    if filteredAndSortedClips.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVGrid(columns: viewMode.columns, spacing: 16) {
                                ForEach(Array(filteredAndSortedClips.enumerated()), id: \.element.id) { index, clip in
                                    clipView(for: clip)
                                        .scaleEffect(animateIn ? 1 : 0.8)
                                        .opacity(animateIn ? 1 : 0)
                                        .animation(
                                            .spring(response: 0.5, dampingFraction: 0.7)
                                                .delay(Double(index) * 0.05),
                                            value: animateIn
                                        )
                                        .onTapGesture {
                                            selectedClip = clip
                                            showingPreview = true
                                        }
                                }
                            }
                            .padding(20)
                        }
                    }
                    
                    storageInfoBar
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Picker("View Mode", selection: $viewMode.animation(.spring())) {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Image(systemName: mode.rawValue)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 80)
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .sheet(item: $selectedClip) { clip in
                ClipPreviewSheet(clip: clip)
            }
            .onAppear {
                viewModel.loadClips(from: viewModel.selectedLocation, coordinator: coordinator)
                withAnimation {
                    animateIn = true
                }
            }
            .onChange(of: viewModel.selectedLocation) { _, newLocation in
                animateIn = false
                viewModel.loadClips(from: newLocation, coordinator: coordinator)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        animateIn = true
                    }
                }
            }
        }
    }
    
    private var adaptiveBackground: Color {
        colorScheme == .dark ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.949, green: 0.949, blue: 0.969)
    }
    
    private var adaptiveDividerColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)
    }
    
    private var headerControls: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                TextField("Search clips...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                    }
                }
            }
            .padding(10)
            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
            .cornerRadius(10)
            
            Button(action: { showingOptions.toggle() }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .popover(isPresented: $showingOptions) {
                sortAndFilterOptions
            }
        }
    }
    
    private var sortAndFilterOptions: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sort By")
                    .font(.headline)
                
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        sortOption = option
                        showingOptions = false
                    }) {
                        HStack {
                            Image(systemName: option.systemImage)
                                .frame(width: 20)
                            Text(option.rawValue)
                            Spacer()
                            if sortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Filter")
                    .font(.headline)
                
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Button(action: {
                        filterOption = option
                        showingOptions = false
                    }) {
                        HStack {
                            Text(option.rawValue)
                            Spacer()
                            if filterOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .frame(width: 280)
    }
    
    private var storageLocationPicker: some View {
        VStack(spacing: 8) {
            Picker("Storage", selection: $viewModel.selectedLocation) {
                ForEach(StorageLocation.allCases, id: \.self) { location in
                    HStack {
                        Image(systemName: location.systemImage)
                        Text(location.displayName)
                    }
                    .tag(location)
                }
            }
            .pickerStyle(.segmented)
            
            HStack {
                Toggle("", isOn: $viewModel.autoUploadEnabled)
                    .labelsHidden()
                Text("Auto-upload to iCloud")
                    .font(.subheadline)
                Spacer()
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
    }
    
    @ViewBuilder
    private func clipView(for clip: GeneratedClip) -> some View {
        if viewMode == .grid {
            EnhancedClipCell(
                clip: clip,
                isSelected: selectedClip?.id == clip.id,
                onDelete: { clip in
                    viewModel.deleteClip(clip)
                }
            )
        } else {
            EnhancedClipRow(
                clip: clip,
                isSelected: selectedClip?.id == clip.id,
                onDelete: { clip in
                    viewModel.deleteClip(clip)
                }
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateIn)
                
                Image(systemName: "film.stack")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(animateIn ? 0 : -10))
                    .animation(.spring(response: 1, dampingFraction: 0.7), value: animateIn)
            }
            
            VStack(spacing: 8) {
                Text("No clips yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            NavigationLink(destination: PromptView()) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create First Scene")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
            }
            .scaleEffect(animateIn ? 1 : 0.9)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateIn)
            
            Spacer()
        }
    }
    
    private var emptyStateMessage: String {
        switch viewModel.selectedLocation {
        case .local:
            return "Start creating amazing video clips that will be stored locally on your device"
        case .iCloud:
            return "Your iCloud clips will appear here once you create and sync them"
        case .backend:
            return "Backend clips will be available across all your devices"
        }
    }
    
    private var storageInfoBar: some View {
        HStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "internaldrive")
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Used")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(viewModel.storageUsed)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            Divider()
                .frame(height: 30)
            
            HStack(spacing: 8) {
                Image(systemName: "film.stack")
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clips")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(filteredAndSortedClips.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
            
            if !NetworkMonitor.shared.isOnline {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Available")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(viewModel.storageAvailable)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
}

extension StorageLocation {
    var systemImage: String {
        switch self {
        case .local:
            return "iphone"
        case .iCloud:
            return "icloud"
        case .backend:
            return "server.rack"
        }
    }
}
