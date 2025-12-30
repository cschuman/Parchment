import Cocoa

/// Coordinates navigation within a markdown document
final class NavigationCoordinator {
    
    // MARK: - Properties
    
    private weak var textView: NSTextView?
    private weak var scrollView: NSScrollView?
    private var headers: [MarkdownHeader] = []
    
    // MARK: - Configuration
    
    private struct Configuration {
        static let scrollAnimationDuration: TimeInterval = 0.3
        static let highlightDuration: TimeInterval = 1.0
        static let highlightColor = NSColor.systemYellow.withAlphaComponent(0.3)
    }
    
    // MARK: - Initialization
    
    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        self.scrollView = scrollView
    }
    
    // MARK: - Header Management
    
    /// Update the list of headers in the document
    func updateHeaders(_ headers: [MarkdownHeader]) {
        self.headers = headers
    }
    
    /// Navigate to the next header in the document
    func navigateToNextHeader() {
        guard let textView = textView,
              let textStorage = textView.textStorage,
              !headers.isEmpty else { return }
        
        let currentLocation = textView.selectedRange().location
        
        // Find next header after current position
        for header in headers {
            if let headerRange = findRange(of: header.title, in: textStorage.string),
               headerRange.location > currentLocation {
                scrollToLocation(headerRange.location)
                return
            }
        }
        
        // Wrap to first header if at end
        if let firstHeader = headers.first,
           let headerRange = findRange(of: firstHeader.title, in: textStorage.string) {
            scrollToLocation(headerRange.location)
        }
    }
    
    /// Navigate to the previous header in the document
    func navigateToPreviousHeader() {
        guard let textView = textView,
              let textStorage = textView.textStorage,
              !headers.isEmpty else { return }
        
        let currentLocation = textView.selectedRange().location
        
        // Find previous header before current position
        for header in headers.reversed() {
            if let headerRange = findRange(of: header.title, in: textStorage.string),
               headerRange.location < currentLocation {
                scrollToLocation(headerRange.location)
                return
            }
        }
        
        // Wrap to last header if at beginning
        if let lastHeader = headers.last,
           let headerRange = findRange(of: lastHeader.title, in: textStorage.string) {
            scrollToLocation(headerRange.location)
        }
    }
    
    /// Scroll to a specific header
    func scrollToHeader(_ header: MarkdownHeader) {
        guard let textStorage = textView?.textStorage else { return }
        
        if let headerRange = findRange(of: header.title, in: textStorage.string) {
            scrollToLocation(headerRange.location, highlight: true)
        }
    }
    
    /// Scroll to a specific location in the document
    func scrollToLocation(_ location: Int, highlight: Bool = false) {
        guard let textView = textView,
              let scrollView = scrollView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        // Ensure location is valid
        let safeLocation = min(location, (textView.textStorage?.length ?? 0) - 1)
        guard safeLocation >= 0 else { return }
        
        // Get the rect for the target location
        let glyphRange = layoutManager.glyphRange(
            forCharacterRange: NSRange(location: safeLocation, length: 1),
            actualCharacterRange: nil
        )
        let targetRect = layoutManager.boundingRect(
            forGlyphRange: glyphRange,
            in: textContainer
        )
        
        // Calculate scroll position to center the target
        let visibleHeight = scrollView.contentView.visibleRect.height
        let targetY = targetRect.midY - visibleHeight / 2
        
        // Animate scroll
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Configuration.scrollAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            let clampedY = max(0, min(targetY, textView.frame.height - visibleHeight))
            scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: clampedY))
        } completionHandler: {
            if highlight {
                self.highlightLocation(safeLocation)
            }
        }
        
        // Update selection
        textView.setSelectedRange(NSRange(location: safeLocation, length: 0))
    }
    
    // MARK: - Search
    
    /// Find the range of text in the document
    private func findRange(of searchText: String, in text: String) -> NSRange? {
        let nsText = text as NSString
        let searchRange = NSRange(location: 0, length: nsText.length)
        
        // Search for exact header text
        let range = nsText.range(of: searchText, options: [], range: searchRange)
        if range.location != NSNotFound {
            return range
        }
        
        // Try searching line by line for partial matches
        var foundRange: NSRange?
        nsText.enumerateSubstrings(in: searchRange, options: [.byLines]) { substring, range, _, stop in
            if let line = substring, line.contains(searchText) {
                foundRange = range
                stop.pointee = true
            }
        }
        
        return foundRange
    }
    
    // MARK: - Visual Feedback
    
    /// Highlight a location temporarily
    private func highlightLocation(_ location: Int) {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        // Find the line containing this location
        let text = textStorage.string as NSString
        let lineRange = text.lineRange(for: NSRange(location: location, length: 0))
        
        // Apply highlight
        textStorage.addAttribute(
            .backgroundColor,
            value: Configuration.highlightColor,
            range: lineRange
        )
        
        // Remove highlight after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Configuration.highlightDuration) {
            textStorage.removeAttribute(.backgroundColor, range: lineRange)
        }
    }
    
    // MARK: - Utility
    
    /// Get the current header based on scroll position
    func getCurrentHeader() -> MarkdownHeader? {
        guard let textView = textView,
              !headers.isEmpty else { return nil }
        
        let currentLocation = textView.selectedRange().location
        
        // Find the header at or before current position
        var currentHeader: MarkdownHeader?
        for header in headers {
            if let headerRange = findRange(of: header.title, in: textView.string),
               headerRange.location <= currentLocation {
                currentHeader = header
            } else {
                break
            }
        }
        
        return currentHeader
    }
}