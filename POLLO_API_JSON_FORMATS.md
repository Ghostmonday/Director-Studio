# Pollo API JSON Formats - Current Implementation

## Overview

DirectorStudio communicates with Pollo AI API using different JSON formats for each tier. All formats use single-image + prompt (no `imageTail`).

---

## 📤 REQUEST FORMATS

### 1. Economy Tier (Kling 1.6)

**Endpoint**: `POST https://pollo.ai/api/platform/generation/kling-ai/kling-v1-6`

**Headers**:
```
Content-Type: application/json
x-api-key: pollo_wR53NAgcFqBTzPAaggCoQtQBvyusFBSPMfyujBdoCfkn
```

**Request Body**:
```json
{
  "input": {
    "prompt": "test",
    "length": 5,
    "mode": "std",
    "strength": 50,
    "image": "data:image/jpeg;base64,/9j/4AAQSkZJRg..." // Optional, base64 with data URI prefix
  }
}
```

**Fields**:
- `prompt` (required): Text prompt for video generation
- `length` (required): Duration in seconds (5 or 10)
- `mode` (required): `"std"` (standard mode)
- `strength` (optional): Default `50`
- `image` (optional): Base64 image with `data:image/jpeg;base64,` prefix
- ❌ `imageTail`: **Omitted** (single image only)
- ❌ `negativePrompt`: Omitted if not provided

---

### 2. Basic Tier (Pollo 1.6)

**Endpoint**: `POST https://pollo.ai/api/platform/generation/pollo/pollo-v1-6`

**Headers**:
```
Content-Type: application/json
x-api-key: pollo_wR53NAgcFqBTzPAaggCoQtQBvyusFBSPMfyujBdoCfkn
```

**Request Body**:
```json
{
  "input": {
    "prompt": "test",
    "resolution": "480p",
    "length": 5,
    "mode": "basic",
    "image": "data:image/jpeg;base64,/9j/4AAQSkZJRg..." // Optional, base64 with data URI prefix
  }
}
```

**Fields**:
- `prompt` (required): Text prompt for video generation
- `resolution` (required): `"480p"` (always 480p for Basic tier)
- `length` (required): Duration in seconds (5 or 10)
- `mode` (required): `"basic"`
- `image` (optional): Base64 image with `data:image/jpeg;base64,` prefix
- `seed` (optional): Random seed for reproducibility
- ❌ `imageTail`: **Omitted** (single image only)

**Note**: Built manually via `JSONSerialization` to ensure `imageTail` is never included.

---

### 3. Pro Tier (Kling 2.5 Turbo)

**Endpoint**: `POST https://pollo.ai/api/platform/generation/kling-ai/kling-v2-5-turbo`

**Headers**:
```
Content-Type: application/json
x-api-key: pollo_wR53NAgcFqBTzPAaggCoQtQBvyusFBSPMfyujBdoCfkn
```

**Request Body**:
```json
{
  "input": {
    "prompt": "test",
    "length": 5,
    "strength": 50,
    "image": "https://example.com/image.jpg" // Optional, HTTPS URL preferred (no base64)
  }
}
```

**Fields**:
- `prompt` (required): Text prompt for video generation
- `length` (required): Duration in seconds
- `strength` (optional): Default `50`
- `image` (optional): HTTPS URL (preferred over base64)
- `negativePrompt` (optional): Negative prompt
- ❌ `mode`: **Not supported** (not in API docs)
- ❌ `imageTail`: **Not supported** (not in API docs)

**Note**: Uses `Codable` structs (`Kling25TurboInput`, `Kling25TurboRequest`).

---

## 📥 RESPONSE FORMATS

### 1. Task Creation Response (All Tiers)

**Wrapped Format** (Kling 1.6, Kling 2.5 Turbo, Pollo 1.6):
```json
{
  "code": "SUCCESS",
  "message": "success",
  "data": {
    "taskId": "cmhdugtn008iw142oungth0my",
    "status": "waiting"
  }
}
```

**Flat Format** (Legacy Pollo 1.6 - fallback):
```json
{
  "taskId": "cmhdugtn008iw142oungth0my",
  "status": "waiting"
}
```

**Status Values**:
- `"waiting"`: Task created, waiting to start
- `"processing"`: Task is being processed
- `"succeed"`: Task completed successfully
- `"failed"`: Task failed

---

### 2. Status Polling Response (Expected)

**Format**:
```json
{
  "taskId": "cmhdugtn008iw142oungth0my",
  "status": "processing", // or "waiting", "succeed", "failed"
  "videoUrl": "https://..." // Present when status is "succeed"
}
```

**OR Wrapped Format**:
```json
{
  "code": "SUCCESS",
  "message": "success",
  "data": {
    "taskId": "cmhdugtn008iw142oungth0my",
    "status": "succeed",
    "videoUrl": "https://cdn.pollo.ai/videos/..."
  }
}
```

**Current Issue**: Status endpoint returns 404 instead of above format.

