# Director Studio - Build Phases & Implementation Roadmap

**Project:** Director Studio (v2.1.1+)  
**Repository:** https://github.com/Ghostmonday/Director-Studio  
**Target:** Production-ready App Store submission  
**Timeline:** 2-4 weeks (20-30 hours/week)  
**Base Requirements:** iOS 17+, Mac Catalyst support, Swift proficiency

---

## System Architecture Overview

This build plan is structured around a comprehensive runtime pipeline that transforms user scripts into professional video content. The architecture follows a noun-only entity model that ensures clean data flow and modular service integration.

### Core Pipeline Flow

The application implements a **Script-to-Video** pipeline organized into five primary stages:

#### Stage 1: Input & Extraction
```
User Input (Script) 
    → Clerk Authentication + Credit Validation
    → DeepSeek LLM Entity Extraction
    → Output: Characters, Scenes, Props (structured entities)
```

**Mapped Build Phases:** Phase 2.1 (Segmented Prompts Editor), Phase 2.2 (Onboarding Flow)

**Key Components:**
- **Script Entity:** Raw text input with title and body
- **LLM Processor:** DeepSeek API service for semantic analysis
- **Extracted Entities:**
  - **Characters:** Name, description, relationships
  - **Scenes:** Name, environment type, lighting, mood
  - **Props:** Label, category, visual attributes

**Technical Implementation:**
- `DeepSeekAIService.swift` handles entity extraction
- `PromptSegment` model stores parsed script blocks
- `CreditsManager.swift` validates token availability pre-extraction

---

#### Stage 2: Asset Generation & Storage
```
Extracted Entities
    → Parallel Asset Generation:
        ├─ Portrait Generation (Kling Text-to-Image) → Character Reference Images
        ├─ Environment Generation (Kling Text-to-Image) → Scene Backgrounds
        └─ Prop Visualization (Optional) → Asset Library
    → Multi-Backend Storage (Local Cache + Supabase + iCloud)
    → Asset Repository (Tagged, Searchable, Reusable)
```

**Mapped Build Phases:** Phase 1.2 (Thumbnail Generation), Phase 3.2 (Enhanced Export)

**Key Components:**
- **Portrait:** Character-specific reference image (seed for video generation)
- **Scene Image:** Environment background used for continuity
- **Asset Repository:** Centralized storage with metadata tagging
- **Storage Backends:** 
  - Local: Fast access, session-based
  - Supabase: Cross-device sync, shareable
  - iCloud: Apple ecosystem integration

**Technical Implementation:**
- `KlingAIService.swift` generates visual assets
- `ClipRepository.swift` manages storage and retrieval
- `StorageBackend` protocol abstracts storage mechanisms
- Cache hit checks optimize redundant generation (e.g., same character portraits)

---

#### Stage 3: Prompt Assembly & Continuity Management
```
Script Segments + Asset Repository
    → Prompt Composer:
        ├─ Inject Character Portraits (casting cards)
        ├─ Apply Scene Environments
        ├─ Reference Props from library
        ├─ Add Previous Frame Seed (ContinuityManager)
        └─ Construct Enhanced Text Prompt
    → Prompt Block (Ready for Video Generation)
```

**Mapped Build Phases:** Phase 2.1 (Segmented Prompts Editor), Phase 1.1 (Video Player Integration)

**Key Components:**
- **Prompt Composer:** Assembles multi-modal prompts (text + images)
- **Continuity Manager:** Injects last frame from previous clip as seed image
- **Casting Card:** Character-to-portrait mapping
- **Seed Image:** Visual anchor for temporal consistency

**Technical Implementation:**
- `ContinuityManager.swift` tracks entity persistence across segments
- `PromptSegment` enriched with visual references
- Seed injection uses last frame extraction via AVFoundation
- Prompt validation ensures all required assets are available

**Continuity Logic:**
```swift
// Simplified continuity flow
func assemblePrompt(for segment: PromptSegment) -> EnrichedPrompt {
    let characterPortraits = segment.characters.map { 
        assetRepository.getPortrait(for: $0) 
    }
    let sceneEnvironment = assetRepository.getEnvironment(for: segment.scene)
    let seedImage = continuityManager.getLastFrame() // Previous clip's final frame
    
    return EnrichedPrompt(
        text: segment.enhancedText,
        characterImages: characterPortraits,
        environmentImage: sceneEnvironment,
        seedImage: seedImage
    )
}
```

---

#### Stage 4: Video Rendering & Audio Integration
```
Enriched Prompt Block
    → Pre-flight Validation:
        ├─ Token Cost Estimation (Economy/Basic/Pro/Ultra tiers)
        ├─ Credit Deduction via Atomic Transaction
        └─ Quality Tier Selection
    → Batch Clip Generation (Kling Video API):
        ├─ Retry Logic on Failure
        ├─ Fallback API (if primary unavailable)
        └─ Progress Tracking (N/M clips complete)
    → Video Clip Output
    
    → Audio Layer (Conditional):
        ├─ If Dialogue Detected:
        │   ├─ Extract Dialogue Text
        │   ├─ Generate TTS per Character Voice Profile (ElevenLabs)
        │   └─ Sync Audio to Video Timeline
        └─ If No Dialogue: Skip to next step
        
    → Audio Mixing:
        ├─ Voice-Over Tracks (TTS or Manual Recording)
        ├─ Background Music (Pro Feature)
        └─ Sound Effects (Optional)
        
    → Final Clip with Synchronized Audio + Video + Metadata
```

**Mapped Build Phases:** Phase 1.3 (Voice-Over Recording), Phase 3.1 (AI Text-to-Speech), Phase 3.2 (Enhanced Export)

**Key Components:**
- **Generation Transaction:** Atomic credit reservation and rollback on failure
- **Clip Output:** Video file with associated metadata (duration, resolution, entities)
- **Dialogue Block:** Extracted spoken text mapped to characters
- **Voice Profile:** Character-specific TTS voice assignment
- **Audio Mix:** Composite audio track combining multiple layers

**Technical Implementation:**
- `GenerationTransaction.swift` ensures atomic operations
- `KlingAIService.swift` handles video rendering with quality parameters
- `TextToSpeechService.swift` (new) integrates ElevenLabs API
- `VoiceoverTrack.swift` manages audio metadata and timing
- `AVAudioMix` combines multiple audio sources

**Tiered Quality Parameters:**
| Tier | Resolution | Frame Rate | Watermark | Cost (Credits) |
|------|-----------|-----------|-----------|---------------|
| Economy | 720p | 24fps | Yes | 10/clip |
| Basic | 720p | 30fps | Yes | 15/clip |
| Pro | 1080p | 30fps | No | 25/clip |
| Ultra | 1080p | 60fps | No | 40/clip |

