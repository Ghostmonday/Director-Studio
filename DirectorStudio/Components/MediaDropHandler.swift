// MODULE: MediaDropHandler
// VERSION: 1.0.0
// PURPOSE: Universal drag and drop support for media files

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drop Delegate
struct MediaDropDelegate: DropDelegate {
    let onDrop: ([URL]) -> Void
    let onEnter: (() -> Void)?
    let onExit: (() -> Void)?
    
    init(
        onDrop: @escaping ([URL]) -> Void,
        onEnter: (() -> Void)? = nil,
        onExit: (() -> Void)? = nil
    ) {
        self.onDrop = onDrop
        self.onEnter = onEnter
        self.onExit = onExit
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        // Check if the drop contains supported file types
        return info.hasItemsConforming(to: [.fileURL, .movie, .image, .audio])
    }
    
    func dropEntered(info: DropInfo) {
        onEnter?()
    }
    
    func dropExited(info: DropInfo) {
        onExit?()
    }
    
    func performDrop(info: DropInfo) -> Bool {
        var urls: [URL] = []
        
        // Extract file URLs
        for provider in info.itemProviders(for: [.fileURL]) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        urls.append(url)
                        if urls.count == info.itemProviders(for: [.fileURL]).count {
                            onDrop(urls)
                        }
                    }
                }
            }
        }
        
        return true
    }
}

// MARK: - Media Drop View Modifier
struct MediaDropModifier: ViewModifier {
    @State private var isDraggingOver = false
    let supportedTypes: [MediaType]
    let onDrop: ([URL]) -> Void
    
    enum MediaType {
        case video
        case image
        case audio
        case any
        
        var utTypes: [UTType] {
            switch self {
            case .video:
                return [.movie, .video, .mpeg4Movie, .quickTimeMovie]
            case .image:
                return [.image, .jpeg, .png, .heif]
            case .audio:
                return [.audio, .mp3, .wav, .aiff]
            case .any:
                return [.movie, .video, .image, .audio, .data]
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                // Drop indicator overlay
                Group {
                    if isDraggingOver {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(DirectorStudioTheme.Colors.primary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        DirectorStudioTheme.Colors.primary,
                                        style: StrokeStyle(lineWidth: 3, dash: [10])
                                    )
                            )
                            .overlay(
                                VStack(spacing: 16) {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(DirectorStudioTheme.Colors.primary)
                                    
                                    Text("Drop files here")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(supportedTypesText)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            )
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }
                }
            )
            .onDrop(of: supportedTypes.flatMap { $0.utTypes }, delegate: MediaDropDelegate(
                onDrop: { urls in
                    withAnimation {
                        isDraggingOver = false
                    }
                    handleDrop(urls: urls)
                },
                onEnter: {
                    withAnimation {
                        isDraggingOver = true
                    }
                },
                onExit: {
                    withAnimation {
                        isDraggingOver = false
                    }
                }
            ))
    }
    
    private var supportedTypesText: String {
        if supportedTypes.contains(.any) {
            return "All media files supported"
        }
        
        let types = supportedTypes.map { type in
            switch type {
            case .video: return "Video"
            case .image: return "Image"
            case .audio: return "Audio"
            case .any: return "Any"
            }
        }
        
        return "Supported: \(types.joined(separator: ", "))"
    }
    
    private func handleDrop(urls: [URL]) {
        let filteredUrls = urls.filter { url in
            guard let uti = UTType(filenameExtension: url.pathExtension) else { return false }
            return supportedTypes.contains { type in
                type.utTypes.contains { supportedType in
                    uti.conforms(to: supportedType)
                }
            }
        }
        
        if !filteredUrls.isEmpty {
            onDrop(filteredUrls)
        }
    }
}

// MARK: - Drag Source Modifier
struct DragSourceModifier<T: Transferable>: ViewModifier {
    let item: T
    let preview: () -> any View
    
    func body(content: Content) -> some View {
        content
            .draggable(item) {
                AnyView(preview())
            }
    }
}

// MARK: - View Extensions
extension View {
    func mediaDrop(
        supportedTypes: [MediaDropModifier.MediaType] = [.any],
        onDrop: @escaping ([URL]) -> Void
    ) -> some View {
        self.modifier(MediaDropModifier(
            supportedTypes: supportedTypes,
            onDrop: onDrop
        ))
    }
    
    func dragSource<T: Transferable>(
        _ item: T,
        preview: @escaping () -> any View = { EmptyView() }
    ) -> some View {
        self.modifier(DragSourceModifier(item: item, preview: preview))
    }
}

// MARK: - Clip Drop Handler
struct ClipDropHandler {
    static func handleDroppedClips(
        urls: [URL],
        into library: LibraryViewModel
    ) {
        for url in urls {
            if isVideoFile(url) {
                // Import video file
                Task {
                    await importVideoFile(url, into: library)
                }
            } else if isProjectFile(url) {
                // Import project file
                Task {
                    await importProjectFile(url, into: library)
                }
            }
        }
    }
    
    private static func isVideoFile(_ url: URL) -> Bool {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "m4v"]
        return videoExtensions.contains(url.pathExtension.lowercased())
    }
    
    private static func isProjectFile(_ url: URL) -> Bool {
        return url.pathExtension.lowercased() == "directorstudio"
    }
    
    private static func importVideoFile(_ url: URL, into library: LibraryViewModel) async {
        // Implementation for importing video files
        print("Importing video: \(url.lastPathComponent)")
    }
    
    private static func importProjectFile(_ url: URL, into library: LibraryViewModel) async {
        // Implementation for importing project files
        print("Importing project: \(url.lastPathComponent)")
    }
}

// MARK: - Transferable Conformance
extension GeneratedClip: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
        FileRepresentation(contentType: .movie, 
                          exporting: { clip in
            // Return the file for the clip
            if let localURL = clip.localURL {
                return SentTransferredFile(localURL)
            }
            throw TransferError.clipNotAvailable
        }, importing: { received in
            // Import a file as a GeneratedClip
            let file = received.file
            return GeneratedClip(
                name: file.lastPathComponent,
                localURL: file,
                duration: 0
            )
        })
    }
    
    enum TransferError: Error {
        case clipNotAvailable
    }
}
