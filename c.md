# 🏗️ DirectorStudio Agent Build Plan

> **Mission**: Build a future-proof, protocol-compliant video generation app, layer by layer, starting with the skeleton and surrounding architecture. The pipeline will be inserted later.

---

## 📘 Phase 0: Protocol Reference (Read-Only)

You MUST follow this document in every line of code:
**[Directorstudio Protocol Suite](#)** ← insert link to protocol textdoc

Also: use this schema for all Supabase integration:
**[SUPABASE_SCHEMA_FOR_AGENT.md](sandbox:/mnt/data/SUPABASE_SCHEMA_FOR_AGENT.md)**** ← insert link to Supabase schema

---

## 🧱 Phase 1: Project Skeleton & Core Modules

### 1.1 Create Initial Xcode Project
- Name: `DirectorStudio`
- Platform: iOS only (SwiftUI, iOS 17+)
- Include unit tests
- Add empty `Secrets.xcconfig`
- Git init and push as first commit

### 1.2 Setup Project Structure
```
DirectorStudio/
├── AppCore/
├── Features/
├── PipelineHost/
├── DataModels/
├── Storage/
├── UIComponents/
├── Tests/
```
Push commit.

### 1.3 Add Empty Core Files
Create compile-safe stubs in each folder:
- `App.swift`, `Coordinator.swift`
- `PromptInputView.swift`, `ClipPreviewView.swift`
- `PipelineConnector.swift` with `process()` stub
- `PromptJob.swift`, `ClipAsset.swift`
- `LocalDataStore.swift`, `SupabaseSync.swift`
Push commit.

---

## 🧩 Phase 2: Interface & Module Wiring

### 2.1 Define Protocols
- `PipelineModule` (Input, Output, process())
- `ErrorReportable`, `IdentifiableJob`, `VersionedModel`
Push commit.

### 2.2 Setup Placeholder Modules
Inside `PipelineHost/Modules/`, create:
- `SegmentationModule.swift`
- `ContinuityModule.swift`
- `StitchingModule.swift`
Each must conform to `PipelineModule`.
Push commit.

### 2.3 Add Connector API
- `PipelineConnector.swift` must call all modules in order.
- Uses stub logic for now.
Push commit.

---

## 🖼️ Phase 3: UI & Workflow Shell

### 3.1 Build Views
- `PromptInputView` → user types prompt
- `ClipPreviewView` → list of `ClipAsset` thumbnails
Wire navigation using `Coordinator.swift`
Push commit.

### 3.2 Add Mock Data
- Create mock `PromptJob` and preview clips for testing
- UI must compile and run without real pipeline
Push commit.

---

## ☁️ Phase 4: Supabase Wiring

### 4.1 Add Supabase SDK
- Integrate via SwiftPM or Cocoapods
- Configure using values from `Secrets.xcconfig`
Push commit.

### 4.2 Mirror Schema
Use schema from `SUPABASE_SCHEMA_FOR_AGENT.md`
- Create model structs for all tables
- Add CRUD functions to `SupabaseSync.swift`
Push commit.

---

## 🔐 Phase 5: Auth & Credits

### 5.1 Add Auth Flow
- Use Supabase Auth (email or Apple sign-in)
- Gate pipeline access behind login
Push commit.

### 5.2 Add Credit Ledger
- Use `clip_jobs` and `credits_ledger` tables
- Decrement on usage
Push commit.

---

## 🧪 Phase 6: Testing & PR Discipline

- Each stage must build
- Each commit must be pushed
- Each feature must be behind a PR titled:
  `🔧 Feature: [What you built]`
- Each PR must contain:
  - What changed
  - Why
  - How to test it

---

## 🧩 Final Phase: Insert Pipeline
Once skeleton and modules are wired:
> Insert actual `Pipeline.swift` and real logic into the modules.
> Then call pipeline from `PipelineConnector.process()`
Push final commit.

---

**END OF PLAN**

