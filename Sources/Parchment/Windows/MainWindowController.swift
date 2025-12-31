import Cocoa
import Markdown

final class MainWindowController: NSWindowController {
    internal var markdownViewController: MarkdownViewController?
    private var tocViewController: TableOfContentsViewController?
    private var splitView: NSSplitView?
    private var statusBarView: StatusBarView?
    private var contentStackView: NSStackView?
    private var currentDocument: MarkdownDocument?
    private var fileWatcher: FileWatcher?
    private var findBarView: FindBarView?
    private var findBarCoordinator: FindBarCoordinator?
    private var dropView: DropView?
    private let toolbarCoordinator = ToolbarCoordinator()
    private var exportCoordinator: ExportCoordinator?

    // Touch Bar support
    @available(macOS 10.12.2, *)
    private lazy var touchBarController: TouchBarController = {
        TouchBarController(windowController: self)
    }()

    // MARK: - Lifecycle

    deinit {
        // Clean up file watcher to release dispatch source and file descriptor
        fileWatcher?.stop()
        fileWatcher = nil

        // Remove Stage Manager notification observers
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // Reading Mode state
    private var isReadingMode = false
    private var savedToolbarVisible = true
    private var savedStatusBarHidden = false
    private var savedTOCHidden = true

    // Distraction-Free Mode state
    private var isDistractionFreeMode = false
    private var savedDistractionFreeToolbarVisible = true
    private var savedDistractionFreeStatusBarHidden = false
    private var savedDistractionFreeTOCHidden = true
    private var savedDistractionFreeProgressHidden = false
    private var savedDistractionFreeWindowStyleMask: NSWindow.StyleMask = []

    // Stage Manager state (macOS 13.0+)
    private var savedWindowFrame: NSRect = .zero
    private var isTransitioningFullScreen = false

    // MARK: - Window Size Constants for Stage Manager

    /// Minimum window size - ensures readable content in Stage Manager tiles
    private static let minimumWindowSize = NSSize(width: 400, height: 300)

    /// Maximum window size - allows full screen usage while respecting Stage Manager
    private static let maximumWindowSize = NSSize(width: 3840, height: 2160)

    /// Default window size - optimized for Stage Manager default tile sizes
    private static let defaultWindowSize = NSSize(width: 1200, height: 800)

    /// Preferred aspect ratio for Stage Manager (approximately 3:2)
    private static let preferredAspectRatio = NSSize(width: 3, height: 2)
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: MainWindowController.defaultWindowSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.center()

        // Configure window size constraints for Stage Manager optimization
        window.minSize = MainWindowController.minimumWindowSize
        window.maxSize = MainWindowController.maximumWindowSize

        // Configure collection behavior for Stage Manager support
        // - fullScreenPrimary: Can enter full screen mode
        // - fullScreenAuxiliary: Can be grouped with other windows in Stage Manager
        // - managed: Participates in window management features
        // - participatesInCycle: Included in Cmd+` window cycling
        window.collectionBehavior = [
            .fullScreenPrimary,
            .fullScreenAuxiliary,
            .managed,
            .participatesInCycle
        ]

        // Enable window tiling for Stage Manager (macOS 13.0+)
        if #available(macOS 13.0, *) {
            // Configure tabbing mode for document-style window management
            window.tabbingMode = .preferred
        }

        // Enable window restoration
        window.isRestorable = true
        window.restorationClass = WindowRestoration.self

        self.init(window: window)
        toolbarCoordinator.actionDelegate = self
        exportCoordinator = ExportCoordinator(window: window)
        window.toolbar = toolbarCoordinator.createToolbar()
        window.delegate = self

