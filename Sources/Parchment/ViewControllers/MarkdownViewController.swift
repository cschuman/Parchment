import Cocoa
import Markdown
import WebKit

// Type aliases to avoid ambiguity
typealias MDText = Markdown.Text

class MarkdownViewController: NSViewController {
    internal var scrollView: NSScrollView!
    internal var textView: MarkdownTextView!
    private var webView: WKWebView?
    internal var currentDocument: MarkdownDocument?
    internal var typewriterScrollingEnabled = false
    private var zoomLevel: CGFloat = 1.0
    private var statisticsOverlay: StatisticsOverlayView?
    internal var visibleRange: NSRange = NSRange(location: 0, length: 0)
    private var isLargeDocument = false
    private var currentCursorLine: Int = 0
    
    // Extracted components
    private let syntaxHighlighter: SyntaxHighlighting = CodeSyntaxHighlighter()
    private var gestureManager: MarkdownGestureManager?
    private var typewriterManager: TypewriterScrollManager?
    private var statisticsManager: ReadingStatisticsManager?
    private var navigationCoordinator: DocumentNavigationCoordinator?
    
    weak var statusBarDelegate: StatusBarDelegate?
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        setupViews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup enhanced features after view hierarchy is complete
        setupEnhancedFeatures()
        
        // Listen for preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesChanged),
            name: .preferencesChanged,
            object: nil
        )
        
        // Apply initial preferences
        applyPreferences()
    }
    
    private func setupViews() {
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)
        
        textView = MarkdownTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.importsGraphics = false
        textView.textContainerInset = NSSize(width: 40, height: 40)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        textView.drawsBackground = true
        
        // Ensure the text view fills the scroll view
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: 680, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        
        scrollView.documentView = textView
        
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidScroll),
            name: NSScrollView.didLiveScrollNotification,
            object: scrollView
        )
        
        // Setup gesture manager
        gestureManager = MarkdownGestureManager(scrollView: scrollView)
        gestureManager?.delegate = self
        
        // Setup typewriter scroll manager
        typewriterManager = TypewriterScrollManager(textView: textView, scrollView: scrollView)
        
        // Setup statistics manager
        statisticsManager = ReadingStatisticsManager(parentView: view)
        
        // Setup navigation coordinator
        navigationCoordinator = DocumentNavigationCoordinator(textView: textView, scrollView: scrollView)
    }
    
    
    internal func navigateToNextHeader() {
        navigationCoordinator?.navigateToNextHeader()
    }
    
    internal func navigateToPreviousHeader() {
        navigationCoordinator?.navigateToPreviousHeader()
    }
    
    
    func loadDocument(_ document: MarkdownDocument) {
        currentDocument = document
        
        // Focus mode reset removed - simplified
        
        // Always use normal loading path - simplified
        loadNormalDocument(document)
    }
    
    private func loadNormalDocument(_ document: MarkdownDocument) {
        
        // Track parse time
        let parseStart = CFAbsoluteTimeGetCurrent()
        
        // Parse with swift-markdown (supports strikethrough, tables, etc.)
        let parsedDoc = Document(parsing: document.content)
        
        let parseTime = CFAbsoluteTimeGetCurrent() - parseStart
        statusBarDelegate?.updateParseTime(parseTime)
        
        // Track render time
        let renderStart = CFAbsoluteTimeGetCurrent()
        
        // Convert to attributed string synchronously for now
        let visitor = MarkdownAttributedStringVisitor(zoomLevel: zoomLevel)
        let attributedString = visitor.convertDocument(parsedDoc)
        
        let renderTime = CFAbsoluteTimeGetCurrent() - renderStart
        statusBarDelegate?.updateRenderTime(renderTime)
        
        // Set the attributed string on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { 
                return 
            }
            
            // Set the attributed string
            self.textView.textStorage?.setAttributedString(attributedString)
            
            // Ensure text view is sized properly
            self.textView.sizeToFit()
            
            // TOC update removed - simplified
            
            // Scroll to top
            self.textView.scrollToBeginningOfDocument(nil)
            
            // Force update
            self.textView.needsDisplay = true
        }
    }
    
    private func createImagePlaceholder(size: NSSize, text: String) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Fill with light gray background
        NSColor.controlBackgroundColor.set()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw border
        NSColor.tertiaryLabelColor.set()
        NSRect(origin: .zero, size: size).frame()
        
        // Draw text
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let attrString = NSAttributedString(string: text, attributes: attrs)
        let textSize = attrString.size()
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        attrString.draw(in: textRect)
        
        image.unlockFocus()
        return image
    }
    
    private func scaleImage(_ image: NSImage, maxWidth: CGFloat) -> NSImage {
        let originalSize = image.size
        
        // If image is smaller than max width, return as-is
        if originalSize.width <= maxWidth {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = originalSize.height / originalSize.width
        let newWidth = maxWidth
        let newHeight = newWidth * aspectRatio
        let newSize = NSSize(width: newWidth, height: newHeight)
        
        // Create new image with scaled size
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        newImage.unlockFocus()
        
        return newImage
    }
    
    private func highlightCode(_ code: String, language: String?) -> NSAttributedString {
        // Delegate to the extracted syntax highlighter
        let fontSize = textView?.font?.pointSize ?? 13
        let theme = ThemeManager.shared.currentTheme
        return syntaxHighlighter.highlight(code: code, language: language, fontSize: fontSize, theme: theme)
    }
    
    
    
    func updateDocument(_ document: MarkdownDocument, diff: DiffHighlighter.DiffResult) {
        currentDocument = document
        
        // Save scroll position as percentage of document height
        let visibleRect = scrollView.contentView.visibleRect
        let documentHeight = textView.frame.height
        let scrollPercentage = documentHeight > 0 ? visibleRect.origin.y / documentHeight : 0
        
        // Re-render the document
        loadNormalDocument(document)
        
        // Apply diff highlighting after rendering
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let textStorage = self.textView.textStorage else { return }
            
            // Apply diff highlighting
            DiffHighlighter.applyDiffHighlighting(
                to: textStorage,
                diff: diff,
                duration: 2.0
            )
            
            // Animate the highlighting
            DiffHighlighter.animateDiffHighlighting(
                in: self.textView,
                diff: diff
            )
            
            // Restore scroll position based on percentage
            let newDocumentHeight = self.textView.frame.height
            let newScrollPosition = NSPoint(x: 0, y: scrollPercentage * newDocumentHeight)
            self.scrollView.contentView.animator().setBoundsOrigin(newScrollPosition)
            
            // Show notification in status bar
            self.showDiffNotification(added: diff.added.count, modified: diff.modified.count, deleted: diff.deleted.count)
        }
    }
    
    private func showDiffNotification(added: Int, modified: Int, deleted: Int) {
        var parts: [String] = []
        if added > 0 { parts.append("+\(added) added") }
        if modified > 0 { parts.append("~\(modified) modified") }
        if deleted > 0 { parts.append("-\(deleted) deleted") }
        
        if !parts.isEmpty {
            let message = "File updated: \(parts.joined(separator: ", "))"
            
            // Create a temporary overlay to show the notification
            let notification = NSTextField(labelWithString: message)
            notification.font = NSFont.systemFont(ofSize: 11)
            notification.textColor = NSColor.secondaryLabelColor
            notification.backgroundColor = NSColor.controlBackgroundColor
            notification.isBordered = true
            notification.wantsLayer = true
            notification.layer?.cornerRadius = 4
            notification.layer?.borderColor = NSColor.separatorColor.cgColor
            notification.layer?.borderWidth = 1
            
            notification.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(notification)
            
            NSLayoutConstraint.activate([
                notification.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
                notification.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10)
            ])
            
            // Fade in
            notification.alphaValue = 0
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                notification.animator().alphaValue = 1.0
            }
            
            // Fade out and remove after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    notification.animator().alphaValue = 0
                }) {
                    notification.removeFromSuperview()
                }
            }
        }
    }
    
    private func displayRenderedContent(_ content: NSAttributedString) {
        Logger.debug("Displaying content with length: \(content.length)", category: Logger.rendering)
        textView.textStorage?.setAttributedString(content)
        
        // Ensure the text view is sized properly
        textView.sizeToFit()
        
        // Focus mode is now handled by EnhancedFocusMode
    }
    
    
    // Old focus mode implementation removed - now using EnhancedFocusMode
    
    // MARK: - Typewriter Scrolling
    
    internal func enableTypewriterScrolling() {
        typewriterManager?.enable()
        typewriterScrollingEnabled = true
    }
    
    internal func disableTypewriterScrolling() {
        typewriterManager?.disable()
        typewriterScrollingEnabled = false
    }
    
    func showReadingStatistics() {
        guard let document = currentDocument else { return }
        
        let scrollProgress = calculateScrollProgress()
        statisticsManager?.showStatistics(for: document, scrollProgress: scrollProgress)
    }
    
    private func calculateScrollProgress() -> Double {
        let visibleRect = scrollView.contentView.visibleRect
        let totalHeight = textView.frame.height
        let scrollPosition = visibleRect.origin.y
        
        return min(1.0, max(0.0, (scrollPosition + visibleRect.height) / totalHeight))
    }
    
    func scrollToHeader(_ header: MarkdownHeader) {
        guard let textStorage = textView.textStorage else { return }
        
        let searchRange = NSRange(location: 0, length: textStorage.length)
        var foundRange: NSRange?
        
        // Search for header text directly
        let searchString = textStorage.string as NSString
        searchString.enumerateSubstrings(in: searchRange, options: [.byLines]) { substring, range, _, stop in
            if let line = substring, line.contains(header.title) {
                foundRange = range
                stop.pointee = true
            }
        }
        
        if let range = foundRange {
            textView.scrollRangeToVisible(range)
            // Highlight the found text temporarily
            textView.textStorage?.addAttribute(
                .backgroundColor,
                value: NSColor.systemYellow.withAlphaComponent(0.3),
                range: range
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.textView.textStorage?.removeAttribute(.backgroundColor, range: range)
            }
        }
    }
    
    func adjustZoom(delta: CGFloat) {
        zoomLevel += delta
        zoomLevel = max(0.5, min(3.0, zoomLevel))
        applyZoom()
    }
    
    func resetZoom() {
        zoomLevel = 1.0
        applyZoom()
    }
    
    private func applyZoom() {
        guard let document = currentDocument else { return }
        loadDocument(document)
    }
    
    @objc private func scrollViewDidScroll(_ notification: Notification) {
        updateVisibleRange()
        // Simplified - no special handling for large documents
    }
    
    private func updateVisibleRange() {
        let visibleRect = scrollView.contentView.visibleRect
        let glyphRange = textView.layoutManager?.glyphRange(forBoundingRect: visibleRect, in: textView.textContainer!)
        if let characterRange = textView.layoutManager?.characterRange(forGlyphRange: glyphRange ?? NSRange(), actualGlyphRange: nil) {
            visibleRange = characterRange
        }
    }
    
    @objc private func preferencesChanged() {
        applyPreferences()
        if let document = currentDocument {
            loadDocument(document)
        }
    }
    
    private func applyPreferences() {
        // Apply theme
        let theme = UserDefaults.standard.string(forKey: "theme") ?? "System"
        applyTheme(theme)
        
        // Apply typewriter mode
        if UserDefaults.standard.bool(forKey: "typewriterMode") {
            enableTypewriterScrolling()
        } else {
            disableTypewriterScrolling()
        }
        
        // Apply focus mode default
        if UserDefaults.standard.bool(forKey: "focusModeDefault") {
            // Enable focus mode if set as default
        }
    }
    
    private func applyTheme(_ theme: String) {
        switch theme {
        case "Dark":
            scrollView.backgroundColor = NSColor(calibratedWhite: 0.1, alpha: 1.0)
            textView.backgroundColor = NSColor(calibratedWhite: 0.1, alpha: 1.0)
            textView.textColor = NSColor.white
        case "High Contrast":
            scrollView.backgroundColor = NSColor.black
            textView.backgroundColor = NSColor.black
            textView.textColor = NSColor.white
        case "Solarized Light":
            let bg = NSColor(calibratedRed: 0.99, green: 0.96, blue: 0.89, alpha: 1.0)
            scrollView.backgroundColor = bg
            textView.backgroundColor = bg
            textView.textColor = NSColor(calibratedRed: 0.4, green: 0.48, blue: 0.51, alpha: 1.0)
        case "Solarized Dark":
            let bg = NSColor(calibratedRed: 0.0, green: 0.17, blue: 0.21, alpha: 1.0)
            scrollView.backgroundColor = bg
            textView.backgroundColor = bg
            textView.textColor = NSColor(calibratedRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0)
        default: // Light/System
            scrollView.backgroundColor = NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)
            textView.backgroundColor = NSColor.textBackgroundColor
            textView.textColor = NSColor.labelColor
        }
    }
    
}

