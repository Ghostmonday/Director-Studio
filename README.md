# DirectorStudio

**Version:** 2.1.1  
**Platform:** iOS 17+, macOS 14+ (via Mac Catalyst)  
**Architecture:** SwiftUI + Dependency-Injected Pipeline with Continuity Engine

---

## Overview

DirectorStudio is a cinematic content creation app that transforms text prompts into video clips with synchronized voiceovers. Users can generate clips, stitch them together, record voiceovers while watching playback, and manage all content through a unified storage system (Local, iCloud, Supabase).

### Production Pipeline

```
Script → Segmentation → Multi-Clip Generation → Stitching → Voiceover → Export
```

**Primary Flow:** Script → Video → Voiceover → Storage

1. Enter text prompt in **Prompt** tab
2. Toggle pipeline stages (segmentation, enhancement, camera direction, etc.)
3. Generate clip with auto-numbered naming (e.g., "Project Name — Clip 1")
4. View and arrange clips in **Studio** tab
5. Record voiceover in **EditRoom** with real-time playback sync
6. Store and sync via **Library** tab (Local/iCloud/Backend)

---

## 🚀 Key Features

### Pipeline Architecture (v2.0+)

- **Dependency Injection**: All services are constructor-injected, making the system fully testable and swappable
- **Video Generation**: Pollo AI integration (OpenAI/Anthropic ready)
- **Text Enhancement**: DeepSeek AI for prompt optimization
- **Continuity Engine**: Automatic visual consistency across clips
- **Storage Backends**: Local, CloudKit, and Supabase support

### Multi-Clip Generation

When "Segmentation" is enabled:
1. Breaks scripts into logical segments
2. Presents each segment for review/editing
3. Generates clips with visual continuity
4. Automatically injects continuity prompts
5. Extracts last frames for next clip reference

---

## 📋 Setup & Configuration

### Requirements

- Xcode 15+
- Swift 5.9+
- iOS 17+ Simulator or Device
- Supabase account with API keys configured

### API Keys Setup

DirectorStudio uses **Supabase** for secure API key management. API keys are fetched from your hosted Supabase instance at runtime.

#### Step 1: Create Supabase Table

Run this SQL in your Supabase SQL editor:

```sql
CREATE TABLE IF NOT EXISTS api_keys (
  service TEXT PRIMARY KEY,
  key TEXT NOT NULL,
  inserted_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anon read" ON api_keys
  FOR SELECT TO anon USING (true);
```

#### Step 2: Insert API Keys

```sql
INSERT INTO api_keys (service, key) VALUES 
  ('Pollo', 'your-pollo-api-key'),
  ('DeepSeek', 'your-deepseek-api-key');
```

#### Step 3: Configure Supabase URL

The Supabase URL is already configured in `SupabaseAPIKeyService.swift`:
- **URL**: `https://carkncjucvtbggqrilwj.supabase.co`
- **Anon Key**: Configured in service file

#### Optional: Local Development Keys

For local testing, create `DirectorStudio/Configuration/Secrets.local.xcconfig`:

```xcconfig
POLLO_API_KEY = your-actual-pollo-api-key-here
POLLO_API_ENDPOINT = https://api.pollo.ai/v1
DEEPSEEK_API_KEY = your-actual-deepseek-api-key-here
DEEPSEEK_API_ENDPOINT = https://api.deepseek.com/v1
```

> **Note:** This file is gitignored and only used for local testing. Production uses Supabase.

### Build Commands

```bash
# Open in Xcode
open DirectorStudio.xcodeproj

# Swift Package Manager (CLI)
swift build

# Run tests
swift test
```

### Testing Targets

- **iPhone 15 Pro** (primary)
- **iPad Pro**
- **iPod touch (7th gen)**
- **MacBook Pro** (Mac Catalyst)

---

## 🎬 Video Generation

### Continuity Implementation

DirectorStudio uses a **single-image continuity approach** for visual consistency across clips:

**Process:**
1. **First clip**: Generated from text prompt only
2. **Subsequent clips**: 
   - Extract last frame from previous video
   - Use that frame as the starting image (`image` parameter) for next clip
   - API continues naturally from that frame with new prompt

**Supported Tiers:**
- Economy (Kling 1.6): Single-image + prompt
- Basic (Pollo 1.6): Single-image + prompt  
- Pro (Kling 2.5 Turbo): Single-image + prompt

All tiers use the same continuity method for consistency. No `imageTail` parameter is used.

### Image Processing

Before sending images to the API, DirectorStudio automatically:

- **Resizes** to 480p (854x480, 16:9 aspect ratio)
- **Compresses** to JPEG at 80% quality (falls back to 60% if >600KB)
- **Encodes** as base64 with data URI prefix
- **Validates** size under 600KB limit

This ensures fast uploads and API compatibility across all tiers.

### Quality Tiers

| Tier | Model | Max Duration | Resolution | Price/Second |
|------|-------|--------------|------------|--------------|
| Economy | Kling 1.6 | 5 seconds | 480p | $0.02/sec |
| Basic | Pollo 1.6 | 10 seconds | 480p | $0.04/sec |
| Pro | Kling 2.5 Turbo | 10 seconds | 720p | $0.08/sec |
| Premium | Runway Gen-4 | 10 seconds | 1080p | User's API key |

