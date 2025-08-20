# Code Signing Guide for Parchment

## Overview
Code signing is required for full macOS integration, including:
- Drag & drop to Dock icon
- Gatekeeper approval
- Distribution outside Mac App Store
- Full system integration

## Prerequisites

### Option 1: Free (Development Only)
- Apple ID
- Xcode installed
- Works only on your Mac

### Option 2: Paid ($99/year)
- Apple Developer Program membership
- Allows distribution to other users
- Required for Mac App Store

## Step 1: Create Signing Certificate

### For Free Development Certificate:
1. Open Xcode
2. Go to Xcode → Preferences → Accounts
3. Add your Apple ID if not already added
4. Click "Manage Certificates"
5. Click "+" and select "Apple Development"
6. Xcode will create a certificate automatically

### For Paid Developer Certificate:
1. Log in to [developer.apple.com](https://developer.apple.com)
2. Go to Certificates, Identifiers & Profiles
3. Create a new certificate:
   - For direct distribution: "Developer ID Application"
   - For Mac App Store: "Mac App Distribution"

## Step 2: Find Your Signing Identity

Run this command to list available identities:
```bash
security find-identity -v -p codesigning
```

Look for something like:
- Development: `Apple Development: Your Name (XXXXXXXXXX)`
- Distribution: `Developer ID Application: Your Name (XXXXXXXXXX)`

## Step 3: Sign the App

### Basic Signing (Development)
```bash
# Sign with development certificate
codesign --force --deep --sign "Apple Development: Your Name (XXXXXXXXXX)" Parchment.app

# Or sign with ad-hoc signature (no certificate needed, limited functionality)
codesign --force --deep --sign - Parchment.app
```

### Production Signing (Requires Paid Account)
```bash
# Sign with Developer ID for distribution outside App Store
codesign --force --deep --sign "Developer ID Application: Your Name (XXXXXXXXXX)" \
  --options runtime \
  --entitlements entitlements.plist \
  Parchment.app
```

## Step 4: Verify Signing
```bash
# Check signature
codesign -dv --verbose=4 Parchment.app

# Verify signature
codesign --verify --deep --strict --verbose=2 Parchment.app

# Check if app will pass Gatekeeper
spctl -a -t exec -vvv Parchment.app
```

## Step 5: Notarization (Paid Account Only)

For apps distributed outside the Mac App Store, notarization is required:

```bash
# Create a zip for notarization
ditto -c -k --keepParent Parchment.app Parchment.zip

# Submit for notarization
xcrun notarytool submit Parchment.zip \
  --apple-id "your-apple-id@email.com" \
  --password "app-specific-password" \
  --team-id "XXXXXXXXXX" \
  --wait

# Staple the notarization ticket
xcrun stapler staple Parchment.app
```

## Entitlements

Create an `entitlements.plist` file for production signing:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.downloads.read-write</key>
    <true/>
</dict>
</plist>
```

## Quick Scripts

### sign_dev.sh (For Development)
```bash
#!/bin/bash
# For development testing only
codesign --force --deep --sign - Parchment.app
echo "App signed with ad-hoc signature for development"
```

### sign_release.sh (For Distribution - Requires Paid Account)
```bash
#!/bin/bash
IDENTITY="Developer ID Application: Your Name (XXXXXXXXXX)"
codesign --force --deep --sign "$IDENTITY" \
  --options runtime \
  --entitlements entitlements.plist \
  Parchment.app
echo "App signed for distribution"
```

## Troubleshooting

### "errSecInternalComponent" Error
- Make sure keychain is unlocked: `security unlock-keychain`

### "No identity found" Error
- Create certificate in Xcode first
- Or join Apple Developer Program

### Drag & Drop Still Not Working
- Make sure app is in /Applications
- Reset Launch Services: `lsregister -kill -r -domain local -domain system -domain user`
- Restart Mac if needed

## Testing Drag & Drop After Signing

1. Sign the app
2. Move to /Applications
3. Reset Launch Services
4. Test drag & drop to Dock icon

## Resources
- [Apple Code Signing Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)