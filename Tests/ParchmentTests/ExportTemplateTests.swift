import XCTest
@testable import Parchment

final class ExportTemplateTests: XCTestCase {

    // MARK: - Template Creation Tests

    func testStandardTemplateProperties() {
        // Given/When
        let template = ExportTemplate.standard

        // Then
        XCTAssertEqual(template.id, "standard", "Standard template should have correct ID")
        XCTAssertEqual(template.name, "Standard", "Standard template should have correct name")
        XCTAssertEqual(template.fontSize, 12, "Standard template should use 12pt font")
        XCTAssertEqual(template.lineHeight, 1.6, "Standard template should use 1.6 line height")
        XCTAssertEqual(template.margins.top, 72, "Standard template should have 1 inch (72pt) top margin")
        XCTAssertEqual(template.margins.right, 72, "Standard template should have 1 inch right margin")
        XCTAssertEqual(template.margins.bottom, 72, "Standard template should have 1 inch bottom margin")
        XCTAssertEqual(template.margins.left, 72, "Standard template should have 1 inch left margin")
        XCTAssertTrue(template.showPageNumbers, "Standard template should show page numbers")
        XCTAssertTrue(template.showWordCount, "Standard template should show word count")
        XCTAssertEqual(template.headerStyle, .standard, "Standard template should use standard header")
        XCTAssertEqual(template.footerStyle, .standard, "Standard template should use standard footer")
    }

    func testAcademicTemplateProperties() {
        // Given/When
        let template = ExportTemplate.academic

        // Then
        XCTAssertEqual(template.id, "academic", "Academic template should have correct ID")
        XCTAssertEqual(template.name, "Academic", "Academic template should have correct name")
        XCTAssertTrue(template.bodyFont.contains("Times"), "Academic template should use serif font")
        XCTAssertEqual(template.lineHeight, 2.0, "Academic template should be double-spaced")
        XCTAssertEqual(template.margins.top, 72, "Academic template should have 1 inch margins")
        XCTAssertEqual(template.margins.right, 72, "Academic template should have 1 inch margins")
        XCTAssertTrue(template.showPageNumbers, "Academic template should show page numbers")
        XCTAssertFalse(template.showWordCount, "Academic template should not show word count")
        XCTAssertEqual(template.headerStyle, .academic, "Academic template should use academic header")
        XCTAssertEqual(template.footerStyle, .academic, "Academic template should use academic footer")
    }

    func testGitHubTemplateProperties() {
        // Given/When
        let template = ExportTemplate.github

        // Then
        XCTAssertEqual(template.id, "github", "GitHub template should have correct ID")
        XCTAssertEqual(template.name, "GitHub", "GitHub template should have correct name")
        XCTAssertTrue(template.bodyFont.contains("system"), "GitHub template should use system font")
        XCTAssertEqual(template.fontSize, 14, "GitHub template should use 14pt font")
        XCTAssertEqual(template.lineHeight, 1.5, "GitHub template should use 1.5 line height")
        XCTAssertEqual(template.maxWidth, 980, "GitHub template should have 980px max width")
        XCTAssertFalse(template.showPageNumbers, "GitHub template should not show page numbers")
        XCTAssertFalse(template.showWordCount, "GitHub template should not show word count")
        XCTAssertEqual(template.headerStyle, .none, "GitHub template should have no custom header")
        XCTAssertEqual(template.footerStyle, .none, "GitHub template should have no custom footer")
    }

    func testManuscriptTemplateProperties() {
        // Given/When
        let template = ExportTemplate.manuscript

        // Then
        XCTAssertEqual(template.id, "manuscript", "Manuscript template should have correct ID")
        XCTAssertEqual(template.name, "Manuscript", "Manuscript template should have correct name")
        XCTAssertTrue(template.bodyFont.contains("Courier"), "Manuscript template should use monospace font")
        XCTAssertEqual(template.lineHeight, 2.0, "Manuscript template should be double-spaced")
        XCTAssertEqual(template.margins.left, 108, "Manuscript template should have 1.5 inch left margin")
        XCTAssertEqual(template.margins.right, 108, "Manuscript template should have 1.5 inch right margin")
        XCTAssertTrue(template.showPageNumbers, "Manuscript template should show page numbers")
        XCTAssertTrue(template.showWordCount, "Manuscript template should show word count")
        XCTAssertEqual(template.headerStyle, .manuscript, "Manuscript template should use manuscript header")
        XCTAssertEqual(template.footerStyle, .manuscript, "Manuscript template should use manuscript footer")
    }

    // MARK: - Template Collection Tests

