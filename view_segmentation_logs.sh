#!/bin/bash

# DirectorStudio Segmentation Log Viewer
# This script displays real-time logs from the segmenting module

echo "🎬 DirectorStudio Segmentation Log Viewer"
echo "=========================================="
echo ""

# Get the log file path
LOG_FILE="$HOME/Library/Developer/CoreSimulator/Devices/6C5BC2B5-8443-409F-9FF1-36AE045B2D9F/data/Containers/Data/Application/*/Documents/segmentation_debug.txt"

# Function to find the actual log file
find_log_file() {
    local found_file=$(ls $LOG_FILE 2>/dev/null | head -n 1)
    echo "$found_file"
}

# Wait for log file to exist
echo "🔍 Looking for segmentation log file..."
while true; do
    ACTUAL_LOG_FILE=$(find_log_file)
    if [ -n "$ACTUAL_LOG_FILE" ] && [ -f "$ACTUAL_LOG_FILE" ]; then
        echo "✅ Found log file: $ACTUAL_LOG_FILE"
        echo ""
        break
    fi
    sleep 1
done

# Display existing logs
echo "📜 Existing logs:"
echo "===================="
cat "$ACTUAL_LOG_FILE"
echo ""
echo "📡 Watching for new logs..."
echo "===================="

# Watch for new logs
tail -f "$ACTUAL_LOG_FILE"
