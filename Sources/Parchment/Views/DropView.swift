import Cocoa

class DropView: NSView {
    weak var dropDelegate: DropViewDelegate?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        Logger.info("DropView: draggingEntered")
        let pasteboard = sender.draggingPasteboard
        
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls {
                if isValidMarkdownFile(url) {
                    self.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.1).cgColor
                    return .copy
                }
            }
        }
        return []
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        Logger.info("DropView: draggingExited")
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        Logger.info("DropView: performDragOperation")
        self.layer?.backgroundColor = NSColor.clear.cgColor
        
        let pasteboard = sender.draggingPasteboard
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls {
                if isValidMarkdownFile(url) {
                    dropDelegate?.dropView(self, didReceiveFileURL: url)
                    return true
                }
            }
        }
        return false
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    private func isValidMarkdownFile(_ url: URL) -> Bool {
        let validExtensions = ["md", "markdown", "mdown", "mkd", "mkdown", "mdwn", "mdtxt", "mdtext", "text", "txt"]
        return validExtensions.contains(url.pathExtension.lowercased())
    }
}

protocol DropViewDelegate: AnyObject {
    func dropView(_ dropView: DropView, didReceiveFileURL url: URL)
}