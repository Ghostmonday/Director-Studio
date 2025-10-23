// MODULE: StorageLaunchView
// VERSION: 1.0.0
// PURPOSE: iPhone-first storage launch screen with local-first UX

import SwiftUI

struct StorageLaunchView: View {
    @StateObject private var viewModel = ProjectListViewModel()
    @State private var selectedStorage: StorageType = .local
    @State private var isLoading = false
    
    enum StorageType: String, CaseIterable {
        case local = "Local"
        case cloud = "Cloud"
        case backend = "Backend"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Storage Segmented Control (thumb-reach optimized)
            storageSelector
            
            // Content Area
            contentArea
        }
        .background(Color(.systemBackground))
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("DirectorStudio")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Your Projects")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.top, 44)
        .padding(.bottom, 20)
    }
    
    // MARK: - Storage Selector (44x44 tap targets)
    
    private var storageSelector: some View {
        HStack(spacing: 12) {
            ForEach(StorageType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedStorage = type
                    }
                }) {
                    Text(type.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(selectedStorage == type ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedStorage == type ? Color.accentColor : Color(.systemGray5))
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Content Area
    
    private var contentArea: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isLoading {
                    ForEach(0..<3) { _ in
                        ProjectRowSkeleton()
                    }
                } else if viewModel.items.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.items) { project in
                        ProjectRow(project: project)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Projects Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Create your first project to get started")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                viewModel.createProjectQuick(prompt: nil)
            }) {
                Text("Create Project")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Load Data
    
    private func loadData() {
        isLoading = true
        
        // Simulate ≤150ms local render
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isLoading = false
        }
    }
}

// MARK: - Project Row

struct ProjectRow: View {
    let project: ProjectOverview
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: "film.fill")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
                .frame(width: 56, height: 56)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(project.projectId)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(project.sceneCount ?? 0) scenes")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions (thumb-reach optimized)
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Skeleton Loader

struct ProjectRowSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray4))
                .frame(width: 56, height: 56)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray4))
                    .frame(width: 120, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    StorageLaunchView()
}