        setupViews()
        setupStageManagerObservers()
    }

    // MARK: - Stage Manager Configuration

    /// Sets up observers for Stage Manager state changes (macOS 13.0+)
    private func setupStageManagerObservers() {
        // Observe active space changes which occur during Stage Manager transitions
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceDidChange(_:)),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        // Observe screen configuration changes (external display connect/disconnect)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func activeSpaceDidChange(_ notification: Notification) {
        // When Stage Manager switches spaces, ensure window frame is appropriate
        guard let window = window, !isTransitioningFullScreen else { return }

        // Validate window is still on screen after space change
        DispatchQueue.main.async { [weak self] in
            self?.ensureWindowOnScreen(window)
        }
    }

    @objc private func screensDidChange(_ notification: Notification) {
        // Handle display configuration changes that affect Stage Manager
        guard let window = window else { return }

        DispatchQueue.main.async { [weak self] in
            self?.ensureWindowOnScreen(window)
        }
    }

    /// Ensures the window remains visible on the current screen
    private func ensureWindowOnScreen(_ window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main else { return }

        let visibleFrame = screen.visibleFrame
        var windowFrame = window.frame

        // Check if window is mostly off-screen
        let intersection = windowFrame.intersection(visibleFrame)
        let visibleArea = intersection.width * intersection.height
        let totalArea = windowFrame.width * windowFrame.height

        // If less than 50% visible, reposition window
        if totalArea > 0 && visibleArea / totalArea < 0.5 {
            // Center window on current screen while maintaining size
            let newOrigin = NSPoint(
                x: visibleFrame.midX - windowFrame.width / 2,
                y: visibleFrame.midY - windowFrame.height / 2
            )
            windowFrame.origin = newOrigin
            window.setFrame(windowFrame, display: true, animate: true)
        }
    }

    /// Returns optimal window size for current Stage Manager configuration
    func optimalWindowSizeForStageManager() -> NSSize {
        guard let screen = window?.screen ?? NSScreen.main else {
            return MainWindowController.defaultWindowSize
        }

        let visibleFrame = screen.visibleFrame

        // For Stage Manager, prefer a size that fits well in tile arrangements
        // Typically 2/3 of screen width and 3/4 of screen height works well
        let optimalWidth = min(visibleFrame.width * 0.67, 1400)
        let optimalHeight = min(visibleFrame.height * 0.75, 900)

        return NSSize(
            width: max(optimalWidth, MainWindowController.minimumWindowSize.width),
            height: max(optimalHeight, MainWindowController.minimumWindowSize.height)
        )
    }

    /// Resizes window to optimal Stage Manager dimensions
    func resizeForStageManager() {
        guard let window = window else { return }

        let optimalSize = optimalWindowSizeForStageManager()
        var frame = window.frame

        // Maintain center position while resizing
        let centerX = frame.midX
        let centerY = frame.midY

        frame.size = optimalSize
        frame.origin.x = centerX - optimalSize.width / 2
        frame.origin.y = centerY - optimalSize.height / 2

        window.setFrame(frame, display: true, animate: true)
    }
    
    private func setupViews() {
        // Create main vertical stack view to hold content and status bar
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView = stackView
        
        // Create split view for TOC and markdown content
        splitView = NSSplitView()
        splitView?.isVertical = true
        splitView?.dividerStyle = .thin
        
        tocViewController = TableOfContentsViewController()
        tocViewController?.delegate = self
        
        markdownViewController = MarkdownViewController()
        markdownViewController?.statusBarDelegate = self
        
        if let tocView = tocViewController?.view,
           let contentView = markdownViewController?.view {
            splitView?.addArrangedSubview(tocView)
            splitView?.addArrangedSubview(contentView)
            
            splitView?.setHoldingPriority(.defaultLow, forSubviewAt: 0)
            splitView?.setHoldingPriority(.required, forSubviewAt: 1)
            
            tocView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
            tocView.widthAnchor.constraint(lessThanOrEqualToConstant: 400).isActive = true
        }
        
        // Create status bar
        statusBarView = StatusBarView(frame: NSRect(x: 0, y: 0, width: 100, height: 22))
        
        // Add split view and status bar to content stack
        if let splitView = splitView, let statusBarView = statusBarView {
            contentStackView?.addArrangedSubview(splitView)
            contentStackView?.addArrangedSubview(statusBarView)
            
            // Make split view take up most of the space
            splitView.setContentHuggingPriority(.defaultLow, for: .vertical)
            statusBarView.setContentHuggingPriority(.required, for: .vertical)
        }
        
        // Create find bar (initially hidden)
        findBarView = FindBarView()
        findBarView?.isHidden = true
        findBarView?.translatesAutoresizingMaskIntoConstraints = false

        // Create find bar coordinator
        findBarCoordinator = FindBarCoordinator(findBarView: findBarView, markdownViewController: markdownViewController)
        
        // Create drop view as the main container
        dropView = DropView(frame: .zero)
        dropView?.dropDelegate = self
        dropView?.translatesAutoresizingMaskIntoConstraints = false
        dropView?.wantsLayer = true

        // Safely add subviews and set constraints
        guard let dropView = dropView,
              let findBarView = findBarView,
              let contentStackView = contentStackView else {
            Logger.error("Failed to initialize main window views")
            return
        }

        dropView.addSubview(findBarView)
        dropView.addSubview(contentStackView)

        window?.contentView = dropView

        NSLayoutConstraint.activate([
            findBarView.topAnchor.constraint(equalTo: dropView.topAnchor),
            findBarView.leadingAnchor.constraint(equalTo: dropView.leadingAnchor),
            findBarView.trailingAnchor.constraint(equalTo: dropView.trailingAnchor),

            contentStackView.topAnchor.constraint(equalTo: findBarView.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: dropView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: dropView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: dropView.bottomAnchor)
        ])
        
        tocViewController?.view.isHidden = true
    }

    // MARK: - Touch Bar Support

    @available(macOS 10.12.2, *)
    override func makeTouchBar() -> NSTouchBar? {
        return touchBarController.makeTouchBar()
    }

    func loadDocument(at url: URL) {
        Logger.info("Loading document: \(url.path)")
        
        // Check file size
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        _ = fileSize > 1_000_000 // Show progress for files > 1MB
        
        // Use performance optimizer for fast loading
        let loadStart = CFAbsoluteTimeGetCurrent()
        
        PerformanceOptimizer.shared.loadFileOptimized(at: url) { [weak self] result in
            switch result {
            case .success(let optimizedDoc):
                let document = MarkdownDocument(url: url, content: optimizedDoc.content)
                
                self?.currentDocument = document
                self?.window?.title = url.lastPathComponent
                
                // Update status bar with file info and performance metrics
                let fileSize = Int64(optimizedDoc.content.utf8.count)
                let lines = optimizedDoc.metadata.lineCount
                let words = optimizedDoc.metadata.wordCount
                
                self?.statusBarView?.updateFileInfo(path: url.path, size: fileSize, lines: lines, words: words)
                
                // Update performance metrics
                self?.statusBarView?.updateParseTime(optimizedDoc.parseTime)
                _ = CFAbsoluteTimeGetCurrent() - loadStart
                
                if let mvc = self?.markdownViewController {
                    mvc.loadDocument(document)
                } else {
                    Logger.error("MarkdownViewController unexpectedly nil when loading document")
                }
                self?.tocViewController?.updateTableOfContents(for: document)
                
                self?.setupFileWatcher(for: url)

                DocumentCache.shared.cacheDocument(document)

                // Index document for Spotlight search
                SpotlightIndexer.shared.indexDocument(at: url, content: optimizedDoc.content)

            case .failure(let error):
                self?.showError("Failed to load document: \(error.localizedDescription)")
            }
        }
    }
    
    func loadWelcomeContent() {
        let welcomeMarkdown = """
        # Welcome to Parchment
        
        ## Fast, Native, Beautiful
        
        Parchment is a high-performance markdown reader built specifically for macOS.
        
        ### Key Features
        
        - **Lightning Fast** - Opens files instantly, handles documents of any size
        - **Focus Mode** - Eliminate distractions with intelligent content dimming
        - **Smart Navigation** - Jump between sections with our intelligent table of contents
        - **Live Updates** - See changes as you edit in your favorite editor
        - **Native Integration** - Quick Look support and deep macOS integration
        
        ### Getting Started
        
        1. Open a markdown file with `Cmd+O`
        2. Toggle Focus Mode with `Cmd+F`
        3. Show Table of Contents with `Cmd+T`
        4. View reading statistics with `Cmd+/`
        
        ### Keyboard Shortcuts
        
        | Action | Shortcut |
        |--------|----------|
        | Open File | `Cmd+O` |
        | Focus Mode | `Cmd+F` |
        | Table of Contents | `Cmd+T` |
        | Reading Stats | `Cmd+/` |
        | Zoom In | `Cmd++` |
        | Zoom Out | `Cmd+-` |
        | Actual Size | `Cmd+0` |
        
        ---
        
        Ready to start? Open a markdown file to begin.
        """
        
        let document = MarkdownDocument(url: nil, content: welcomeMarkdown)
        
        // Ensure view controllers are initialized
        if markdownViewController == nil {
            Logger.error("ERROR: markdownViewController is nil!")
            // Try to create it if missing
            markdownViewController = MarkdownViewController()
            markdownViewController?.statusBarDelegate = self
        }
        
        markdownViewController?.loadDocument(document)
        tocViewController?.updateTableOfContents(for: document)
        window?.title = "Welcome"
        
        // Force the window to display
        if let window = window {
            window.display()
            window.makeKeyAndOrderFront(nil)
            Logger.info("Window shown with frame: \(window.frame)")
        } else {
            Logger.error("Window is nil in loadWelcomeContent!")
        }
    }
    
    func reloadIfNeeded(url: URL) {
        guard let currentDocument = currentDocument,
              currentDocument.url == url else { return }
        
        do {
            let newContent = try String(contentsOf: url, encoding: .utf8)
            
            if newContent != currentDocument.content {
                let oldDocument = currentDocument
                let newDocument = MarkdownDocument(url: url, content: newContent)
                
                self.currentDocument = newDocument
                
                let diff = DiffHighlighter.computeDiff(old: oldDocument.content, new: newContent)
                markdownViewController?.updateDocument(newDocument, diff: diff)
                tocViewController?.updateTableOfContents(for: newDocument)
                
                DocumentCache.shared.cacheDocument(newDocument)
            }
        } catch {
            Logger.error("Failed to reload document: \(error)")
        }
    }
    
    private func setupFileWatcher(for url: URL) {
        fileWatcher?.stop()
        fileWatcher = FileWatcher(url: url) { [weak self] in
            DispatchQueue.main.async {
                self?.reloadIfNeeded(url: url)
            }
        }
        fileWatcher?.start()
    }
    
    
    @objc func toggleFocusMode() {
        markdownViewController?.toggleFocusMode()
    }
    
    @objc func toggleTableOfContents() {
        guard let tocView = tocViewController?.view else { return }

        let wasHidden = tocView.isHidden

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true

            tocView.isHidden.toggle()
            splitView?.layoutSubtreeIfNeeded()
        }

        // Show tip on first TOC open
        if wasHidden && !tocView.isHidden {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                OnboardingManager.shared.showTip(.tocNavigation, near: tocView)
            }
        }
    }
    
    @objc func showReadingStatistics() {
        markdownViewController?.showReadingStatistics()
    }
    
    @objc func toggleStatusBar() {
        guard let statusBarView = statusBarView else { return }

        // No animation - just toggle visibility instantly
        statusBarView.isHidden.toggle()
        contentStackView?.layoutSubtreeIfNeeded()
    }

    @objc func toggleReadingMode() {
        isReadingMode.toggle()

        if isReadingMode {
            enterReadingMode()
        } else {
            exitReadingMode()
        }
    }

    private func enterReadingMode() {
        // Save current state
        savedToolbarVisible = window?.toolbar?.isVisible ?? true
        savedStatusBarHidden = statusBarView?.isHidden ?? false
        savedTOCHidden = tocViewController?.view.isHidden ?? true

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true

            // Hide all chrome
            statusBarView?.animator().isHidden = true
            tocViewController?.view.animator().isHidden = true
            window?.toolbar?.isVisible = false

            // Hide presentation options (dock, menu bar)
            NSApp.presentationOptions = [.autoHideDock, .autoHideMenuBar]

            contentStackView?.layoutSubtreeIfNeeded()
        }

        // Enter full screen if not already
        if window?.styleMask.contains(.fullScreen) == false {
            window?.toggleFullScreen(nil)
        }

        // Enable centered reading width
        markdownViewController?.setReadingModeWidth(680)
    }

    private func exitReadingMode() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true

            // Restore chrome
            statusBarView?.animator().isHidden = savedStatusBarHidden
            tocViewController?.view.animator().isHidden = savedTOCHidden
            window?.toolbar?.isVisible = savedToolbarVisible

            // Restore presentation options
            NSApp.presentationOptions = []

            contentStackView?.layoutSubtreeIfNeeded()
        }

        // Exit full screen if we're in it
        if window?.styleMask.contains(.fullScreen) == true {
            window?.toggleFullScreen(nil)
        }

        // Disable centered reading width
        markdownViewController?.setReadingModeWidth(nil)
    }

    // MARK: - Distraction-Free Mode

    @objc func toggleDistractionFreeMode() {
        isDistractionFreeMode.toggle()

        if isDistractionFreeMode {
            enterDistractionFreeMode()
        } else {
            exitDistractionFreeMode()
        }
    }

    /// Returns true if distraction-free mode is currently active
    var distractionFreeModeEnabled: Bool {
        return isDistractionFreeMode
    }

    private func enterDistractionFreeMode() {
        // Save current state
        savedDistractionFreeToolbarVisible = window?.toolbar?.isVisible ?? true
        savedDistractionFreeStatusBarHidden = statusBarView?.isHidden ?? false
        savedDistractionFreeTOCHidden = tocViewController?.view.isHidden ?? true
        savedDistractionFreeProgressHidden = markdownViewController?.isReadingProgressHidden ?? false

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true

            // Hide all chrome with fade
            statusBarView?.animator().alphaValue = 0
            tocViewController?.view.animator().alphaValue = 0
            window?.toolbar?.isVisible = false

            // Hide reading progress indicator
            markdownViewController?.setReadingProgressHidden(true, animated: false)

            contentStackView?.layoutSubtreeIfNeeded()
        } completionHandler: { [weak self] in
            // Actually hide views after fade completes
            self?.statusBarView?.isHidden = true
            self?.tocViewController?.view.isHidden = true
            self?.statusBarView?.alphaValue = 1
            self?.tocViewController?.view.alphaValue = 1
        }

        // Hide dock and menu bar
        NSApp.presentationOptions = [.autoHideDock, .autoHideMenuBar]

        // Make title bar fully transparent
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.styleMask.insert(.fullSizeContentView)

        // Enter full screen if not already
        if window?.styleMask.contains(.fullScreen) == false {
            window?.toggleFullScreen(nil)
        }

        // Enable centered reading width for optimal focus
        markdownViewController?.setReadingModeWidth(680)

        // Show mode indicator
        showDistractionFreeModeIndicator(entering: true)
    }

    private func exitDistractionFreeMode() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true

            // Prepare views for fade in
            statusBarView?.alphaValue = 0
            tocViewController?.view.alphaValue = 0

            // Restore visibility
            statusBarView?.isHidden = savedDistractionFreeStatusBarHidden
            tocViewController?.view.isHidden = savedDistractionFreeTOCHidden
            window?.toolbar?.isVisible = savedDistractionFreeToolbarVisible

            // Fade in
            statusBarView?.animator().alphaValue = 1
            tocViewController?.view.animator().alphaValue = 1

            // Restore reading progress indicator
            markdownViewController?.setReadingProgressHidden(savedDistractionFreeProgressHidden, animated: false)

            // Restore presentation options
            NSApp.presentationOptions = []

            contentStackView?.layoutSubtreeIfNeeded()
        }

        // Exit full screen if we're in it
        if window?.styleMask.contains(.fullScreen) == true {
            window?.toggleFullScreen(nil)
        }

        // Disable centered reading width
        markdownViewController?.setReadingModeWidth(nil)

        // Show mode indicator
        showDistractionFreeModeIndicator(entering: false)
    }

    private func showDistractionFreeModeIndicator(entering: Bool) {
        guard let contentView = window?.contentView else { return }

        let indicator = ModeIndicatorView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        indicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(indicator)

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 200),
            indicator.heightAnchor.constraint(equalToConstant: 100)
        ])

        if entering {
            indicator.showMode("Distraction Free", subtitle: "Press Esc or Cmd+Shift+D to exit")
        } else {
            indicator.showMode("Normal View", subtitle: nil)
        }

        // Remove indicator after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            indicator.removeFromSuperview()
        }
    }

    /// Handle Escape key to exit distraction-free mode
    func handleEscapeKey() -> Bool {
        if isDistractionFreeMode {
            toggleDistractionFreeMode()
            return true
        }
        return false
    }

    func adjustZoom(delta: CGFloat) {
        markdownViewController?.adjustZoom(delta: delta)
    }

    func resetZoom() {
        markdownViewController?.resetZoom()
    }

    func jumpToNextHeader() {
        markdownViewController?.navigateToNextHeader()
    }

    func jumpToPreviousHeader() {
        markdownViewController?.navigateToPreviousHeader()
    }

    func jumpToTop() {
        markdownViewController?.jumpToTop()
    }

    func jumpToBottom() {
        markdownViewController?.jumpToBottom()
    }

    /// Restores scroll position from Handoff
    /// - Parameter percentage: Scroll percentage (0.0 to 1.0)
    func restoreScrollPosition(_ percentage: Double) {
        markdownViewController?.restoreScrollPositionFromHandoff(percentage)
    }

    func applyTheme(_ theme: ParchmentTheme) {
        // Apply theme to window background
        window?.backgroundColor = theme.backgroundColor
        window?.contentView?.layer?.backgroundColor = theme.backgroundColor.cgColor
        
        // Apply theme to drop view
        dropView?.layer?.backgroundColor = theme.backgroundColor.cgColor
        dropView?.needsDisplay = true
        
        // Apply theme to split view (NSSplitView doesn't have backgroundColor directly)
        splitView?.wantsLayer = true
        splitView?.layer?.backgroundColor = theme.backgroundColor.cgColor
        splitView?.needsDisplay = true
        
        // Apply theme to content stack view
        contentStackView?.layer?.backgroundColor = theme.backgroundColor.cgColor
        
        // Apply theme to find bar
        findBarView?.layer?.backgroundColor = theme.backgroundColor.cgColor
        
        // Apply theme to TOC
        tocViewController?.applyTheme(theme)
        
        // Apply theme to markdown view (this handles re-rendering)
        markdownViewController?.applyTheme(theme)
        
        // Apply theme to status bar
        statusBarView?.applyTheme(theme)
        
        // Force window and all subviews to redraw
        window?.display()
        window?.contentView?.needsDisplay = true
        window?.contentView?.subviews.forEach { $0.needsDisplay = true }
    }
    
    func exportDocument(format: DocumentExporter.ExportFormat) {
        guard let document = currentDocument else {
            showError("No document to export")
            return
        }
        exportCoordinator?.exportDirectly(document, format: format)
    }

    /// Export document with preview panel - shows preview before saving
    func exportDocumentWithPreview(format: DocumentExporter.ExportFormat) {
        guard let document = currentDocument else {
            showError("No document to export")
            return
        }
        exportCoordinator?.exportDocument(document, format: format)
    }

    private func showError(_ message: String) {
        AlertHelper.showError(message, in: window)
    }
}

