# API Setup Guide for DirectorStudio

## Current Configuration

Your app is configured with:
- **DEMO_MODE = NO** (in `Secrets.local.xcconfig`)
- **Guest mode disabled** - Full UI access enabled
- **No API key entry in UI** - Keys managed via config files only

## To Use Real API Services

### 1. Get Your API Keys

**Pollo AI** (for video generation):
- Sign up at: https://pollo.ai
- Get your API key from the dashboard

**DeepSeek** (for prompt enhancement):
- Sign up at: https://deepseek.com
- Get your API key from settings

### 2. Add Keys to Local Config

Edit `DirectorStudio/Configuration/Secrets.local.xcconfig`:

```
// DEMO MODE - Set to NO to use real APIs
DEMO_MODE = NO

// Pollo API Configuration
POLLO_API_KEY = your-actual-pollo-key-here
POLLO_API_ENDPOINT = https://api.pollo.ai/v1

// DeepSeek API Configuration
DEEPSEEK_API_KEY = your-actual-deepseek-key-here
DEEPSEEK_API_ENDPOINT = https://api.deepseek.com/v1
```

### 3. Clean & Build

1. Open Xcode
2. Product → Clean Build Folder (⇧⌘K)
3. Product → Build (⌘B)
4. Run the app (⌘R)

## Demo Mode

To use demo mode (no API calls):
- Set `DEMO_MODE = YES` in `Secrets.local.xcconfig`
- The app will simulate video generation with sample videos

## GitHub Actions

Your GitHub Actions already use the API keys from repository secrets:
- `POLLO_API_KEY`
- `DEEPSEEK_API_KEY`

These are automatically injected during CI/CD builds.

## Troubleshooting

**"API key not configured" error:**
- Check that your keys are in `Secrets.local.xcconfig`
- Clean build folder and rebuild
- Ensure `DEMO_MODE = NO`

**Can't interact with UI:**
- Guest mode has been disabled
- All UI elements should be interactive
- Try restarting the app

**Want to hide API costs:**
- Set `DEMO_MODE = YES` for testing
- Only set `DEMO_MODE = NO` when ready to generate real videos
