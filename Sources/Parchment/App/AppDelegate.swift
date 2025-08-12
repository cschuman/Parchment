import Cocoa
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController?
    var recentDocuments: [URL] = []
    var documentCache = DocumentCache()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Write to stderr which is unbuffered
        fputs("AppDelegate: applicationDidFinishLaunching called\n", stderr)
        
        // Register custom fonts
        FontManager.shared.registerCustomFonts()
        
        // Initialize plugin manager early
        fputs("AppDelegate: Loading plugins\n", stderr)
        PluginManager.shared.loadAllPlugins()
        
        setupMenuBar()
        setupEnhancedMenus()  // Add enhanced menus for new features
        loadRecentDocuments()
        
        // Always show window first
        fputs("AppDelegate: Calling showWelcomeWindow\n", stderr)
        showWelcomeWindow()
        
        // Then load file if provided
        if ProcessInfo.processInfo.arguments.count > 1 {
            let path = ProcessInfo.processInfo.arguments[1]
            fputs("AppDelegate: Got file argument: \(path)\n", stderr)
            
            // Make path absolute if it's relative
            let absolutePath: String
            if path.hasPrefix("/") {
                absolutePath = path
            } else {
                absolutePath = FileManager.default.currentDirectoryPath + "/" + path
            }
            
            // Load the document after window is shown
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                fputs("AppDelegate: Loading document\n", stderr)
                fputs("AppDelegate: Absolute path: \(absolutePath)\n", stderr)
                fputs("AppDelegate: About to call openDocument\n", stderr)
                self?.openDocument(at: URL(fileURLWithPath: absolutePath))
                fputs("AppDelegate: openDocument call completed\n", stderr)
            }
        }
        
        registerForFileSystemEvents()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        saveRecentDocuments()
        documentCache.persist()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        openDocument(at: url)
        return true
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
        fileMenu.addItem(NSMenuItem(title: "Open with Browser...", action: #selector(openWithBrowser), keyEquivalent: "O"))
        fileMenu.addItem(NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: ""))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Export as PDF...", action: #selector(exportAsPDF), keyEquivalent: "e"))
        fileMenu.addItem(NSMenuItem(title: "Export as HTML...", action: #selector(exportAsHTML), keyEquivalent: ""))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu
        
        viewMenu.addItem(NSMenuItem(title: "Toggle Focus Mode", action: #selector(toggleFocusMode), keyEquivalent: "f"))
        viewMenu.addItem(NSMenuItem(title: "Toggle Table of Contents", action: #selector(toggleTOC), keyEquivalent: "t"))
        viewMenu.addItem(NSMenuItem(title: "Show Reading Statistics", action: #selector(showStatistics), keyEquivalent: "/"))
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(NSMenuItem(title: "Toggle Status Bar", action: #selector(toggleStatusBar), keyEquivalent: "b"))
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(NSMenuItem(title: "Zoom In", action: #selector(zoomIn), keyEquivalent: "+"))
        viewMenu.addItem(NSMenuItem(title: "Zoom Out", action: #selector(zoomOut), keyEquivalent: "-"))
        viewMenu.addItem(NSMenuItem(title: "Actual Size", action: #selector(actualSize), keyEquivalent: "0"))
    }
    
    private func showWelcomeWindow() {
        fputs("AppDelegate: showWelcomeWindow - starting\n", stderr)
        if windowController == nil {
            fputs("AppDelegate: Creating MainWindowController\n", stderr)
            windowController = MainWindowController()
            fputs("AppDelegate: MainWindowController created\n", stderr)
        }
        fputs("AppDelegate: Calling showWindow\n", stderr)
        windowController?.showWindow(nil)
        fputs("AppDelegate: Calling makeKeyAndOrderFront\n", stderr)
        windowController?.window?.makeKeyAndOrderFront(nil)
        fputs("AppDelegate: Loading welcome content\n", stderr)
        windowController?.loadWelcomeContent()
        fputs("AppDelegate: Activating app\n", stderr)
        NSApp.activate(ignoringOtherApps: true)
        fputs("AppDelegate: showWelcomeWindow - complete\n", stderr)
    }
    
    func openDocument(at url: URL) {
        fputs("AppDelegate.openDocument: Trying to open document at: \(url.path)\n", stderr)
        fputs("AppDelegate.openDocument: File exists: \(FileManager.default.fileExists(atPath: url.path))\n", stderr)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            fputs("AppDelegate.openDocument: File not found!\n", stderr)
            showError("File not found: \(url.lastPathComponent)")
            return
        }
        
        fputs("AppDelegate.openDocument: Opening document: \(url.path)\n", stderr)
        
        if windowController == nil {
            fputs("AppDelegate.openDocument: Creating new MainWindowController\n", stderr)
            windowController = MainWindowController()
        }
        
        fputs("AppDelegate.openDocument: Calling showWindow\n", stderr)
        windowController?.showWindow(nil)
        fputs("AppDelegate.openDocument: Calling makeKeyAndOrderFront\n", stderr)
        windowController?.window?.makeKeyAndOrderFront(nil)
        fputs("AppDelegate.openDocument: Calling loadDocument\n", stderr)
        if let wc = windowController {
            fputs("AppDelegate.openDocument: windowController exists, calling loadDocument\n", stderr)
            wc.loadDocument(at: url)
        } else {
            fputs("AppDelegate.openDocument: WARNING - windowController is nil!\n", stderr)
        }
        fputs("AppDelegate.openDocument: Activating app\n", stderr)
        NSApp.activate(ignoringOtherApps: true)
        
        fputs("AppDelegate.openDocument: Adding to recent documents\n", stderr)
        addToRecentDocuments(url)
        fputs("AppDelegate.openDocument: Complete\n", stderr)
    }
    
    @objc private func openDocument() {
        // Check if user is holding Shift for traditional open dialog
        if NSEvent.modifierFlags.contains(.shift) {
            openDocumentWithPanel()
        } else {
            openDocumentWithFuzzyFinder()
        }
    }
    
    private func openDocumentWithFuzzyFinder() {
        // Show fuzzy finder for quick file switching
        let fuzzyFinder = FuzzyFileFinderWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        fuzzyFinder.onFileSelected = { [weak self] url in
            self?.openDocument(at: url)
        }
        
        fuzzyFinder.makeKeyAndOrderFront(nil)
        fuzzyFinder.center()
    }
    
    private func openDocumentWithPanel() {
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
    
    @objc private func openWithBrowser() {
        // Always use the standard file browser
        openDocumentWithPanel()
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
        let preferencesWindow = PreferencesWindowController()
        preferencesWindow.showWindow(nil)
    }
    
    @objc private func toggleFocusMode() {
        windowController?.toggleFocusMode()
    }
    
    @objc private func toggleTOC() {
        windowController?.toggleTableOfContents()
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
        recentDocuments.removeAll { $0 == url }
        recentDocuments.insert(url, at: 0)
        if recentDocuments.count > 10 {
            recentDocuments.removeLast()
        }
    }
    
    private func loadRecentDocuments() {
        if let data = UserDefaults.standard.data(forKey: "RecentDocuments"),
           let urls = try? JSONDecoder().decode([URL].self, from: data) {
            recentDocuments = urls
        }
    }
    
    private func saveRecentDocuments() {
        if let data = try? JSONEncoder().encode(recentDocuments) {
            UserDefaults.standard.set(data, forKey: "RecentDocuments")
        }
    }
    
    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}

extension Notification.Name {
    static let fileDidChange = Notification.Name("FileDidChange")
}