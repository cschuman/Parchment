cask "parchment" do
  version "2.0.0"
  sha256 :no_check  # Update with actual SHA after release

  url "https://github.com/cschuman/Parchment/releases/download/v#{version}/Parchment-v#{version}.zip"
  name "Parchment"
  desc "Beautiful native macOS markdown viewer with premium typography"
  homepage "https://github.com/cschuman/Parchment"

  livecheck do
    url :url
    strategy :github_latest
    regex(/v?(\d+(?:\.\d+)+(?:-\w+)?)/i)
  end

  auto_updates false
  depends_on macos: ">= :monterey"

  app "Parchment.app"

  # Create CLI symlink for terminal access
  binary "#{appdir}/Parchment.app/Contents/MacOS/parchment"

  postflight do
    # Ensure the CLI is accessible
    system_command "/bin/ln",
                   args: ["-sf", "#{appdir}/Parchment.app/Contents/MacOS/parchment", "/usr/local/bin/parchment"],
                   sudo: true
  end

  uninstall_postflight do
    # Remove CLI symlink
    system_command "/bin/rm",
                   args: ["-f", "/usr/local/bin/parchment"],
                   sudo: true
  end

  zap trash: [
    "~/Library/Application Support/Parchment",
    "~/Library/Caches/com.coreymd.parchment",
    "~/Library/Preferences/com.coreymd.parchment.plist",
    "~/Library/Saved Application State/com.coreymd.parchment.savedState",
  ]
end