---

### 3. Error Response

**Format**:
```json
{
  "message": "Not found",
  "code": "NOT_FOUND"
}
```

**OR**:
```json
{
  "message": "Error description",
  "code": "ERROR_CODE",
  "issues": [
    {
      "message": "Specific issue description"
    }
  ]
}
```

---

## 🔄 COMPLETE REQUEST/RESPONSE FLOW

### Example: Basic Tier (Pollo 1.6)

**Step 1: Create Task**
```bash
POST https://pollo.ai/api/platform/generation/pollo/pollo-v1-6
Headers:
  Content-Type: application/json
  x-api-key: pollo_wR53NAgcFqBTzPAaggCoQtQBvyusFBSPMfyujBdoCfkn

Body:
{
  "input": {
    "prompt": "test",
    "resolution": "480p",
    "length": 5,
    "mode": "basic"
  }
}

Response (200 OK):
{
  "code": "SUCCESS",
  "message": "success",
  "data": {
    "taskId": "cmhdugtn008iw142oungth0my",
    "status": "waiting"
  }
}
```

**Step 2: Poll Status** (Currently failing)
```bash
GET https://pollo.ai/api/platform/generation/task/status/cmhdugtn008iw142oungth0my
Headers:
  x-api-key: pollo_wR53NAgcFqBTzPAaggCoQtQBvyusFBSPMfyujBdoCfkn

Expected Response (200 OK):
{
  "code": "SUCCESS",
  "message": "success",
  "data": {
    "taskId": "cmhdugtn008iw142oungth0my",
    "status": "succeed",
    "videoUrl": "https://cdn.pollo.ai/videos/..."
  }
}

Actual Response (404 Not Found):
{
  "message": "Not found",
  "code": "NOT_FOUND"
}
```

---

## 🖼️ IMAGE FORMATS

### Image Processing

**Before Sending**:
1. Resize to 480p (854x480) maintaining aspect ratio
2. Compress to JPEG at 80% quality (fallback to 60% if >600KB)
3. Encode to base64
4. Add data URI prefix: `data:image/jpeg;base64,{base64String}`

**For Kling 2.5 Turbo**:
- Prefer HTTPS URL over base64
- If base64 needed, use same format as above

**Example**:
```
data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k=
```

---

## 📋 CODE STRUCTURES

### Swift Structs

**PolloInput** (Basic Tier):
```swift
struct PolloInput: Codable {
    let prompt: String
    let resolution: String
    let length: Int
    let mode: String
    let image: String? // Base64 with data URI prefix
    let imageTail: String? // Deprecated - not used
    let seed: Int?
}
```

**KlingInput** (Economy Tier):
```swift
struct KlingInput: Codable {
    let prompt: String
    let length: Int
    let mode: String
    let strength: Int?
    let image: String? // Base64 with data URI prefix
    let imageTail: String? // Deprecated - not used
    let negativePrompt: String?
}
```

**Kling25TurboInput** (Pro Tier):
```swift
struct Kling25TurboInput: Codable {
    let prompt: String
    let length: Int
    let strength: Int?
    let image: String? // HTTPS URL preferred
    let negativePrompt: String?
    // NO mode or imageTail fields
}
```

**Response Structs**:
```swift
struct PolloResponse: Codable {
    let taskId: String
    let status: String
    let videoUrl: String?
}

struct KlingWrappedResponse: Codable {
    let code: String
    let message: String
    let data: PolloResponse
}
```

---

## 🔍 KEY DIFFERENCES BY TIER

| Field | Economy (Kling 1.6) | Basic (Pollo 1.6) | Pro (Kling 2.5) |
|-------|---------------------|-------------------|------------------|
| `mode` | ✅ `"std"` | ✅ `"basic"` | ❌ Not supported |
| `resolution` | ❌ Not used | ✅ `"480p"` | ❌ Not used |
| `strength` | ✅ Default 50 | ❌ Not used | ✅ Default 50 |
| `image` format | Base64 + data URI | Base64 + data URI | HTTPS URL preferred |
| `imageTail` | ❌ Omitted | ❌ Omitted | ❌ Not supported |
| Response format | Wrapped | Wrapped/Flat | Wrapped |

---

## ⚠️ CURRENT ISSUES

1. **Status Endpoint**: Returns 404 for all tasks (all tiers)
2. **Task IDs**: Valid (created successfully)
3. **Request Format**: Verified correct (matches API expectations)
4. **Response Handling**: Handles both wrapped and flat formats

---

## 📝 NOTES

- All tiers use **single-image + prompt** approach (no `imageTail`)
- Pollo 1.6 request built manually to ensure `imageTail` is never included
- Image compression targets <600KB (80% JPEG quality)
- Status polling tries wrapped format first, falls back to flat format
- Fast-fail timeout: 30 seconds max for task indexing

---

**Last Updated**: 2025-10-30  
**Status**: Request formats verified ✅ | Status endpoint returning 404 ❌


