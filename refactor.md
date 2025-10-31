# 🎬 DirectorStudio Clip Generation Flow — Prompt-Driven Architecture

## 🧠 Description

This system processes a user’s full script into a sequence of AI-generated video clips. Each clip is built from one prompt, automatically derived from the story. Dialogue is extracted from the narrative, synthesized via TTS, and layered with sound FX. Each clip is finalized before moving to the next. All data is saved with logs, and retries are gracefully handled. Once all prompts are complete, the user can review, re-record, and export the full film.

---

## 🔁 Mermaid Flowchart

```mermaid
flowchart TD
  A[User enters project title + script] --> B[Extract & Save Prompt List]
  B --> B2[Save Prompts as Project File]
  B2 --> C[Load Project Config - User Settings and API Keys]
  C --> D[Initialize Clip Generation Loop]

  D --> E{More Prompts?}
  E -- Yes --> F[Pull Next Prompt from List]
  F --> G[Generate Video for Prompt]
  G --> H[Log Video Generation Metrics]
  G --> |Failure| G1[Handle Failure (Retry or Switch API)]

  G --> I[Extract Dialogue from Prompt]
  I --> J[Generate TTS Audio]
  J --> K[Log Dialogue Metrics]
  K --> L[Add Environmental Sound FX]
  L --> M[Save Finalized Clip]
  M --> N[Commit Clip to Project Timeline]

  N --> E

  E -- No --> O[Open Editing Room]
  O --> P[User Reviews All Clips]
  P --> Q[Re-record or Adjust Dialogue/Audio]
  Q --> R[User Exports Final Movie]
  R --> S{Choose Export Destination}
  S -- Local --> S1[Save to Device]
  S -- Cloud --> S2[Upload to iCloud or Drive]
  S -- Share --> S3[Generate Share Link]
```

---

## ⚙️ Key Architecture Notes

- **Prompt List = Backbone**
  - Extracted from full script at the beginning
  - Stored per project in a dedicated file (JSON or similar)
  - Enables one-at-a-time controlled generation

- **Retry + Failure Logic**
  - On video failure: retry or switch generation API (e.g. Pollo, Runway)
  - On persistent failure: rollback to previous stable state

- **Dialogue Generation**
  - Derived from narration (NLP pass)
  - Includes both direct quotes and indirect speech (e.g. “he remarked...” → becomes speech)

- **TTS + Sound FX**
  - Dialogue synthesized via TTS engine
  - Background/environmental FX (birds, footsteps, etc.) layered after
  - FX may be inferred from prompt tags or defaults

- **Time-Safe Processing**
  - Timestamps should be logged and respected to avoid API timeout
  - Graceful fallbacks ensure no clip breaks the app

- **Final Clip = Timeline Entry**
  - After video + audio synthesis, clip is saved and committed
  - The process loops to the next prompt, serially

---

## 🛠️ Implementation Directive

This is a full-system architecture. You are to:

- ✅ Implement anything described above that does not yet exist
- 🔄 Reform anything partially implemented or currently in prototype
- ❌ Leave nothing untouched — this system is moving from concept to production

**Focus Areas:**
- Prompt list generation + per-project save/load
- Full clip loop (video → dialogue → FX → save → commit)
- Retry logic & rollback paths
- File timestamping and API timeout avoidance
- “Editing Room” UX logic stub if not yet wired
- Export branching (local/cloud/share)

---

## ✅ Elements That Can Be Left Untouched (For Now)

- **Core project metadata input (title, script)** — if already implemented cleanly as a SwiftUI form and stored with per-project persistence, this can remain untouched
- **Basic file handling (clip save/load)** — any existing local file I/O or clip caching that works without bugs or data loss can be reused
- **Export logic stubs** — the share/export path (local, iCloud, etc.) does not need rework unless currently broken or unreachable from UI

Everything else is either newly required or must be validated against the new pipeline.

---

## 🔧 API Integration Refactor Plan

The **KlingAI API integration** must be cleaned and modularized to support the new sequential prompt pipeline. Key refactor tasks:

- **1. Centralize All API Calls**
  - Create a `KlingAPIClient.swift` (or similar) to isolate:
    - `/v1/video/generate`
    - `/v1/audio/tts`
    - `/v1/video/status`
    - `/v1/audio/status`
    - Error handling and retry logic

- **2. Async Polling with Retry Safety**
  - Ensure polling for status checks is:
    - Background-safe
    - Time-limited (with exponential backoff)
    - Linked to `task_id`

- **3. Prompt-Centric Input Mapping**
  - All API inputs must now be structured around one prompt at a time, pulled from the prompt list
  - No batch submission

- **4. API Response Normalization**
  - Extract all success/failure paths to standard result models (e.g. `VideoGenerationResult`, `TTSResult`)
  - Include:
    - `task_id`
    - `url`
    - `duration`
    - `status_msg`

- **5. Logging + Callback Handling**
  - Log all outbound API attempts and responses
  - If using `callback_url`, ensure endpoint is active and secure
  - Fallback to polling if callback fails

This refactor ensures resilience, traceability, and future-proofing against KlingAI version updates (1.6 → 2.0 → 2.5).
