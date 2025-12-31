# Parchment Homebrew Distribution

Homebrew formulas for installing Parchment on macOS.

## Installation Options

### Option 1: CLI from Source (Formula)

Builds from source, installs CLI tools:

```bash
brew install parchment
```

This installs:
- `parchment` - CLI tool for opening markdown files
- `Parchment` - Main application executable
- App bundle at `$(brew --prefix)/share/parchment/Parchment.app`

### Option 2: App Bundle (Cask)

Downloads pre-built app bundle:

```bash
brew install --cask parchment
```

This installs:
- `Parchment.app` in `/Applications`
- File associations for `.md` files
- Quick Look support

## For Developers

### Testing Locally

```bash
# Test formula (builds from source)
brew install --build-from-source ./parchment.rb

# Test cask (requires release zip)
brew install --cask ./Casks/parchment.rb
```

### Updating for New Release

1. Create a GitHub release with tag `vX.Y.Z`
2. Build and upload `Parchment-vX.Y.Z.zip`
3. Run the update script:
   ```bash
   ./update-formula.sh vX.Y.Z
   ```
4. Verify SHA256 hashes are correct
5. Submit PRs to homebrew-core and homebrew-cask

### Submitting to Homebrew

**Formula (homebrew-core):**
```bash
brew bump-formula-pr parchment --url=https://github.com/cschuman/Parchment/archive/refs/tags/vX.Y.Z.tar.gz
```

**Cask (homebrew-cask):**
```bash
brew bump-cask-pr parchment --version=X.Y.Z
```

## File Structure

```
distribution/homebrew/
├── README.md           # This file
├── parchment.rb        # Formula (builds from source)
├── update-formula.sh   # Script to update SHA256 hashes
└── Casks/
    └── parchment.rb    # Cask (pre-built app bundle)
```

## Requirements

- **Formula**: Xcode 14.0+, macOS Ventura 13.0+
- **Cask**: macOS Ventura 13.0+

## Troubleshooting

### "Parchment cannot be opened"

macOS Gatekeeper may block unsigned apps. Solutions:
1. Right-click Parchment.app > Open
2. System Settings > Privacy & Security > Open Anyway

### Build Failures

Ensure Xcode Command Line Tools are installed:
```bash
xcode-select --install
```

### SHA256 Mismatch

Re-run the update script after uploading release assets:
```bash
./update-formula.sh vX.Y.Z
```