    func testAllTemplatesAvailable() {
        // Given/When
        let allTemplates = ExportTemplate.all

        // Then
        XCTAssertEqual(allTemplates.count, 4, "Should have 4 templates available")
        XCTAssertTrue(allTemplates.contains(.standard), "Should include standard template")
        XCTAssertTrue(allTemplates.contains(.academic), "Should include academic template")
        XCTAssertTrue(allTemplates.contains(.github), "Should include GitHub template")
        XCTAssertTrue(allTemplates.contains(.manuscript), "Should include manuscript template")
    }

    func testTemplateByIdLookup() {
        // Given/When
        let standard = ExportTemplate.template(withId: "standard")
        let academic = ExportTemplate.template(withId: "academic")
        let github = ExportTemplate.template(withId: "github")
        let manuscript = ExportTemplate.template(withId: "manuscript")
        let invalid = ExportTemplate.template(withId: "nonexistent")

        // Then
        XCTAssertNotNil(standard, "Should find standard template by ID")
        XCTAssertEqual(standard?.name, "Standard")
        XCTAssertNotNil(academic, "Should find academic template by ID")
        XCTAssertEqual(academic?.name, "Academic")
        XCTAssertNotNil(github, "Should find GitHub template by ID")
        XCTAssertEqual(github?.name, "GitHub")
        XCTAssertNotNil(manuscript, "Should find manuscript template by ID")
        XCTAssertEqual(manuscript?.name, "Manuscript")
        XCTAssertNil(invalid, "Should return nil for invalid ID")
    }

    // MARK: - Template Equality Tests

    func testTemplateEquality() {
        // Given
        let template1 = ExportTemplate.standard
        let template2 = ExportTemplate.standard
        let template3 = ExportTemplate.academic

        // Then
        XCTAssertEqual(template1, template2, "Same templates should be equal")
        XCTAssertNotEqual(template1, template3, "Different templates should not be equal")
    }

    func testTemplateHashable() {
        // Given
        var templateSet: Set<ExportTemplate> = []

        // When
        templateSet.insert(.standard)
        templateSet.insert(.academic)
        templateSet.insert(.standard)  // Duplicate

        // Then
        XCTAssertEqual(templateSet.count, 2, "Set should contain unique templates only")
    }

    // MARK: - CSS Generation Tests

    func testCSSGenerationWithLightTheme() {
        // Given
        let template = ExportTemplate.standard
        var options = ExportOptions()
        options.theme = .light

        // When
        let css = template.generateCSS(with: options)

        // Then
        XCTAssertFalse(css.isEmpty, "CSS should not be empty")
        XCTAssertTrue(css.contains("--text-color: #1d1d1f"), "Light theme should have dark text color")
        XCTAssertTrue(css.contains("--bg-color: #ffffff"), "Light theme should have white background")
        XCTAssertTrue(css.contains("font-family"), "CSS should set font family")
        XCTAssertTrue(css.contains("line-height"), "CSS should set line height")
    }

    func testCSSGenerationWithDarkTheme() {
        // Given
        let template = ExportTemplate.standard
        var options = ExportOptions()
        options.theme = .dark

        // When
        let css = template.generateCSS(with: options)

        // Then
        XCTAssertTrue(css.contains("--text-color: #f5f5f7"), "Dark theme should have light text color")
        XCTAssertTrue(css.contains("--bg-color: #1d1d1f"), "Dark theme should have dark background")
    }

    func testAcademicCSSIncludesSpecialStyles() {
        // Given
        let template = ExportTemplate.academic
        let options = ExportOptions()

        // When
        let css = template.generateCSS(with: options)

        // Then
        XCTAssertTrue(css.contains("text-indent"), "Academic CSS should include text indent for paragraphs")
        XCTAssertTrue(css.contains("text-align: center") || css.contains("academic"), "Academic CSS should include academic-specific styles")
    }

    func testGitHubCSSIncludesSpecialStyles() {
        // Given
        let template = ExportTemplate.github
        let options = ExportOptions()

        // When
        let css = template.generateCSS(with: options)

        // Then
        XCTAssertTrue(css.contains("hljs") || css.contains("syntax"), "GitHub CSS should include syntax highlighting classes")
        XCTAssertTrue(css.contains("task-list") || css.contains("980"), "GitHub CSS should include GitHub-specific styles")
    }

