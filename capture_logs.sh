#!/bin/bash

# DirectorStudio Log Capture Script
# Captures logs from simulator to file for easy reading

echo "📱 Capturing DirectorStudio logs from simulator..."
echo "📝 Logs will be saved to: director_studio_logs.txt"
echo "🛑 Press Ctrl+C to stop capturing"
echo ""
echo "=== LOG CAPTURE STARTED: $(date) ===" > director_studio_logs.txt

# Capture logs from the simulator
xcrun simctl spawn 12673044-36F5-49BF-9242-4BE668CAC291 log stream --predicate 'processImagePath CONTAINS "DirectorStudio"' | tee -a director_studio_logs.txt

