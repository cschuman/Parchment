#!/bin/bash

echo "Building Parchment for Release..."

# Build in release mode
swift build -c release

# Create app bundle structure
APP_NAME="Parchment"
APP_BUNDLE="$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Clean and create directories
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy executable
cp ".build/release/$APP_NAME" "$MACOS/$APP_NAME"

# Copy icon
cp Parchment.icns "$RESOURCES/" 2>/dev/null || cp MarkdownViewer.icns "$RESOURCES/"

# Create Info.plist
cat > "$CONTENTS/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Parchment</string>
    <key>CFBundleIdentifier</key>
    <string>com.corey.Parchment</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
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
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleIconFile</key>
    <string>Parchment</string>
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
            <key>LSItemContentTypes</key>
            <array>
                <string>net.daringfireball.markdown</string>
            </array>
        </dict>
    </array>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 Corey. All rights reserved.</string>
</dict>
</plist>
EOF

# Make executable
chmod +x "$MACOS/$APP_NAME"

echo "✅ Release build created: $APP_BUNDLE"
echo ""
echo "Features included:"
echo "  ✅ Native Swift/AppKit implementation"
echo "  ✅ Inline formatting (bold, italic, code, links, strikethrough)"
echo "  ✅ Tables with headers and data cells"
echo "  ✅ Image support (local + remote with caching)"
echo "  ✅ Syntax highlighting (Swift, JavaScript, Python, etc.)"
echo "  ✅ Table of Contents with navigation"
echo "  ✅ Focus Mode and reading statistics"
echo "  ✅ Live file watching and updates"
echo "  ✅ Export to PDF/HTML/RTF/DOCX"
echo "  ✅ Wiki-links and backlinks support"
echo "  ✅ Zoom controls and keyboard shortcuts"
echo "  ✅ Custom app icon"
echo ""
echo "Ready for distribution! 🚀"