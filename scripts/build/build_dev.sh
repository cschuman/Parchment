#!/bin/bash

echo "Building Parchment (debug mode)..."

# Build in debug mode (faster)
swift build

# Create app bundle structure if it doesn't exist
mkdir -p Parchment.app/Contents/{MacOS,Resources}

# Copy Info.plist
cp Info.plist Parchment.app/Contents/

# Copy executable
cp .build/debug/Parchment Parchment.app/Contents/MacOS/Parchment

# Copy fonts to Resources
if [ -f Resources/Fonts/OpenDyslexic-Regular.otf ]; then
    cp Resources/Fonts/OpenDyslexic-Regular.otf Parchment.app/Contents/Resources/
    echo "Copied OpenDyslexic font to app bundle"
fi

echo "Updated app bundle with debug build"
echo "Run with: open Parchment.app"