// MARK: - Toolbar Action Delegate

extension MainWindowController: ToolbarActionDelegate {}

extension MainWindowController: TableOfContentsDelegate {
    func didSelectHeader(_ header: MarkdownHeader) {
        markdownViewController?.scrollToHeader(header)
    }
}

extension MainWindowController: DropViewDelegate {
    func dropView(_ dropView: DropView, didReceiveFileURL url: URL) {
        Logger.info("MainWindowController: Received dropped file: \(url.path)")
        loadDocument(at: url)
    }
}

// MARK: - Status Bar Delegate

protocol StatusBarDelegate: AnyObject {
    func updateParseTime(_ time: TimeInterval)
    func updateRenderTime(_ time: TimeInterval)
    func updateCacheHitRate(_ rate: Double)
    func updateScrollProgress(_ progress: Double)
}

extension MainWindowController: StatusBarDelegate {
    func updateParseTime(_ time: TimeInterval) {
        statusBarView?.updateParseTime(time)
    }

    func updateRenderTime(_ time: TimeInterval) {
        statusBarView?.updateRenderTime(time)
    }

    func updateCacheHitRate(_ rate: Double) {
        statusBarView?.updateCacheHitRate(rate)
    }

    func updateScrollProgress(_ progress: Double) {
        statusBarView?.updateScrollProgress(progress)
    }
}

