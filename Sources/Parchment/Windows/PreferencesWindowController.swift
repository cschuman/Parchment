import Cocoa

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    
    // UI Elements
    private var fontSizeSlider: NSSlider!
    private var fontSizeLabel: NSTextField!
    private var themePopup: NSPopUpButton!
    private var defaultWidthField: NSTextField!
    private var defaultHeightField: NSTextField!
    private var autoReloadCheckbox: NSButton!
    private var showLineNumbersCheckbox: NSButton!
    private var enableTypewriterCheckbox: NSButton!
    private var previewTextView: NSTextView!
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.center()
        
        self.init(window: window)
        window.delegate = self
        setupViews()
        loadPreferences()
    }
    
    private func setupViews() {
        guard let contentView = window?.contentView else { return }
        
        // Create tab view
        let tabView = NSTabView()
        tabView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tabView)
        
        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            tabView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            tabView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            tabView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
        
        // Add tabs
        tabView.addTabViewItem(createGeneralTab())
        tabView.addTabViewItem(createAppearanceTab())
        tabView.addTabViewItem(createEditorTab())
    }
    
    private func createGeneralTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "general")
        item.label = "General"
        
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 580, height: 400))
        
        // Default window size section
        let sizeLabel = NSTextField(labelWithString: "Default Window Size:")
        sizeLabel.font = .boldSystemFont(ofSize: 13)
        sizeLabel.frame = NSRect(x: 20, y: 350, width: 200, height: 20)
        view.addSubview(sizeLabel)
        
        let widthLabel = NSTextField(labelWithString: "Width:")
        widthLabel.frame = NSRect(x: 20, y: 320, width: 50, height: 20)
        view.addSubview(widthLabel)
        
        defaultWidthField = NSTextField()
        defaultWidthField.frame = NSRect(x: 75, y: 320, width: 80, height: 22)
        defaultWidthField.placeholderString = "1200"
        view.addSubview(defaultWidthField)
        
        let heightLabel = NSTextField(labelWithString: "Height:")
        heightLabel.frame = NSRect(x: 170, y: 320, width: 50, height: 20)
        view.addSubview(heightLabel)
        
        defaultHeightField = NSTextField()
        defaultHeightField.frame = NSRect(x: 225, y: 320, width: 80, height: 22)
        defaultHeightField.placeholderString = "800"
        view.addSubview(defaultHeightField)
        
        // Auto-reload checkbox
        autoReloadCheckbox = NSButton(checkboxWithTitle: "Auto-reload files when changed externally", target: self, action: #selector(toggleAutoReload))
        autoReloadCheckbox.frame = NSRect(x: 20, y: 280, width: 350, height: 20)
        view.addSubview(autoReloadCheckbox)
        
        // Show line numbers checkbox
        showLineNumbersCheckbox = NSButton(checkboxWithTitle: "Show line numbers", target: self, action: #selector(toggleLineNumbers))
        showLineNumbersCheckbox.frame = NSRect(x: 20, y: 250, width: 350, height: 20)
        view.addSubview(showLineNumbersCheckbox)
        
        item.view = view
        return item
    }
    
    private func createAppearanceTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "appearance")
        item.label = "Appearance"
        
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 580, height: 400))
        
        // Theme selection
        let themeLabel = NSTextField(labelWithString: "Theme:")
        themeLabel.font = .boldSystemFont(ofSize: 13)
        themeLabel.frame = NSRect(x: 20, y: 350, width: 100, height: 20)
        view.addSubview(themeLabel)
        
        themePopup = NSPopUpButton()
        themePopup.frame = NSRect(x: 120, y: 348, width: 200, height: 25)
        themePopup.addItems(withTitles: ["Light", "Dark", "System", "High Contrast", "Solarized Light", "Solarized Dark"])
        themePopup.target = self
        themePopup.action = #selector(themeChanged)
        view.addSubview(themePopup)
        
        // Font size slider
        let fontSizeTitle = NSTextField(labelWithString: "Font Size:")
        fontSizeTitle.font = .boldSystemFont(ofSize: 13)
        fontSizeTitle.frame = NSRect(x: 20, y: 310, width: 100, height: 20)
        view.addSubview(fontSizeTitle)
        
        fontSizeSlider = NSSlider()
        fontSizeSlider.frame = NSRect(x: 120, y: 310, width: 200, height: 20)
        fontSizeSlider.minValue = 10
        fontSizeSlider.maxValue = 24
        fontSizeSlider.target = self
        fontSizeSlider.action = #selector(fontSizeChanged)
        view.addSubview(fontSizeSlider)
        
        fontSizeLabel = NSTextField(labelWithString: "14pt")
        fontSizeLabel.frame = NSRect(x: 330, y: 310, width: 50, height: 20)
        fontSizeLabel.alignment = .left
        view.addSubview(fontSizeLabel)
        
        // Preview area
        let previewLabel = NSTextField(labelWithString: "Preview:")
        previewLabel.font = .boldSystemFont(ofSize: 13)
        previewLabel.frame = NSRect(x: 20, y: 270, width: 100, height: 20)
        view.addSubview(previewLabel)
        
        let scrollView = NSScrollView()
        scrollView.frame = NSRect(x: 20, y: 20, width: 540, height: 240)
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        
        previewTextView = NSTextView()
        previewTextView.isEditable = false
        previewTextView.isRichText = true
        previewTextView.string = """
        # Preview
        
        This is how your **markdown** will look with the current settings.
        
        - Font size: Adjustable with slider
        - Theme: Choose from multiple options
        - Code blocks are `highlighted`
        
        ```swift
        func example() {
            Logger.info("Hello, Parchment!")
        }
        ```
        """
        
        scrollView.documentView = previewTextView
        view.addSubview(scrollView)
        
        item.view = view
        return item
    }
    
    private func createEditorTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "editor")
        item.label = "Editor"
        
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 580, height: 400))
        
        // Typewriter mode
        enableTypewriterCheckbox = NSButton(checkboxWithTitle: "Enable typewriter scrolling", target: self, action: #selector(toggleTypewriter))
        enableTypewriterCheckbox.frame = NSRect(x: 20, y: 350, width: 300, height: 20)
        view.addSubview(enableTypewriterCheckbox)
        
        let typewriterDesc = NSTextField(wrappingLabelWithString: "Keeps the current line centered while typing")
        typewriterDesc.font = .systemFont(ofSize: 11)
        typewriterDesc.textColor = .secondaryLabelColor
        typewriterDesc.frame = NSRect(x: 40, y: 325, width: 400, height: 20)
        view.addSubview(typewriterDesc)
        
        // Focus mode
        let focusModeCheckbox = NSButton(checkboxWithTitle: "Enable focus mode by default", target: self, action: #selector(toggleFocusMode))
        focusModeCheckbox.frame = NSRect(x: 20, y: 290, width: 300, height: 20)
        view.addSubview(focusModeCheckbox)
        
        let focusDesc = NSTextField(wrappingLabelWithString: "Dims all text except the current paragraph")
        focusDesc.font = .systemFont(ofSize: 11)
        focusDesc.textColor = .secondaryLabelColor
        focusDesc.frame = NSRect(x: 40, y: 265, width: 400, height: 20)
        view.addSubview(focusDesc)
        
        item.view = view
        return item
    }
    
    @objc private func fontSizeChanged(_ sender: NSSlider) {
        let size = Int(sender.doubleValue)
        fontSizeLabel.stringValue = "\(size)pt"
        UserDefaults.standard.set(size, forKey: "fontSize")
        updatePreview()
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
    
    @objc private func themeChanged(_ sender: NSPopUpButton) {
        let theme = sender.titleOfSelectedItem ?? "System"
        UserDefaults.standard.set(theme, forKey: "theme")
        updatePreview()
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
    
    @objc private func toggleAutoReload(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "autoReload")
    }
    
    @objc private func toggleLineNumbers(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "showLineNumbers")
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
    
    @objc private func toggleTypewriter(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "typewriterMode")
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
    
    @objc private func toggleFocusMode(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "focusModeDefault")
        NotificationCenter.default.post(name: .preferencesChanged, object: nil)
    }
    
    private func loadPreferences() {
        // Load saved preferences
        let fontSize = UserDefaults.standard.integer(forKey: "fontSize")
        if fontSize > 0 {
            fontSizeSlider?.doubleValue = Double(fontSize)
            fontSizeLabel?.stringValue = "\(fontSize)pt"
        } else {
            fontSizeSlider?.doubleValue = 14
            fontSizeLabel?.stringValue = "14pt"
        }
        
        let theme = UserDefaults.standard.string(forKey: "theme") ?? "System"
        themePopup?.selectItem(withTitle: theme)
        
        autoReloadCheckbox?.state = UserDefaults.standard.bool(forKey: "autoReload") ? .on : .off
        showLineNumbersCheckbox?.state = UserDefaults.standard.bool(forKey: "showLineNumbers") ? .on : .off
        enableTypewriterCheckbox?.state = UserDefaults.standard.bool(forKey: "typewriterMode") ? .on : .off
        
        let width = UserDefaults.standard.integer(forKey: "defaultWindowWidth")
        let height = UserDefaults.standard.integer(forKey: "defaultWindowHeight")
        if width > 0 { defaultWidthField?.stringValue = "\(width)" }
        if height > 0 { defaultHeightField?.stringValue = "\(height)" }
        
        updatePreview()
    }
    
    private func updatePreview() {
        guard let textView = previewTextView else { return }
        
        let fontSize = CGFloat(fontSizeSlider?.doubleValue ?? 14)
        let theme = themePopup?.titleOfSelectedItem ?? "System"
        
        // Apply theme colors
        switch theme {
        case "Dark":
            textView.backgroundColor = NSColor(calibratedWhite: 0.1, alpha: 1.0)
            textView.textColor = NSColor.white
        case "High Contrast":
            textView.backgroundColor = NSColor.black
            textView.textColor = NSColor.white
        case "Solarized Light":
            textView.backgroundColor = NSColor(calibratedRed: 0.99, green: 0.96, blue: 0.89, alpha: 1.0)
            textView.textColor = NSColor(calibratedRed: 0.4, green: 0.48, blue: 0.51, alpha: 1.0)
        case "Solarized Dark":
            textView.backgroundColor = NSColor(calibratedRed: 0.0, green: 0.17, blue: 0.21, alpha: 1.0)
            textView.textColor = NSColor(calibratedRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0)
        default: // Light/System
            textView.backgroundColor = NSColor.textBackgroundColor
            textView.textColor = NSColor.labelColor
        }
        
        // Apply font size
        textView.font = NSFont.systemFont(ofSize: fontSize)
    }
    
    func windowWillClose(_ notification: Notification) {
        // Save window size preferences
        if let width = defaultWidthField?.integerValue, width > 0 {
            UserDefaults.standard.set(width, forKey: "defaultWindowWidth")
        }
        if let height = defaultHeightField?.integerValue, height > 0 {
            UserDefaults.standard.set(height, forKey: "defaultWindowHeight")
        }
    }
}

extension Notification.Name {
    static let preferencesChanged = Notification.Name("preferencesChanged")
}