    func testManuscriptCSSIncludesSpecialStyles() {
        // Given
        let template = ExportTemplate.manuscript
        let options = ExportOptions()

        // When
        let css = template.generateCSS(with: options)

        // Then
        XCTAssertTrue(css.contains("text-indent") || css.contains("manuscript"), "Manuscript CSS should include manuscript styles")
        XCTAssertTrue(css.contains("scene-break") || css.contains("chapter"), "Manuscript CSS should include chapter/scene break styles")
    }

    func testCustomCSSIsIncluded() {
        // Given
        let template = ExportTemplate.standard
        var options = ExportOptions()
        options.customCSS = "body { background: red; }"

        // When
        let css = template.generateCSS(with: options)

        // Then
        XCTAssertTrue(css.contains("background: red"), "Custom CSS should be included in generated CSS")
    }

    // MARK: - Header Generation Tests

    func testStandardHeaderGeneration() {
        // Given
        let template = ExportTemplate.standard
        let document = MarkdownDocument(url: URL(fileURLWithPath: "/tmp/TestDoc.md"), content: "# Test")

        // When
        let header = template.generateHeader(for: document, wordCount: 500)

        // Then
        XCTAssertTrue(header.contains("TestDoc"), "Header should contain document title")
        XCTAssertTrue(header.contains("header"), "Header should contain header class")
    }

    func testAcademicHeaderGeneration() {
        // Given
        let template = ExportTemplate.academic
        let document = MarkdownDocument(url: URL(fileURLWithPath: "/tmp/Essay.md"), content: "# Essay")

        // When
        let header = template.generateHeader(for: document, wordCount: 1000)

        // Then
        XCTAssertTrue(header.contains("Essay"), "Header should contain document title")
        XCTAssertTrue(header.contains("Author") || header.contains("author"), "Academic header should have author placeholder")
        XCTAssertTrue(header.contains("academic"), "Academic header should have academic class")
    }

    func testManuscriptHeaderGeneration() {
        // Given
        let template = ExportTemplate.manuscript
        let document = MarkdownDocument(url: URL(fileURLWithPath: "/tmp/Chapter1.md"), content: "# Chapter 1")

        // When
        let header = template.generateHeader(for: document, wordCount: 5000)

        // Then
        XCTAssertTrue(header.contains("Chapter1"), "Header should contain document title")
        XCTAssertTrue(header.contains("word"), "Manuscript header should show word count")
        XCTAssertTrue(header.contains("manuscript"), "Manuscript header should have manuscript class")
    }

    func testNoHeaderForGitHubTemplate() {
        // Given
        let template = ExportTemplate.github
        let document = MarkdownDocument(url: nil, content: "# README")

        // When
        let header = template.generateHeader(for: document, wordCount: 100)

        // Then
        XCTAssertTrue(header.isEmpty, "GitHub template should have no header")
    }

    // MARK: - Footer Generation Tests

    func testStandardFooterGeneration() {
        // Given
        let template = ExportTemplate.standard
        let document = MarkdownDocument(url: nil, content: "Test content")

        // When
        let footer = template.generateFooter(for: document, wordCount: 250, readingTime: 2)

        // Then
        XCTAssertTrue(footer.contains("footer"), "Footer should contain footer class")
        XCTAssertTrue(footer.contains("250 words"), "Footer should show word count")
        XCTAssertTrue(footer.contains("2 min"), "Footer should show reading time")
        XCTAssertTrue(footer.contains("Parchment"), "Footer should credit Parchment")
    }

    func testAcademicFooterGeneration() {
        // Given
        let template = ExportTemplate.academic
        let document = MarkdownDocument(url: nil, content: "Academic content")

        // When
        let footer = template.generateFooter(for: document, wordCount: 2000, readingTime: 8)

        // Then
        XCTAssertTrue(footer.contains("academic"), "Academic footer should have academic class")
        XCTAssertTrue(footer.contains("page-number"), "Academic footer should have page number")
    }

    func testManuscriptFooterGeneration() {
        // Given
        let template = ExportTemplate.manuscript
        let document = MarkdownDocument(url: nil, content: "Story content")

        // When
        let footer = template.generateFooter(for: document, wordCount: 10000, readingTime: 40)

        // Then
        XCTAssertTrue(footer.contains("manuscript"), "Manuscript footer should have manuscript class")
        XCTAssertTrue(footer.contains("SURNAME") || footer.contains("surname"), "Manuscript footer should have surname placeholder")
    }

    func testNoFooterForGitHubTemplate() {
        // Given
        let template = ExportTemplate.github
        let document = MarkdownDocument(url: nil, content: "README content")

        // When
        let footer = template.generateFooter(for: document, wordCount: 100, readingTime: 1)

        // Then
        XCTAssertTrue(footer.isEmpty, "GitHub template should have no footer")
    }

