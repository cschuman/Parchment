import Cocoa
import Markdown
import MarkdownKit
import WebKit

// Simple synchronous markdown visitor
class MarkdownAttributedStringVisitor {
    let attributedString = NSMutableAttributedString()
    private let zoomLevel: CGFloat
    private var currentAttributes: [NSAttributedString.Key: Any] = [:]
    private var listDepth = 0
    
    init(zoomLevel: CGFloat) {
        self.zoomLevel = zoomLevel
        setupDefaultAttributes()
    }
    
    private func setupDefaultAttributes() {
        currentAttributes = [
            .font: NSFont.systemFont(ofSize: 14 * zoomLevel),
            .foregroundColor: NSColor.labelColor
        ]
    }
    
    func convertDocument(_ document: Document) -> NSAttributedString {
        fputs("DEBUG: convertDocument - starting with \(document.childCount) children\n", stderr)
        for (index, child) in document.children.enumerated() {
            fputs("DEBUG: Processing child \(index + 1)/\(document.childCount): \(type(of: child))\n", stderr)
            visit(child)
        }
        fputs("DEBUG: convertDocument - finished, string length: \(attributedString.length)\n", stderr)
        return NSAttributedString(attributedString: attributedString)
    }
    
    private func visit(_ node: any Markup) {
        switch node {
        case let heading as Heading:
            visitHeading(heading)
        case let paragraph as Paragraph:
            visitParagraph(paragraph)
        case let text as Markdown.Text:
            visitText(text)
        case let strong as Strong:
            visitStrong(strong)
        case let emphasis as Emphasis:
            visitEmphasis(emphasis)
        case let strikethrough as Strikethrough:
            visitStrikethrough(strikethrough)
        case let code as InlineCode:
            visitInlineCode(code)
        case let codeBlock as CodeBlock:
            visitCodeBlock(codeBlock)
        case let list as UnorderedList:
            visitUnorderedList(list)
        case let list as OrderedList:
            visitOrderedList(list)
        case let item as ListItem:
            visitListItem(item)
        case let link as Link:
            visitLink(link)
        case let table as Table:
            visitTable(table)
        case let lineBreak as LineBreak:
            attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        default:
            // Visit children for unknown nodes
            for child in node.children {
                visit(child)
            }
        }
    }
    
    private func visitHeading(_ heading: Heading) {
        let sizes: [CGFloat] = [0, 28, 24, 20, 18, 16, 14]
        let fontSize = sizes[min(heading.level, 6)] * zoomLevel
        let savedAttributes = currentAttributes
        currentAttributes[.font] = NSFont.boldSystemFont(ofSize: fontSize)
        for child in heading.children {
            visit(child)
        }
        attributedString.append(NSAttributedString(string: "\n\n", attributes: currentAttributes))
        currentAttributes = savedAttributes
    }
    
    private func visitParagraph(_ paragraph: Paragraph) {
        for child in paragraph.children {
            visit(child)
        }
        attributedString.append(NSAttributedString(string: "\n\n", attributes: currentAttributes))
    }
    
    private func visitText(_ text: Markdown.Text) {
        attributedString.append(NSAttributedString(string: text.string, attributes: currentAttributes))
    }
    
