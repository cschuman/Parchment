import Cocoa
import QuartzCore

final class FloatingTOCView: NSView {
    
    struct TOCItem {
        let title: String
        let level: Int
        let range: NSRange
        var progress: Double = 0
        var isVisible: Bool = false
        var isActive: Bool = false
    }
    
    private var items: [TOCItem] = []
    private var outlineView: NSOutlineView!
    private var scrollView: NSScrollView!
    private var headerView: NSView!
    private var progressBar: CircularProgressView!
    private var collapseButton: NSButton!
    
    private weak var textView: NSTextView?
    private weak var documentScrollView: NSScrollView?
    
    private var isCollapsed = false
    private var isDragging = false
    private var dragOffset = NSPoint.zero
    
    private let maxWidth: CGFloat = 280
    private let minWidth: CGFloat = 48
    
    weak var delegate: FloatingTOCDelegate?
    
    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        self.documentScrollView = scrollView
        super.init(frame: NSRect(x: 0, y: 0, width: maxWidth, height: 400))
        setupViews()
        observeScrolling()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        layer?.cornerRadius = 12
        layer?.shadowRadius = 8
        layer?.shadowOpacity = 0.15
        layer?.shadowOffset = CGSize(width: 0, height: 4)
        layer?.borderWidth = 0.5
        layer?.borderColor = NSColor.separatorColor.cgColor
        
