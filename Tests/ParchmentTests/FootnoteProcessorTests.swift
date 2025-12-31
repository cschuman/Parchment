import XCTest
@testable import Parchment

final class FootnoteProcessorTests: XCTestCase {

    var processor: FootnoteProcessor!

    override func setUp() {
        super.setUp()
        processor = FootnoteProcessor.shared
    }

    // MARK: - Reference Detection Tests

    func testFindSimpleNumericReference() {
        let text = "This is a sentence with a footnote.[^1]"
        let references = processor.findReferences(in: text)

        XCTAssertEqual(references.count, 1, "Should find exactly one reference")
        XCTAssertEqual(references[0].identifier, "1", "Reference identifier should be '1'")
    }

    func testFindMultipleReferences() {
        let text = "First footnote[^1] and second footnote[^2] and third[^3]."
        let references = processor.findReferences(in: text)

        XCTAssertEqual(references.count, 3, "Should find three references")
        XCTAssertEqual(references[0].identifier, "1")
        XCTAssertEqual(references[1].identifier, "2")
        XCTAssertEqual(references[2].identifier, "3")
    }

    func testFindAlphanumericReference() {
        let text = "Here is a note[^note] and another[^long-identifier]."
        let references = processor.findReferences(in: text)

        XCTAssertEqual(references.count, 2, "Should find two alphanumeric references")
        XCTAssertEqual(references[0].identifier, "note")
        XCTAssertEqual(references[1].identifier, "long-identifier")
    }

    func testReferenceWithUnderscore() {
        let text = "Reference with underscore[^my_note]."
        let references = processor.findReferences(in: text)

        XCTAssertEqual(references.count, 1)
        XCTAssertEqual(references[0].identifier, "my_note")
    }

    func testNoReferencesInPlainText() {
        let text = "This is plain text without any footnotes."
        let references = processor.findReferences(in: text)

        XCTAssertEqual(references.count, 0, "Should find no references in plain text")
    }

    func testDoesNotMatchDefinition() {
        // Definition syntax [^1]: should not be matched as a reference
        let text = "[^1]: This is a definition, not a reference."
        let references = processor.findReferences(in: text)

        XCTAssertEqual(references.count, 0, "Should not match definition as reference")
    }

    // MARK: - Definition Detection Tests

    func testFindSimpleDefinition() {
        let text = "[^1]: This is the footnote content."
        let definitions = processor.findDefinitions(in: text)

        XCTAssertEqual(definitions.count, 1, "Should find one definition")
        XCTAssertEqual(definitions[0].identifier, "1")
        XCTAssertEqual(definitions[0].content, "This is the footnote content.")
    }

    func testFindMultipleDefinitions() {
        let text = """
        [^1]: First footnote content.
        [^2]: Second footnote content.
        """
        let definitions = processor.findDefinitions(in: text)

        XCTAssertEqual(definitions.count, 2, "Should find two definitions")
        XCTAssertEqual(definitions[0].identifier, "1")
        XCTAssertEqual(definitions[1].identifier, "2")
    }

    func testDefinitionWithMultipleWords() {
        let text = "[^note]: This is a longer footnote with multiple words and punctuation!"
        let definitions = processor.findDefinitions(in: text)

        XCTAssertEqual(definitions.count, 1)
        XCTAssertTrue(definitions[0].content.contains("longer footnote"))
    }

    // MARK: - Processing Tests

    func testProcessRemovesDefinitions() {
        let text = """
        This is a paragraph with a footnote.[^1]

        [^1]: This is the footnote definition.
        """
        let processed = processor.process(text)

        XCTAssertFalse(processed.text.contains("[^1]:"), "Processed text should not contain definition")
        XCTAssertTrue(processed.text.contains("[^1]"), "Processed text should still contain reference")
    }

    func testProcessPreservesReferenceOrder() {
        let text = """
        First[^b] then second[^a] then first again[^b].

        [^a]: Definition A
        [^b]: Definition B
        """
        let processed = processor.process(text)

        // Order should be based on first occurrence: b, a
        XCTAssertEqual(processed.referenceOrder.count, 2)
        XCTAssertEqual(processed.referenceOrder[0], "b", "First referenced should be 'b'")
        XCTAssertEqual(processed.referenceOrder[1], "a", "Second referenced should be 'a'")
    }

    func testProcessBuildsDefinitionMap() {
        let text = """
        Text[^1] and more[^note].

        [^1]: Numeric footnote
        [^note]: Named footnote
        """
        let processed = processor.process(text)

        XCTAssertEqual(processed.definitions.count, 2)
        XCTAssertNotNil(processed.definitions["1"])
        XCTAssertNotNil(processed.definitions["note"])
        XCTAssertEqual(processed.definitions["1"]?.content, "Numeric footnote")
        XCTAssertEqual(processed.definitions["note"]?.content, "Named footnote")
    }

    // MARK: - Display Number Tests

    func testDisplayNumber() {
        let order = ["first", "second", "third"]

        XCTAssertEqual(processor.displayNumber(for: "first", in: order), 1)
        XCTAssertEqual(processor.displayNumber(for: "second", in: order), 2)
        XCTAssertEqual(processor.displayNumber(for: "third", in: order), 3)
        XCTAssertEqual(processor.displayNumber(for: "unknown", in: order), 0)
    }

    // MARK: - Edge Cases

    func testEmptyText() {
        let processed = processor.process("")

        XCTAssertEqual(processed.text, "")
        XCTAssertTrue(processed.definitions.isEmpty)
        XCTAssertTrue(processed.referenceOrder.isEmpty)
    }

