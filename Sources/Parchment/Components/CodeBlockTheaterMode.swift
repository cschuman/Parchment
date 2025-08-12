import Cocoa
import QuartzCore

final class CodeBlockTheaterMode: NSViewController {
    
    private var backdropView: NSVisualEffectView!
    private var containerView: NSView!
    private var codeScrollView: NSScrollView!
    private var codeTextView: NSTextView!
    private var titleLabel: NSTextField!
    private var languageLabel: NSTextField!
    private var toolbarView: NSView!
    private var lineNumberView: LineNumberView!
    private var miniMapView: MiniMapView!
    
    private var copyButton: NSButton!
    private var closeButton: NSButton!
    private var themeButton: NSPopUpButton!
    private var fontSizeSlider: NSSlider!
    private var wrapLinesButton: NSButton!
    
    private var code: String = ""
    private var language: String = ""
    private var fileName: String?
    
    private var currentTheme: CodeTheme = .oneDark
    private var isAnimating = false
    
    enum CodeTheme: String, CaseIterable {
        case oneDark = "One Dark"
        case monokai = "Monokai"
        case solarizedDark = "Solarized Dark"
        case githubLight = "GitHub Light"
        case nord = "Nord"
        
        var backgroundColor: NSColor {
            switch self {
            case .oneDark: return NSColor(hex: "#282c34")
            case .monokai: return NSColor(hex: "#272822")
            case .solarizedDark: return NSColor(hex: "#002b36")
            case .githubLight: return NSColor(hex: "#ffffff")
            case .nord: return NSColor(hex: "#2e3440")
            }
        }
        