> **Premium tier** requires user-provided Runway API key (optional feature)

---

## 🎨 Design System

### Color Scheme

DirectorStudio uses a **professional blue-orange** color scheme:

- **Primary Blue**: `#2563EB` - Professional, trustworthy
- **Secondary Orange**: `#FF6B35` - Warm, inviting
- **Background**: `#191919` - Dark base for reduced eye strain
- **Surface Panel**: `#262626` - Elevated UI elements

All colors are centralized in `DirectorStudioTheme.swift`. **Always use theme tokens, never hardcoded colors.**

### Theme Usage

```swift
// ✅ Correct - Use theme tokens
DirectorStudioTheme.Colors.primary
DirectorStudioTheme.Colors.secondary
DirectorStudioTheme.Colors.blueGradient
DirectorStudioTheme.Colors.backgroundBase

// ❌ Wrong - Hardcoded colors
Color(hex: "4A8FE8")
Color(hex: "FF9E0A")
```

---

## 💰 Monetization

DirectorStudio uses a token-based credit system:

- **Base Rate**: 0.5 tokens per second of video
- **Quality Multipliers**: Basic (1x), Standard (1.5x), Premium (2x), Ultra (3x)
- **Feature Add-ons**: Enhancement (+20%), Continuity (+10%)
- **Transaction Management**: Atomic multi-clip generation with rollback on failure
- **Cost Calculator**: Real-time analysis of customer costs, API costs, and profit margins (available in Settings → Monetization Calculator)

### Credit Enforcement

- Credits are reserved before generation starts
- Failed generations automatically rollback credits
- Multi-clip generations use transactions to ensure atomicity

---

## 📁 Project Structure

```
DirectorStudio/
├── App/
│   ├── DirectorStudioApp.swift      # Main entry point
│   └── AppCoordinator.swift          # App-wide state & navigation
├── Features/
│   ├── Prompt/                       # Prompt input & pipeline config
│   ├── Studio/                       # Clip grid & preview
│   ├── EditRoom/                     # Voiceover recording
│   ├── Library/                      # Storage management
│   └── Settings/                     # Settings and monetization
├── Models/
│   ├── Project.swift                 # Project data model
│   ├── GeneratedClip.swift           # Clip with sync status
│   ├── VoiceoverTrack.swift          # Voiceover metadata
│   ├── StorageLocation.swift         # Storage backend enum
│   └── TokenSystem.swift             # Token calculation and monetization
├── Repositories/
│   └── ClipRepository.swift           # Clip storage and management
├── Transactions/
│   └── GenerationTransaction.swift   # Atomic multi-clip generation
├── Services/
│   ├── PolloAIService.swift          # Pollo AI video generation
│   ├── DeepSeekAIService.swift       # DeepSeek prompt enhancement
│   ├── ContinuityManager.swift       # Visual continuity analysis
│   ├── VideoStitchingService.swift   # AVFoundation video stitching
│   ├── CreditsManager.swift          # Token-based credit system
│   ├── SupabaseAPIKeyService.swift  # Secure API key management
│   └── Monetization/                 # Cost calculation & pricing
└── Utils/
    ├── Telemetry.swift               # Event logging
    └── CrashReporter.swift           # Error reporting
```

---

## 🔌 Architecture

### Pipeline Modules

The app uses a protocol-based architecture for maximum flexibility:

```swift
protocol VideoGenerationProtocol {
    func generateVideo(prompt: String, duration: TimeInterval) async throws -> URL
    func generateVideoFromImage(imageData: Data, prompt: String, duration: TimeInterval) async throws -> URL
}

protocol TextEnhancementProtocol {
    func enhancePrompt(prompt: String) async throws -> String
}

protocol ContinuityManagerProtocol {
    func analyzeContinuity(prompt: String, isFirstClip: Bool, referenceImage: Data?) -> ContinuityAnalysis
    func injectContinuity(prompt: String, analysis: ContinuityAnalysis, referenceImage: Data?) -> String
}

protocol VideoStitchingProtocol {
    func stitchClips(_ clips: [GeneratedClip], withTransitions: TransitionStyle, outputQuality: ExportQuality) async throws -> URL
}

protocol VoiceoverGenerationProtocol {
    func generateVoiceover(script: String, style: VoiceoverStyle) async throws -> VoiceoverTrack
    func mixAudioWithVideo(voiceover: VoiceoverTrack, videoURL: URL, outputQuality: ExportQuality) async throws -> URL
}
```

### Current Implementations

- **PolloAIService**: Video generation via Pollo AI API
- **DeepSeekAIService**: Advanced prompt enhancement
- **ContinuityManager**: Visual consistency analysis & injection
- **VideoStitchingService**: AVFoundation-based video stitching
- **VoiceoverGenerationService**: AI TTS and audio mixing
- **CloudKitStorageService**: Full iCloud sync implementation

---

## 🔐 Authentication & Storage

### Authentication

