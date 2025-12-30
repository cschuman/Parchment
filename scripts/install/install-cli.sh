#!/bin/bash

# Parchment CLI Installation Script
# Installs the parchment command-line tool to /usr/local/bin

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLI_NAME="parchment"
INSTALL_DIR="/usr/local/bin"
BUILD_DIR="$SCRIPT_DIR/.build/debug"

echo "📦 Parchment CLI Installer"
echo "=========================="
echo ""

# Check if running with sufficient permissions
if [ ! -w "$INSTALL_DIR" ]; then
    echo "⚠️  Need permission to install to $INSTALL_DIR"
    echo "   You may be prompted for your password."
    echo ""
    NEED_SUDO=true
else
    NEED_SUDO=false
fi

# Build the CLI tool
echo "🔨 Building parchment CLI..."
swift build --product parchment

if [ ! -f "$BUILD_DIR/$CLI_NAME" ]; then
    echo "❌ Build failed. CLI binary not found at $BUILD_DIR/$CLI_NAME"
    exit 1
fi

# Create /usr/local/bin if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "📁 Creating $INSTALL_DIR directory..."
    if [ "$NEED_SUDO" = true ]; then
        sudo mkdir -p "$INSTALL_DIR"
    else
        mkdir -p "$INSTALL_DIR"
    fi
fi

# Install the CLI
echo "📥 Installing parchment to $INSTALL_DIR..."
if [ "$NEED_SUDO" = true ]; then
    sudo cp "$BUILD_DIR/$CLI_NAME" "$INSTALL_DIR/$CLI_NAME"
    sudo chmod +x "$INSTALL_DIR/$CLI_NAME"
else
    cp "$BUILD_DIR/$CLI_NAME" "$INSTALL_DIR/$CLI_NAME"
    chmod +x "$INSTALL_DIR/$CLI_NAME"
fi

# Verify installation
if command -v parchment &> /dev/null; then
    echo "✅ Installation successful!"
    echo ""
    echo "🎉 You can now use 'parchment' from anywhere in your terminal:"
    echo "   parchment README.md"
    echo "   parchment docs/"
    echo "   parchment --help"
else
    echo "⚠️  Installation completed but 'parchment' is not in your PATH"
    echo "   Add $INSTALL_DIR to your PATH:"
    echo ""
    echo "   For zsh (default on macOS):"
    echo "   echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.zshrc"
    echo "   source ~/.zshrc"
    echo ""
    echo "   For bash:"
    echo "   echo 'export PATH=\"$INSTALL_DIR:\$PATH\"' >> ~/.bash_profile"
    echo "   source ~/.bash_profile"
fi

echo ""
echo "📚 Run 'parchment --help' for usage information"