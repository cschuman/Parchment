#!/bin/bash

echo "==================================="
echo "Development Code Signing for Parchment"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build the app first
echo -e "${YELLOW}Building app...${NC}"
./build_dev.sh

# Remove any existing signatures
echo -e "${YELLOW}Removing existing signatures...${NC}"
codesign --remove-signature Parchment.app 2>/dev/null || true

# Sign with ad-hoc signature for development
echo -e "${YELLOW}Signing app with ad-hoc signature...${NC}"
codesign --force --deep --sign - Parchment.app

# Verify the signature
echo -e "${YELLOW}Verifying signature...${NC}"
if codesign --verify --deep --strict --verbose=2 Parchment.app 2>&1; then
    echo -e "${GREEN}✓ App signed successfully${NC}"
else
    echo -e "${RED}✗ Signature verification failed${NC}"
    exit 1
fi

# Check signature details
echo -e "${YELLOW}Signature details:${NC}"
codesign -dv Parchment.app 2>&1 | grep -E "Signature|Identifier|TeamIdentifier"

# Copy to Applications if requested
if [[ "$1" == "--install" ]]; then
    echo -e "${YELLOW}Installing to /Applications...${NC}"
    rm -rf /Applications/Parchment.app 2>/dev/null || true
    cp -r Parchment.app /Applications/
    echo -e "${GREEN}✓ Installed to /Applications/Parchment.app${NC}"
    
    # Reset Launch Services
    echo -e "${YELLOW}Resetting Launch Services...${NC}"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Parchment.app
    echo -e "${GREEN}✓ Launch Services updated${NC}"
fi

echo -e "${GREEN}==================================="
echo -e "Development signing complete!"
echo -e "===================================${NC}"
echo ""
echo "To install to /Applications and reset Launch Services:"
echo "  ./sign_dev.sh --install"
echo ""
echo "Note: This is an ad-hoc signature for development only."
echo "For distribution, you'll need an Apple Developer certificate."