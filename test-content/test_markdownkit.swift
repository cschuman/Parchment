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

print("\nParsed document type: \(doc)")

// Generate HTML to see what's happening
let htmlGen = HtmlGenerator()
let html = htmlGen.generate(doc: doc)
print("\nGenerated HTML:")
print(html)

// Try AttributedStringGenerator
let generator = AttributedStringGenerator(
    fontSize: 14,
    fontFamily: "Helvetica Neue"
)

if let attrString = generator.generate(doc: doc) {
    print("\nAttributedString generated successfully")
    print("String content: \(attrString.string)")
} else {
    print("\nFailed to generate AttributedString")
}