Users must be signed into iCloud to create content. The app checks `CKContainer.default().accountStatus()` on launch. If not authenticated, the app enters **Guest Mode** where:
- All tabs are visible but interaction is disabled
- A demo video is shown (future feature)

### Storage Options

**Local:**
- Stores clips/voiceovers in `Documents/DirectorStudio/`
- No sync, device-only access

**iCloud:**
- Uses `NSUbiquitousContainer`
- Auto-upload configurable per user
- Sync status displayed per clip

**Backend (Supabase):**
- API key management via Supabase (`api_keys` table)
- Secure key retrieval for Pollo AI, DeepSeek, and other services
- Keys cached in-memory for performance
- See **Setup & Configuration** section above for database setup

---

## ✅ Feature Status

### Completed Features

- ✅ Tab navigation (Prompt, Studio, Library)
- ✅ AppCoordinator for state management
- ✅ SwiftUI-based UI
- ✅ Text prompt input with pipeline stage toggles
- ✅ Auto-numbered clip generation
- ✅ Clip grid with thumbnails
- ✅ EditRoom with recording UI and waveform visualization
- ✅ LocalStorageService (FileManager)
- ✅ CloudKitStorageService (iCloud sync)
- ✅ ExportService with quality options
- ✅ Token-based credit system
- ✅ Real-time cost calculation
- ✅ Monetization calculator (Settings → Monetization Calculator)
- ✅ Real pipeline module integration with dependency injection
- ✅ Advanced video stitching with transitions
- ✅ Frame extraction for continuity

### Future Work

- [ ] Thumbnail generation for clips
- [ ] Real video player integration
- [ ] Actual voiceover recording (AVAudioRecorder)
- [ ] Guest mode demo video
- [ ] Advanced export options (4K, etc.)
- [ ] Onboarding flow
- [ ] Segmented prompts UI (design complete, needs implementation)
- [ ] Real AI TTS integration
- [ ] Automated SwiftLint/SwiftFormat in CI/CD pipeline

---

## 🧪 Testing

The app compiles successfully for macOS and iOS. To test:

1. Open project in Xcode
2. Select **iPhone 15 Pro** simulator
3. Build and run (⌘R)
4. Verify:
   - Tab navigation works
   - Prompt input accepts text
   - Pipeline toggles function
   - Generate button creates clip
   - Studio displays clip with metadata
   - EditRoom shows recording UI
   - Library segmented control switches views

---

## 📝 Code Quality

### Status

- ✅ **Build Status**: Build successful (xcodebuild clean build completed)
- ✅ **Linter Errors**: Zero errors found via Xcode linter
- ✅ **Code Style**: Consistent formatting maintained
- ✅ **Import Ordering**: Properly structured imports
- ✅ **SwiftLint**: Configuration created (`.swiftlint.yml`)
- ✅ **SwiftFormat**: Configuration created (`.swiftformat`)

### Validation

- Project builds successfully for iOS Simulator (iPhone 16, arm64)
- Zero linter errors via Xcode's built-in static analysis
- Consistent code style and formatting maintained
- All Swift files properly structured with correct import ordering
- No deprecated API calls detected
- Comprehensive error handling for API calls (HTTP 400/401/404)

### Next Steps for Full Automation

1. Install SwiftLint: `brew install swiftlint`
2. Install SwiftFormat: `brew install swiftformat`
3. Run: `swiftlint autocorrect` and `swiftformat .`
4. Configure test target in Xcode project if unit tests are needed
5. Integrate into CI/CD pipeline for automated checks

---

## 📚 Version History

### v2.1.1 (October 30, 2025) - Repository Cleanup

- Removed 33+ documentation markdown files (kept README.md only)
- Removed debug/test scripts and temporary files
- Consolidated all important information into README.md
- Updated continuity documentation (single-image approach)
- Fixed hardcoded colors (all use theme tokens now)

### v2.1 (October 29, 2025) - Monetization & Code Quality

- **Monetization Calculator**: Comprehensive cost analysis tool (Settings → Monetization Calculator)
  - Real-time calculation of customer-facing tokens, real API costs, and profit margins
  - Support for single videos and multi-clip films
  - Configurable quality tiers, features, and upstream costs
- **Token-Based Credit System**: Fixed "insufficient credits" bug with accurate token calculations
- **Improved API Error Handling**: Detailed, user-friendly error messages for HTTP 400/401/404
- **AI Duration Selection**: Automated duration strategy set as default
- **Code Cleanup**: Removed 30+ unused markdown files, improved documentation
- **Build Tools**: Added SwiftLint and SwiftFormat configuration files

### v2.0 - Pipeline Architecture

- Dependency injection, multi-clip generation, video stitching, CloudKit storage, continuity engine
- Image Reference Feature: Generate promotional videos from screenshots with cinematic camera movements

---

## 📄 License

Proprietary - DirectorStudio 2025

---

## 🤝 Contributing

This project follows a phased implementation approach where every build phase results in a working, compilable app. All code must:
- Compile without errors
- Follow SwiftLint/SwiftFormat guidelines
- Use theme tokens instead of hardcoded values
- Include proper error handling
- Maintain consistency with existing architecture

---
