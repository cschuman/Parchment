import Foundation
import Markdown

let tableMarkdown = """
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
| Row 2 A  | Row 2 B  | Row 2 C  |
"""

let document = Document(parsing: tableMarkdown)

print("Document has \(document.children.count) children")

for (index, child) in document.children.enumerated() {
    print("Child \(index): \(type(of: child))")
    
    if let table = child as? Table {
        print("  Table found!")
        print("  Header rows: \(table.head.childCount)")
        print("  Body rows: \(table.body.childCount)")
        
        // Print alignments
        print("  Alignments: \(table.columnAlignments)")
    }
    
    if let paragraph = child as? Paragraph {
        print("  Paragraph: '\(paragraph.plainText)'")
    }
}

// Try with GFM-style table
print("\n--- Testing GFM table ---")
let gfmTable = """
| Left | Center | Right |
|:-----|:------:|------:|
| L1   | C1     | R1    |
| L2   | C2     | R2    |
"""

let gfmDoc = Document(parsing: gfmTable)
print("GFM Document has \(gfmDoc.children.count) children")

for (index, child) in gfmDoc.children.enumerated() {
    print("Child \(index): \(type(of: child))")
}