    // MARK: - ExportOptions Template Integration Tests

    func testApplyTemplateUpdatesOptions() {
        // Given
        var options = ExportOptions()
        let academicTemplate = ExportTemplate.academic

        // When
        options.applyTemplate(academicTemplate)

        // Then
        XCTAssertEqual(options.template, academicTemplate, "Template should be set")
        XCTAssertEqual(options.margins.top, academicTemplate.margins.top, "Margins should be applied from template")
        XCTAssertEqual(options.fontSize, academicTemplate.fontSize, "Font size should be applied from template")
        XCTAssertEqual(options.lineHeight, academicTemplate.lineHeight, "Line height should be applied from template")
        XCTAssertEqual(options.maxWidth, academicTemplate.maxWidth, "Max width should be applied from template")
        XCTAssertEqual(options.includePageNumbers, academicTemplate.showPageNumbers, "Page number setting should be applied")
        XCTAssertEqual(options.includeWordCount, academicTemplate.showWordCount, "Word count setting should be applied")
    }

    func testTemplatePreservesTheme() {
        // Given
        var options = ExportOptions()
        options.theme = .dark

        // When
        options.applyTemplate(.academic)

        // Then
        XCTAssertEqual(options.theme, .dark, "Theme should be preserved when applying template")
    }

    // MARK: - HTML Export Integration Tests

    func testExportWithAcademicTemplate() {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "# Academic Paper\n\nThis is the introduction.")
        var options = ExportOptions()
        options.applyTemplate(.academic)

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertTrue(html.contains("Times") || html.contains("serif"), "Academic export should use serif font")
        XCTAssertTrue(html.contains("2") || html.contains("line-height"), "Academic export should be double-spaced")
        XCTAssertTrue(html.contains("academic"), "Academic export should have academic styles")
    }

    func testExportWithGitHubTemplate() {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "# README\n\n```swift\nlet code = true\n```")
        var options = ExportOptions()
        options.applyTemplate(.github)

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertFalse(html.contains("<header class=\"header\">"), "GitHub export should not have header")
        XCTAssertFalse(html.contains("<footer class=\"footer\">"), "GitHub export should not have footer")
        XCTAssertTrue(html.contains("hljs") || html.contains("syntax") || html.contains("GitHub"), "GitHub export should have syntax styles")
    }

    func testExportWithManuscriptTemplate() {
        // Given
        let exporter = DocumentExporter()
        let document = MarkdownDocument(url: nil, content: "# Chapter One\n\nIt was a dark and stormy night.")
        var options = ExportOptions()
        options.applyTemplate(.manuscript)

        // When
        let html = exporter.generateHTMLPreview(document: document, options: options)

        // Then
        XCTAssertTrue(html.contains("Courier") || html.contains("monospace"), "Manuscript export should use monospace font")
        XCTAssertTrue(html.contains("manuscript"), "Manuscript export should have manuscript styles")
        XCTAssertTrue(html.contains("word"), "Manuscript export should show word count in header")
    }

    // MARK: - Edge Cases

    func testTemplateWithEmptyDocument() {
        // Given
        let template = ExportTemplate.academic
        let document = MarkdownDocument(url: nil, content: "")

        // When
        let header = template.generateHeader(for: document, wordCount: 0)
        let footer = template.generateFooter(for: document, wordCount: 0, readingTime: 0)

        // Then
        XCTAssertFalse(header.isEmpty, "Header should still be generated for empty document")
        XCTAssertFalse(footer.isEmpty, "Footer should still be generated for empty document")
    }

    func testTemplateWithSpecialCharactersInTitle() {
        // Given
        let template = ExportTemplate.standard
        let url = URL(fileURLWithPath: "/tmp/Test & \"Special\" <Chars>.md")
        let document = MarkdownDocument(url: url, content: "Content")

        // When
        let header = template.generateHeader(for: document, wordCount: 10)

        // Then
        // Special characters should be escaped
        XCTAssertFalse(header.contains("<Chars>"), "Special characters should be escaped")
        XCTAssertTrue(header.contains("&amp;") || header.contains("&lt;") || header.contains("&gt;"), "HTML entities should be used")
    }

    func testTemplateWithLargeWordCount() {
        // Given
        let template = ExportTemplate.manuscript
        let document = MarkdownDocument(url: nil, content: "Long content")

        // When
        let header = template.generateHeader(for: document, wordCount: 150_000)

        // Then
        XCTAssertTrue(header.contains("150") || header.contains("word"), "Large word count should be formatted in header")
    }
}
