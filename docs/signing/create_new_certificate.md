# Create New Apple Development Certificate

## ✅ Old Certificate Deleted Successfully!

Now you need to create a fresh certificate with its private key.

## Steps to Create New Certificate:

### 1. Open Xcode
```bash
open -a Xcode
```

### 2. Go to Certificate Management
- **Xcode menu** → **Settings** (or Preferences)
- Click **Accounts** tab
- Select your Apple ID (or add it if not there)
- Click **Manage Certificates...**

### 3. Create New Certificate
- Click the **+** button in bottom left
- Select **Apple Development**
- Xcode will create a new certificate with private key

### 4. Wait for Creation
- Xcode will communicate with Apple's servers
- A new certificate will be created and downloaded
- The private key will be automatically generated and stored in your keychain

### 5. Verify Success
After Xcode creates the certificate, verify it:

```bash
# Check if new certificate exists
security find-identity -v -p codesigning
```

You should see something like:
```
1) XXXXXXXXXX "Apple Development: Corey Schuman (XXXXXXXXX)"
    1 valid identities found
```

### 6. Sign Parchment
Once you see the certificate:
```bash
./sign_with_xcode_cert.sh
```

## If Xcode Can't Create Certificate:

### Option A: Sign in Again
1. In Accounts, remove your Apple ID (- button)
2. Add it back (+ button)
3. Try creating certificate again

### Option B: Use Xcode Project
1. Create new macOS app project
2. Set bundle ID: `com.coreymd.parchment`
3. Select your team
4. Let Xcode auto-manage signing
5. Build once (Cmd+B)
6. Xcode will create necessary certificates

## What's Happening:
- We deleted the broken certificate that had no private key
- Now Xcode will create a fresh certificate WITH its private key
- This will enable proper code signing
- Drag & drop to Dock will work once signed!

## Quick Commands:
```bash
# After creating certificate in Xcode, run:
security find-identity -v -p codesigning

# If certificate shows up, sign the app:
./sign_with_xcode_cert.sh

# Test drag & drop:
open /Applications/Parchment.app
# Then drag a .md file to the Dock icon!
```