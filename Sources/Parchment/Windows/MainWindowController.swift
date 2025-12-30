import Cocoa
import Markdown
import UniformTypeIdentifiers

class MainWindowController: NSWindowController {
    internal var markdownViewController: MarkdownViewController?
    private var tocViewController: TableOfContentsViewController?
    private var splitView: NSSplitView?
    private var statusBarView: StatusBarView?
    private var contentStackView: NSStackView?
    private var currentDocument: MarkdownDocument?
    private var fileWatcher: FileWatcher?
    private let documentExporter = DocumentExporter()
    private var findBarView: FindBarView?
    private var findMatches: [NSRange] = []
    private var dropView: DropView?
    
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
        window.toolbar = createToolbar()
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
        findBarView?.delegate = self
        findBarView?.isHidden = true
        findBarView?.translatesAutoresizingMaskIntoConstraints = false
        
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
    
    private func createToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = true
        return toolbar
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
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = contentTypes(for: format)
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = (document.url?.deletingPathExtension().lastPathComponent ?? "Untitled") + fileExtension(for: format)
        
        savePanel.beginSheetModal(for: window!) { [weak self] response in
            guard response == .OK, let url = savePanel.url else { return }
            
            Task {
                do {
                    let options = self?.createExportOptions(for: format) ?? ExportOptions()
                    try await self?.documentExporter.export(document: document, to: format, at: url, options: options)
                    
                    await MainActor.run {
                        self?.showExportSuccess(url: url)
                    }
                } catch {
                    await MainActor.run {
                        self?.showError("Export failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func contentTypes(for format: DocumentExporter.ExportFormat) -> [UTType] {
        switch format {
        case .pdf:
            return [.pdf]
        case .html:
            return [.html]
        case .rtf:
            return [.rtf]
        case .docx:
            return [UTType(filenameExtension: "docx")!]
        case .plainText:
            return [.plainText]
        }
    }
    
    private func fileExtension(for format: DocumentExporter.ExportFormat) -> String {
        switch format {
        case .pdf:
            return ".pdf"
        case .html:
            return ".html"
        case .rtf:
            return ".rtf"
        case .docx:
            return ".docx"
        case .plainText:
            return ".txt"
        }
    }
    
    private func createExportOptions(for format: DocumentExporter.ExportFormat) -> ExportOptions {
        var options = ExportOptions()
        options.format = format
        
        if NSApp.appearance?.name == .darkAqua {
            options.theme = .dark
        }
        
        return options
    }
    
    private func showExportSuccess(url: URL) {
        let alert = NSAlert()
        alert.messageText = "Export Successful"
        alert.informativeText = "Document exported to \(url.lastPathComponent)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Show in Finder")
        
        alert.beginSheetModal(for: window!) { response in
            if response == .alertSecondButtonReturn {
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.beginSheetModal(for: window!) { _ in }
    }
}

extension MainWindowController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier {
        case .focusMode:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Focus Mode"
            item.toolTip = "Toggle Focus Mode - Dims surrounding text"
            item.image = NSImage(systemSymbolName: "circle.dashed", accessibilityDescription: "Focus Mode")
            item.action = #selector(toggleFocusMode)
            item.target = self
            return item
            
        case .tableOfContents:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Contents"
            item.toolTip = "Toggle Table of Contents"
            item.image = NSImage(systemSymbolName: "list.bullet.indent", accessibilityDescription: "Table of Contents")
            item.action = #selector(toggleTableOfContents)
            item.target = self
            return item
            
        case .readingStats:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Statistics"
            item.toolTip = "Show Reading Statistics"
            item.image = NSImage(systemSymbolName: "chart.bar", accessibilityDescription: "Statistics")
            item.action = #selector(showReadingStatistics)
            item.target = self
            return item
            
        default:
            return nil
        }
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.focusMode, .tableOfContents, .flexibleSpace, .readingStats]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.focusMode, .tableOfContents, .readingStats, .flexibleSpace]
    }
}

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

extension NSToolbarItem.Identifier {
    static let focusMode = NSToolbarItem.Identifier("FocusMode")
    static let tableOfContents = NSToolbarItem.Identifier("TableOfContents")
    static let readingStats = NSToolbarItem.Identifier("ReadingStats")
}

// MARK: - Status Bar Delegate

protocol StatusBarDelegate: AnyObject {
    func updateParseTime(_ time: TimeInterval)
    func updateRenderTime(_ time: TimeInterval)
    func updateCacheHitRate(_ rate: Double)
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
}

// MARK: - Find Bar Support

extension MainWindowController {
    func showFindBar() {
        findBarView?.isHidden = false
        findBarView?.focusAndSelectAll()
    }
    
    func findNext() {
        if findBarView?.isHidden == false {
            findBarView?.findNext()
        }
    }
    
    func findPrevious() {
        if findBarView?.isHidden == false {
            findBarView?.findPrevious()
        }
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

extension MainWindowController: FindBarDelegate {
    func findBarDidSearch(_ searchText: String, completion: @escaping (Int) -> Void) {
        guard let textView = markdownViewController?.textView,
              let textStorage = textView.textStorage else {
            completion(0)
            return
        }
        
        // Clear previous highlights
        findBarClearHighlights()
        findMatches.removeAll()
        
        // Search for all matches
        let text = textStorage.string as NSString
        var searchStart = 0
        
        while searchStart < text.length {
            let range = text.range(of: searchText, 
                                  options: [.caseInsensitive], 
                                  range: NSRange(location: searchStart, length: text.length - searchStart))
            
            if range.location != NSNotFound {
                findMatches.append(range)
                
                // Highlight the match
                textStorage.addAttribute(.backgroundColor, 
                                        value: NSColor.systemYellow.withAlphaComponent(0.3), 
                                        range: range)
                
                searchStart = range.location + range.length
            } else {
                break
            }
        }
        
        completion(findMatches.count)
    }
    
    func findBarHighlightMatch(at index: Int) {
        guard index < findMatches.count,
              let textView = markdownViewController?.textView,
              let textStorage = textView.textStorage else { return }
        
        // Remove current highlight
        for (i, range) in findMatches.enumerated() {
            let color = i == index ? 
                NSColor.systemOrange.withAlphaComponent(0.5) : 
                NSColor.systemYellow.withAlphaComponent(0.3)
            textStorage.addAttribute(.backgroundColor, value: color, range: range)
        }
        
        // Scroll to match
        textView.scrollRangeToVisible(findMatches[index])
    }
    
    func findBarClearHighlights() {
        guard let textStorage = markdownViewController?.textView.textStorage else { return }
        
        for range in findMatches {
            textStorage.removeAttribute(.backgroundColor, range: range)
        }
    }
    
    func findBarDidClose() {
        findBarClearHighlights()
        findMatches.removeAll()
        findBarView?.isHidden = true
        markdownViewController?.textView.window?.makeFirstResponder(markdownViewController?.textView)
    }
}