# frozen_string_literal: true

# Homebrew Cask for Parchment - Native macOS Markdown Viewer
# Install with: brew install --cask parchment

cask "parchment" do
  version "2.0.0"
  sha256 "d040d731f1e0870ff76ba3d975f1caf60cef1d1f69315a4bf71ff2625b2f04f9"

  url "https://github.com/cschuman/Parchment/releases/download/v#{version}/Parchment-v#{version}.zip"
  name "Parchment"
  desc "Beautiful native macOS markdown viewer with premium typography"
  homepage "https://github.com/cschuman/Parchment"

  livecheck do
    url :url
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  auto_updates false
  depends_on macos: ">= :ventura"

  app "Parchment.app"

  # Create CLI symlink in Homebrew bin directory
  binary "#{appdir}/Parchment.app/Contents/MacOS/Parchment", target: "parchment-app"

  preflight do
    # Verify the download is a valid app bundle
    app_path = staged_path/"Parchment.app"
    unless app_path.exist?
      raise "Parchment.app not found in download"
    end
  end

  postflight do
    # Register app with Launch Services for file associations
    system_command "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
                   args: ["-f", "#{appdir}/Parchment.app"],
                   sudo: false
  end

  uninstall quit: "com.coreymd.parchment"

  zap trash: [
    "~/Library/Application Support/Parchment",
    "~/Library/Caches/com.coreymd.parchment",
    "~/Library/HTTPStorages/com.coreymd.parchment",
    "~/Library/Preferences/com.coreymd.parchment.plist",
    "~/Library/Saved Application State/com.coreymd.parchment.savedState",
    "~/Library/WebKit/com.coreymd.parchment",
  ]

  caveats <<~EOS
    Parchment has been installed to /Applications.

    Quick Start:
      Open a markdown file:  open -a Parchment README.md
      Or drag files onto the Parchment icon in your Dock

    File Associations:
      Parchment is registered to open .md, .markdown, and related files.
      To set as default: Right-click a .md file > Get Info > Open With > Parchment > Change All

    Keyboard Shortcuts:
      Open File:           Cmd+O
      Toggle Focus Mode:   Cmd+F
      Toggle TOC:          Cmd+T
      Export as PDF:       Cmd+E

    First Run:
      macOS may display a security prompt on first launch.
      If "Parchment cannot be opened" appears:
        1. Open System Settings > Privacy & Security
        2. Click "Open Anyway" next to the Parchment message
        3. Or: Right-click Parchment.app > Open

    CLI Access:
      A CLI symlink 'parchment-app' is available in your PATH.
      For full CLI features, install the formula version:
        brew install parchment
  EOS
end
