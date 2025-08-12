import Cocoa
import QuartzCore
import os.log

private let searchLog = OSLog(subsystem: "com.markdownviewer", category: "Search")

final class InstantFuzzySearch: NSViewController {
    
    struct SearchResult {
        let content: String
        let location: NSRange
        let context: String
        let score: Double
        let lineNumber: Int
        let type: ResultType
        
        enum ResultType {
            case heading
            case paragraph
            case code
            case link
            case list
        }
    }
    
    private var searchField: NSSearchField!
    private var resultsTableView: NSTableView!
    private var scrollView: NSScrollView!
    private var statusLabel: NSTextField!
    private var searchProgress: NSProgressIndicator!
    
    private var results: [SearchResult] = []
    private var highlightedRanges: [NSRange] = []
    private var currentResultIndex = -1
    
    private let searchQueue = OperationQueue()
    private var currentSearchOperation: Operation?
    
    weak var delegate: InstantFuzzySearchDelegate?
    weak var textView: NSTextView?
    
    private let highlightColor = NSColor.systemYellow.withAlphaComponent(0.3)
    private let currentHighlightColor = NSColor.systemOrange.withAlphaComponent(0.5)
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 400))
        setupViews()
    }
    
    private func setupViews() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        view.layer?.cornerRadius = 10
        view.layer?.shadowRadius = 10
        view.layer?.shadowOpacity = 0.2
        
        searchField = NSSearchField()
        searchField.placeholderString = "Search (⌘F)"
        searchField.delegate = self
        searchField.sendsSearchStringImmediately = true
        searchField.sendsWholeSearchString = false
        searchField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchField)
        
        searchProgress = NSProgressIndicator()
        searchProgress.style = .spinning
        searchProgress.controlSize = .small
        searchProgress.isDisplayedWhenStopped = false
        searchProgress.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchProgress)
        
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        resultsTableView = NSTableView()
        resultsTableView.style = .plain
        resultsTableView.rowHeight = 60
        resultsTableView.intercellSpacing = NSSize(width: 0, height: 1)
        resultsTableView.backgroundColor = .clear
        resultsTableView.delegate = self
        resultsTableView.dataSource = self
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ResultColumn"))
        column.width = 300
        resultsTableView.addTableColumn(column)
        resultsTableView.headerView = nil
        
        scrollView.documentView = resultsTableView
        
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: searchProgress.leadingAnchor, constant: -8),
            
            searchProgress.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            searchProgress.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -8),
            
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            statusLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        
        setupKeyboardShortcuts()
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            switch event.keyCode {
            case 125: // Down arrow
                self.selectNextResult()
                return nil
            case 126: // Up arrow
                self.selectPreviousResult()
                return nil
            case 36: // Enter
                self.openSelectedResult()
                return nil
            case 53: // Escape
                self.clearSearch()
                return nil
            default:
                break
            }
            
            if event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers {
                case "g":
                    if event.modifierFlags.contains(.shift) {
                        self.selectPreviousResult()
                    } else {
                        self.selectNextResult()
                    }
                    return nil
                default:
                    break
                }
            }
            
            return event
        }
    }
    
    func performSearch(_ query: String) {
        currentSearchOperation?.cancel()
        
        guard !query.isEmpty else {
            clearResults()
            return
        }
        
        searchProgress.startAnimation(nil)
        
        let operation = SearchOperation(
            query: query,
            content: textView?.string ?? "",
            textStorage: textView?.textStorage
        ) { [weak self] results in
            DispatchQueue.main.async {
                self?.displayResults(results)
                self?.searchProgress.stopAnimation(nil)
            }
        }
        
        currentSearchOperation = operation
        searchQueue.addOperation(operation)
    }
    
    private func displayResults(_ results: [SearchResult]) {
        self.results = results
        resultsTableView.reloadData()
        
        updateStatusLabel()
        highlightAllResults()
        
        if !results.isEmpty {
            currentResultIndex = 0
            resultsTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            scrollToResult(at: 0)
        }
    }
    
    private func highlightAllResults() {
        clearHighlights()
        
        guard let textStorage = textView?.textStorage else { return }
        
        for result in results {
            textStorage.addAttribute(
                .backgroundColor,
                value: highlightColor,
                range: result.location
            )
            highlightedRanges.append(result.location)
        }
    }
    
    private func clearHighlights() {
        guard let textStorage = textView?.textStorage else { return }
        
        for range in highlightedRanges {
            textStorage.removeAttribute(.backgroundColor, range: range)
        }
        highlightedRanges.removeAll()
    }
    
    private func selectNextResult() {
        guard !results.isEmpty else { return }
        
        currentResultIndex = (currentResultIndex + 1) % results.count
        resultsTableView.selectRowIndexes(IndexSet(integer: currentResultIndex), byExtendingSelection: false)
        resultsTableView.scrollRowToVisible(currentResultIndex)
        scrollToResult(at: currentResultIndex)
        updateCurrentHighlight()
    }
    
    private func selectPreviousResult() {
        guard !results.isEmpty else { return }
        
        currentResultIndex = currentResultIndex > 0 ? currentResultIndex - 1 : results.count - 1
        resultsTableView.selectRowIndexes(IndexSet(integer: currentResultIndex), byExtendingSelection: false)
        resultsTableView.scrollRowToVisible(currentResultIndex)
        scrollToResult(at: currentResultIndex)
        updateCurrentHighlight()
    }
    
    private func updateCurrentHighlight() {
        guard let textStorage = textView?.textStorage else { return }
        
        for (index, result) in results.enumerated() {
            let color = index == currentResultIndex ? currentHighlightColor : highlightColor
            textStorage.addAttribute(
                .backgroundColor,
                value: color,
                range: result.location
            )
        }
    }
    
    private func scrollToResult(at index: Int) {
        guard index < results.count,
              let textView = textView else { return }
        
        let result = results[index]
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            textView.scrollRangeToVisible(result.location)
        }
        
        animateHighlight(at: result.location)
    }
    
    private func animateHighlight(at range: NSRange) {
        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        let pulseLayer = CALayer()
        pulseLayer.frame = rect
        pulseLayer.backgroundColor = NSColor.systemOrange.cgColor
        pulseLayer.cornerRadius = 4
        pulseLayer.opacity = 0
        
        textView.layer?.addSublayer(pulseLayer)
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 0.5
        animation.duration = 0.3
        animation.autoreverses = true
        animation.isRemovedOnCompletion = true
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            pulseLayer.removeFromSuperlayer()
        }
        pulseLayer.add(animation, forKey: "pulse")
        CATransaction.commit()
    }
    
    private func openSelectedResult() {
        guard currentResultIndex >= 0 && currentResultIndex < results.count else { return }
        
        let result = results[currentResultIndex]
        delegate?.instantFuzzySearch(self, didSelectResult: result)
    }
    
    private func clearSearch() {
        searchField.stringValue = ""
        clearResults()
        clearHighlights()
        delegate?.instantFuzzySearchDidClear(self)
    }
    
    private func clearResults() {
        results.removeAll()
        resultsTableView.reloadData()
        currentResultIndex = -1
        updateStatusLabel()
    }
    
    private func updateStatusLabel() {
        if results.isEmpty {
            statusLabel.stringValue = searchField.stringValue.isEmpty ? "" : "No results"
        } else {
            let current = currentResultIndex >= 0 ? currentResultIndex + 1 : 0
            statusLabel.stringValue = "\(current) of \(results.count) results"
        }
    }
}