    func testTextWithOnlyDefinitions() {
        let text = """
        [^1]: Footnote one
        [^2]: Footnote two
        """
        let processed = processor.process(text)

        // Definitions should be captured but text should be mostly empty
        XCTAssertEqual(processed.definitions.count, 2)
        XCTAssertTrue(processed.referenceOrder.isEmpty, "No references means empty order")
    }

    func testOrphanReference() {
        // Reference without corresponding definition
        let text = "This has an orphan reference[^missing]."
        let processed = processor.process(text)

        // Reference should still be in text, but not in definitions
        XCTAssertTrue(processed.text.contains("[^missing]"))
        XCTAssertNil(processed.definitions["missing"])
        // Orphan references should not be in the reference order
        XCTAssertTrue(processed.referenceOrder.isEmpty, "Orphan reference should not be in order")
    }

    func testOrphanDefinition() {
        // Definition without corresponding reference
        let text = """
        This paragraph has no footnotes.

        [^unused]: This definition is never referenced.
        """
        let processed = processor.process(text)

        // Definition should be captured but not in order
        XCTAssertNotNil(processed.definitions["unused"])
        XCTAssertFalse(processed.referenceOrder.contains("unused"))
    }

    // MARK: - Rendering Tests

    func testRenderReference() {
        let theme = ParchmentTheme.minimal
        let baseFont = NSFont.systemFont(ofSize: 16)

        let attrString = processor.renderReference(
            number: 1,
            identifier: "test",
            theme: theme,
            baseFont: baseFont
        )

        XCTAssertTrue(attrString.string.contains("[1]"), "Should contain bracketed number")

        // Check for superscript styling
        var effectiveRange = NSRange()
        let attrs = attrString.attributes(at: 0, effectiveRange: &effectiveRange)

        XCTAssertNotNil(attrs[.baselineOffset], "Should have baseline offset for superscript")
        XCTAssertNotNil(attrs[.font], "Should have font attribute")
    }

    func testRenderFootnotesSection() {
        let theme = ParchmentTheme.minimal
        let definitions: [String: FootnoteProcessor.FootnoteDefinition] = [
            "1": FootnoteProcessor.FootnoteDefinition(
                identifier: "1",
                content: "First footnote content",
                range: "".startIndex..<"".endIndex
            ),
            "2": FootnoteProcessor.FootnoteDefinition(
                identifier: "2",
                content: "Second footnote content",
                range: "".startIndex..<"".endIndex
            )
        ]
        let order = ["1", "2"]

        let section = processor.renderFootnotesSection(
            definitions: definitions,
            order: order,
            theme: theme,
            zoomLevel: 1.0
        )

        let text = section.string
        XCTAssertTrue(text.contains("Footnotes"), "Should contain Footnotes header")
        XCTAssertTrue(text.contains("[1]"), "Should contain first footnote number")
        XCTAssertTrue(text.contains("[2]"), "Should contain second footnote number")
        XCTAssertTrue(text.contains("First footnote content"))
        XCTAssertTrue(text.contains("Second footnote content"))
    }

    func testRenderEmptyFootnotesSection() {
        let theme = ParchmentTheme.minimal
        let section = processor.renderFootnotesSection(
            definitions: [:],
            order: [],
            theme: theme,
            zoomLevel: 1.0
        )

        XCTAssertEqual(section.string, "", "Empty order should produce empty section")
    }

    // MARK: - HTML Rendering Tests

    func testProcessForHTMLSimple() {
        let markdown = """
        Text with footnote[^1].

        [^1]: Footnote content.
        """

        let (processedMarkdown, footnotesHTML) = processor.processForHTML(markdown)

        // Processed markdown should have HTML reference
        XCTAssertTrue(processedMarkdown.contains("<sup"), "Should contain superscript tag")
        XCTAssertTrue(processedMarkdown.contains("fnref:1"), "Should contain footnote reference ID")
        XCTAssertFalse(processedMarkdown.contains("[^1]"), "Should not contain raw footnote reference")

        // Footnotes HTML should have the definition
        XCTAssertTrue(footnotesHTML.contains("Footnotes"), "Should have Footnotes header")
        XCTAssertTrue(footnotesHTML.contains("fn:1"), "Should have footnote ID")
        XCTAssertTrue(footnotesHTML.contains("Footnote content."), "Should have content")
    }

    func testProcessForHTMLNoFootnotes() {
        let markdown = "Plain text without footnotes."

        let (processedMarkdown, footnotesHTML) = processor.processForHTML(markdown)

        XCTAssertEqual(processedMarkdown, markdown, "Should return unchanged markdown")
        XCTAssertEqual(footnotesHTML, "", "Should return empty footnotes HTML")
    }

    func testProcessForHTMLEscapesContent() {
        let markdown = """
        Text[^1].

        [^1]: Content with <script>alert('xss')</script> HTML.
        """

        let (_, footnotesHTML) = processor.processForHTML(markdown)

        XCTAssertFalse(footnotesHTML.contains("<script>"), "Should escape HTML tags")
        XCTAssertTrue(footnotesHTML.contains("&lt;script&gt;"), "Should have escaped script tag")
    }

    func testProcessForHTMLMultipleFootnotes() {
        let markdown = """
        First[^a] and second[^b].

        [^a]: First content.
        [^b]: Second content.
        """

        let (processedMarkdown, footnotesHTML) = processor.processForHTML(markdown)

        // Check references
        XCTAssertTrue(processedMarkdown.contains("fnref:a"))
        XCTAssertTrue(processedMarkdown.contains("fnref:b"))

        // Check definitions
        XCTAssertTrue(footnotesHTML.contains("fn:a"))
        XCTAssertTrue(footnotesHTML.contains("fn:b"))
        XCTAssertTrue(footnotesHTML.contains("First content."))
        XCTAssertTrue(footnotesHTML.contains("Second content."))
    }
}
