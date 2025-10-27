#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📺 DirectorStudio App Logs - Live Terminal View"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ App is running on simulator"
echo "🎬 Now generate a video in the app and watch logs below:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Stream logs from the DirectorStudio app
xcrun simctl spawn booted log stream --predicate 'processImagePath CONTAINS "DirectorStudio"' --level debug --style compact 2>&1 | grep --line-buffered -E "🔧|💰|🔍|🎬|🔑|📤|📥|━|DEBUG|DEMO|Pollo|Supabase|tokens|Duration|prompt|Authorization|Status Code|video_url"

