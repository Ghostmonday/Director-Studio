# 💰 Monetization Quick Start

## ✅ What's Been Added

### 1. **Credits System**
- Every user starts with **3 FREE credits**
- 1 credit = 1 video generation
- When credits = 0, app switches to demo mode automatically

### 2. **Demo Mode Logic**
- **No credits?** → Demo mode ON (uses sample videos)
- **Has credits?** → Real AI generation
- **No API keys needed** for users!

### 3. **Purchase Options**
- **Starter Pack**: 10 credits for $4.99
- **Popular Pack**: 30 credits for $9.99 (BEST VALUE)
- **Professional**: 100 credits for $24.99

### 4. **UI Updates**
- Credits counter in Prompt view
- "Get Credits" button when low/out
- Purchase flow in Settings → Credits

## 🚨 IMPORTANT: Add Files to Xcode

You need to manually add these new files to your Xcode project:

1. Open Xcode
2. Right-click on the appropriate folders:
   - `Services` folder → Add `CreditsManager.swift`
   - `Settings` folder → Add `CreditsPurchaseView.swift`
3. Make sure "Copy items if needed" is UNCHECKED
4. Make sure target "DirectorStudio" is checked

## 🎯 How It Works

1. **First Launch**: User gets 3 free credits
2. **Generate Video**: Uses 1 credit (if available)
3. **No Credits**: Switches to demo mode
4. **Purchase Credits**: Tap "Get Credits" anywhere

## 💳 Next Steps for Production

1. **Replace Mock Purchase**: 
   - Integrate StoreKit 2
   - Set up App Store Connect products
   - Replace `simulatePurchase()` with real IAP

2. **Server Validation**:
   - Add receipt validation
   - Track credits server-side
   - Prevent credit manipulation

3. **Analytics**:
   - Track conversion rates
   - Monitor demo vs paid usage
   - A/B test pricing

## 🧪 Testing

1. **Reset Credits** (for testing):
   ```swift
   UserDefaults.standard.removeObject(forKey: "user_credits")
   UserDefaults.standard.removeObject(forKey: "first_launch_completed")
   ```

2. **Test Purchase Flow**:
   - Credits → Get Credits
   - Select a pack
   - Tap Purchase (simulated)

## 📱 User Experience

- **Seamless**: No login required
- **Generous**: 3 free videos to start
- **Clear**: Always shows credit balance
- **Fair**: Pay only for what you use

Your monetization is now LIVE! 🚀
