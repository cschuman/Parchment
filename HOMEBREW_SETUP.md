# Homebrew Distribution for Parchment

## Option 1: Create Your Own Tap (Immediate)

### Step 1: Create a tap repository
1. Go to GitHub and create a new repository named `homebrew-tap`
2. Clone it locally:
   ```bash
   git clone https://github.com/cschuman/homebrew-tap.git
   cd homebrew-tap
   ```

### Step 2: Add the Cask formula
1. Create a `Casks` directory:
   ```bash
   mkdir Casks
   ```

2. Copy the formula:
   ```bash
   cp /path/to/parchment.rb Casks/parchment.rb
   ```

3. Commit and push:
   ```bash
   git add .
   git commit -m "Add Parchment cask"
   git push
   ```

### Step 3: Users can now install with:
```bash
# Add your tap
brew tap cschuman/tap

# Install Parchment
brew install --cask parchment
```

## Option 2: Submit to Official Homebrew Cask (Takes Time)

### Prerequisites:
- App should be stable (not beta)
- Should be code-signed and notarized
- Should have decent user base

### Steps:

1. **Fork homebrew-cask repository**
   ```bash
   git clone https://github.com/Homebrew/homebrew-cask.git
   cd homebrew-cask
   ```

2. **Create a branch**
   ```bash
   git checkout -b add-parchment
   ```

3. **Add your cask**
   ```bash
   cp /path/to/parchment.rb Casks/p/parchment.rb
   ```

4. **Test the cask**
   ```bash
   brew audit --cask parchment
   brew style --fix Casks/p/parchment.rb
   brew install --cask parchment
   ```

5. **Submit PR**
   - Commit your changes
   - Push to your fork
   - Create a pull request to homebrew-cask

### Requirements for Official Cask:
- ✅ Open source
- ✅ Has GitHub releases
- ❌ Should be code-signed (currently not)
- ❌ Should be notarized (currently not)
- ❌ Should be stable release (currently beta)

## Option 3: Quick Distribution (No Homebrew)

For now, users can install directly:

```bash
# Download and install
curl -L https://github.com/cschuman/Parchment/releases/download/v1.0.0-beta/Parchment-v1.0.0-beta.zip -o Parchment.zip
unzip Parchment.zip
mv Parchment.app /Applications/
rm Parchment.zip
```

Or create an install script:

```bash
#!/bin/bash
# install.sh
VERSION="1.0.0-beta"
echo "Installing Parchment v$VERSION..."
curl -L "https://github.com/cschuman/Parchment/releases/download/v$VERSION/Parchment-v$VERSION.zip" -o /tmp/Parchment.zip
unzip -q /tmp/Parchment.zip -d /tmp/
mv /tmp/Parchment.app /Applications/
rm /tmp/Parchment.zip
echo "✅ Parchment installed to /Applications"
```

## Next Steps for Homebrew:

### To make Parchment ready for official Homebrew Cask:

1. **Code Sign the App**
   ```bash
   codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" Parchment.app
   ```

2. **Notarize with Apple**
   ```bash
   xcrun notarytool submit Parchment.zip --apple-id your@email.com --team-id TEAMID --wait
   ```

3. **Staple the Notarization**
   ```bash
   xcrun stapler staple Parchment.app
   ```

4. **Create Stable Release**
   - Remove "-beta" from version
   - Test thoroughly
   - Tag as v1.0.0

### For Your Own Tap (Recommended for Now):

Since the app is in beta and not code-signed, creating your own tap is the best option. Users who trust you can easily install with:

```bash
brew tap cschuman/tap
brew install --cask parchment
```

This gives you:
- ✅ Easy installation for users
- ✅ Automatic updates when you release new versions
- ✅ No approval process needed
- ✅ Full control over the formula