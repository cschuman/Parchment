# Fix Missing Private Key Issue

## What Happened
Xcode recognizes your certificate `Apple Development: Corey Schuman (TT8WDUPS38)` but the private key is missing from your keychain.

## Solution: Force Xcode to Reset Certificate

### Step 1: In Your Xcode Project
1. Go to **Signing & Capabilities** tab
2. **Uncheck** "Automatically manage signing"
3. You'll see an error - that's expected
4. **Check** "Automatically manage signing" again
5. Click **Try Again** if prompted

### Step 2: Revoke and Recreate
When Xcode shows the error:
1. Click on the **Team** dropdown
2. Select **Add an Account...** (even if your account is there)
3. Cancel out
4. Go back to the Team dropdown
5. Select your team again
6. Xcode might prompt: "Revoke and recreate certificate?" - Click **Revoke**

### Step 3: Alternative - Manual Revoke
1. In Xcode, go to **Settings** → **Accounts**
2. Select your Apple ID
3. Click **Manage Certificates...**
4. You should see your certificate
5. Right-click on it → **Revoke**
6. Click **+** → **Apple Development**
7. Let Xcode create a new one

### Step 4: Clean Build
After fixing the certificate:
1. **Product** → **Clean Build Folder** (Shift+Cmd+K)
2. **Product** → **Build** (Cmd+B)
3. Should now succeed!

## Verify Certificate is Fixed
Once Xcode builds successfully, check:

```bash
# Should now show a valid identity
security find-identity -v -p codesigning
```

You should see:
```
1) [HASH] "Apple Development: Corey Schuman (XXXXXXXX)"
    1 valid identities found
```

## Sign Parchment
Once the certificate works:
```bash
# Update the certificate name in our script if needed
./sign_with_xcode_cert.sh
```

## Why This Happens
- The certificate exists on Apple's servers
- But your local private key is missing
- Xcode needs to regenerate the private key
- Revoking forces a fresh certificate+key pair