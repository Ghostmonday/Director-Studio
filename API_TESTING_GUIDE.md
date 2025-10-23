# API Testing Guide

## ✅ Setup Complete!

I've configured DirectorStudio to use your DeepSeek and Pollo API keys. Here's what was done:

### Changes Made:

1. **Info.plist** - Added API key configuration entries
2. **Secrets.local.xcconfig** - Created local secrets file (needs your real keys)
3. **GitHub Actions Workflows** - Updated to inject secrets during CI/CD builds
4. **AppCoordinator.swift** - Added automatic API health check on app launch

---

## 🧪 How to Test

### ⚠️ IMPORTANT: API Call Costs

The health checks **make actual API calls** which may cost money:
- **DeepSeek**: Small text completion (~pennies)
- **Pollo**: Potential video generation call (more expensive)

**By default, automatic testing is DISABLED** to save you money!

### Option 1: Test Configuration Only (FREE)

1. **Add Your Real API Keys**  
   Edit: `DirectorStudio/Configuration/Secrets.local.xcconfig`
   
   Replace the placeholder text with your actual keys:
   ```xcconfig
   POLLO_API_KEY = your-actual-pollo-key
   DEEPSEEK_API_KEY = your-actual-deepseek-key
   ```

2. **Build and Run in Xcode**
   - Press `⌘B` to build
   - Press `⌘R` to run
   
3. **Check Console Output**
   
   You'll see if keys are configured (no API calls made):
   ```
   🔑 Pollo API key configured: true/false
   🔑 DeepSeek API key configured: true/false
   ```

### Option 2: Test With Actual API Calls (COSTS MONEY)

To test that the APIs actually work, uncomment this line in `AppCoordinator.swift`:

```swift
// Change this:
// await testAPIServices()

// To this:
await testAPIServices(runHealthCheck: true)
```

This will make real API calls and show connection status.

### Option 2: Test in GitHub Actions

Your workflows are already configured! The API keys will be automatically injected when:

- **ios-simple.yml**: Runs on every push to `main` branch
- **ios.yml**: Run manually via workflow dispatch

To trigger a manual build:
1. Go to: `https://github.com/[your-username]/last-try/actions`
2. Select "Build iOS (Full - Disabled)"
3. Click "Run workflow"

---

## 🔐 Security Notes

- `Secrets.local.xcconfig` is in `.gitignore` - your keys won't be committed
- GitHub Actions uses encrypted secrets
- Never commit actual API keys to version control

---

## 📊 What Gets Tested

The health check will:
- ✅ Verify API keys are configured
- ✅ Test connection to both services
- ✅ Report success/failure in console

If a health check fails, check:
1. Are the API keys correct?
2. Are the endpoints accessible?
3. Do you have internet connectivity?

---

## 🚀 Next Steps

Once both services show "Connected successfully":
1. Your app can use DeepSeek for text analysis and prompt enhancement
2. Your app can use Pollo for video generation
3. The services are automatically available throughout your app

Enjoy building with DirectorStudio! 🎬

