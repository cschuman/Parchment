import Cocoa

protocol BacklinksViewControllerDelegate: AnyObject {
    func didSelectBacklink(_ backlink: WikiLinkParser.Backlink)
}

class BacklinksViewController: NSViewController {
    weak var delegate: BacklinksViewControllerDelegate?
    
    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var backlinks: [WikiLinkParser.Backlink] = []
    private var emptyStateLabel: NSTextField!
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        setupViews()
    }
    
    private func setupViews() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        let headerLabel = NSTextField(labelWithString: "Backlinks")
        headerLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerLabel)
        
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        
        tableView = NSTableView()
        tableView.headerView = nil
        tableView.rowSizeStyle = .custom
        tableView.rowHeight = 60
        tableView.intercellSpacing = NSSize(width: 0, height: 1)
        tableView.gridStyleMask = .solidHorizontalGridLineMask
        tableView.selectionHighlightStyle = .regular
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("BacklinkColumn"))
        column.isEditable = false
        tableView.addTableColumn(column)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self
        tableView.doubleAction = #selector(tableViewDoubleClicked(_:))
        
        scrollView.documentView = tableView
        
        emptyStateLabel = NSTextField(labelWithString: "No backlinks found")
        emptyStateLabel.font = NSFont.systemFont(ofSize: 13)
        emptyStateLabel.textColor = NSColor.secondaryLabelColor
        emptyStateLabel.alignment = .center
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.isHidden = true
        
        view.addSubview(scrollView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            
            scrollView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func updateBacklinks(_ backlinks: [WikiLinkParser.Backlink]) {
        self.backlinks = backlinks.sorted { $0.sourceFile.lastPathComponent < $1.sourceFile.lastPathComponent }
        
        tableView.reloadData()
        
        let hasBacklinks = !backlinks.isEmpty
        scrollView.isHidden = !hasBacklinks
        emptyStateLabel.isHidden = hasBacklinks
    }
    
    @objc private func tableViewDoubleClicked(_ sender: Any) {
        let clickedRow = tableView.clickedRow
        guard clickedRow >= 0 && clickedRow < backlinks.count else { return }
        
        let backlink = backlinks[clickedRow]
        delegate?.didSelectBacklink(backlink)
    }
}

extension BacklinksViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return backlinks.count
    }
}

extension BacklinksViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let backlink = backlinks[row]
        
        let cellView = BacklinkCellView()
        cellView.configure(with: backlink)
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
}

class BacklinkCellView: NSView {
    private var fileLabel: NSTextField!
    private var contextLabel: NSTextField!
    private var lineLabel: NSTextField!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        fileLabel = NSTextField(labelWithString: "")
        fileLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        fileLabel.textColor = NSColor.labelColor
        fileLabel.lineBreakMode = .byTruncatingTail
        fileLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contextLabel = NSTextField(labelWithString: "")
        contextLabel.font = NSFont.systemFont(ofSize: 11)
        contextLabel.textColor = NSColor.secondaryLabelColor
        contextLabel.lineBreakMode = .byTruncatingTail
        contextLabel.maximumNumberOfLines = 2
        contextLabel.translatesAutoresizingMaskIntoConstraints = false
        
        lineLabel = NSTextField(labelWithString: "")
        lineLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        lineLabel.textColor = NSColor.tertiaryLabelColor
        lineLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(fileLabel)
        addSubview(contextLabel)
        addSubview(lineLabel)
        
        NSLayoutConstraint.activate([
            fileLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            fileLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            fileLabel.trailingAnchor.constraint(equalTo: lineLabel.leadingAnchor, constant: -8),
            
            contextLabel.topAnchor.constraint(equalTo: fileLabel.bottomAnchor, constant: 4),
            contextLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            contextLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            contextLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
            
            lineLabel.centerYAnchor.constraint(equalTo: fileLabel.centerYAnchor),
            lineLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            lineLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
    }
    
    func configure(with backlink: WikiLinkParser.Backlink) {
        fileLabel.stringValue = backlink.sourceFile.lastPathComponent
        contextLabel.stringValue = backlink.context.trimmingCharacters(in: .whitespacesAndNewlines)
        lineLabel.stringValue = "L\(backlink.lineNumber)"
    }
}