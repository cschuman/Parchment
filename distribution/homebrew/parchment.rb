# frozen_string_literal: true

# Homebrew formula for Parchment - Native macOS Markdown Viewer
# Install with: brew install parchment
# For app bundle: brew install --cask parchment (see Casks/parchment.rb)

class Parchment < Formula
  desc "Beautiful native macOS markdown viewer with premium typography"
  homepage "https://github.com/cschuman/Parchment"
  url "https://github.com/cschuman/Parchment/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256_HASH_UPDATE_ON_RELEASE"
  license "MIT"
  head "https://github.com/cschuman/Parchment.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on xcode: ["14.0", :build]
  depends_on macos: :ventura

  def install
    # Build release version
    system "swift", "build",
           "-c", "release",
           "--disable-sandbox",
           "-Xswiftc", "-suppress-warnings"

    # Install CLI executable
    bin.install ".build/release/parchment"

    # Install main app executable (can be used directly)
    bin.install ".build/release/Parchment" => "Parchment"

    # Create app bundle in pkgshare for users who want it
    app_bundle = pkgshare/"Parchment.app/Contents"
    app_bundle.mkpath
    (app_bundle/"MacOS").mkpath
    (app_bundle/"Resources").mkpath

    # Copy Info.plist
    cp "Info.plist", app_bundle/"Info.plist"

    # Copy main executable to app bundle
    cp ".build/release/Parchment", app_bundle/"MacOS/Parchment"

    # Copy resources if they exist
    if File.exist?("OpenDyslexic-Regular.otf")
      cp "OpenDyslexic-Regular.otf", app_bundle/"Resources/"
    end

    # Install man page if it exists
    man1.install "docs/parchment.1" if File.exist?("docs/parchment.1")
  end

  def post_install
    # Remind users about the app bundle location
    ohai "App bundle available at: #{pkgshare}/Parchment.app"
  end

  def caveats
    <<~EOS
      Parchment CLI has been installed to #{HOMEBREW_PREFIX}/bin/parchment

      To use the full GUI application, you can either:

      1. Use the CLI to open files:
         parchment README.md

      2. Install the cask version for the full app experience:
         brew install --cask parchment

      3. Copy the app bundle to Applications:
         cp -r #{pkgshare}/Parchment.app /Applications/

      First run permissions:
        On first launch, macOS may ask for permission to access files.
        This is normal - Parchment needs file access to render markdown.

      Quick Look support:
        The cask version includes Quick Look integration for previewing
        markdown files with spacebar in Finder.
    EOS
  end

  test do
    # Test CLI help
    assert_match "Parchment", shell_output("#{bin}/parchment --help 2>&1", 0)

    # Create a test markdown file
    (testpath/"test.md").write <<~MARKDOWN
      # Test Document

      This is a **test** markdown file.

      - Item 1
      - Item 2
    MARKDOWN

    # Verify the executable can process the file (basic validation)
    # Note: Full GUI testing requires a display, so we just verify the binary exists
    assert_predicate bin/"parchment", :executable?
    assert_predicate bin/"Parchment", :executable?
  end
end
