#\!/bin/bash

# Build release version of Parchment
echo "Building Parchment release version..."

# Clean previous builds
rm -rf .build/release Parchment.app release

# Build release (simplified for single architecture)
swift build -c release

# Create app bundle
mkdir -p Parchment.app/Contents/{MacOS,Resources}

# Copy Info.plist
cp Info.plist Parchment.app/Contents/

# Copy executable
cp .build/release/Parchment Parchment.app/Contents/MacOS/

# Copy font if it exists
if [ -f "OpenDyslexic-Regular.otf" ]; then
    cp OpenDyslexic-Regular.otf Parchment.app/Contents/Resources/
    echo "Copied OpenDyslexic font to app bundle"
fi

# Get version from git tag or use date
VERSION=$(git describe --tags 2>/dev/null || echo "v1.0.0-$(date +%Y%m%d)")
echo "Version: $VERSION"

# Create release directory
mkdir -p release

# Create ZIP for distribution
echo "Creating ZIP..."
zip -r "release/Parchment-$VERSION.zip" Parchment.app -x "*.DS_Store"

echo ""
echo "Release build created:"
echo "  - release/Parchment-$VERSION.zip"
echo ""
echo "File size:"
ls -lh release/Parchment-$VERSION.zip

# Generate checksum
echo ""
echo "Checksum:"
shasum -a 256 release/Parchment-$VERSION.zip | tee release/checksums.txt