extension InstantFuzzySearch: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let searchField = obj.object as? NSSearchField else { return }
        performSearch(searchField.stringValue)
    }
}

extension InstantFuzzySearch: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return results.count
    }
}

extension InstantFuzzySearch: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let result = results[row]
        
        let cellView = SearchResultCellView()
        cellView.configure(with: result, searchQuery: searchField.stringValue)
        
        return cellView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = resultsTableView.selectedRow
        if selectedRow >= 0 {
            currentResultIndex = selectedRow
            scrollToResult(at: selectedRow)
            updateCurrentHighlight()
        }
    }
}

class SearchResultCellView: NSTableCellView {
    private var typeIcon: NSImageView!
    private var contentLabel: NSTextField!
    private var contextLabel: NSTextField!
    private var lineNumberLabel: NSTextField!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        typeIcon = NSImageView()
        typeIcon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(typeIcon)
        
        contentLabel = NSTextField(labelWithString: "")
        contentLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        contentLabel.maximumNumberOfLines = 1
        contentLabel.lineBreakMode = .byTruncatingTail
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentLabel)
        
        contextLabel = NSTextField(labelWithString: "")
        contextLabel.font = NSFont.systemFont(ofSize: 11)
        contextLabel.textColor = NSColor.secondaryLabelColor
        contextLabel.maximumNumberOfLines = 2
        contextLabel.lineBreakMode = .byTruncatingTail
        contextLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contextLabel)
        
        lineNumberLabel = NSTextField(labelWithString: "")
        lineNumberLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .light)
        lineNumberLabel.textColor = NSColor.tertiaryLabelColor
        lineNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(lineNumberLabel)
        
        NSLayoutConstraint.activate([
            typeIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            typeIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            typeIcon.widthAnchor.constraint(equalToConstant: 16),
            typeIcon.heightAnchor.constraint(equalToConstant: 16),
            
            contentLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            contentLabel.leadingAnchor.constraint(equalTo: typeIcon.trailingAnchor, constant: 8),
            contentLabel.trailingAnchor.constraint(equalTo: lineNumberLabel.leadingAnchor, constant: -8),
            
            contextLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 2),
            contextLabel.leadingAnchor.constraint(equalTo: contentLabel.leadingAnchor),
            contextLabel.trailingAnchor.constraint(equalTo: contentLabel.trailingAnchor),
            contextLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8),
            
            lineNumberLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            lineNumberLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    
    func configure(with result: InstantFuzzySearch.SearchResult, searchQuery: String) {
        let iconName: String
        let iconColor: NSColor
        
        switch result.type {
        case .heading:
            iconName = "text.badge.star"
            iconColor = .systemBlue
        case .paragraph:
            iconName = "text.alignleft"
            iconColor = .systemGray
        case .code:
            iconName = "curlybraces"
            iconColor = .systemPurple
        case .link:
            iconName = "link"
            iconColor = .systemGreen
        case .list:
            iconName = "list.bullet"
            iconColor = .systemOrange
        }
        
        typeIcon.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        typeIcon.contentTintColor = iconColor
        
        let attributedContent = highlightMatches(in: result.content, query: searchQuery)
        contentLabel.attributedStringValue = attributedContent
        
        contextLabel.stringValue = result.context
        lineNumberLabel.stringValue = "L\(result.lineNumber)"
    }
    
    private func highlightMatches(in text: String, query: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        attributedString.addAttributes(baseAttributes, range: NSRange(location: 0, length: text.count))
        
        let lowercaseText = text.lowercased()
        let lowercaseQuery = query.lowercased()
        
        var searchRange = NSRange(location: 0, length: text.count)
        while searchRange.location < text.count {
            guard let range = lowercaseText.range(
                of: lowercaseQuery,
                options: [],
                range: Range(searchRange, in: lowercaseText)
            ) else { break }
            
            let nsRange = NSRange(range, in: text)
            attributedString.addAttributes([
                .backgroundColor: NSColor.systemYellow.withAlphaComponent(0.3),
                .font: NSFont.systemFont(ofSize: 12, weight: .bold)
            ], range: nsRange)
            
            searchRange.location = nsRange.location + nsRange.length
            searchRange.length = text.count - searchRange.location
        }
        
        return attributedString
    }
}

