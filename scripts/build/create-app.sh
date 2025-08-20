#!/bin/bash

echo "Building Parchment app bundle..."

# Build in release mode
swift build -c release

# Create app bundle structure
APP_NAME="Parchment"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Clean previous build
rm -rf "$APP_BUNDLE"

# Create directories
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy executable
cp ./.build/release/Parchment "$MACOS/$APP_NAME"

# Create Info.plist
cat > "$CONTENTS/Info.plist" << EOF
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
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>md</string>
                <string>markdown</string>
            </array>
            <key>CFBundleTypeName</key>
            <string>Markdown Document</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
        </dict>
    </array>
</dict>
</plist>
EOF

echo "App bundle created: $APP_BUNDLE"
echo ""
echo "You can now:"
echo "1. Double-click $APP_BUNDLE in Finder"
echo "2. Run: open $APP_BUNDLE"
echo "3. Run with a file: open $APP_BUNDLE --args test.md"
echo "4. Move to Applications: mv $APP_BUNDLE /Applications/"