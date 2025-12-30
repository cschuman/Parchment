#!/bin/bash

# Parchment CLI Uninstallation Script
# Removes the parchment command-line tool from /usr/local/bin

set -e

CLI_NAME="parchment"
INSTALL_DIR="/usr/local/bin"
CLI_PATH="$INSTALL_DIR/$CLI_NAME"

echo "🗑️  Parchment CLI Uninstaller"
echo "============================"
echo ""

# Check if CLI is installed
if [ ! -f "$CLI_PATH" ]; then
    echo "❌ parchment CLI not found at $CLI_PATH"
    echo "   Nothing to uninstall."
    exit 0
fi

# Check if we need sudo
if [ ! -w "$INSTALL_DIR" ]; then
    echo "⚠️  Need permission to remove from $INSTALL_DIR"
    echo "   You may be prompted for your password."
    echo ""
    NEED_SUDO=true
else
    NEED_SUDO=false
fi

# Remove the CLI
echo "🗑️  Removing parchment from $INSTALL_DIR..."
if [ "$NEED_SUDO" = true ]; then
    sudo rm -f "$CLI_PATH"
else
    rm -f "$CLI_PATH"
fi

# Verify removal
if [ ! -f "$CLI_PATH" ]; then
    echo "✅ Uninstallation successful!"
    echo ""
    echo "   The parchment CLI has been removed from your system."
else
    echo "❌ Failed to remove parchment CLI"
    exit 1
fi