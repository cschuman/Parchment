import Cocoa

/// Window for selecting and customizing themes
class ThemeSelectorWindow: NSWindow {
    
    private var themeCollectionView: NSCollectionView!
    private var previewTextView: NSTextView!
    private var customizeButton: NSButton!
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                  styleMask: [.titled, .closable, .resizable],
                  backing: .buffered,
                  defer: false)
        
        setupWindow()
        setupViews()
        loadThemes()
    }
    
    private func setupWindow() {
        title = "Theme Selector"
        titlebarAppearsTransparent = false
        center()
    }
    
    private func setupViews() {
        let contentView = NSView()
        
        // Split view
        let splitView = NSSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.translatesAutoresizingMaskIntoConstraints = false
        
        // Left side - Theme list
        let scrollView = NSScrollView()
        themeCollectionView = NSCollectionView()
        themeCollectionView.collectionViewLayout = createLayout()
        themeCollectionView.delegate = self
        themeCollectionView.dataSource = self
        themeCollectionView.isSelectable = true
        themeCollectionView.allowsMultipleSelection = false
        themeCollectionView.register(ThemeItemView.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("ThemeItem"))
        
        scrollView.documentView = themeCollectionView
        scrollView.hasVerticalScroller = true
        
        // Right side - Preview
        let previewContainer = NSView()
        
        let previewLabel = NSTextField(labelWithString: "Preview")
        previewLabel.font = NSFont.boldSystemFont(ofSize: 14)
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let previewScrollView = NSScrollView()
        previewTextView = NSTextView()
        previewTextView.isEditable = false
        previewTextView.isRichText = true
        previewTextView.font = NSFont.systemFont(ofSize: 14)
        previewScrollView.documentView = previewTextView
        previewScrollView.hasVerticalScroller = true
        previewScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        customizeButton = NSButton(title: "Customize", target: self, action: #selector(customizeTheme))
        customizeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let applyButton = NSButton(title: "Apply", target: self, action: #selector(applyTheme))
        applyButton.bezelStyle = .rounded
        applyButton.keyEquivalent = "\r"
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        
        previewContainer.addSubview(previewLabel)
        previewContainer.addSubview(previewScrollView)
        previewContainer.addSubview(customizeButton)
        previewContainer.addSubview(applyButton)
        
        NSLayoutConstraint.activate([
            previewLabel.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 10),
            previewLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 10),
            
            previewScrollView.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 10),
            previewScrollView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 10),
            previewScrollView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -10),
            previewScrollView.bottomAnchor.constraint(equalTo: customizeButton.topAnchor, constant: -10),
            
            customizeButton.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 10),
            customizeButton.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -10),
            
            applyButton.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -10),
            applyButton.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -10)
        ])
        
        splitView.addArrangedSubview(scrollView)
        splitView.addArrangedSubview(previewContainer)
        
        splitView.setHoldingPriority(.defaultLow, forSubviewAt: 0)
        splitView.setHoldingPriority(.required, forSubviewAt: 1)
        
        contentView.addSubview(splitView)
        
        NSLayoutConstraint.activate([
            splitView.topAnchor.constraint(equalTo: contentView.topAnchor),
            splitView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            splitView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            splitView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        self.contentView = contentView
        
        // Set initial preview text
        updatePreview(with: ThemeManager.shared.currentTheme)
    }
    
    private func createLayout() -> NSCollectionViewFlowLayout {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 200, height: 120)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return layout
    }
    
    private func loadThemes() {
        themeCollectionView.reloadData()
        
        // Select current theme
        let themes = ThemeManager.shared.availableThemes()
        if let currentIndex = themes.firstIndex(where: { $0.name == ThemeManager.shared.currentTheme.name }) {
            themeCollectionView.selectItems(at: [IndexPath(item: currentIndex, section: 0)], scrollPosition: .centeredVertically)
        }
    }
    
    private func updatePreview(with theme: Theme) {
        let previewText = """
        # \(theme.name) Theme
        
        This is a preview of the **\(theme.name)** theme showing various markdown elements.
        
        ## Headers
        
        ### Level 3 Header
        #### Level 4 Header
        
        ## Text Formatting
        
        Regular text with **bold**, *italic*, and ***bold italic*** formatting.
        
        You can also use ~~strikethrough~~ and `inline code`.
        
        ## Links
        
        [Visit GitHub](https://github.com) or check out [[wiki-links]].
        
        ## Code Block
        
        ```swift
        func greet(name: String) -> String {
            return "Hello, \\(name)!"
        }
        
        let message = greet(name: "World")
        print(message) // Output: Hello, World!
        ```
        
        ## Blockquote
        
        > This is a blockquote showing how quoted text appears.
        > It can span multiple lines.
        
        ## Lists
        
        - First item
        - Second item
          - Nested item
        - Third item
        
        1. Numbered item
        2. Another item
        3. Final item
        
        ## Table
        
        | Feature | Status |
        |---------|--------|
        | Theme Support | ✅ |
        | Dark Mode | ✅ |
        | Custom Themes | ✅ |
        """
        
        // Apply theme to preview
        let attributedString = NSMutableAttributedString(string: previewText)
        let fullRange = NSRange(location: 0, length: attributedString.length)
        
        // Background
        previewTextView.backgroundColor = theme.colors.background
        
        // Base text
        attributedString.addAttribute(.font, value: theme.fonts.body, range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: theme.colors.text, range: fullRange)
        
        // Apply paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = theme.spacing.lineSpacing
        paragraphStyle.paragraphSpacing = theme.spacing.paragraphSpacing
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        // Style headers
        let headerRegex = try? NSRegularExpression(pattern: "^#+\\s+.*$", options: [.anchorsMatchLines])
        headerRegex?.enumerateMatches(in: previewText, options: [], range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            let headerLevel = (previewText as NSString).substring(with: range).prefix(while: { $0 == "#" }).count
            
            let font: NSFont
            switch headerLevel {
            case 1: font = theme.fonts.heading1
            case 2: font = theme.fonts.heading2
            case 3: font = theme.fonts.heading3
            case 4: font = theme.fonts.heading4
            case 5: font = theme.fonts.heading5
            default: font = theme.fonts.heading6
            }
            
            attributedString.addAttribute(.font, value: font, range: range)
            attributedString.addAttribute(.foregroundColor, value: theme.colors.headingText, range: range)
        }
        
        // Style code blocks
        let codeRegex = try? NSRegularExpression(pattern: "`[^`]+`", options: [])
        codeRegex?.enumerateMatches(in: previewText, options: [], range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            attributedString.addAttribute(.font, value: theme.fonts.code, range: range)
            attributedString.addAttribute(.foregroundColor, value: theme.colors.codeText, range: range)
            attributedString.addAttribute(.backgroundColor, value: theme.colors.codeBackground, range: range)
        }
        
        // Style links
        let linkRegex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\([^\\)]+\\)", options: [])
        linkRegex?.enumerateMatches(in: previewText, options: [], range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            attributedString.addAttribute(.foregroundColor, value: theme.colors.linkText, range: range)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }
        
        previewTextView.textStorage?.setAttributedString(attributedString)
    }
    
    @objc private func customizeTheme() {
        // TODO: Open theme customization panel
        let alert = NSAlert()
        alert.messageText = "Theme Customization"
        alert.informativeText = "Theme customization panel coming soon!"
        alert.runModal()
    }
    
    @objc private func applyTheme() {
        guard let selectedIndex = themeCollectionView.selectionIndexPaths.first else { return }
        
        let themes = ThemeManager.shared.availableThemes()
        let selectedTheme = themes[selectedIndex.item]
        
        ThemeManager.shared.setTheme(selectedTheme)
        close()
    }
}

