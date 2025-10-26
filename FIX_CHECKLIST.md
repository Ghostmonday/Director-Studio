# 🔧 **COMPLETE FIX CHECKLIST - Make Everything Work**

---

## ⚠️ **CRITICAL ISSUES FOUND:**

### **1. Supabase is NOT Running** ❌
- Your local Supabase at `http://127.0.0.1:54321` is **not running**
- API key fetching will fail
- Videos will default to demo mode

### **2. File References Broken** ❌
- Xcode still references 6 deleted files
- Build will fail until fixed

---

## 🛠️ **FIXES (In Order):**

---

### **FIX #1: Start Supabase** (2 minutes)

**In a NEW Terminal window:**
```bash
cd /Users/user944529/Desktop/last-try
supabase start
```

**Wait for:**
```
✓ Started supabase local development setup.

API URL: http://127.0.0.1:54321
```

**Keep this terminal open!** Supabase must stay running.

**Test it works:**
```bash
curl -X POST http://127.0.0.1:54321/functions/v1/generate-api-key \
  -H "Content-Type: application/json" \
  -d '{"service":"Pollo"}'
```

**Should return:** `{"key":"sk-your-pollo-key..."}`

---

### **FIX #2: Clean Xcode File References** (2 minutes)

**In Xcode (already open):**

#### **A) Remove RED files:**
1. `PolishedPromptView.swift` → Right-click → Delete → Remove Reference
2. `CreditsPurchaseView.swift` → Right-click → Delete → Remove Reference
3. `SettingsView.swift` → Right-click → Delete → Remove Reference
4. `StudioView.swift` → Right-click → Delete → Remove Reference
5. `AgentDevMode.swift` → Right-click → Delete → Remove Reference
6. `FrameExtractor.swift` (in ROOT, not Services) → Right-click → Delete → Remove Reference

#### **B) Add new file:**
1. Right-click **Services** folder
2. **"Add Files to 'DirectorStudio'..."**
3. Navigate to: `DirectorStudio/Services/`
4. Select: `SupabaseAPIKeyService.swift`
5. ✅ Check: "Add to targets: DirectorStudio"
6. ❌ Uncheck: "Copy items if needed"
7. Click **Add**

#### **C) Add Monetization folder (if not there):**
1. In Xcode, check if `Services` folder has `Monetization` subfolder
2. If NOT:
   - Right-click **Services** folder
   - **"Add Files to 'DirectorStudio'..."**
   - Select the **Monetization** folder
   - ✅ Check: "Create groups" (NOT "folder references")
   - ✅ Check: "Add to targets: DirectorStudio"
   - Click **Add**

#### **D) Build:**
Press **⌘+B**

**Should see:** ✅ **Build Succeeded**

---

### **FIX #3: Verify Image Picker** (30 seconds)

**In Xcode:**

1. Open `DirectorStudio/Info.plist`
2. Verify these keys exist:
   - `NSPhotoLibraryUsageDescription` ✅ (Already there)
   - `NSPhotoLibraryAddUsageDescription` ✅ (Already there)
   - `NSCameraUsageDescription` (Add if missing)

**If missing Camera permission:**
```xml
<key>NSCameraUsageDescription</key>
<string>DirectorStudio needs camera access for reference images</string>
```

---

### **FIX #4: Rebuild & Install** (1 minute)

```bash
cd /Users/user944529/Desktop/last-try

# Clean build
xcodebuild clean -scheme DirectorStudio

# Build
xcodebuild -scheme DirectorStudio \
  -destination 'platform=iOS Simulator,id=12673044-36F5-49BF-9242-4BE668CAC291' \
  build

# Install
xcrun simctl install 12673044-36F5-49BF-9242-4BE668CAC291 \
  ~/Library/Developer/Xcode/DerivedData/DirectorStudio-*/Build/Products/Debug-iphonesimulator/DirectorStudio.app

# Launch
xcrun simctl launch 12673044-36F5-49BF-9242-4BE668CAC291 com.directorstudio.app
```

---

## ✅ **VERIFICATION TESTS:**

### **Test 1: Image Picker**
1. Tap **📷 Add Image** button
2. Should show photo library picker
3. Select an image
4. Image should appear as preview

**If fails:** Check console logs for permission errors

---

### **Test 2: API Key Fetching**
1. **Check Xcode console** after app launches
2. Look for: `🔑 Using Supabase Pollo key`
3. Should NOT say: `🎬 DEMO MODE`

**If fails:** Supabase not running or keys not in database

---

### **Test 3: Video Generation**
1. Enter prompt: "A dragon breathing fire"
2. Set duration: 5 seconds
3. Tap **Generate Video**
4. **Check console for:**
   - `🔑 Fetching Pollo key from Supabase...`
   - `✅ Successfully fetched Pollo key`
   - NOT: `🎬 DEMO MODE`

**Expected:** Real video generated (not Chromecast demo)

**If demo video:** Supabase keys are wrong or not accessible

---

## 🚨 **TROUBLESHOOTING:**

### **"Supabase won't start"**
```bash
# Check if already running
supabase status

# Stop and restart
supabase stop
supabase start
```

### **"Image picker doesn't show"**
- Reset simulator: Device → Erase All Content and Settings
- Rebuild and try again

### **"Still getting demo videos"**
- Verify Supabase is running: `supabase status`
- Test API manually:
```bash
curl -X POST http://127.0.0.1:54321/functions/v1/generate-api-key \
  -H "Content-Type: application/json" \
  -d '{"service":"Pollo"}'
```
- Check Supabase database has keys:
```sql
SELECT * FROM api_keys;
```

### **"Build fails in Xcode"**
- Make sure you removed ALL 6 red file references
- Make sure you added SupabaseAPIKeyService.swift
- Clean build folder: ⌘+Shift+K
- Rebuild: ⌘+B

---

## 📊 **EXPECTED OUTCOME:**

✅ **Build succeeds**  
✅ **Image picker opens**  
✅ **Supabase returns API keys**  
✅ **Real videos generate (not demo)**  
✅ **Duration slider works**  
✅ **Cost calculations show**  

---

## 🎯 **DO THIS NOW:**

1. **Start Supabase** (keep terminal open)
2. **Fix Xcode file references**
3. **Press ⌘+B** to build
4. **Run the rebuild script above**
5. **Test image picker**
6. **Test video generation**

---

**If ANY step fails, tell me EXACTLY what error you see!** 🔍

