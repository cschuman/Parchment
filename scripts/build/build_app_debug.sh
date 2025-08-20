#!/bin/bash

echo "Building Parchment app (debug)..."

# Build in debug mode (faster)
swift build

# Variables
EXECUTABLE_NAME="Parchment"
BUNDLE_NAME="Parchment.app"
BUILD_DIR=".build/debug"
EXECUTABLE_PATH="$BUILD_DIR/$EXECUTABLE_NAME"

# Remove old app bundle if it exists
rm -rf "$BUNDLE_NAME"

# Create app bundle structure
mkdir -p "$BUNDLE_NAME/Contents/MacOS"
mkdir -p "$BUNDLE_NAME/Contents/Resources"

# Copy executable
cp "$EXECUTABLE_PATH" "$BUNDLE_NAME/Contents/MacOS/"

# Create Info.plist
cat > "$BUNDLE_NAME/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Parchment</string>
    <key>CFBundleIdentifier</key>
    <string>com.coreymd.markdownviewer</string>
    <key>CFBundleName</key>
    <string>Parchment</string>
    <key>CFBundleDisplayName</key>
    <string>Parchment</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>md</string>
                <string>markdown</string>
                <string>txt</string>
            </array>
            <key>CFBundleTypeName</key>
            <string>Markdown Document</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Default</string>
        </dict>
    </array>
</dict>
</plist>
EOF

echo "App bundle created: $BUNDLE_NAME"
echo "To run: open $BUNDLE_NAME"