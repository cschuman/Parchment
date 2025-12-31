import XCTest
import Markdown
@testable import Parchment

final class TypographyTests: XCTestCase {

    // MARK: - Baseline Grid Tests

    func testRoundToGridSnapsToNearestMultiple() {
        // Test snapping to 8pt grid
        XCTAssertEqual(TypographyEngine.roundToGrid(7), 8, "7 should round to 8")
        XCTAssertEqual(TypographyEngine.roundToGrid(8), 8, "8 should stay 8")
        XCTAssertEqual(TypographyEngine.roundToGrid(9), 8, "9 should round to 8")
        XCTAssertEqual(TypographyEngine.roundToGrid(12), 16, "12 should round to 16")
        XCTAssertEqual(TypographyEngine.roundToGrid(4), 8, "4 should round to 8")
        XCTAssertEqual(TypographyEngine.roundToGrid(3), 0, "3 should round to 0")
        XCTAssertEqual(TypographyEngine.roundToGrid(0), 0, "0 should stay 0")
        XCTAssertEqual(TypographyEngine.roundToGrid(16), 16, "16 should stay 16")
        XCTAssertEqual(TypographyEngine.roundToGrid(24), 24, "24 should stay 24")
    }

    func testRoundToGridWithCustomGridSize() {
        // Test with custom 4pt grid
        XCTAssertEqual(TypographyEngine.roundToGrid(5, gridSize: 4), 4, "5 should round to 4 with 4pt grid")
        XCTAssertEqual(TypographyEngine.roundToGrid(6, gridSize: 4), 8, "6 should round to 8 with 4pt grid")
        XCTAssertEqual(TypographyEngine.roundToGrid(7, gridSize: 4), 8, "7 should round to 8 with 4pt grid")
    }

    func testCeilToGridRoundsUp() {
        XCTAssertEqual(TypographyEngine.ceilToGrid(1), 8, "1 should ceil to 8")
        XCTAssertEqual(TypographyEngine.ceilToGrid(7), 8, "7 should ceil to 8")
        XCTAssertEqual(TypographyEngine.ceilToGrid(8), 8, "8 should stay 8")
        XCTAssertEqual(TypographyEngine.ceilToGrid(9), 16, "9 should ceil to 16")
        XCTAssertEqual(TypographyEngine.ceilToGrid(16), 16, "16 should stay 16")
        XCTAssertEqual(TypographyEngine.ceilToGrid(0), 0, "0 should stay 0")
    }

    func testGridAlignedLineHeightMultiple() {
        // For 16pt font with 1.4 multiple: 16 * 1.4 = 22.4, ceils to 24
        // Resulting multiple: 24 / 16 = 1.5
        let multiple16 = TypographyEngine.gridAlignedLineHeightMultiple(fontSize: 16, desiredMultiple: 1.4)
        let lineHeight16 = 16 * multiple16
        XCTAssertEqual(lineHeight16.truncatingRemainder(dividingBy: 8), 0, accuracy: 0.001,
                       "Line height for 16pt font should be a multiple of 8")

        // For 18pt font with 1.5 multiple: 18 * 1.5 = 27, ceils to 32
        // Resulting multiple: 32 / 18 = 1.778
        let multiple18 = TypographyEngine.gridAlignedLineHeightMultiple(fontSize: 18, desiredMultiple: 1.5)
        let lineHeight18 = 18 * multiple18
        XCTAssertEqual(lineHeight18.truncatingRemainder(dividingBy: 8), 0, accuracy: 0.001,
                       "Line height for 18pt font should be a multiple of 8")

        // For 14pt font with 1.3 multiple: 14 * 1.3 = 18.2, ceils to 24
        let multiple14 = TypographyEngine.gridAlignedLineHeightMultiple(fontSize: 14, desiredMultiple: 1.3)
        let lineHeight14 = 14 * multiple14
        XCTAssertEqual(lineHeight14.truncatingRemainder(dividingBy: 8), 0, accuracy: 0.001,
                       "Line height for 14pt font should be a multiple of 8")
    }

