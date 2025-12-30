import Cocoa

final class FindBarView: NSView {
    private var searchField: NSSearchField!
    private var resultsLabel: NSTextField!
    private var nextButton: NSButton!
    private var previousButton: NSButton!
    private var closeButton: NSButton!
    
    weak var delegate: FindBarDelegate?
    
    private var currentMatch = 0
    private var totalMatches = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Search field
        searchField = NSSearchField()
        searchField.placeholderString = "Find"
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.target = self
        searchField.action = #selector(searchFieldChanged(_:))
        searchField.delegate = self
        searchField.setAccessibilityLabel("Search in document")
        searchField.setAccessibilityIdentifier("findBarSearchField")

        // Results label
        resultsLabel = NSTextField(labelWithString: "")
        resultsLabel.font = NSFont.systemFont(ofSize: 11)
        resultsLabel.textColor = NSColor.secondaryLabelColor
        resultsLabel.translatesAutoresizingMaskIntoConstraints = false
        resultsLabel.setAccessibilityElement(true)
        resultsLabel.setAccessibilityRole(.staticText)
        resultsLabel.setAccessibilityLabel("Search results count")
        
        // Navigation buttons
        previousButton = NSButton(image: NSImage(systemSymbolName: "chevron.up", accessibilityDescription: "Previous")!, target: self, action: #selector(findPrevious))
        previousButton.isBordered = false
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        previousButton.isEnabled = false
        
        nextButton = NSButton(image: NSImage(systemSymbolName: "chevron.down", accessibilityDescription: "Next")!, target: self, action: #selector(findNext))
        nextButton.isBordered = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.isEnabled = false
        
        // Close button
        closeButton = NSButton(image: NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")!, target: self, action: #selector(close))
        closeButton.isBordered = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all subviews
        addSubview(searchField)
        addSubview(resultsLabel)
        addSubview(previousButton)
        addSubview(nextButton)
        addSubview(closeButton)
        
        // Layout
        NSLayoutConstraint.activate([
            searchField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            searchField.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchField.widthAnchor.constraint(equalToConstant: 200),
            
            resultsLabel.leadingAnchor.constraint(equalTo: searchField.trailingAnchor, constant: 10),
            resultsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            previousButton.leadingAnchor.constraint(equalTo: resultsLabel.trailingAnchor, constant: 10),
            previousButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            nextButton.leadingAnchor.constraint(equalTo: previousButton.trailingAnchor, constant: 5),
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func searchFieldChanged(_ sender: NSSearchField) {
        let searchText = sender.stringValue
        if searchText.isEmpty {
            clearSearch()
        } else {
            performSearch(searchText)
        }
    }
    
    private func performSearch(_ searchText: String) {
        delegate?.findBarDidSearch(searchText) { [weak self] matches in
            self?.totalMatches = matches
            self?.currentMatch = matches > 0 ? 1 : 0
            self?.updateUI()
            
            if matches > 0 {
                self?.delegate?.findBarHighlightMatch(at: 0)
            }
        }
    }
    
    @objc func findNext() {
        guard totalMatches > 0 else { return }
        currentMatch = (currentMatch % totalMatches) + 1
        delegate?.findBarHighlightMatch(at: currentMatch - 1)
        updateUI()
    }
    
    @objc func findPrevious() {
        guard totalMatches > 0 else { return }
        currentMatch = currentMatch > 1 ? currentMatch - 1 : totalMatches
        delegate?.findBarHighlightMatch(at: currentMatch - 1)
        updateUI()
    }
    
    @objc private func close() {
        clearSearch()
        delegate?.findBarDidClose()
    }
    
    private func clearSearch() {
        currentMatch = 0
        totalMatches = 0
        updateUI()
        delegate?.findBarClearHighlights()
    }
    
    private func updateUI() {
        if totalMatches > 0 {
            resultsLabel.stringValue = "\(currentMatch) of \(totalMatches)"
            previousButton.isEnabled = true
            nextButton.isEnabled = true
        } else if !searchField.stringValue.isEmpty {
            resultsLabel.stringValue = "No results"
            previousButton.isEnabled = false
            nextButton.isEnabled = false
        } else {
            resultsLabel.stringValue = ""
            previousButton.isEnabled = false
            nextButton.isEnabled = false
        }
    }
    
    func focus() {
        searchField.becomeFirstResponder()
    }
    
    func focusAndSelectAll() {
        searchField.becomeFirstResponder()
        searchField.selectText(nil)
    }
}

extension FindBarView: NSSearchFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(cancelOperation(_:)) {
            close()
            return true
        } else if commandSelector == #selector(insertNewline(_:)) {
            if NSEvent.modifierFlags.contains(.shift) {
                findPrevious()
            } else {
                findNext()
            }
            return true
        }
        return false
    }
}

protocol FindBarDelegate: AnyObject {
    func findBarDidSearch(_ searchText: String, completion: @escaping (Int) -> Void)
    func findBarHighlightMatch(at index: Int)
    func findBarClearHighlights()
    func findBarDidClose()
}