// MARK: - Find Bar Support

extension MainWindowController {
    func showFindBar() {
        findBarCoordinator?.showFindBar()
    }

    func findNext() {
        findBarCoordinator?.findNext()
    }

    func findPrevious() {
        findBarCoordinator?.findPrevious()
    }
}

// MARK: - Window Delegate

extension MainWindowController: NSWindowDelegate {

    // MARK: - Full Screen Transitions (Stage Manager Aware)

    func windowWillEnterFullScreen(_ notification: Notification) {
        isTransitioningFullScreen = true

        // Save window frame for restoration after exiting full screen
        if let window = window {
            savedWindowFrame = window.frame
        }

        // Ensure proper responder chain
        window?.makeFirstResponder(markdownViewController?.textView)
    }

    func windowDidEnterFullScreen(_ notification: Notification) {
        isTransitioningFullScreen = false

        // Re-establish first responder after full-screen transition
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(self?.markdownViewController?.textView)
        }
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        isTransitioningFullScreen = true
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        isTransitioningFullScreen = false

        // Restore first responder after exiting full-screen
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let window = self.window else { return }

            self.window?.makeFirstResponder(self.markdownViewController?.textView)

            // Restore saved window frame if valid
            if self.savedWindowFrame != .zero {
                // Ensure the saved frame is still valid for current screen configuration
                if let screen = window.screen ?? NSScreen.main {
                    let visibleFrame = screen.visibleFrame
                    var restoredFrame = self.savedWindowFrame

                    // Adjust if saved frame is now off-screen
                    if !visibleFrame.intersects(restoredFrame) {
                        restoredFrame.origin.x = visibleFrame.midX - restoredFrame.width / 2
                        restoredFrame.origin.y = visibleFrame.midY - restoredFrame.height / 2
                    }

                    window.setFrame(restoredFrame, display: true, animate: true)
                }
            }
        }
    }

    // MARK: - Window Resize (Stage Manager Support)

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        // Enforce minimum and maximum sizes for Stage Manager compatibility
        var adjustedSize = frameSize

        adjustedSize.width = max(adjustedSize.width, MainWindowController.minimumWindowSize.width)
        adjustedSize.height = max(adjustedSize.height, MainWindowController.minimumWindowSize.height)
        adjustedSize.width = min(adjustedSize.width, MainWindowController.maximumWindowSize.width)
        adjustedSize.height = min(adjustedSize.height, MainWindowController.maximumWindowSize.height)

        return adjustedSize
    }

    func windowDidResize(_ notification: Notification) {
        // Notify views of resize for layout optimization
        contentStackView?.layoutSubtreeIfNeeded()
    }

    // MARK: - Window State Restoration

    func window(_ window: NSWindow, willEncodeRestorableState state: NSCoder) {
        // Encode current document URL for restoration
        if let documentURL = currentDocument?.url {
            state.encode(documentURL.absoluteString, forKey: "documentURL")
        }

        // Encode window frame
        state.encode(NSStringFromRect(window.frame), forKey: "windowFrame")

        // Encode UI state
        state.encode(tocViewController?.view.isHidden ?? true, forKey: "tocHidden")
        state.encode(statusBarView?.isHidden ?? false, forKey: "statusBarHidden")
    }

    func window(_ window: NSWindow, didDecodeRestorableState state: NSCoder) {
        // Restore document if URL was saved
        if let urlString = state.decodeObject(forKey: "documentURL") as? String,
           let documentURL = URL(string: urlString),
           FileManager.default.fileExists(atPath: documentURL.path) {
            DispatchQueue.main.async { [weak self] in
                self?.loadDocument(at: documentURL)
            }
        }

        // Restore window frame
        if let frameString = state.decodeObject(forKey: "windowFrame") as? String {
            let savedFrame = NSRectFromString(frameString)
            if savedFrame != .zero {
                // Validate frame is still on screen
                if let screen = window.screen ?? NSScreen.main {
                    let visibleFrame = screen.visibleFrame
                    if visibleFrame.intersects(savedFrame) {
                        window.setFrame(savedFrame, display: false)
                    }
                }
            }
        }

        // Restore UI state
        tocViewController?.view.isHidden = state.decodeBool(forKey: "tocHidden")
        statusBarView?.isHidden = state.decodeBool(forKey: "statusBarHidden")
    }

    // MARK: - Window Move (Stage Manager Awareness)

    func windowDidMove(_ notification: Notification) {
        // Track window position for Stage Manager persistence
        guard let window = window, !isTransitioningFullScreen else { return }
        savedWindowFrame = window.frame
    }
}

