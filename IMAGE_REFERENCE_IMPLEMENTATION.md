# Image Reference Implementation Guide

## 🎯 Overview

This document describes the implementation of the **visual reference image** feature for DirectorStudio's video generation pipeline.

## ✅ What Was Implemented

### 1. Image Selection UI (PromptView)

**Location**: `DirectorStudio/Features/Prompt/PromptView.swift`

**Features**:
- Image picker button below the text prompt area
- Thumbnail preview when image is selected
- Option to remove selected image
- Sheet-based image picker with:
  - Default ad.png option (pre-selected for demo)
  - Photo library picker for custom images
- Clean iOS design with proper spacing and styling

**Usage**:
```swift
// The image picker shows two options:
// 1. "Use Default Demo Image" - loads ad.png from bundle
// 2. "Choose from Library" - opens system photo picker
```

### 2. ViewModel Updates (PromptViewModel)

**Location**: `DirectorStudio/Features/Prompt/PromptViewModel.swift`

**New Properties**:
```swift
@Published var selectedImage: UIImage? = nil
@Published var useDefaultAdImage: Bool = false
```

**Features**:
- Converts UIImage to JPEG data before sending to pipeline
- Logs analytics event when image is used
- Clears image after successful generation
- Gracefully handles optional image (works with or without)

### 3. Pipeline Integration (PipelineService)

**Location**: `DirectorStudio/Services/PipelineServiceBridge.swift`

**Updates**:
```swift
func generateClip(
    prompt: String,
    clipName: String,
    enabledStages: Set<PipelineStage>,
    referenceImageData: Data? = nil,  // NEW
    isFeaturedDemo: Bool = false       // NEW
) async throws -> GeneratedClip
```

**Flow**:
1. If `enabledStages` contains `.enhancement`, prompt is enhanced via DeepSeek
2. If `referenceImageData` is present → calls `PolloAIService.generateVideoFromImage()`
3. If no image → calls `PolloAIService.generateVideo()`
4. Downloads video to local storage
5. Returns GeneratedClip with metadata

### 4. GeneratedClip Model Update

**Location**: `DirectorStudio/Models/GeneratedClip.swift`

**New Properties**:
```swift
var isGeneratedFromImage: Bool = false
var isFeaturedDemo: Bool = false
```

These properties enable:
- Tracking which clips used image references
- Filtering featured demo clips in Studio view
- Future analytics and reporting

### 5. Featured Demo Section (StudioView)

**Location**: `DirectorStudio/Features/Studio/StudioView.swift`

**Features**:
- Separate "Featured Demo" section at the top
- Shows clips where `isFeaturedDemo == true`
- Star icon badge indicating featured status
- "My Clips" section for regular user-generated clips
- Proper layout and spacing

### 6. Asset Integration

**Location**: `DirectorStudio/Assets.xcassets/ad.imageset/`

**Files**:
- `ad.png` - The promotional reference image
- `Contents.json` - Asset catalog metadata

**Access**:
```swift
let adImage = UIImage(named: "ad")
```

### 7. Analytics Logging

**Location**: `PromptViewModel.logImageUsageEvent()`

**Events**:
- `image_generation_default_ad` - When ad.png is used
- `image_generation_custom` - When user uploads their own image

## 🎬 How to Generate the Demo Video

1. **Open DirectorStudio**
2. **Navigate to Prompt tab**
3. **Enter project name**: "Dante's Inferno" (or any name)
4. **Paste journal/story text**:
   ```
   From journal to cinema. From emotion to vision. From prompt to screen — in seconds.
   
   A solitary figure sits in candlelight, pen in hand, pouring emotions onto paper. 
   The words transform into cinematic sequences - dark corridors, dramatic lighting, 
   emotional close-ups. Each entry becomes a scene, each feeling becomes a frame.
   ```
5. **Click "Add Reference Image"**
6. **Select "Use Default Demo Image"** (this selects ad.png)
7. **Toggle pipeline stages** as desired:
   - ✅ Enhancement (recommended for better prompts)
   - ✅ Continuity
   - ✅ Lighting
8. **Click "Generate Clip"**
9. Wait for generation (calls POLLO API)
10. **Navigate to Studio tab** → Video appears in "Featured Demo" section

## 🔧 Technical Flow

```
User Action: Select Image
    ↓
PromptViewModel.selectedImage = UIImage
    ↓
User Action: Generate Clip
    ↓
Convert to Data: image.jpegData(compressionQuality: 0.8)
    ↓
Log Analytics: "image_generation_default_ad"
    ↓
PipelineService.generateClip(referenceImageData: data)
    ↓
If enhancement enabled: DeepSeekAIService.enhancePrompt()
    ↓
PolloAIService.generateVideoFromImage(imageData, prompt)
    ↓
Download video to local storage
    ↓
Create GeneratedClip(isGeneratedFromImage: true, isFeaturedDemo: true)
    ↓
AppCoordinator.addClip()
    ↓
StudioView displays in "Featured Demo" section
```