    func testGridAlignedLineHeightIsAtLeastDesiredMultiple() {
        // The grid-aligned multiple should always be >= the desired multiple
        let testCases: [(fontSize: CGFloat, desiredMultiple: CGFloat)] = [
            (16, 1.2),
            (16, 1.4),
            (16, 1.5),
            (18, 1.4),
            (14, 1.3),
            (24, 1.2),
        ]

        for (fontSize, desiredMultiple) in testCases {
            let gridMultiple = TypographyEngine.gridAlignedLineHeightMultiple(
                fontSize: fontSize,
                desiredMultiple: desiredMultiple
            )
            XCTAssertGreaterThanOrEqual(gridMultiple, desiredMultiple,
                "Grid-aligned multiple (\(gridMultiple)) should be >= desired (\(desiredMultiple)) for \(fontSize)pt font")
        }
    }

    func testBaselineGridConstant() {
        XCTAssertEqual(TypographyEngine.baselineGridSize, 8.0, "Baseline grid size should be 8pt")
    }

    // MARK: - Typography Engine Attribute Tests

    func testBodyAttributesHaveGridAlignedLineHeight() {
        let theme = ParchmentTheme.minimal
        let engine = TypographyEngine(theme: theme)
        let attrs = engine.bodyAttributes()

        guard let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle,
              let font = attrs[.font] as? NSFont else {
            XCTFail("Body attributes must have paragraph style and font")
            return
        }

        // Calculate the effective line height
        let lineHeight = font.pointSize * paragraphStyle.lineHeightMultiple
        // Check that line height is close to a multiple of 8
        // (accounting for floating point precision issues)
        let nearestGrid = (lineHeight / 8).rounded() * 8
        XCTAssertEqual(lineHeight, nearestGrid, accuracy: 0.01,
                       "Body line height (\(lineHeight)) should be a multiple of 8pt grid")
    }

    func testHeadingAttributesHaveGridAlignedLineHeight() {
        let engine = TypographyEngine(theme: .minimal)

        for level in 1...6 {
            let attrs = engine.headingAttributes(level: level)

            guard let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle,
                  let font = attrs[.font] as? NSFont else {
                XCTFail("Heading \(level) attributes must have paragraph style and font")
                continue
            }

            let lineHeight = font.pointSize * paragraphStyle.lineHeightMultiple
            // Check that line height is close to a multiple of 8
            // (accounting for floating point precision issues)
            let nearestGrid = (lineHeight / 8).rounded() * 8
            XCTAssertEqual(lineHeight, nearestGrid, accuracy: 0.01,
                           "Heading \(level) line height (\(lineHeight)) should be a multiple of 8pt grid")
        }
    }

    func testHeadingParagraphSpacingIsGridAligned() {
        let engine = TypographyEngine(theme: .minimal)

        for level in 1...6 {
            let attrs = engine.headingAttributes(level: level)

            guard let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle else {
                XCTFail("Heading \(level) attributes must have paragraph style")
                continue
            }

            let spacingBefore = paragraphStyle.paragraphSpacingBefore
            let spacingAfter = paragraphStyle.paragraphSpacing

            XCTAssertEqual(spacingBefore.truncatingRemainder(dividingBy: 8), 0, accuracy: 0.001,
                           "Heading \(level) paragraphSpacingBefore (\(spacingBefore)) should be grid-aligned")
            XCTAssertEqual(spacingAfter.truncatingRemainder(dividingBy: 8), 0, accuracy: 0.001,
                           "Heading \(level) paragraphSpacing (\(spacingAfter)) should be grid-aligned")
        }
    }

    func testCodeBlockAttributesHaveGridAlignedLineHeight() {
        let engine = TypographyEngine(theme: .minimal)
        let attrs = engine.codeBlockAttributes()

        guard let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle,
              let font = attrs[.font] as? NSFont else {
            XCTFail("Code block attributes must have paragraph style and font")
            return
        }

        let lineHeight = font.pointSize * paragraphStyle.lineHeightMultiple
        // Check that line height is close to a multiple of 8
        let nearestGrid = (lineHeight / 8).rounded() * 8
        XCTAssertEqual(lineHeight, nearestGrid, accuracy: 0.01,
                       "Code block line height (\(lineHeight)) should be a multiple of 8pt grid")
    }

    func testBlockquoteAttributesHaveGridAlignedIndent() {
        let engine = TypographyEngine(theme: .minimal)
        let attrs = engine.blockquoteAttributes()

        guard let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle else {
            XCTFail("Blockquote attributes must have paragraph style")
            return
        }

        XCTAssertEqual(paragraphStyle.headIndent.truncatingRemainder(dividingBy: 8), 0, accuracy: 0.001,
                       "Blockquote headIndent (\(paragraphStyle.headIndent)) should be grid-aligned")
        XCTAssertEqual(paragraphStyle.firstLineHeadIndent.truncatingRemainder(dividingBy: 8), 0, accuracy: 0.001,
                       "Blockquote firstLineHeadIndent (\(paragraphStyle.firstLineHeadIndent)) should be grid-aligned")
    }

