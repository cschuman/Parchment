import Cocoa

/// Custom NSTextView for markdown display with enhanced keyboard handling
public class MarkdownTextView: NSTextView {
    
    override public func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Handle Cmd+C for copying with proper plain text support
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "c":
                let selectedRange = self.selectedRange()
                if selectedRange.length > 0 {
                    let selectedText = self.attributedString().attributedSubstring(from: selectedRange)
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.writeObjects([selectedText.string as NSString])
                    return true
                }
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}