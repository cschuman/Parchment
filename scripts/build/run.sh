#!/bin/bash

# Build the app in release mode for better performance
echo "Building Parchment..."
swift build -c release

# Run the app
echo "Launching Parchment..."
./.build/release/Parchment "$@"