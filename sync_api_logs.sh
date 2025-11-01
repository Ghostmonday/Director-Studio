#!/bin/bash
# Sync API debug logs to a consistent location for easy access
# This copies the latest log file to ~/Desktop/directorstudio_api_logs_latest.txt

DESKTOP_LOG="$HOME/Desktop/directorstudio_api_debug.log"
SIMULATOR_LOG=$(find ~/Library/Developer/CoreSimulator/Devices -name "api_debug.log" -type f 2>/dev/null | sort -r | head -1)
SYNCED_LOG="$HOME/Desktop/directorstudio_api_logs_latest.txt"

# Find the most recent log file
SOURCE_LOG=""
if [ -f "$DESKTOP_LOG" ]; then
    SOURCE_LOG="$DESKTOP_LOG"
elif [ -n "$SIMULATOR_LOG" ] && [ -f "$SIMULATOR_LOG" ]; then
    SOURCE_LOG="$SIMULATOR_LOG"
else
    echo "⚠️  No log file found"
    exit 1
fi

# Copy latest content to synced file
if [ -f "$SOURCE_LOG" ]; then
    cp "$SOURCE_LOG" "$SYNCED_LOG"
    echo "✅ Synced log file: $SYNCED_LOG"
    echo "   Source: $SOURCE_LOG"
    echo "   Size: $(wc -l < "$SYNCED_LOG") lines"
else
    echo "❌ Source log file not found: $SOURCE_LOG"
    exit 1
fi


