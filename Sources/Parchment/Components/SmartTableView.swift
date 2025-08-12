import Cocoa
import QuartzCore

final class SmartTableView: NSView {
    
    struct TableData {
        let headers: [String]
        let rows: [[String]]
        let alignments: [ColumnAlignment]
    }
    
    enum ColumnAlignment {
        case left, center, right
    }
    
    private var scrollView: NSScrollView!
    private var tableView: NSTableView!
    private var headerView: StickyHeaderView!
    private var data: TableData?
    
    private var columnWidths: [CGFloat] = []
    private var sortOrder: [Int] = []
    private var currentSortColumn: Int = -1
    private var isAscending: Bool = true
    
    private let cellPadding: CGFloat = 12
    private let minColumnWidth: CGFloat = 60
    private let maxColumnWidth: CGFloat = 400
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView = NSTableView()
        tableView.style = .plain
        tableView.rowHeight = 36
        tableView.intercellSpacing = NSSize(width: 1, height: 1)
        tableView.gridStyleMask = [.solidHorizontalGridLineMask, .solidVerticalGridLineMask]
        tableView.gridColor = NSColor.separatorColor.withAlphaComponent(0.3)
        tableView.backgroundColor = NSColor.controlBackgroundColor
        tableView.selectionHighlightStyle = .regular
        tableView.allowsMultipleSelection = true
        tableView.allowsColumnReordering = true
        tableView.allowsColumnResizing = true
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        
        tableView.delegate = self
        tableView.dataSource = self
        
        scrollView.documentView = tableView
        
        headerView = StickyHeaderView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(scrollView)
        addSubview(headerView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        setupScrollObserver()
    }
    
    private func setupScrollObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidScroll),
            name: NSScrollView.didLiveScrollNotification,
            object: scrollView
        )
    }
    
    func setTableData(_ data: TableData) {
        self.data = data
        
        tableView.tableColumns.forEach { tableView.removeTableColumn($0) }
        
        calculateOptimalColumnWidths()
        
        for (index, header) in data.headers.enumerated() {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("column_\(index)"))
            column.title = header
            column.width = columnWidths[index]
            column.minWidth = minColumnWidth
            column.maxWidth = maxColumnWidth
            
            let headerCell = TableHeaderCell()
            headerCell.stringValue = header
            headerCell.alignment = alignmentToNSTextAlignment(data.alignments[safe: index] ?? .left)
            headerCell.isSortable = true
            headerCell.sortIndicator = .none
            column.headerCell = headerCell
            
            tableView.addTableColumn(column)
        }
        
        headerView.setHeaders(data.headers, alignments: data.alignments)
        
        sortOrder = Array(0..<data.rows.count)
        tableView.reloadData()
        
        animateTableAppearance()
    }
    
    private func calculateOptimalColumnWidths() {
        guard let data = data else { return }
        
        columnWidths = Array(repeating: minColumnWidth, count: data.headers.count)
        
        let font = NSFont.systemFont(ofSize: 13)
        let headerFont = NSFont.systemFont(ofSize: 13, weight: .semibold)
        let attributes = [NSAttributedString.Key.font: font]
        let headerAttributes = [NSAttributedString.Key.font: headerFont]
        
        for (index, header) in data.headers.enumerated() {
            let headerWidth = header.size(withAttributes: headerAttributes).width + cellPadding * 2
            columnWidths[index] = max(columnWidths[index], headerWidth)
        }
        
        for row in data.rows {
            for (index, cell) in row.enumerated() {
                let cellWidth = cell.size(withAttributes: attributes).width + cellPadding * 2
                columnWidths[index] = max(columnWidths[index], min(cellWidth, maxColumnWidth))
            }
        }
        
        let totalWidth = columnWidths.reduce(0, +)
        let availableWidth = bounds.width - 20
        
        if totalWidth < availableWidth {
            let scale = availableWidth / totalWidth
            columnWidths = columnWidths.map { $0 * scale }
        }
    }
    
    private func animateTableAppearance() {
        tableView.alphaValue = 0
        headerView.alpha = 0
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            tableView.animator().alphaValue = 1
            headerView.animator().alpha = 1
        }
        
        for (index, column) in tableView.tableColumns.enumerated() {
            let delay = Double(index) * 0.05
            
            column.width = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    column.width = self.columnWidths[index]
                }
            }
        }
    }
    
    @objc private func scrollViewDidScroll(_ notification: Notification) {
        let scrollY = scrollView.contentView.bounds.origin.y
        
        if scrollY > 0 {
            headerView.layer?.shadowOpacity = 0.1
            headerView.layer?.shadowRadius = 4
            headerView.layer?.shadowOffset = CGSize(width: 0, height: 2)
        } else {
            headerView.layer?.shadowOpacity = 0
        }
        
        let scrollX = scrollView.contentView.bounds.origin.x
        headerView.scrollToX(scrollX)
    }
    
    private func sortTable(by columnIndex: Int) {
        guard let data = data else { return }
        
        if currentSortColumn == columnIndex {
            isAscending.toggle()
        } else {
            currentSortColumn = columnIndex
            isAscending = true
        }
        
        sortOrder.sort { index1, index2 in
            let value1 = data.rows[index1][safe: columnIndex] ?? ""
            let value2 = data.rows[index2][safe: columnIndex] ?? ""
            
            if let num1 = Double(value1), let num2 = Double(value2) {
                return isAscending ? num1 < num2 : num1 > num2
            } else {
                return isAscending ?
                    value1.localizedCaseInsensitiveCompare(value2) == .orderedAscending :
                    value1.localizedCaseInsensitiveCompare(value2) == .orderedDescending
            }
        }
        
        for (index, column) in tableView.tableColumns.enumerated() {
            if let headerCell = column.headerCell as? TableHeaderCell {
                if index == columnIndex {
                    headerCell.sortIndicator = isAscending ? .ascending : .descending
                } else {
                    headerCell.sortIndicator = .none
                }
            }
        }
        
        tableView.reloadData()
        
        animateSortTransition()
    }
    
    private func animateSortTransition() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        
        let animation = CATransition()
        animation.type = .fade
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        tableView.layer?.add(animation, forKey: "sortAnimation")
        
        CATransaction.commit()
    }
    
    private func alignmentToNSTextAlignment(_ alignment: ColumnAlignment) -> NSTextAlignment {
        switch alignment {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        }
    }
}

