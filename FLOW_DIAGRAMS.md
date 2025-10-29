# 🎬 DirectorStudio Flow Diagrams

Visual representation of the app's major workflows with issue markers.

---

## 1. App Initialization Flow ✅

```
┌─────────────────────────────────────────────────────────────┐
│ @main DirectorStudioApp                                     │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ init()                                                  │ │
│ │   ├─ SupabaseAPIKeyService.shared.clearCache()        │ │
│ │   └─ testTelemetry() ✅                                │ │
│ └─────────────────────────────────────────────────────────┘ │
│                              ↓                              │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ body: some Scene                                        │ │
│ │   ├─ AdaptiveContentView()                             │ │
│ │   │    └─ .environmentObject(coordinator) ✅           │ │
│ │   └─ .fullScreenCover(showOnboarding) ✅               │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│ AdaptiveContentView                                         │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ TabView(selection: $coordinator.selectedTab)            │ │
│ │   ├─ PromptView()    .tag(.prompt) ✅                   │ │
│ │   ├─ StudioView()    .tag(.studio) ✅                   │ │
│ │   └─ LibraryView()   .tag(.library) ✅                  │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘

STATUS: ✅ All flows work correctly
```

---

## 2. Single Video Generation Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│ PromptView                                                           │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 1. User Input                                                    │ │
│ │    ├─ Types prompt in TextEditor                                │ │
│ │    ├─ Selects duration (5s or 10s)                              │ │
│ │    ├─ Toggles pipeline stages                                   │ │
│ │    └─ Optional: Adds reference image                            │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 2. Confirm Prompt ⚠️ ISSUE #3                                   │ │
│ │    ├─ User taps "Confirm Prompt" button                         │ │
│ │    ├─ isPromptConfirmed = true                                  │ │
│ │    ├─ Cost calculation enabled                                  │ │
│ │    └─ ⚠️ RESETS ON ANY TEXT CHANGE (even 1 char!)              │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 3. Generate Button                                               │ │
│ │    ├─ Validates: !promptText.isEmpty                            │ │
│ │    ├─ Validates: isPromptConfirmed == true                      │ │
│ │    ├─ Validates: sufficient credits                             │ │
│ │    └─ Calls: viewModel.generateClip(coordinator)                │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ PromptViewModel.generateClip()                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 1. Pre-flight Checks                                             │ │
│ │    ├─ Calculate cost: creditsNeeded(duration, stages)           │ │
│ │    ├─ Check credits: canGenerate(cost)                          │ │
│ │    └─ If fails → show InsufficientCreditsOverlay                │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 2. Pipeline Execution                                            │ │
│ │    └─ pipelineService.generateClip(                             │ │
│ │           prompt, clipName, stages, image, duration)            │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ PipelineServiceBridge.generateClip() ⚠️ ISSUE #4                    │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 1. Credit Check (Again) ⚠️                                       │ │
│ │    ├─ Calculate totalCost                                        │ │
│ │    ├─ checkCreditsForGeneration(cost) ✅                         │ │
│ │    └─ ⚠️ Credits NOT deducted yet! (race condition)             │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 2. Service Selection 🔴 ISSUE #1                                │ │
│ │    ├─ videoService = AIServiceFactory.createVideoService()      │ │
│ │    └─ 🔴 Returns RunwayGen4Service                              │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 3. Pipeline Stages                                               │ │
│ │    ├─ [10%] Continuity Analysis (if enabled)                    │ │
│ │    ├─ [20%] Continuity Injection (if enabled)                   │ │
│ │    ├─ [40%] Enhancement ⚠️ Actually skipped now                 │ │
│ │    └─ [60%] Prompt Ready                                         │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 4. Video Generation (30-120 seconds)                             │ │
│ │    ├─ If image: generateVideoFromImage()                        │ │
│ │    └─ If text: generateVideo()                                  │ │
│ │        ├─ [70%] Generating...                                    │ │
│ │        ├─ Poll for completion                                    │ │
│ │        └─ [85%] Video URL received                               │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 5. Download & Save                                               │ │
│ │    ├─ [90%] Downloading video...                                │ │
│ │    ├─ Save to Documents/DirectorStudio/Clips/                   │ │
│ │    ├─ [95%] Create GeneratedClip metadata                       │ │
│ │    └─ storageService.saveClip()                                 │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 6. Credit Deduction ⚠️ ISSUE #4                                 │ │
│ │    ├─ useCredits(totalCost)                                     │ │
│ │    └─ ⚠️ Deducted AFTER generation (race condition window!)     │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 7. Complete                                                      │ │
│ │    ├─ coordinator.addClip(clip)                                 │ │
│ │    ├─ coordinator.navigateTo(.studio)                           │ │
│ │    └─ [100%] Success! ✅                                         │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘

