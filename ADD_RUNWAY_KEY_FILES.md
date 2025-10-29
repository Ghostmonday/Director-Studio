# Add Runway API Key Files to Xcode

## Files Created

1. `DirectorStudio/Services/UserAPIKeysManager.swift` - Manages user-provided API keys
2. `DirectorStudio/Features/Settings/RunwayAPIKeyView.swift` - UI for entering Runway API key

## How to Add to Xcode

### Step 1: Add UserAPIKeysManager.swift

1. Open `DirectorStudio.xcodeproj` in Xcode
2. In the Project Navigator, right-click on `DirectorStudio/Services/` folder
3. Select **"Add Files to DirectorStudio..."**
4. Navigate to and select: `DirectorStudio/Services/UserAPIKeysManager.swift`
5. Make sure:
   - ✅ "Copy items if needed" is **UNCHECKED**
   - ✅ "Add to targets: DirectorStudio" is **CHECKED**
6. Click **"Add"**

### Step 2: Add RunwayAPIKeyView.swift

1. In the Project Navigator, right-click on `DirectorStudio/Features/Settings/` folder
2. Select **"Add Files to DirectorStudio..."**
3. Navigate to and select: `DirectorStudio/Features/Settings/RunwayAPIKeyView.swift`
4. Make sure:
   - ✅ "Copy items if needed" is **UNCHECKED**
   - ✅ "Add to targets: DirectorStudio" is **CHECKED**
5. Click **"Add"**

### Step 3: Verify Build

Build the project (⌘B) - it should compile successfully.

## What This Adds

### Settings UI
- New "API Keys" section in Settings → Preferences
- "Runway API Key" option
- Shows "Your key is set" if user has entered a key

### User Experience
1. User goes to **Settings → Preferences → Runway API Key**
2. Enters their own Runway API key
3. Key is stored securely on device (UserDefaults)
4. App uses user's key instead of Supabase (if provided)
5. Falls back to Supabase if user hasn't provided a key

### Benefits
- ✅ Users can use their own Runway account
- ✅ Reduces your API costs for Runway
- ✅ Optional feature - app works fine without it
- ✅ Keys stored locally, never sent to your servers

