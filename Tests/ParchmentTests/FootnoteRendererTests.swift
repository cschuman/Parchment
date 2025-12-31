import XCTest
@testable import Parchment

final class FootnoteRendererTests: XCTestCase {

    var renderer: EnhancedMarkdownRenderer!

    override func setUp() {
        super.setUp()
        renderer = EnhancedMarkdownRenderer(theme: .minimal, zoomLevel: 1.0)
    }

    // MARK: - Integration Tests

    func testRenderSimpleFootnote() {
        let markdown = """
        This is a sentence with a footnote.[^1]

        [^1]: This is the footnote content.
        """

        let result = renderer.render(markdownText: markdown)
        let text = result.string

        // Should contain the main text
        XCTAssertTrue(text.contains("This is a sentence with a footnote."))

        // Should contain the footnote number in superscript format
        XCTAssertTrue(text.contains("[1]"), "Should render footnote reference as [1]")

        // Should contain footnotes section
        XCTAssertTrue(text.contains("Footnotes"), "Should have Footnotes header")
        XCTAssertTrue(text.contains("This is the footnote content."))
    }

    func testRenderMultipleFootnotes() {
        let markdown = """
        First point[^1] and second point[^2].

        [^1]: First footnote explanation.
        [^2]: Second footnote explanation.
        """

        let result = renderer.render(markdownText: markdown)
        let text = result.string

        XCTAssertTrue(text.contains("[1]"))
        XCTAssertTrue(text.contains("[2]"))
        XCTAssertTrue(text.contains("First footnote explanation."))
        XCTAssertTrue(text.contains("Second footnote explanation."))
    }

    func testRenderNamedFootnotes() {
        let markdown = """
        Important claim[^citation] needs evidence.

        [^citation]: Smith, J. (2024). Research Paper.
        """

        let result = renderer.render(markdownText: markdown)
        let text = result.string

        // Named footnote should be rendered as [1] since it's the first
        XCTAssertTrue(text.contains("[1]"))
        XCTAssertTrue(text.contains("Smith, J."))
    }

    func testFootnoteOrderBasedOnFirstReference() {
        let markdown = """
        Second appears first[^second], then first[^first].

        [^first]: This is defined first but referenced second.
        [^second]: This is defined second but referenced first.
        """

        let result = renderer.render(markdownText: markdown)
        let text = result.string

        // The footnote numbers should be based on order of first appearance
        // [^second] appears first, so it should be [1]
        // [^first] appears second, so it should be [2]

        // Find positions in the footnotes section
        if let footnotesIndex = text.range(of: "Footnotes") {
            let footnotesSection = String(text[footnotesIndex.lowerBound...])

            // [1] should appear before "defined second" content
            let pos1 = footnotesSection.range(of: "[1]")?.lowerBound
            let posSecond = footnotesSection.range(of: "defined second")?.lowerBound

            XCTAssertNotNil(pos1)
            XCTAssertNotNil(posSecond)

            if let p1 = pos1, let ps = posSecond {
                XCTAssertTrue(p1 < ps, "[1] should be associated with 'second' footnote")
            }
        }
    }

    func testRenderWithoutFootnotes() {
        let markdown = """
        This is regular markdown without footnotes.

        ## Heading

        - List item 1
        - List item 2
        """

        let result = renderer.render(markdownText: markdown)
        let text = result.string

        // Should not contain footnotes section
        XCTAssertFalse(text.contains("Footnotes"), "Should not have Footnotes section when no footnotes present")
    }

    func testRenderMixedContent() {
        let markdown = """
        # Main Title

        This paragraph has **bold text** and a footnote[^1].

        - List item with footnote[^2]
        - Regular list item

        > Blockquote with footnote[^3]

        [^1]: First note
        [^2]: Second note
        [^3]: Third note
        """

        let result = renderer.render(markdownText: markdown)
        let text = result.string

        // Should render all footnotes
        XCTAssertTrue(text.contains("[1]"))
        XCTAssertTrue(text.contains("[2]"))
        XCTAssertTrue(text.contains("[3]"))

        // Should preserve other formatting
        XCTAssertTrue(text.contains("Main Title"))
    }

    func testOrphanFootnoteReference() {
        let markdown = """
        This has an orphan reference[^missing] that has no definition.
        """

        let result = renderer.render(markdownText: markdown)
        let text = result.string

        // Orphan reference should be rendered as-is
        XCTAssertTrue(text.contains("[^missing]"), "Orphan reference should remain as plain text")

        // Should not have footnotes section since no valid footnotes
        XCTAssertFalse(text.contains("Footnotes"))
    }

    func testDuplicateReferences() {
        let markdown = """
        First reference[^1] and same reference again[^1].

        [^1]: This footnote is referenced twice.
        """

        let result = renderer.render(markdownText: markdown)
        let text = result.string

        // Count occurrences of [1] in the main text (before Footnotes section)
        if let footnotesIndex = text.range(of: "Footnotes") {
            let mainText = String(text[..<footnotesIndex.lowerBound])
            let count = mainText.components(separatedBy: "[1]").count - 1
            XCTAssertEqual(count, 2, "Should have two [1] references in main text")
        }

        // Footnotes section should only have one definition
        if let footnotesIndex = text.range(of: "Footnotes") {
            let footnotesSection = String(text[footnotesIndex.lowerBound...])
            let defCount = footnotesSection.components(separatedBy: "referenced twice").count - 1
            XCTAssertEqual(defCount, 1, "Should have only one definition in footnotes section")
        }
    }

    // MARK: - Theme Integration Tests

    func testFootnoteRenderingWithDifferentThemes() {
        let markdown = """
        Text with footnote[^1].

        [^1]: Footnote content.
        """

        let themes: [ParchmentTheme] = [.minimal, .midnight, .sepia, .elegant]

        for theme in themes {
            let themeRenderer = EnhancedMarkdownRenderer(theme: theme, zoomLevel: 1.0)
            let result = themeRenderer.render(markdownText: markdown)

            XCTAssertTrue(result.string.contains("[1]"),
                         "Footnote should render correctly with \(theme.name) theme")
            XCTAssertTrue(result.string.contains("Footnotes"),
                         "Footnotes section should render with \(theme.name) theme")
        }
    }

    func testFootnoteRenderingWithZoom() {
        let markdown = """
        Text with footnote[^1].

        [^1]: Footnote content.
        """

        let zoomLevels: [CGFloat] = [0.5, 1.0, 1.5, 2.0]

        for zoom in zoomLevels {
            let zoomRenderer = EnhancedMarkdownRenderer(theme: .minimal, zoomLevel: zoom)
            let result = zoomRenderer.render(markdownText: markdown)

            XCTAssertTrue(result.string.contains("[1]"),
                         "Footnote should render correctly at zoom \(zoom)")
        }
    }
}
