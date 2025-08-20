# Fix "You already have a current Development certificate" Error

## The Problem
Apple's servers still think you have a certificate, even though we deleted it locally.

## Solution Options:

### Option 1: Download Existing Certificate
In the Manage Certificates window:
1. Click **Download Manual Profiles** button (if visible)
2. This might restore the certificate with its private key
3. Check if a certificate appears with a key icon next to it

### Option 2: Revoke on Apple Developer Website (if you have paid account)
1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple ID
3. Go to Certificates, IDs & Profiles
4. Find and revoke the old certificate
5. Return to Xcode and create new one

### Option 3: Use the Existing Certificate Reference
Since Apple thinks you have a certificate, let's try to make it work:

1. **In Xcode**, try to refresh:
   - Close the Manage Certificates window
   - Sign out of your Apple ID (click "-" in Accounts)
   - Sign back in (click "+")
   - Open Manage Certificates again
   - Check if certificate appears

2. **Reset Xcode's certificate cache**:
   ```bash
   # Remove Xcode's cached account data
   rm -rf ~/Library/Developer/Xcode/DeveloperPortal*
   rm -rf ~/Library/Caches/com.apple.dt.Xcode
   ```
   Then restart Xcode and try again.

### Option 4: Create an Xcode Project (Workaround)
This often forces Xcode to properly set up certificates:

1. In Xcode: **File** → **New** → **Project**
2. Choose **macOS** → **App**
3. Set these values:
   - Product Name: `ParchmentSigning`
   - Bundle Identifier: `com.coreymd.parchment.signing`
   - Team: Select your Personal Team
   - Language: Swift
   - Don't use Core Data or any extras

4. Click **Create**
5. In the project settings, under **Signing & Capabilities**:
   - Make sure "Automatically manage signing" is checked
   - Select your team

6. Press **Cmd+B** to build
   - Xcode will handle certificate creation/download

7. Once it builds successfully, check:
   ```bash
   security find-identity -v -p codesigning
   ```

### Option 5: Wait and Retry
Sometimes there's a delay in Apple's servers:
1. Wait 5-10 minutes
2. Restart Xcode
3. Try creating certificate again

## Check What We Have Now:
Let's see if anything is in your keychain after Xcode's attempt:

```bash
# List all certificates
security find-identity -v

# Check for any Apple certificates
security find-certificate -a -p ~/Library/Keychains/login.keychain-db | grep -A 1 "subject"

# Check if Xcode downloaded anything
ls ~/Library/MobileDevice/Provisioning\ Profiles/
```

## If Nothing Works:
We can use ad-hoc signing for now:
```bash
./sign_dev.sh --install
```

This won't enable Dock drag & drop, but everything else will work while we sort out the certificate issue.