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

    func findBarDidSearch(_ searchText: String, completion: @escaping (Int) -> Void) {
        guard let textView = markdownViewController?.textView,
              let textStorage = textView.textStorage else {
            completion(0)
            return
        }

        clearHighlights()
        findMatches.removeAll()

        let text = textStorage.string as NSString
        var searchStart = 0

        while searchStart < text.length {
            let range = text.range(of: searchText,
                                  options: [.caseInsensitive],
                                  range: NSRange(location: searchStart, length: text.length - searchStart))

            if range.location != NSNotFound {
                findMatches.append(range)

                textStorage.addAttribute(.backgroundColor,
                                        value: NSColor.systemYellow.withAlphaComponent(0.3),
                                        range: range)

                searchStart = range.location + range.length
            } else {
                break
            }
        }

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

    // MARK: - Private

    private func clearHighlights() {
        guard let textStorage = markdownViewController?.textView.textStorage else { return }

        for range in findMatches {
            textStorage.removeAttribute(.backgroundColor, range: range)
        }
    }
}
