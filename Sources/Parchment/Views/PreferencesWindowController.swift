import Cocoa

class PreferencesWindowController: NSWindowController {
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Preferences"
        window.center()
        
        self.init(window: window)
        setupViews()
    }
    
    private func setupViews() {
        let tabViewController = NSTabViewController()
        tabViewController.tabStyle = .toolbar
        
        tabViewController.addTabViewItem(createGeneralTab())
        tabViewController.addTabViewItem(createAppearanceTab())
        tabViewController.addTabViewItem(createEditorTab())
        tabViewController.addTabViewItem(createAdvancedTab())
        
        window?.contentViewController = tabViewController
    }
    
    private func createGeneralTab() -> NSTabViewItem {
        let item = NSTabViewItem(viewController: GeneralPreferencesViewController())
        item.label = "General"
        item.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General")
        return item
    }
    
    private func createAppearanceTab() -> NSTabViewItem {
        let item = NSTabViewItem(viewController: AppearancePreferencesViewController())
        item.label = "Appearance"
        item.image = NSImage(systemSymbolName: "paintbrush", accessibilityDescription: "Appearance")
        return item
    }
    
    private func createEditorTab() -> NSTabViewItem {
        let item = NSTabViewItem(viewController: EditorPreferencesViewController())
        item.label = "Editor"
        item.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Editor")
        return item
    }
    
    private func createAdvancedTab() -> NSTabViewItem {
        let item = NSTabViewItem(viewController: AdvancedPreferencesViewController())
        item.label = "Advanced"
        item.image = NSImage(systemSymbolName: "wrench.and.screwdriver", accessibilityDescription: "Advanced")
        return item
    }
}

class GeneralPreferencesViewController: NSViewController {
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 300))
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 20
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let defaultEditorButton = NSButton(checkboxWithTitle: "Open files in external editor by default", target: self, action: #selector(toggleDefaultEditor))
        stackView.addArrangedSubview(defaultEditorButton)
        
        let autoUpdateButton = NSButton(checkboxWithTitle: "Check for updates automatically", target: self, action: #selector(toggleAutoUpdate))
        autoUpdateButton.state = .on
        stackView.addArrangedSubview(autoUpdateButton)
        
        let recentFilesSlider = createSliderSetting(title: "Number of recent files:", min: 5, max: 20, value: 10)
        stackView.addArrangedSubview(recentFilesSlider)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func createSliderSetting(title: String, min: Double, max: Double, value: Double) -> NSView {
        let container = NSView()
        
        let label = NSTextField(labelWithString: title)
        let slider = NSSlider(value: value, minValue: min, maxValue: max, target: self, action: #selector(sliderChanged))
        let valueLabel = NSTextField(labelWithString: "\(Int(value))")
        
        slider.numberOfTickMarks = Int(max - min) + 1
        slider.allowsTickMarkValuesOnly = true
        
        container.addSubview(label)
        container.addSubview(slider)
        container.addSubview(valueLabel)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            slider.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10),
            slider.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            slider.widthAnchor.constraint(equalToConstant: 200),
            
            valueLabel.leadingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 10),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return container
    }
    
    @objc private func toggleDefaultEditor(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "UseExternalEditor")
    }
    
    @objc private func toggleAutoUpdate(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "AutoUpdate")
    }
    
    @objc private func sliderChanged(_ sender: NSSlider) {
        UserDefaults.standard.set(sender.integerValue, forKey: "RecentFilesCount")
    }
}

class AppearancePreferencesViewController: NSViewController {
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 300))
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 20
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let themePopup = NSPopUpButton()
        themePopup.addItems(withTitles: ["System", "Light", "Dark"])
        themePopup.target = self
        themePopup.action = #selector(themeChanged)
        
        let themeContainer = createLabeledControl(label: "Theme:", control: themePopup)
        stackView.addArrangedSubview(themeContainer)
        
        let fontSizeSlider = NSSlider(value: 14, minValue: 10, maxValue: 24, target: self, action: #selector(fontSizeChanged))
        let fontContainer = createLabeledControl(label: "Default font size:", control: fontSizeSlider)
        stackView.addArrangedSubview(fontContainer)
        
        let lineSpacingSlider = NSSlider(value: 1.5, minValue: 1.0, maxValue: 2.0, target: self, action: #selector(lineSpacingChanged))
        let spacingContainer = createLabeledControl(label: "Line spacing:", control: lineSpacingSlider)
        stackView.addArrangedSubview(spacingContainer)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func createLabeledControl(label: String, control: NSControl) -> NSView {
        let container = NSView()
        
        let labelField = NSTextField(labelWithString: label)
        labelField.translatesAutoresizingMaskIntoConstraints = false
        control.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(labelField)
        container.addSubview(control)
        
        NSLayoutConstraint.activate([
            labelField.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            labelField.widthAnchor.constraint(equalToConstant: 120),
            
            control.leadingAnchor.constraint(equalTo: labelField.trailingAnchor, constant: 10),
            control.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            control.widthAnchor.constraint(equalToConstant: 200),
            control.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            container.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return container
    }
    
    @objc private func themeChanged(_ sender: NSPopUpButton) {
        UserDefaults.standard.set(sender.indexOfSelectedItem, forKey: "Theme")
    }
    
    @objc private func fontSizeChanged(_ sender: NSSlider) {
        UserDefaults.standard.set(sender.doubleValue, forKey: "DefaultFontSize")
    }
    
    @objc private func lineSpacingChanged(_ sender: NSSlider) {
        UserDefaults.standard.set(sender.doubleValue, forKey: "LineSpacing")
    }
}

class EditorPreferencesViewController: NSViewController {
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 300))
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 20
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let enableFocusModeButton = NSButton(checkboxWithTitle: "Enable Focus Mode by default", target: self, action: #selector(toggleFocusMode))
        stackView.addArrangedSubview(enableFocusModeButton)
        
        let typewriterScrollingButton = NSButton(checkboxWithTitle: "Enable typewriter scrolling", target: self, action: #selector(toggleTypewriter))
        stackView.addArrangedSubview(typewriterScrollingButton)
        
        let syntaxHighlightingButton = NSButton(checkboxWithTitle: "Enable syntax highlighting in code blocks", target: self, action: #selector(toggleSyntaxHighlighting))
        syntaxHighlightingButton.state = .on
        stackView.addArrangedSubview(syntaxHighlightingButton)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc private func toggleFocusMode(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "DefaultFocusMode")
    }
    
    @objc private func toggleTypewriter(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "TypewriterScrolling")
    }
    
    @objc private func toggleSyntaxHighlighting(_ sender: NSButton) {
        UserDefaults.standard.set(sender.state == .on, forKey: "SyntaxHighlighting")
    }
}

class AdvancedPreferencesViewController: NSViewController {
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 300))
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 20
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let cacheButton = NSButton(title: "Clear Cache", target: self, action: #selector(clearCache))
        stackView.addArrangedSubview(cacheButton)
        
        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetDefaults))
        stackView.addArrangedSubview(resetButton)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    @objc private func clearCache() {
        DocumentCache.shared.persist()
        ImageCache.shared.clear()
        
        let alert = NSAlert()
        alert.messageText = "Cache Cleared"
        alert.informativeText = "The document and image caches have been cleared."
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc private func resetDefaults() {
        let alert = NSAlert()
        alert.messageText = "Reset to Defaults"
        alert.informativeText = "Are you sure you want to reset all preferences to their default values?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            UserDefaults.standard.synchronize()
        }
    }
}