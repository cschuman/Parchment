#!/bin/bash
# Alfred script to open markdown file in Parchment

FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
    echo "No file specified"
    exit 1
fi

# Check if Parchment is installed
if [ -d "/Applications/Parchment.app" ]; then
    open -a Parchment "$FILE_PATH"
elif command -v parchment &> /dev/null; then
    parchment "$FILE_PATH"
else
    echo "Parchment is not installed"
    exit 1
fi