ISSUES FOUND:
🔴 #1: Service confusion (RunwayGen4 vs Pollo)
⚠️  #3: Prompt confirmation resets on text change
⚠️  #4: Credits checked but not reserved (race condition)
```

---

## 3. Multi-Clip Film Generation Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│ PromptView (Multi-Clip Mode)                                         │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 1. User Input                                                    │ │
│ │    ├─ User selects "Film/Series" mode                           │ │
│ │    ├─ Writes complete story/script                              │ │
│ │    ├─ AI will auto-select durations                             │ │
│ │    └─ Pipeline stages auto-enabled:                             │ │
│ │        ├─ Segmentation ✅                                        │ │
│ │        ├─ Continuity Analysis ✅                                 │ │
│ │        └─ Continuity Injection ✅                                │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 2. Generate Button (No confirmation needed)                      │ │
│ │    ├─ scriptForGeneration = viewModel.promptText ⚠️ #6          │ │
│ │    └─ showVideoGenerationScreen = true                          │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ VideoGenerationScreen (Full Screen Cover)                            │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ Receives: initialScript = viewModel.promptText ⚠️ #6            │ │
│ │ ⚠️ scriptForGeneration never actually used!                      │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ Step 1: ANALYZING                                                │ │
│ │ ┌────────────────────────────────────────────────────────────┐  │ │
│ │ │ FilmGeneratorViewModel.analyzeStory(initialScript)         │  │ │
│ │ │   ├─ Fetch DeepSeek API key from Supabase                  │  │ │
│ │ │   ├─ Create StoryToFilmGenerator                           │  │ │
│ │ │   └─ generateFilm(from: text)                              │  │ │
│ │ │       ├─ AI analyzes story structure                       │  │ │
│ │ │       ├─ Breaks into logical takes                         │  │ │
│ │ │       ├─ Generates prompt for each take                    │  │ │
│ │ │       ├─ Estimates duration per take                       │  │ │
│ │ │       └─ Returns FilmBreakdown                             │  │ │
│ │ └────────────────────────────────────────────────────────────┘  │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ Step 2: PREVIEW                                                  │ │
│ │ ┌────────────────────────────────────────────────────────────┐  │ │
│ │ │ TakesPreviewView(film: FilmBreakdown)                      │  │ │
│ │ │   ├─ Shows: Take count, total duration                     │  │ │
│ │ │   ├─ List of all takes with:                               │  │ │
│ │ │   │   ├─ Take number                                       │  │ │
│ │ │   │   ├─ Story content                                     │  │ │
│ │ │   │   ├─ Generated prompt                                  │  │ │
│ │ │   │   └─ Estimated duration                                │  │ │
│ │ │   ├─ Calculate total cost                                  │  │ │
│ │ │   └─ User can:                                             │  │ │
│ │ │       ├─ Review each take                                  │  │ │
│ │ │       ├─ Cancel entire flow                                │  │ │
│ │ │       └─ Confirm and generate                              │  │ │
│ │ └────────────────────────────────────────────────────────────┘  │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ Step 3: GENERATING 🔴 ISSUE #2                                   │ │
│ │ ┌────────────────────────────────────────────────────────────┐  │ │
│ │ │ FilmGeneratorViewModel.generateVideos()                    │  │ │
│ │ │                                                             │  │ │
│ │ │ for (index, take) in film.takes.enumerated() {             │  │ │
│ │ │   currentTakeIndex = index                                 │  │ │
│ │ │   progress = Double(index) / Double(total)                 │  │ │
│ │ │                                                             │  │ │
│ │ │   ┌─────────────────────────────────────────────────────┐  │  │ │
│ │ │   │ Generate Take N                                      │  │  │ │
│ │ │   │ ├─ If index == 0:                                    │  │  │ │
│ │ │   │ │    └─ videoService.generateVideo(text-to-video)   │  │  │ │
│ │ │   │ │       └─ 🔴 Uses PolloAIService (ISSUE #1!)       │  │  │ │
│ │ │   │ ├─ If index > 0:                                     │  │  │ │
│ │ │   │ │    ├─ Requires lastFrame from previous take       │  │  │ │
│ │ │   │ │    └─ videoService.generateVideoFromImage()       │  │  │ │
│ │ │   │ │       └─ 🔴 Uses PolloAIService (ISSUE #1!)       │  │  │ │
│ │ │   │ ├─ Download video to local storage                  │  │  │ │
│ │ │   │ ├─ Create GeneratedClip                             │  │  │ │
│ │ │   │ ├─ generatedClips.append(clip) ⚠️                    │  │  │ │
│ │ │   │ ├─ Extract last frame for next take                 │  │  │ │
│ │ │   │ └─ Save clip to storage                             │  │  │ │
│ │ │   └─────────────────────────────────────────────────────┘  │  │ │
│ │ │                                                             │  │ │
│ │ │   🔴 ISSUE #2: If take fails:                              │  │ │
│ │ │      ├─ error = error                                      │  │ │
│ │ │      ├─ status = "Error on Take X..."                      │  │ │
│ │ │      └─ return  ⚠️                                         │  │ │
│ │ │          └─ Previous clips already appended!               │  │ │
│ │ │          └─ Previous clips already saved!                  │  │ │
│ │ │          └─ No rollback!                                   │  │ │
│ │ │ }                                                           │  │ │
│ │ └────────────────────────────────────────────────────────────┘  │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ Step 4: COMPLETE                                                 │ │
│ │ ┌────────────────────────────────────────────────────────────┐  │ │
│ │ │ CompleteView(clips: generatedClips)                        │  │ │
│ │ │   ├─ Show success message                                  │  │ │
│ │ │   ├─ List all generated clips                              │  │ │
│ │ │   └─ User taps "Done"                                      │  │ │
│ │ │       ├─ Add all clips to coordinator                      │  │ │
│ │ │       ├─ Navigate to Studio tab                            │  │ │
│ │ │       └─ Dismiss VideoGenerationScreen                     │  │ │
│ │ └────────────────────────────────────────────────────────────┘  │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘

ISSUES FOUND:
🔴 #1: Uses PolloAIService directly (should use factory)
🔴 #2: No transaction rollback on failure
⚠️  #6: scriptForGeneration state variable unused
```

