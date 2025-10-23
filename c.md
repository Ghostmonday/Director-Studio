Perfect. Here's the complete, final spec — tailored for a high-level coder or Claude — **with all of your directives integrated**.

**Document Status:** Under Review | **Last Updated:** 2025-10-23

---

# 📦 **DirectorStudio: StorageSync Edition — Full Build Specification (v1.0)**

**Mode:** Compile-First Execution
**Goal:** Script → Video → Voiceover → Synced Output
**Target:** iOS (iPhone, iPad, iPod) + macOS (via Catalyst)
**Agent Note:** Every build phase must result in a compiling app that runs in simulator.

---

## 🧠 **Plain-Language Summary**

DirectorStudio empowers users to generate cinematic content from text-based prompts.
They can stitch together clips, record voiceovers while watching the playback, and manage all their files using a unified Local / iCloud / Supabase system.

Everything they generate is automatically numbered and associated with their project (e.g. "Dante’s Inferno — Clip 1").
They can explore the app in Guest Mode, but only logged-in Apple/iCloud users can create and sync content.

---

## 🧭 **Critical Path Directive**

Build the **Script → Video → Voiceover → Sync** pipeline **first**.
Everything else is secondary.
At every phase:

* Code must compile
* App must launch in simulator (iPhone first, then others)
* Every visual must render with testable dummy data
* Never skip simulator testing to move faster

---

## 🧱 **Architecture Overview**

### 🔨 Phase 1: App Shell + Routing

* `DirectorStudioApp.swift` → main entry point
* `AppCoordinator` or enum-based tab router:
  Tabs:

  1. **Prompt**
  2. **Studio**
  3. **Library**

Compile & launch this immediately — content can be placeholders.

---

### 🧨 Phase 2: Prompt-to-Video Core Flow

#### ✅ Prompt View

* User enters text prompt (e.g. “Dante descends into Inferno”)
* Pipeline is made of toggleable stages (e.g. segmentation → enhancement → camera direction)
* User can switch stages on/off before hitting "Generate Clip"

#### ✅ Generation Stub

* Pressing generate returns a fake video URL after delay
* Filename = Project name + number (e.g. “Dante’s Inferno — Clip 1”)
* Show placeholder thumbnail, sync status = “Not Uploaded”

Compile. Display the clip in Studio tab.

---

### 🎬 Phase 3: Studio (Playback + Stitching)

#### ✅ Video Stitching Grid

* Shows generated clips (in order)
* Allows previewing one by one or all together
* Add “+” button to add another clip (routes to Prompt view)

#### ✅ Editing Room (Voiceover Tool)

* User presses “Record Voiceover”
* Video plays in realtime while mic input is recorded
* Shows waveform, time marker, “cut” button
* User can play back, redo, approve
* Stores voiceover locally
* Optional: timeline UI with thumbnails or waveform for later polish

Compile. Confirm simulator playback and recording UI.

---

### 🔗 Phase 4: StorageSync Panel

#### ✅ Segmented Control

* Local / iCloud / Backend
* Grid view of clips with:

  * Thumbnail
  * Number
  * Sync status dot

#### ✅ Behavior per tab:

* **Local**: Reads from device filesystem (FileManager)
* **iCloud**: Uses Apple ubiquity container
* **Backend**: Connects to Supabase (clip_jobs, screenplays, continuity_logs)

User can toggle whether a file is auto-uploaded to iCloud. Default: **ON**.

---

### 👤 Phase 5: Auth & Guest Mode

#### ✅ iCloud Auth Only

* Users are tied to Apple ID (no custom login flow)
* First-launch: check for iCloud account

#### ✅ Guest Mode

* UI accessible but buttons disabled
* Show only 1 preloaded demo video (e.g. App Store trailer)

---

### 🔧 Phase 6: Export & Share

* Export .mp4 via native ShareSheet
* Toggle for high/low quality export (agent may decide best formats)
* Save locally or share from iCloud

---

### 🧾 Phase 7: Additional Specs

#### 🧠 Profile

* Stored per iCloud account
* Holds current project name, number of clips, voiceovers, etc.

#### 💥 Crash Reporting (Optional)

* If possible, enable crash alert popup → send report
* If not, app must be hardened to avoid crash paths before launch

#### 🧠 Telemetry

* Track clip generation, sync events, voiceover interactions
* Keep lightweight

#### 🧰 Settings Panel

* Auto-upload toggle
* Storage used / available
* Experimental options

#### 🚀 Onboarding

* Defer until core flow is built
* Build based on real UI after internal use

---

## 🗂️ Suggested File Structure

```
/App
  DirectorStudioApp.swift
  AppCoordinator.swift

/Features
  /Prompt
    PromptView.swift
    PromptViewModel.swift
  /Studio
    StudioView.swift
    ClipCell.swift
    StitchingPlayer.swift
  /EditRoom
    EditRoomView.swift
    VoiceoverService.swift
  /Library
    StorageSyncView.swift
    LocalStorageService.swift
    CloudStorageService.swift
    SupabaseService.swift

/Models
  Project.swift
  GeneratedClip.swift
  VoiceoverTrack.swift
  StorageLocation.swift

/Services
  AuthService.swift
  ExportService.swift
  CrashReporter.swift (optional)
```

---

## 📣 Final Notes for Agent

You must:

* Compile every time you add a file
* Test on iPhone simulator (iPhone 15 Pro)
* After base flow is working, test iPad and Mac Catalyst compatibility
* Never allow broken state through — this app will be App Store–featured

If a component is too large to implement now (e.g. Supabase), stub it but maintain compile success.


