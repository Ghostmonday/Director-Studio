# Flowchart Implementation Gap Analysis

## Overview
This document compares the comprehensive flowchart provided with the current codebase implementation to identify gaps and missing features.

## ✅ Implemented Features

| Flowchart Step | Current Implementation | Status |
|----------------|----------------------|--------|
| **Script Input** | `PromptView` with script text field | ✅ |
| **Credit Check** | `CreditsManager.canAffordGeneration()` | ✅ |
| **Pre-flight Validation** | `ValidationService` + `validateGeneration()` | ✅ |
| **Script Segmentation** | `SegmentingModule.segment()` | ✅ |
| **Dialogue Extraction** | `SegmentingModule` extracts dialogue | ✅ |
| **Batch Clip Generation** | `GenerationOrchestrator.generateProject()` | ✅ |
| **Cache Checking** | `ClipCacheManager.retrieve()` | ✅ |
| **Video Generation** | `KlingAPIClient` (native Kling API) | ✅ |
| **Retry Logic** | Exponential backoff in `generateVideoClip()` | ✅ |
| **TTS Generation** | `VoiceoverGenerationService.generateVoiceover()` | ⚠️ Placeholder |
| **Audio Mixing** | `mixVoiceoverWithVideo()` (AVFoundation) | ✅ |
| **Performance Metrics** | `GenerationMetrics` tracking | ✅ |
| **Timeline Storage** | `saveClipToTimeline()` + `ClipRepository` | ✅ |
| **Local Storage** | `ProjectFileManager` + `LocalStorageService` | ✅ |
| **Continuity Management** | `ContinuityManager` exists | ⚠️ Partial |

## ❌ Missing Features

### 1. **Authentication System**
**Flowchart:** Clerk Auth + Credit Check  
**Current:** iCloud-based authentication  
**Gap:** No Clerk integration

**Files to Update:**
- `DirectorStudio/App/AppCoordinator.swift`
- `DirectorStudio/Services/AuthService.swift` (if exists)

**Required Changes:**
- Integrate Clerk SDK
- Replace iCloud auth checks with Clerk auth
- Add Clerk user ID to project metadata

---

### 2. **LLM Entity Extraction**
**Flowchart:** DeepSeek extracts Characters, Scenes, Props  
**Current:** `SegmentingModule` segments but doesn't extract structured entities  
**Gap:** No structured entity extraction (characters, scenes, props)

**Files to Update:**
- `DirectorStudio/Services/SegmentingModule.swift`
- Create: `DirectorStudio/Services/EntityExtractor.swift`

**Required Changes:**
```swift
struct ExtractedEntities {
    let characters: [Character]
    let scenes: [Scene]
    let props: [Prop]
}

protocol EntityExtractorProtocol {
    func extractEntities(from script: String) async throws -> ExtractedEntities
}
```

---

### 3. **Text-to-Image Generation**
**Flowchart:** Parallel generation of Portraits (Kling Text-to-Image) + Environments  
**Current:** No text-to-image generation implemented  
**Gap:** Kling API client only supports video, not images

**Files to Create:**
- `DirectorStudio/Services/ImageGenerationService.swift`
- `DirectorStudio/Services/AssetRepository.swift`

**Required Changes:**
- Integrate Kling Text-to-Image API (or alternative like DALL-E, Midjourney)
- Generate character portraits from extracted entities
- Generate environment backgrounds from scene descriptions
- Store generated assets in `AssetRepository`

**Note:** Kling API may not support text-to-image. Alternatives:
- Stable Diffusion API
- DALL-E 3 API
- Midjourney API (if available)

---

### 4. **Asset Repository**
**Flowchart:** Store in Asset Repository (Local + Supabase)  
**Current:** Assets stored locally only  
**Gap:** No Supabase asset storage, no centralized asset repository

**Files to Create:**
- `DirectorStudio/Services/AssetRepository.swift`
- `DirectorStudio/Services/SupabaseAssetService.swift`

**Required Changes:**
```swift
protocol AssetRepositoryProtocol {
    func storePortrait(_ image: UIImage, for character: String) async throws -> URL
    func storeEnvironment(_ image: UIImage, for scene: String) async throws -> URL
    func retrievePortrait(for character: String) async throws -> URL?
    func retrieveEnvironment(for scene: String) async throws -> URL?
}
```

---

### 5. **Tier-Based Cost Estimation**
**Flowchart:** Token Cost Estimate (Economy/Basic/Pro/Ultra)  
**Current:** `CreditsManager.creditsNeeded()` exists but may not match flowchart tiers  
**Gap:** Need to verify tier mapping matches flowchart

**Files to Check:**
- `DirectorStudio/Services/CreditsManager.swift`
- `DirectorStudio/Services/Monetization/CostCalculator.swift`

**Current Tiers:**
- Economy (v1.6_standard)
- Basic (v2.0_master)
- Pro (v2.5_turbo)
- Ultra/Premium (Runway Gen-4)

**Status:** ✅ Likely implemented, verify pricing matches flowchart

---

### 6. **Continuity with Last Frame Seed**
**Flowchart:** Continuity Manager injects Last Frame as Seed  
**Current:** `ContinuityManager` exists but doesn't extract/inject last frame  
**Gap:** No frame extraction or seed injection for continuity

