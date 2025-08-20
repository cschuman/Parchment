#!/bin/bash

echo "==================================="
echo "Creating Xcode Project for Signing"
echo "==================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create a temporary Xcode project
PROJECT_NAME="ParchmentSigning"
PROJECT_DIR="/tmp/$PROJECT_NAME"

echo -e "${YELLOW}Creating temporary Xcode project...${NC}"

# Remove old project if exists
rm -rf "$PROJECT_DIR"

# Create project directory
mkdir -p "$PROJECT_DIR"

# Create basic Xcode project file structure
cat > "$PROJECT_DIR/$PROJECT_NAME.xcodeproj/project.pbxproj" << 'EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {
	};
	rootObject = 1234567890ABCDEF;
}
EOF

echo -e "${BLUE}Instructions:${NC}"
echo ""
echo "1. Open Xcode and create a new project:"
echo -e "   ${YELLOW}File → New → Project${NC}"
echo ""
echo "2. Choose: ${GREEN}macOS → App${NC}"
echo ""
echo "3. Configure with these EXACT settings:"
echo "   • Product Name: ${GREEN}ParchmentSigning${NC}"
echo "   • Team: ${GREEN}Corey Schuman (Personal Team)${NC}"
echo "   • Organization Identifier: ${GREEN}com.coreymd${NC}"
echo "   • Bundle Identifier: ${GREEN}com.coreymd.ParchmentSigning${NC}"
echo "   • Language: Swift"
echo "   • User Interface: AppKit"
echo "   • ☐ Use Core Data (unchecked)"
echo "   • ☐ Include Tests (unchecked)"
echo ""
echo "4. Click ${GREEN}Next${NC} and save anywhere (Desktop is fine)"
echo ""
echo "5. Once project opens:"
echo "   • Make sure ${GREEN}Automatically manage signing${NC} is checked"
echo "   • Select your team if not already selected"
echo ""
echo "6. Press ${GREEN}Cmd+B${NC} to build"
echo "   • Xcode will download/create certificates automatically"
echo "   • You should see 'Build Succeeded'"
echo ""
echo "7. After successful build, close Xcode and run:"
echo -e "   ${YELLOW}security find-identity -v -p codesigning${NC}"
echo ""
echo "8. If you see a certificate, run:"
echo -e "   ${YELLOW}./sign_with_xcode_cert.sh${NC}"
echo ""
echo -e "${GREEN}Opening Xcode now...${NC}"
open -a Xcode

echo ""
echo -e "${BLUE}Alternative: Let me check if we can download the certificate${NC}"
echo ""

# Try to refresh certificates
echo -e "${YELLOW}Attempting to refresh certificates...${NC}"

# Clear Xcode cache
rm -rf ~/Library/Developer/Xcode/DeveloperPortal* 2>/dev/null
rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null

echo -e "${GREEN}Xcode cache cleared. Try Manage Certificates again after creating the project.${NC}"