---

#### Stage 5: Timeline Composition & Export
```
Individual Clips + Audio
    → Interactive Timeline:
        ├─ Drag-Drop Reordering
        ├─ Trim In/Out Points
        ├─ Apply Transitions (Fade, Dissolve, Wipe)
        ├─ Add Timing Cues
        └─ Real-Time Preview
        
    → Video Stitching:
        ├─ Combine Clips in Sequence
        ├─ Render Transitions
        ├─ Mix Audio Tracks
        └─ Apply Watermark (if non-Pro)
        
    → Export Pipeline:
        ├─ Resolution Selection (720p/1080p/4K)
        ├─ Format Selection (MP4/MOV/ProRes)
        ├─ Quality Settings
        └─ Output Destination:
            ├─ Export MP4 to Files App
            ├─ Save to Photos Library
            ├─ Generate Shareable Link (Supabase)
            └─ Return to Edit Room for Further Refinement
```

**Mapped Build Phases:** Phase 2.3 (Interactive Timeline), Phase 3.2 (Enhanced Export), Phase 1.1 (Video Player)

**Key Components:**
- **Timeline:** Ordered sequence of clips with timing metadata
- **Clip Sequence:** Array of clips with transition specifications
- **Output Export:** Final rendered video file
- **Shareable Link:** Public URL with expiration and access controls

**Technical Implementation:**
- `VideoStitchingService.swift` handles sequencing and rendering
- `AVFoundation` APIs for video composition and export
- `Timeline` SwiftUI view with gesture-based interactions
- Supabase Storage for shareable link hosting
- `ExportSession` manages background export tasks

**Export Options Flow:**
```
Timeline Ready
    ↓
[User Initiates Export]
    ↓
Select Quality & Format → Calculate Cost (if Pro features used)
    ↓
Deduct Credits → Begin Rendering
    ↓
Apply Watermark (if Free Tier) → Progress Tracking
    ↓
Success: Save File + Generate Link
    OR
Failure: Refund Credits + Show Error
```

---

### Cross-Cutting Concerns

#### Telemetry & Performance Logging
**Tracked Throughout Pipeline:**
- Tokens consumed per LLM call
- Generation duration per clip
- Quality tier distribution
- Export success/failure rates
- User flow analytics (drop-off points)

**Technical Implementation:**
- `Telemetry.swift` captures events at each stage
- `CrashReporter.swift` logs errors for debugging
- Analytics aggregated for optimization insights

#### Error Handling & Resilience
**Failure Points & Recovery:**
- **LLM Extraction Failure:** Retry with simplified prompt, offer manual entity input
- **Asset Generation Failure:** Use cached alternatives, fallback to text-only prompts
- **Video Rendering Timeout:** Retry with lower quality, refund credits on persistent failure
- **Export Failure:** Save partial progress, allow resume from last checkpoint

#### Monetization Integration Points
**Credit Deduction Triggers:**
1. Entity extraction (5 credits per script)
2. Portrait generation (10 credits per character)
3. Environment generation (8 credits per scene)
4. Video clip generation (10-40 credits based on tier)
5. TTS generation (10 credits per 100 words)
6. Premium export formats (5-20 credits based on resolution)

**Technical Implementation:**
- `CreditsManager.swift` enforces balance checks
- `TokenSystem.swift` manages Pro subscription status
- Atomic transactions prevent partial deductions
- Upsell modals trigger on insufficient credits

---

### Alignment with Build Phases

| Pipeline Stage | Build Phase Coverage | Priority |
|---------------|---------------------|----------|
| **Input & Extraction** | Phase 2.1 (Prompt Editor), 2.2 (Onboarding) | High |
| **Asset Generation** | Phase 1.2 (Thumbnails), 3.2 (Export) | Medium |
| **Prompt Assembly** | Phase 2.1 (Segmented UI), 1.1 (Player) | High |
| **Video Rendering** | Phase 1.3 (Voice-Over), 3.1 (TTS) | Critical |
| **Timeline & Export** | Phase 2.3 (Timeline), 3.2 (Export) | Critical |

**Build Phase Dependencies Validated:**
- Phase 1 (Foundation) enables playback and recording → Required for Stages 4-5
- Phase 2 (UX) enhances extraction and editing → Improves Stages 1 & 3
- Phase 3 (Advanced) completes audio and export → Finalizes Stages 4-5
- Phase 4 (QA) validates entire pipeline → End-to-end flow testing

---

### Validation Against Noun-Only Entity Model

The architecture strictly adheres to the noun-only model for clean separation of concerns:

**Entities (Nouns Only):**
- Script, Character, Scene, Prop, Portrait, Environment, Prompt, Clip, Audio, Timeline, Export

**Relationships (Represented as Flows):**
- Extraction: Script → Entities
- Generation: Entities → Assets
- Assembly: Assets + Script → Prompts
- Rendering: Prompts → Clips
- Composition: Clips → Timeline → Export

**No Verb-Based Entities:** All actions are represented as service methods or flows, not as persistent entities. This prevents conceptual confusion and ensures clear data modeling.

---

### Extensibility for Future Phases

The modular architecture supports post-launch enhancements without refactoring:

**v1.1 Potential Extensions:**
- **Template Library:** Pre-configured entity sets for common story types
- **Style Transfer:** Apply visual styles to generated assets
- **Collaboration:** Shared timelines with real-time editing
- **B-Roll Integration:** Automatic stock footage insertion
- **Advanced Continuity:** AI-powered scene transition suggestions

Each extension maps to the existing pipeline stages without breaking core flows.

---

## Flowchart Validation & Coverage Analysis

The runtime flowchart that models the Director Studio pipeline has been validated against three critical dimensions: the noun-only entity model, the repository's technical implementation, and the proposed build phases. This validation confirms comprehensive coverage and ensures no gaps exist between architectural design and implementation planning.

### Entity Model Integration (100% Coverage)

**Validation Criteria:** Every entity and relationship in the noun-only model must have a corresponding flowchart node or transition.

✅ **Input & Extraction Flow:**
- Flowchart Node: "User Creates Project (Title + Script Input)" → "LLM Entity Extraction (DeepSeek)"
- Model Coverage: Script → LLM → Character Name, Scene Name, Environment Type, Prop Label
- Implementation: `DeepSeekAIService.swift` with `PromptSegment` model