**Files to Update:**
- `DirectorStudio/Services/ContinuityManager.swift`
- `DirectorStudio/Services/FrameExtractor.swift` (may exist)

**Required Changes:**
```swift
extension ContinuityManager {
    func extractLastFrame(from videoURL: URL) async throws -> Data
    func injectSeedImage(_ imageData: Data, into prompt: ProjectPrompt) -> ProjectPrompt
}
```

---

### 7. **ElevenLabs TTS Integration**
**Flowchart:** Generate TTS (ElevenLabs) Per Character Voice Profile  
**Current:** `VoiceoverGenerationService` uses placeholder TTS  
**Gap:** No ElevenLabs integration, no character voice profiles

**Files to Update:**
- `DirectorStudio/Services/VoiceoverGenerationService.swift`

**Required Changes:**
- Integrate ElevenLabs API
- Create character voice profile system
- Map dialogue lines to character voices
- Generate TTS with character-specific voices

---

### 8. **Watermarking System**
**Flowchart:** Add Watermark + 720p (non-Pro) vs Ultra Quality + No WM + 1080p (Pro)  
**Current:** No watermarking, no tier-based resolution  
**Gap:** Watermarking not implemented, resolution not tier-based

**Files to Create:**
- `DirectorStudio/Services/WatermarkService.swift`
- `DirectorStudio/Services/VideoExportService.swift`

**Required Changes:**
```swift
protocol WatermarkServiceProtocol {
    func addWatermark(to videoURL: URL, tier: VideoQualityTier) async throws -> URL
}

extension VideoExportService {
    func exportVideo(at url: URL, resolution: VideoResolution, watermarked: Bool) async throws -> URL
}

enum VideoResolution {
    case p720  // Non-Pro tiers
    case p1080 // Pro/Ultra tiers
}
```

---

### 9. **Shareable Links**
**Flowchart:** Generate Shareable Link (Supabase + Short ID)  
**Current:** No shareable link generation  
**Gap:** Share functionality not implemented

**Files to Create:**
- `DirectorStudio/Services/ShareService.swift`
- `DirectorStudio/Services/SupabaseShareService.swift`

**Required Changes:**
- Generate short IDs (e.g., using nanoid or similar)
- Store share links in Supabase
- Create public share endpoint/view
- Handle link expiration and access control

---

### 10. **Interactive Timeline**
**Flowchart:** Update Interactive Timeline (Drag-Drop, Transitions, Cues)  
**Current:** Basic timeline display in `StudioView`  
**Gap:** No drag-drop, transitions, or cues

**Files to Update:**
- `DirectorStudio/Features/Studio/EnhancedStudioView.swift`
- `DirectorStudio/Features/Studio/iPadStudioView.swift`

**Required Changes:**
- Implement drag-and-drop for clips
- Add transition editor
- Add cue points for audio sync
- Update timeline UI to be interactive

---

## ⚠️ Partial Implementations

### 1. **Credit System**
- ✅ Basic credit checking exists
- ⚠️ May need Clerk integration for user-specific credits
- ⚠️ Need to verify tier pricing matches flowchart

### 2. **Video Export**
- ✅ Basic export exists (`ExportService`)
- ❌ No tier-based resolution (720p vs 1080p)
- ❌ No watermarking

### 3. **Dialogue Extraction**
- ✅ Basic dialogue extraction in `SegmentingModule`
- ❌ No character voice profile mapping
- ❌ No speaker attribution verification

---

## Implementation Priority

### Phase 1: Core Missing Features (Critical)
1. ✅ **Watermarking System** - Required for monetization
2. ✅ **Tier-Based Resolution** - Required for Pro tier differentiation
3. ✅ **Continuity Last Frame Seed** - Required for smooth transitions
4. ✅ **ElevenLabs TTS Integration** - Required for dialogue audio

### Phase 2: Asset Management (High Priority)
5. ✅ **Entity Extraction** - Required for portrait/environment generation
6. ✅ **Text-to-Image Generation** - Required for assets
7. ✅ **Asset Repository** - Required for asset storage

### Phase 3: Enhanced Features (Medium Priority)
8. ✅ **Clerk Auth Integration** - Replace iCloud auth
9. ✅ **Shareable Links** - User-requested feature
10. ✅ **Interactive Timeline** - UX enhancement

---

## Quick Wins (Easy to Implement)

1. **Watermarking Service** - Can use AVFoundation to overlay watermark
2. **Tier-Based Resolution** - Add resolution parameter to export functions
3. **Shareable Links** - Simple Supabase table + short ID generation
4. **Continuity Last Frame** - Use existing `FrameExtractor` to extract last frame

---

## Complex Features (Require External APIs)

1. **ElevenLabs TTS** - Requires ElevenLabs API key and integration
2. **Text-to-Image** - Requires image generation API (DALL-E, Stable Diffusion, etc.)
3. **Clerk Auth** - Requires Clerk SDK integration

---

## Summary

**Fully Implemented:** ~60%  
**Partially Implemented:** ~20%  
**Missing:** ~20%

The core video generation pipeline is complete, but several enhancement features from the flowchart are missing, particularly:
- Asset generation (portraits/environments)
- Watermarking and tier-based resolution
- ElevenLabs TTS integration
- Shareable links
- Interactive timeline features

Most critical missing piece: **Watermarking + Tier-based resolution** for proper monetization differentiation.