    private func visitStrong(_ strong: Strong) {
        let savedFont = currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 14)
        currentAttributes[.font] = NSFont.boldSystemFont(ofSize: savedFont.pointSize)
        for child in strong.children {
            visit(child)
        }
        currentAttributes[.font] = savedFont
    }
    
    private func visitEmphasis(_ emphasis: Emphasis) {
        let savedFont = currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 14)
        if let italic = NSFont(descriptor: savedFont.fontDescriptor.withSymbolicTraits(.italic), 
                               size: savedFont.pointSize) {
            currentAttributes[.font] = italic
        }
        for child in emphasis.children {
            visit(child)
        }
        currentAttributes[.font] = savedFont
    }
    
    private func visitStrikethrough(_ strikethrough: Strikethrough) {
        let savedStrike = currentAttributes[.strikethroughStyle]
        currentAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        for child in strikethrough.children {
            visit(child)
        }
        if savedStrike != nil {
            currentAttributes[.strikethroughStyle] = savedStrike
        } else {
            currentAttributes.removeValue(forKey: .strikethroughStyle)
        }
    }
    
    private func visitInlineCode(_ code: InlineCode) {
        let savedAttributes = currentAttributes
        currentAttributes[.font] = NSFont.monospacedSystemFont(ofSize: 13 * zoomLevel, weight: .regular)
        currentAttributes[.backgroundColor] = NSColor.quaternaryLabelColor
        attributedString.append(NSAttributedString(string: " \(code.code) ", attributes: currentAttributes))
        currentAttributes = savedAttributes
    }
    
    private func visitCodeBlock(_ codeBlock: CodeBlock) {
        let savedAttributes = currentAttributes
        currentAttributes[.font] = NSFont.monospacedSystemFont(ofSize: 13 * zoomLevel, weight: .regular)
        currentAttributes[.backgroundColor] = NSColor.quaternaryLabelColor
        attributedString.append(NSAttributedString(string: "\n\(codeBlock.code)\n\n", attributes: currentAttributes))
        currentAttributes = savedAttributes
    }
    
    private func visitUnorderedList(_ list: UnorderedList) {
        listDepth += 1
        for child in list.children {
            visit(child)
        }
        listDepth -= 1
    }
    
    private func visitOrderedList(_ list: OrderedList) {
        listDepth += 1
        for (index, child) in list.children.enumerated() {
            if let item = child as? ListItem {
                visitOrderedListItem(item, number: index + 1)
            }
        }
        listDepth -= 1
    }
    
    private func visitListItem(_ item: ListItem) {
        let indent = String(repeating: "  ", count: listDepth - 1)
        attributedString.append(NSAttributedString(string: "\(indent)• ", attributes: currentAttributes))
        for child in item.children {
            visit(child)
        }
        if !attributedString.string.hasSuffix("\n") {
            attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        }
    }
    
    private func visitOrderedListItem(_ item: ListItem, number: Int) {
        let indent = String(repeating: "  ", count: listDepth - 1)
        attributedString.append(NSAttributedString(string: "\(indent)\(number). ", attributes: currentAttributes))
        for child in item.children {
            visit(child)
        }
        if !attributedString.string.hasSuffix("\n") {
            attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        }
    }
    
    private func visitLink(_ link: Link) {
        let savedColor = currentAttributes[.foregroundColor]
        currentAttributes[.foregroundColor] = NSColor.linkColor
        currentAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        if let destination = link.destination {
            currentAttributes[.link] = URL(string: destination)
        }
        for child in link.children {
            visit(child)
        }
        currentAttributes[.foregroundColor] = savedColor
        currentAttributes.removeValue(forKey: .underlineStyle)
        currentAttributes.removeValue(forKey: .link)
    }
    
    private func visitTable(_ table: Table) {
        // Simple table rendering
        for child in table.children {
            if child is Table.Head || child is Table.Body {
                for row in child.children {
                    if let tableRow = row as? Table.Row {
                        for cell in tableRow.children {
                            if let tableCell = cell as? Table.Cell {
                                for cellChild in tableCell.children {
                                    visit(cellChild)
                                }
                                attributedString.append(NSAttributedString(string: " | ", attributes: currentAttributes))
                            }
                        }
                        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
                    }
                }
                if child is Table.Head {
                    attributedString.append(NSAttributedString(string: String(repeating: "-", count: 40) + "\n", 
                                                              attributes: currentAttributes))
                }
            }
        }
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
    }
}

// Type aliases to avoid ambiguity
typealias MKText = MarkdownKit.Text
typealias MKAlignment = MarkdownKit.Alignment
typealias MDText = Markdown.Text

class MarkdownViewController: NSViewController {
    internal var scrollView: NSScrollView!
    internal var textView: MarkdownTextView!
    private var webView: WKWebView?
    internal var currentDocument: MarkdownDocument?
    internal var focusModeEnabled = false
    internal var typewriterScrollingEnabled = false
    private var zoomLevel: CGFloat = 1.0
    private var statisticsOverlay: StatisticsOverlayView?
    private var renderingEngine: MarkdownRenderingEngine!
    internal var visibleRange: NSRange = NSRange(location: 0, length: 0)
    private var wikiLinkParser: WikiLinkParser!
    private var virtualScrollManager: VirtualScrollManager!
    private var viewportTracker: ViewportTracker?
    private var isLargeDocument = false
    private var currentCursorLine: Int = 0
    
