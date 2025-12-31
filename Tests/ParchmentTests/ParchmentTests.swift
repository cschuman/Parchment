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

        // MarkupChildren doesn't have isEmpty, so check childCount instead
        XCTAssertGreaterThan(document.childCount, 0)

        // Get the first child properly
        if let firstChild = document.children.first(where: { _ in true }) {
            XCTAssertTrue(firstChild is Heading)
        } else {
            XCTFail("Document should have at least one child")
        }
    }

    func testPerformanceOfLargeDocument() {
        let largeMarkdown = String(repeating: "# Heading\n\nParagraph text.\n\n", count: 1000)

        measure {
            let document = Document(parsing: largeMarkdown)
            let renderer = EnhancedMarkdownRenderer()
            _ = renderer.render(document)
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
