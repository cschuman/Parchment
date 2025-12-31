#!/bin/bash
# Update Homebrew formula SHA256 hashes for a new release
# Usage: ./update-formula.sh v2.0.0

set -euo pipefail

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 v2.0.0"
    exit 1
fi

# Remove 'v' prefix if present for consistency
VERSION_NUM="${VERSION#v}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMULA_FILE="$SCRIPT_DIR/parchment.rb"
CASK_FILE="$SCRIPT_DIR/Casks/parchment.rb"

echo "Updating formulas for version $VERSION_NUM..."

# URLs for downloads
SOURCE_URL="https://github.com/cschuman/Parchment/archive/refs/tags/v${VERSION_NUM}.tar.gz"
CASK_URL="https://github.com/cschuman/Parchment/releases/download/v${VERSION_NUM}/Parchment-v${VERSION_NUM}.zip"

# Download and compute SHA256 for source tarball
echo "Fetching source tarball SHA256..."
if command -v curl &> /dev/null; then
    SOURCE_SHA=$(curl -sL "$SOURCE_URL" | shasum -a 256 | cut -d' ' -f1)
elif command -v wget &> /dev/null; then
    SOURCE_SHA=$(wget -qO- "$SOURCE_URL" | shasum -a 256 | cut -d' ' -f1)
else
    echo "Error: curl or wget required"
    exit 1
fi

if [[ -z "$SOURCE_SHA" || "$SOURCE_SHA" == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]]; then
    echo "Warning: Could not fetch source tarball (may not exist yet)"
    echo "Using placeholder hash. Update manually after release."
    SOURCE_SHA="PLACEHOLDER_SHA256_HASH_UPDATE_ON_RELEASE"
else
    echo "Source SHA256: $SOURCE_SHA"
fi

# Download and compute SHA256 for cask zip
echo "Fetching cask zip SHA256..."
if command -v curl &> /dev/null; then
    CASK_SHA=$(curl -sL "$CASK_URL" | shasum -a 256 | cut -d' ' -f1)
elif command -v wget &> /dev/null; then
    CASK_SHA=$(wget -qO- "$CASK_URL" | shasum -a 256 | cut -d' ' -f1)
fi

if [[ -z "$CASK_SHA" || "$CASK_SHA" == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]]; then
    echo "Warning: Could not fetch cask zip (may not exist yet)"
    echo "Using placeholder hash. Update manually after release."
    CASK_SHA="PLACEHOLDER_SHA256_HASH_UPDATE_ON_RELEASE"
else
    echo "Cask SHA256: $CASK_SHA"
fi

# Update formula file
if [[ -f "$FORMULA_FILE" ]]; then
    echo "Updating $FORMULA_FILE..."
    sed -i.bak "s|url \"https://github.com/cschuman/Parchment/archive/refs/tags/v[^\"]*\"|url \"https://github.com/cschuman/Parchment/archive/refs/tags/v${VERSION_NUM}.tar.gz\"|" "$FORMULA_FILE"
    sed -i.bak "s|sha256 \"[^\"]*\"|sha256 \"${SOURCE_SHA}\"|" "$FORMULA_FILE"
    rm -f "$FORMULA_FILE.bak"
fi

# Update cask file
if [[ -f "$CASK_FILE" ]]; then
    echo "Updating $CASK_FILE..."
    sed -i.bak "s|version \"[^\"]*\"|version \"${VERSION_NUM}\"|" "$CASK_FILE"
    sed -i.bak "s|sha256 \"[^\"]*\"|sha256 \"${CASK_SHA}\"|" "$CASK_FILE"
    rm -f "$CASK_FILE.bak"
fi

echo ""
echo "Formula files updated for version $VERSION_NUM"
echo ""
echo "Next steps:"
echo "1. Create GitHub release with tag v$VERSION_NUM"
echo "2. Upload Parchment-v${VERSION_NUM}.zip to the release"
echo "3. Re-run this script to update SHA256 hashes"
echo "4. Submit PR to homebrew-core (formula) and homebrew-cask (cask)"
