#!/bin/bash

echo "Testing Drag & Drop functionality..."

# Kill any existing Parchment instances
pkill -f Parchment || true

# Create test files
echo "# Test File 1" > test_drag1.md
echo "## This is the first test file" >> test_drag1.md

echo "# Test File 2" > test_drag2.md  
echo "## This is the second test file" >> test_drag2.md

echo "Created test files: test_drag1.md and test_drag2.md"

# Open the app first
open Parchment.app

sleep 2

# Now open a file by simulating what happens when dragged to dock icon
open -a Parchment.app test_drag1.md

echo ""
echo "Test complete! The app should now be open with test_drag1.md loaded."
echo ""
echo "To manually test drag & drop:"
echo "1. Drag test_drag2.md onto the Parchment window - should open the file"
echo "2. Drag test_drag2.md onto the Parchment icon in the Dock - should open the file"
echo "3. Drag multiple .md files onto the app icon - should open the first one"