private class SearchOperation: Operation {
    let query: String
    let content: String
    let textStorage: NSTextStorage?
    let completion: ([InstantFuzzySearch.SearchResult]) -> Void
    
    init(query: String, content: String, textStorage: NSTextStorage?, completion: @escaping ([InstantFuzzySearch.SearchResult]) -> Void) {
        self.query = query
        self.content = content
        self.textStorage = textStorage
        self.completion = completion
    }
    
    override func main() {
        guard !isCancelled else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let results = performFuzzySearch()
        let searchTime = CFAbsoluteTimeGetCurrent() - startTime
        
        os_log(.debug, log: searchLog, "Search completed in %.2fms with %d results", searchTime * 1000, results.count)
        
        guard !isCancelled else { return }
        completion(results)
    }
    
    private func performFuzzySearch() -> [InstantFuzzySearch.SearchResult] {
        var results: [InstantFuzzySearch.SearchResult] = []
        let lines = content.components(separatedBy: .newlines)
        let lowercaseQuery = query.lowercased()
        
        for (lineIndex, line) in lines.enumerated() {
            guard !isCancelled else { break }
            
            let lowercaseLine = line.lowercased()
            
            if let range = lowercaseLine.range(of: lowercaseQuery) {
                let nsRange = NSRange(range, in: line)
                let score = calculateFuzzyScore(query: lowercaseQuery, in: lowercaseLine)
                
                let type = detectResultType(line: line)
                let context = extractContext(lines: lines, at: lineIndex)
                
                let result = InstantFuzzySearch.SearchResult(
                    content: line,
                    location: nsRange,
                    context: context,
                    score: score,
                    lineNumber: lineIndex + 1,
                    type: type
                )
                
                results.append(result)
            }
        }
        
        results.sort { $0.score > $1.score }
        return Array(results.prefix(100))
    }
    
