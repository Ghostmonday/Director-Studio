#!/bin/bash
# Script to read debug logs from the simulator

SIMULATOR_ID="12673044-36F5-49BF-9242-4BE668CAC291"
APP_ID="com.directorstudio.app"

# Find the app's data directory
DATA_DIR=$(xcrun simctl get_app_container $SIMULATOR_ID $APP_ID data 2>/dev/null)

if [ -z "$DATA_DIR" ]; then
    echo "❌ Could not find app data directory. Is the app installed?"
    exit 1
fi

LOG_FILE="$DATA_DIR/Documents/debug_logs.txt"

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Log file not found at: $LOG_FILE"
    echo "💡 Try running the app first to generate logs"
    exit 1
fi

echo "📖 Reading logs from: $LOG_FILE"
echo ""
echo "============================================================"
cat "$LOG_FILE"
echo "============================================================"
echo ""
echo "✅ Log file location: $LOG_FILE"

