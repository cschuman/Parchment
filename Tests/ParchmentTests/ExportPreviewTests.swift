import XCTest
@testable import Parchment

final class ExportPreviewTests: XCTestCase {

    // MARK: - Preview Generation Tests

    func testHTMLPreviewGeneration() {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "# Test\n\nHello World")
        let options = ExportOptions()

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertFalse(html.isEmpty, "HTML preview should not be empty")
        XCTAssertTrue(html.contains("<!DOCTYPE html>"), "HTML should contain doctype")
        XCTAssertTrue(html.contains("<h1>"), "HTML should contain heading")
        XCTAssertTrue(html.contains("Hello World"), "HTML should contain content")
    }

    func testHTMLPreviewWithDarkTheme() {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "# Dark Theme Test")
        var options = ExportOptions()
        options.theme = .dark

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertTrue(html.contains("#f5f5f7"), "Dark theme should use light text color")
        XCTAssertTrue(html.contains("#1d1d1f"), "Dark theme should use dark background color")
    }

    func testHTMLPreviewWithLightTheme() {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "# Light Theme Test")
        var options = ExportOptions()
        options.theme = .light

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertTrue(html.contains("#1d1d1f"), "Light theme should use dark text color")
        XCTAssertTrue(html.contains("#ffffff"), "Light theme should use light background color")
    }

    func testHTMLPreviewWithoutHeader() {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "# No Header")
        var options = ExportOptions()
        options.includeHeader = false

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertFalse(html.contains("<header class=\"header\">"), "HTML should not contain document header when disabled")
    }

    func testHTMLPreviewWithoutFooter() {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "# No Footer")
        var options = ExportOptions()
        options.includeFooter = false

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertFalse(html.contains("<footer class=\"footer\">"), "HTML should not contain footer when disabled")
    }

    func testRTFPreviewGeneration() throws {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "# RTF Test\n\nThis is RTF content.")
        let options = ExportOptions()

        // When
        let attributedString = try exporter.generateRTFPreview(document: document, options: options)

        // Then
        XCTAssertGreaterThan(attributedString.length, 0, "RTF preview should have content")
        XCTAssertTrue(attributedString.string.contains("RTF Test"), "RTF should contain heading text")
        XCTAssertTrue(attributedString.string.contains("This is RTF content"), "RTF should contain paragraph text")
    }

    func testPDFPreviewGeneration() async throws {
        // Skip in headless test environment - PDF generation requires WebView context
        throw XCTSkip("PDF preview generation requires UI context and hangs in headless tests")
    }

    // MARK: - Export Options Tests

    func testExportOptionsDefaultValues() {
        // Given/When
        let options = ExportOptions()

        // Then
        XCTAssertEqual(options.format, .pdf, "Default format should be PDF")
        XCTAssertEqual(options.theme, .light, "Default theme should be light")
        XCTAssertTrue(options.includeHeader, "Header should be included by default")
        XCTAssertTrue(options.includeFooter, "Footer should be included by default")
        XCTAssertTrue(options.includePageNumbers, "Page numbers should be included by default")
        XCTAssertTrue(options.includeWordCount, "Word count should be included by default")
    }

    func testExportOptionsModification() {
        // Given
        var options = ExportOptions()

        // When
        options.format = .html
        options.theme = .dark
        options.includeHeader = false
        options.includeFooter = false
        options.fontSize = 14
        options.lineHeight = 1.8

        // Then
        XCTAssertEqual(options.format, .html)
        XCTAssertEqual(options.theme, .dark)
        XCTAssertFalse(options.includeHeader)
        XCTAssertFalse(options.includeFooter)
        XCTAssertEqual(options.fontSize, 14)
        XCTAssertEqual(options.lineHeight, 1.8)
    }

    // MARK: - Format Support Tests

    func testPreviewSupportedFormats() {
        // PDF, HTML, and RTF should support preview
        // DOCX and plain text should not (they go directly to export)

        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "Test")
        let options = ExportOptions()

        // HTML preview should work
        let html = exporter.generateHTMLPreview(document: document, options: options)
        XCTAssertFalse(html.isEmpty, "HTML preview should be supported")

        // RTF preview should work
        do {
            let rtf = try exporter.generateRTFPreview(document: document, options: options)
            XCTAssertGreaterThan(rtf.length, 0, "RTF preview should be supported")
        } catch {
            XCTFail("RTF preview should not throw: \(error)")
        }
    }

    // MARK: - Content Security Tests

    func testHTMLPreviewHasContentSecurityPolicy() {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "# Security Test")
        let options = ExportOptions()

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertTrue(html.contains("Content-Security-Policy"), "HTML should contain CSP meta tag")
        XCTAssertTrue(html.contains("script-src 'none'"), "CSP should block script execution")
    }

    func testHTMLPreviewEscapesSpecialCharacters() {
        // Given
        let exporter = DocumentExporter()
        // The markdown parser escapes special characters like <, >, &
        let content = "Test with special chars: <test> & \"quotes\""
        let document = MarkdownDocument(url: nil, content: content)
        let options = ExportOptions()

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        // Content should be escaped to prevent XSS
        XCTAssertTrue(html.contains("&lt;test&gt;") || html.contains("&amp;"), "Special characters should be HTML encoded in body content")
    }

    // MARK: - Footnote Support Tests

    func testHTMLPreviewWithFootnotes() {
        // Given
        let exporter = DocumentExporter()
        let content = """
        # Document with Footnotes

        This is a paragraph with a footnote[^1].

        [^1]: This is the footnote content.
        """
        let document = MarkdownDocument(url: nil, content: content)
        let options = ExportOptions()

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertTrue(html.contains("footnote"), "HTML should contain footnote elements")
        XCTAssertTrue(html.contains("footnotes"), "HTML should contain footnotes section")
    }

    // MARK: - Custom CSS Tests

    func testHTMLPreviewWithCustomCSS() {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "# Custom CSS Test")
        var options = ExportOptions()
        options.customCSS = "body { font-family: Georgia; }"

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertTrue(html.contains("font-family: Georgia"), "HTML should contain custom CSS")
    }

    // MARK: - Edge Cases

    func testEmptyDocumentPreview() {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "")
        let options = ExportOptions()

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertFalse(html.isEmpty, "HTML preview of empty document should still have structure")
        XCTAssertTrue(html.contains("<!DOCTYPE html>"), "Empty document should still have valid HTML structure")
    }

    func testLargeDocumentPreview() {
        // Given
        let exporter = DocumentExporter()
        let content = String(repeating: "# Heading\n\nParagraph with some content.\n\n", count: 100)
        let document = MarkdownDocument(url: nil, content: content)
        let options = ExportOptions()

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertFalse(html.isEmpty, "Large document preview should work")
        XCTAssertGreaterThan(html.count, content.count, "HTML should be larger than raw content")
    }

    func testDocumentWithSpecialCharactersInTitle() {
        // Given
        let exporter = DocumentExporter()
        let url = URL(fileURLWithPath: "/tmp/Test & \"Special\" <Characters>.md")
        let document = MarkdownDocument(url: url, content: "# Content")
        let options = ExportOptions()

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        // Special characters in title should be escaped
        XCTAssertFalse(html.contains("<title>Test & \"Special\" <Characters></title>"), "Title should be escaped")
        XCTAssertTrue(html.contains("&amp;") || html.contains("&quot;") || html.contains("&lt;"), "Special characters should be HTML encoded")
    }
}
