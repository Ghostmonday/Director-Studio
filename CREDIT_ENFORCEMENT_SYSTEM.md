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
