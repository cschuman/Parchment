import Cocoa

/// Manages typewriter-style scrolling behavior for text editing
final class TypewriterScrollManager: NSObject {
    
    // MARK: - Properties
    
    private weak var textView: NSTextView?
    private weak var scrollView: NSScrollView?
    private var isEnabled: Bool = false
    private var currentCursorLine: Int = 0
    
    // MARK: - Configuration
    
    private struct Configuration {
        static let animationDuration: TimeInterval = 0.15
        static let scrollCenterOffset: CGFloat = 0.5 // Center of visible area
    }
    
    // MARK: - Initialization
    
    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        self.scrollView = scrollView
        super.init()
    }
    
    deinit {
        disable()
    }
    
    // MARK: - Public Interface
    
    /// Enable typewriter scrolling mode
    func enable() {
        guard !isEnabled else { return }
        
        isEnabled = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidChangeSelection(_:)),
            name: NSTextView.didChangeSelectionNotification,
            object: textView
        )
        
        // Center current position immediately
        centerCurrentLine()
    }
    
    /// Disable typewriter scrolling mode
    func disable() {
        guard isEnabled else { return }
        
        isEnabled = false
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSTextView.didChangeSelectionNotification,
            object: textView
        )
    }
    
    /// Toggle typewriter scrolling mode
    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
    
    /// Check if typewriter mode is enabled
    var isTypewriterModeEnabled: Bool {
        return isEnabled
    }
    
    // MARK: - Private Methods
    
    @objc private func textViewDidChangeSelection(_ notification: Notification) {
        guard isEnabled else { return }
        centerCurrentLine()
    }
    
    /// Center the current line in the scroll view
    func centerCurrentLine() {
        guard let textView = textView,
              let scrollView = scrollView,
              let textStorage = textView.textStorage,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        let selectedRange = textView.selectedRange()
        guard selectedRange.location < textStorage.length else { return }
        
        // Get the glyph range for the current line
        let glyphRange = layoutManager.glyphRange(forCharacterRange: selectedRange, actualCharacterRange: nil)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphRange.location, effectiveRange: nil)
        
        // Calculate the target scroll position (center of visible area)
        let visibleHeight = scrollView.contentView.visibleRect.height
        let targetY = lineRect.midY - (visibleHeight * Configuration.scrollCenterOffset)
        
        // Smooth scroll to the target position
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Configuration.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            let targetPoint = NSPoint(x: 0, y: max(0, targetY))
            scrollView.contentView.animator().setBoundsOrigin(targetPoint)
        }
        
        // Update cursor line tracking
        updateCurrentCursorLine()
    }
    
    /// Update the current cursor line number
    private func updateCurrentCursorLine() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        let selectedRange = textView.selectedRange()
        guard selectedRange.location < textStorage.length else { return }
        
        let text = textStorage.string as NSString
        let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        
        // Count lines before current position
        let beforeText = text.substring(to: lineRange.location)
        currentCursorLine = beforeText.components(separatedBy: .newlines).count
    }
    
    /// Get the current cursor line number
    func getCurrentLine() -> Int {
        return currentCursorLine
    }
    
    /// Calculate the line number for a given character position
    func lineNumber(for characterIndex: Int) -> Int {
        guard let textStorage = textView?.textStorage else { return 0 }
        
        let text = textStorage.string as NSString
        guard characterIndex < text.length else { return 0 }
        
        let beforeText = text.substring(to: characterIndex)
        return beforeText.components(separatedBy: .newlines).count
    }
    
    /// Calculate total number of lines in the document
    func totalLines() -> Int {
        guard let textStorage = textView?.textStorage else { return 0 }
        
        let text = textStorage.string
        return text.components(separatedBy: .newlines).count
    }
}