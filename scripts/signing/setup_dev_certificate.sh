#!/bin/bash

echo "==================================="
echo "Development Certificate Setup Guide"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Xcode is not installed!${NC}"
    echo "Please install Xcode from the Mac App Store first."
    exit 1
fi

echo -e "${GREEN}✓ Xcode is installed${NC}"

# Check current identities
echo -e "\n${YELLOW}Current code signing identities:${NC}"
IDENTITIES=$(security find-identity -v -p codesigning 2>&1)
if echo "$IDENTITIES" | grep -q "0 valid identities found"; then
    echo -e "${RED}No signing identities found${NC}"
    NEEDS_CERT=true
else
    echo "$IDENTITIES"
    echo -e "\n${YELLOW}Do you want to create a new certificate anyway? (y/n)${NC}"
    read -r response
    if [[ "$response" != "y" ]]; then
        NEEDS_CERT=false
    else
        NEEDS_CERT=true
    fi
fi

if [[ "$NEEDS_CERT" == true ]]; then
    echo -e "\n${BLUE}Steps to create a free development certificate:${NC}"
    echo ""
    echo "1. Open Xcode"
    echo "   ${YELLOW}Run: open -a Xcode${NC}"
    echo ""
    echo "2. Go to Xcode menu → Settings (or Preferences on older versions)"
    echo ""
    echo "3. Click the 'Accounts' tab"
    echo ""
    echo "4. Click '+' button to add your Apple ID"
    echo "   - Enter your Apple ID email"
    echo "   - Enter your password"
    echo "   - Complete 2FA if required"
    echo ""
    echo "5. Select your Apple ID in the list"
    echo ""
    echo "6. Click 'Manage Certificates...'"
    echo ""
    echo "7. Click '+' button and select 'Apple Development'"
    echo ""
    echo "8. Xcode will create and install the certificate"
    echo ""
    echo -e "${GREEN}After completing these steps, run this command again to verify.${NC}"
    echo ""
    echo -e "${YELLOW}Opening Xcode now...${NC}"
    open -a Xcode
    
    echo -e "\n${BLUE}Once you've created the certificate, you can sign Parchment with:${NC}"
    echo "  ./sign_with_xcode_cert.sh"
fi

# If certificate exists, offer to sign the app
if [[ "$NEEDS_CERT" == false ]]; then
    DEV_IDENTITY=$(echo "$IDENTITIES" | grep "Apple Development" | head -1 | sed -n 's/.*"\(.*\)".*/\1/p')
    
    if [[ -n "$DEV_IDENTITY" ]]; then
        echo -e "\n${GREEN}Found development identity: $DEV_IDENTITY${NC}"
        echo -e "\n${YELLOW}Do you want to sign Parchment with this certificate? (y/n)${NC}"
        read -r response
        
        if [[ "$response" == "y" ]]; then
            echo -e "\n${YELLOW}Signing Parchment...${NC}"
            
            # Build first
            ./build_dev.sh
            
            # Sign with the development certificate
            codesign --force --deep --sign "$DEV_IDENTITY" \
                --entitlements entitlements.plist \
                Parchment.app
            
            # Verify
            if codesign --verify --deep --strict Parchment.app 2>&1; then
                echo -e "${GREEN}✓ Successfully signed Parchment!${NC}"
                
                echo -e "\n${YELLOW}Installing to /Applications...${NC}"
                rm -rf /Applications/Parchment.app 2>/dev/null || true
                cp -r Parchment.app /Applications/
                
                # Reset Launch Services
                /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
                /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Parchment.app
                
                echo -e "${GREEN}✓ Installed and registered!${NC}"
                echo -e "\n${GREEN}Drag & drop to Dock should now work!${NC}"
            else
                echo -e "${RED}✗ Signing failed${NC}"
            fi
        fi
    fi
fi