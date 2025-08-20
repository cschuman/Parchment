cask "parchment" do
  version "1.0.0-beta"
  sha256 "20bbaac9e0eff8dfe617d706bad5f30a1077cbb4bb7b83970424623fac901cc8"

  url "https://github.com/cschuman/Parchment/releases/download/v#{version}/Parchment-v#{version}.zip"
  name "Parchment"
  desc "Fast, native macOS markdown viewer with live preview"
  homepage "https://github.com/cschuman/Parchment"

  livecheck do
    url :url
    strategy :github_latest
    regex(/v?(\d+(?:\.\d+)+(?:-\w+)?)/i)
  end

  auto_updates false
  depends_on macos: ">= :ventura"

  app "Parchment.app"

  zap trash: [
    "~/Library/Preferences/com.coreymd.parchment.plist",
    "~/Library/Saved Application State/com.coreymd.parchment.savedState",
  ]
end