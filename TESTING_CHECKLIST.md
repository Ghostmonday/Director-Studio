# 🧪 DirectorStudio Image Reference Testing Checklist

## ⚡ Pre-Flight Check

### 1. API Keys Required

You need at least **POLLO_API_KEY** to test image-to-video generation.

**Check your keys:**
```bash
# Look in DirectorStudio/Configuration/Secrets.xcconfig
cat DirectorStudio/Configuration/Secrets.xcconfig
```

**Should have:**
- `POLLO_API_KEY = your_actual_key_here`
- `DEEPSEEK_API_KEY = your_actual_key_here` (optional, for prompt enhancement)

### 2. Build the App

```bash
cd /Users/user944529/Desktop/last-try
xcodebuild -scheme DirectorStudio -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15 Pro' clean build
```

Or just open in Xcode and hit **⌘+R** to run!

---

## 🎬 THE BIG TEST - Generate Promo Video

### Step-by-Step:

1. **Launch DirectorStudio** on simulator or device

2. **Navigate to Prompt tab** (should be default)

3. **Fill in the form:**

   **Project Name:**
   ```
   DirectorStudio Promo
   ```

   **Prompt Text** (copy this EXACT prompt):
   ```
   Animate this mobile app screenshot with cinematic camera movements while preserving ALL UI elements and text clarity. Start with a gentle push-in centered on the text input field, hold for 2 seconds, then slowly pan down revealing the pipeline stage toggles. Add subtle zoom emphasizing the creative power. Professional gimbal-quality smooth movement. Warm inviting lighting (3200K-4500K), soft key light from top-left, subtle lens flares, 15% film grain for cinematic texture. Slight vignette to focus attention. Modern tech commercial color grade - slightly desaturated with lifted blacks. UI elements have subtle parallax depth. Gentle screen glow suggesting live interface. Very subtle floating particles (5% opacity) suggesting creativity. ALL text must remain 100% sharp and readable - no motion blur on UI elements. Maintain crisp edges on buttons and toggles. Style: Apple WWDC app reveal meets modern SaaS demo (Linear/Notion style). Professional, clean, inspiring. Tech commercial meets film production quality. Preserve UI contrast for accessibility. Mood: inspiring without cheesy, professional without cold, creative possibility, accessible power. This is where stories become cinema.
   ```

4. **Click "Add Reference Image"**

5. **Select "Use Default Demo Image"** ✅ (this is your ad.png)

6. **Set Duration Slider:**
   - Move to **15 seconds** (good balance for promo)
   - Or go up to **20 seconds** for more cinematic slow motion

7. **Pipeline Stages** (recommended):
   - ✅ **Enhancement** - Makes prompt even better with DeepSeek
   - ✅ **Camera Direction** - Adds professional movements
   - ✅ **Lighting** - Optimizes atmosphere
   - ✅ **Continuity** - Ensures smooth flow
   - ⬜ Segmentation - Not needed for single shot

8. **Click "Generate Clip"** 🪄

---

## ⏱️ What Happens Next

### Console Output to Watch:

```
🎬 Starting clip generation...
   Clip: Clip_001
   Prompt: Animate this mobile app screenshot...
   Image: Yes (XXX KB)
   Featured: true
   Duration: 15.0s

🔧 Enhancing prompt with DeepSeek...
✅ Enhanced prompt: [improved version]...

🖼️ Generating video from image...
📤 Sending image-to-video request to Pollo...
   Prompt: [enhanced prompt]
   Duration: 15.0s
   Image size: XXX KB

📥 Response status: 200
⏳ Video generation in progress (job: xxx)...
⏳ Still processing... (5s elapsed)
⏳ Still processing... (10s elapsed)
✅ Video generation completed after 45s

⬇️ Downloading video...
✅ Generated clip: Clip_001
   Local URL: /path/to/video.mp4
```

### Expected Timeline:
- **Enhancement**: 5-10 seconds (DeepSeek)
- **Video Generation**: 30-120 seconds (Pollo AI, varies by queue)
- **Download**: 2-5 seconds
- **Total**: 1-3 minutes

---

## ✅ Success Criteria

After generation completes:

1. **App navigates to Studio tab** automatically
2. **"Featured Demo" section appears** at top with star icon ⭐
3. **Your promo video is listed** with name "Clip_001"
4. **Star badge visible** on the thumbnail
5. **Duration shows** as 15s (or whatever you set)
6. **Sync status** shows orange dot (not uploaded yet)

---

## 🐛 Troubleshooting

### "Pollo API key not configured"
- Check `Secrets.xcconfig` has `POLLO_API_KEY = your_key`
- Make sure no extra spaces or quotes
- Restart Xcode after editing

### "DeepSeek API request failed"
- Enhancement will skip, uses original prompt
- Not critical - video will still generate

### "Video generation failed"
- Check console for error details
- Verify API key is valid
- Check Pollo API quota/credits

### App crashes
- Check Xcode console for stack trace
- Look for linter errors in modified files
- Verify ad.png exists in Assets catalog

### No image appears in picker
- Verify: `DirectorStudio/Assets.xcassets/ad.imageset/ad.png` exists
- Check `Contents.json` is valid
- Clean build folder: Xcode → Product → Clean Build Folder

---

## 📊 What to Check

### UI Validation:
- [ ] Image picker button appears below text area
- [ ] Clicking opens sheet with 2 options
- [ ] Default demo image shows thumbnail
- [ ] Custom library picker works
- [ ] Selected image shows thumbnail preview
- [ ] X button removes image
- [ ] Duration slider shows (3-20s range)
- [ ] Current duration displays correctly
- [ ] Generate button works

### Generation Validation:
- [ ] Console shows image size
- [ ] "Featured: true" in logs
- [ ] Correct duration passed to API
- [ ] Video URL returned
- [ ] File downloads successfully
- [ ] App navigates to Studio

### Studio Display:
- [ ] Featured Demo section appears
- [ ] Star badge on clip cell
- [ ] Clip name correct
- [ ] Duration displays correctly
- [ ] Can select/highlight clip

---

## 🎉 Next Steps After Success

1. **Watch the generated video** (tap to preview - if implemented)
2. **Test with custom image** - try your own photo
3. **Try different durations** (3s, 10s, 20s)
4. **Test different prompts** - experiment with styles
5. **Generate regular clips** - test without image
6. **Test multiple clips** - verify Featured Demo stays at top

---

## 🚨 IMPORTANT NOTES

- **Pollo API calls cost money** - be mindful of testing frequency
- **First generation might take longer** - API cold start
- **Videos are downloaded locally** - check storage space
- **No video playback implemented yet** - that's next feature
- **iCloud disabled in guest mode** - normal behavior

---

## 📝 Quick Test Command

```bash
# Build and run in one line
cd /Users/user944529/Desktop/last-try && \
xcodebuild -scheme DirectorStudio \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  clean build && \
echo "✅ Build successful! Now run in Simulator or Xcode."
```

---

## 🎬 YOU'RE READY!

Everything is implemented and ready to test. The moment of truth! 

**LET'S MAKE SOME MOVIE MAGIC!** 🎥✨