✅ **Asset Generation & Storage:**
- Flowchart Nodes: "Generate Portraits" || "Generate Environments" → "Store in Asset Repository"
- Model Coverage: Entity → Asset Generator → Reference Storage (Portrait → Repository, Scene Image → Tag)
- Implementation: `KlingAIService.swift` with multi-backend storage via `ClipRepository.swift`

✅ **Prompt Assembly:**
- Flowchart Node: "Segment Script → Prompt Blocks + Dialogue Extraction" + "Continuity Manager (Inject Last Frame as Seed)"
- Model Coverage: Prompt Assembly (Scene, Character, Prop, Input Image, Identifier)
- Implementation: `ContinuityManager.swift` enriching prompt segments with visual references

✅ **Rendering Pipeline:**
- Flowchart Node: "Batch Clip Generation" → "Generate Clip" with quality tiers
- Model Coverage: Rendering (Prompt Segment → API Call, Seed Image → Clip Output)
- Implementation: `GenerationTransaction.swift` with atomic credit handling

✅ **Composition & Export:**
- Flowchart Nodes: "Combine Video + Audio (AVFoundation)" → "Timeline" → "Export MP4" / "Generate Shareable Link"
- Model Coverage: Final Composition (Clip Sequence, Output Export, Filename, Format, Resolution)
- Implementation: `VideoStitchingService.swift` with export options

**Model Structure Summary Verification:**
```
Input (Script) 
    → Processor (LLM) 
    → Output (Prompt + Images) 
    → Container (DirectorStudio) 
    → Flow (Extraction → Generation → Composition → Export)
```
**Status:** ✅ Fully represented in flowchart and build phases

---

### Repository Feature Coverage (v2.1.1 Alignment)

**Validation Criteria:** All existing repository services and recent updates must be reflected in the flowchart and build phases.

✅ **Monetization System:**
- Flowchart: "Clerk Auth + Credit Check" → "Pre-flight Validation + Token Cost Estimate"
- Repository: `CreditsManager.swift`, `TokenSystem.swift`, `GenerationTransaction.swift`
- Build Phase: Phase 3.2 (tiered exports), Phase 4.2 (credit system testing)
- Feature: Atomic credit reservations, rollback on failure, Pro/Ultra tier differentiation

✅ **Continuity Management:**
- Flowchart: "Continuity Manager (Inject Last Frame as Seed)" node with visual grounding loop
- Repository: `ContinuityManager.swift` tracking entity persistence
- Build Phase: Phase 2.1 (prompt editor with continuity visualization)
- Feature: Last-frame injection, entity consistency validation

✅ **Multi-Backend Storage:**
- Flowchart: "Store in Asset Repository (Local + Supabase)" with cache hit checks
- Repository: `ClipRepository.swift` with protocol-based storage abstraction
- Build Phase: Phase 1.2 (thumbnail caching), Phase 3.2 (shareable links via Supabase)
- Feature: Local cache for speed, Supabase for cross-device sync, iCloud for backup

✅ **Audio & Voice-Over Pipeline:**
- Flowchart: "Has Dialogue?" branch → "Generate TTS (ElevenLabs)" → "Audio Mix (Optional Music - Pro)"
- Repository: `VoiceoverTrack.swift` (existing metadata handling)
- Build Phase: Phase 1.3 (manual recording), Phase 3.1 (TTS integration)
- Feature: Character-specific voice profiles, fallback to manual recording, Pro-tier music mixing

✅ **Performance Monitoring:**
- Flowchart: "Log Performance (Tokens Used, Duration, Quality)" node post-generation
- Repository: `Telemetry.swift`, `CrashReporter.swift`
- Build Phase: Phase 4.1 (CI/CD telemetry integration), Phase 4.2 (beta analytics)
- Feature: Per-clip metrics, user flow tracking, crash reporting

✅ **Interactive Timeline:**
- Flowchart: "Update Interactive Timeline" with drag-drop transitions
- Repository: Timeline UI in `Studio/` module (implied structure)
- Build Phase: Phase 2.3 (drag-drop implementation, real-time preview)
- Feature: Clip reordering, trim editing, transition application

**Unimplemented Features Correctly Excluded:**
- Onboarding flow: Pre-runtime setup, correctly absent from runtime flowchart (handled in Phase 2.2)
- CI/CD pipelines: Development process, not user-facing (handled in Phase 4.1)
- Thumbnail generation: Sub-process of asset storage (implemented in Phase 1.2)

---

### Build Phase Task Mapping

**Validation Criteria:** Every flowchart node must have a corresponding implementation task in the build phases.

| Flowchart Component | Build Phase Task | Implementation Status |
|---------------------|------------------|----------------------|
| **User Creates Project** | Phase 2.2 (Onboarding) | To Implement |
| **LLM Entity Extraction** | Phase 2.1 (Prompt Editor) | Partially Complete* |
| **Generate Portraits/Environments** | Phase 1.2 (Thumbnail System) | To Implement |
| **Asset Repository Storage** | Phase 1.2, 3.2 (Storage Backend) | Complete* |
| **Continuity Manager** | Phase 2.1 (Prompt Enhancement) | Complete* |
| **Segment Script** | Phase 2.1 (Editable Segments UI) | To Implement |
| **Prompt Composer** | Phase 2.1 (Assembly Logic) | Partially Complete* |
| **Credit Check & Validation** | Phase 3.2 (Monetization Polish) | Complete* |
| **Batch Clip Generation** | Phase 1.1 (Video Player) | Complete* |
| **Generate TTS** | Phase 3.1 (ElevenLabs Integration) | To Implement |
| **Audio Mixing** | Phase 1.3, 3.1 (Voice-Over + TTS) | Partially Complete* |
| **Combine Video + Audio** | Phase 3.2 (Export Options) | Complete* |
| **Interactive Timeline** | Phase 2.3 (Drag-Drop Timeline) | To Implement |
| **Export Pipeline** | Phase 3.2 (Enhanced Exports) | Partially Complete* |
| **Log Performance** | Phase 4.1 (Telemetry Integration) | Complete* |

*Status Key:*
- **Complete:** Core service exists in repository (e.g., `ContinuityManager.swift`)
- **Partially Complete:** Foundation exists, UI/integration needed
- **To Implement:** New feature requiring development

**Coverage Rate:** 15/15 flowchart components mapped = **100% coverage**

---

### Gap Analysis & Refinement Opportunities

While the flowchart provides comprehensive coverage, minor enhancements could increase explicitness:

