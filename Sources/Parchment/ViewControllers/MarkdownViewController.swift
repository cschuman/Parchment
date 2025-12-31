import Cocoa
import Markdown
import WebKit

// Type aliases to avoid ambiguity
typealias MDText = Markdown.Text

final class MarkdownViewController: NSViewController, ThemeApplicable {
    private enum Configuration {
        static let minZoomLevel: CGFloat = 0.5
        static let maxZoomLevel: CGFloat = 3.0
        static let defaultZoomLevel: CGFloat = 1.0
        static let zoomStep: CGFloat = 0.1
    }

    private(set) var scrollView: NSScrollView!
    private(set) var textView: MarkdownTextView!
    private(set) var currentDocument: MarkdownDocument?
    private(set) var typewriterScrollingEnabled = false
    private var zoomLevel: CGFloat = Configuration.defaultZoomLevel
    private var statisticsOverlay: StatisticsOverlayView?

    // Extracted components
    private var gestureManager: GestureManager?
    private var typewriterManager: TypewriterScrollManager?
    private var statisticsManager: ReadingStatisticsManager?
    private var navigationCoordinator: NavigationCoordinator?
    private var readingProgressView: ReadingProgressView?
    private var loadingView: LoadingAnimationView?

    // Link hover preview
    private var linkTooltip: LinkPreviewTooltip?
    private var linkHoverTimer: Timer?
    private var trackingArea: NSTrackingArea?

    // Reading position restoration
    private var savePositionTimer: Timer?
    private var isRestoringPosition = false

    // Observer registration flag to prevent duplicates
    private var observersRegistered = false

    weak var statusBarDelegate: StatusBarDelegate?
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    deinit {
        // Invalidate timers to prevent memory leaks
        linkHoverTimer?.invalidate()
        linkHoverTimer = nil
        savePositionTimer?.invalidate()
        savePositionTimer = nil

        // Clean up link tooltip explicitly
        linkTooltip?.hide()
        linkTooltip = nil

        // Remove tracking area if present
        if let area = trackingArea {
            textView?.removeTrackingArea(area)
            trackingArea = nil
        }

        // Remove notification observers
        NotificationCenter.default.removeObserver(self)
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        setupViews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup enhanced features after view hierarchy is complete
        setupEnhancedFeatures()

        // Enable smooth scrolling with spring physics
        scrollView.enableSmoothScrolling()

        // Register observers only once to prevent duplicates
        guard !observersRegistered else { return }
        observersRegistered = true

        // Listen for preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesChanged),
            name: .preferencesChanged,
            object: nil
        )

        // Listen for theme changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: .themeDidChange,
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
        scrollView.setAccessibilityLabel("Document scroll view")

        // Enable smooth scrolling with spring physics
        scrollView.enableSmoothScrolling()

        textView = MarkdownTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.importsGraphics = false
        textView.textContainerInset = NSSize(width: 40, height: 40)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        textView.drawsBackground = true
        textView.setAccessibilityElement(true)
        textView.setAccessibilityRole(.textArea)
        textView.setAccessibilityLabel("Markdown document content")
        
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
        gestureManager = GestureManager(scrollView: scrollView)
        gestureManager?.delegate = self
        
        // Setup typewriter scroll manager
        typewriterManager = TypewriterScrollManager(textView: textView, scrollView: scrollView)
        
        // Setup statistics manager
        statisticsManager = ReadingStatisticsManager(parentView: view)

        // Setup navigation coordinator
        navigationCoordinator = NavigationCoordinator(textView: textView, scrollView: scrollView)

        // Setup reading progress indicator
        readingProgressView = ReadingProgressView()
        readingProgressView?.translatesAutoresizingMaskIntoConstraints = false
        if let progressView = readingProgressView {
            view.addSubview(progressView)
            NSLayoutConstraint.activate([
                progressView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
                progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                progressView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
                progressView.widthAnchor.constraint(equalToConstant: 12)
            ])
        }

