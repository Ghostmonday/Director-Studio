# Code Signing Guide for DirectorStudio

## Local Development

### 1. Automatic Signing (Easiest)
- Open DirectorStudio.xcodeproj in Xcode
- Select DirectorStudio target → Signing & Capabilities
- Check "Automatically manage signing"
- Select your Team from dropdown
- Xcode handles certificates automatically

### 2. Manual Signing (More Control)
- Uncheck "Automatically manage signing"
- Select specific provisioning profiles
- Manage certificates manually in Keychain

## GitHub Actions CI/CD

To enable automated builds with signing on GitHub Actions:

### 1. Export Your Certificates
```bash
# Export your signing certificate
security find-identity -p codesigning -v

# Export to .p12 file
security export -k ~/Library/Keychains/login.keychain-db -t certs -f pkcs12 -o certificate.p12
```

### 2. Create GitHub Secrets
Go to your repository Settings → Secrets and add:
- `CERTIFICATES_P12` - Base64 encoded certificate
- `CERTIFICATES_PASSWORD` - Certificate password
- `PROVISIONING_PROFILE` - Base64 encoded .mobileprovision file
- `TEAM_ID` - Your Apple Developer Team ID

### 3. Update GitHub Actions Workflow
```yaml
- name: Install certificates
  env:
    CERTIFICATES_P12: ${{ secrets.CERTIFICATES_P12 }}
    CERTIFICATES_PASSWORD: ${{ secrets.CERTIFICATES_PASSWORD }}
    KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
  run: |
    # Create temporary keychain
    security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
    
    # Import certificate
    echo "$CERTIFICATES_P12" | base64 --decode > certificate.p12
    security import certificate.p12 -k build.keychain -P "$CERTIFICATES_PASSWORD" -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" build.keychain
```

## Common Issues

### "No signing certificate" error
- Make sure you've signed into Xcode with your Apple ID
- Check that your Apple ID has access to the development team

### "Provisioning profile doesn't match" error
- Update your bundle identifier to be unique
- Regenerate provisioning profiles in Apple Developer portal

### GitHub Actions build fails with signing
- Disable code signing for CI builds: add `-CODE_SIGNING_ALLOWED=NO` to xcodebuild command
- Or set up proper certificate management as shown above

## Bundle Identifier Best Practices

Change from `com.directorstudio.app` to something unique:
- `com.yourname.directorstudio`
- `com.yourcompany.directorstudio`
- Use reverse domain notation

This ensures no conflicts with other developers.
