import Cocoa

/// Window for selecting and previewing themes
class ThemeSelectorWindow: NSWindow {

    private var themeCollectionView: NSCollectionView!
    private var previewTextView: NSTextView!

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

        let applyButton = NSButton(title: "Apply", target: self, action: #selector(applyTheme))
        applyButton.bezelStyle = .rounded
        applyButton.keyEquivalent = "\r"
        applyButton.translatesAutoresizingMaskIntoConstraints = false

        previewContainer.addSubview(previewLabel)
        previewContainer.addSubview(previewScrollView)
        previewContainer.addSubview(applyButton)

        NSLayoutConstraint.activate([
            previewLabel.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 10),
            previewLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 10),

            previewScrollView.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 10),
            previewScrollView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 10),
            previewScrollView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -10),
            previewScrollView.bottomAnchor.constraint(equalTo: applyButton.topAnchor, constant: -10),

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

        // Set initial preview
        updatePreview(with: ParchmentTheme.current)
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
        if let currentIndex = ParchmentTheme.all.firstIndex(where: { $0.name == ParchmentTheme.current.name }) {
            themeCollectionView.selectItems(at: [IndexPath(item: currentIndex, section: 0)], scrollPosition: .centeredVertically)
        }
    }

    private func updatePreview(with theme: ParchmentTheme) {
        let previewText = """
        # \(theme.name) Theme

        This is a preview of the **\(theme.name)** theme showing various markdown elements.

        ## Headers

        ### Level 3 Header
        #### Level 4 Header

        ## Text Formatting

        Regular text with **bold**, *italic*, and ***bold italic*** formatting.

        You can also use ~~strikethrough~~ and `inline code`.

        ## Code Block

        ```swift
        func greet(name: String) -> String {
            return "Hello, \\(name)!"
        }
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
        """

        // Apply theme to preview
        let attributedString = NSMutableAttributedString(string: previewText)
        let fullRange = NSRange(location: 0, length: attributedString.length)

        // Background
        previewTextView.backgroundColor = theme.backgroundColor

        // Base text
        let bodyFont = NSFont(name: theme.bodyFontName, size: theme.baseFontSize) ?? NSFont.systemFont(ofSize: theme.baseFontSize)
        attributedString.addAttribute(.font, value: bodyFont, range: fullRange)
        attributedString.addAttribute(.foregroundColor, value: theme.textColor, range: fullRange)

        // Apply paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = theme.lineHeightMultiple
        paragraphStyle.paragraphSpacing = 8
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)

        // Style headers
        let headingFont = NSFont(name: theme.headingFontName, size: theme.baseFontSize * 1.5) ?? NSFont.boldSystemFont(ofSize: theme.baseFontSize * 1.5)
        let headerRegex = try? NSRegularExpression(pattern: "^#+\\s+.*$", options: [.anchorsMatchLines])
        headerRegex?.enumerateMatches(in: previewText, options: [], range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            attributedString.addAttribute(.font, value: headingFont, range: range)
            attributedString.addAttribute(.foregroundColor, value: theme.headingColor, range: range)
        }

        // Style code blocks
        let codeFont = NSFont(name: theme.codeFontName, size: theme.baseFontSize - 1) ?? NSFont.monospacedSystemFont(ofSize: theme.baseFontSize - 1, weight: .regular)
        let codeRegex = try? NSRegularExpression(pattern: "`[^`]+`", options: [])
        codeRegex?.enumerateMatches(in: previewText, options: [], range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            attributedString.addAttribute(.font, value: codeFont, range: range)
            attributedString.addAttribute(.foregroundColor, value: theme.codeTextColor, range: range)
            attributedString.addAttribute(.backgroundColor, value: theme.codeBackgroundColor, range: range)
        }

        // Style links
        let linkRegex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\([^\\)]+\\)", options: [])
        linkRegex?.enumerateMatches(in: previewText, options: [], range: fullRange) { match, _, _ in
            guard let range = match?.range else { return }
            attributedString.addAttribute(.foregroundColor, value: theme.linkColor, range: range)
            attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        }

        previewTextView.textStorage?.setAttributedString(attributedString)
    }

    @objc private func applyTheme() {
        guard let selectedIndex = themeCollectionView.selectionIndexPaths.first else { return }

        let selectedTheme = ParchmentTheme.all[selectedIndex.item]
        ParchmentTheme.current = selectedTheme
        close()
    }
}

// MARK: - Collection View DataSource

extension ThemeSelectorWindow: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return ParchmentTheme.all.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("ThemeItem"), for: indexPath) as! ThemeItemView
        let theme = ParchmentTheme.all[indexPath.item]
        item.configure(with: theme)
        return item
    }
}

// MARK: - Collection View Delegate

extension ThemeSelectorWindow: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        let selectedTheme = ParchmentTheme.all[indexPath.item]
        updatePreview(with: selectedTheme)
    }
}

// MARK: - Theme Item View

class ThemeItemView: NSCollectionViewItem {

    private var themeNameLabel: NSTextField!
    private var colorPreview: NSView!

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 8

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

    func configure(with theme: ParchmentTheme) {
        themeNameLabel.stringValue = theme.name
        colorPreview.layer?.backgroundColor = theme.backgroundColor.cgColor

        // Add color swatches
        colorPreview.subviews.forEach { $0.removeFromSuperview() }

        let colors = [
            theme.textColor,
            theme.headingColor,
            theme.linkColor,
            theme.codeBackgroundColor
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
