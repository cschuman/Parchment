#!/bin/bash

echo "==================================="
echo "Alternative Certificate Fix Methods"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Method 1: Delete from Keychain Access app${NC}"
echo "----------------------------------------"
echo "1. Open Keychain Access:"
echo -e "   ${YELLOW}open -a 'Keychain Access'${NC}"
echo ""
echo "2. In the search box, type: Apple Development"
echo ""
echo "3. Look for certificates and keys named:"
echo "   - Apple Development: Corey Schuman (TT8WDUPS38)"
echo ""
echo "4. Right-click → Delete"
echo "   (You may need to delete both certificate AND private key separately)"
echo ""
echo "5. Empty Trash in Keychain Access: File → Empty Trash"
echo ""

echo -e "${BLUE}Method 2: Delete via command line${NC}"
echo "----------------------------------------"
echo "Run these commands:"
echo ""

# Show the commands to delete
echo -e "${YELLOW}# Delete the certificate${NC}"
echo "security delete-certificate -c 'Apple Development: Corey Schuman (TT8WDUPS38)' ~/Library/Keychains/login.keychain-db"
echo ""
echo -e "${YELLOW}# Or try with the certificate hash${NC}"
echo "security delete-certificate -Z 2CCF8A80322F2DA37BAE8FDA3D43DE11 ~/Library/Keychains/login.keychain-db"
echo ""

echo -e "${BLUE}Method 3: Create new certificate anyway${NC}"
echo "----------------------------------------"
echo "Sometimes Xcode can create a new certificate even if old one exists:"
echo ""
echo "1. In Xcode → Settings → Accounts → Manage Certificates"
echo "2. Click '+' → 'Apple Development'"
echo "3. If it creates a new one, you'll see two certificates"
echo "4. Use the newer one (check creation date)"
echo ""

echo -e "${BLUE}Method 4: Reset certificates completely${NC}"
echo "----------------------------------------"
echo "Nuclear option - removes ALL development certificates:"
echo ""
echo -e "${RED}WARNING: This will remove ALL Apple Development certificates!${NC}"
echo "Only do this if you're sure you want to start fresh."
echo ""
echo "Run: security delete-certificate -c 'Apple Development' ~/Library/Keychains/login.keychain-db"
echo ""

echo -e "${BLUE}Method 5: Sign with explicit keychain access${NC}"
echo "----------------------------------------"
echo "Try signing with explicit keychain unlocking:"
echo ""

# Attempt to sign with explicit keychain
echo -e "${YELLOW}Attempting to sign with explicit keychain access...${NC}"

# Unlock keychain
security unlock-keychain ~/Library/Keychains/login.keychain-db

# Set keychain settings to avoid timeout
security set-keychain-settings -t 3600 ~/Library/Keychains/login.keychain-db

# Try to sign with explicit keychain
echo -e "${YELLOW}Trying to sign with certificate...${NC}"
codesign --force --deep --sign "Apple Development: Corey Schuman (TT8WDUPS38)" \
    --keychain ~/Library/Keychains/login.keychain-db \
    Parchment.app 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Signing succeeded!${NC}"
else
    echo -e "${RED}✗ Signing still failed${NC}"
    echo ""
    echo -e "${BLUE}Method 6: Use Xcode directly${NC}"
    echo "----------------------------------------"
    echo "Create a simple Xcode project to let Xcode handle signing:"
    echo ""
    echo "1. Open Xcode"
    echo "2. File → New → Project"
    echo "3. Choose macOS → App"
    echo "4. Product Name: ParchmentTemp"
    echo "5. Bundle Identifier: com.coreymd.parchment"
    echo "6. Select your Team (Personal Team is fine)"
    echo "7. Let Xcode create/download certificates"
    echo "8. Once it works, close Xcode and try our script again"
fi

echo ""
echo -e "${GREEN}After trying these methods, run:${NC}"
echo "  security find-identity -v -p codesigning"
echo ""
echo "If you see a valid identity, run:"
echo "  ./sign_with_xcode_cert.sh"