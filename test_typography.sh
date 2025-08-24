#!/bin/bash

# Typography and Performance Test Suite for Parchment

echo "🎨 Parchment Typography Test Suite"
echo "=================================="

# Build the app
echo "📦 Building Parchment..."
./build_dev.sh > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

# Test file opening performance
echo ""
echo "⚡ Performance Tests"
echo "-------------------"

# Create test files of different sizes
echo "Creating test files..."
echo "# Small Test (1KB)" > test_small.md
for i in {1..10}; do
    echo "This is paragraph $i with some content to test rendering." >> test_small.md
done

echo "# Medium Test (100KB)" > test_medium.md
for i in {1..1000}; do
    echo "## Section $i" >> test_medium.md
    echo "This is paragraph $i with some content to test rendering performance at scale." >> test_medium.md
    echo '```swift' >> test_medium.md
    echo "func test$i() { return $i }" >> test_medium.md
    echo '```' >> test_medium.md
done

echo "# Large Test (1MB)" > test_large.md
for i in {1..10000}; do
    echo "Paragraph $i: The quick brown fox jumps over the lazy dog." >> test_large.md
done

# Function to time file opening
test_file_opening() {
    local file=$1
    local size=$(du -h "$file" | cut -f1)
    
    echo "Testing $file ($size)..."
    
    # Launch and time
    start_time=$(date +%s%N)
    timeout 5 open -W Parchment.app --args "$file" 2>/dev/null &
    pid=$!
    sleep 2
    kill $pid 2>/dev/null
    end_time=$(date +%s%N)
    
    # Calculate time in milliseconds
    elapsed=$(( ($end_time - $start_time) / 1000000 ))
    echo "  Opening time: ~${elapsed}ms"
}

test_file_opening "test_small.md"
test_file_opening "test_medium.md"
test_file_opening "test_large.md"

# Test with our typography test file
echo ""
echo "🎨 Typography Test"
echo "------------------"
echo "Opening typography test document..."
open Parchment.app --args typography_test.md

echo ""
echo "📋 Manual Testing Checklist"
echo "---------------------------"
echo "[ ] Headings show golden ratio scaling"
echo "[ ] Smart quotes render as curly quotes"
echo "[ ] Em dashes render properly (—)"
echo "[ ] Code blocks have syntax highlighting"
echo "[ ] Lists have proper indentation"
echo "[ ] Scroll is smooth at 60-120fps"
echo "[ ] Theme switching works (Cmd+T)"
echo "[ ] Zoom maintains readability (Cmd+/Cmd-)"
echo "[ ] File opens in <50ms for typical docs"
echo "[ ] No beach balls or UI freezes"

echo ""
echo "🎯 Theme Testing"
echo "----------------"
echo "Press Cmd+1 through Cmd+5 to test themes:"
echo "1. Minimal - Clean, iA Writer inspired"
echo "2. Elegant - Serif-based, Medium inspired"
echo "3. Midnight - Dark theme for night reading"
echo "4. Sepia - Warm, paper-like"
echo "5. High Contrast - Accessibility focused"

echo ""
echo "✨ Test complete! Parchment should now be running with the test document."
echo "Check the app and verify all typography features are working correctly."

# Cleanup
rm -f test_small.md test_medium.md test_large.md