#!/bin/bash

echo "==================================="
echo "Release Code Signing for Parchment"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for signing identity
echo -e "${YELLOW}Checking for signing identities...${NC}"
IDENTITIES=$(security find-identity -v -p codesigning | grep -E "Developer ID Application|Apple Development" | head -1)

if [[ -z "$IDENTITIES" ]]; then
    echo -e "${RED}No signing identity found!${NC}"
    echo ""
    echo "To create a signing identity:"
    echo "1. For free development certificate:"
    echo "   - Open Xcode → Preferences → Accounts"
    echo "   - Add your Apple ID and create certificate"
    echo ""
    echo "2. For distribution certificate ($99/year):"
    echo "   - Join Apple Developer Program"
    echo "   - Create Developer ID certificate"
    echo ""
    exit 1
fi

# Extract identity
IDENTITY=$(echo "$IDENTITIES" | sed -n 's/.*"\(.*\)".*/\1/p')
echo -e "${GREEN}Found identity: $IDENTITY${NC}"

# Build release version
echo -e "${YELLOW}Building release version...${NC}"
./build_release.sh

# Remove any existing signatures
echo -e "${YELLOW}Removing existing signatures...${NC}"
codesign --remove-signature Parchment.app 2>/dev/null || true

# Sign with proper identity and entitlements
echo -e "${YELLOW}Signing app with Developer ID...${NC}"
if codesign --force --deep \
    --sign "$IDENTITY" \
    --options runtime \
    --entitlements entitlements.plist \
    --timestamp \
    Parchment.app; then
    echo -e "${GREEN}✓ App signed successfully${NC}"
else
    echo -e "${RED}✗ Signing failed${NC}"
    exit 1
fi

# Verify the signature
echo -e "${YELLOW}Verifying signature...${NC}"
if codesign --verify --deep --strict --verbose=2 Parchment.app 2>&1; then
    echo -e "${GREEN}✓ Signature verified${NC}"
else
    echo -e "${RED}✗ Signature verification failed${NC}"
    exit 1
fi

# Check Gatekeeper
echo -e "${YELLOW}Checking Gatekeeper acceptance...${NC}"
if spctl -a -t exec -vvv Parchment.app 2>&1 | grep -q "accepted"; then
    echo -e "${GREEN}✓ App will be accepted by Gatekeeper${NC}"
else
    echo -e "${YELLOW}⚠ App may need notarization for Gatekeeper${NC}"
fi

# Show signature details
echo -e "${YELLOW}Signature details:${NC}"
codesign -dv --verbose=4 Parchment.app 2>&1 | grep -E "Authority|TeamIdentifier|Signature|Timestamp"

echo -e "${GREEN}==================================="
echo -e "Release signing complete!"
echo -e "===================================${NC}"
echo ""
echo "Next steps:"
echo "1. Test the app thoroughly"
echo "2. For distribution outside App Store:"
echo "   - Notarize the app with Apple"
echo "   - Create DMG for distribution"
echo ""
echo "To notarize (requires Apple Developer account):"
echo "  xcrun notarytool submit Parchment.zip --apple-id YOUR_APPLE_ID --wait"
echo "  xcrun stapler staple Parchment.app"