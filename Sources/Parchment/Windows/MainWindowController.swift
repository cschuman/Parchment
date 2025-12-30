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
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.center()
        window.collectionBehavior = [.fullScreenPrimary, .managed]
        
        self.init(window: window)
        toolbarCoordinator.actionDelegate = self
        exportCoordinator = ExportCoordinator(window: window)
        window.toolbar = toolbarCoordinator.createToolbar()
        window.delegate = self
        setupViews()
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
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            
            tocView.isHidden.toggle()
            splitView?.layoutSubtreeIfNeeded()
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
    
    func adjustZoom(delta: CGFloat) {
        markdownViewController?.adjustZoom(delta: delta)
    }
    
    func resetZoom() {
        markdownViewController?.resetZoom()
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
    func windowWillEnterFullScreen(_ notification: Notification) {
        // Ensure proper responder chain
        window?.makeFirstResponder(markdownViewController?.textView)
    }
    
    func windowDidEnterFullScreen(_ notification: Notification) {
        // Re-establish first responder after full-screen transition
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(self?.markdownViewController?.textView)
        }
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        // Restore first responder after exiting full-screen
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(self?.markdownViewController?.textView)
        }
    }
}

