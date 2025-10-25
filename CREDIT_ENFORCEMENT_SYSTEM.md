# Credit Enforcement System

## Overview
DirectorStudio now has a comprehensive credit enforcement system that automatically manages demo mode and API access based on user credits.

## Key Features

### 1. **Automatic Demo Mode Detection**
- Demo mode is NO LONGER controlled by config files
- System automatically enables demo mode when:
  - User has 0 credits AND hasn't made any purchases
  - API key is set to "demo-key"

### 2. **Credit Management**
- **New users**: Automatically receive 1 free credit on first launch
- **Credit costs**: Calculated dynamically based on:
  - Video duration (1 credit per 5 seconds)
  - Enabled pipeline stages (+1-2 credits each)
- **Purchase tracking**: System tracks if user has ever made a purchase

### 3. **UI Enforcement**
- Real-time credit balance display
- Cost preview before generation
- Generate button disabled when insufficient credits
- Color-coded status indicators:
  - Green: Sufficient credits
  - Orange/Red: Insufficient credits
- Purchase prompts when credits are low (≤3)

### 4. **Error Handling**
- Clear error messages for insufficient credits
- Non-intrusive alerts with purchase options
- Graceful fallback to demo mode

## Configuration

### API Keys
Edit `DirectorStudio/Configuration/Secrets.local.xcconfig`:
```
// To use real APIs, replace with actual keys:
POLLO_API_KEY = your-actual-pollo-key
DEEPSEEK_API_KEY = your-actual-deepseek-key
```

### Credit System Properties
- `CreditsManager.shared.credits`: Current credit balance
- `CreditsManager.shared.hasPurchased`: Purchase history flag
- `CreditsManager.shared.shouldUseDemoMode`: Auto-calculated demo status

## How It Works

### 1. **Pre-flight Check**
Before any generation:
```swift
let cost = CreditsManager.shared.creditsNeeded(for: duration, enabledStages: stages)
try CreditsManager.shared.checkCreditsForGeneration(cost: cost)
```

### 2. **Dynamic Demo Mode**
Services check credits at runtime:
```swift
if CreditsManager.shared.shouldUseDemoMode || apiKey == "demo-key" {
    // Use demo video
} else {
    // Make real API call
}
```

### 3. **Post-Generation**
On successful generation:
```swift
CreditsManager.shared.useCredits(amount: cost)
```

## User Experience

### With Credits
1. See real-time cost calculation
2. Generate button enabled
3. Credits deducted on success
4. Real API calls made

### Without Credits
1. See "Insufficient Credits" message
2. Generate button disabled
3. Purchase prompt shown
4. Demo mode auto-enabled

## Testing

### Simulate Different States
```swift
// Give credits for testing
CreditsManager.shared.addCredits(10)

// Simulate purchase
CreditsManager.shared.addCredits(10, fromPurchase: true)

// Reset to demo mode
CreditsManager.shared.credits = 0
```

## Benefits
- ✅ No manual demo mode toggling
- ✅ Prevents accidental API usage
- ✅ Clear user guidance
- ✅ Seamless demo → paid transition
- ✅ Protection against credit abuse

## Developer Mode (DEBUG builds only)

### Security Features
Developer mode includes multiple security layers to prevent unauthorized access:

1. **Build Configuration Check**
   - Only available in DEBUG builds
   - Completely removed from release builds via #if DEBUG

2. **Secret Gesture Activation**
   - Hidden in Settings → About DirectorStudio
   - Requires 5 taps within 2 seconds to reveal
   - Provides haptic feedback when unlocked

3. **Monthly Rotating Passcode**
   - Format: `YYYYDSMM` (e.g., "2025DS10" for October 2025)
   - Changes automatically each month
   - Invalid passcode shows error feedback

4. **Time-Limited Sessions**
   - Dev mode expires after 1 hour
   - Must re-enter passcode to continue
   - Automatic cleanup on expiration

5. **Configuration Requirement**
   - Requires `DEV_MODE = YES` in build config
   - Additional protection against tampering

### Dev Mode Features
When activated, dev mode provides:
- 🆓 Free API usage (no credit consumption)
- 🎯 Real API calls instead of demo videos
- 🔧 Credit manipulation tools for testing
- 🚫 Bypasses all credit checks
- 💜 Clear purple visual indicators

### Usage
1. Go to Settings → About
2. Tap "About DirectorStudio" 5 times quickly
3. Developer Options section appears
4. Tap "Enter Dev Passcode"
5. Enter current month's passcode (YYYYDSMM)
6. Dev mode active for 1 hour

### Security Considerations
- Never share passcode format publicly
- Passcode changes monthly
- All security checks must pass
- Visual indicators prevent accidental use
- Automatic expiration limits exposure
