# Fix Certificate Issue

## The Problem
Your "Apple Development: Corey Schuman (TT8WDUPS38)" certificate exists but:
1. The private key might be missing
2. The certificate chain might be incomplete

## Solution Steps

### Step 1: Open Xcode and Check Certificate Status
1. Open Xcode: `open -a Xcode`
2. Go to **Xcode → Settings** (or Preferences)
3. Click **Accounts** tab
4. Select your Apple ID
5. Click **Manage Certificates...**

### Step 2: Check Certificate Status
Look for your certificate in the list. It should show:
- ✅ **With key icon** = Certificate and private key are paired (good!)
- ❌ **Without key icon** = Private key is missing (needs fixing)
- ⚠️ **Red X or warning** = Certificate has issues

### Step 3: If Certificate Has Issues

#### Option A: Revoke and Recreate (Recommended)
1. In the Manage Certificates window:
   - Right-click on the problematic certificate
   - Select **Delete** or **Revoke Certificate**
2. Click the **+** button
3. Select **Apple Development**
4. Xcode will create a new certificate with private key

#### Option B: Download Missing Components
1. Click **Download Manual Profiles** button (if available)
2. Xcode will attempt to fix certificate chain issues

### Step 4: Verify the Fix
After creating/fixing the certificate, run:
```bash
security find-identity -v -p codesigning
```

You should now see something like:
```
1) XXXXXXXXXX "Apple Development: Corey Schuman (XXXXXXXXX)"
    1 valid identities found
```

### Step 5: Sign Parchment
Once the certificate is fixed:
```bash
./sign_with_xcode_cert.sh
```

## Alternative: Use Xcode to Sign

If command-line signing continues to fail, you can create a simple Xcode project:

1. Open Xcode
2. Create new project → macOS → App
3. Set Bundle ID: `com.coreymd.parchment`
4. Select your team/account
5. Let Xcode handle signing
6. Copy the signing settings to your app

## Why This Happens

Common causes:
- Certificate was created on different Mac
- Keychain sync issues with iCloud
- Certificate created without private key
- Incomplete certificate chain download

## If All Else Fails

Use ad-hoc signing for local development:
```bash
./sign_dev.sh --install
```

This won't enable Dock drag & drop, but the app will work otherwise.