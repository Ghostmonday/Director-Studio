Looking at your codebase, you have **significant working functionality** that would be wasteful to discard. Instead, here's a comprehensive refactor plan that preserves your work while implementing the Phase 1 optimizations:

## 🎯 Recommendation: **REFACTOR, Don't Restart**

You have ~80% of a working app. The issues are organizational, not fundamental.

## 📁 Refactored Folder Structure

```
DirectorStudio/
├── App/
│   ├── DirectorStudioApp.swift
│   ├── AppCoordinator.swift
│   └── AdaptiveContentView.swift
│
├── Core/
│   ├── Models/
│   │   ├── Project.swift
│   │   ├── ProjectPrompt.swift              ⭐ NEW
│   │   ├── GeneratedClip.swift
│   │   ├── GenerationMetrics.swift         ⭐ NEW
│   │   └── StorageLocation.swift
│   │
│   ├── Persistence/
│   │   ├── ProjectFileManager.swift        ⭐ NEW
│   │   ├── ClipRepository.swift
│   │   └── MigrationManager.swift          ⭐ NEW
│   │
│   └── Configuration/
│       ├── MonetizationConfig.swift
│       ├── KlingVersionConfig.swift        ⭐ NEW
│       └── TestingMode.swift
│
├── Services/
│   ├── Generation/
│   │   ├── GenerationOrchestrator.swift    ⭐ REFACTORED
│   │   ├── GenerationStateMachine.swift    ⭐ NEW
│   │   ├── VideoGenerationProvider.swift   ⭐ NEW (Protocol)
│   │   ├── PolloAIService.swift           ✅ KEEP
│   │   ├── RunwayGen4Service.swift        ✅ KEEP
│   │   └── KlingAPIClient.swift           ⭐ EXTRACT from Pollo
│   │
│   ├── Intelligence/
│   │   ├── SegmentingModule.swift         ✅ KEEP & ENHANCE
│   │   ├── ContinuityManager.swift        ✅ KEEP
│   │   ├── DeepSeekAIService.swift       ✅ KEEP
│   │   ├── SmartSuggestions.swift        ✅ KEEP
│   │   └── ComplexityAnalyzer.swift      ⭐ NEW
│   │
│   ├── Processing/
│   │   ├── VideoStitchingService.swift   ✅ KEEP
│   │   ├── FrameExtractor.swift          ✅ KEEP
│   │   ├── ThumbnailCache.swift          ✅ KEEP
│   │   └── ClipReuseAnalyzer.swift       ⭐ NEW
│   │
│   ├── Storage/
│   │   ├── StorageService.swift          ✅ KEEP (Protocol)
│   │   ├── CloudKitStorageService.swift  ✅ KEEP
│   │   ├── LocalStorageService.swift     ⭐ CREATE
│   │   └── SupabaseStorageService.swift  ⭐ FUTURE
│   │
│   └── Monetization/
│       ├── CreditsManager.swift          ✅ KEEP
│       ├── TokenMeteringEngine.swift     ✅ KEEP
│       ├── CostCalculator.swift          ✅ KEEP
│       └── TransactionManager.swift      ⭐ NEW
│
├── Features/
│   ├── Prompt/
│   │   ├── PromptView.swift
│   │   ├── PromptViewModel.swift         ⭐ MAJOR REFACTOR
│   │   └── Components/
│   │       ├── SegmentEditorView.swift
│   │       └── DurationSelectionView.swift
│   │
│   ├── Studio/
│   │   ├── StudioView.swift              ⭐ RENAME from EnhancedStudioView
│   │   ├── StudioViewModel.swift         ⭐ NEW
│   │   └── Components/
│   │       ├── ClipCell.swift
│   │       └── TimelineView.swift        ⭐ NEW
│   │
│   ├── EditRoom/
│   │   ├── EditRoomView.swift
│   │   ├── EditRoomViewModel.swift
│   │   └── VoiceoverRecorder.swift       ⭐ EXTRACT
│   │
│   └── Library/
│       ├── LibraryView.swift
│       ├── LibraryViewModel.swift
│       └── Components/
│           ├── ClipRow.swift
│           └── ClipPreviewSheet.swift
│
└── Shared/
    ├── Theme/
    │   └── DirectorStudioTheme.swift     ✅ KEEP (REMOVE DUPLICATES)
    ├── Components/
    │   ├── LoadingView.swift
    │   ├── ErrorView.swift
    │   └── AnimatedCreditDisplay.swift
    └── Extensions/
        ├── View+Extensions.swift          ⭐ NEW
        └── Error+UserFriendly.swift       ⭐ NEW
```

## 🔧 Module Responsibilities

### 1. **GenerationOrchestrator** (New Central Hub)
```swift
actor GenerationOrchestrator {
    // Manages parallel batch generation
    private let batchSize = DeviceCapabilityManager.shared.recommendedConcurrency
    private let providers: [VideoGenerationProvider]
    private let cache: ClipReuseAnalyzer
    private let metrics: MetricsCollector
    
    func generateProject(_ prompts: [ProjectPrompt]) async throws {
        // Orchestrates the entire pipeline
    }
}
```