    private func calculateFuzzyScore(query: String, in text: String) -> Double {
        var score = 0.0
        
        if text.hasPrefix(query) {
            score += 10
        }
        
        let words = text.components(separatedBy: .whitespaces)
        for word in words {
            if word.lowercased().hasPrefix(query) {
                score += 5
            }
        }
        
        let distance = levenshteinDistance(query, text)
        score += max(0, 10 - Double(distance))
        
        return score
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let len1 = s1.count
        let len2 = min(s2.count, 50)
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: len2 + 1), count: len1 + 1)
        
        for i in 0...len1 {
            matrix[i][0] = i
        }
        for j in 0...len2 {
            matrix[0][j] = j
        }
        
        for i in 1...len1 {
            for j in 1...len2 {
                let cost = s1[s1.index(s1.startIndex, offsetBy: i - 1)] ==
                          s2[s2.index(s2.startIndex, offsetBy: j - 1)] ? 0 : 1
                
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }
        
        return matrix[len1][len2]
    }
    
    private func detectResultType(line: String) -> InstantFuzzySearch.SearchResult.ResultType {
        if line.hasPrefix("#") {
            return .heading
        } else if line.hasPrefix("```") || line.hasPrefix("    ") {
            return .code
        } else if line.contains("](") || line.contains("[[") {
            return .link
        } else if line.hasPrefix("-") || line.hasPrefix("*") || line.hasPrefix("1.") {
            return .list
        } else {
            return .paragraph
        }
    }
    
    private func extractContext(lines: [String], at index: Int) -> String {
        var context = ""
        
        if index > 0 {
            context += "..." + lines[index - 1].suffix(30) + " "
        }
        
        context += lines[index]
        
        if index < lines.count - 1 {
            context += " " + lines[index + 1].prefix(30) + "..."
        }
        
        return context
    }
}

protocol InstantFuzzySearchDelegate: AnyObject {
    func instantFuzzySearch(_ search: InstantFuzzySearch, didSelectResult result: InstantFuzzySearch.SearchResult)
    func instantFuzzySearchDidClear(_ search: InstantFuzzySearch)
}