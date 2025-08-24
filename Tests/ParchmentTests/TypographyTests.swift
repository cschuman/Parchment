import XCTest
import Markdown
@testable import Parchment

final class TypographyTests: XCTestCase {
    
    func testTypographyEngineInitialization() {
        let engine = TypographyEngine()
        XCTAssertNotNil(engine)
    }
    
    func testGoldenRatioHeadingScales() {
        let engine = TypographyEngine()
        
        // Test heading scales follow golden ratio
        let h1Attrs = engine.headingAttributes(level: 1)
        let h2Attrs = engine.headingAttributes(level: 2)
        let h3Attrs = engine.headingAttributes(level: 3)
        
        // Check fonts exist
        XCTAssertNotNil(h1Attrs[.font])
        XCTAssertNotNil(h2Attrs[.font])
        XCTAssertNotNil(h3Attrs[.font])
        
        // Check font sizes follow golden ratio (approximately)
        if let h1Font = h1Attrs[.font] as? NSFont,
           let h2Font = h2Attrs[.font] as? NSFont {
            let ratio = h1Font.pointSize / h2Font.pointSize
            XCTAssertTrue(ratio > 1.1 && ratio < 1.3, "Heading ratio should be close to golden ratio")
        }
    }
    
    func testBodyAttributes() {
        let engine = TypographyEngine()
        let attrs = engine.bodyAttributes()
        
        XCTAssertNotNil(attrs[.font])
        XCTAssertNotNil(attrs[.paragraphStyle])
        
        if let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle {
            XCTAssertEqual(paragraphStyle.lineHeightMultiple, 1.6, accuracy: 0.1)
        }
    }
    
    func testCodeBlockAttributes() {
        let engine = TypographyEngine()
        let attrs = engine.codeBlockAttributes()
        
        XCTAssertNotNil(attrs[.font])
        XCTAssertNotNil(attrs[.backgroundColor])
        
        if let font = attrs[.font] as? NSFont {
            XCTAssertTrue(font.fontName.contains("Mono") || font.fontName.contains("mono"))
        }
    }
    
    func testThemeCreation() {
        let themes = ParchmentTheme.all
        XCTAssertEqual(themes.count, 5)
        
        // Test each theme has required properties
        for theme in themes {
            XCTAssertFalse(theme.name.isEmpty)
            XCTAssertNotNil(theme.backgroundColor)
            XCTAssertNotNil(theme.textColor)
            XCTAssertGreaterThan(theme.baseFontSize, 0)
            XCTAssertGreaterThan(theme.lineHeightMultiple, 0)
        }
    }
    
    func testEnhancedMarkdownRenderer() {
        let renderer = EnhancedMarkdownRenderer(theme: .minimal)
        let markdown = "# Test\n\nThis is a **bold** test with *italics*."
        let document = Document(parsing: markdown)
        
        let result = renderer.render(document)
        XCTAssertGreaterThan(result.length, 0)
        
        // Check that attributes are applied
        var hasFont = false
        result.enumerateAttribute(.font, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if value != nil {
                hasFont = true
            }
        }
        XCTAssertTrue(hasFont, "Rendered text should have font attributes")
    }
    
    func testSmartTypography() {
        let renderer = EnhancedMarkdownRenderer()
        let markdown = "\"Hello\" -- it's amazing..."
        let document = Document(parsing: markdown)
        
        let result = renderer.render(document)
        let text = result.string
        
        // Check smart quotes (using unicode values)
        XCTAssertTrue(text.contains("\u{201C}") || text.contains("\u{201D}"), "Should have smart quotes")
        XCTAssertTrue(text.contains("—"), "Should have em dash")
        XCTAssertTrue(text.contains("…"), "Should have ellipsis")
    }
    
    func testSmoothScrollManager() {
        let scrollView = NSScrollView()
        scrollView.enableSmoothScrolling()
        
        XCTAssertNotNil(scrollView.smoothScrollManager)
    }
    
    func testFastFileOpener() {
        let opener = FastFileOpener.shared
        
        // Test with a small markdown string
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test.md")
        let testContent = "# Test\n\nQuick test"
        
        do {
            try testContent.write(to: tempURL, atomically: true, encoding: .utf8)
            
            let expectation = self.expectation(description: "File opened")
            
            opener.openFile(at: tempURL) { result in
                switch result {
                case .success(let document):
                    XCTAssertGreaterThan(document.attributedString.length, 0)
                    XCTAssertNotNil(document.metadata)
                case .failure(let error):
                    XCTFail("Failed to open file: \(error)")
                }
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 5)
            
            // Cleanup
            try? FileManager.default.removeItem(at: tempURL)
            
        } catch {
            XCTFail("Failed to create test file: \(error)")
        }
    }
    
    func testPerformanceOfRendering() {
        let renderer = EnhancedMarkdownRenderer()
        let largeMarkdown = String(repeating: "# Heading\n\nParagraph text. ", count: 1000)
        let document = Document(parsing: largeMarkdown)
        
        measure {
            _ = renderer.render(document)
        }
    }
}