### 2. **ProjectFileManager** (New Persistence Layer)
```swift
class ProjectFileManager {
    func savePromptList(_ prompts: [ProjectPrompt], for projectId: UUID) throws
    func loadPromptList(for projectId: UUID) throws -> [ProjectPrompt]
    func updatePromptStatus(_ promptId: UUID, status: GenerationStatus) async
    func migrateLegacyPrompts(_ strings: [String]) -> [ProjectPrompt]
}
```

### 3. **PromptViewModel Refactor**
```swift
// BEFORE: 600+ lines doing everything
// AFTER: Focused on UI state only
@MainActor
class PromptViewModel: ObservableObject {
    @Published var userInput: String = ""
    @Published var segments: [ProjectPrompt] = []
    @Published var isGenerating = false
    
    private let orchestrator: GenerationOrchestrator
    private let segmenter: SegmentingModule
    
    func startGeneration() async {
        // Delegates to orchestrator
        let prompts = segmenter.segment(userInput)
        await orchestrator.generateProject(prompts)
    }
}
```

## ⚠️ Risky/Tightly-Coupled Areas

### 1. **Project.pbxproj Duplicates**
- Multiple entries for same files (e.g., `MultiClipSegment.swift` appears 3 times)
- **Fix**: Clean project file, remove duplicates

### 2. **API Client Coupling**
- PolloAIService contains too much logic
- **Fix**: Extract `KlingAPIClient` for raw API calls, keep service for business logic

### 3. **View-ViewModel Boundaries**
- Some views contain business logic
- **Fix**: Strict MVVM - Views only display, ViewModels handle state

### 4. **Error Handling Inconsistency**
- Mix of throwing, Result types, and completion handlers
- **Fix**: Standardize on async/await + throwing

## 🎭 Clean Separation Guidelines

### Views vs ViewModels
```swift
// ✅ View: Pure UI
struct PromptView: View {
    @StateObject private var viewModel: PromptViewModel
    
    var body: some View {
        // Only UI code, no logic
    }
}

// ✅ ViewModel: State + Coordination
class PromptViewModel: ObservableObject {
    @Published var uiState: PromptUIState
    
    func handleUserAction(_ action: UserAction) {
        // Coordinates with services
    }
}
```

### Services vs State Machines
```swift
// Service: External interactions
protocol VideoGenerationProvider {
    func generate(_ prompt: String) async throws -> URL
}

// State Machine: Internal state transitions
class GenerationStateMachine {
    enum State {
        case idle, generating(Progress), completed(URL), failed(Error)
    }
    
    func transition(from: State, event: Event) -> State
}
```

### Codable vs Runtime Models
```swift
// Codable: For persistence/network
struct ProjectPrompt: Codable {
    let id: UUID
    let prompt: String
    let klingVersion: KlingVersion?
}

// Runtime: For UI/business logic
class GenerationContext {
    let prompt: ProjectPrompt
    var attempts: Int = 0
    var startTime: Date?
    weak var delegate: GenerationDelegate?
}
```

## ✂️ Future Framework Cut Lines

### 1. **DirectorCore** (Foundation Layer)
- Models, Persistence, Configuration
- No UI dependencies
- Could be used by CLI tools

### 2. **DirectorServices** (Business Logic)
- All services and orchestration
- Platform-agnostic
- Could support macOS/tvOS

### 3. **DirectorUI** (Presentation)
- Views, ViewModels, Components
- SwiftUI only
- Could be swapped for UIKit

## 🚀 Implementation Priority

### Week 1: Foundation
1. Create `ProjectPrompt` and `GenerationMetrics` models
2. Implement `ProjectFileManager` with migration
3. Clean up project.pbxproj duplicates
4. Extract `KlingAPIClient` from PolloAIService

### Week 2: Orchestration
1. Build `GenerationOrchestrator` with parallel batching
2. Implement `GenerationStateMachine`
3. Add `ClipReuseAnalyzer` for caching
4. Refactor `PromptViewModel` to delegate

### Week 3: Polish
1. Implement adaptive quality selection
2. Add comprehensive metrics tracking
3. Background task scheduling
4. Error message improvements

## 📋 Specific Cleanup Tasks

1. **Remove duplicates**: 
   - `DirectorStudioTheme.swift` (2 copies)
   - `MultiClipSegment.swift` (3 copies)
   - `MultiClipGenerationView.swift` (2 copies)

2. **Consolidate similar views**:
   - `EnhancedStudioView` + `PolishedStudioView` → `StudioView`
   - `EnhancedLibraryView` + base → `LibraryView`

3. **Fix hardcoded values**:
   - All colors should use `DirectorStudioTheme`
   - API endpoints should be configurable

4. **Standardize naming**:
   - Remove "Enhanced", "Polished" prefixes
   - Use consistent Service/Manager/Provider suffixes

## ✅ Don't Touch These (They Work!)
- CloudKit integration
- Token/credit system core logic
- Video stitching service
- DeepSeek integration
- Export service

## 🎯 Success Metrics
- Build time < 30 seconds
- Zero SwiftLint warnings
- All ViewModels < 200 lines
- 80%+ code coverage on services
- Parallel generation reduces time by 40%

**Bottom line**: Your codebase is solid. It needs organization and the Phase 1 optimizations, not a rewrite. This refactor preserves 90% of your work while achieving all Phase 1 goals.