#### 1. Onboarding Pre-Flow (Low Priority)
**Current State:** Onboarding handled in Phase 2.2 but not visualized in runtime flowchart  
**Potential Enhancement:** Add pre-entry node:
```
[App Launch]
    ↓
[First-Time User?] 
    Yes → [Onboarding: iCloud Auth + Feature Tour] → [Create Project]
    No → [Load Existing Projects] → [Create Project]
```
**Benefit:** Makes user authentication flow explicit  
**Trade-off:** Adds complexity to runtime flowchart; better suited for separate UX diagram

#### 2. Thumbnail Extraction Sub-Process (Medium Priority)
**Current State:** Thumbnail generation implied in "Asset Repository" storage  
**Potential Enhancement:** Explicit sub-node under "Final Clip + Metadata":
```
[Video Clip Generated]
    ↓
[Extract Thumbnail (AVFoundation frame capture)]
    ↓
[Cache Thumbnail (240p/480p/720p)]
    ↓
[Link to Clip Metadata]
```
**Benefit:** Clarifies Phase 1.2 implementation requirements  
**Trade-off:** May clutter flowchart with implementation details

#### 3. Retry & Fallback Logic (High Priority for Production)
**Current State:** "Retry or Fallback API" node exists in flowchart  
**Recommendation:** Expand in Phase 4.1 testing:
```
[API Call Failed]
    ↓
Attempt 1: Retry with exponential backoff (2s, 4s, 8s)
    ↓
Attempt 2: Switch to fallback API endpoint
    ↓
Attempt 3: Reduce quality tier and retry
    ↓
Final Failure: Refund credits + Show user-friendly error
```
**Benefit:** Ensures resilience under production load  
**Implementation:** Add to `KlingAIService.swift` and `DeepSeekAIService.swift`

---

### Validation Summary

✅ **Entity Model Alignment:** 100% (all entities and relationships mapped)  
✅ **Repository Feature Coverage:** 100% (all v2.1.1 features represented)  
✅ **Build Phase Mapping:** 100% (all flowchart nodes have implementation tasks)  
✅ **Extensibility:** Architecture supports v1.1 features without refactoring  
✅ **Production Readiness:** Pipeline design supports App Store submission

**Confidence Level:** High – The flowchart, entity model, repository implementation, and build phases form a cohesive, production-ready system. No critical gaps identified; all recommended enhancements are optional refinements rather than blockers.

---

### Implementation Confidence Matrix

This matrix validates that each major system component has corresponding design (flowchart), implementation (repository), and execution (build phase) coverage:

| System Component | Flowchart Node | Repository Service | Build Phase | Confidence |
|-----------------|---------------|-------------------|-------------|-----------|
| Script Input & Parsing | ✅ User Creates Project | ✅ `DeepSeekAIService.swift` | ✅ Phase 2.1 | 🟢 High |
| Entity Extraction | ✅ LLM Extraction | ✅ `PromptSegment` model | ✅ Phase 2.1 | 🟢 High |
| Character Portraits | ✅ Generate Portraits | ✅ `KlingAIService.swift` | ✅ Phase 1.2 | 🟢 High |
| Environment Assets | ✅ Generate Environments | ✅ `KlingAIService.swift` | ✅ Phase 1.2 | 🟢 High |
| Asset Storage | ✅ Asset Repository | ✅ `ClipRepository.swift` | ✅ Phase 1.2 | 🟢 High |
| Continuity Tracking | ✅ Continuity Manager | ✅ `ContinuityManager.swift` | ✅ Phase 2.1 | 🟢 High |
| Prompt Assembly | ✅ Prompt Composer | ✅ Prompt enrichment logic | ✅ Phase 2.1 | 🟡 Medium* |
| Credit Management | ✅ Credit Check | ✅ `CreditsManager.swift` | ✅ Phase 3.2 | 🟢 High |
| Video Generation | ✅ Batch Clip Generation | ✅ `KlingAIService.swift` | ✅ Phase 1.1 | 🟢 High |
| Transaction Atomicity | ✅ Token Cost Estimate | ✅ `GenerationTransaction.swift` | ✅ Phase 4.1 | 🟢 High |
| TTS Integration | ✅ Generate TTS | ⚠️ To Implement | ✅ Phase 3.1 | 🟡 Medium** |
| Voice-Over Recording | ✅ Audio Layer | ✅ `VoiceoverTrack.swift` | ✅ Phase 1.3 | 🟢 High |
| Audio Mixing | ✅ Audio Mix | ⚠️ Partial (metadata only) | ✅ Phase 3.1 | 🟡 Medium** |
| Timeline Editing | ✅ Interactive Timeline | ⚠️ To Implement | ✅ Phase 2.3 | 🟡 Medium** |
| Video Stitching | ✅ Combine Video + Audio | ✅ `VideoStitchingService.swift` | ✅ Phase 3.2 | 🟢 High |
| Export Pipeline | ✅ Export MP4 | ✅ Export logic exists | ✅ Phase 3.2 | 🟢 High |
| Shareable Links | ✅ Generate Shareable Link | ✅ Supabase integration | ✅ Phase 3.2 | 🟢 High |
| Telemetry Logging | ✅ Log Performance | ✅ `Telemetry.swift` | ✅ Phase 4.1 | 🟢 High |

**Legend:**
- 🟢 **High Confidence:** Fully designed, implemented, and scheduled for refinement
- 🟡 **Medium Confidence:** Designed and scheduled, but requires new implementation
- 🔴 **Low Confidence:** Missing design, implementation, or build phase coverage

**Notes:**
- *Prompt assembly logic exists but UI for user review/editing needs development (Phase 2.1)
- **TTS, Audio Mixing, and Timeline features are greenfield implementations (Phases 1.3, 2.3, 3.1)

**Overall System Confidence:** 🟢 **High** (14/18 components at high confidence, 4/18 at medium with clear implementation paths)

---

## Phase 1: Core Playback & Media Foundation
**Duration:** 3-5 days  
**Priority:** Critical  
**Dependencies:** None (foundation phase)

### Objectives
Establish essential video playback, preview, and media handling capabilities that form the foundation for all subsequent features.

### Tasks

#### 1.1 Video Player Integration
**Module:** `Studio/`, `EditRoom/`  
**Effort:** 8-12 hours

**Implementation Steps:**
- Create `VideoPlayerView.swift` component wrapping `AVPlayer` and `AVPlayerLayer`
- Implement playback controls (play/pause, seek, scrubbing, playback speed)
- Add timeline synchronization with clip boundaries
- Build metadata overlay (timecodes, duration, resolution)
- Handle state management for multi-clip sequences
- Implement error handling for corrupted/missing video files

