// MODULE: LibraryView
// VERSION: 1.0.0
// PURPOSE: Storage management interface with Local/iCloud/Backend switching

import SwiftUI

/// Library view with storage location selector
struct LibraryView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @StateObject private var viewModel = LibraryViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Storage location picker
                Picker("Storage", selection: $viewModel.selectedLocation) {
                    ForEach(StorageLocation.allCases, id: \.self) { location in
                        Text(location.displayName).tag(location)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Auto-upload toggle
                Toggle("Auto-upload to iCloud", isOn: $viewModel.autoUploadEnabled)
                    .padding(.horizontal)
                    .disabled(coordinator.isGuestMode)
                
                Divider()
                    .padding(.vertical)
                
                // Content grid
                if viewModel.clips.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No clips in \(viewModel.selectedLocation.displayName)")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 150), spacing: 16)
                        ], spacing: 16) {
                            ForEach(viewModel.clips) { clip in
                                ClipCell(clip: clip, isSelected: false)
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                // Storage info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Storage Used")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(viewModel.storageUsed)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Available")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(viewModel.storageAvailable)
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
            }
            .navigationTitle("Library")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
                #endif
            }
            .onChange(of: viewModel.selectedLocation) { _, newLocation in
                viewModel.loadClips(from: newLocation, coordinator: coordinator)
            }
            .onAppear {
                viewModel.loadClips(from: viewModel.selectedLocation, coordinator: coordinator)
            }
        }
    }
}

// SettingsView has been moved to Features/Settings/SettingsView.swift

