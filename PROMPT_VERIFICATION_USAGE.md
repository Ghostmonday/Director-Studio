# PromptVerificationService - Usage Guide

## Overview

`PromptVerificationService` uses DeepSeek AI to verify continuity, dialogue logic, and prompt consistency across a sequence of prompts before video generation.

## Features

- ✅ **Dialogue Continuity**: Checks for consistent character names and speaker attribution
- ✅ **Logical Flow**: Verifies smooth scene transitions and narrative coherence
- ✅ **Visual Continuity**: Ensures descriptions match between adjacent prompts
- ✅ **Story Coherence**: Identifies plot holes and contradictions
- ✅ **Speaker Identity**: Validates consistent character speaking patterns

## Basic Usage

```swift
import Foundation

// Get the shared service instance
let verificationService = PromptVerificationService.shared

// Your prompts
let prompts = [
    "A cinematic shot of a hero standing on a cliff",
    "The hero looks down at the valley below",
    "A character says 'This is dangerous'",  // Note: character name missing
    "The hero turns around and walks away"
]

// Verify the prompts
Task {
    do {
        let results = try await verificationService.verify(prompts: prompts)
        
        // Check if any blocking issues found
        let hasBlockingIssues = results.contains { $0.isBlocking }
        
        if hasBlockingIssues {
            print("⚠️ Blocking issues found - fix before generation")
            for result in results where result.isBlocking {
                print("Prompt \(result.index): \(result.issues.joined(separator: ", "))")
            }
        } else if !results.isEmpty {
            print("💡 Warnings found - review before generation")
            for result in results {
                print("Prompt \(result.index): \(result.issues.joined(separator: ", "))")
            }
        } else {
            print("✅ All prompts verified successfully")
        }
    } catch {
        print("❌ Verification failed: \(error.localizedDescription)")
    }
}
```

## Quick Verification                                                                                                                                                                                                                                                                                                                                                                                                                                         ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss 
                                                                                                                                                              s                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
For simple pass/fail checks:

```swift
let isValid = try await verificationService.verifyQuick(prompts: prompts)
if isValid {
    // Proceed with generation
} else {
    // Show user that issues need to be fixed
}
```

## Get Summary

For displaying user-friendly summaries:

```swift
let summary = try await verificationService.getVerificationSummary(prompts: prompts)
print(summary)
// Output: "✅ All prompts verified successfully - no issues found"
// or: "⚠️ Verification found 3 issue(s) (1 blocking) (2 warnings)"
```

## Integration with Generation Flow

```swift
// In your generation orchestrator
public func generateProject(_ projectId: UUID, prompts: [ProjectPrompt]) async throws {
    // 1. Verify prompts before generation
    let promptTexts = prompts.map { $0.prompt }
    let verificationResults = try await PromptVerificationService.shared.verify(prompts: promptTexts)
    
    // 2. Check for blocking issues
    let blockingIssues = verificationResults.filter { $0.isBlocking }
    if !blockingIssues.isEmpty {
        throw GenerationError.verificationFailed(blockingIssues)
    }
    
    // 3. Log warnings (non-blocking)
    let warnings = verificationResults.filter { !$0.isBlocking }
    if !warnings.isEmpty {
        logger.warning("⚠️ \(warnings.count) verification warnings found")
        // Could show user-friendly warnings in UI
    }
    
    // 4. Proceed with generation
    // ... rest of generation logic
}
```

## Response Format

The service returns an array of `VerificationResult`:

```swift
struct VerificationResult {
    let id: UUID           // Unique identifier
    let index: Int         // 1-based prompt number
    let issues: [String]   // Array of specific issues found
    let isBlocking: Bool   // true = prevents generation, false = warning
}
```

### Example Response

```json
[
  {
    "index": 3,
    "issues": [
      "Dialogue line has no speaker attribution",
      "Scene transition from cliff to valley is abrupt"
    ],
    "isBlocking": true
  },
  {
    "index": 4,
    "issues": [
      "Hero's position unclear - was walking away from cliff or valley?"
    ],
    "isBlocking": false
  }
]
```

## Error Handling

The service throws `VerificationError`:

```swift
enum VerificationError {
    case apiError(String)      // DeepSeek API failure
    case parsingError(String)  // JSON parsing failure
    case invalidResponse       // Unexpected response format
}
```

### Example Error Handling

```swift
do {
    let results = try await verificationService.verify(prompts: prompts)
    // Process results
} catch VerificationError.apiError(let message) {
    // Handle API errors (network, auth, etc.)
    showError("Verification service unavailable: \(message)")
} catch VerificationError.parsingError(let message) {
    // Handle parsing errors
    logger.error("Failed to parse verification response: \(message)")
    // Could fallback to manual verification or skip
} catch {
    // Handle other errors
    showError("Unexpected error: \(error.localizedDescription)")
}
```

## Performance

- **Latency**: ~500-2000ms depending on prompt count and complexity
- **Cost**: Uses DeepSeek API (check current pricing)
- **Caching**: Consider caching results for identical prompt sequences

## Best Practices

1. **Verify Before Generation**: Always verify prompts before starting expensive generation
2. **Show Warnings**: Display non-blocking warnings to users but allow override
3. **Block on Critical Issues**: Prevent generation if blocking issues found
4. **Batch Verification**: Verify all prompts at once for better context analysis
5. **User Feedback**: Show verification results clearly with actionable fixes

## Integration Points

- **SegmentingModule**: Verify after segmentation, before generation
- **GenerationOrchestrator**: Verify in pre-flight validation step
- **PromptViewModel**: Verify as user edits prompts (debounced)
- **AppCoordinator**: Verify before starting generation flow

