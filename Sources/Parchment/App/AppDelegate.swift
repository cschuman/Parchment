import Cocoa
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController?
    var preferencesWindowController: PreferencesWindowController?
    private let recentDocumentsManager = RecentDocumentsManager()
    var documentCache = DocumentCache()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Write to stderr which is unbuffered

        // Pre-initialize MathRenderer on main thread (WKWebView requires main thread)
        _ = MathRenderer.shared

        // Register custom fonts
        FontManager.shared.registerCustomFonts()

        setupMenuBar()
        setupEnhancedMenus()  // Add enhanced menus for new features

        // Setup recent documents callback
        recentDocumentsManager.onDocumentsChanged = { [weak self] in
            self?.updateOpenRecentMenu()
        }
        updateOpenRecentMenu()
        
        // Always show window first
        showWelcomeWindow()
        
        // Then load file if provided
        if ProcessInfo.processInfo.arguments.count > 1 {
            let path = ProcessInfo.processInfo.arguments[1]

            // Use URL to safely handle relative paths and normalize (prevents path traversal)
            let baseURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let fileURL = URL(fileURLWithPath: path, relativeTo: baseURL).standardized

            // Validate the path before loading
            if validateCLIPath(fileURL) {
                // Load the document after window is shown
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.openDocument(at: fileURL)
                }
            } else {
                Logger.warning("CLI path validation failed for: \(path)")
            }
        }
        
        registerForFileSystemEvents()

        // Setup system appearance observation for auto dark/light mode
        setupAppearanceObserver()

        // Apply initial theme based on system appearance if following
        if ParchmentTheme.followSystemAppearance {
            let theme = ParchmentTheme.themeForSystemAppearance()
            ParchmentTheme.current = theme
            windowController?.applyTheme(theme)
        }

        // Register for Spotlight search result notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSpotlightSearchResult(_:)),
            name: NSNotification.Name("OpenDocumentFromSpotlight"),
            object: nil
        )

        // Index recent documents for Spotlight on launch
        SpotlightIndexer.shared.indexRecentDocuments()
    }

    @objc private func handleSpotlightSearchResult(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else { return }
        openDocument(at: url)
    }

    // Handle Spotlight search result clicks
    func application(_ application: NSApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void) -> Bool {
        return SpotlightSearchHandler.shared.handleSearchResult(userActivity: userActivity)
    }

    private func setupAppearanceObserver() {
        // Observe effective appearance changes
        NSApp.addObserver(self, forKeyPath: "effectiveAppearance", options: [.new], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "effectiveAppearance" {
            handleSystemAppearanceChange()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func handleSystemAppearanceChange() {
        guard ParchmentTheme.followSystemAppearance else { return }

        let theme = ParchmentTheme.themeForSystemAppearance()

        // Only switch if different from current theme
        guard theme.name != ParchmentTheme.current.name else { return }

        // Apply with smooth animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            ParchmentTheme.current = theme
            self.windowController?.applyTheme(theme)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When clicking on the Dock icon, show the window if it's hidden
        if !flag {
            showWelcomeWindow()
        }
        return true
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        Logger.info("AppDelegate: Application became active")
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        Logger.info("AppDelegate: application:open:urls called with \(urls.count) URLs")
        for url in urls {
            Logger.info("AppDelegate: Processing URL: \(url.path)")
            if url.pathExtension.lowercased() == "md" || 
               url.pathExtension.lowercased() == "markdown" ||
               url.pathExtension.lowercased() == "txt" {
                openDocument(at: url)
                break // Only open first file for now
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        recentDocumentsManager.persist()
        documentCache.persistMetadata()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        Logger.info("AppDelegate: openFile called with: \(filename)")
        
        // Ensure app is active and window is visible
        NSApp.activate(ignoringOtherApps: true)
        
        let url = URL(fileURLWithPath: filename)
        
        // Verify it's a markdown file
        let validExtensions = ["md", "markdown", "mdown", "mkd", "mkdown", "mdwn", "mdtxt", "mdtext", "text", "txt"]
        guard validExtensions.contains(url.pathExtension.lowercased()) else {
            Logger.info("AppDelegate: Not a markdown file: \(filename)")
            return false
        }
        
        openDocument(at: url)
        return true
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        Logger.info("AppDelegate: openFiles called with \(filenames.count) files")
        
        // Ensure app is active and window is visible
        NSApp.activate(ignoringOtherApps: true)
        
        var handledFiles: [String] = []
        
        // Handle multiple files being dropped onto the app icon
        for filename in filenames {
            Logger.info("AppDelegate: Processing file: \(filename)")
            let url = URL(fileURLWithPath: filename)
            
            // Check if it's a markdown file
            let validExtensions = ["md", "markdown", "mdown", "mkd", "mkdown", "mdwn", "mdtxt", "mdtext", "text", "txt"]
            if validExtensions.contains(url.pathExtension.lowercased()) {
                Logger.info("AppDelegate: Opening markdown file: \(filename)")
                openDocument(at: url)
                handledFiles.append(filename)
                // For now, only open the first file since we don't have multi-tab support yet
                break
            } else {
                Logger.info("AppDelegate: Skipping non-markdown file: \(filename)")
            }
        }
        
        // Tell the system we handled all the files
        if !handledFiles.isEmpty {
            sender.reply(toOpenOrPrint: .success)
        } else {
            sender.reply(toOpenOrPrint: .failure)
        }
    }
    
    
    private func setupMenuBar() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        
        appMenu.addItem(NSMenuItem(title: "About Parchment", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu
        
        fileMenu.addItem(NSMenuItem(title: "Open...", action: #selector(openDocument as () -> Void), keyEquivalent: "o"))
        
        // Open Recent submenu
        let openRecentItem = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
        let openRecentMenu = NSMenu(title: "Open Recent")
        openRecentItem.submenu = openRecentMenu
        fileMenu.addItem(openRecentItem)
        updateOpenRecentMenu(openRecentMenu)
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Export as PDF...", action: #selector(exportAsPDF), keyEquivalent: "e"))
        fileMenu.addItem(NSMenuItem(title: "Export as HTML...", action: #selector(exportAsHTML), keyEquivalent: ""))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Find...", action: #selector(showFind), keyEquivalent: "f"))
        editMenu.addItem(NSMenuItem(title: "Find Next", action: #selector(findNext), keyEquivalent: "g"))
        editMenu.addItem(NSMenuItem(title: "Find Previous", action: #selector(findPrevious), keyEquivalent: "G"))
        
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu
        
        let focusModeItem = NSMenuItem(title: "Toggle Focus Mode", action: #selector(toggleFocusMode), keyEquivalent: "f")
        focusModeItem.keyEquivalentModifierMask = [.command, .shift]
        viewMenu.addItem(focusModeItem)

        let readingModeItem = NSMenuItem(title: "Toggle Reading Mode", action: #selector(toggleReadingMode), keyEquivalent: "r")
        readingModeItem.keyEquivalentModifierMask = [.command, .shift]
        viewMenu.addItem(readingModeItem)

        viewMenu.addItem(NSMenuItem(title: "Toggle Table of Contents", action: #selector(toggleTOC), keyEquivalent: "t"))
        viewMenu.addItem(NSMenuItem(title: "Show Reading Statistics", action: #selector(showStatistics), keyEquivalent: "/"))
        viewMenu.addItem(NSMenuItem.separator())
        
        // Theme submenu
        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        let themeMenu = NSMenu(title: "Theme")
        themeItem.submenu = themeMenu
        
        for (index, theme) in ParchmentTheme.all.enumerated() {
            let menuItem = NSMenuItem(
                title: theme.name,
                action: #selector(selectTheme(_:)),
                keyEquivalent: index < 9 ? "\(index + 1)" : ""
            )
            menuItem.tag = index
            themeMenu.addItem(menuItem)
        }

        // Add separator and Follow System Appearance option
        themeMenu.addItem(NSMenuItem.separator())
        let followSystemItem = NSMenuItem(
            title: "Follow System Appearance",
            action: #selector(toggleFollowSystemAppearance(_:)),
            keyEquivalent: ""
        )
        followSystemItem.state = ParchmentTheme.followSystemAppearance ? .on : .off
        themeMenu.addItem(followSystemItem)

        viewMenu.addItem(themeItem)
        viewMenu.addItem(NSMenuItem.separator())
        
        viewMenu.addItem(NSMenuItem(title: "Toggle Status Bar", action: #selector(toggleStatusBar), keyEquivalent: "b"))
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(NSMenuItem(title: "Zoom In", action: #selector(zoomIn), keyEquivalent: "+"))
        viewMenu.addItem(NSMenuItem(title: "Zoom Out", action: #selector(zoomOut), keyEquivalent: "-"))
        viewMenu.addItem(NSMenuItem(title: "Actual Size", action: #selector(actualSize), keyEquivalent: "0"))
        viewMenu.addItem(NSMenuItem.separator())

        // Navigation submenu
        let navigationItem = NSMenuItem(title: "Navigate", action: nil, keyEquivalent: "")
        let navigationMenu = NSMenu(title: "Navigate")
        navigationItem.submenu = navigationMenu

        navigationMenu.addItem(NSMenuItem(title: "Next Header", action: #selector(jumpToNextHeader), keyEquivalent: "]"))
        navigationMenu.addItem(NSMenuItem(title: "Previous Header", action: #selector(jumpToPreviousHeader), keyEquivalent: "["))
        navigationMenu.addItem(NSMenuItem.separator())

        let topItem = NSMenuItem(title: "Jump to Top", action: #selector(jumpToTop), keyEquivalent: String(UnicodeScalar(NSUpArrowFunctionKey)!))
        topItem.keyEquivalentModifierMask = [.command]
        navigationMenu.addItem(topItem)

        let bottomItem = NSMenuItem(title: "Jump to Bottom", action: #selector(jumpToBottom), keyEquivalent: String(UnicodeScalar(NSDownArrowFunctionKey)!))
        bottomItem.keyEquivalentModifierMask = [.command]
        navigationMenu.addItem(bottomItem)

        viewMenu.addItem(navigationItem)
    }
    
    private func showWelcomeWindow() {
        Logger.info("Creating window controller")
        if windowController == nil {
            windowController = MainWindowController()
        }
        Logger.info("Showing window")
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        
        // Make sure window is visible
        windowController?.window?.makeKey()
        windowController?.window?.orderFront(nil)
        windowController?.window?.display()
        
        Logger.info("Loading welcome content")
        windowController?.loadWelcomeContent()
        
        // Activate the app
        NSApp.activate(ignoringOtherApps: true)
        NSApp.setActivationPolicy(.regular)
        
        Logger.info("Window frame: \(windowController?.window?.frame ?? .zero)")
        Logger.info("Window is visible: \(windowController?.window?.isVisible ?? false)")
        
        // Fallback: Create a simple window if something went wrong
        if windowController?.window == nil || windowController?.window?.isVisible == false {
            Logger.error("Window creation failed, creating fallback window")
            let fallbackWindow = NSWindow(
                contentRect: NSRect(x: 100, y: 100, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            fallbackWindow.title = "Parchment"
            fallbackWindow.center()
            fallbackWindow.makeKeyAndOrderFront(nil)
            
            let label = NSTextField(labelWithString: "Parchment is running but encountered an initialization error.\nPlease use File → Open to open a markdown file.")
            label.frame = NSRect(x: 20, y: 300, width: 760, height: 50)
            fallbackWindow.contentView?.addSubview(label)
        }
    }
    
    func openDocument(at url: URL) {

        guard FileManager.default.fileExists(atPath: url.path) else {
            showError("File not found: \(url.lastPathComponent)")
            return
        }

        if windowController == nil {
            windowController = MainWindowController()
        }

        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        if let wc = windowController {
            wc.loadDocument(at: url)
        } else {
            Logger.error("Window controller unexpectedly nil when opening document")
        }
        NSApp.activate(ignoringOtherApps: true)

        addToRecentDocuments(url)

        // Track document opens for reading position tip
        OnboardingManager.shared.documentOpened()
    }
    
    @objc private func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Open Markdown File"
        panel.message = "Choose a markdown file to open"
        panel.prompt = "Open"
        
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.openDocument(at: url)
            }
        }
    }
    
    @objc private func showAbout() {
        // Create custom about window with version info
        let alert = NSAlert()
        alert.messageText = "Parchment"
        alert.informativeText = """
        Version \(AppVersion.current.fullString)
        
        A high-performance markdown viewer with award-winning design.
        
        Features:
        • 7 Reading Modes
        • Metal-accelerated rendering
        • Wiki-link support
        • Real-time performance monitoring
        
        © 2024 Parchment
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "View Changelog")
        
        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            showChangelog()
        }
    }
    
    private func showChangelog() {
        let changelogWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        changelogWindow.title = "Changelog"
        changelogWindow.center()
        
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        
        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 20, height: 20)
        
        let changelogText = NSMutableAttributedString()
        
        for entry in AppVersion.changelog {
            // Version header
            let versionAttr = NSAttributedString(
                string: "Version \(entry.version)\n",
                attributes: [
                    .font: NSFont.boldSystemFont(ofSize: 16),
                    .foregroundColor: NSColor.labelColor
                ]
            )
            changelogText.append(versionAttr)
            
            // Date
            let dateAttr = NSAttributedString(
                string: "\(entry.formattedDate)\n\n",
                attributes: [
                    .font: NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
            )
            changelogText.append(dateAttr)
            
            // Changes
            for change in entry.changes {
                let changeAttr = NSAttributedString(
                    string: "• \(change)\n",
                    attributes: [
                        .font: NSFont.systemFont(ofSize: 13),
                        .foregroundColor: NSColor.labelColor
                    ]
                )
                changelogText.append(changeAttr)
            }
            
            changelogText.append(NSAttributedString(string: "\n"))
        }
        
        textView.textStorage?.setAttributedString(changelogText)
        scrollView.documentView = textView
        changelogWindow.contentView = scrollView
        
        changelogWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc private func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    @objc private func toggleFocusMode() {
        windowController?.toggleFocusMode()
    }

    @objc private func toggleReadingMode() {
        windowController?.toggleReadingMode()
    }

    @objc private func toggleTOC() {
        windowController?.toggleTableOfContents()
    }
    
    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard let theme = ParchmentTheme.theme(at: sender.tag) else { return }

        // Disable auto-follow when user manually selects a theme
        ParchmentTheme.followSystemAppearance = false

        ParchmentTheme.current = theme
        windowController?.applyTheme(theme)

        // Show auto-theme tip on first manual theme change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            OnboardingManager.shared.showTip(.autoTheme, near: nil)
        }
    }

    @objc private func toggleFollowSystemAppearance(_ sender: NSMenuItem) {
        ParchmentTheme.followSystemAppearance = !ParchmentTheme.followSystemAppearance
        sender.state = ParchmentTheme.followSystemAppearance ? .on : .off

        // If turning on, immediately apply the appropriate theme
        if ParchmentTheme.followSystemAppearance {
            let theme = ParchmentTheme.themeForSystemAppearance()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true
                ParchmentTheme.current = theme
                self.windowController?.applyTheme(theme)
            }
        }
    }
    
    @objc private func showStatistics() {
        windowController?.showReadingStatistics()
    }
    
    @objc private func zoomIn() {
        windowController?.adjustZoom(delta: 0.1)
    }
    
    @objc private func zoomOut() {
        windowController?.adjustZoom(delta: -0.1)
    }
    
    @objc private func actualSize() {
        windowController?.resetZoom()
    }
    
    @objc private func toggleStatusBar() {
        windowController?.toggleStatusBar()
    }

    @objc private func jumpToNextHeader() {
        windowController?.jumpToNextHeader()
    }

    @objc private func jumpToPreviousHeader() {
        windowController?.jumpToPreviousHeader()
    }

    @objc private func jumpToTop() {
        windowController?.jumpToTop()
    }

    @objc private func jumpToBottom() {
        windowController?.jumpToBottom()
    }

    @objc private func showFind() {
        windowController?.showFindBar()
    }
    
    @objc private func findNext() {
        windowController?.findNext()
    }
    
    @objc private func findPrevious() {
        windowController?.findPrevious()
    }
    
    @objc private func exportAsPDF() {
        windowController?.exportDocument(format: .pdf)
    }
    
    @objc private func exportAsHTML() {
        windowController?.exportDocument(format: .html)
    }
    
    private func registerForFileSystemEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFileChange),
            name: .fileDidChange,
            object: nil
        )
    }
    
    @objc private func handleFileChange(_ notification: Notification) {
        if let url = notification.userInfo?["url"] as? URL {
            windowController?.reloadIfNeeded(url: url)
        }
    }
    
    private func addToRecentDocuments(_ url: URL) {
        recentDocumentsManager.addDocument(url)
    }
    
    private func updateOpenRecentMenu(_ menu: NSMenu? = nil) {
        let targetMenu = menu ?? findOpenRecentMenu()
        guard let openRecentMenu = targetMenu else { return }

        openRecentMenu.removeAllItems()

        let documents = recentDocumentsManager.recentDocuments
        if documents.isEmpty {
            let emptyItem = NSMenuItem(title: "No Recent Documents", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            openRecentMenu.addItem(emptyItem)
        } else {
            for (index, url) in documents.enumerated() {
                let menuItem = NSMenuItem(
                    title: url.lastPathComponent,
                    action: #selector(openRecentDocument(_:)),
                    keyEquivalent: index < 9 ? "\(index + 1)" : ""
                )
                menuItem.representedObject = url
                menuItem.toolTip = url.path
                openRecentMenu.addItem(menuItem)
            }

            openRecentMenu.addItem(NSMenuItem.separator())
            openRecentMenu.addItem(NSMenuItem(
                title: "Clear Menu",
                action: #selector(clearRecentDocuments),
                keyEquivalent: ""
            ))
        }
    }
    
    private func findOpenRecentMenu() -> NSMenu? {
        guard let fileMenu = NSApp.mainMenu?.item(withTitle: "File")?.submenu else { return nil }
        return fileMenu.item(withTitle: "Open Recent")?.submenu
    }
    
    @objc private func openRecentDocument(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        openDocument(at: url)
    }
    
    @objc private func clearRecentDocuments() {
        recentDocumentsManager.clearAll()
    }
    
    private func showError(_ message: String) {
        AlertHelper.showError(message)
    }

    // MARK: - Path Validation

    /// Validates CLI-provided paths to ensure they are safe to open
    private func validateCLIPath(_ url: URL) -> Bool {
        let resolvedPath = url.resolvingSymlinksInPath().path

        // Validate file extension
        let validExtensions = ["md", "markdown", "mdown", "mkd", "mkdown", "mdwn", "mdtxt", "mdtext", "text", "txt"]
        guard validExtensions.contains(url.pathExtension.lowercased()) else {
            Logger.warning("Invalid file extension: \(url.pathExtension)")
            return false
        }

        // Block access to sensitive system directories
        let blockedPrefixes = [
            "/System",
            "/Library/Keychains",
            "/private/etc",
            "/private/var",
            "/etc",
            "/var/root",
            "/usr/local/etc"
        ]

        for prefix in blockedPrefixes {
            if resolvedPath.hasPrefix(prefix + "/") || resolvedPath == prefix {
                Logger.warning("Blocked access to sensitive path: \(resolvedPath)")
                return false
            }
        }

        // Ensure file exists
        guard FileManager.default.fileExists(atPath: resolvedPath) else {
            Logger.warning("File does not exist: \(resolvedPath)")
            return false
        }

        // Ensure it's readable
        guard FileManager.default.isReadableFile(atPath: resolvedPath) else {
            Logger.warning("File is not readable: \(resolvedPath)")
            return false
        }

        return true
    }
}

extension Notification.Name {
    static let fileDidChange = Notification.Name("FileDidChange")
}