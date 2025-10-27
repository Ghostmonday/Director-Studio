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

# Try all log files
LOG_FILE1="$DATA_DIR/Documents/segmentation_debug.txt"
LOG_FILE2="$DATA_DIR/Documents/debug_logs.txt"
LOG_FILE3="$DATA_DIR/Documents/segmentation_error.txt"
LOG_FILE4="$DATA_DIR/Documents/test_log.txt"

LOG_FILE=""
if [ -f "$LOG_FILE3" ]; then
    LOG_FILE="$LOG_FILE3"  # Error log takes priority
elif [ -f "$LOG_FILE1" ]; then
    LOG_FILE="$LOG_FILE1"
elif [ -f "$LOG_FILE2" ]; then
    LOG_FILE="$LOG_FILE2"
elif [ -f "$LOG_FILE4" ]; then
    LOG_FILE="$LOG_FILE4"
fi

if [ -z "$LOG_FILE" ]; then
    echo "❌ No log files found in: $DATA_DIR/Documents/"
    echo "💡 Looking for:"
    echo "   - segmentation_debug.txt"
    echo "   - debug_logs.txt"
    echo ""
    echo "📁 Files in Documents:"
    ls -la "$DATA_DIR/Documents/" 2>/dev/null || echo "   (empty)"
    exit 1
fi

echo "📖 Reading logs from: $LOG_FILE"
echo ""
echo "============================================================"
cat "$LOG_FILE"
echo "============================================================"
echo ""
echo "✅ Log file location: $LOG_FILE"

