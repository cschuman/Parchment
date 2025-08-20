#!/bin/bash

echo "==================================="
echo "Signing with Xcode Certificate"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# The certificate name we found
CERT_NAME="Apple Development: Corey Schuman (TT8WDUPS38)"

echo -e "${YELLOW}Found certificate: $CERT_NAME${NC}"
echo ""

# First, let's try to unlock the keychain if needed
echo -e "${YELLOW}Unlocking keychain (you may need to enter your password)...${NC}"
security unlock-keychain ~/Library/Keychains/login.keychain-db

# Build the app
echo -e "${YELLOW}Building app...${NC}"
./build_dev.sh

# Try to sign with the certificate
echo -e "${YELLOW}Attempting to sign with Xcode certificate...${NC}"

# Remove old signature
codesign --remove-signature Parchment.app 2>/dev/null || true

# Try signing with the certificate
if codesign --force --deep --sign "$CERT_NAME" Parchment.app 2>&1; then
    echo -e "${GREEN}✓ Successfully signed with Xcode certificate!${NC}"
    
    # Verify signature
    echo -e "${YELLOW}Verifying signature...${NC}"
    codesign -dv Parchment.app 2>&1 | grep -E "Signature|Identifier|TeamIdentifier"
    
    # Install to Applications
    echo -e "${YELLOW}Installing to /Applications...${NC}"
    rm -rf /Applications/Parchment.app 2>/dev/null || true
    cp -r Parchment.app /Applications/
    
    # Reset Launch Services
    echo -e "${YELLOW}Resetting Launch Services...${NC}"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Parchment.app
    
    echo -e "${GREEN}✓ Installation complete!${NC}"
    echo -e "${GREEN}✓ Drag & drop to Dock should now work!${NC}"
    
    # Kill and restart the app
    pkill -f Parchment || true
    sleep 1
    open /Applications/Parchment.app
    
else
    echo -e "${RED}✗ Signing failed${NC}"
    echo ""
    echo "This might mean the private key is missing or not accessible."
    echo ""
    echo "Try these steps:"
    echo "1. Open Xcode"
    echo "2. Go to Settings → Accounts"
    echo "3. Select your Apple ID"
    echo "4. Click 'Manage Certificates'"
    echo "5. If you see a certificate with a missing private key (no key icon):"
    echo "   - Delete it (right-click → Delete)"
    echo "   - Click '+' → 'Apple Development' to create a new one"
    echo ""
    echo "Alternative: Try signing with your Apple ID directly:"
    echo "  xcrun codesign --force --deep --sign 'Apple Development: your.email@example.com' Parchment.app"
fi