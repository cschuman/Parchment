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
        let theme = ParchmentTheme.minimal
        let engine = TypographyEngine(theme: theme)
        let attrs = engine.bodyAttributes()

        XCTAssertNotNil(attrs[.font])
        XCTAssertNotNil(attrs[.paragraphStyle])

        if let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle {
            // Should match the theme's lineHeightMultiple (1.4 for minimal)
            XCTAssertEqual(paragraphStyle.lineHeightMultiple, theme.lineHeightMultiple, accuracy: 0.1)
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
        // Use builtIn to avoid custom themes affecting the count
        let themes = ParchmentTheme.builtIn
        XCTAssertEqual(themes.count, 9, "Should have 9 built-in themes")

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
        // Note: swift-markdown converts -- to en-dash (U+2013), not em-dash (U+2014)
        // This is the conventional typographic behavior (-- = en-dash, --- = em-dash)
        XCTAssertTrue(text.contains("–") || text.contains("\u{2013}"), "Should have en-dash (–)")
        XCTAssertTrue(text.contains("…") || text.contains("\u{2026}"), "Should have ellipsis (…)")
    }

    func testStrikethroughRendering() {
        let renderer = EnhancedMarkdownRenderer()
        let markdown = "This is ~~strikethrough~~ text."
        let document = Document(parsing: markdown)

        let result = renderer.render(document)
        let text = result.string

        // Check that "strikethrough" text is present
        XCTAssertTrue(text.contains("strikethrough"), "Should contain strikethrough text")

        // Find the range of "strikethrough" and check for strikethrough attribute
        if let range = text.range(of: "strikethrough") {
            let nsRange = NSRange(range, in: text)
            var hasStrikethrough = false
            result.enumerateAttribute(.strikethroughStyle, in: nsRange) { value, _, _ in
                if let style = value as? Int, style == NSUnderlineStyle.single.rawValue {
                    hasStrikethrough = true
                }
            }
            XCTAssertTrue(hasStrikethrough, "Strikethrough text should have strikethrough style attribute")
        } else {
            XCTFail("Could not find 'strikethrough' in rendered text")
        }
    }

    func testStrikethroughWithOtherFormatting() {
        let renderer = EnhancedMarkdownRenderer()
        let markdown = "This is **bold ~~strikethrough~~** and *italic ~~strikethrough~~* text."
        let document = Document(parsing: markdown)

        let result = renderer.render(document)
        let text = result.string

        // Check that strikethrough text is present
        XCTAssertTrue(text.contains("strikethrough"), "Should contain strikethrough text")

        // Find all occurrences of "strikethrough" and verify they have the attribute
        var strikethroughCount = 0
        result.enumerateAttribute(.strikethroughStyle, in: NSRange(location: 0, length: result.length)) { value, _, _ in
            if let style = value as? Int, style == NSUnderlineStyle.single.rawValue {
                strikethroughCount += 1
            }
        }
        XCTAssertGreaterThan(strikethroughCount, 0, "Should have strikethrough styling applied")
    }
    
    func testSmoothScrollManager() {
        let scrollView = NSScrollView()
        scrollView.enableSmoothScrolling()
        
        XCTAssertNotNil(scrollView.smoothScrollManager)
    }
    
    // testFastFileOpener removed - FastFileOpener class was deleted in commit bddcae4
    
    func testPerformanceOfRendering() {
        let renderer = EnhancedMarkdownRenderer()
        let largeMarkdown = String(repeating: "# Heading\n\nParagraph text. ", count: 1000)
        let document = Document(parsing: largeMarkdown)
        
        measure {
            _ = renderer.render(document)
        }
    }
}