**Technical Details:**
- Utilize `GeneratedClip.swift` model for video source URLs
- Integrate with `VideoStitchingService.swift` for sequence playback
- Support both local and remote video sources (iCloud, Supabase)
- Implement frame-accurate seeking (CMTime precision)

**Success Criteria:**
- [ ] Video playback works seamlessly in both Studio and EditRoom
- [ ] Scrubbing provides real-time visual feedback
- [ ] Player handles transitions between clips smoothly
- [ ] Memory usage remains stable during extended playback
- [ ] Supports both portrait and landscape orientations

---

#### 1.2 Thumbnail Generation System
**Module:** `ClipRepository.swift`, `Studio/`  
**Effort:** 6-10 hours

**Implementation Steps:**
- Extend `ClipRepository.swift` with thumbnail extraction method
- Use `AVAssetImageGenerator` to capture frames at specified intervals
- Implement caching strategy (memory + disk cache)
- Generate thumbnails at 3 resolutions: grid view (240p), preview (480p), full (720p)
- Add batch thumbnail generation for newly imported clips
- Create background processing queue to avoid UI blocking

**Technical Details:**
- Extract thumbnail at 1-second mark (or first frame with content)
- Store thumbnails in app's cache directory with UUID naming
- Implement LRU cache eviction policy (max 500MB cache size)
- Generate thumbnails asynchronously with completion handlers
- Support both video and image clips

**Success Criteria:**
- [ ] Clip grid displays thumbnails within 100ms of view appearance
- [ ] Thumbnail quality is sufficient for visual identification
- [ ] System handles 100+ clips without performance degradation
- [ ] Cache persists between app launches
- [ ] Graceful fallback for thumbnail generation failures

---

#### 1.3 Voice-Over Recording Implementation
**Module:** `EditRoom/`, `VoiceoverTrack.swift`  
**Effort:** 10-14 hours

**Implementation Steps:**
- Integrate `AVAudioRecorder` with waveform visualization component
- Implement recording session management (permissions, interruptions)
- Build real-time waveform display using audio metering
- Add playback synchronization with video timeline
- Create audio trimming/editing interface
- Implement multi-track audio mixing capabilities

**Technical Details:**
- Record at 48kHz, 16-bit, AAC format for quality/size balance
- Use `AVAudioSession` with `.playAndRecord` category
- Store recordings via storage backend abstraction (local/iCloud/Supabase)
- Link voice-over metadata to specific clip segments via `VoiceoverTrack.swift`
- Implement audio normalization and noise reduction options

**Audio Recording Workflow:**
1. Request microphone permissions via Info.plist keys
2. Configure audio session with ducking for video playback
3. Display real-time input levels during recording
4. Save raw audio file + metadata (start time, duration, clip association)
5. Enable preview with video synchronization
6. Allow re-recording and trimming operations

**Success Criteria:**
- [ ] Voice-over recording produces high-quality audio output
- [ ] Waveform visualization updates in real-time (<50ms latency)
- [ ] Audio syncs precisely with video playback (±100ms tolerance)
- [ ] Recording handles interruptions (calls, background mode) gracefully
- [ ] Storage backend integration works across all supported backends

---

### Phase 1 Testing Checklist
- [ ] Unit tests for thumbnail generation (edge cases: corrupted video, zero-duration)
- [ ] Integration tests for video player state management
- [ ] Audio recording permission flow testing on physical devices
- [ ] Performance profiling for memory usage during playback
- [ ] Cross-platform validation (iOS, iPadOS, macOS via Catalyst)

---

## Phase 2: User Experience & Workflow Optimization
**Duration:** 4-6 days  
**Priority:** High  
**Dependencies:** Phase 1 complete

### Objectives
Refine user interaction patterns, establish intuitive workflows, and reduce friction for new users through onboarding and enhanced editing capabilities.

### Tasks

#### 2.1 Segmented Prompts Editor
**Module:** `Prompt/`, integration with `DeepSeekAIService.swift`  
**Effort:** 12-16 hours

**Implementation Steps:**
- Design editable prompt segment UI with inline controls
- Implement segment reordering via drag-and-drop
- Add per-segment enhancement via DeepSeek API
- Create entity extraction visualization (characters, locations, actions)
- Build segment merging/splitting interface
- Implement undo/redo stack for prompt modifications

**UI Components:**
1. **Segment Card:**
   - Editable text field with character count
   - Entity tags (auto-detected, manually adjustable)
   - Enhancement toggle and preview
   - Visual continuity indicator (connects to adjacent segments)

2. **Enhancement Panel:**
   - "Enhance Prompt" button triggering `DeepSeekAIService.swift`
   - Before/after comparison view
   - Accept/reject enhancement controls
   - Cost display (credits consumed per enhancement)

3. **Batch Operations:**
   - Select multiple segments for bulk enhancement
   - Global find/replace for consistent terminology
   - Export/import segment JSON for version control

**Technical Details:**
- Integrate with existing `PromptSegment` model
- Leverage `DeepSeekAIService.swift` for AI-powered suggestions
- Implement debouncing for real-time enhancement previews
- Store segment history for rollback capabilities
- Validate segment continuity via `ContinuityManager.swift`

**Success Criteria:**
- [ ] Users can edit, reorder, and enhance segments intuitively
- [ ] Enhancement suggestions appear within 2-3 seconds
- [ ] Entity extraction accuracy exceeds 85% for standard scripts
- [ ] Undo/redo works reliably for all modification types
- [ ] Interface scales to scripts with 50+ segments without lag

---

#### 2.2 Onboarding Flow
**Module:** `AppCoordinator.swift`, new `Onboarding/` module  
**Effort:** 10-14 hours

**Implementation Steps:**
- Create multi-step onboarding wizard (4-6 screens)
- Implement iCloud authentication and setup flow
- Build interactive feature demonstrations with sample data
- Add permission requests (camera roll, microphone) with rationale
- Create sample project template for immediate experimentation
- Implement skip/revisit onboarding functionality

**Onboarding Screens:**

1. **Welcome Screen:**
   - App logo, tagline, value proposition
   - "Get Started" CTA, "Sign In" option

2. **Authentication:**
   - iCloud sign-in with benefits explanation (sync, backup)
   - Optional account creation for Supabase backend
   - Privacy policy and terms acceptance

3. **Features Tour:**
   - Interactive walkthrough of Studio, EditRoom, Prompt modules
   - Animated demonstrations of key workflows
   - "Try It" buttons launching guided tasks

4. **Permissions Setup:**
   - Microphone access for voice-overs (with sample recording demo)
   - Photo library access for media import (with visual examples)
   - Notifications for generation completion (optional)