// MARK: - Collection View DataSource

extension ThemeSelectorWindow: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return ThemeManager.shared.availableThemes().count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("ThemeItem"), for: indexPath) as! ThemeItemView
        
        let themes = ThemeManager.shared.availableThemes()
        let theme = themes[indexPath.item]
        
        item.configure(with: theme)
        
        return item
    }
}

// MARK: - Collection View Delegate

extension ThemeSelectorWindow: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        
        let themes = ThemeManager.shared.availableThemes()
        let selectedTheme = themes[indexPath.item]
        
        updatePreview(with: selectedTheme)
    }
}

// MARK: - Theme Item View

class ThemeItemView: NSCollectionViewItem {
    
    private var themeNameLabel: NSTextField!
    private var colorPreview: NSView!
    
    override func loadView() {
        view = NSView()
        
        themeNameLabel = NSTextField(labelWithString: "")
        themeNameLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        themeNameLabel.alignment = .center
        themeNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        colorPreview = NSView()
        colorPreview.wantsLayer = true
        colorPreview.layer?.cornerRadius = 8
        colorPreview.layer?.borderWidth = 1
        colorPreview.layer?.borderColor = NSColor.separatorColor.cgColor
        colorPreview.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(colorPreview)
        view.addSubview(themeNameLabel)
        
        NSLayoutConstraint.activate([
            colorPreview.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            colorPreview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            colorPreview.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            colorPreview.heightAnchor.constraint(equalToConstant: 60),
            
            themeNameLabel.topAnchor.constraint(equalTo: colorPreview.bottomAnchor, constant: 5),
            themeNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            themeNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            themeNameLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -5)
        ])
    }
    
    func configure(with theme: Theme) {
        themeNameLabel.stringValue = theme.name
        colorPreview.layer?.backgroundColor = theme.colors.background.cgColor
        
        // Add color swatches
        colorPreview.subviews.forEach { $0.removeFromSuperview() }
        
        let colors = [
            theme.colors.text,
            theme.colors.headingText,
            theme.colors.linkText,
            theme.colors.codeBackground
        ]
        
        let swatchSize: CGFloat = 12
        let spacing: CGFloat = 4
        var x: CGFloat = 10
        
        for color in colors {
            let swatch = NSView(frame: NSRect(x: x, y: 24, width: swatchSize, height: swatchSize))
            swatch.wantsLayer = true
            swatch.layer?.backgroundColor = color.cgColor
            swatch.layer?.cornerRadius = 2
            swatch.layer?.borderWidth = 0.5
            swatch.layer?.borderColor = NSColor.separatorColor.cgColor
            colorPreview.addSubview(swatch)
            x += swatchSize + spacing
        }
    }
    
    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected ? NSColor.selectedControlColor.withAlphaComponent(0.3).cgColor : NSColor.clear.cgColor
        }
    }
}