        // Setup loading animation view
        loadingView = LoadingAnimationView()
        loadingView?.translatesAutoresizingMaskIntoConstraints = false
        if let loading = loadingView {
            view.addSubview(loading)
            NSLayoutConstraint.activate([
                loading.topAnchor.constraint(equalTo: view.topAnchor),
                loading.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                loading.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                loading.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        // Setup link hover tooltip
        linkTooltip = LinkPreviewTooltip(theme: ParchmentTheme.current)

        // Setup mouse tracking for link hovers
        setupLinkTracking()
    }

    private func setupLinkTracking() {
        // Remove old tracking area if present (safe to call multiple times)
        if let oldArea = trackingArea {
            textView.removeTrackingArea(oldArea)
            trackingArea = nil
        }

        // Create tracking area for mouse movement
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect]
        trackingArea = NSTrackingArea(rect: .zero, options: options, owner: self, userInfo: nil)
        if let area = trackingArea {
            textView.addTrackingArea(area)
        }
    }

    override func mouseMoved(with event: NSEvent) {
        handleMouseMovement(event)
    }

    private func handleMouseMovement(_ event: NSEvent) {
        // Convert event location to text view coordinates
        let windowPoint = event.locationInWindow
        let textViewPoint = textView.convert(windowPoint, from: nil)

        // Check if over a link
        if let url = linkAt(point: textViewPoint) {
            scheduleLinkTooltip(url: url, at: textViewPoint)
        } else {
            cancelLinkTooltip()
        }
    }

    private func linkAt(point: NSPoint) -> URL? {
        // Get character index at point
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return nil }

        // Adjust point for text container inset
        let adjustedPoint = NSPoint(
            x: point.x - textView.textContainerInset.width,
            y: point.y - textView.textContainerInset.height
        )

        let characterIndex = layoutManager.characterIndex(for: adjustedPoint, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        guard characterIndex < textView.textStorage?.length ?? 0 else { return nil }

        // Check for link attribute
        if let link = textView.textStorage?.attribute(.link, at: characterIndex, effectiveRange: nil) {
            if let url = link as? URL {
                return url
            } else if let urlString = link as? String, let url = URL(string: urlString) {
                return url
            }
        }

        return nil
    }

    private func scheduleLinkTooltip(url: URL, at point: NSPoint) {
        // Cancel existing timer
        linkHoverTimer?.invalidate()

        // Schedule new tooltip after delay
        linkHoverTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.showLinkTooltip(url: url, at: point)
        }
    }

    private func showLinkTooltip(url: URL, at point: NSPoint) {
        linkTooltip?.show(url: url, near: point, in: textView)
    }

    private func cancelLinkTooltip() {
        linkHoverTimer?.invalidate()
        linkHoverTimer = nil
        linkTooltip?.hide()
    }

    internal func navigateToNextHeader() {
        navigationCoordinator?.navigateToNextHeader()
    }
    
    internal func navigateToPreviousHeader() {
        navigationCoordinator?.navigateToPreviousHeader()
    }