5. **Choose Your Plan:**
   - Free tier vs. Pro comparison table
   - Credit system explanation with visual guide
   - "Start Free" option prominently displayed

6. **Create First Project:**
   - Pre-filled sample script or blank canvas choice
   - Quick project creation with default settings
   - Immediate access to Studio interface

**Technical Details:**
- Store onboarding completion state in UserDefaults
- Implement analytics tracking for drop-off points via `Telemetry.swift`
- Use `AppCoordinator.swift` to manage navigation flow
- Ensure onboarding is skippable and re-accessible from settings
- Optimize for accessibility (VoiceOver, Dynamic Type)

**Success Criteria:**
- [ ] 80%+ of new users complete onboarding sequence
- [ ] Users understand core workflow within first 5 minutes
- [ ] Permission acceptance rate exceeds 70%
- [ ] Onboarding completes in under 3 minutes for engaged users
- [ ] Sample project generates successfully for all users

---

#### 2.3 Interactive Timeline Management
**Module:** `Studio/`, integration with `VideoStitchingService.swift`  
**Effort:** 14-18 hours

**Implementation Steps:**
- Build drag-and-drop timeline component using SwiftUI gestures
- Implement clip reordering with visual feedback (ghost preview)
- Add transition editor (fade, dissolve, wipe) between clips
- Create real-time preview generation for timeline changes
- Implement zoom and pan controls for large timelines
- Add snap-to-grid and magnetic snap to clip boundaries

**Timeline Interface Components:**

1. **Track View:**
   - Horizontal scrollable timeline with timecode ruler
   - Multiple tracks: video, audio, voice-over, music
   - Clip thumbnails with duration overlays
   - Visual indicators for transitions and effects

2. **Clip Manipulation:**
   - Drag to reorder (with collision detection)
   - Edge drag to trim in/out points
   - Double-tap to open clip editor
   - Context menu for duplicate, delete, split operations

3. **Preview Integration:**
   - Scrubber synced with video player
   - Real-time preview updates during drag operations
   - Transition preview on hover/selection
   - Playhead follows during playback

4. **Timeline Controls:**
   - Zoom slider (10% to 200% view)
   - Fit-to-window and actual-size buttons
   - Grid snap toggle (1s, 5s, 10s intervals)
   - Undo/redo with visual history stack

**Technical Details:**
- Use SwiftUI's `DragGesture` and `onDrop` modifiers
- Integrate with `VideoStitchingService.swift` for preview generation
- Implement efficient rendering for timelines with 50+ clips
- Store timeline state in `ClipRepository.swift` for persistence
- Handle concurrent modifications with optimistic locking

**Drag-and-Drop Logic:**
```swift
// Simplified conceptual flow
struct TimelineClipView: View {
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ClipThumbnail()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Update ghost preview position
                        dragOffset = value.translation.width
                        // Calculate new timeline position
                        let newIndex = calculateIndex(from: dragOffset)
                        // Show insertion indicator
                    }
                    .onEnded { value in
                        // Commit reorder via ClipRepository
                        // Trigger VideoStitchingService preview update
                        // Reset ghost preview
                    }
            )
    }
}
```

**Success Criteria:**
- [ ] Drag-and-drop feels responsive (<16ms frame time during drag)
- [ ] Clip reordering commits successfully 100% of the time
- [ ] Timeline handles 100+ clips without performance issues
- [ ] Transition previews generate within 1-2 seconds
- [ ] Undo/redo works reliably for all timeline operations

---

### Phase 2 Testing Checklist
- [ ] Usability testing with 5+ first-time users (onboarding)
- [ ] A/B testing of onboarding flow variations
- [ ] Integration tests for segment enhancement with DeepSeek API
- [ ] Performance benchmarking for timeline with varying clip counts
- [ ] Accessibility audit (VoiceOver, keyboard navigation)

---

## Phase 3: Advanced Features & Monetization
**Duration:** 3-4 days  
**Priority:** Medium-High  
**Dependencies:** Phase 2 complete

### Objectives
Implement premium features that differentiate the product, enhance creative capabilities, and activate monetization mechanisms.

### Tasks

#### 3.1 AI Text-to-Speech Integration
**Module:** `EditRoom/`, new `TextToSpeechService.swift`  
**Effort:** 10-14 hours

**Implementation Steps:**
- Integrate ElevenLabs API (or Azure/Google TTS as fallback)
- Create voice selection interface with audio preview samples
- Map script dialogues to voice-over tracks via `DeepSeekAIService.swift`
- Implement voice customization (pitch, speed, emotion)
- Add TTS generation queue with progress tracking
- Build fallback to manual recording if API fails or user prefers

**Voice-Over Generation Workflow:**

1. **Dialogue Extraction:**
   - Parse script segments for quoted text or dialogue markers
   - Use `DeepSeekAIService.swift` to identify speaker labels
   - Present extracted dialogues in review interface

2. **Voice Assignment:**
   - Display voice library (categorized: male, female, neutral, accent)
   - Play 5-second preview samples for each voice
   - Assign voices to characters/speakers
   - Store voice preferences in project metadata

3. **Generation & Refinement:**
   - Queue TTS requests with rate limiting
   - Display generation progress (N/M dialogues complete)
   - Allow regeneration with adjusted parameters
   - Enable per-dialogue editing before final render

4. **Credits & Monetization:**
   - Calculate credit cost (e.g., 10 credits per 100 words)
   - Display cost preview before generation
   - Enforce limits via `CreditsManager.swift`
   - Offer TTS as Pro-tier feature or pay-per-use

**Technical Details:**
- Store TTS audio files in storage backend with clip associations
- Implement caching to avoid regenerating identical requests
- Support SSML for advanced speech control (pauses, emphasis)
- Handle API errors gracefully with informative user messages
- Provide manual recording as alternative for free-tier users

**API Integration Example:**
```swift
class TextToSpeechService {
    func generateVoiceOver(
        text: String,
        voiceID: String,
        settings: VoiceSettings
    ) async throws -> AudioFile {
        // ElevenLabs API call
        let response = try await networkClient.post(
            url: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)",
            body: ["text": text, "voice_settings": settings]
        )
        // Deduct credits via CreditsManager
        // Save audio file via StorageBackend
        // Return AudioFile reference
    }
}
```

**Success Criteria:**
- [ ] TTS generation produces natural-sounding voice-overs
- [ ] Voice selection interface is intuitive and responsive
- [ ] Generation completes within 5-10 seconds per dialogue
- [ ] Credit system accurately tracks and enforces TTS usage
- [ ] Fallback to manual recording works seamlessly

