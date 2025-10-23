# 🎬 DirectorStudio Protocol Suite

## 🧠 FUTURE-SAFE ENGINEERING PROTOCOL

### 1. Decouple or Die
Each module must expose clear `Input`, `Output`, and never rely on internal state of others. Use protocols, not classes.

### 2. Plug, Don't Patch
All features are plug-ins. Never hardcode logic into pipelines. Use `PipelineModule` with `id`, `version`, and `process()`.

### 3. Flatten Dependencies
Favor data structs and stateless logic. Avoid nested object graphs or observer chains. One source of truth per flow.

### 4. Fail Safe, Log Always
All modules must return `.success`, `.failure(reason)`, or `.partial(results)` with context. No silent errors. Always log.

### 5. Nothing is Final
Every major type (asset, job, prompt, config) must be versioned. Support migration. Build as if changes are inevitable.

### 6. Compile Early, Compile Often
Never leave the project in a non-compiling state. Each commit must build standalone with fake data.

### 7. Testing is a Design Tool
Write minimal but real tests. If it's hard to test, it's badly structured. Refactor, then test.

---

## 📛 NAMING CLARITY & PROFESSIONALISM PROTOCOL

### 1. Name for Purpose, Not Implementation
**Good:** `VideoAssembler`, `PromptEnhancer`  
**Bad:** `FastJoiner`, `StringTweaker`

### 2. No Abbreviations, No Cleverness
**Good:** `generatePreviewAsset()`  
**Bad:** `genPrevAst()`

### 3. Structure Names Consistently
- `ModuleName` for types
- `doSomething()` for functions
- `someProperty` for variables
- `TypeName.swift` for files

### 4. Prefix with Context If Needed
**Example:** `ContinuityInput`, `SegmentationInput`

### 5. Make Enums Descriptive
```swift
enum GenerationStatus {
  case notStarted, inProgress, completed, failed(reason: String)
}
```

### 6. Avoid "Manager", "Util", or "Stuff"
Be specific. Instead of `AssetManager`, use `VideoAssetStore`.

---

## 🤖 AGENT CONTINUITY PROTOCOL (CURSOR)

### 1. Own What You Build
Design for your future self. Everything must be understandable and re-usable.

### 2. No Breaks Between Builds
If something's unfinished, stub it safely. Keep the app compiling at all times.

### 3. Single Source of Truth
Centralize types, config, and constants. Avoid duplication.

### 4. Never Introduce Ambiguity
Names must be literal, consistent, and predictable.

### 5. Leave Trails
Use `// MARK:` and minimal comments to document structure, not behavior.

### 6. Follow Protocols
Use required contracts: `PipelineModule`, `Input`, `Output`, etc.

### 7. Validate Each Phase
After each feature, validate the whole build stays clean.

---

## 🔁 GIT FLOW + PULL REQUEST PROTOCOL

### 1. Branch With Purpose
From `main` or `develop`, use clear names:  
`feature/prompt-ui`, `fix/generation-crash`, etc.

### 2. Push Early, Push Clean
Frequent commits with real messages:  
`git commit -m "feat: Add PromptEnhancer"`

### 3. Open PRs for Everything
No raw commits to `main`. Always open PRs with clear titles:  
`📦 Feature: Add AssetStorage`

### 4. Describe Clearly
PRs must explain:
- What changed
- Why
- How to test it

### 5. Link Issues & Tag Agents
Use `Closes #42`, `Relates to #7`, and tag reviewers.

### 6. Self-Review First
All PRs must pass this checklist:
- [ ] Compiles
- [ ] No regressions
- [ ] Matches protocols
- [ ] Testable if needed

### 7. Squash & Merge
Use squash commits for clean history.

### 8. Always Push After Completion
Every time a task, file, or module is finished, even small ones, the agent must push the code to GitHub immediately.

### 9. One PR per Prompt Cycle
Every time a user prompt leads to code generation, it ends in a PR. No exceptions. Even micro-tweaks.

---

## 🚨 CRITICAL AGENT RULES

**MANDATORY COMPLIANCE:**
- Every code change must follow these protocols
- No exceptions for "quick fixes" or "temporary code"
- All modules must implement the full protocol suite
- Validation must pass before any commit
- Documentation must be updated with every change

**FAILURE TO COMPLY = REJECTION**

This document serves as the definitive reference for all DirectorStudio development. Agents must follow these protocols without fail.
