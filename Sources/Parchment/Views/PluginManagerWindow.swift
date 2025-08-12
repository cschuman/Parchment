import Cocoa

/// Window for managing plugins
class PluginManagerWindow: NSWindow {
    
    private var pluginTableView: NSTableView!
    private var detailView: NSView!
    private var nameLabel: NSTextField!
    private var versionLabel: NSTextField!
    private var authorLabel: NSTextField!
    private var descriptionLabel: NSTextField!
    private var enableButton: NSButton!
    private var configureButton: NSButton!
    
    private var plugins: [MarkdownPlugin] = []
    private var selectedPlugin: MarkdownPlugin?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
                  styleMask: [.titled, .closable, .resizable],
                  backing: .buffered,
                  defer: false)
        
        setupWindow()
        setupViews()
        loadPlugins()
    }
    
    private func setupWindow() {
        title = "Plugin Manager"
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
        
        // Left side - Plugin list
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        
        pluginTableView = NSTableView()
        pluginTableView.delegate = self
        pluginTableView.dataSource = self
        pluginTableView.rowHeight = 60
        pluginTableView.intercellSpacing = NSSize(width: 0, height: 5)
        pluginTableView.gridStyleMask = []
        
        // Columns
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.title = "Plugin"
        nameColumn.width = 250
        pluginTableView.addTableColumn(nameColumn)
        
        let statusColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("status"))
        statusColumn.title = "Status"
        statusColumn.width = 80
        pluginTableView.addTableColumn(statusColumn)
        
        scrollView.documentView = pluginTableView
        scrollView.hasVerticalScroller = true
        
        // Right side - Plugin details
        detailView = NSView()
        detailView.wantsLayer = true
        detailView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Plugin info labels
        let titleLabel = NSTextField(labelWithString: "Plugin Details")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel = NSTextField(labelWithString: "Select a plugin")
        nameLabel.font = NSFont.boldSystemFont(ofSize: 14)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        versionLabel = NSTextField(labelWithString: "")
        versionLabel.font = NSFont.systemFont(ofSize: 12)
        versionLabel.textColor = NSColor.secondaryLabelColor
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        authorLabel = NSTextField(labelWithString: "")
        authorLabel.font = NSFont.systemFont(ofSize: 12)
        authorLabel.textColor = NSColor.secondaryLabelColor
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        descriptionLabel = NSTextField(wrappingLabelWithString: "")
        descriptionLabel.font = NSFont.systemFont(ofSize: 13)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Buttons
        enableButton = NSButton(title: "Enable", target: self, action: #selector(togglePlugin))
        enableButton.bezelStyle = .rounded
        enableButton.translatesAutoresizingMaskIntoConstraints = false
        enableButton.isEnabled = false
        
        configureButton = NSButton(title: "Configure", target: self, action: #selector(configurePlugin))
        configureButton.bezelStyle = .rounded
        configureButton.translatesAutoresizingMaskIntoConstraints = false
        configureButton.isEnabled = false
        
        let installButton = NSButton(title: "Install Plugin...", target: self, action: #selector(installPlugin))
        installButton.bezelStyle = .rounded
        installButton.translatesAutoresizingMaskIntoConstraints = false
        
        detailView.addSubview(titleLabel)
        detailView.addSubview(nameLabel)
        detailView.addSubview(versionLabel)
        detailView.addSubview(authorLabel)
        detailView.addSubview(descriptionLabel)
        detailView.addSubview(enableButton)
        detailView.addSubview(configureButton)
        detailView.addSubview(installButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: detailView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: detailView.leadingAnchor, constant: 20),
            
            nameLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: detailView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: detailView.trailingAnchor, constant: -20),
            
            versionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            versionLabel.leadingAnchor.constraint(equalTo: detailView.leadingAnchor, constant: 20),
            
            authorLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 5),
            authorLabel.leadingAnchor.constraint(equalTo: detailView.leadingAnchor, constant: 20),
            
            descriptionLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 15),
            descriptionLabel.leadingAnchor.constraint(equalTo: detailView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: detailView.trailingAnchor, constant: -20),
            
            enableButton.leadingAnchor.constraint(equalTo: detailView.leadingAnchor, constant: 20),
            enableButton.bottomAnchor.constraint(equalTo: detailView.bottomAnchor, constant: -20),
            enableButton.widthAnchor.constraint(equalToConstant: 100),
            
            configureButton.leadingAnchor.constraint(equalTo: enableButton.trailingAnchor, constant: 10),
            configureButton.bottomAnchor.constraint(equalTo: detailView.bottomAnchor, constant: -20),
            configureButton.widthAnchor.constraint(equalToConstant: 100),
            
            installButton.trailingAnchor.constraint(equalTo: detailView.trailingAnchor, constant: -20),
            installButton.bottomAnchor.constraint(equalTo: detailView.bottomAnchor, constant: -20)
        ])
        
        splitView.addArrangedSubview(scrollView)
        splitView.addArrangedSubview(detailView)
        
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
    }
    
    private func loadPlugins() {
        plugins = PluginManager.shared.getAllPlugins()
        pluginTableView.reloadData()
    }
    
    private func updateDetailView(for plugin: MarkdownPlugin?) {
        guard let plugin = plugin else {
            nameLabel.stringValue = "Select a plugin"
            versionLabel.stringValue = ""
            authorLabel.stringValue = ""
            descriptionLabel.stringValue = ""
            enableButton.isEnabled = false
            configureButton.isEnabled = false
            return
        }
        
        selectedPlugin = plugin
        
        nameLabel.stringValue = plugin.name
        versionLabel.stringValue = "Version \(plugin.version)"
        authorLabel.stringValue = "By \(plugin.author)"
        descriptionLabel.stringValue = plugin.description
        
        enableButton.isEnabled = true
        enableButton.title = plugin.isEnabled ? "Disable" : "Enable"
        
        // Check if plugin has configuration
        configureButton.isEnabled = !plugin.getConfiguration().isEmpty || plugin is MarkdownActionPlugin
    }
    
    @objc private func togglePlugin() {
        guard let plugin = selectedPlugin else { return }
        
        PluginManager.shared.togglePlugin(plugin.identifier)
        
        // Update UI
        enableButton.title = plugin.isEnabled ? "Disable" : "Enable"
        pluginTableView.reloadData()
    }
    
    @objc private func configurePlugin() {
        guard let plugin = selectedPlugin else { return }
        
        // Show configuration dialog
        let alert = NSAlert()
        alert.messageText = "Configure \(plugin.name)"
        alert.informativeText = "Plugin configuration coming soon!"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func installPlugin() {
        // Show file picker for .mdplugin files
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["mdplugin"]
        openPanel.message = "Select a plugin to install"
        
        openPanel.beginSheetModal(for: self) { response in
            if response == .OK, let url = openPanel.url {
                // Install plugin
                self.installPluginFromURL(url)
            }
        }
    }
    
    private func installPluginFromURL(_ url: URL) {
        // Copy plugin to plugins directory
        if let pluginsDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Parchment")
            .appendingPathComponent("Plugins") {
            
            do {
                let destinationURL = pluginsDir.appendingPathComponent(url.lastPathComponent)
                try FileManager.default.copyItem(at: url, to: destinationURL)
                
                // Reload plugins
                PluginManager.shared.loadAllPlugins()
                loadPlugins()
                
                let alert = NSAlert()
                alert.messageText = "Plugin Installed"
                alert.informativeText = "The plugin has been installed successfully."
                alert.runModal()
            } catch {
                let alert = NSAlert()
                alert.messageText = "Installation Failed"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }
}

// MARK: - Table View DataSource

extension PluginManagerWindow: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return plugins.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let plugin = plugins[row]
        
        if tableColumn?.identifier.rawValue == "name" {
            let cellView = NSView()
            
            let nameLabel = NSTextField(labelWithString: plugin.name)
            nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let descLabel = NSTextField(labelWithString: plugin.description)
            descLabel.font = NSFont.systemFont(ofSize: 11)
            descLabel.textColor = NSColor.secondaryLabelColor
            descLabel.translatesAutoresizingMaskIntoConstraints = false
            
            cellView.addSubview(nameLabel)
            cellView.addSubview(descLabel)
            
            NSLayoutConstraint.activate([
                nameLabel.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 10),
                nameLabel.topAnchor.constraint(equalTo: cellView.topAnchor, constant: 10),
                nameLabel.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -10),
                
                descLabel.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 10),
                descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
                descLabel.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -10)
            ])
            
            return cellView
        } else if tableColumn?.identifier.rawValue == "status" {
            let cellView = NSView()
            
            let statusLabel = NSTextField(labelWithString: plugin.isEnabled ? "Enabled" : "Disabled")
            statusLabel.font = NSFont.systemFont(ofSize: 11)
            statusLabel.textColor = plugin.isEnabled ? NSColor.systemGreen : NSColor.secondaryLabelColor
            statusLabel.alignment = .center
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
            
            cellView.addSubview(statusLabel)
            
            NSLayoutConstraint.activate([
                statusLabel.centerXAnchor.constraint(equalTo: cellView.centerXAnchor),
                statusLabel.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
            ])
            
            return cellView
        }
        
        return nil
    }
}

// MARK: - Table View Delegate

extension PluginManagerWindow: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = pluginTableView.selectedRow
        
        if selectedRow >= 0 && selectedRow < plugins.count {
            updateDetailView(for: plugins[selectedRow])
        } else {
            updateDetailView(for: nil)
        }
    }
}