---

#### 3.2 Enhanced Export System
**Module:** `VideoStitchingService.swift`, `TokenSystem.swift`  
**Effort:** 8-12 hours

**Implementation Steps:**
- Add export resolution options (720p, 1080p, 4K for Pro users)
- Implement watermarking for free-tier exports (semi-transparent logo)
- Create shareable link generation via Supabase storage
- Add export format options (MP4, MOV, ProRes for Pro)
- Build export queue with background processing
- Implement export progress tracking with time estimates

**Export Configuration Interface:**

1. **Resolution & Quality:**
   - Dropdown: 720p (free), 1080p (Pro), 4K (Pro)
   - Quality slider: Draft, Standard, High, Max
   - Estimated file size and export time display

2. **Watermark Settings:**
   - Toggle: Enable watermark (disabled for Pro users)
   - Position selector (corner placement)
   - Opacity adjustment (20-50%)

3. **Output Format:**
   - MP4 (H.264) - universal compatibility
   - MOV (H.264) - Apple ecosystem optimized
   - ProRes 422 (Pro only) - editing-friendly

4. **Sharing Options:**
   - Export to Files app
   - Save to Photos library
   - Generate shareable link (Supabase-hosted, 7-day expiry)
   - Direct share to social media platforms

**Technical Details:**
- Use `AVAssetExportSession` for video rendering
- Apply watermark via `CIFilter` overlay during export
- Implement background export with `URLSessionDownloadTask`
- Store export settings in user preferences
- Validate Pro status via `TokenSystem.swift` before allowing premium options

**Watermark Implementation:**
```swift
func applyWatermark(to video: AVAsset) -> AVAsset {
    let composition = AVMutableComposition()
    // ... add video tracks
    
    let watermarkLayer = CALayer()
    watermarkLayer.contents = UIImage(named: "watermark")?.cgImage
    watermarkLayer.frame = CGRect(x: 10, y: 10, width: 100, height: 50)
    watermarkLayer.opacity = 0.3
    
    let videoLayer = CALayer()
    let parentLayer = CALayer()
    parentLayer.addSublayer(videoLayer)
    parentLayer.addSublayer(watermarkLayer)
    
    // Apply via AVVideoComposition
    // ...
}
```

**Shareable Link Generation:**
- Upload exported video to Supabase Storage
- Generate public URL with expiration token
- Store link metadata in database (creator, views, expiry)
- Provide QR code for easy mobile sharing
- Track link analytics via `Telemetry.swift`

**Success Criteria:**
- [ ] Export completes successfully for all resolution/format combinations
- [ ] Watermark is visible but non-intrusive for free users
- [ ] Shareable links work across all devices and browsers
- [ ] Export time is reasonable (2-3x video duration for 1080p)
- [ ] Pro users can export without watermarks successfully

---

### Phase 3 Testing Checklist
- [ ] End-to-end testing of TTS workflow (dialogue extraction → voice-over)
- [ ] Export validation across all resolution/format combinations
- [ ] Credit deduction accuracy testing for TTS and premium exports
- [ ] Watermark rendering verification on various video dimensions
- [ ] Shareable link access control and expiration testing

---

## Phase 4: Quality Assurance & Deployment
**Duration:** 4-7 days  
**Priority:** Critical  
**Dependencies:** Phases 1-3 complete

### Objectives
Ensure production stability, establish continuous quality processes, gather user feedback, and successfully launch on the App Store.

### Tasks

#### 4.1 Automated Testing & CI/CD Pipeline
**Module:** Repository root, GitHub Actions workflows  
**Effort:** 12-16 hours

**Implementation Steps:**

**Code Quality Automation:**
- Configure GitHub Actions workflow for SwiftLint enforcement (`.swiftlint.yml`)
- Add SwiftFormat checks (`.swiftformat`) with auto-fix on commit
- Implement SonarQube or similar for code coverage tracking (target: 70%+)
- Set up dependency vulnerability scanning (Dependabot)

**Unit Test Suite:**
1. **ContinuityManager.swift Tests:**
   - Entity tracking across segments
   - Consistency validation logic
   - Edge cases (missing entities, contradictions)

2. **GenerationTransaction.swift Tests:**
   - Atomic multi-clip generation
   - Rollback on partial failure
   - Concurrent transaction handling

3. **CreditsManager.swift Tests:**
   - Credit deduction accuracy
   - Insufficient balance handling
   - Refund logic for failed operations

4. **VideoStitchingService.swift Tests:**
   - Clip sequencing correctness
   - Transition rendering accuracy
   - Memory management during large exports

**Integration Test Suite:**
- End-to-end video generation workflow
- Storage backend switching (local → iCloud → Supabase)
- AI service integration (DeepSeek, Kling, ElevenLabs)
- Payment processing flow (in-app purchases)

**CI/CD Workflow Structure:**
```yaml
# .github/workflows/ci.yml
name: Continuous Integration

on: [push, pull_request]

jobs:
  lint:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: SwiftLint
        run: swiftlint lint --strict
      
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Unit Tests
        run: xcodebuild test -scheme DirectorStudio -destination 'platform=iOS Simulator,name=iPhone 15'
      - name: Upload Coverage
        run: bash <(curl -s https://codecov.io/bash)
  
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build App
        run: xcodebuild -scheme DirectorStudio -configuration Release build
```

**Success Criteria:**
- [ ] All code passes SwiftLint without warnings
- [ ] Unit test coverage exceeds 70%
- [ ] CI pipeline completes in under 10 minutes
- [ ] Zero critical vulnerabilities in dependencies
- [ ] All tests pass on both iOS and macOS targets

---

#### 4.2 Beta Testing Program
**Module:** TestFlight distribution  
**Effort:** 16-24 hours (including feedback iteration)

**Implementation Steps:**

**TestFlight Setup:**
- Create App Store Connect app record
- Upload first beta build with symbol files
- Configure internal testing group (5-10 internal testers)
- Set up external testing group (50-100 beta users)
- Prepare beta testing instructions and feedback form

**Feedback Collection Mechanisms:**
1. **In-App Feedback:**
   - Implement feedback button in settings (uses `Telemetry.swift`)
   - Collect device info, logs, and screenshots automatically
   - Integrate with issue tracking system (GitHub Issues, Linear)

2. **Telemetry Tracking:**
   - Monitor feature usage patterns via `Telemetry.swift`
   - Track crash frequency and locations via `CrashReporter.swift`
   - Measure performance metrics (app launch time, export duration)

