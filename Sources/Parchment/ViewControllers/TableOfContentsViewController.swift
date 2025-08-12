import Cocoa

protocol TableOfContentsDelegate: AnyObject {
    func didSelectHeader(_ header: MarkdownHeader)
}

class TableOfContentsViewController: NSViewController {
    weak var delegate: TableOfContentsDelegate?
    
    private var outlineView: NSOutlineView!
    private var headers: [MarkdownHeader] = []
    private var currentHighlight: MarkdownHeader?
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 600))
        setupViews()
    }
    
    private func setupViews() {
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        outlineView = NSOutlineView()
        outlineView.headerView = nil
        outlineView.floatsGroupRows = false
        outlineView.rowSizeStyle = .default
        outlineView.autoresizesOutlineColumn = true
        outlineView.indentationPerLevel = 16.0
        outlineView.selectionHighlightStyle = .regular
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("HeaderColumn"))
        column.isEditable = false
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        
        outlineView.delegate = self
        outlineView.dataSource = self
        outlineView.target = self
        outlineView.action = #selector(outlineViewClicked(_:))
        
        scrollView.documentView = outlineView
        
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }
    
    func updateTableOfContents(for document: MarkdownDocument) {
        headers = extractHeaders(from: document.content)
        outlineView.reloadData()
        
        if !headers.isEmpty {
            outlineView.expandItem(nil, expandChildren: true)
        }
    }
    
    private func extractHeaders(from markdown: String) -> [MarkdownHeader] {
        var headers: [MarkdownHeader] = []
        let lines = markdown.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("#") {
                let level = trimmed.prefix(while: { $0 == "#" }).count
                if level <= 6 {
                    let title = trimmed
                        .dropFirst(level)
                        .trimmingCharacters(in: .whitespaces)
                    
                    if !title.isEmpty {
                        headers.append(MarkdownHeader(
                            level: level,
                            title: String(title),
                            lineNumber: index,
                            parent: findParent(for: level, in: headers)
                        ))
                    }
                }
            }
        }
        
        return buildHierarchy(from: headers)
    }
    
    private func findParent(for level: Int, in headers: [MarkdownHeader]) -> MarkdownHeader? {
        for header in headers.reversed() {
            if header.level < level {
                return header
            }
        }
        return nil
    }
    
    private func buildHierarchy(from headers: [MarkdownHeader]) -> [MarkdownHeader] {
        var rootHeaders: [MarkdownHeader] = []
        var headerMap: [String: MarkdownHeader] = [:]
        
        for header in headers {
            headerMap[header.id] = header
            
            if let parentId = header.parent?.id,
               let parent = headerMap[parentId] {
                parent.children.append(header)
            } else {
                rootHeaders.append(header)
            }
        }
        
        return rootHeaders
    }
    
    func highlightCurrentSection(_ header: MarkdownHeader?) {
        currentHighlight = header
        outlineView.reloadData()
        
        if let header = header {
            let row = outlineView.row(forItem: header)
            if row >= 0 {
                outlineView.scrollRowToVisible(row)
            }
        }
    }
    
    @objc private func outlineViewClicked(_ sender: Any) {
        let clickedRow = outlineView.clickedRow
        guard clickedRow >= 0,
              let header = outlineView.item(atRow: clickedRow) as? MarkdownHeader else {
            return
        }
        
        delegate?.didSelectHeader(header)
    }
}

extension TableOfContentsViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return headers.count
        }
        
        if let header = item as? MarkdownHeader {
            return header.children.count
        }
        
        return 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return headers[index]
        }
        
        if let header = item as? MarkdownHeader {
            return header.children[index]
        }
        
        return ""
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let header = item as? MarkdownHeader {
            return !header.children.isEmpty
        }
        return false
    }
}

extension TableOfContentsViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cellIdentifier = NSUserInterfaceItemIdentifier("HeaderCell")
        
        var cellView = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView
        
        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = cellIdentifier
            
            let textField = NSTextField()
            textField.isEditable = false
            textField.isBordered = false
            textField.backgroundColor = .clear
            textField.translatesAutoresizingMaskIntoConstraints = false
            
            cellView?.addSubview(textField)
            cellView?.textField = textField
            
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
            ])
        }
        
        if let header = item as? MarkdownHeader {
            cellView?.textField?.stringValue = header.title
            
            let fontSize = CGFloat(14 - min(2, header.level - 1))
            let weight: NSFont.Weight = header.level <= 2 ? .semibold : .regular
            cellView?.textField?.font = NSFont.systemFont(ofSize: fontSize, weight: weight)
            
            if header == currentHighlight {
                cellView?.textField?.textColor = NSColor.controlAccentColor
            } else {
                cellView?.textField?.textColor = NSColor.labelColor
            }
        }
        
        return cellView
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if let header = item as? MarkdownHeader {
            return header.level <= 2 ? 28 : 24
        }
        return 24
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return true
    }
}