---

## 4. Credits Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│ App Launch                                                           │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ CreditsManager.init()                                            │ │
│ │   ├─ loadTokens()                                                │ │
│ │   │   ├─ Check for tokens in UserDefaults                       │ │
│ │   │   └─ If none: Migrate from legacy credits                   │ │
│ │   │       └─ 1 credit = 100 tokens                              │ │
│ │   └─ checkFirstLaunch()                                          │ │
│ │       └─ If new user: Grant 150 free tokens ✅                   │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ Video Generation Flow                                                │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 1. Cost Calculation                                              │ │
│ │    ├─ Duration: 10s                                              │ │
│ │    ├─ Quality: .pro (37 tokens/sec)                              │ │
│ │    ├─ Base cost: 10s × 37 = 370 tokens                           │ │
│ │    ├─ + Enhancement (20%): 444 tokens                            │ │
│ │    └─ + Continuity (10%): 488 tokens total                       │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 2. Pre-flight Check (PromptViewModel)                            │ │
│ │    ├─ canGenerate(cost: 488)                                     │ │
│ │    ├─ If isDevMode: return true ✅                                │ │
│ │    ├─ If credits >= 488: return true ✅                           │ │
│ │    └─ Else: throw InsufficientCreditsError ❌                     │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 3. Pipeline Check (PipelineServiceBridge) ⚠️ DUPLICATE          │ │
│ │    ├─ calculateCost() AGAIN                                      │ │
│ │    ├─ checkCreditsForGeneration() AGAIN                          │ │
│ │    └─ ⚠️ Credits STILL not deducted!                             │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ │                 [30-120 second gap] ⚠️ ISSUE #4                  │ │
│ │                 (Video being generated...)                        │ │
│ │                 (User could start another generation!)            │ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ 4. Credit Deduction (AFTER generation)                           │ │
│ │    ├─ useCredits(amount: 488)                                    │ │
│ │    ├─ tokens -= 488                                              │ │
│ │    ├─ saveTokens() to UserDefaults                               │ │
│ │    └─ Post notification: .creditsDidChange                       │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ Purchase Flow (If low/out of credits)                                │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ InsufficientCreditsOverlay                                       │ │
│ │   ├─ Shows: "Need X tokens, have Y"                             │ │
│ │   └─ Button: "Get Credits" → CreditsPurchaseView                │ │
│ └──────────────────────────────────────────────────────────────────┘ │
│                              ↓                                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ CreditsPurchaseView ⚠️ NOT REAL STOREKIT                         │ │
│ │   ├─ Display token bundles                                       │ │
│ │   │   ├─ 500 tokens - $4.99                                      │ │
│ │   │   ├─ 1000 tokens - $9.99                                     │ │
│ │   │   ├─ 2200 tokens - $19.99 (Save 10%) ⭐                      │ │
│ │   │   └─ 6000 tokens - $49.99 (Save 17%)                         │ │
│ │   └─ User taps purchase                                          │ │
│ │       └─ simulatePurchase() ⚠️                                   │ │
│ │           ├─ Fake 1.5s delay                                     │ │
│ │           └─ addTokens(amount) ⚠️ No actual payment!             │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘

ISSUES FOUND:
⚠️  #4: Credits checked but not reserved (race condition)
⚠️  Duplicate credit checks (ViewModel + Pipeline)
⚠️  StoreKit not implemented (only simulation)
```

---

## 5. Error Handling Flow (Current State)

```
┌──────────────────────────────────────────────────────────────────────┐
│ Error Occurs Anywhere                                                │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ Service Layer (PolloAIService, RunwayGen4Service, etc.)              │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ do {                                                             │ │
│ │     let response = try await client.performRequest(...)          │ │
│ │ } catch let error as APIError {                                  │ │
│ │     logger.error("❌ Error: \(error)")                           │ │
│ │     throw error  // Re-throw                                     │ │
│ │ } catch {                                                        │ │
│ │     throw error  // Re-throw                                     │ │
│ │ }                                                                │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ Pipeline Layer (PipelineServiceBridge)                               │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ do {                                                             │ │
│ │     videoURL = try await videoService.generateVideo(...)         │ │
│ │ } catch {                                                        │ │
│ │     print("❌ Error: \(error)")  // ⚠️ Only print!              │ │
│ │     throw error  // Re-throw                                     │ │
│ │ }                                                                │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ ViewModel Layer (PromptViewModel, FilmGeneratorViewModel)            │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ do {                                                             │ │
│ │     let clip = try await pipelineService.generateClip(...)       │ │
│ │ } catch {                                                        │ │
│ │     generationError = error  // Set error                        │ │
│ │     // ⚠️ NO RECOVERY ATTEMPT                                    │ │
│ │     // ⚠️ NO ROLLBACK                                            │ │
│ │     // ⚠️ NO USER GUIDANCE                                       │ │
│ │ }                                                                │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ View Layer (PromptView, VideoGenerationScreen)                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ .alert("Generation Failed", isPresented: ...) {                  │ │
│ │     Button("OK") {                                               │ │
│ │         viewModel.generationError = nil                          │ │
│ │         // ⚠️ DEAD END - No retry, no recovery!                  │ │
│ │     }                                                            │ │
│ │ } message: {                                                     │ │
│ │     Text(error.localizedDescription)                             │ │
│ │     // ⚠️ Generic error message, not helpful                     │ │
│ │ }                                                                │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘

PROBLEMS:
❌ No error classification (network vs credit vs API)
❌ No recovery strategies
❌ No retry logic
❌ No rollback mechanism
❌ No user guidance on what to do
❌ Credits may be deducted even on failure
❌ Partial state left behind (multi-clip)
```

---

## 6. Suggested Error Handling Flow (Improved)

```
┌──────────────────────────────────────────────────────────────────────┐
│ Error Occurs                                                         │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ ErrorClassifier                                                      │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ classify(error) -> ErrorCategory                                 │ │
│ │   ├─ Network Error (timeout, no connection)                      │ │
│ │   ├─ Credit Error (insufficient funds)                           │ │
│ │   ├─ API Error (503, rate limit, invalid key)                    │ │
│ │   ├─ Validation Error (bad input)                                │ │
│ │   └─ Unknown Error                                               │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ ErrorRecoveryManager                                                 │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ attemptRecovery(error, context) -> RecoveryAction                │ │
│ │                                                                  │ │
│ │ NetworkError:                                                    │ │
│ │   └─ Retry with exponential backoff                             │ │
│ │       ├─ Attempt 1: Wait 1s                                      │ │
│ │       ├─ Attempt 2: Wait 2s                                      │ │
│ │       ├─ Attempt 3: Wait 4s                                      │ │
│ │       └─ Max 3 attempts                                          │ │
│ │                                                                  │ │
│ │ CreditError:                                                     │ │
│ │   └─ Direct user to purchase                                     │ │
│ │       └─ Calculate exact amount needed                           │ │
│ │                                                                  │ │
│ │ APIError:                                                        │ │
│ │   └─ Check service status                                        │ │
│ │       ├─ If temporary: Queue for retry                           │ │
│ │       └─ If permanent: Show error + support link                 │ │
│ │                                                                  │ │
│ │ ValidationError:                                                 │ │
│ │   └─ Show specific field error                                   │ │
│ │       └─ Highlight problematic input                             │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ TransactionManager (for multi-step operations)                       │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ beginTransaction()                                               │ │
│ │   ├─ Reserve credits                                             │ │
│ │   ├─ Create pending clip records                                │ │
│ │   └─ Track all operations                                        │ │
│ │                                                                  │ │
│ │ ... operations ...                                               │ │
│ │                                                                  │ │
│ │ if success:                                                      │ │
│ │   commitTransaction()                                            │ │
│ │     ├─ Deduct reserved credits                                   │ │
│ │     ├─ Finalize clip records                                     │ │
│ │     └─ Clear pending state                                       │ │
│ │ else:                                                            │ │
│ │   rollbackTransaction()                                          │ │
│ │     ├─ Release reserved credits                                  │ │
│ │     ├─ Delete partial clips                                      │ │
│ │     └─ Restore previous state                                    │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
                              ↓
┌──────────────────────────────────────────────────────────────────────┐
│ User Feedback                                                        │
│ ┌──────────────────────────────────────────────────────────────────┐ │
│ │ SmartErrorView(error, recovery)                                  │ │
│ │   ├─ Icon based on error type                                    │ │
│ │   ├─ Clear explanation                                           │ │
│ │   ├─ What went wrong                                             │ │
│ │   ├─ What was rolled back                                        │ │
│ │   └─ Action buttons:                                             │ │
│ │       ├─ Primary: Retry / Fix / Purchase                         │ │
│ │       ├─ Secondary: Change Settings                              │ │
│ │       └─ Tertiary: Contact Support                               │ │
│ └──────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘

