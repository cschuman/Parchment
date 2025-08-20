#!/bin/bash

# Launch Parchment with environment variables to disable Touch Bar
# This may help work around the Touch Bar crash on macOS 15.4 beta

echo "Launching Parchment with Touch Bar disabled..."

# Set environment variables to disable Touch Bar
export NSApplicationTouchBarEnabled=false
export NSWindowAllowsAutomaticWindowTabbing=NO

# Change to app directory
cd "$(dirname "$0")"

# Launch the app directly
if [ -f "Parchment.app/Contents/MacOS/Parchment" ]; then
    # If a file argument is provided, pass it to the app
    if [ "$1" != "" ]; then
        ./Parchment.app/Contents/MacOS/Parchment "$1" 2>&1 | tee markdown_viewer.log
    else
        ./Parchment.app/Contents/MacOS/Parchment 2>&1 | tee markdown_viewer.log
    fi
else
    echo "Error: Parchment.app not found!"
    echo "Please run ./build_app_debug.sh first"
    exit 1
fi