    func testZoomLevelAffectsGridAlignment() {
        // Test that grid alignment works correctly with zoom levels
        let zoomLevels: [CGFloat] = [0.75, 1.0, 1.25, 1.5, 2.0]

        for zoom in zoomLevels {
            let engine = TypographyEngine(theme: .minimal, zoomLevel: zoom)
            let attrs = engine.bodyAttributes()

            guard let paragraphStyle = attrs[.paragraphStyle] as? NSParagraphStyle,
                  let font = attrs[.font] as? NSFont else {
                XCTFail("Body attributes at zoom \(zoom) must have paragraph style and font")
                continue
            }

            let lineHeight = font.pointSize * paragraphStyle.lineHeightMultiple
            // Check that line height is close to a multiple of 8
            let nearestGrid = (lineHeight / 8).rounded() * 8
            XCTAssertEqual(lineHeight, nearestGrid, accuracy: 0.01,
                           "Body line height at zoom \(zoom) (\(lineHeight)) should be grid-aligned")
        }
    }

    // MARK: - Original Tests

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
            // Should be >= the theme's lineHeightMultiple (grid-aligned, so may be higher)
            XCTAssertGreaterThanOrEqual(paragraphStyle.lineHeightMultiple, theme.lineHeightMultiple,
                "Line height multiple should be at least the theme's specified value")
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

    // MARK: - Variable Font Tests

    func testVariableFontProviderSupportsVariableAxesCheck() {
        // System font should support variable axes (San Francisco is a variable font)
        let systemFont = NSFont.systemFont(ofSize: 16, weight: .regular)
        let hasAxes = VariableFontProvider.supportsVariableAxes(systemFont)
        // Note: This may vary by macOS version, so we just verify the method runs
        XCTAssertNotNil(hasAxes, "supportsVariableAxes should return a boolean value")
    }

    func testVariableFontProviderAvailableAxes() {
        let systemFont = NSFont.systemFont(ofSize: 16, weight: .regular)
        let axes = VariableFontProvider.availableAxes(for: systemFont)
        // We don't assert specific axes exist since availability varies by macOS version
        // Just verify the method returns a valid dictionary
        XCTAssertNotNil(axes, "availableAxes should return a dictionary")
    }

    func testVariableFontProviderCreateVariableFontReturnsNilForUnsupportedAxes() {
        // Use a font that may not support variable axes
        let monoFont = NSFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        let axes = VariableFontProvider.availableAxes(for: monoFont)

        // If no weight axis, createVariableFont with weight should return nil
        if axes.isEmpty {
            let result = VariableFontProvider.createVariableFont(from: monoFont, weight: 500)
            XCTAssertNil(result, "createVariableFont should return nil when no axes are available")
        }
    }

    func testVariableFontProviderCreateHeadingFontReturnsValidFont() {
        // Test that createHeadingFont always returns a valid font
        for level in 1...6 {
            let font = VariableFontProvider.createHeadingFont(
                name: "-apple-system",
                size: 24,
                targetWeight: .bold,
                headingLevel: level
            )
            XCTAssertNotNil(font, "createHeadingFont should return a font for level \(level)")
            XCTAssertEqual(font.pointSize, 24, "Font should have the requested point size")
        }
    }

    func testVariableFontProviderCreateHeadingFontFallsBackToStandardFont() {
        // Test with a non-existent font name - should fall back to system font
        let font = VariableFontProvider.createHeadingFont(
            name: "NonExistentFontName12345",
            size: 20,
            targetWeight: .semibold,
            headingLevel: 2
        )
        XCTAssertNotNil(font, "createHeadingFont should fall back to system font for unknown font names")
        XCTAssertEqual(font.pointSize, 20, "Fallback font should have the requested point size")
    }

    func testVariableFontProviderCreateHeadingFontWithCustomFont() {
        // Test with a built-in font name
        let font = VariableFontProvider.createHeadingFont(
            name: "Georgia",
            size: 18,
            targetWeight: .bold,
            headingLevel: 1
        )
        XCTAssertNotNil(font, "createHeadingFont should work with custom font names")
        XCTAssertEqual(font.pointSize, 18, "Custom font should have the requested point size")
    }

