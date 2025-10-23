# GitHub Actions IPA Build Setup Guide

## Overview
This workflow automatically builds an IPA file whenever you push code to GitHub. The IPA can be downloaded as an artifact or uploaded to TestFlight/App Store Connect.

## Required GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions, then add:

### 1. TEAM_ID (Required)
Your Apple Developer Team ID (10 characters, like "ABCD1234EF")
- Find it in Xcode → Settings → Accounts → Select your team

### 2. BUILD_CERTIFICATE_BASE64 (Required for signed builds)
Your Apple Developer certificate in base64 format:
```bash
# Export your certificate from Keychain
security find-identity -v -p codesigning
# Export to p12 (you'll be prompted for password)
security export -k ~/Library/Keychains/login.keychain-db \
  -f pkcs12 -o cert.p12 \
  -P "your-password" \
  -T /usr/bin/codesign
# Convert to base64
base64 -i cert.p12 | pbcopy
# Now paste into GitHub secret
```

### 3. P12_PASSWORD (Required if using certificate)
The password you used when exporting the certificate

### 4. KEYCHAIN_PASSWORD (Required if using certificate)
Any password for the temporary keychain (e.g., "temporary")

### 5. BUILD_PROVISION_PROFILE_BASE64 (Required for App Store builds)
Your provisioning profile in base64:
```bash
# Download from Apple Developer portal or export from Xcode
# Convert to base64
base64 -i YourProfile.mobileprovision | pbcopy
```

### 6. APP_STORE_CONNECT_API_KEY (Optional - for auto-upload)
For automatic TestFlight uploads, create an API key:
1. Go to App Store Connect → Users and Access → Keys
2. Create a new key with "App Manager" role
3. Download the .p8 file
4. Note the Key ID and Issuer ID

## Workflow Outputs

After each push, the workflow will:
1. Build your app
2. Create a signed IPA file
3. Upload it as a GitHub artifact
4. (Optional) Upload to TestFlight

## Downloading Your IPA

1. Go to Actions tab in your GitHub repo
2. Click on the latest workflow run
3. Scroll to "Artifacts" section
4. Download "DirectorStudio.ipa"

## Installing the IPA

### Via TestFlight:
- Upload IPA to App Store Connect
- Add testers in TestFlight
- They install via TestFlight app

### Via Ad Hoc (Sideloading):
- Use Apple Configurator 2
- Or third-party tools like AltStore
- Device must be in your provisioning profile

## Troubleshooting

### "No signing identity found"
- Make sure BUILD_CERTIFICATE_BASE64 is set correctly
- Certificate must be valid Apple Developer certificate

### "Provisioning profile doesn't match"
- Profile must include the app's bundle ID
- Profile must be for correct environment (Development/Distribution)

### Build succeeds but no IPA
- Check ExportOptions.plist settings
- Ensure signing is configured correctly

## Quick Test

To test without signing (creates unsigned IPA):
1. Remove certificate/profile steps from workflow
2. Add `-CODE_SIGNING_ALLOWED=NO` to build commands
3. IPA will work only in simulator

## Full Setup Checklist

- [ ] Set TEAM_ID secret
- [ ] Export and set BUILD_CERTIFICATE_BASE64
- [ ] Set P12_PASSWORD
- [ ] Set KEYCHAIN_PASSWORD
- [ ] Export and set BUILD_PROVISION_PROFILE_BASE64
- [ ] Push code to trigger build
- [ ] Download IPA from Actions artifacts
- [ ] Test installation