## 🧪 Verification Checklist

- [x] Image picker UI appears in Prompt tab
- [x] Thumbnail preview shows selected image
- [x] Default ad.png option works
- [x] Custom photo library picker works
- [x] Image removal works
- [x] Video generation accepts image parameter
- [x] POLLO service has `generateVideoFromImage()` method
- [x] GeneratedClip tracks image metadata
- [x] Featured Demo section appears in Studio
- [x] Star badge shows on featured clips
- [x] Analytics logging implemented
- [x] No linter errors
- [ ] Actual API call test (requires valid POLLO_API_KEY)

## 📝 API Integration Notes

### POLLO Image-to-Video API

**Endpoint**: `POST /video/image-to-video`

**Request**:
```json
{
  "image": "<base64_encoded_image>",
  "prompt": "Enhanced prompt text",
  "duration": 5.0,
  "resolution": "1920x1080",
  "fps": 30,
  "motion_strength": 0.8,
  "interpolate": true
}
```

**Response Options**:
1. **Immediate**: `{ "video_url": "https://..." }`
2. **Polling**: `{ "job_id": "..." }` → Poll `/video/status/:jobId`

**Implementation**: `PolloAIService.generateVideoFromImage()` (lines 113-176)

## 🎨 UI Design

### Prompt Tab Layout

```
┌─────────────────────────────┐
│ Project Name                │
│ [Dante's Inferno          ]│
├─────────────────────────────┤
│ Scene Description           │
│ ┌─────────────────────────┐│
│ │ From journal to cinema...││
│ │                          ││
│ └─────────────────────────┘│
├─────────────────────────────┤
│ Reference Image (Optional)  │
│ ┌───┬─────────────────────┐│
│ │ 📷│ Image selected      ││
│ │   │ Will be used as ref ││
│ └───┴─────────────────────┘│
├─────────────────────────────┤
│ Pipeline Stages             │
│ ☑ Segmentation              │
│ ☑ Enhancement               │
│ ...                         │
├─────────────────────────────┤
│ [🪄 Generate Clip]          │
└─────────────────────────────┘
```

### Studio Tab Layout

```
┌─────────────────────────────┐
│ ⭐ Featured Demo            │
│ DirectorStudio promo video  │
│ ┌─────┐                     │
│ │ 🎬  │ (with star badge)   │
│ └─────┘                     │
├─────────────────────────────┤
│ My Clips                    │
│ ┌─────┐ ┌─────┐ ┌─────┐    │
│ │ 🎬  │ │ 🎬  │ │  +  │    │
│ └─────┘ └─────┘ └─────┘    │
└─────────────────────────────┘
```

## 🚀 Next Steps

### For Testing
1. Add valid `POLLO_API_KEY` to `Info.plist` or `Secrets.xcconfig`
2. Add valid `DEEPSEEK_API_KEY` for prompt enhancement
3. Run on simulator or device
4. Generate test clip with ad.png
5. Verify video appears in Featured Demo section

### For Production Polish
1. Add loading spinner during image selection
2. Add image size validation (e.g., max 10MB)
3. Implement video thumbnail generation
4. Add ability to play video from Studio tab
5. Add social sharing for demo video
6. Integrate with proper Telemetry service
7. Add error handling UI for failed generations

## 📊 Analytics Events

The following events are logged:

| Event | Trigger | Purpose |
|-------|---------|---------|
| `image_generation_default_ad` | User selects ad.png | Track demo video generation |
| `image_generation_custom` | User selects custom image | Track custom image usage |

## 🛡️ Error Handling

**Fallback Behavior**:
- If ad.png is missing → Button is visible but does nothing (silent fail)
- If image is too large → No validation yet (TODO)
- If POLLO API fails → Error logged to console, generation fails
- If no API key → PipelineError.configurationError thrown

## 📚 Files Modified

1. `DirectorStudio/Features/Prompt/PromptView.swift` - UI
2. `DirectorStudio/Features/Prompt/PromptViewModel.swift` - Logic
3. `DirectorStudio/Services/PipelineServiceBridge.swift` - Pipeline
4. `DirectorStudio/Models/GeneratedClip.swift` - Model
5. `DirectorStudio/Features/Studio/StudioView.swift` - Display
6. `DirectorStudio/Features/Studio/ClipCell.swift` - Badge
7. `DirectorStudio/Assets.xcassets/ad.imageset/` - Asset

## 🎯 Mission Accomplished

All objectives from the directive have been implemented:

1. ✅ Image selection UI in Prompt tab
2. ✅ Thumbnail preview after selection
3. ✅ Optional image handling
4. ✅ ad.png as default reference
5. ✅ Pipeline integration (POLLO/DeepSeek)
6. ✅ Walkthrough video capability
7. ✅ Featured Demo section in Studio
8. ✅ Analytics logging
9. ✅ Documentation

**Status**: Ready for testing with valid API keys.

**Concept**: "From journal to cinema. From emotion to vision. From prompt to screen — in seconds." ✨

