# 🧠 KlingAI Integration Log for DirectorStudio

## Purpose
This file tracks all extracted, transformed, and agent-ready technical information about KlingAI's API. Its core purpose is to ensure:
- No knowledge is lost
- All capabilities are referenceable
- Composer 1 (or other agents) can reorganize, integrate, or refactor based on this evolving spec
- Support clean integration with DirectorStudio's modular Swift/iOS build

---

## 📦 Authentication & Token Generation
- **AccessKey + SecretKey** required
- JWT signed with HS256 used as `Bearer` token (valid 30 mins)
- Token embedded in all request headers

```python
import time, jwt
ak = "..."  # AccessKey
sk = "..."  # SecretKey
headers = {"alg": "HS256", "typ": "JWT"}
payload = {"iss": ak, "exp": time.time() + 1800, "nbf": time.time() - 5}
token = jwt.encode(payload, sk, headers=headers)
```

---

## 🎬 Video Generation: Text-to-Video Endpoint
**POST** `/v1/videos/text2video`

### Required Parameters:
- `model_name`: e.g. `kling-v2-5-turbo`
- `prompt`: max 2500 characters

### Optional:
- `negative_prompt`
- `cfg_scale`: [0.0 – 1.0] (ignored in v2.x)
- `mode`: `std` or `pro`
- `duration`: `5` or `10`
- `aspect_ratio`: `16:9`, `9:16`, `1:1`
- `camera_control`: with `type` + `config` (only for supported models)
- `external_task_id`, `callback_url`

### Response:
Returns `task_id`, status, timestamps, and downloadable `video_url` (valid 30 days)

---

## 🧩 Model Version Capability Matrix
(*Summarized from full matrix already logged in context*)

- **V1/V1.5/V1.6**: Support motion brush, end frames, dual-character effects, camera control
- **V2.x**: No cfg_scale, better quality, requires PRO mode for most advanced output

---

## 🔄 Concurrency & Quota Rules
- All API keys under an account share concurrency quota
- Limit is tied to resource pack type (video/image/try-on)
- Image-to-video concurrency = `n` in the request
- Over-limit returns `1303`: backoff and retry required

---

## ✂️ Multi-Elements Editing Suite
**Used for editing objects inside videos post-generation**

### Flow:
1. **`/init-selection`**: Parse video, return session_id
2. **`/add-selection`**: Mark frame + coordinates (RLE mask returned)
3. **`/delete-selection`, `/clear-selection`**: Modify masks
4. **`/preview-selection`**: Overlay preview video
5. **`/multi-elements`**: Final apply

### Supported Modes:
- `addition`: Insert new object via cropped image
- `swap`: Replace marked object with new image
- `removal`: Clean delete from video

### Required:
- `model_name`: currently only `kling-v1-6`
- `session_id`: valid for 24h
- Cropped images: as base64 or URLs (no prefix, ≤10MB)
- Prompt must include references like `<<<video_1>>>`, `<<<image_1>>>`

---

## 🔍 Error Codes Summary
Key examples:
- `1001–1004`: JWT problems
- `1101–1103`: Account/billing issues
- `1200+`: Bad parameters or invalid model
- `1301–1303`: Policy triggers or rate limits
- `500x`: Server-side errors

---

## 🔒 Data Retention Notes
- All generated videos/images purge automatically after **30 days**
- Video dimensions: must be between **720px and 2160px**
- Duration constraints for multi-element videos:
  - 5s edit = source video must be 2–5s
  - 10s edit = source video must be 7–10s

---

## 🛠️ Use Plan
- Maintain this file as a **live engineering spec**
- Extend with new endpoints, bug responses, test runs, or version differences
- Feed this whole file into Composer 1 for:
  - Refactor planning
  - API module upgrades
  - UI slotting of editing capabilities
  - Future telemetry/analytics wrapping

---

✅ Ready for continued updates.
Just keep pasting and I'll preserve & structure everything here.