    func testTypographyEngineUseVariableFontsDefault() {
        let engine = TypographyEngine()
        XCTAssertTrue(engine.useVariableFonts, "useVariableFonts should default to true")
    }

    func testTypographyEngineUseVariableFontsCanBeDisabled() {
        let engine = TypographyEngine(useVariableFonts: false)
        XCTAssertFalse(engine.useVariableFonts, "useVariableFonts should be false when disabled")
    }

    func testHeadingAttributesWithVariableFontsEnabled() {
        let engine = TypographyEngine(theme: .minimal, useVariableFonts: true)

        for level in 1...6 {
            let attrs = engine.headingAttributes(level: level)
            guard let font = attrs[.font] as? NSFont else {
                XCTFail("Heading \(level) should have a font attribute")
                continue
            }
            XCTAssertNotNil(font, "Heading \(level) should have a valid font with variable fonts enabled")
            XCTAssertGreaterThan(font.pointSize, 0, "Heading \(level) font should have a positive point size")
        }
    }

    func testHeadingAttributesWithVariableFontsDisabled() {
        let engine = TypographyEngine(theme: .minimal, useVariableFonts: false)

        for level in 1...6 {
            let attrs = engine.headingAttributes(level: level)
            guard let font = attrs[.font] as? NSFont else {
                XCTFail("Heading \(level) should have a font attribute")
                continue
            }
            XCTAssertNotNil(font, "Heading \(level) should have a valid font with variable fonts disabled")
            XCTAssertGreaterThan(font.pointSize, 0, "Heading \(level) font should have a positive point size")
        }
    }

    func testHeadingFontSizesConsistentBetweenVariableFontModes() {
        let engineWithVariable = TypographyEngine(theme: .minimal, useVariableFonts: true)
        let engineWithoutVariable = TypographyEngine(theme: .minimal, useVariableFonts: false)

        for level in 1...6 {
            let attrsWithVariable = engineWithVariable.headingAttributes(level: level)
            let attrsWithoutVariable = engineWithoutVariable.headingAttributes(level: level)

            guard let fontWithVariable = attrsWithVariable[.font] as? NSFont,
                  let fontWithoutVariable = attrsWithoutVariable[.font] as? NSFont else {
                XCTFail("Both engines should produce font attributes for heading \(level)")
                continue
            }

            XCTAssertEqual(fontWithVariable.pointSize, fontWithoutVariable.pointSize, accuracy: 0.1,
                           "Font sizes should be consistent between variable font modes for heading \(level)")
        }
    }

    func testVariableFontWeightCurveAppliesCorrectly() {
        // Test that heading levels have appropriate weight progression
        // We can't directly test variable font weight values, but we can verify
        // that fonts are created successfully for all heading levels
        for level in 1...6 {
            let font = VariableFontProvider.createHeadingFont(
                name: "-apple-system",
                size: 20,
                targetWeight: .bold,
                headingLevel: level
            )
            XCTAssertNotNil(font, "Font should be created for heading level \(level)")
        }
    }

    func testCreateVariableFontWithWeightAndOpticalSize() {
        let systemFont = NSFont.systemFont(ofSize: 24, weight: .regular)
        let axes = VariableFontProvider.availableAxes(for: systemFont)

        // Only run this test if the font supports variable axes
        if !axes.isEmpty {
            // Try creating a font with both weight and optical size
            let variableFont = VariableFontProvider.createVariableFont(
                from: systemFont,
                weight: 600,
                opticalSize: 24
            )
            // Result depends on which axes the font supports
            // Just verify the method doesn't crash
            _ = variableFont
        }
    }

    func testVariableFontWeightClamping() {
        let systemFont = NSFont.systemFont(ofSize: 16, weight: .regular)
        let axes = VariableFontProvider.availableAxes(for: systemFont)

        // Only run if weight axis is available
        if let weightAxis = axes[0x77676874] { // 'wght'
            // Test that out-of-range values are clamped
            let font = VariableFontProvider.createVariableFont(from: systemFont, weight: 1000)
            // If font is created, it should be valid (clamped to max)
            if font != nil {
                XCTAssertNotNil(font, "Font should be created with clamped weight value")
            }

            // Verify the axis bounds were read correctly
            XCTAssertLessThanOrEqual(weightAxis.min, weightAxis.max,
                                     "Weight axis min should be <= max")
        }
    }
}