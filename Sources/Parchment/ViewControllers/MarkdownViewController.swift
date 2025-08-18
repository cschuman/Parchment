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
        
        setupGestureRecognizers()
    }
    
    // MARK: - Gesture Recognition
    
    private func setupGestureRecognizers() {
        // Pinch to zoom
        let pinchGesture = NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        scrollView.addGestureRecognizer(pinchGesture)
        
        // Three-finger swipe for navigation between headers
        let swipeLeft = NSPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.buttonMask = 0x1
        swipeLeft.numberOfTouchesRequired = 3
        scrollView.addGestureRecognizer(swipeLeft)
        
        // Two-finger swipe for history navigation
        let twoFingerSwipe = NSPanGestureRecognizer(target: self, action: #selector(handleTwoFingerSwipe(_:)))
        twoFingerSwipe.buttonMask = 0x1
        twoFingerSwipe.numberOfTouchesRequired = 2
        scrollView.addGestureRecognizer(twoFingerSwipe)
        
        // Double-tap to toggle focus mode
        let doubleTap = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfClicksRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    @objc private func handlePinch(_ gesture: NSMagnificationGestureRecognizer) {
        switch gesture.state {
        case .changed:
            let newZoom = zoomLevel * (1 + gesture.magnification)
            let clampedZoom = max(0.5, min(3.0, newZoom))
            
            if abs(clampedZoom - zoomLevel) > 0.01 {
                zoomLevel = clampedZoom
                applyZoom()
            }
            
        case .ended:
            // Snap to common zoom levels
            if zoomLevel < 0.9 {
                animateZoomTo(1.0)
            } else if zoomLevel > 1.4 && zoomLevel < 1.6 {
                animateZoomTo(1.5)
            } else if zoomLevel > 1.9 && zoomLevel < 2.1 {
                animateZoomTo(2.0)
            }
            
        default:
            break
        }
        
        gesture.magnification = 0
    }
    
    @objc private func handleSwipe(_ gesture: NSPanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let velocity = gesture.velocity(in: scrollView)
        
        if abs(velocity.x) > abs(velocity.y) {
            if velocity.x > 0 {
                navigateToPreviousHeader()
            } else {
                navigateToNextHeader()
            }
        }
    }
    
    @objc private func handleTwoFingerSwipe(_ gesture: NSPanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let velocity = gesture.velocity(in: scrollView)
        
        // Horizontal swipe for document history
        if abs(velocity.x) > abs(velocity.y) && abs(velocity.x) > 100 {
            if velocity.x > 0 {
                // Navigate to previous document
                NotificationCenter.default.post(name: .navigateToPreviousDocument, object: nil)
            } else {
                // Navigate to next document
                NotificationCenter.default.post(name: .navigateToNextDocument, object: nil)
            }
        }
    }
    
    @objc private func handleDoubleTap(_ gesture: NSClickGestureRecognizer) {
        toggleFocusMode()
    }
    
    private func animateZoomTo(_ targetZoom: CGFloat) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            zoomLevel = targetZoom
            applyZoom()
        }
    }
    
    internal func navigateToNextHeader() {
        guard let textStorage = textView.textStorage else { return }
        
        let currentLocation = textView.selectedRange().location
        var nextHeaderLocation: Int?
        
        // Find next header after current position
        textStorage.enumerateAttribute(
            .font,
            in: NSRange(location: currentLocation, length: textStorage.length - currentLocation),
            options: []
        ) { value, range, stop in
            if let font = value as? NSFont, font.fontDescriptor.symbolicTraits.contains(.bold) {
                nextHeaderLocation = range.location
                stop.pointee = true
            }
        }
        
        if let location = nextHeaderLocation {
            scrollToLocation(location)
        }
    }
    
    internal func navigateToPreviousHeader() {
        guard let textStorage = textView.textStorage else { return }
        
        let currentLocation = textView.selectedRange().location
        var previousHeaderLocation: Int?
        
        // Find previous header before current position
        textStorage.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: currentLocation),
            options: [.reverse]
        ) { value, range, stop in
            if let font = value as? NSFont, font.fontDescriptor.symbolicTraits.contains(.bold) {
                previousHeaderLocation = range.location
                stop.pointee = true
            }
        }
        
        if let location = previousHeaderLocation {
            scrollToLocation(location)
        }
    }
    
    private func scrollToLocation(_ location: Int) {
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: location, length: 0), actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            scrollView.contentView.animator().scroll(to: NSPoint(x: 0, y: rect.origin.y))
        }
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
        let baseFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let backgroundColor = NSColor.controlBackgroundColor
        
        // Basic syntax highlighting colors
        let colors = SyntaxColors()
        
        let result = NSMutableAttributedString()
        
        // Add background color block
        let backgroundAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: backgroundColor
        ]
        
        if let lang = language?.lowercased(), !lang.isEmpty {
            // Apply language-specific highlighting
            let highlightedText = applySyntaxHighlighting(to: code, language: lang, baseFont: baseFont, colors: colors)
            result.append(highlightedText)
        } else {
            // No syntax highlighting, just format as code
            result.append(NSAttributedString(string: code, attributes: backgroundAttributes))
        }
        
        // Add padding around code block
        let padding = NSAttributedString(string: "  ", attributes: backgroundAttributes)
        let paddedResult = NSMutableAttributedString()
        
        // Split by lines and add padding
        let lines = code.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            paddedResult.append(padding)
            
            if let lang = language?.lowercased(), !lang.isEmpty {
                let highlightedLine = applySyntaxHighlighting(to: line, language: lang, baseFont: baseFont, colors: colors)
                paddedResult.append(highlightedLine)
            } else {
                paddedResult.append(NSAttributedString(string: line, attributes: backgroundAttributes))
            }
            
            paddedResult.append(padding)
            if index < lines.count - 1 {
                paddedResult.append(NSAttributedString(string: "\n", attributes: backgroundAttributes))
            }
        }
        
        return paddedResult
    }
    
    private func applySyntaxHighlighting(to code: String, language: String, baseFont: NSFont, colors: SyntaxColors) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.controlBackgroundColor
        ]
        
        switch language {
        case "swift":
            result.append(highlightSwift(code, baseFont: baseFont, colors: colors))
        case "javascript", "js":
            result.append(highlightJavaScript(code, baseFont: baseFont, colors: colors))
        case "python", "py":
            result.append(highlightPython(code, baseFont: baseFont, colors: colors))
        case "json":
            result.append(highlightJSON(code, baseFont: baseFont, colors: colors))
        case "html", "xml":
            result.append(highlightHTML(code, baseFont: baseFont, colors: colors))
        case "css":
            result.append(highlightCSS(code, baseFont: baseFont, colors: colors))
        default:
            result.append(NSAttributedString(string: code, attributes: baseAttributes))
        }
        
        return result
    }
    
    
    
    func updateDocument(_ document: MarkdownDocument, diff: DiffHighlighter.DiffResult) {
        currentDocument = document
        
        // Save scroll position
        let previousScrollPosition = scrollView.contentView.bounds.origin
        
        // Re-render the document
        if isLargeDocument {
            loadLargeDocument(document)
        } else {
            loadNormalDocument(document)
        }
        
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
            
            // Restore scroll position
            self.scrollView.contentView.scroll(to: previousScrollPosition)
            
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
        print("Parchment: Displaying content with length: \(content.length)")
        textView.textStorage?.setAttributedString(content)
        
        // Ensure the text view is sized properly
        textView.sizeToFit()
        
        // Focus mode is now handled by EnhancedFocusMode
    }
    
    
    // Old focus mode implementation removed - now using EnhancedFocusMode
    
    // MARK: - Typewriter Scrolling
    
    internal func enableTypewriterScrolling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidChangeSelection),
            name: NSTextView.didChangeSelectionNotification,
            object: textView
        )
        
        // Center current position
        centerCurrentLine()
    }
    
    internal func disableTypewriterScrolling() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSTextView.didChangeSelectionNotification,
            object: textView
        )
    }
    
    @objc private func textViewDidChangeSelection(_ notification: Notification) {
        guard typewriterScrollingEnabled else { return }
        centerCurrentLine()
    }
    
    private func centerCurrentLine() {
        guard let textStorage = textView.textStorage,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        // Get current cursor position
        let cursorLocation = textView.selectedRange().location
        guard cursorLocation < textStorage.length else { return }
        
        // Find the line containing the cursor
        let lineRange = (textStorage.string as NSString).lineRange(for: NSRange(location: cursorLocation, length: 0))
        
        // Get the rect for this line
        let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
        let lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        // Calculate the scroll position to center this line
        let viewportHeight = scrollView.contentView.bounds.height
        let targetY = lineRect.midY - viewportHeight / 2
        
        // Animate scroll to center
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            let clampedY = max(0, min(targetY, textView.frame.height - viewportHeight))
            scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: clampedY))
        }
        
        // Update current line for focus mode
        currentCursorLine = getCurrentLineNumber(at: cursorLocation)
    }
    
    private func getCurrentLineNumber(at location: Int) -> Int {
        guard let textStorage = textView.textStorage else { return 0 }
        
        let text = textStorage.string as NSString
        var lineNumber = 0
        var charCount = 0
        
        text.enumerateSubstrings(in: NSRange(location: 0, length: text.length), options: [.byLines]) { _, range, _, stop in
            lineNumber += 1
            if NSLocationInRange(location, range) {
                stop.pointee = true
            }
            charCount += range.length
        }
        
        return lineNumber
    }
    
    func showReadingStatistics() {
        guard let document = currentDocument else { return }
        
        if statisticsOverlay == nil {
            statisticsOverlay = StatisticsOverlayView()
            view.addSubview(statisticsOverlay!)
            
            statisticsOverlay?.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                statisticsOverlay!.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
                statisticsOverlay!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                statisticsOverlay!.widthAnchor.constraint(equalToConstant: 250),
                statisticsOverlay!.heightAnchor.constraint(equalToConstant: 150)
            ])
        }
        
        let stats = calculateStatistics(for: document)
        statisticsOverlay?.updateStatistics(stats)
        statisticsOverlay?.show()
    }
    
    private func calculateStatistics(for document: MarkdownDocument) -> ReadingStatistics {
        let words = document.content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        let characters = document.content.count
        let sentences = document.content.components(separatedBy: CharacterSet(charactersIn: ".!?")).count - 1
        let readingTime = Int(ceil(Double(words) / 200.0))
        
        let avgWordsPerSentence = sentences > 0 ? Double(words) / Double(sentences) : 0
        let complexityScore = min(100, Int(avgWordsPerSentence * 3))
        
        return ReadingStatistics(
            wordCount: words,
            characterCount: characters,
            readingTime: readingTime,
            complexityScore: complexityScore,
            progress: calculateReadingProgress()
        )
    }
    
    private func calculateReadingProgress() -> Double {
        let visibleRect = scrollView.contentView.visibleRect
        let totalHeight = textView.frame.height
        let scrollPosition = visibleRect.origin.y
        
        return min(1.0, max(0.0, (scrollPosition + visibleRect.height) / totalHeight))
    }
    
    func scrollToHeader(_ header: MarkdownHeader) {
        guard let textStorage = textView.textStorage else { return }
        
        let searchRange = NSRange(location: 0, length: textStorage.length)
        var foundRange: NSRange?
        
        textStorage.enumerateAttribute(.headingLevel, in: searchRange, options: []) { value, range, stop in
            if let level = value as? Int, level == header.level {
                let text = textStorage.attributedSubstring(from: range).string
                if text.contains(header.title) {
                    foundRange = range
                    stop.pointee = true
                }
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
    
}

extension Notification.Name {
    static let navigateToPreviousDocument = Notification.Name("navigateToPreviousDocument")
    static let navigateToNextDocument = Notification.Name("navigateToNextDocument")
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

extension MarkdownViewController {
    func highlightSwift(_ code: String, baseFont: NSFont, colors: SyntaxColors) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.controlBackgroundColor
        ]
        
        let keywords = ["func", "var", "let", "class", "struct", "enum", "if", "else", "for", "while", "return", "import", "private", "public", "internal", "static", "override", "init", "deinit", "extension", "protocol", "where", "in", "guard", "switch", "case", "default", "break", "continue", "throws", "try", "catch", "do", "defer", "async", "await"]
        
        // Simple regex-based highlighting
        let pattern = "\\b(" + keywords.joined(separator: "|") + ")\\b|\"[^\"]*\"|//.*$|/\\*[\\s\\S]*?\\*/|\\b\\d+\\b"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.count))
            
            var lastLocation = 0
            for match in matches {
                // Add text before match
                if match.range.location > lastLocation {
                    let beforeRange = NSRange(location: lastLocation, length: match.range.location - lastLocation)
                    let beforeText = (code as NSString).substring(with: beforeRange)
                    result.append(NSAttributedString(string: beforeText, attributes: baseAttributes))
                }
                
                // Add highlighted match
                let matchText = (code as NSString).substring(with: match.range)
                var attributes = baseAttributes
                
                if keywords.contains(matchText) {
                    attributes[.foregroundColor] = colors.keyword
                } else if matchText.hasPrefix("\"") {
                    attributes[.foregroundColor] = colors.string
                } else if matchText.hasPrefix("//") || matchText.hasPrefix("/*") {
                    attributes[.foregroundColor] = colors.comment
                } else if matchText.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil {
                    attributes[.foregroundColor] = colors.number
                }
                
                result.append(NSAttributedString(string: matchText, attributes: attributes))
                lastLocation = match.range.location + match.range.length
            }
            
            // Add remaining text
            if lastLocation < code.count {
                let remainingRange = NSRange(location: lastLocation, length: code.count - lastLocation)
                let remainingText = (code as NSString).substring(with: remainingRange)
                result.append(NSAttributedString(string: remainingText, attributes: baseAttributes))
            }
            
        } catch {
            // Fallback to plain text
            result.append(NSAttributedString(string: code, attributes: baseAttributes))
        }
        
        return result
    }
    
    func highlightJavaScript(_ code: String, baseFont: NSFont, colors: SyntaxColors) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.controlBackgroundColor
        ]
        
        let keywords = ["function", "var", "let", "const", "if", "else", "for", "while", "return", "import", "export", "class", "extends", "constructor", "this", "super", "new", "try", "catch", "throw", "typeof", "instanceof", "in", "of", "true", "false", "null", "undefined"]
        
        // Simple highlighting
        let pattern = "\\b(" + keywords.joined(separator: "|") + ")\\b|\"[^\"]*\"|'[^']*'|//.*$|/\\*[\\s\\S]*?\\*/|\\b\\d+\\b"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: code, options: [], range: NSRange(location: 0, length: code.count))
            
            var lastLocation = 0
            for match in matches {
                // Add text before match
                if match.range.location > lastLocation {
                    let beforeRange = NSRange(location: lastLocation, length: match.range.location - lastLocation)
                    let beforeText = (code as NSString).substring(with: beforeRange)
                    result.append(NSAttributedString(string: beforeText, attributes: baseAttributes))
                }
                
                // Add highlighted match
                let matchText = (code as NSString).substring(with: match.range)
                var attributes = baseAttributes
                
                if keywords.contains(matchText) {
                    attributes[.foregroundColor] = colors.keyword
                } else if matchText.hasPrefix("\"") || matchText.hasPrefix("'") {
                    attributes[.foregroundColor] = colors.string
                } else if matchText.hasPrefix("//") || matchText.hasPrefix("/*") {
                    attributes[.foregroundColor] = colors.comment
                } else if matchText.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil {
                    attributes[.foregroundColor] = colors.number
                }
                
                result.append(NSAttributedString(string: matchText, attributes: attributes))
                lastLocation = match.range.location + match.range.length
            }
            
            // Add remaining text
            if lastLocation < code.count {
                let remainingRange = NSRange(location: lastLocation, length: code.count - lastLocation)
                let remainingText = (code as NSString).substring(with: remainingRange)
                result.append(NSAttributedString(string: remainingText, attributes: baseAttributes))
            }
            
        } catch {
            // Fallback to plain text
            result.append(NSAttributedString(string: code, attributes: baseAttributes))
        }
        
        return result
    }
    
    func highlightPython(_ code: String, baseFont: NSFont, colors: SyntaxColors) -> NSAttributedString {
        // Similar implementation for Python
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.controlBackgroundColor
        ]
        return NSAttributedString(string: code, attributes: baseAttributes)
    }
    
    func highlightJSON(_ code: String, baseFont: NSFont, colors: SyntaxColors) -> NSAttributedString {
        // Similar implementation for JSON
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.controlBackgroundColor
        ]
        return NSAttributedString(string: code, attributes: baseAttributes)
    }
    
    func highlightHTML(_ code: String, baseFont: NSFont, colors: SyntaxColors) -> NSAttributedString {
        // Similar implementation for HTML
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.controlBackgroundColor
        ]
        return NSAttributedString(string: code, attributes: baseAttributes)
    }
    
    func highlightCSS(_ code: String, baseFont: NSFont, colors: SyntaxColors) -> NSAttributedString {
        // Similar implementation for CSS
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.controlBackgroundColor
        ]
        return NSAttributedString(string: code, attributes: baseAttributes)
    }
}

