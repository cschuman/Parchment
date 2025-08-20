#!/bin/bash

echo "==================================="
echo "Force New Certificate Creation"
echo "==================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Step 1: Removing ALL Apple Development certificates...${NC}"

# Remove all Apple Development certificates
security delete-certificate -c "Apple Development" ~/Library/Keychains/login.keychain-db 2>/dev/null

# Clear Xcode's cache completely
echo -e "${YELLOW}Step 2: Clearing Xcode cache...${NC}"
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Developer/Xcode/DeveloperPortal*
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""
echo -e "${YELLOW}Now do this in Xcode:${NC}"
echo ""
echo "1. Close your ParchmentSigning project"
echo "2. Quit Xcode completely (Cmd+Q)"
echo "3. Run this command to reopen Xcode:"
echo -e "   ${GREEN}open -a Xcode${NC}"
echo ""
echo "4. Go to Xcode → Settings → Accounts"
echo "5. Remove your Apple ID (select it and click '-')"
echo "6. Add it back (click '+' → Apple ID)"
echo "7. After signing in, click 'Manage Certificates'"
echo "8. Click '+' → 'Apple Development'"
echo "9. Close Settings"
echo ""
echo "10. Open your ParchmentSigning project again"
echo "11. Build (Cmd+B)"
echo ""
echo -e "${GREEN}This should create a fresh certificate with private key!${NC}"