        var textColor: NSColor {
            switch self {
            case .githubLight: return NSColor(hex: "#24292e")
            default: return NSColor(hex: "#abb2bf")
            }
        }
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 600))
        setupViews()
    }
    
    private func setupViews() {
        backdropView = NSVisualEffectView()
        backdropView.blendingMode = .behindWindow
        backdropView.material = .hudWindow
        backdropView.state = .active
        backdropView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdropView)
        
        containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = currentTheme.backgroundColor.cgColor
        containerView.layer?.cornerRadius = 12
        containerView.layer?.shadowRadius = 20
        containerView.layer?.shadowOpacity = 0.3
        containerView.layer?.shadowOffset = CGSize(width: 0, height: 10)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        setupToolbar()
        setupCodeView()
        setupLineNumbers()
        setupMiniMap()
        
        NSLayoutConstraint.activate([
            backdropView.topAnchor.constraint(equalTo: view.topAnchor),
            backdropView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdropView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdropView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.85)
        ])
        
        setupGestures()
    }
    
    private func setupToolbar() {
        toolbarView = NSView()
        toolbarView.wantsLayer = true
        toolbarView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.2).cgColor
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(toolbarView)
        
        titleLabel = NSTextField(labelWithString: fileName ?? "Code")
        titleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.addSubview(titleLabel)
        
        languageLabel = NSTextField(labelWithString: language.uppercased())
        languageLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        languageLabel.textColor = NSColor.white.withAlphaComponent(0.7)
        languageLabel.wantsLayer = true
        languageLabel.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.1).cgColor
        languageLabel.layer?.cornerRadius = 4
        languageLabel.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.addSubview(languageLabel)
        
        closeButton = createToolbarButton(symbol: "xmark.circle.fill", action: #selector(close))
        toolbarView.addSubview(closeButton)
        
        copyButton = createToolbarButton(symbol: "doc.on.doc", action: #selector(copyCode))
        toolbarView.addSubview(copyButton)
        
        wrapLinesButton = createToolbarButton(symbol: "text.alignleft", action: #selector(toggleWrapLines))
        toolbarView.addSubview(wrapLinesButton)
        
        themeButton = NSPopUpButton()
        themeButton.addItems(withTitles: CodeTheme.allCases.map { $0.rawValue })
        themeButton.selectItem(withTitle: currentTheme.rawValue)
        themeButton.target = self
        themeButton.action = #selector(changeTheme(_:))
        themeButton.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.addSubview(themeButton)
        
        fontSizeSlider = NSSlider(value: 14, minValue: 10, maxValue: 24, target: self, action: #selector(changeFontSize(_:)))
        fontSizeSlider.translatesAutoresizingMaskIntoConstraints = false
        toolbarView.addSubview(fontSizeSlider)
        
        NSLayoutConstraint.activate([
            toolbarView.topAnchor.constraint(equalTo: containerView.topAnchor),
            toolbarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            toolbarView.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            
            languageLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            languageLabel.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            
            copyButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            copyButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            
            wrapLinesButton.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -8),
            wrapLinesButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            
            themeButton.trailingAnchor.constraint(equalTo: wrapLinesButton.leadingAnchor, constant: -12),
            themeButton.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            themeButton.widthAnchor.constraint(equalToConstant: 120),
            
            fontSizeSlider.trailingAnchor.constraint(equalTo: themeButton.leadingAnchor, constant: -12),
            fontSizeSlider.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor),
            fontSizeSlider.widthAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setupCodeView() {
        codeScrollView = NSScrollView()
        codeScrollView.hasVerticalScroller = true
        codeScrollView.hasHorizontalScroller = true
        codeScrollView.autohidesScrollers = false
        codeScrollView.borderType = .noBorder
        codeScrollView.translatesAutoresizingMaskIntoConstraints = false
        codeScrollView.backgroundColor = currentTheme.backgroundColor
        containerView.addSubview(codeScrollView)
        
        codeTextView = NSTextView()
        codeTextView.isEditable = false
        codeTextView.isSelectable = true
        codeTextView.isRichText = true
        codeTextView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        codeTextView.textColor = currentTheme.textColor
        codeTextView.backgroundColor = currentTheme.backgroundColor
        codeTextView.textContainerInset = NSSize(width: 10, height: 10)
        codeTextView.isAutomaticQuoteSubstitutionEnabled = false
        codeTextView.isAutomaticDashSubstitutionEnabled = false
        codeTextView.isAutomaticTextReplacementEnabled = false
        codeTextView.allowsUndo = false
        
        codeScrollView.documentView = codeTextView
        
        NSLayoutConstraint.activate([
            codeScrollView.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            codeScrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 50),
            codeScrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -120),
            codeScrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    private func setupLineNumbers() {
        lineNumberView = LineNumberView()
        lineNumberView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(lineNumberView)
        
        NSLayoutConstraint.activate([
            lineNumberView.topAnchor.constraint(equalTo: codeScrollView.topAnchor),
            lineNumberView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            lineNumberView.widthAnchor.constraint(equalToConstant: 50),
            lineNumberView.bottomAnchor.constraint(equalTo: codeScrollView.bottomAnchor)
        ])
        
        lineNumberView.scrollView = codeScrollView
        lineNumberView.textView = codeTextView
    }
    
    private func setupMiniMap() {
        miniMapView = MiniMapView()
        miniMapView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(miniMapView)
        
        NSLayoutConstraint.activate([
            miniMapView.topAnchor.constraint(equalTo: codeScrollView.topAnchor),
            miniMapView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            miniMapView.widthAnchor.constraint(equalToConstant: 120),
            miniMapView.bottomAnchor.constraint(equalTo: codeScrollView.bottomAnchor)
        ])
        
        miniMapView.textView = codeTextView
        miniMapView.scrollView = codeScrollView
    }
    
    private func setupGestures() {
        let escapeGesture = NSPressGestureRecognizer(target: self, action: #selector(handleEscape(_:)))
        escapeGesture.minimumPressDuration = 0
        escapeGesture.allowedTouchTypes = .indirect
        view.addGestureRecognizer(escapeGesture)
        
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleBackdropClick(_:)))
        backdropView.addGestureRecognizer(clickGesture)
    }
    
    private func createToolbarButton(symbol: String, action: Selector) -> NSButton {
        let button = NSButton()
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        button.contentTintColor = .white
        button.target = self
        button.action = action
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    func showCode(_ code: String, language: String, fileName: String? = nil) {
        self.code = code
        self.language = language
        self.fileName = fileName
        
        titleLabel.stringValue = fileName ?? "Code"
        languageLabel.stringValue = language.uppercased()
        
        let highlightedCode = highlightCode(code, language: language)
        codeTextView.textStorage?.setAttributedString(highlightedCode)
        
        lineNumberView.updateLineNumbers()
        miniMapView.updateMiniMap()
        
        animateIn()
    }
    
    private func highlightCode(_ code: String, language: String) -> NSAttributedString {
        let highlighter = SyntaxHighlighter()
        return highlighter.highlight(code: code, language: language, fontSize: codeTextView.font?.pointSize ?? 14)
    }
    
    private func animateIn() {
        guard !isAnimating else { return }
        isAnimating = true
        
        view.alphaValue = 0
        containerView.layer?.transform = CATransform3DMakeScale(0.8, 0.8, 1)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            self.view.animator().alphaValue = 1
            self.containerView.layer?.transform = CATransform3DIdentity
        }) {
            self.isAnimating = false
        }
    }
    
    private func animateOut(completion: @escaping () -> Void) {
        guard !isAnimating else { return }
        isAnimating = true
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            self.view.animator().alphaValue = 0
            self.containerView.layer?.transform = CATransform3DMakeScale(0.9, 0.9, 1)
        }) {
            self.isAnimating = false
            completion()
        }
    }
    
    @objc private func close() {
        animateOut {
            self.dismiss(nil)
        }
    }
    
    @objc private func copyCode() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)
        
        copyButton.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.copyButton.image = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil)
        }
    }
    
    @objc private func toggleWrapLines() {
        codeTextView.isHorizontallyResizable.toggle()
        codeTextView.textContainer?.widthTracksTextView.toggle()
        
        if codeTextView.textContainer?.widthTracksTextView ?? false {
            codeTextView.textContainer?.containerSize = CGSize(
                width: codeScrollView.frame.width,
                height: CGFloat.greatestFiniteMagnitude
            )
            wrapLinesButton.contentTintColor = .systemBlue
        } else {
            codeTextView.textContainer?.containerSize = CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            wrapLinesButton.contentTintColor = .white
        }
    }
    
    @objc private func changeTheme(_ sender: NSPopUpButton) {
        guard let selectedTitle = sender.selectedItem?.title,
              let theme = CodeTheme(rawValue: selectedTitle) else { return }
        
        currentTheme = theme
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            
            containerView.layer?.backgroundColor = theme.backgroundColor.cgColor
            codeTextView.animator().backgroundColor = theme.backgroundColor
            codeScrollView.animator().backgroundColor = theme.backgroundColor
        }
        
        let highlightedCode = highlightCode(code, language: language)
        codeTextView.textStorage?.setAttributedString(highlightedCode)
    }
    
    @objc private func changeFontSize(_ sender: NSSlider) {
        let fontSize = sender.doubleValue
        codeTextView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        let highlightedCode = highlightCode(code, language: language)
        codeTextView.textStorage?.setAttributedString(highlightedCode)
        
        lineNumberView.updateLineNumbers()
        miniMapView.updateMiniMap()
    }
    
    @objc private func handleEscape(_ gesture: NSPressGestureRecognizer) {
        if gesture.state == .recognized {
            close()
        }
    }
    
    @objc private func handleBackdropClick(_ gesture: NSClickGestureRecognizer) {
        close()
    }
}

