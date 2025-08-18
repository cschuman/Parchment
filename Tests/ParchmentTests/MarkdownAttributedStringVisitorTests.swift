import XCTest
import Markdown
@testable import Parchment

final class MarkdownAttributedStringVisitorTests: XCTestCase {
    
    func testBasicParagraph() {
        let markdown = "This is a simple paragraph."
        let document = Document(parsing: markdown)
        let visitor = MarkdownAttributedStringVisitor()
        
        let result = visitor.convertDocument(document)
        
        XCTAssertEqual(result.string, "This is a simple paragraph.\n\n")
    }
    
    func testHeadings() {
        let markdown = """
        # Heading 1
        ## Heading 2
        ### Heading 3
        """
        
        let document = Document(parsing: markdown)
        let visitor = MarkdownAttributedStringVisitor()
        
        let result = visitor.convertDocument(document)
        
        XCTAssertTrue(result.string.contains("Heading 1"))
        XCTAssertTrue(result.string.contains("Heading 2"))
        XCTAssertTrue(result.string.contains("Heading 3"))
        
        // Check font sizes are different
        var foundDifferentFonts = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length), options: []) { value, range, _ in
            if let font = value as? NSFont {
                if font.pointSize == 28 || font.pointSize == 24 || font.pointSize == 20 {
                    foundDifferentFonts = true
                }
            }
        }
        XCTAssertTrue(foundDifferentFonts)
    }
    
    func testBoldAndItalic() {
        let markdown = "This is **bold** and this is *italic*."
        let document = Document(parsing: markdown)
        let visitor = MarkdownAttributedStringVisitor()
        
        let result = visitor.convertDocument(document)
        
        XCTAssertEqual(result.string, "This is bold and this is italic.\n\n")
        
        // Check for bold font
        let boldRange = (result.string as NSString).range(of: "bold")
        var foundBold = false
        result.enumerateAttribute(.font, in: boldRange, options: []) { value, _, _ in
            if let font = value as? NSFont {
                foundBold = font.fontDescriptor.symbolicTraits.contains(.bold)
            }
        }
        XCTAssertTrue(foundBold)
        
        // Check for italic font
        let italicRange = (result.string as NSString).range(of: "italic")
        var foundItalic = false
        result.enumerateAttribute(.font, in: italicRange, options: []) { value, _, _ in
            if let font = value as? NSFont {
                foundItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
            }
        }
        XCTAssertTrue(foundItalic)
    }
    
    func testStrikethrough() {
        let markdown = "This is ~~strikethrough~~ text."
        let document = Document(parsing: markdown)
        let visitor = MarkdownAttributedStringVisitor()
        
        let result = visitor.convertDocument(document)
        
        // Check for strikethrough attribute
        let strikeRange = (result.string as NSString).range(of: "strikethrough")
        var foundStrike = false
        result.enumerateAttribute(.strikethroughStyle, in: strikeRange, options: []) { value, _, _ in
            if value != nil {
                foundStrike = true
            }
        }
        XCTAssertTrue(foundStrike)
    }
    
    func testInlineCode() {
        let markdown = "This is `inline code` in text."
        let document = Document(parsing: markdown)
        let visitor = MarkdownAttributedStringVisitor()
        
        let result = visitor.convertDocument(document)
        
        XCTAssertTrue(result.string.contains("inline code"))
        
        // Check for monospaced font
        let codeRange = (result.string as NSString).range(of: "inline code")
        var foundMonospace = false
        result.enumerateAttribute(.font, in: codeRange, options: []) { value, _, _ in
            if let font = value as? NSFont {
                foundMonospace = font.fontName.lowercased().contains("mono") || 
                               font.fontName.contains("Menlo") || 
                               font.fontName.contains("Monaco")
            }
        }
        XCTAssertTrue(foundMonospace)
    }
    
    func testCodeBlock() {
        let markdown = """
        ```
        func hello() {
            print("world")
        }
        ```
        """
        
        let document = Document(parsing: markdown)
        let visitor = MarkdownAttributedStringVisitor()
        
        let result = visitor.convertDocument(document)
        
        XCTAssertTrue(result.string.contains("func hello()"))
        XCTAssertTrue(result.string.contains("print(\"world\")"))
    }
    
    func testUnorderedList() {
        let markdown = """
        - Item 1
        - Item 2
        - Item 3
        """
        
        let document = Document(parsing: markdown)
        let visitor = MarkdownAttributedStringVisitor()
        
        let result = visitor.convertDocument(document)
        
        XCTAssertTrue(result.string.contains("• Item 1"))
        XCTAssertTrue(result.string.contains("• Item 2"))
        XCTAssertTrue(result.string.contains("• Item 3"))
    }
    
    func testOrderedList() {
        let markdown = """
        1. First
        2. Second
        3. Third
        """
        
        let document = Document(parsing: markdown)
        let visitor = MarkdownAttributedStringVisitor()
        
        let result = visitor.convertDocument(document)
        
        XCTAssertTrue(result.string.contains("1. First"))
        XCTAssertTrue(result.string.contains("2. Second"))
        XCTAssertTrue(result.string.contains("3. Third"))
    }
    
    func testLink() {
        let markdown = "This is a [link](https://example.com)."
        let document = Document(parsing: markdown)
        let visitor = MarkdownAttributedStringVisitor()
        
        let result = visitor.convertDocument(document)
        
        XCTAssertTrue(result.string.contains("link"))
        
        // Check for link attribute
        let linkRange = (result.string as NSString).range(of: "link")
        var foundLink = false
        result.enumerateAttribute(.link, in: linkRange, options: []) { value, _, _ in
            if let url = value as? URL {
                foundLink = url.absoluteString == "https://example.com"
            }
        }
        XCTAssertTrue(foundLink)
    }
    
    func testZoomLevel() {
        let markdown = "# Test Heading"
        let document = Document(parsing: markdown)
        
        let visitor1 = MarkdownAttributedStringVisitor(zoomLevel: 1.0)
        let result1 = visitor1.convertDocument(document)
        
        let visitor2 = MarkdownAttributedStringVisitor(zoomLevel: 2.0)
        let result2 = visitor2.convertDocument(document)
        
        // Get font sizes
        var fontSize1: CGFloat = 0
        var fontSize2: CGFloat = 0
        
        result1.enumerateAttribute(.font, in: NSRange(location: 0, length: 4), options: []) { value, _, _ in
            if let font = value as? NSFont {
                fontSize1 = font.pointSize
            }
        }
        
        result2.enumerateAttribute(.font, in: NSRange(location: 0, length: 4), options: []) { value, _, _ in
            if let font = value as? NSFont {
                fontSize2 = font.pointSize
            }
        }
        
        XCTAssertEqual(fontSize2, fontSize1 * 2)
    }
}