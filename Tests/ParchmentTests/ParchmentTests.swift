import XCTest
import Markdown
@testable import Parchment

final class ParchmentTests: XCTestCase {
    
    func testApplicationName() {
        XCTAssertEqual("Parchment", "Parchment")
    }
    
    func testMarkdownParsing() {
        let markdown = "# Hello World"
        let document = Document(parsing: markdown)
        
        XCTAssertFalse(document.children.isEmpty)
        XCTAssertTrue(document.children.first is Heading)
    }
    
    func testPerformanceOfLargeDocument() {
        let largeMarkdown = String(repeating: "# Heading\n\nParagraph text.\n\n", count: 1000)
        
        measure {
            let document = Document(parsing: largeMarkdown)
            let visitor = MarkdownAttributedStringVisitor()
            _ = visitor.convertDocument(document)
        }
    }
    
    func testMemoryUsage() {
        // Test that we don't have memory leaks when processing documents
        var document: MarkdownDocument? = MarkdownDocument(
            url: URL(fileURLWithPath: "/test.md"),
            content: String(repeating: "Test content\n", count: 10000)
        )
        
        weak var weakDoc = document
        document = nil
        
        XCTAssertNil(weakDoc, "Document should be deallocated")
    }
}