    weak var statusBarDelegate: StatusBarDelegate?
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        fputs("MarkdownViewController: init called\n", stderr)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fputs("MarkdownViewController: init(coder:) called\n", stderr)
    }
    
    override func loadView() {
        fputs("MarkdownViewController: loadView called\n", stderr)
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        setupViews()
        setupEnhancedFeatures()  // Initialize all enhanced features
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
        
        renderingEngine = MarkdownRenderingEngine()
        wikiLinkParser = WikiLinkParser()
        virtualScrollManager = VirtualScrollManager()
        viewportTracker = ViewportTracker(scrollView: scrollView)
        
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
        fputs("MarkdownViewController.loadDocument: Called with document of size \(document.content.count) chars\n", stderr)
        currentDocument = document
        
        // Check if this is a large document (>1MB or >10k lines)
        let lineCount = document.content.components(separatedBy: .newlines).count
        let byteCount = document.content.utf8.count
        isLargeDocument = lineCount > 10000 || byteCount > 1_000_000
        fputs("MarkdownViewController.loadDocument: Lines: \(lineCount), Bytes: \(byteCount), IsLarge: \(isLargeDocument)\n", stderr)
        
        if isLargeDocument {
            loadLargeDocument(document)
        } else {
            loadNormalDocument(document)
        }
    }
    
    private func loadNormalDocument(_ document: MarkdownDocument) {
        fputs("DEBUG: loadNormalDocument - starting\n", stderr)
        
        // Track parse time
        let parseStart = CFAbsoluteTimeGetCurrent()
        
        // Parse with swift-markdown (supports strikethrough, tables, etc.)
        let parsedDoc = Document(parsing: document.content)
        fputs("DEBUG: Parsed document with \(parsedDoc.childCount) children\n", stderr)
        
        let parseTime = CFAbsoluteTimeGetCurrent() - parseStart
        statusBarDelegate?.updateParseTime(parseTime)
        fputs("DEBUG: Parse time: \(parseTime)s\n", stderr)
        
        // Track render time
        let renderStart = CFAbsoluteTimeGetCurrent()
        
        // Convert to attributed string synchronously for now
        let visitor = MarkdownAttributedStringVisitor(zoomLevel: zoomLevel)
        fputs("DEBUG: Created visitor, starting conversion...\n", stderr)
        let attributedString = visitor.convertDocument(parsedDoc)
        fputs("DEBUG: Conversion complete, attributed string length: \(attributedString.length)\n", stderr)
        
        let renderTime = CFAbsoluteTimeGetCurrent() - renderStart
        statusBarDelegate?.updateRenderTime(renderTime)
        fputs("DEBUG: Render time: \(renderTime)s\n", stderr)
        
        // Set the attributed string on main thread
        fputs("DEBUG: Dispatching to main thread...\n", stderr)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { 
                fputs("DEBUG: Self is nil in main thread dispatch\n", stderr)
                return 
            }
            
            fputs("DEBUG: Setting attributed string on text view...\n", stderr)
            // Set the attributed string
            self.textView.textStorage?.setAttributedString(attributedString)
            
            // Ensure text view is sized properly
            self.textView.sizeToFit()
            
            // Update floating TOC if it exists
            self.updateFloatingTOC()
            
            // Scroll to top
            self.textView.scrollToBeginningOfDocument(nil)
            
            // Force update
            self.textView.needsDisplay = true
            fputs("DEBUG: Document loaded successfully\n", stderr)
        }
    }
    
    private func loadLargeDocument(_ document: MarkdownDocument) {
        // Initialize virtual scrolling
        virtualScrollManager.prepareDocument(document.content)
        
        // Calculate initial visible range
        let viewportHeight = scrollView.contentView.bounds.height
        let range = virtualScrollManager.calculateVisibleRange(scrollY: 0, viewportHeight: viewportHeight)
        
        // Track parse time for visible portion
        let parseStart = CFAbsoluteTimeGetCurrent()
        
        // Render only visible content
        let attributedString = virtualScrollManager.renderVisibleContent(
            document.content,
            range: range
        ) { content in
            // Parse and render this chunk
            let parser = ExtendedMarkdownParser.standard
            let markdownDoc = parser.parse(content)
            let result = NSMutableAttributedString()
            self.renderMarkdownKitDocument(markdownDoc, into: result)
            return result
        }
        
        let parseTime = CFAbsoluteTimeGetCurrent() - parseStart
        statusBarDelegate?.updateParseTime(parseTime)
        
        // Get metrics from virtual scroll manager
        let metrics = virtualScrollManager.getMetrics()
        statusBarDelegate?.updateRenderTime(metrics.renderTime)
        statusBarDelegate?.updateCacheHitRate(metrics.cacheHitRate)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.textView.textStorage?.setAttributedString(attributedString)
            self.textView.sizeToFit()
            self.textView.scrollToBeginningOfDocument(nil)
            self.textView.needsDisplay = true
            
            // Update floating TOC if it exists
            self.updateFloatingTOC()
            
            // Start prefetching nearby content
            self.virtualScrollManager.prefetchNearbyChunks(document.content) { content in
                let parser = ExtendedMarkdownParser.standard
                let markdownDoc = parser.parse(content)
                let result = NSMutableAttributedString()
                self.renderMarkdownKitDocument(markdownDoc, into: result)
                return result
            }
        }
    }
    
    private func renderMarkdownKitDocument(_ doc: Block, into attributedString: NSMutableAttributedString) {
        switch doc {
        case .document(let blocks):
            for block in blocks {
                renderMarkdownKitBlock(block, into: attributedString)
            }
        default:
            renderMarkdownKitBlock(doc, into: attributedString)
        }
    }
    
    private func renderMarkdownKitBlock(_ block: Block, into attributedString: NSMutableAttributedString) {
        switch block {
        case .heading(let level, let text):
            let fontSize = 28.0 - Double(level) * 3.0
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: NSColor.labelColor
            ]
            attributedString.append(NSAttributedString(string: renderMarkdownKitText(text) + "\n\n", attributes: attributes))
            
        case .paragraph(let text):
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]
            attributedString.append(NSAttributedString(string: renderMarkdownKitText(text) + "\n\n", attributes: attributes))
            
        case .table(let header, let alignments, let rows):
            renderMarkdownKitTable(header: header, alignments: alignments, rows: rows, into: attributedString)
            
        case .indentedCode(let lines):
            let code = lines.joined(separator: "\n")
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor,
                .backgroundColor: NSColor.controlBackgroundColor
            ]
            attributedString.append(NSAttributedString(string: code + "\n\n", attributes: attributes))
            
        case .fencedCode(_, let lines):
            let code = lines.joined(separator: "\n")
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor.secondaryLabelColor,
                .backgroundColor: NSColor.controlBackgroundColor
            ]
            attributedString.append(NSAttributedString(string: code + "\n\n", attributes: attributes))
            
        case .list(let start, _, let items):
            for (index, item) in items.enumerated() {
                let bullet = start == nil ? "• " : "\(index + (start ?? 1)). "
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 14),
                    .foregroundColor: NSColor.labelColor
                ]
                attributedString.append(NSAttributedString(string: bullet, attributes: attributes))
                
                if case .listItem(_, _, let blocks) = item {
                    for block in blocks {
                        renderMarkdownKitBlock(block, into: attributedString)
                    }
                }
            }
            
        case .blockquote(let blocks):
            let quoteAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.firstLineHeadIndent = 20
                    style.headIndent = 20
                    return style
                }()
            ]
            let quoteString = NSMutableAttributedString()
            for block in blocks {
                renderMarkdownKitBlock(block, into: quoteString)
            }
            quoteString.addAttributes(quoteAttributes, range: NSRange(location: 0, length: quoteString.length))
            attributedString.append(quoteString)
            
        default:
            // For other blocks, just add as plain text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]
            attributedString.append(NSAttributedString(string: "\(block)\n\n", attributes: attributes))
        }
    }
    
    private func renderMarkdownKitTable(header: Row?, alignments: Alignments, rows: Rows, into attributedString: NSMutableAttributedString) {
        let tableFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold),
            .foregroundColor: NSColor.labelColor
        ]
        let cellAttributes: [NSAttributedString.Key: Any] = [
            .font: tableFont,
            .foregroundColor: NSColor.labelColor
        ]
        
        // Calculate column widths
        var columnWidths: [Int] = []
        var allRows: [[String]] = []
        
        // Process header
        if let header = header {
            let headerCells = extractCellsFromRow(header)
            allRows.append(headerCells)
            for (index, cell) in headerCells.enumerated() {
                if index >= columnWidths.count {
                    columnWidths.append(cell.count)
                } else {
                    columnWidths[index] = max(columnWidths[index], cell.count)
                }
            }
        }
        
        // Process body rows
        for row in rows {
            let rowCells = extractCellsFromRow(row)
            allRows.append(rowCells)
            for (index, cell) in rowCells.enumerated() {
                if index >= columnWidths.count {
                    columnWidths.append(cell.count)
                } else {
                    columnWidths[index] = max(columnWidths[index], cell.count)
                }
            }
        }
        
        // Add padding
        columnWidths = columnWidths.map { max($0 + 2, 5) }
        
        // Render table
        let hasHeader = header != nil
        for (rowIndex, rowData) in allRows.enumerated() {
            var rowText = "│ "
            
            for (colIndex, cellText) in rowData.enumerated() {
                if colIndex < columnWidths.count {
                    let width = columnWidths[colIndex]
                    let paddedText = cellText.padding(toLength: width, withPad: " ", startingAt: 0)
                    rowText += paddedText + " │ "
                }
            }
            
            let isHeader = hasHeader && rowIndex == 0
            let attributes = isHeader ? headerAttributes : cellAttributes
            attributedString.append(NSAttributedString(string: rowText + "\n", attributes: attributes))
            
            // Add separator after header
            if isHeader {
                var separatorText = "├"
                for (index, width) in columnWidths.enumerated() {
                    separatorText += String(repeating: "─", count: width + 2)
                    if index < columnWidths.count - 1 {
                        separatorText += "┼"
                    } else {
                        separatorText += "┤"
                    }
                }
                attributedString.append(NSAttributedString(string: separatorText + "\n", attributes: cellAttributes))
            }
        }
        
        attributedString.append(NSAttributedString(string: "\n"))
    }
    
    private func extractCellsFromRow(_ row: Row) -> [String] {
        // Row is a typealias for ContiguousArray<Text>
        return row.map { text in
            renderMarkdownKitText(text)
        }
    }
    
    private func renderMarkdownKitText(_ text: MKText) -> String {
        // MKText is a Collection of TextFragments
        return text.map { renderMarkdownKitTextFragment($0) }.joined()
    }
    
    private func renderMarkdownKitTextFragment(_ fragment: TextFragment) -> String {
        switch fragment {
        case .text(let str):
            return String(str)
        case .code(let str):
            return String(str)
        case .emph(let text):
            return renderMarkdownKitText(text)
        case .strong(let text):
            return renderMarkdownKitText(text)
        case .link(let text, _, _):
            return renderMarkdownKitText(text)
        default:
            return ""
        }
    }
    
    private func renderMarkdownNode(_ node: Markup, into attributedString: NSMutableAttributedString, level: Int) {
        switch node {
        case let heading as Heading:
            let fontSize = 28.0 - Double(heading.level) * 3.0
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: NSColor.labelColor
            ]
            let headingText = renderInlineElements(from: heading.children, baseFont: NSFont.boldSystemFont(ofSize: fontSize))
            attributedString.append(headingText)
            attributedString.append(NSAttributedString(string: "\n\n"))
            
        case let paragraph as Paragraph:
            let paragraphText = renderInlineElements(from: paragraph.children, baseFont: NSFont.systemFont(ofSize: 14))
            attributedString.append(paragraphText)
            attributedString.append(NSAttributedString(string: "\n\n"))
            
        case let listItem as ListItem:
            let indent = String(repeating: "  ", count: level)
            let bulletAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]
            attributedString.append(NSAttributedString(string: indent + "• ", attributes: bulletAttributes))
            
            // Render list item content with inline formatting
            for child in listItem.children {
                if let paragraph = child as? Paragraph {
                    let itemText = renderInlineElements(from: paragraph.children, baseFont: NSFont.systemFont(ofSize: 14))
                    attributedString.append(itemText)
                } else {
                    renderMarkdownNode(child, into: attributedString, level: level + 1)
                }
            }
            attributedString.append(NSAttributedString(string: "\n"))
            
        case let codeBlock as CodeBlock:
            let highlightedCode = highlightCode(codeBlock.code, language: codeBlock.language)
            attributedString.append(highlightedCode)
            attributedString.append(NSAttributedString(string: "\n\n"))
            
        case let blockQuote as BlockQuote:
            let quoteAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.secondaryLabelColor,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.firstLineHeadIndent = 20
                    style.headIndent = 20
                    return style
                }()
            ]
            let quoteString = NSMutableAttributedString()
            for child in blockQuote.children {
                renderMarkdownNode(child, into: quoteString, level: level + 1)
            }
            quoteString.addAttributes(quoteAttributes, range: NSRange(location: 0, length: quoteString.length))
            attributedString.append(quoteString)
            
        case let table as Table:
            print("DEBUG: Rendering table with \(table.body.childCount) body rows and \(table.head.childCount) header rows")
            renderTable(table, into: attributedString)
            
        case is UnorderedList, is OrderedList:
            // Process list containers
            for child in node.children {
                renderMarkdownNode(child, into: attributedString, level: level + 1)
            }
            
        default:
            // For other containers, render children
            for child in node.children {
                renderMarkdownNode(child, into: attributedString, level: level)
            }
        }
    }
    
    private func renderInlineElements(from nodes: MarkupChildren, baseFont: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for node in nodes {
            switch node {
            case let text as MDText:
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: baseFont,
                    .foregroundColor: NSColor.labelColor
                ]
                result.append(NSAttributedString(string: text.string, attributes: attributes))
                
            case let strong as Strong:
                let boldFont = NSFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.bold), size: baseFont.pointSize) ?? baseFont
                let boldText = renderInlineElements(from: strong.children, baseFont: boldFont)
                result.append(boldText)
                
            case let emphasis as Emphasis:
                let italicFont = NSFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.italic), size: baseFont.pointSize) ?? baseFont
                let italicText = renderInlineElements(from: emphasis.children, baseFont: italicFont)
                result.append(italicText)
                
            case let code as InlineCode:
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: baseFont.pointSize * 0.9, weight: .regular),
                    .foregroundColor: NSColor.systemPink,
                    .backgroundColor: NSColor.controlBackgroundColor
                ]
                result.append(NSAttributedString(string: code.code, attributes: attributes))
                
            case let link as Link:
                let linkAttributes: [NSAttributedString.Key: Any] = [
                    .font: baseFont,
                    .foregroundColor: NSColor.linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: link.destination ?? ""
                ]
                let linkText = link.children.compactMap { ($0 as? MDText)?.string }.joined()
                result.append(NSAttributedString(string: linkText.isEmpty ? (link.destination ?? "") : linkText, attributes: linkAttributes))
                
            case let image as Image:
                let altText = image.children.compactMap { ($0 as? MDText)?.string }.joined()
                
                if let source = image.source, !source.isEmpty {
                    // Create image attachment
                    let imageAttachment = NSTextAttachment()
                    
                    // Resolve image path relative to document
                    let imageURL: URL?
                    if source.hasPrefix("http://") || source.hasPrefix("https://") {
                        imageURL = URL(string: source)
                    } else if let docURL = currentDocument?.url {
                        imageURL = docURL.deletingLastPathComponent().appendingPathComponent(source)
                    } else {
                        imageURL = URL(fileURLWithPath: source)
                    }
                    
                    if let url = imageURL {
                        // Try to load the image
                        if let loadedImage = loadImageSync(from: url) {
                            // Scale image to fit content width (max 600px)
                            let scaledImage = scaleImage(loadedImage, maxWidth: 600)
                            imageAttachment.image = scaledImage
                            
                            let imageString = NSAttributedString(attachment: imageAttachment)
                            result.append(imageString)
                            
                            // Add alt text as caption if available
                            if !altText.isEmpty {
                                let captionAttributes: [NSAttributedString.Key: Any] = [
                                    .font: NSFont.systemFont(ofSize: baseFont.pointSize * 0.9),
                                    .foregroundColor: NSColor.secondaryLabelColor
                                ]
                                result.append(NSAttributedString(string: "\n\(altText)\n", attributes: captionAttributes))
                            }
                        } else {
                            // Show placeholder for failed image
                            let placeholderAttributes: [NSAttributedString.Key: Any] = [
                                .font: NSFont.systemFont(ofSize: baseFont.pointSize),
                                .foregroundColor: NSColor.tertiaryLabelColor,
                                .backgroundColor: NSColor.controlBackgroundColor
                            ]
                            result.append(NSAttributedString(string: "[Image: \(altText.isEmpty ? source : altText)]", attributes: placeholderAttributes))
                        }
                    }
                } else {
                    // No source, show placeholder
                    let placeholderAttributes: [NSAttributedString.Key: Any] = [
                        .font: NSFont.systemFont(ofSize: baseFont.pointSize),
                        .foregroundColor: NSColor.tertiaryLabelColor
                    ]
                    result.append(NSAttributedString(string: "[Image: \(altText.isEmpty ? "missing source" : altText)]", attributes: placeholderAttributes))
                }
                
            case let strikethrough as Strikethrough:
                let strikeAttributes: [NSAttributedString.Key: Any] = [
                    .font: baseFont,
                    .foregroundColor: NSColor.labelColor,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue
                ]
                let strikeText = strikethrough.children.compactMap { ($0 as? MDText)?.string }.joined()
                result.append(NSAttributedString(string: strikeText, attributes: strikeAttributes))
                
            default:
                // For any other inline elements, try to get their text content
                if let textContent = (node as? InlineMarkup)?.plainText {
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: baseFont,
                        .foregroundColor: NSColor.labelColor
                    ]
                    result.append(NSAttributedString(string: textContent, attributes: attributes))
                }
            }
        }
        
        return result
    }
    
    private func renderTable(_ table: Table, into attributedString: NSMutableAttributedString) {
        // Create a formatted table representation
        let tableFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .bold),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.controlBackgroundColor
        ]
        let cellAttributes: [NSAttributedString.Key: Any] = [
            .font: tableFont,
            .foregroundColor: NSColor.labelColor
        ]
        let separatorAttributes: [NSAttributedString.Key: Any] = [
            .font: tableFont,
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
        
        // Calculate column widths
        var columnWidths: [Int] = []
        var allRows: [[String]] = []
        
        // Collect header data
        for row in table.head.children {
            if let tableRow = row as? Table.Row {
                var rowData: [String] = []
                for cell in tableRow.children {
                    if let tableCell = cell as? Table.Cell {
                        rowData.append(tableCell.plainText)
                    }
                }
                allRows.append(rowData)
                
                // Update column widths
                for (index, cellText) in rowData.enumerated() {
                    if index >= columnWidths.count {
                        columnWidths.append(cellText.count)
                    } else {
                        columnWidths[index] = max(columnWidths[index], cellText.count)
                    }
                }
            }
        }
        
        let headerCount = allRows.count
        
        // Collect body data
        for row in table.body.children {
            if let tableRow = row as? Table.Row {
                var rowData: [String] = []
                for cell in tableRow.children {
                    if let tableCell = cell as? Table.Cell {
                        rowData.append(tableCell.plainText)
                    }
                }
                allRows.append(rowData)
                
                // Update column widths
                for (index, cellText) in rowData.enumerated() {
                    if index >= columnWidths.count {
                        columnWidths.append(cellText.count)
                    } else {
                        columnWidths[index] = max(columnWidths[index], cellText.count)
                    }
                }
            }
        }
        
        // Add minimum padding
        columnWidths = columnWidths.map { $0 + 2 }
        
        // Render the table
        for (rowIndex, rowData) in allRows.enumerated() {
            var rowText = "│ "
            
            for (colIndex, cellText) in rowData.enumerated() {
                if colIndex < columnWidths.count {
                    let width = columnWidths[colIndex]
                    let paddedText = cellText.padding(toLength: width, withPad: " ", startingAt: 0)
                    rowText += paddedText + " │ "
                } else {
                    rowText += cellText + " │ "
                }
            }
            
            let isHeader = rowIndex < headerCount
            let attributes = isHeader ? headerAttributes : cellAttributes
            attributedString.append(NSAttributedString(string: rowText + "\n", attributes: attributes))
            
            // Add separator after header
            if isHeader && rowIndex == headerCount - 1 {
                var separatorText = "├"
                for (index, width) in columnWidths.enumerated() {
                    separatorText += String(repeating: "─", count: width + 2)
                    if index < columnWidths.count - 1 {
                        separatorText += "┼"
                    } else {
                        separatorText += "┤"
                    }
                }
                attributedString.append(NSAttributedString(string: separatorText + "\n", attributes: separatorAttributes))
            }
        }
        
        attributedString.append(NSAttributedString(string: "\n"))
    }
    
    private func loadImageSync(from url: URL) -> NSImage? {
        if url.isFileURL {
            // Load local file
            return NSImage(contentsOf: url)
        } else {
            // For remote images, try to load from cache first
            if let cachedImage = ImageCache.shared.get(url.absoluteString) {
                return cachedImage
            }
            
            // Start async loading for remote images
            Task {
                if let remoteImage = await ImageLoader.shared.loadImage(from: url) {
                    // Cache the image
                    ImageCache.shared.set(url.absoluteString, image: remoteImage)
                    
                    // Reload the document to show the loaded image
                    DispatchQueue.main.async { [weak self] in
                        if let document = self?.currentDocument {
                            self?.loadDocument(document)
                        }
                    }
                }
            }
            
            // Return placeholder for now
            return createImagePlaceholder(size: NSSize(width: 200, height: 150), text: "Loading...")
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
    
    private func processWikiLinks(_ links: [WikiLinkParser.WikiLink], in content: String) {
        for link in links {
            if let targetPath = link.targetPath {
                let linkAttributes: [NSAttributedString.Key: Any] = [
                    .link: URL(fileURLWithPath: targetPath),
                    .foregroundColor: NSColor.linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .cursor: NSCursor.pointingHand
                ]
            }
        }
    }
    
    func getBacklinks() -> [WikiLinkParser.Backlink] {
        guard let url = currentDocument?.url else { return [] }
        return wikiLinkParser.getBacklinks(for: url)
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
        
        if focusModeEnabled {
            applyFocusMode()
        }
    }
    
    
    func toggleFocusMode() {
        focusModeEnabled.toggle()
        
        if focusModeEnabled {
            typewriterScrollingEnabled = true
            applyFocusMode()
            enableTypewriterScrolling()
            AnimationEngine.animateFocusMode(enabled: true, in: textView)
        } else {
            typewriterScrollingEnabled = false
            removeFocusMode()
            disableTypewriterScrolling()
            AnimationEngine.animateFocusMode(enabled: false, in: textView)
        }
    }
    
    private func applyFocusMode() {
        guard let textStorage = textView.textStorage else { return }
        
        let visibleRect = scrollView.contentView.visibleRect
        let glyphRange = textView.layoutManager?.glyphRange(forBoundingRect: visibleRect, in: textView.textContainer!)
        let characterRange = textView.layoutManager?.characterRange(forGlyphRange: glyphRange ?? NSRange(), actualGlyphRange: nil)
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.addAttribute(.foregroundColor, value: NSColor.tertiaryLabelColor, range: fullRange)
        
        if let range = characterRange {
            let paragraphRange = textStorage.mutableString.paragraphRange(for: range)
            textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: paragraphRange)
        }
    }
    
    private func removeFocusMode() {
        guard let textStorage = textView.textStorage else { return }
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
    }
    
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
        
        if focusModeEnabled {
            applyFocusMode()
        }
        
        // Re-render visible content for large documents
        if isLargeDocument, let document = currentDocument {
            let scrollY = scrollView.contentView.bounds.origin.y
            let viewportHeight = scrollView.contentView.bounds.height
            let range = virtualScrollManager.calculateVisibleRange(scrollY: scrollY, viewportHeight: viewportHeight)
            
            // Only re-render if range changed significantly
            if abs(range.location - visibleRange.location) > 20 || abs(range.length - visibleRange.length) > 20 {
                let attributedString = virtualScrollManager.renderVisibleContent(
                    document.content,
                    range: range
                ) { content in
                    let parser = ExtendedMarkdownParser.standard
                    let markdownDoc = parser.parse(content)
                    let result = NSMutableAttributedString()
                    self.renderMarkdownKitDocument(markdownDoc, into: result)
                    return result
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.textView.textStorage?.setAttributedString(attributedString)
                    self?.textView.needsDisplay = true
                }
                
                // Update metrics
                let metrics = virtualScrollManager.getMetrics()
                statusBarDelegate?.updateCacheHitRate(metrics.cacheHitRate)
            }
        }
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

class MarkdownTextView: NSTextView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "c":
                let selectedRange = self.selectedRange()
                if selectedRange.length > 0 {
                    let selectedText = self.attributedString().attributedSubstring(from: selectedRange)
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.writeObjects([selectedText.string as NSString])
                    return true
                }
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}