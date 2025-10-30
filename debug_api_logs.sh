#!/bin/bash
# Debug API Logs Viewer
# This script shows the latest API request/response logs from DirectorStudio

# Try Desktop first, then simulator Documents directory
DESKTOP_LOG="$HOME/Desktop/directorstudio_api_debug.log"
SIMULATOR_ID="78B798D0-18BF-4036-A4B4-48F920CA2EED"
SIMULATOR_LOG="$HOME/Library/Developer/CoreSimulator/Devices/$SIMULATOR_ID/data/Containers/Data/Application/*/Documents/api_debug.log"

# Find the actual log file
LOG_FILE=""
if [ -f "$DESKTOP_LOG" ]; then
    LOG_FILE="$DESKTOP_LOG"
elif ls $SIMULATOR_LOG 1> /dev/null 2>&1; then
    LOG_FILE=$(ls -t $SIMULATOR_LOG | head -1)
else
    echo "❌ Log file not found. Trying to locate..."
    # Try to find any api_debug.log file
    LOG_FILE=$(find ~/Library/Developer/CoreSimulator/Devices -name "api_debug.log" 2>/dev/null | head -1)
fi

if [ -z "$LOG_FILE" ] || [ ! -f "$LOG_FILE" ]; then
    echo "❌ No log file found."
    echo "Please start the app and make an API request first."
    exit 1
fi

echo "📋 DirectorStudio API Debug Logs"
echo "================================"
echo ""
echo "File: $LOG_FILE"
echo "Last updated: $(stat -f "%Sm" "$LOG_FILE" 2>/dev/null || stat -c "%y" "$LOG_FILE" 2>/dev/null || echo "N/A")"
echo ""
echo "--- Latest 100 lines ---"
echo ""

tail -n 100 "$LOG_FILE" 2>/dev/null || cat "$LOG_FILE"

echo ""
echo "--- End of log ---"
echo ""
echo "To follow logs in real-time, run: tail -f \"$LOG_FILE\""

