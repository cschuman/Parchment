import XCTest
@testable import Parchment

final class MarkdownDocumentTests: XCTestCase {
    
    func testDocumentCreation() {
        let url = URL(fileURLWithPath: "/test/document.md")
        let content = "# Test Document\n\nThis is test content."
        
        let document = MarkdownDocument(url: url, content: content)
        
        XCTAssertEqual(document.url, url)
        XCTAssertEqual(document.content, content)
        XCTAssertNotNil(document.id)
        XCTAssertNotNil(document.createdAt)
    }
    
    func testDocumentURL() {
        let url1 = URL(fileURLWithPath: "/path/to/MyDocument.md")
        let doc1 = MarkdownDocument(url: url1, content: "")
        XCTAssertEqual(doc1.url?.lastPathComponent, "MyDocument.md")
        
        let url2 = URL(fileURLWithPath: "/path/to/README.md")
        let doc2 = MarkdownDocument(url: url2, content: "")
        XCTAssertEqual(doc2.url?.lastPathComponent, "README.md")
    }
    
    func testWordCount() {
        let url = URL(fileURLWithPath: "/test.md")
        let content = "This is a test document with several words in it."
        
        let document = MarkdownDocument(url: url, content: content)
        
        // Should count 10 words
        let wordCount = content.split(separator: " ").count
        XCTAssertEqual(wordCount, 10)
    }
    
    func testLineCount() {
        let url = URL(fileURLWithPath: "/test.md")
        let content = """
        Line 1
        Line 2
        Line 3
        Line 4
        """
        
        let document = MarkdownDocument(url: url, content: content)
        
        let lineCount = content.components(separatedBy: .newlines).count
        XCTAssertEqual(lineCount, 4)
    }
    
    func testEmptyDocument() {
        let url = URL(fileURLWithPath: "/empty.md")
        let content = ""
        
        let document = MarkdownDocument(url: url, content: content)
        
        XCTAssertEqual(document.content, "")
        XCTAssertEqual(document.url?.lastPathComponent, "empty.md")
    }
    
    func testLargeDocument() {
        let url = URL(fileURLWithPath: "/large.md")
        let content = String(repeating: "This is a line of text.\n", count: 10000)
        
        let document = MarkdownDocument(url: url, content: content)
        
        XCTAssertEqual(document.content.count, content.count)
        XCTAssertTrue(document.content.count > 100000) // Should be large
    }
    
    func testDocumentWithSpecialCharacters() {
        let url = URL(fileURLWithPath: "/special-chars.md")
        let content = "# Title with émojis 🎉\n\n**Bold** and *italic* with special chars: &<>\"'"
        
        let document = MarkdownDocument(url: url, content: content)
        
        XCTAssertEqual(document.content, content)
        XCTAssertTrue(document.content.contains("🎉"))
        XCTAssertTrue(document.content.contains("&<>"))
    }
    
    func testDocumentEquality() {
        let url1 = URL(fileURLWithPath: "/doc1.md")
        let url2 = URL(fileURLWithPath: "/doc2.md")
        let content = "Same content"
        
        let doc1 = MarkdownDocument(url: url1, content: content)
        let doc2 = MarkdownDocument(url: url1, content: content) // Same URL
        let doc3 = MarkdownDocument(url: url2, content: content) // Different URL
        
        // Documents with same URL should be considered equal
        XCTAssertEqual(doc1.url, doc2.url)
        XCTAssertNotEqual(doc1.url, doc3.url)
    }
}