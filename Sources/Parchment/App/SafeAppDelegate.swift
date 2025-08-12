import Cocoa
import Foundation

class SafeAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    var textView: NSTextView?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        fputs("SafeAppDelegate: Starting safe mode\n", stderr)
        
        // Create window without any Touch Bar or advanced features
        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window?.title = "Parchment (Safe Mode)"
        window?.center()
        
        // Create scroll view and text view
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        
        textView = NSTextView()
        textView?.isEditable = false
        textView?.isRichText = true
        textView?.importsGraphics = false
        textView?.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        
        scrollView.documentView = textView
        window?.contentView = scrollView
        
        // Load file if provided as argument
        if ProcessInfo.processInfo.arguments.count > 1 {
            let path = ProcessInfo.processInfo.arguments[1]
            loadFile(at: path)
        } else {
            textView?.string = "# Parchment Safe Mode\n\nNo file specified.\n\nUsage: ./parchment <file.md>"
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func loadFile(at path: String) {
        let absolutePath: String
        if path.hasPrefix("/") {
            absolutePath = path
        } else {
            absolutePath = FileManager.default.currentDirectoryPath + "/" + path
        }
        
        fputs("SafeAppDelegate: Loading file: \(absolutePath)\n", stderr)
        
        do {
            let content = try String(contentsOfFile: absolutePath, encoding: .utf8)
            
            // Simple markdown rendering without parser to avoid crash
            let attributed = NSMutableAttributedString(string: content)
            
            // Basic styling
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            
            attributed.addAttributes([
                .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
                .paragraphStyle: paragraphStyle
            ], range: NSRange(location: 0, length: attributed.length))
            
            // Simple header detection (without parser)
            let lines = content.components(separatedBy: .newlines)
            var location = 0
            
            for line in lines {
                if line.hasPrefix("# ") {
                    attributed.addAttribute(.font, value: NSFont.systemFont(ofSize: 24, weight: .bold), 
                                           range: NSRange(location: location, length: line.count))
                } else if line.hasPrefix("## ") {
                    attributed.addAttribute(.font, value: NSFont.systemFont(ofSize: 20, weight: .semibold), 
                                           range: NSRange(location: location, length: line.count))
                } else if line.hasPrefix("### ") {
                    attributed.addAttribute(.font, value: NSFont.systemFont(ofSize: 18, weight: .medium), 
                                           range: NSRange(location: location, length: line.count))
                }
                location += line.count + 1 // +1 for newline
            }
            
            textView?.textStorage?.setAttributedString(attributed)
            window?.title = "Parchment (Safe Mode) - \(URL(fileURLWithPath: absolutePath).lastPathComponent)"
            
        } catch {
            textView?.string = "Error loading file: \(error.localizedDescription)"
            fputs("SafeAppDelegate: Error loading file: \(error)\n", stderr)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}