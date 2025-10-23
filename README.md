# DirectorStudio

**Version:** 1.0.0  
**Platform:** iOS 17+, macOS 14+ (via Mac Catalyst)  
**Architecture:** SwiftUI + Modular Pipeline

## Overview

DirectorStudio is a cinematic content creation app that transforms text prompts into video clips with synchronized voiceovers. Users can generate clips, stitch them together, record voiceovers while watching playback, and manage all content through a unified storage system (Local, iCloud, Supabase).

## Critical Flow

**Script → Video → Voiceover → Storage**

1. Enter text prompt in **Prompt** tab
2. Toggle pipeline stages (segmentation, enhancement, camera direction, etc.)
3. Generate clip with auto-numbered naming (e.g., "Project Name — Clip 1")
4. View and arrange clips in **Studio** tab
5. Record voiceover in **EditRoom** with real-time playback sync
6. Store and sync via **Library** tab (Local/iCloud/Backend)

## Project Structure

```
DirectorStudio/
├── App/
│   ├── DirectorStudioApp.swift      # Main entry point
│   └── AppCoordinator.swift          # App-wide state & navigation
├── Features/
│   ├── Prompt/                       # Prompt input & pipeline config
│   │   ├── PromptView.swift
│   │   └── PromptViewModel.swift
│   ├── Studio/                       # Clip grid & preview
│   │   ├── StudioView.swift
│   │   └── ClipCell.swift
│   ├── EditRoom/                     # Voiceover recording
│   │   ├── EditRoomView.swift
│   │   └── EditRoomViewModel.swift
│   └── Library/                      # Storage management
│       ├── LibraryView.swift
│       └── LibraryViewModel.swift
├── Models/
│   ├── Project.swift                 # Project data model
│   ├── GeneratedClip.swift           # Clip with sync status
│   ├── VoiceoverTrack.swift          # Voiceover metadata
│   └── StorageLocation.swift         # Storage backend enum
├── Services/
│   ├── AuthService.swift             # iCloud authentication
│   ├── StorageService.swift          # Local/iCloud/Supabase storage
│   ├── PipelineService.swift         # Stub pipeline (ready for real modules)
│   └── ExportService.swift           # Video export & ShareSheet
└── Utils/
    ├── Telemetry.swift               # Event logging
    └── CrashReporter.swift           # Error reporting (stub)
```

## Build & Run

### Requirements
- Xcode 15+
- Swift 5.9+
- iOS 17+ Simulator or Device

### Build Commands

```bash
# Swift Package Manager (CLI)
swift build

# Run tests
swift test

# For Xcode
open DirectorStudio.xcodeproj
```

### Testing Targets
1. **iPhone 15 Pro** (primary)
2. **iPad Pro**
3. **iPod touch (7th gen)**
4. **MacBook Pro** (Mac Catalyst)

## Features

### ✅ Phase 1: App Shell
- [x] Tab navigation (Prompt, Studio, Library)
- [x] AppCoordinator for state management
- [x] SwiftUI-based UI

### ✅ Phase 2: Prompt → Video
- [x] Text prompt input
- [x] Pipeline stage toggles
- [x] Stub PipelineModule protocol
- [x] Auto-numbered clip generation
- [x] Fake video file creation

### ✅ Phase 3: Studio & Voiceover
- [x] Clip grid with thumbnails
- [x] Preview player (stub)
- [x] EditRoom with recording UI
- [x] Waveform visualization
- [x] Playback/recording controls

### ✅ Phase 4: Storage System
- [x] LocalStorageService (FileManager)
- [x] CloudStorageService (iCloud stub)
- [x] SupabaseService (backend stub)
- [x] Segmented storage selector
- [x] Auto-upload toggle

### ✅ Phase 5: Auth & Guest Mode
- [x] iCloud authentication check
- [x] Guest mode UI state
- [x] Button disabling for guests

### ✅ Phase 6: Export
- [x] ExportService with quality options
- [x] ShareSheet integration (iOS)
- [x] Stitched video export

### ✅ Phase 7: Settings & Profile
- [x] Settings panel
- [x] Storage usage display
- [x] Auto-upload preferences

## Pipeline Modules

The app is designed to accept production pipeline modules conforming to `PipelineModule`:

```swift
protocol PipelineModule {
    var id: String { get }
    var version: String { get }
    
    associatedtype Input
    associatedtype Output
    
    func process(_ input: Input) async throws -> Output
}
```

Current stub modules:
- SegmentationModule
- EnhancementModule
- CameraDirectionModule

Real modules can be dropped in without modifying the core app structure.

## Authentication

Users must be signed into iCloud to create content. The app checks `CKContainer.default().accountStatus()` on launch. If not authenticated, the app enters **Guest Mode** where:
- All tabs are visible but interaction is disabled
- A demo video is shown (future feature)

## Storage Behavior

### Local
- Stores clips/voiceovers in `Documents/DirectorStudio/`
- No sync, device-only access

### iCloud
- Uses `NSUbiquitousContainer`
- Auto-upload configurable per user
- Sync status displayed per clip

### Backend (Supabase)
- Stub implementation
- Will connect to `clip_jobs`, `screenplays`, `continuity_logs` tables

## Testing

The app compiles successfully for macOS and iOS. To test:

1. Open project in Xcode
2. Select **iPhone 15 Pro** simulator
3. Build and run (⌘R)
4. Verify:
   - Tab navigation works
   - Prompt input accepts text
   - Pipeline toggles function
   - Generate button creates stub clip
   - Studio displays clip with metadata
   - EditRoom shows recording UI
   - Library segmented control switches views

## Known Issues / Future Work

- [ ] Thumbnail generation for clips
- [ ] Real video player integration
- [ ] Actual voiceover recording (AVAudioRecorder)
- [ ] iCloud sync implementation
- [ ] Supabase backend integration
- [ ] Guest mode demo video
- [ ] Real pipeline module integration
- [ ] Advanced export options (4K, etc.)
- [ ] Onboarding flow

## Protocols Compliance

This app is built according to:
- **b.md**: Engineering protocol (compile-first, git workflow, agent conduct)
- **c.md**: Product specification (phased implementation)

Every build phase results in a working, compilable app.

## License

Proprietary - DirectorStudio 2025