class LineNumberView: NSView {
    weak var scrollView: NSScrollView?
    weak var textView: NSTextView?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        let text = textStorage.string
        let lines = text.components(separatedBy: .newlines)
        
        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .light)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let visibleRect = scrollView?.contentView.visibleRect ?? bounds
        let startLine = Int(visibleRect.origin.y / 20)
        let endLine = min(lines.count, startLine + Int(visibleRect.height / 20) + 2)
        
        for lineNumber in startLine..<endLine {
            let lineString = "\(lineNumber + 1)"
            let attributedString = NSAttributedString(string: lineString, attributes: attributes)
            let size = attributedString.size()
            
            let yPosition = CGFloat(lineNumber) * 20 + 10 - visibleRect.origin.y
            let rect = NSRect(
                x: bounds.width - size.width - 8,
                y: yPosition,
                width: size.width,
                height: size.height
            )
            
            attributedString.draw(in: rect)
        }
    }
    
    func updateLineNumbers() {
        needsDisplay = true
    }
}

class MiniMapView: NSView {
    weak var textView: NSTextView?
    weak var scrollView: NSScrollView?
    
    private var miniMapImage: NSImage?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        NSColor.black.withAlphaComponent(0.1).setFill()
        dirtyRect.fill()
        
        if let image = miniMapImage {
            image.draw(in: bounds)
        }
        
        drawViewportIndicator()
    }
    
    func updateMiniMap() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        let scale: CGFloat = 0.1
        let miniMapSize = CGSize(
            width: bounds.width,
            height: CGFloat(textStorage.string.components(separatedBy: .newlines).count) * 2
        )
        
        miniMapImage = NSImage(size: miniMapSize)
        miniMapImage?.lockFocus()
        
        let font = NSFont.monospacedSystemFont(ofSize: 1, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor.withAlphaComponent(0.3)
        ]
        
        let lines = textStorage.string.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            let trimmedLine = String(line.prefix(100))
            let density = min(1.0, Double(trimmedLine.count) / 80.0)
            
            NSColor.labelColor.withAlphaComponent(density * 0.3).setFill()
            let rect = NSRect(x: 0, y: CGFloat(index) * 2, width: bounds.width * CGFloat(density), height: 1)
            rect.fill()
        }
        
        miniMapImage?.unlockFocus()
        needsDisplay = true
    }
    
    private func drawViewportIndicator() {
        guard let scrollView = scrollView else { return }
        
        let visibleRect = scrollView.contentView.visibleRect
        let documentHeight = scrollView.documentView?.frame.height ?? 1
        
        let indicatorY = (visibleRect.origin.y / documentHeight) * bounds.height
        let indicatorHeight = (visibleRect.height / documentHeight) * bounds.height
        
        let indicatorRect = NSRect(
            x: 0,
            y: indicatorY,
            width: bounds.width,
            height: indicatorHeight
        )
        
        NSColor.systemBlue.withAlphaComponent(0.3).setFill()
        indicatorRect.fill()
        
        NSColor.systemBlue.setStroke()
        indicatorRect.frame()
    }
}

// NSColor extension with hex init is already defined in ThemeManager.swift