import Cocoa

/// Coordinates find bar functionality, handling search, highlighting, and navigation
final class FindBarCoordinator: NSObject, FindBarDelegate {

    private weak var findBarView: FindBarView?
    private weak var markdownViewController: MarkdownViewController?
    private var findMatches: [NSRange] = []

    init(findBarView: FindBarView?, markdownViewController: MarkdownViewController?) {
        self.findBarView = findBarView
        self.markdownViewController = markdownViewController
        super.init()

        findBarView?.delegate = self
    }

    // MARK: - Public Methods

    func showFindBar() {
        findBarView?.isHidden = false
        findBarView?.focusAndSelectAll()
    }

    func hideFindBar() {
        clearHighlights()
        findMatches.removeAll()
        findBarView?.isHidden = true
        markdownViewController?.textView.window?.makeFirstResponder(markdownViewController?.textView)
    }

    func findNext() {
        guard findBarView?.isHidden == false else { return }
        findBarView?.findNext()
    }

    func findPrevious() {
        guard findBarView?.isHidden == false else { return }
        findBarView?.findPrevious()
    }

    var isFindBarVisible: Bool {
        findBarView?.isHidden == false
    }

    // MARK: - FindBarDelegate

    func findBarDidSearch(_ searchText: String, options: FindOptions, completion: @escaping (Int) -> Void) {
        guard let textView = markdownViewController?.textView,
              let textStorage = textView.textStorage else {
            completion(0)
            return
        }

        clearHighlights()
        findMatches.removeAll()

        let text = textStorage.string as NSString

        // Get ranges to search based on options
        let searchRanges = options.headersOnly ?
            getHeaderRanges(in: text as String) :
            [NSRange(location: 0, length: text.length)]

        // Perform search based on options
        if options.useRegex {
            findWithRegex(searchText, in: text, ranges: searchRanges, caseSensitive: options.caseSensitive)
        } else {
            findWithString(searchText, in: text, ranges: searchRanges, caseSensitive: options.caseSensitive)
        }

        // Apply highlighting
        applyHighlighting(to: textStorage)

        completion(findMatches.count)
    }

    func findBarHighlightMatch(at index: Int) {
        guard index < findMatches.count,
              let textView = markdownViewController?.textView,
              let textStorage = textView.textStorage else { return }

        for (i, range) in findMatches.enumerated() {
            let color = i == index ?
                NSColor.systemOrange.withAlphaComponent(0.5) :
                NSColor.systemYellow.withAlphaComponent(0.3)
            textStorage.addAttribute(.backgroundColor, value: color, range: range)
        }

        textView.scrollRangeToVisible(findMatches[index])
    }

    func findBarClearHighlights() {
        clearHighlights()
    }

    func findBarDidClose() {
        hideFindBar()
    }

    // MARK: - Private - Search Methods

    private func findWithString(_ searchText: String, in text: NSString, ranges: [NSRange], caseSensitive: Bool) {
        let searchOptions: NSString.CompareOptions = caseSensitive ? [] : [.caseInsensitive]

        for searchRange in ranges {
            var searchStart = searchRange.location
            let searchEnd = searchRange.location + searchRange.length

            while searchStart < searchEnd {
                let remainingLength = searchEnd - searchStart
                let range = text.range(of: searchText,
                                       options: searchOptions,
                                       range: NSRange(location: searchStart, length: remainingLength))

                if range.location != NSNotFound && range.location + range.length <= searchEnd {
                    findMatches.append(range)
                    searchStart = range.location + range.length
                } else {
                    break
                }
            }
        }
    }

    private func findWithRegex(_ pattern: String, in text: NSString, ranges: [NSRange], caseSensitive: Bool) {
        do {
            var regexOptions: NSRegularExpression.Options = []
            if !caseSensitive {
                regexOptions.insert(.caseInsensitive)
            }

            let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)

            for searchRange in ranges {
                let matches = regex.matches(in: text as String, range: searchRange)
                for match in matches {
                    findMatches.append(match.range)
                }
            }
        } catch {
            // Invalid regex - return no matches
            findMatches.removeAll()
        }
    }

    // MARK: - Private - Header Detection

    private func getHeaderRanges(in text: String) -> [NSRange] {
        var headerRanges: [NSRange] = []
        let lines = text.components(separatedBy: .newlines)
        var currentPosition = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check if this line is a header (starts with #)
            if trimmed.hasPrefix("#") {
                let level = trimmed.prefix(while: { $0 == "#" }).count
                if level <= 6 {
                    // This is a valid header line
                    let lineRange = NSRange(location: currentPosition, length: line.count)
                    headerRanges.append(lineRange)
                }
            }

            // Move to next line (add 1 for newline character)
            currentPosition += line.count + 1
        }

        return headerRanges
    }

    // MARK: - Private - Highlighting

    private func applyHighlighting(to textStorage: NSTextStorage) {
        for range in findMatches {
            textStorage.addAttribute(.backgroundColor,
                                    value: NSColor.systemYellow.withAlphaComponent(0.3),
                                    range: range)
        }
    }

    private func clearHighlights() {
        guard let textStorage = markdownViewController?.textView.textStorage else { return }

        for range in findMatches {
            textStorage.removeAttribute(.backgroundColor, range: range)
        }
    }
}