IMPROVEMENTS:
✅ Errors classified by type
✅ Automatic recovery where possible
✅ Rollback on failure
✅ User-friendly messages
✅ Actionable next steps
```

---

## 7. Data Flow Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                          DirectorStudioApp                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ @StateObject var coordinator = AppCoordinator()                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
                                   ↓
                    .environmentObject(coordinator)
                                   ↓
┌────────────────────────────────────────────────────────────────────────┐
│                          AdaptiveContentView                           │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ @EnvironmentObject var coordinator: AppCoordinator               │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
        ↓                           ↓                           ↓
  PromptView                   StudioView                 LibraryView
        │                           │                           │
        │                           │                           │
┌───────┴─────────┐      ┌─────────┴──────────┐      ┌─────────┴─────────┐
│ PromptViewModel │      │ (No ViewModel)     │      │ LibraryViewModel  │
│ @StateObject    │      │ Reads directly:    │      │ @StateObject      │
│                 │      │ coordinator.clips  │      │                   │
│ Uses:           │      └────────────────────┘      │ Uses:             │
│ - Pipeline      │                                  │ - Storage Service │
│ - Credits Mgr   │                                  └───────────────────┘
└─────────────────┘

SHARED STATE (AppCoordinator):
┌────────────────────────────────────────────────────────────────────────┐
│ AppCoordinator (ObservableObject)                                     │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ @Published var selectedTab: AppTab                               │  │
│  │ @Published var currentProject: Project?                          │  │
│  │ @Published var generatedClips: [GeneratedClip] ⚠️ Unbounded     │  │
│  │ @Published var isAuthenticated: Bool                             │  │
│  │                                                                  │  │
│  │ let authService: AuthService                                     │  │
│  │ let storageService: StorageServiceProtocol                       │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘

SINGLETON STATE (CreditsManager):
┌────────────────────────────────────────────────────────────────────────┐
│ CreditsManager.shared (ObservableObject)                              │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ @Published var tokens: Int                                       │  │
│  │ @Published var selectedQuality: VideoQualityTier                 │  │
│  │ @Published var isLoadingCredits: Bool                            │  │
│  │                                                                  │  │
│  │ Persistence: UserDefaults                                        │  │
│  │   - "user_tokens"                                                │  │
│  │   - "selected_video_quality"                                     │  │
│  │   - "free_credit_granted"                                        │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘

FILE SYSTEM STATE:
┌────────────────────────────────────────────────────────────────────────┐
│ Documents/DirectorStudio/                                             │
│  ├─ Clips/                                                            │
│  │  ├─ {uuid}.json  (GeneratedClip metadata)                         │
│  │  └─ ... ⚠️ But actual videos stored at top level!                 │
│  ├─ Voiceovers/                                                       │
│  │  └─ {uuid}.json  (VoiceoverTrack metadata)                        │
│  └─ Clip_{name}_{timestamp}.mp4  ⚠️ Should be in Clips/ !            │
└────────────────────────────────────────────────────────────────────────┘

DATA FLOW ISSUES:
⚠️  generatedClips array grows unbounded in memory
⚠️  Video files not organized in same directory as metadata
⚠️  No orphan cleanup if metadata/video mismatched
⚠️  No pagination or lazy loading
```

---

## Summary of Critical Flow Issues

| Issue # | Severity | Component | Description |
|---------|----------|-----------|-------------|
| #1 | 🔴 Critical | Video Services | Dual service confusion - PolloAIService vs RunwayGen4Service |
| #2 | 🔴 Critical | Multi-Clip Gen | No rollback on failure - partial films left behind |
| #3 | ⚠️ High | PromptView | Confirmation resets on any text change |
| #4 | 🔴 Critical | Credits | Race condition - credits checked but not reserved |
| #5 | 🔴 Critical | Studio/Library | No validation if video files still exist |
| #6 | ⚠️ Medium | VideoGenScreen | Unused state variable scriptForGeneration |
| #7 | ⚠️ High | DevMode | Inconsistent bypass - still makes real API calls |

**Total Critical Issues**: 4  
**Total High Priority**: 2  
**Total Medium Priority**: 1

---

## Next Steps

1. **Immediate Fixes** (Critical Issues):
   - Standardize video service usage
   - Add transaction rollback for multi-clip
   - Implement credit reservation system
   - Add file existence validation

2. **Architecture Improvements**:
   - Implement error recovery manager
   - Add transaction pattern for multi-step ops
   - Improve state management
   - Add proper monitoring/analytics

3. **Technical Debt**:
   - Implement real StoreKit integration
   - Add proper iCloud sync
   - Improve file organization
   - Add pagination for clips

---

**Generated**: October 29, 2025  
**Tool**: AI Codebase Flow Validator