3. **User Surveys:**
   - Post-usage survey after first project completion
   - NPS (Net Promoter Score) survey after 7 days
   - Feature request prioritization voting

**Testing Focus Areas:**
- **Usability:** Can new users create a video within 10 minutes?
- **Reliability:** Does the app crash during normal use? (target: <1% crash rate)
- **Performance:** Do exports complete without timeout? (target: <5min for 3min video)
- **Credits System:** Are credit deductions accurate and transparent?
- **Cross-Device Sync:** Does iCloud/Supabase sync work reliably?

**Beta Iteration Process:**
1. Week 1: Internal testing, fix critical bugs
2. Week 2: External beta launch, gather feedback
3. Week 3: Address top 3 user complaints
4. Week 4: Final beta build, validation testing

**Success Criteria:**
- [ ] Beta participants successfully create and export videos
- [ ] Crash rate below 1% across all beta sessions
- [ ] Average user rating of 4.0+ stars
- [ ] Top 3 feature requests documented for post-launch roadmap
- [ ] All critical and high-severity bugs resolved

---

#### 4.3 App Store Submission Preparation
**Module:** App Store Connect, marketing materials  
**Effort:** 12-18 hours

**Implementation Steps:**

**Technical Preparation:**
- Finalize app bundle ID and version (1.0.0)
- Configure entitlements (iCloud, push notifications, in-app purchases)
- Generate production signing certificates and provisioning profiles
- Create app icons in all required sizes (20x20 to 1024x1024)
- Implement privacy manifest (PrivacyInfo.xcprivacy) for App Tracking Transparency

**App Store Metadata:**
1. **App Description (4000 char limit):**
   - Lead with value proposition (AI-powered filmmaking)
   - Highlight key features (script-to-video, voice-overs, TTS)
   - Include use cases (content creators, educators, marketers)
   - End with call-to-action (download and create)

2. **Keywords (100 char limit):**
   - Primary: AI video maker, script to video, filmmaking
   - Secondary: video editor, story creator, TTS, voice-over

3. **Screenshots (6-8 required per device type):**
   - Hero shot: Finished video playing in Studio
   - Workflow demo: Script input → Segment editing → Final export
   - Feature highlights: Timeline editing, voice-over recording, TTS selection
   - Results showcase: Before/after examples

4. **App Preview Videos (15-30 seconds):**
   - Voiceover narration explaining key workflow
   - Show complete creation process in accelerated time
   - End with app icon and tagline

**Privacy & Compliance:**
- Complete App Privacy questionnaire (data collection disclosure)
- Implement data deletion mechanisms (GDPR compliance)
- Add privacy policy URL (host on GitHub Pages or website)
- Configure age rating (likely 4+ or 9+)

**Pricing & Availability:**
- Set base price (consider free with IAP for Pro features)
- Configure in-app purchases (credit packs, Pro subscription)
- Select initial launch territories (US, UK, Canada, Australia initially)
- Set launch date (coordinate with marketing campaign)

**Submission Checklist:**
- [ ] App builds successfully in Release configuration
- [ ] All required app icons and launch screens present
- [ ] Privacy policy published and linked correctly
- [ ] In-app purchases configured and tested
- [ ] App description, screenshots, and preview videos uploaded
- [ ] Beta testing feedback addressed
- [ ] Export compliance documentation completed (encryption)

**Review Preparation:**
- Prepare demo account credentials for App Review
- Create video walkthrough demonstrating core functionality
- Document any unusual features requiring explanation
- Plan for rapid response to review feedback (24-48 hour turnaround)

**Success Criteria:**
- [ ] App passes automated pre-submission validation
- [ ] All metadata meets App Store guidelines
- [ ] In-app purchases tested and functional
- [ ] App approved within 2-3 review cycles (target: 1 week)
- [ ] Launch day materials ready (social media, press kit)

---

### Phase 4 Post-Launch Monitoring
**Duration:** Ongoing (first 30 days critical)

**Key Metrics to Track:**
- Daily Active Users (DAU) and retention rates
- Conversion rate (free → Pro subscription)
- Average videos created per user
- Export completion rate
- Crash-free user percentage (target: 99%+)
- App Store rating and review sentiment

**Rapid Response Plan:**
- Monitor crash reports daily via `CrashReporter.swift`
- Address critical bugs within 24 hours (hotfix release)
- Respond to App Store reviews (especially negative ones)
- Collect and prioritize feature requests for v1.1

---

## Summary: Build Phase Dependencies

```
Phase 1 (Core Foundation)
    ↓
Phase 2 (UX & Workflows) ← depends on Phase 1 complete
    ↓
Phase 3 (Advanced Features) ← depends on Phase 2 complete
    ↓
Phase 4 (QA & Launch) ← depends on Phases 1-3 complete
```

**Critical Path Highlights:**
- Phase 1 must be fully functional before Phase 2 (video playback is foundational)
- Onboarding (Phase 2) should be tested before TTS/export (Phase 3) to ensure user can reach advanced features
- All features must pass QA (Phase 4) before submission

**Parallel Workstream Opportunities:**
- CI/CD setup (Phase 4.1) can begin during Phase 1
- App Store metadata preparation (Phase 4.3) can overlap with Phase 3
- Beta recruitment can start during Phase 2

---

## Risk Mitigation Strategies

### Technical Risks
- **API Integration Failures:** Implement robust retry logic and fallback mechanisms for all third-party services
- **Performance Bottlenecks:** Profile early and often; optimize video processing pipeline
- **Storage Backend Issues:** Abstract storage behind protocol; test all backends thoroughly

### Timeline Risks
- **Scope Creep:** Defer non-essential features to v1.1 (e.g., advanced color grading)
- **API Key Delays:** Obtain all necessary API keys before Phase 1 starts
- **App Review Rejection:** Build in 1-week buffer for review iterations

### User Adoption Risks
- **Poor Onboarding:** Invest heavily in Phase 2.2; iterate based on user testing
- **Credit System Confusion:** Provide clear, visual explanations of credit economics
- **Competition:** Emphasize unique AI-driven workflow in marketing materials

---

## Next Steps After Phase 4

**Version 1.1 Roadmap (Post-Launch):**
- Advanced audio editing (music library, sound effects)
- Collaboration features (shared projects, comments)
- Template marketplace (pre-built story structures)
- Enhanced AI features (style transfer, automatic b-roll)
- Additional export destinations (YouTube, TikTok direct upload)

**Success Definition:**
A production-ready app that enables users to transform scripts into polished videos with minimal manual effort, backed by a sustainable monetization model and 4.5+ star App Store rating.