        setupHeader()
        setupOutlineView()
        setupGestures()
    }
    
    private func setupHeader() {
        headerView = NSView()
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)
        
        let titleLabel = NSTextField(labelWithString: "Contents")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        
        progressBar = CircularProgressView()
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(progressBar)
        
        collapseButton = NSButton()
        collapseButton.bezelStyle = .regularSquare
        collapseButton.isBordered = false
        collapseButton.image = NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: nil)
        collapseButton.target = self
        collapseButton.action = #selector(toggleCollapse)
        collapseButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(collapseButton)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            progressBar.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            progressBar.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            progressBar.widthAnchor.constraint(equalToConstant: 32),
            progressBar.heightAnchor.constraint(equalToConstant: 32),
            
            collapseButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -8),
            collapseButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
    }
    
    private func setupOutlineView() {
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        outlineView = NSOutlineView()
        outlineView.style = .sourceList
        outlineView.rowHeight = 32
        outlineView.indentationPerLevel = 16
        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.headerView = nil
        outlineView.backgroundColor = .clear
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("TOCColumn"))
        column.isEditable = false
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        
        scrollView.documentView = outlineView
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupGestures() {
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        headerView.addGestureRecognizer(panGesture)
    }
    
    private func observeScrolling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(documentDidScroll),
            name: NSScrollView.didLiveScrollNotification,
            object: documentScrollView
        )
    }
    
    func updateWithContent(_ content: String) {
        items.removeAll()
        items = extractTOCItems(from: content)
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
        updateProgress()
    }
    
    private func extractTOCItems(from content: String) -> [TOCItem] {
        var items: [TOCItem] = []
        let lines = content.components(separatedBy: .newlines)
        var currentLocation = 0
        
        for line in lines {
            if line.hasPrefix("#") {
                let level = line.prefix(while: { $0 == "#" }).count
                let title = line.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
                
                if !title.isEmpty && level <= 6 {
                    let range = NSRange(location: currentLocation, length: line.count)
                    items.append(TOCItem(
                        title: title,
                        level: level,
                        range: range
                    ))
                }
            }
            currentLocation += line.count + 1
        }
        
        return items
    }
    
    @objc private func documentDidScroll() {
        updateProgress()
        updateActiveItems()
    }
    
    private func updateProgress() {
        guard let scrollView = documentScrollView,
              let documentView = scrollView.documentView else { return }
        
        let visibleRect = scrollView.contentView.visibleRect
        let totalHeight = documentView.frame.height
        let scrollProgress = (visibleRect.origin.y + visibleRect.height) / totalHeight
        
        progressBar.setProgress(scrollProgress, animated: true)
        
        for i in 0..<items.count {
            if let textView = textView,
               let layoutManager = textView.layoutManager,
               let textContainer = textView.textContainer {
                
                let glyphRange = layoutManager.glyphRange(
                    forCharacterRange: items[i].range,
                    actualCharacterRange: nil
                )
                let rect = layoutManager.boundingRect(
                    forGlyphRange: glyphRange,
                    in: textContainer
                )
                
                items[i].isVisible = visibleRect.intersects(rect)
                
                if i < items.count - 1 {
                    let nextGlyphRange = layoutManager.glyphRange(
                        forCharacterRange: items[i + 1].range,
                        actualCharacterRange: nil
                    )
                    let nextRect = layoutManager.boundingRect(
                        forGlyphRange: nextGlyphRange,
                        in: textContainer
                    )
                    
                    let sectionHeight = nextRect.origin.y - rect.origin.y
                    let visibleHeight = min(visibleRect.maxY, nextRect.origin.y) - 
                                       max(visibleRect.minY, rect.origin.y)
                    items[i].progress = max(0, min(1, visibleHeight / sectionHeight))
                } else {
                    let sectionHeight = totalHeight - rect.origin.y
                    let visibleHeight = visibleRect.maxY - rect.origin.y
                    items[i].progress = max(0, min(1, visibleHeight / sectionHeight))
                }
            }
        }
        
        outlineView.reloadData()
    }
    
    private func updateActiveItems() {
        guard let scrollView = documentScrollView else { return }
        
        let visibleRect = scrollView.contentView.visibleRect
        let centerY = visibleRect.midY
        
        for i in 0..<items.count {
            if let textView = textView,
               let layoutManager = textView.layoutManager,
               let textContainer = textView.textContainer {
                
                let glyphRange = layoutManager.glyphRange(
                    forCharacterRange: items[i].range,
                    actualCharacterRange: nil
                )
                let rect = layoutManager.boundingRect(
                    forGlyphRange: glyphRange,
                    in: textContainer
                )
                
                items[i].isActive = rect.minY <= centerY && 
                                   (i == items.count - 1 || 
                                    (i < items.count - 1 && centerY < layoutManager.boundingRect(
                                        forGlyphRange: layoutManager.glyphRange(
                                            forCharacterRange: items[i + 1].range,
                                            actualCharacterRange: nil
                                        ),
                                        in: textContainer
                                    ).minY))
            }
        }
        
        outlineView.reloadData()
    }
    
    @objc private func toggleCollapse() {
        isCollapsed.toggle()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            let targetWidth = isCollapsed ? minWidth : maxWidth
            self.animator().setFrameSize(NSSize(width: targetWidth, height: self.frame.height))
            
            scrollView.animator().alphaValue = isCollapsed ? 0 : 1
            collapseButton.animator().alphaValue = 1
            
            let rotation = isCollapsed ? 180.0 : 0.0
            collapseButton.animator().frameCenterRotation = CGFloat(rotation)
        }
    }
    
    @objc private func handlePan(_ gesture: NSPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            isDragging = true
            dragOffset = gesture.location(in: superview)
            
        case .changed:
            let currentLocation = gesture.location(in: superview)
            let deltaX = currentLocation.x - dragOffset.x
            let deltaY = currentLocation.y - dragOffset.y
            
            var newOrigin = frame.origin
            newOrigin.x += deltaX
            newOrigin.y += deltaY
            
            if let superviewBounds = superview?.bounds {
                newOrigin.x = max(0, min(newOrigin.x, superviewBounds.width - frame.width))
                newOrigin.y = max(0, min(newOrigin.y, superviewBounds.height - frame.height))
            }
            
            setFrameOrigin(newOrigin)
            dragOffset = currentLocation
            
        case .ended, .cancelled:
            isDragging = false
            
        default:
            break
        }
    }
    
    private func scrollToItem(_ item: TOCItem) {
        guard let textView = textView else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            textView.scrollRangeToVisible(item.range)
        }
        
        highlightItem(item)
    }
    
    private func highlightItem(_ item: TOCItem) {
        guard let textView = textView else { return }
        
        textView.textStorage?.addAttribute(
            .backgroundColor,
            value: NSColor.systemBlue.withAlphaComponent(0.2),
            range: item.range
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            textView.textStorage?.removeAttribute(.backgroundColor, range: item.range)
        }
    }
}

extension FloatingTOCView: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return items.filter { $0.level == 1 }.count
        }
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return items.filter { $0.level == 1 }[index]
        }
        return TOCItem(title: "", level: 0, range: NSRange())
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
}

extension FloatingTOCView: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let tocItem = item as? TOCItem else { return nil }
        
        let cellView = TOCCellView()
        cellView.configure(with: tocItem)
        
        return cellView
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let selectedItem = outlineView.item(atRow: outlineView.selectedRow) as? TOCItem else { return }
        scrollToItem(selectedItem)
        delegate?.floatingTOC(self, didSelectItem: selectedItem)
    }
}