extension SmartTableView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data?.rows.count ?? 0
    }
}

extension SmartTableView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let data = data,
              let columnIndex = tableView.tableColumns.firstIndex(where: { $0 === tableColumn }) else {
            return nil
        }
        
        let cellIdentifier = NSUserInterfaceItemIdentifier("TableCell")
        
        let cellView: TableCellView
        if let recycled = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? TableCellView {
            cellView = recycled
        } else {
            cellView = TableCellView()
            cellView.identifier = cellIdentifier
        }
        
        let actualRow = sortOrder[row]
        cellView.textField?.stringValue = data.rows[actualRow][safe: columnIndex] ?? ""
        cellView.textField?.alignment = alignmentToNSTextAlignment(data.alignments[safe: columnIndex] ?? .left)
        
        if let numValue = Double(cellView.textField?.stringValue ?? "") {
            cellView.textField?.textColor = NSColor.systemBlue
            cellView.textField?.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        } else {
            cellView.textField?.textColor = NSColor.labelColor
            cellView.textField?.font = NSFont.systemFont(ofSize: 13)
        }
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 36
    }
    
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        if let columnIndex = tableView.tableColumns.firstIndex(where: { $0 === tableColumn }) {
            sortTable(by: columnIndex)
        }
    }
}

class StickyHeaderView: NSView {
    private var headers: [String] = []
    private var alignments: [SmartTableView.ColumnAlignment] = []
    private var scrollOffset: CGFloat = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 0.5
    }
    
    func setHeaders(_ headers: [String], alignments: [SmartTableView.ColumnAlignment]) {
        self.headers = headers
        self.alignments = alignments
        needsDisplay = true
    }
    
    func scrollToX(_ x: CGFloat) {
        scrollOffset = x
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard !headers.isEmpty else { return }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: NSColor.labelColor
        ]
        
        var xOffset: CGFloat = -scrollOffset + 12
        
        for (index, header) in headers.enumerated() {
            let attributedString = NSAttributedString(string: header, attributes: attributes)
            let size = attributedString.size()
            
            let rect = NSRect(
                x: xOffset,
                y: (bounds.height - size.height) / 2,
                width: size.width,
                height: size.height
            )
            
            attributedString.draw(in: rect)
            
            xOffset += 150
        }
    }
    
    var alpha: CGFloat {
        get { alphaValue }
        set { alphaValue = newValue }
    }
}

class TableCellView: NSTableCellView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        let textField = NSTextField()
        textField.isBezeled = false
        textField.isEditable = false
        textField.drawsBackground = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(textField)
        self.textField = textField
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

class TableHeaderCell: NSTableHeaderCell {
    enum SortIndicator {
        case none, ascending, descending
    }
    
    var isSortable: Bool = false
    var sortIndicator: SortIndicator = .none
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.draw(withFrame: cellFrame, in: controlView)
        
        if isSortable && sortIndicator != .none {
            let indicatorRect = NSRect(
                x: cellFrame.maxX - 20,
                y: cellFrame.midY - 4,
                width: 8,
                height: 8
            )
            
            let path = NSBezierPath()
            
            switch sortIndicator {
            case .ascending:
                path.move(to: NSPoint(x: indicatorRect.midX, y: indicatorRect.minY))
                path.line(to: NSPoint(x: indicatorRect.minX, y: indicatorRect.maxY))
                path.line(to: NSPoint(x: indicatorRect.maxX, y: indicatorRect.maxY))
                path.close()
                
            case .descending:
                path.move(to: NSPoint(x: indicatorRect.midX, y: indicatorRect.maxY))
                path.line(to: NSPoint(x: indicatorRect.minX, y: indicatorRect.minY))
                path.line(to: NSPoint(x: indicatorRect.maxX, y: indicatorRect.minY))
                path.close()
                
            default:
                break
            }
            
            NSColor.secondaryLabelColor.setFill()
            path.fill()
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}