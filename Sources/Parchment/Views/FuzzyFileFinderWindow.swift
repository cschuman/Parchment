import Cocoa
import Foundation

/// A fuzzy file finder window for quick file switching
class FuzzyFileFinderWindow: NSWindow {
    
    private var searchField: NSSearchField!
    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var statusLabel: NSTextField!
    
    private var allFiles: [FileItem] = []
    private var filteredFiles: [FileItem] = []
    private var searchWorkItem: DispatchWorkItem?
    
    var onFileSelected: ((URL) -> Void)?
    
    struct FileItem {
        let url: URL
        let name: String
        let path: String
        let modifiedDate: Date
        let size: Int64
        var score: Double = 0
        
        var displayPath: String {
            return path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
        }
    }
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                  styleMask: [.titled, .closable, .resizable],
                  backing: .buffered,
                  defer: false)
        
        setupWindow()
        setupViews()
        loadRecentFiles()
    }
    
    private func setupWindow() {
        title = "Quick Open"
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        level = .floating
        
        // Center on screen
        center()
    }
    
    private func setupViews() {
        let contentView = NSView()
        
        // Search field
        searchField = NSSearchField()
        searchField.placeholderString = "Type to search files..."
        searchField.delegate = self
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.focusRingType = .none
        searchField.font = NSFont.systemFont(ofSize: 16)
        
        // Table view
        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.headerView = nil
        tableView.intercellSpacing = NSSize(width: 0, height: 2)
        tableView.rowHeight = 44
        tableView.doubleAction = #selector(openSelectedFile)
        tableView.target = self
        
        // Create columns
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        nameColumn.width = 400
        tableView.addTableColumn(nameColumn)
        
        // Scroll view
        scrollView = NSScrollView()
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Status label
        statusLabel = NSTextField(labelWithString: "0 files")
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(searchField)
        contentView.addSubview(scrollView)
        contentView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            searchField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            searchField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            searchField.heightAnchor.constraint(equalToConstant: 28),
            
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -5),
            
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            statusLabel.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        self.contentView = contentView
        
        // Set up keyboard shortcuts
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.handleKeyEvent(event)
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        switch event.keyCode {
        case 53: // Escape
            close()
            return nil
            
        case 36: // Enter
            openSelectedFile()
            return nil
            
        case 125: // Down arrow
            if tableView.selectedRow < filteredFiles.count - 1 {
                tableView.selectRowIndexes(IndexSet(integer: tableView.selectedRow + 1), byExtendingSelection: false)
                tableView.scrollRowToVisible(tableView.selectedRow)
            }
            return nil
            
        case 126: // Up arrow
            if tableView.selectedRow > 0 {
                tableView.selectRowIndexes(IndexSet(integer: tableView.selectedRow - 1), byExtendingSelection: false)
                tableView.scrollRowToVisible(tableView.selectedRow)
            }
            return nil
            
        default:
            return event
        }
    }
    
    private func loadRecentFiles() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.scanForMarkdownFiles()
        }
    }
    
    private func scanForMarkdownFiles() {
        var files: [FileItem] = []
        
        // Start with recent documents
        if let recentData = UserDefaults.standard.data(forKey: "RecentDocuments"),
           let recentURLs = try? JSONDecoder().decode([URL].self, from: recentData) {
            for url in recentURLs {
                if let item = createFileItem(from: url) {
                    files.append(item)
                }
            }
        }
        
        // Scan common directories
        var searchPaths: [URL] = []
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            searchPaths.append(docs)
        }
        if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            searchPaths.append(desktop)
        }
        if let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            searchPaths.append(downloads)
        }
        searchPaths.append(URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Notes"))
        searchPaths.append(URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents/Obsidian"))
        
        for searchPath in searchPaths {
            scanDirectory(at: searchPath, into: &files, maxDepth: 3)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.allFiles = files.sorted { $0.modifiedDate > $1.modifiedDate }
            self?.filteredFiles = self?.allFiles ?? []
            self?.tableView.reloadData()
            self?.updateStatusLabel()
            
            if !(self?.filteredFiles.isEmpty ?? true) {
                self?.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            }
        }
    }
    
    private func scanDirectory(at url: URL, into files: inout [FileItem], maxDepth: Int, currentDepth: Int = 0) {
        guard currentDepth < maxDepth else { return }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            for itemURL in contents {
                let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey, .contentModificationDateKey, .fileSizeKey])
                
                if resourceValues.isDirectory ?? false {
                    scanDirectory(at: itemURL, into: &files, maxDepth: maxDepth, currentDepth: currentDepth + 1)
                } else if itemURL.pathExtension == "md" || itemURL.pathExtension == "markdown" {
                    if let item = createFileItem(from: itemURL) {
                        files.append(item)
                    }
                }
            }
        } catch {
            // Ignore errors for inaccessible directories
        }
    }
    
    private func createFileItem(from url: URL) -> FileItem? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let modifiedDate = attributes[.modificationDate] as? Date ?? Date()
            let size = attributes[.size] as? Int64 ?? 0
            
            return FileItem(
                url: url,
                name: url.lastPathComponent,
                path: url.path,
                modifiedDate: modifiedDate,
                size: size
            )
        } catch {
            return nil
        }
    }
    
    private func performFuzzySearch(_ query: String) {
        guard !query.isEmpty else {
            filteredFiles = allFiles
            tableView.reloadData()
            updateStatusLabel()
            return
        }
        
        // Cancel previous search
        searchWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            let results = self.allFiles.compactMap { file -> (FileItem, Double)? in
                let score = self.fuzzyMatch(query: query.lowercased(), in: file.name.lowercased())
                if score > 0 {
                    var fileWithScore = file
                    fileWithScore.score = score
                    return (fileWithScore, score)
                }
                return nil
            }
            
            let sorted = results.sorted { $0.1 > $1.1 }.map { $0.0 }
            
            DispatchQueue.main.async {
                self.filteredFiles = sorted
                self.tableView.reloadData()
                self.updateStatusLabel()
                
                if !self.filteredFiles.isEmpty {
                    self.tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
                }
            }
        }
        
        searchWorkItem = workItem
        DispatchQueue.global(qos: .userInteractive).async(execute: workItem)
    }
    
    private func fuzzyMatch(query: String, in text: String) -> Double {
        var score = 0.0
        var textIndex = text.startIndex
        var consecutiveMatches = 0
        
        for queryChar in query {
            var found = false
            
            while textIndex < text.endIndex {
                if text[textIndex] == queryChar {
                    score += 1.0
                    
                    // Bonus for consecutive matches
                    if consecutiveMatches > 0 {
                        score += Double(consecutiveMatches) * 0.5
                    }
                    consecutiveMatches += 1
                    
                    // Bonus for matching at word boundaries
                    if textIndex == text.startIndex || text[text.index(before: textIndex)] == " " || text[text.index(before: textIndex)] == "_" {
                        score += 2.0
                    }
                    
                    textIndex = text.index(after: textIndex)
                    found = true
                    break
                } else {
                    consecutiveMatches = 0
                }
                textIndex = text.index(after: textIndex)
            }
            
            if !found {
                return 0
            }
        }
        
        // Normalize score by length
        return score / Double(text.count)
    }
    
    @objc private func openSelectedFile() {
        guard tableView.selectedRow >= 0 && tableView.selectedRow < filteredFiles.count else { return }
        
        let file = filteredFiles[tableView.selectedRow]
        onFileSelected?(file.url)
        close()
    }
    
    private func updateStatusLabel() {
        let totalCount = allFiles.count
        let filteredCount = filteredFiles.count
        
        if searchField.stringValue.isEmpty {
            statusLabel.stringValue = "\(totalCount) files"
        } else {
            statusLabel.stringValue = "\(filteredCount) of \(totalCount) files"
        }
    }
}