// MARK: - GestureManagerDelegate

extension MarkdownViewController: GestureManagerDelegate {
    func gestureManagerDidRequestZoom(_ manager: MarkdownGestureManager, to level: CGFloat) {
        zoomLevel = level
        applyZoom()
    }
    
    func gestureManagerDidUpdateZoom(_ manager: MarkdownGestureManager, to level: CGFloat) {
        zoomLevel = level
        applyZoom()
    }
    
    func gestureManagerDidRequestNavigation(_ manager: MarkdownGestureManager, direction: NavigationDirection) {
        switch direction {
        case .next:
            navigateToNextHeader()
        case .previous:
            navigateToPreviousHeader()
        case .nextDocument:
            NotificationCenter.default.post(name: .navigateToNextDocument, object: nil)
        case .previousDocument:
            NotificationCenter.default.post(name: .navigateToPreviousDocument, object: nil)
        }
    }
    
    func gestureManagerDidToggleFocusMode(_ manager: MarkdownGestureManager) {
        toggleFocusMode()
    }
}

struct SyntaxColors {
    let keyword = NSColor.systemPurple
    let string = NSColor.systemRed
    let comment = NSColor.systemGreen
    let number = NSColor.systemBlue
    let type = NSColor.systemTeal
    let function = NSColor.systemIndigo
    let variable = NSColor.systemOrange
    let operatorColor = NSColor.systemBrown
}

