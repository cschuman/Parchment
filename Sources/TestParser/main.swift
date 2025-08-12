import Foundation
import Markdown

let testMarkdown = """
# Test

This is ~~strikethrough~~ text.

This is **bold** and *italic* text.

- List item 1
  - Nested item 1.1
  - Nested item 1.2
"""

// Test default parsing
let doc = Document(parsing: testMarkdown)
print("Document has \(doc.childCount) children")

func printNode(_ node: any Markup, indent: Int = 0) {
    let spacing = String(repeating: "  ", count: indent)
    let nodeType = String(describing: type(of: node))
    
    if let text = node as? Text {
        print("\(spacing)\(nodeType): '\(text.string)'")
    } else {
        print("\(spacing)\(nodeType)")
    }
    
    for child in node.children {
        printNode(child, indent: indent + 1)
    }
}

printNode(doc)