// MARK: - NSSearchFieldDelegate

extension FuzzyFileFinderWindow: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        performFuzzySearch(searchField.stringValue)
    }
}

// MARK: - NSTableViewDataSource

extension FuzzyFileFinderWindow: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredFiles.count
    }
}

// MARK: - NSTableViewDelegate

extension FuzzyFileFinderWindow: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filteredFiles.count else { return nil }
        
        let file = filteredFiles[row]
        let container = NSView()
        
        // File name label
        let nameLabel = NSTextField(labelWithString: file.name)
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = .labelColor
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Path label
        let pathLabel = NSTextField(labelWithString: file.displayPath)
        pathLabel.font = NSFont.systemFont(ofSize: 11)
        pathLabel.textColor = .secondaryLabelColor
        pathLabel.lineBreakMode = .byTruncatingMiddle
        pathLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Score indicator (for debugging)
        let scoreLabel = NSTextField(labelWithString: String(format: "%.1f", file.score * 100))
        scoreLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        scoreLabel.textColor = .tertiaryLabelColor
        scoreLabel.isHidden = file.score == 0
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(nameLabel)
        container.addSubview(pathLabel)
        container.addSubview(scoreLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: scoreLabel.leadingAnchor, constant: -10),
            
            pathLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            pathLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            pathLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -10),
            
            scoreLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            scoreLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            scoreLabel.widthAnchor.constraint(equalToConstant: 40)
        ])
        
        return container
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = NSTableRowView()
        rowView.isEmphasized = false
        return rowView
    }
}