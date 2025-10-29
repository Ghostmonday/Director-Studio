#!/bin/bash

# DirectorStudio Console Log Monitor for Segmentation
# This script filters and displays segmentation-related logs from the simulator console

echo "🎬 DirectorStudio Segmentation Console Monitor"
echo "=============================================="
echo ""
echo "Watching for segmentation logs..."
echo "(Look for [SegmentingModule] tags)"
echo ""

# Watch simulator logs and filter for segmentation-related messages
xcrun simctl spawn 6C5BC2B5-8443-409F-9FF1-36AE045B2D9F log stream --level debug --style compact | grep -E "(SegmentingModule|SEGMENTATION|segment|Script|Clip|LLM|AI Mode|Duration Mode|Validation|Pipeline)" --color=always
