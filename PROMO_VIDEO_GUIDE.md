# 🎬 App Store Promo Video Generator

## ✨ UX/UI Design

### Where to Find It

The promo video generator is thoughtfully placed in **Settings** under a dedicated **"🎬 Marketing Tools"** section:

```
Library Tab → ⚙️ Settings (top-right gear icon) → Marketing Tools Section
```

### Navigation Flow

```
┌─────────────────┐
│   Library Tab   │
│                 │
│  📁 Storage     │
│  ⚙️  Settings ←──── Tap gear icon
└─────────────────┘
         ↓
┌─────────────────────────────────┐
│        Settings View            │
├─────────────────────────────────┤
│ 👤 Account                      │
│ 💾 Storage                      │
│ 🧪 Experimental                 │
│                                 │
│ 🎬 Marketing Tools ←────────────── New Section
│ ┌─────────────────────────────┐ │
│ │ Generate App Store          │ │
│ │ Promo Video                 │ │
│ │                             │ │
│ │ Create a 15-second promo    │ │
│ │ video from your app         │ │
│ │ screenshot using Pollo AI   │ │
│ │                             │ │
│ │ [✨ Generate Promo Video 💰] │ │ ← Beautiful button
│ │                             │ │
│ │ ⚠️ This makes a real API    │ │
│ │ call and will cost money    │ │
│ └─────────────────────────────┘ │
│                                 │
│ ℹ️  About                       │
└─────────────────────────────────┘
```

## 🎨 UI Features

### 1. **Visual Hierarchy**
- **Section Header**: "🎬 Marketing Tools" with emoji for visual recognition
- **Clear Title**: "Generate App Store Promo Video" in bold
- **Descriptive Subtitle**: Explains what it does in plain language

### 2. **Progressive Disclosure**
- Collapsed into Settings to avoid cluttering main interface
- Clear warning about API costs with ⚠️ icon
- Money icon (💰) on button to remind users of cost

### 3. **Loading States**
```
Before: [✨ Generate Promo Video 💰]

During: [⏳ Generating video...]  (with spinner)

After:  [✅ Success alert]
```

### 4. **User Feedback**
- **Progress indicator**: Circular spinner while generating
- **Status messages**: Real-time updates in footer
- **Alert dialog**: Success confirmation with file location
- **Console logs**: Detailed progress for developers

## 🔐 Safety Features

### Cost Protection
✅ Hidden in Settings (not main flow)  
✅ Clear warning message  
✅ Visual cost indicator ($)  
✅ Requires explicit button tap  
✅ Progress indicator prevents double-tap

### Error Handling
✅ Validates API keys before request  
✅ Catches and displays API errors  
✅ Timeout protection (5 minutes max)  
✅ Graceful failure messages

## 📱 User Experience Flow

### Happy Path
1. User opens Library tab
2. Taps gear icon (top-right)
3. Scrolls to "🎬 Marketing Tools"
4. Reads description and warning
5. Taps "Generate Promo Video"
6. Sees spinner: "Generating video..."
7. Gets success alert after ~30-60 seconds
8. Video saved to:
   - Documents folder
   - Photo Library (iOS)

### What Gets Generated

**Input**: App icon or screenshot  
**Prompt**: 
```
Create a stunning, professional App Store preview video showcasing DirectorStudio.
Smooth camera zoom and pan across the interface showing:
- The elegant dark interface with purple/blue accents
- Three main sections: Prompt input, Video Studio, and Library
- Text overlay: "DirectorStudio - AI-Powered Video Creation"
- Smooth transitions and professional motion
- Modern, clean aesthetic perfect for iOS App Store
Add subtle glow effects and smooth camera movements to make it engaging.
```

**Output**: 
- 15-second video (1920x1080, 30fps)
- MP4 format
- Saved as: `DirectorStudio_AppStore_Promo.mp4`

## 🚀 How to Use

### Prerequisites
1. Add your Pollo API key to:
   ```
   DirectorStudio/Configuration/Secrets.local.xcconfig
   ```

2. Ensure you have an app screenshot or icon ready

### Steps
1. **Launch the app** in Xcode (⌘R)
2. **Navigate**: Library → Settings
3. **Scroll** to "🎬 Marketing Tools"
4. **Tap**: "Generate Promo Video" button
5. **Wait**: 30-60 seconds for generation
6. **Success**: Check Documents folder and Photo Library

### Where to Find Your Video

**iOS Simulator**:
```bash
~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/DirectorStudio_AppStore_Promo.mp4
```

**Photo Library** (iOS Device):
- Open Photos app
- Check "Recents" album

**Console Output**:
The app prints the exact file path when complete.

## 💡 Design Rationale

### Why in Settings?
- **Non-intrusive**: Doesn't clutter main creative workflow
- **Discoverability**: Users exploring settings will find it
- **Context**: Makes sense with other app configuration
- **Safety**: Extra step prevents accidental expensive API calls

### Why This Section?
- **"Marketing Tools"** clearly indicates its purpose
- Separated from user settings (storage, account)
- Room to add more marketing features later
- Professional categorization

### Visual Indicators
- 🎬 **Emoji**: Quick visual recognition
- 💰 **Cost icon**: Constant reminder of API cost
- ⚠️ **Warning**: Hard to miss yellow triangle
- ✨ **Sparkle**: Suggests AI/magic generation
- ⏳ **Progress**: Shows it's working (not frozen)

## 🎯 Perfect for App Store

The generated video is ideal for:
- App Store preview videos
- Marketing materials
- Social media posts
- Demo videos
- Investor presentations

**Pro tip**: Upload multiple variations and A/B test which performs best!

---

## 📊 Technical Details

**API Endpoint**: `POST https://api.pollo.ai/v1/video/image-to-video`

**Request Payload**:
```json
{
  "image": "base64_encoded_image",
  "prompt": "video description...",
  "duration": 15.0,
  "resolution": "1920x1080",
  "fps": 30,
  "motion_strength": 0.8,
  "interpolate": true
}
```

**Response Handling**:
- Direct URL: Immediate download
- Job ID: Polls every 5 seconds (max 60 attempts = 5 minutes)

**Cost Estimate**: 
Check Pollo AI pricing - typically $0.10-1.00 per video depending on length/quality.

---

Built with ❤️ for a smooth, professional user experience.

