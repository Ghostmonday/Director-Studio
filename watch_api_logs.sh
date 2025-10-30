#!/bin/bash
# Watch API debug logs in real-time

echo "🔍 Watching API debug logs..."
echo "📁 Log files:"
echo "   - ~/Documents/api_debug.log"
echo "   - ~/Desktop/directorstudio_api_debug.log"
echo ""
echo "Press Ctrl+C to stop"
echo "================================"
echo ""

# Watch both log files
tail -f ~/Documents/api_debug.log ~/Desktop/directorstudio_api_debug.log 2>/dev/null | grep --line-buffered -E "(🚀|🔑|📥|❌|✅|🔄|💡|🌐)" || {
    echo "⚠️  Log files not found yet. Waiting for app to start..."
    while [ ! -f ~/Documents/api_debug.log ] && [ ! -f ~/Desktop/directorstudio_api_debug.log ]; do
        sleep 1
    done
    echo "✅ Log file detected! Watching..."
    tail -f ~/Documents/api_debug.log ~/Desktop/directorstudio_api_debug.log 2>/dev/null
}

