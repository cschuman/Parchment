#!/bin/bash

echo "Building Parchment in safe mode..."

# Compile safe mode version
swiftc -o Parchment_safe \
    -import-objc-header Sources/Parchment/BridgingHeader.h \
    Sources/Parchment/safe_main.swift \
    Sources/Parchment/App/SafeAppDelegate.swift \
    -framework Cocoa \
    -framework Foundation

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Run with: ./Parchment_safe test.md"
else
    echo "Build failed"
    exit 1
fi