    func jumpToTop() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            scrollView.contentView.animator().setBoundsOrigin(.zero)
        }
    }

    func jumpToBottom() {
        guard let documentView = scrollView.documentView else { return }
        let maxY = documentView.frame.height - scrollView.contentSize.height
        let targetPoint = NSPoint(x: 0, y: max(0, maxY))

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            scrollView.contentView.animator().setBoundsOrigin(targetPoint)
        }
    }

    /// Set reading mode with centered, width-constrained text
    func setReadingModeWidth(_ maxWidth: CGFloat?) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true

            if let width = maxWidth {
                // Center the text container with max width
                textView.textContainerInset = NSSize(width: 0, height: 40)

                // Calculate horizontal inset for centering
                let viewWidth = scrollView.frame.width
                let horizontalInset = max(60, (viewWidth - width) / 2)
                textView.textContainerInset = NSSize(width: horizontalInset, height: 40)

                // Ensure text container respects width
                textView.textContainer?.size = NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)
            } else {
                // Restore default insets
                let theme = ParchmentTheme.current
                textView.textContainerInset = NSSize(
                    width: theme.contentInsets.left,
                    height: theme.contentInsets.top
                )

                // Reset text container width
                textView.textContainer?.size = NSSize(
                    width: scrollView.frame.width - theme.contentInsets.left - theme.contentInsets.right,
                    height: CGFloat.greatestFiniteMagnitude
                )
            }

            textView.needsLayout = true
            textView.needsDisplay = true
        }
    }

    func loadDocument(_ document: MarkdownDocument) {
        currentDocument = document

        // Update accessibility with document info
        let fileName = document.url?.lastPathComponent ?? "Untitled"
        textView.setAccessibilityLabel("Markdown document: \(fileName)")

        // Always use normal loading path - simplified
        loadNormalDocument(document)
    }
    
    private func loadNormalDocument(_ document: MarkdownDocument) {
        // Show loading animation for larger documents
        let showLoading = document.content.count > 5000
        if showLoading {
            loadingView?.show(message: "Rendering document...")
        }

        // Capture values needed for background work
        let content = document.content
        let currentTheme = ParchmentTheme.current
        let zoom = zoomLevel

        // Parse and render on background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Track parse time
            let parseStart = CFAbsoluteTimeGetCurrent()

            let parseTime = CFAbsoluteTimeGetCurrent() - parseStart

            // Track render time
            let renderStart = CFAbsoluteTimeGetCurrent()

            // Use enhanced renderer with current theme
            // render(markdownText:) handles footnote pre-processing and parsing
            let renderer = EnhancedMarkdownRenderer(theme: currentTheme, zoomLevel: zoom)
            let attributedString = renderer.render(markdownText: content)

            let renderTime = CFAbsoluteTimeGetCurrent() - renderStart

            // Update UI on main thread
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // Update timing metrics
                self.statusBarDelegate?.updateParseTime(parseTime)
                self.statusBarDelegate?.updateRenderTime(renderTime)

                // Set the attributed string
                self.textView.textStorage?.setAttributedString(attributedString)

                // Ensure text view is sized properly
                self.textView.sizeToFit()

                // Restore saved reading position or scroll to top
                self.restoreScrollPosition()

                // Force update
                self.textView.needsDisplay = true

                // Hide loading animation
                if showLoading {
                    self.loadingView?.hide()
                }
            }
        }
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
        zoomLevel = max(Configuration.minZoomLevel, min(Configuration.maxZoomLevel, zoomLevel))
        applyZoom()
    }

    func resetZoom() {
        zoomLevel = Configuration.defaultZoomLevel
        applyZoom()
    }
    
    func applyTheme(_ theme: ParchmentTheme, animated: Bool = true) {
        // Save scroll position before theme change
        let scrollPercentage = calculateScrollPercentage()

        if animated {
            // Create smooth cross-fade transition
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                context.allowsImplicitAnimation = true

                // Animate background colors
                scrollView?.animator().backgroundColor = theme.backgroundColor
                textView?.animator().backgroundColor = theme.backgroundColor

                // Apply non-animatable properties
                textView?.textColor = theme.textColor
                textView?.insertionPointColor = theme.cursorColor
                textView?.selectedTextAttributes = [
                    .backgroundColor: theme.selectionColor
                ]

                // Apply theme to reading progress indicator
                readingProgressView?.applyTheme(theme)

                // Apply theme to link tooltip
                linkTooltip?.applyTheme(theme)

                // Apply theme to loading view
                loadingView?.applyTheme(theme, animated: true)

            } completionHandler: { [weak self] in
                // Rerender document after animation completes
                self?.rerenderWithTheme(theme, scrollPercentage: scrollPercentage)
            }
        } else {
            // Instant application (for initial load)
            scrollView?.backgroundColor = theme.backgroundColor
            textView?.backgroundColor = theme.backgroundColor
            textView?.textColor = theme.textColor
            textView?.insertionPointColor = theme.cursorColor
            textView?.selectedTextAttributes = [
                .backgroundColor: theme.selectionColor
            ]
            readingProgressView?.applyTheme(theme)
            linkTooltip?.applyTheme(theme)
            loadingView?.applyTheme(theme, animated: false)
            rerenderWithTheme(theme, scrollPercentage: scrollPercentage)
        }

        scrollView?.drawsBackground = true
        textView?.drawsBackground = true
    }

    private func rerenderWithTheme(_ theme: ParchmentTheme, scrollPercentage: CGFloat) {
        guard let document = currentDocument else { return }

        // Use new renderer with updated theme
        // render(markdownText:) handles footnote pre-processing and parsing
        let renderer = EnhancedMarkdownRenderer(theme: theme, zoomLevel: zoomLevel)
        let attributedString = renderer.render(markdownText: document.content)

        // Set the new attributed string
        textView?.textStorage?.setAttributedString(attributedString)
        textView?.sizeToFit()

        // Restore scroll position after layout
        DispatchQueue.main.async { [weak self] in
            self?.restoreScrollPercentage(scrollPercentage)
        }

        // Force view updates
        scrollView?.needsDisplay = true
        textView?.needsDisplay = true
    }

    private func calculateScrollPercentage() -> CGFloat {
        let documentHeight = textView.frame.height
        let visibleRect = scrollView.contentView.visibleRect
        let scrollableHeight = documentHeight - visibleRect.height

        guard scrollableHeight > 0 else { return 0 }

        return visibleRect.origin.y / scrollableHeight
    }

    private func restoreScrollPercentage(_ percentage: CGFloat) {
        let documentHeight = textView.frame.height
        let visibleHeight = scrollView.contentView.bounds.height
        let scrollableHeight = documentHeight - visibleHeight

        guard scrollableHeight > 0 else { return }

        let targetY = scrollableHeight * percentage
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: targetY))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
    
    private func applyZoom() {
        guard let document = currentDocument else { return }
        loadDocument(document)
    }
    
    @objc private func scrollViewDidScroll(_ notification: Notification) {
        // Update status bar progress in real-time
        updateStatusBarProgress()

        // Update reading progress indicator
        updateReadingProgress()

        // Don't save position while restoring
        guard !isRestoringPosition else { return }

        // Debounce position saving (500ms after scroll stops)
        savePositionTimer?.invalidate()
        savePositionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.saveCurrentScrollPosition()
        }
    }

    private func updateReadingProgress() {
        let documentHeight = textView.frame.height
        let visibleRect = scrollView.contentView.visibleRect
        let scrollableHeight = documentHeight - visibleRect.height

        guard scrollableHeight > 0 else {
            readingProgressView?.updateProgress(0)
            return
        }

        let percentage = visibleRect.origin.y / scrollableHeight
        let clampedPercentage = CGFloat(min(max(percentage, 0), 1))
        readingProgressView?.updateProgress(clampedPercentage)
    }

    private func updateStatusBarProgress() {
        let documentHeight = textView.frame.height
        let visibleRect = scrollView.contentView.visibleRect
        let scrollableHeight = documentHeight - visibleRect.height

        guard scrollableHeight > 0 else {
            statusBarDelegate?.updateScrollProgress(0)
            return
        }

        let percentage = visibleRect.origin.y / scrollableHeight
        let clampedPercentage = min(max(percentage, 0), 1)
        statusBarDelegate?.updateScrollProgress(clampedPercentage)
    }

    private func saveCurrentScrollPosition() {
        guard let url = currentDocument?.url else { return }

        let documentHeight = textView.frame.height
        let visibleRect = scrollView.contentView.visibleRect
        let scrollableHeight = documentHeight - visibleRect.height

        guard scrollableHeight > 0 else { return }

        let percentage = visibleRect.origin.y / scrollableHeight
        let clampedPercentage = min(max(percentage, 0), 1)

        ReadingPositionManager.shared.save(url: url, percentage: clampedPercentage)
    }

    private func restoreScrollPosition() {
        guard let url = currentDocument?.url,
              let percentage = ReadingPositionManager.shared.position(for: url),
              percentage > 0.01 else {
            // No saved position, scroll to top
            textView.scrollToBeginningOfDocument(nil)
            return
        }

        isRestoringPosition = true

        // Delay slightly to ensure content is fully laid out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            let documentHeight = self.textView.frame.height
            let visibleRect = self.scrollView.contentView.visibleRect
            let scrollableHeight = documentHeight - visibleRect.height

            guard scrollableHeight > 0 else {
                self.isRestoringPosition = false
                return
            }

            let targetY = scrollableHeight * percentage
            let targetPoint = NSPoint(x: 0, y: targetY)

            // Animate scroll to restored position
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.scrollView.contentView.animator().setBoundsOrigin(targetPoint)
            }, completionHandler: { [weak self] in
                self?.isRestoringPosition = false
                self?.showResumedToast(percentage: percentage)
            })
        }
    }

    private func showResumedToast(percentage: Double) {
        let percentText = Int(percentage * 100)
        guard percentText > 0 else { return }

        let toast = NSTextField(labelWithString: "Resumed at \(percentText)%")
        toast.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        toast.textColor = .white
        toast.backgroundColor = NSColor.black.withAlphaComponent(0.75)
        toast.isBezeled = false
        toast.drawsBackground = true
        toast.alignment = .center
        toast.wantsLayer = true
        toast.layer?.cornerRadius = 6

        toast.sizeToFit()
        toast.frame.size.width += 24
        toast.frame.size.height += 12

        // Position at bottom center
        let viewBounds = view.bounds
        toast.frame.origin.x = (viewBounds.width - toast.frame.width) / 2
        toast.frame.origin.y = 40

        toast.alphaValue = 0
        view.addSubview(toast)

        // Fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            toast.animator().alphaValue = 1.0
        }

        // Fade out after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                toast.animator().alphaValue = 0
            }, completionHandler: {
                toast.removeFromSuperview()
            })
        }
    }

    @objc private func preferencesChanged() {
        applyPreferences()
        if let document = currentDocument {
            loadDocument(document)
        }
    }
    
    @objc private func themeDidChange() {
        // Apply theme to views
        let theme = ParchmentTheme.current
        textView.applyTheme(theme)
        scrollView.applyTheme(theme)

        // Re-render with new theme
        if let document = currentDocument {
            loadNormalDocument(document)
        }
    }
    
    private func applyPreferences() {
        // Apply current theme from ParchmentTheme
        let theme = ParchmentTheme.current
        applyTheme(theme)

        // Apply typewriter mode
        if UserDefaults.standard.bool(forKey: "typewriterMode") {
            enableTypewriterScrolling()
        } else {
            disableTypewriterScrolling()
        }
    }
    
}

// MARK: - GestureManagerDelegate

extension MarkdownViewController: GestureManagerDelegate {
    func gestureManagerDidRequestZoom(_ manager: GestureManager, to level: CGFloat) {
        zoomLevel = level
        applyZoom()
    }
    
    func gestureManagerDidUpdateZoom(_ manager: GestureManager, to level: CGFloat) {
        zoomLevel = level
        applyZoom()
    }
    
    func gestureManagerDidRequestNavigation(_ manager: GestureManager, direction: NavigationDirection) {
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
    
    func gestureManagerDidToggleFocusMode(_ manager: GestureManager) {
        toggleFocusMode()
    }
}


