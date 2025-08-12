import Foundation
import MarkdownKit

let tableMarkdown = """
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
| Row 2 A  | Row 2 B  | Row 2 C  |
"""

print("Testing MarkdownKit ExtendedMarkdownParser...")
let parser = ExtendedMarkdownParser.standard
let doc = parser.parse(tableMarkdown)

print("\nParsed document: \(doc)")

// Check if it's actually a table
switch doc {
case .document(let blocks):
    print("Document has \(blocks.count) blocks")
    for (index, block) in blocks.enumerated() {
        print("Block \(index): ", terminator: "")
        switch block {
        case .table(_, _, _):
            print("TABLE FOUND!")
        case .paragraph(_):
            print("Paragraph")
        default:
            print("Other: \(block)")
        }
    }
default:
    print("Not a document")
}

// Generate HTML
let htmlGen = HtmlGenerator()
let html = htmlGen.generate(doc: doc)
print("\nGenerated HTML:")
print(html)