class TOCCellView: NSTableCellView {
    private var progressIndicator: ProgressIndicatorView!
    private var titleLabel: NSTextField!
    private var levelIndicator: NSView!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        progressIndicator = ProgressIndicatorView()
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressIndicator)
        
        levelIndicator = NSView()
        levelIndicator.wantsLayer = true
        levelIndicator.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        levelIndicator.layer?.cornerRadius = 2
        levelIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(levelIndicator)
        
        titleLabel = NSTextField(labelWithString: "")
        titleLabel.font = NSFont.systemFont(ofSize: 12)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            progressIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            progressIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressIndicator.widthAnchor.constraint(equalToConstant: 20),
            progressIndicator.heightAnchor.constraint(equalToConstant: 20),
            
            levelIndicator.leadingAnchor.constraint(equalTo: progressIndicator.trailingAnchor, constant: 8),
            levelIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            levelIndicator.widthAnchor.constraint(equalToConstant: 3),
            levelIndicator.heightAnchor.constraint(equalToConstant: 16),
            
            titleLabel.leadingAnchor.constraint(equalTo: levelIndicator.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(with item: FloatingTOCView.TOCItem) {
        titleLabel.stringValue = item.title
        titleLabel.font = NSFont.systemFont(
            ofSize: 14 - CGFloat(item.level - 1),
            weight: item.isActive ? .semibold : .regular
        )
        titleLabel.textColor = item.isActive ? NSColor.controlAccentColor : 
                               item.isVisible ? NSColor.labelColor : 
                               NSColor.secondaryLabelColor
        
        progressIndicator.setProgress(item.progress)
        progressIndicator.isHighlighted = item.isActive
        
        levelIndicator.alphaValue = CGFloat(1.0 - Double(item.level - 1) * 0.15)
        
        let indentConstraint = titleLabel.constraints.first { $0.firstAttribute == .leading }
        indentConstraint?.constant = CGFloat(8 + (item.level - 1) * 16)
    }
}

class ProgressIndicatorView: NSView {
    private var progressLayer: CAShapeLayer!
    private var backgroundLayer: CAShapeLayer!
    private var progress: Double = 0
    var isHighlighted = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        wantsLayer = true
        
        backgroundLayer = CAShapeLayer()
        backgroundLayer.strokeColor = NSColor.tertiaryLabelColor.cgColor
        backgroundLayer.fillColor = NSColor.clear.cgColor
        backgroundLayer.lineWidth = 2
        layer?.addSublayer(backgroundLayer)
        
        progressLayer = CAShapeLayer()
        progressLayer.strokeColor = NSColor.controlAccentColor.cgColor
        progressLayer.fillColor = NSColor.clear.cgColor
        progressLayer.lineWidth = 2
        progressLayer.lineCap = .round
        layer?.addSublayer(progressLayer)
    }
    
    override func layout() {
        super.layout()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 2
        
        let path = CGMutablePath()
        path.addArc(center: center, radius: radius, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)
        
        backgroundLayer.path = path
        progressLayer.path = path
        
        updateProgress()
    }
    
    func setProgress(_ progress: Double) {
        self.progress = progress
        updateProgress()
    }
    
    private func updateProgress() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        
        progressLayer.strokeEnd = CGFloat(progress)
        progressLayer.strokeColor = isHighlighted ? 
            NSColor.controlAccentColor.cgColor : 
            NSColor.secondaryLabelColor.cgColor
        
        CATransaction.commit()
    }
}

class CircularProgressView: NSView {
    private var progressLayer: CAShapeLayer!
    private var progress: Double = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        wantsLayer = true
        
        progressLayer = CAShapeLayer()
        progressLayer.strokeColor = NSColor.controlAccentColor.cgColor
        progressLayer.fillColor = NSColor.clear.cgColor
        progressLayer.lineWidth = 3
        progressLayer.lineCap = .round
        layer?.addSublayer(progressLayer)
    }
    
    override func layout() {
        super.layout()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 4
        
        let path = CGMutablePath()
        path.addArc(center: center, radius: radius, startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)
        
        progressLayer.path = path
    }
    
    func setProgress(_ progress: Double, animated: Bool) {
        self.progress = progress
        
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.3)
        }
        
        progressLayer.strokeEnd = CGFloat(progress)
        
        if animated {
            CATransaction.commit()
        }
    }
}

protocol FloatingTOCDelegate: AnyObject {
    func floatingTOC(_ toc: FloatingTOCView, didSelectItem item: FloatingTOCView.TOCItem)
}