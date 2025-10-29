# Segmentation Module Logging & Debug Guide

## 🎬 Overview

I've set up comprehensive logging for the DirectorStudio segmentation module so you can see exactly what happens when the AI re-articulates stories into segments.

## 📊 Three Ways to View Logs

### 1. **In-App Debug View** (NEW!)
- Look for the floating debug button (magnifying glass icon) in the bottom-right corner of the Prompt screen
- Tap to open the real-time log viewer
- Features:
  - Color-coded log levels (Info, Warning, Error, Success)
  - Search functionality
  - Auto-scroll toggle
  - Expandable log entries for details
  - Real-time updates as segmentation happens

### 2. **Console Log Monitoring**
Run this command in Terminal to see filtered console logs:
```bash
./watch_segmentation_console.sh
```

This shows:
- All segmentation module activity
- Script processing steps
- AI mode operations
- Duration calculations
- Validation results

### 3. **File-Based Logs**
The segmentation module writes detailed logs to:
```
~/Library/Developer/CoreSimulator/Devices/[DEVICE_ID]/data/Containers/Data/Application/[APP_ID]/Documents/segmentation_debug.txt
```

To view these logs:
```bash
./view_segmentation_logs.sh
```

## 🚀 Running the App with Logging

The app is already running on your simulator with console output enabled. When you:

1. **Enter a script** in the Prompt view
2. **Enable "Segmentation"** in the pipeline stages
3. **Tap "Generate"**

You'll see detailed logs showing:

### What Gets Logged:

```
🎬 [SegmentingModule] SEGMENTATION STARTED
📝 Script Length: 245 characters
📝 Script Preview: A young woman walks through...
🎯 Mode: AI (Cinematic)
⚙️  Constraints:
   - Max Segments: 20
   - Max Tokens/Segment: 200
   - Max Duration: 20.0s
   - Target Duration: 3.0s

🤖 [AI Mode] Starting LLM-based segmentation...
✅ [AI Mode] Success: Generated 4 segments

🔍 [Validation] Enforcing constraints on 4 segments...
✅ [Validation] After enforcement: 4 segments

✅ [SegmentingModule] SEGMENTATION COMPLETE
📊 Results:
   - Total Segments: 4
   - Total Tokens: 156
   - Total Duration: 12.0s
   - Avg Confidence: 85%
   - Execution Time: 2.34s
```

## 🔍 Debug Features

### In the Debug View:
- **Filter by log level**: See only errors, warnings, or successes
- **Search**: Find specific operations or errors
- **Export**: Copy logs for sharing (tap and hold on entries)
- **Stats**: See count of each log type

### Understanding Log Levels:
- 🔵 **Info**: Normal operations
- 🟠 **Warning**: Non-critical issues (e.g., fallbacks)
- 🔴 **Error**: Failures that need attention
- 🟢 **Success**: Completed operations

## 💡 Common Scenarios to Watch For:

1. **AI Segmentation Success**:
   - Look for "✅ [AI Mode] Success"
   - Check segment count and confidence scores

2. **Fallback to Duration-Based**:
   - "⚠️ [Hybrid Mode] AI failed"
   - "🔄 [Hybrid Mode] Falling back to duration-based"

3. **Constraint Violations**:
   - "⚠️ [Validation] Constraints violated"
   - Watch for auto-adjustments

4. **API Issues**:
   - "❌ [AI Mode] FAILED: No LLM configuration"
   - Check API key setup

## 🛠️ Troubleshooting

If you don't see logs:
1. Make sure you're in DEBUG mode (not Release)
2. Check that "Segmentation" is enabled in pipeline stages
3. Verify the app is running on the simulator
4. Try generating a multi-segment story (longer scripts)

## 📱 Quick Test

To see the logging in action:
1. Open DirectorStudio
2. Go to Prompt tab
3. Select "Full Film" mode
4. Paste this test script:
   ```
   A detective enters a dimly lit office. Thunder rumbles outside.
   
   He searches through old files, finding a crucial photograph.
   
   The phone rings. A mysterious voice warns him to stop investigating.
   
   Despite the threat, he grabs his coat and heads into the stormy night.
   ```
5. Enable "Segmentation" toggle
6. Tap "Generate"
7. Watch the logs appear in real-time!

---

The segmentation module is now fully instrumented for debugging. You can see exactly how your stories are being analyzed and split into cinematic segments!
