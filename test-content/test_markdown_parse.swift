import Foundation
import Markdown

let testMarkdown = """
# Test

This is ~~strikethrough~~ text.

This is **bold** and *italic* text.
"""

// Test default parsing
let doc1 = Document(parsing: testMarkdown)
print("Default parsing:")
print("Document has \(doc1.childCount) children")

func printNode(_ node: any Markup, indent: Int = 0) {
    let spacing = String(repeating: "  ", count: indent)
    print("\(spacing)\(type(of: node))")
    for child in node.children {
        printNode(child, indent: indent + 1)
    }
}

printNode(doc1)

// Test with ParseOptions
struct TestOptions: OptionSet {
    let rawValue: Int
    static let parseBlockDirectives = TestOptions(rawValue: 1 << 0)
}

let doc2 = Document(parsing: testMarkdown, source: nil, options: [])
print("\nWith empty options:")
print("Document has \(doc2.childCount) children")
printNode(doc2)