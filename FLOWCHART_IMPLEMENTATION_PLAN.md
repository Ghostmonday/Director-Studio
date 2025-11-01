# Flowchart Implementation Plan
**Reference:** User-provided flowchart diagram  
**Status:** Aligning codebase with exact flowchart flow

## Flowchart Flow Mapping

### 1. **User Creates Project → Title + Script Input**
**Current Status:** ✅ Implemented  
**Location:** `PromptView.swift`, `AppCoordinator.swift`  
**Implementation:** 
- User enters script in `PromptView`
- Project created via `AppCoordinator.startGeneration(for:)`

---

### 2. **Clerk Auth + Credit Check**
**Current Status:** ⚠️ Partial (iCloud auth instead of Clerk)  
**Location:** `AppCoordinator.swift`, `CreditsManager.swift`  
**Current:** Uses iCloud authentication  
**Required:** 
- [ ] Integrate Clerk SDK for authentication
- [ ] Replace iCloud auth checks with Clerk session
- [ ] Credit check before proceeding to extraction

**Files to Update:**
- `DirectorStudio/Services/AuthService.swift` (create if missing)
- `DirectorStudio/App/AppCoordinator.swift`

---

### 3. **LLM Entity Extraction (DeepSeek) → Characters, Scenes, Props**
**Current Status:** ⚠️ Partial (DeepSeek exists but doesn't extract structured entities)  
**Location:** `DeepSeekAIService.swift`, `SegmentingModule.swift`  
**Current:** `SegmentingModule` segments script but doesn't extract structured entities  
**Required:**
- [ ] Enhance `DeepSeekAIService` to extract:
  - **Characters:** Name, description, relationships
  - **Scenes:** Name, environment type, lighting, mood
  - **Props:** Label, category, visual attributes
- [ ] Store extracted entities in `ProjectPrompt` model
- [ ] Create entity models: `Character`, `Scene`, `Prop`

**Files to Create/Update:**
- `DirectorStudio/Core/Models/Character.swift`
- `DirectorStudio/Core/Models/Scene.swift`
- `DirectorStudio/Core/Models/Prop.swift`
- `DirectorStudio/Services/DeepSeekAIService.swift` (enhance)
- `DirectorStudio/Core/Models/ProjectPrompt.swift` (add entity fields)

---

### 4. **Generate Portraits (Kling Text-to-Image)**
**Current Status:** ❌ Not Implemented  
**Location:** `KlingAIService.swift`  
**Required:**
- [ ] Add text-to-image generation method to `KlingAIService`
- [ ] Generate character portraits from character descriptions
- [ ] Store portraits in asset repository
- [ ] Link portraits to characters in project

**Files to Create/Update:**
- `DirectorStudio/Services/KlingAIService.swift` (add image generation)
- `DirectorStudio/Services/AssetRepository.swift` (create if missing)

---

### 5. **Generate Environments (Kling Text-to-Image)**
**Current Status:** ❌ Not Implemented  
**Location:** `KlingAIService.swift`  
**Required:**
- [ ] Generate scene environment images from scene descriptions
- [ ] Store environments in asset repository
- [ ] Link environments to scenes

**Files to Update:**
- `DirectorStudio/Services/KlingAIService.swift` (add image generation)

---

### 6. **Store in Asset Repository (Local + Supabase)**
**Current Status:** ⚠️ Partial (`ClipRepository` exists but not specifically for assets)  
**Location:** `ClipRepository.swift`  
**Required:**
- [ ] Extend `ClipRepository` or create `AssetRepository` for:
  - Character portraits
  - Scene environments
  - Prop visualizations
- [ ] Support multi-backend storage (Local + Supabase)
- [ ] Implement tagging and search

**Files to Create/Update:**
- `DirectorStudio/Services/AssetRepository.swift`

---

### 7. **Pre-flight Validation + Token Cost Estimate**
**Current Status:** ✅ Partially Implemented  
**Location:** `GenerationOrchestrator.swift`, `CreditsManager.swift`, `ValidationService.swift`  
**Current:** Validation exists but needs enhancement  
**Required:**
- [ ] Calculate total cost including:
  - Entity extraction (5 credits)
  - Portrait generation (10 credits per character)
  - Environment generation (8 credits per scene)
  - Video generation (10-40 credits based on tier)
- [ ] Show cost breakdown before generation
- [ ] Enforce credit check with atomic reservation

**Files to Update:**
- `DirectorStudio/Services/CreditsManager.swift`
- `DirectorStudio/Services/ValidationService.swift`

---

### 8. **Segment Script → Prompt Blocks + Dialogue Extraction**
**Current Status:** ✅ Implemented  
**Location:** `SegmentingModule.swift`  
**Implementation:** Already segments script and extracts dialogue

---

### 9. **Continuity Manager → Inject Last Frame as Seed**
**Current Status:** ⚠️ Partial (continuity exists but doesn't inject last frame as seed)  
**Location:** `ContinuityManager.swift`  
**Current:** Tracks continuity but doesn't extract/inject last frame  
**Required:**
- [ ] Extract last frame from previous clip using `AVAssetImageGenerator`
- [ ] Inject last frame as seed image in video generation
- [ ] Update `KlingAIService.generateVideo()` to accept seed image

**Files to Update:**
- `DirectorStudio/Services/ContinuityManager.swift`
- `DirectorStudio/Services/KlingAIService.swift`
- `DirectorStudio/Services/FrameExtractor.swift` (enhance)

---

### 10. **Batch Clip Generation (Kling Video API)**
**Current Status:** ✅ Implemented  
**Location:** `GenerationOrchestrator.swift`, `KlingAIService.swift`  
**Implementation:** Already handles batch generation with parallel processing

---

### 11. **Supabase Cache Check**
**Current Status:** ⚠️ Partial (cache checking exists but not Supabase-specific)  
**Location:** `ClipCacheManager.swift`, `GenerationOrchestrator.swift`  
**Required:**
- [ ] Implement Supabase cache lookup
- [ ] Store cache keys in Supabase
- [ ] Retrieve cached clips from Supabase storage

**Files to Update:**
- `DirectorStudio/Services/ClipCacheManager.swift`

---

### 12. **Generate Clip (5s Segment + Reference Anchor)**
**Current Status:** ✅ Implemented  
**Location:** `KlingAIService.swift`  
**Note:** Currently generates 5s clips, reference anchor (portrait) needs integration

---

### 13. **Retry or Fallback API**
**Current Status:** ✅ Implemented  
**Location:** `GenerationOrchestrator.swift`  
**Implementation:** Exponential backoff retry logic exists

---

### 14. **Combine Input: Video + Portrait + Last Frame**
**Current Status:** ⚠️ Partial (video generation accepts images but not fully integrated)  
**Location:** `KlingAIService.swift`  
**Required:**
- [ ] Ensure video generation includes:
  - Character portrait as reference
  - Last frame as seed image
  - Scene environment as background reference

**Files to Update:**
- `DirectorStudio/Services/KlingAIService.swift`

---

### 15. **Has Dialogue? → TTS (ElevenLabs) or No Audio**
**Current Status:** ⚠️ Partial (TTS service exists but ElevenLabs not integrated)  
**Location:** `VoiceoverGenerationService.swift`  
**Current:** TTS service placeholder exists  
**Required:**
- [ ] Integrate ElevenLabs API
- [ ] Map character voices to voice profiles
- [ ] Generate TTS only when dialogue detected

**Files to Update:**
- `DirectorStudio/Services/VoiceoverGenerationService.swift` (waiting for API key)

---

### 16. **Audio Track (Optional Music - Pro)**
**Current Status:** ❌ Not Implemented  
**Required:**
- [ ] Add background music mixing (Pro tier only)
- [ ] Music library integration
- [ ] Volume mixing controls

**Files to Create:**
- `DirectorStudio/Services/AudioMixingService.swift`

---

### 17. **Combine Video + Audio (AVFoundation)**
**Current Status:** ✅ Implemented  
**Location:** `VoiceoverGenerationService.swift`, `VideoStitchingService.swift`  
**Implementation:** Already combines video and audio tracks

---

### 18. **Pro Tier? → Watermark + 720p OR Ultra Quality + 1080p**
**Current Status:** ⚠️ Partial (watermark not implemented, quality tiers exist)  
**Location:** `VideoStitchingService.swift`, `ExportService.swift`  
**Required:**
- [ ] Add watermark application for non-Pro users
- [ ] Enforce 720p for free tier, 1080p for Pro
- [ ] Check user tier via `TokenSystem.swift`

**Files to Update:**
- `DirectorStudio/Services/VideoStitchingService.swift`
- `DirectorStudio/Services/ExportService.swift`

---

### 19. **Final Clip + Metadata**
**Current Status:** ✅ Implemented  
**Location:** `GeneratedClip.swift`  
**Implementation:** Metadata tracking exists

---

### 20. **Log Performance (Tokens Used, Duration, Quality)**
**Current Status:** ✅ Implemented  
**Location:** `TelemetryService.swift`, `GenerationMetrics.swift`  
**Implementation:** Metrics tracking exists

---

### 21. **Save to Timeline + Clip Repository + Session History**
**Current Status:** ✅ Implemented  
**Location:** `GenerationOrchestrator.swift`, `ClipRepository.swift`  
**Implementation:** Already saves clips

---

### 22. **Update Interactive Timeline (Drag-Drop, Transitions, Cues)**
**Current Status:** ❌ Not Implemented (Phase 2.3)  
**Required:**
- [ ] Drag-drop clip reordering
- [ ] Transition editor (fade, dissolve, wipe)
- [ ] Real-time preview
- [ ] Timeline UI component

**Files to Create:**
- `DirectorStudio/Features/Studio/InteractiveTimelineView.swift`

---

### 23. **Export Options (Export MP4 / Share Link / Edit Room)**
**Current Status:** ⚠️ Partial  
**Location:** `ExportService.swift`  
**Required:**
- [ ] Export MP4 to Files/Photos
- [ ] Generate shareable link (Supabase)
- [ ] Return to Edit Room for regeneration

**Files to Update:**
- `DirectorStudio/Services/ExportService.swift`

---

## Implementation Priority

### Phase 1: Critical Path (Without API Keys)
1. ✅ Video Player (Phase 1.1) - COMPLETE
2. ⏳ Thumbnail Generation (Phase 1.2)
3. ⏳ Voice-Over Recording (Phase 1.3)
4. ⏳ Enhanced Entity Extraction (DeepSeek)
5. ⏳ Continuity Last-Frame Injection
6. ⏳ Watermark System
7. ⏳ Interactive Timeline (Phase 2.3)

### Phase 2: API Key Dependent
1. ⏳ Portrait/Environment Generation (Kling Text-to-Image)
2. ⏳ ElevenLabs TTS Integration
3. ⏳ Clerk Authentication

### Phase 3: Polish
1. ⏳ Shareable Links
2. ⏳ Export Enhancements
3. ⏳ Audio Mixing (Pro)

---

## Next Steps

1. Complete Phase 1.2 (Thumbnail Generation)
2. Enhance DeepSeek for structured entity extraction
3. Implement continuity last-frame seed injection
4. Add watermark system for free tier
5. Build interactive timeline UI

**Flowchart Alignment:** This document ensures all implementations follow the exact flowchart flow.

