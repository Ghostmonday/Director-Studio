#!/bin/bash
# Auto-relaunch script for DirectorStudio app
# Usage: ./relaunch_app.sh

set -e

SIMULATOR_ID="327D271A-F817-45CA-957D-6CF33C2508C9"
APP_BUNDLE_ID="com.directorstudio.app"
PROJECT_DIR="/Users/user944529/Desktop/Director-Studio"

cd "$PROJECT_DIR"

echo "🔄 Relaunching DirectorStudio app..."

# Kill previous instance
echo "⏹️  Stopping previous app instance..."
pkill -f "simctl launch.*$APP_BUNDLE_ID" 2>/dev/null || true

# Boot simulator if needed
echo "📱 Booting simulator..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || echo "   Simulator already booted"

# Build
echo "🔨 Building app..."
xcodebuild -project DirectorStudio.xcodeproj \
  -scheme DirectorStudio \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -derivedDataPath ./DerivedData \
  build 2>&1 | grep -E "(BUILD|error:)" | tail -3

# Install
echo "📦 Installing app..."
xcrun simctl install "$SIMULATOR_ID" \
  ./DerivedData/Build/Products/Debug-iphonesimulator/DirectorStudio.app

# Launch
echo "🚀 Launching app..."
xcrun simctl launch --console "$SIMULATOR_ID" "$APP_BUNDLE_ID" 2>&1 &

echo "✅ App relaunched successfully!"
echo "   Simulator ID: $SIMULATOR_ID"
echo "   Bundle ID: $APP_BUNDLE_ID"

