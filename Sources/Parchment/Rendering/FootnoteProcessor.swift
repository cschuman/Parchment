import Cocoa

/// Processes GFM-style footnotes in markdown text
/// Footnote references: [^1], [^note], [^long-identifier]
/// Footnote definitions: [^1]: Content of the footnote
final class FootnoteProcessor {

    // MARK: - Types

    struct FootnoteReference {
        let identifier: String
        let range: Range<String.Index>
    }

    struct FootnoteDefinition {
        let identifier: String
        let content: String
        let range: Range<String.Index>
    }

    struct ProcessedContent {
        let text: String
        let definitions: [String: FootnoteDefinition]
        let referenceOrder: [String]
    }

    // MARK: - Singleton

    static let shared = FootnoteProcessor()

    // MARK: - Cached Regex Patterns

    /// Matches footnote references like [^1], [^note], [^long-id]
    /// Pattern: [^identifier] where identifier is alphanumeric with hyphens
    private static let referencePattern = try? NSRegularExpression(
        pattern: "\\[\\^([a-zA-Z0-9_-]+)\\](?!:)",
        options: []
    )

    /// Matches footnote definitions like [^1]: Content here
    /// Captures: (1) identifier, (2) content until next definition or double newline
    private static let definitionPattern = try? NSRegularExpression(
        pattern: "^\\[\\^([a-zA-Z0-9_-]+)\\]:\\s*(.+?)(?=\\n\\[\\^|\\n\\n|$)",
        options: [.anchorsMatchLines, .dotMatchesLineSeparators]
    )

    // MARK: - Public Interface

    /// Find all footnote references in text
    func findReferences(in text: String) -> [FootnoteReference] {
        guard let regex = Self.referencePattern else { return [] }

        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        return matches.compactMap { match -> FootnoteReference? in
            guard let fullRange = Range(match.range, in: text),
                  let idRange = Range(match.range(at: 1), in: text) else {
                return nil
            }

            let identifier = String(text[idRange])
            return FootnoteReference(identifier: identifier, range: fullRange)
        }
    }

    /// Find all footnote definitions in text
    func findDefinitions(in text: String) -> [FootnoteDefinition] {
        guard let regex = Self.definitionPattern else { return [] }

        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

        return matches.compactMap { match -> FootnoteDefinition? in
            guard let fullRange = Range(match.range, in: text),
                  let idRange = Range(match.range(at: 1), in: text),
                  let contentRange = Range(match.range(at: 2), in: text) else {
                return nil
            }

            let identifier = String(text[idRange])
            let content = String(text[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            return FootnoteDefinition(identifier: identifier, content: content, range: fullRange)
        }
    }

    /// Process markdown text to extract footnote definitions and prepare for rendering
    /// Returns text with definitions removed (they will be rendered at the end)
    func process(_ text: String) -> ProcessedContent {
        let definitions = findDefinitions(in: text)
        let references = findReferences(in: text)

        // Build definition dictionary
        var definitionMap: [String: FootnoteDefinition] = [:]
        for def in definitions {
            definitionMap[def.identifier] = def
        }

        // Track reference order (for numbering) - only include references that have definitions
        var referenceOrder: [String] = []
        var seen = Set<String>()
        for ref in references {
            if !seen.contains(ref.identifier) && definitionMap[ref.identifier] != nil {
                seen.insert(ref.identifier)
                referenceOrder.append(ref.identifier)
            }
        }

        // Remove definitions from text (they will be rendered at the end)
        var cleanText = text
        // Sort by range in reverse order to avoid index shifting
        let sortedDefs = definitions.sorted { $0.range.lowerBound > $1.range.lowerBound }
        for def in sortedDefs {
            cleanText.removeSubrange(def.range)
        }

        // Clean up extra blank lines that may result from removing definitions
        cleanText = cleanText.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)

        return ProcessedContent(
            text: cleanText.trimmingCharacters(in: .whitespacesAndNewlines),
            definitions: definitionMap,
            referenceOrder: referenceOrder
        )
    }

    /// Get the display number for a footnote identifier based on order of first reference
    func displayNumber(for identifier: String, in order: [String]) -> Int {
        if let index = order.firstIndex(of: identifier) {
            return index + 1
        }
        return 0
    }
}

// MARK: - Footnote Rendering Support

extension FootnoteProcessor {

    /// Create attributed string for a footnote reference (superscript number)
    func renderReference(
        number: Int,
        identifier: String,
        theme: ParchmentTheme,
        baseFont: NSFont
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Create superscript style
        let superscriptSize = baseFont.pointSize * 0.7
        let superscriptFont = NSFont.systemFont(ofSize: superscriptSize, weight: .medium)

        // Create the footnote number with link-like styling
        let numberText = "[\(number)]"
        var attributes: [NSAttributedString.Key: Any] = [
            .font: superscriptFont,
            .foregroundColor: theme.linkColor,
            .baselineOffset: baseFont.pointSize * 0.35,
            // Store footnote ID for potential click handling
            .toolTip: "Footnote: \(identifier)"
        ]

        // Add underline for visual distinction
        attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        attributes[.underlineColor] = theme.linkColor.withAlphaComponent(0.5)

        result.append(NSAttributedString(string: numberText, attributes: attributes))

        return result
    }

    /// Create attributed string for the footnotes section at the end of document
    func renderFootnotesSection(
        definitions: [String: FootnoteDefinition],
        order: [String],
        theme: ParchmentTheme,
        zoomLevel: CGFloat
    ) -> NSAttributedString {
        guard !order.isEmpty else {
            return NSAttributedString()
        }

        let result = NSMutableAttributedString()

        // Add separator line
        let separatorAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: theme.blockquoteColor.withAlphaComponent(0.5),
            .font: NSFont.systemFont(ofSize: theme.baseFontSize * 0.8 * zoomLevel)
        ]
        result.append(NSAttributedString(string: "\n\n", attributes: separatorAttrs))

        // Horizontal rule
        let ruleLength = 30
        let rule = String(repeating: "\u{2500}", count: ruleLength) // Box drawing horizontal
        result.append(NSAttributedString(string: rule + "\n\n", attributes: separatorAttrs))

        // Footnotes header
        let headerFont = NSFont.systemFont(ofSize: theme.baseFontSize * 0.9 * zoomLevel, weight: .semibold)
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: headerFont,
            .foregroundColor: theme.headingColor
        ]
        result.append(NSAttributedString(string: "Footnotes\n\n", attributes: headerAttrs))

        // Render each footnote
        let bodyFont = NSFont.systemFont(ofSize: theme.baseFontSize * 0.85 * zoomLevel, weight: .regular)
        let numberFont = NSFont.systemFont(ofSize: theme.baseFontSize * 0.85 * zoomLevel, weight: .semibold)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 6
        paragraphStyle.headIndent = 20
        paragraphStyle.firstLineHeadIndent = 0

        for (index, identifier) in order.enumerated() {
            guard let definition = definitions[identifier] else { continue }

            let number = index + 1

            // Number
            let numberAttrs: [NSAttributedString.Key: Any] = [
                .font: numberFont,
                .foregroundColor: theme.linkColor,
                .paragraphStyle: paragraphStyle
            ]
            result.append(NSAttributedString(string: "[\(number)] ", attributes: numberAttrs))

            // Content
            let contentAttrs: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: theme.textColor,
                .paragraphStyle: paragraphStyle
            ]
            result.append(NSAttributedString(string: definition.content + "\n", attributes: contentAttrs))
        }

        return result
    }
}

// MARK: - HTML Rendering Support

extension FootnoteProcessor {

    /// Process markdown text for HTML rendering, replacing footnote references with HTML
    /// Returns the processed HTML-ready markdown and the footnotes HTML section
    func processForHTML(_ markdown: String) -> (processedMarkdown: String, footnotesHTML: String) {
        let processed = process(markdown)

        if processed.referenceOrder.isEmpty {
            return (markdown, "")
        }

        // Replace footnote references in text with HTML superscript links
        var result = processed.text
        let references = findReferences(in: result)

        // Process in reverse order to maintain string indices
        for ref in references.reversed() {
            if processed.definitions[ref.identifier] != nil {
                let number = displayNumber(for: ref.identifier, in: processed.referenceOrder)
                let htmlRef = "<sup id=\"fnref:\(ref.identifier)\"><a href=\"#fn:\(ref.identifier)\" class=\"footnote-ref\">[\(number)]</a></sup>"
                result.replaceSubrange(ref.range, with: htmlRef)
            }
        }

        // Generate footnotes section HTML
        let footnotesHTML = generateFootnotesHTML(
            definitions: processed.definitions,
            order: processed.referenceOrder
        )

        return (result, footnotesHTML)
    }

    /// Generate HTML for the footnotes section
    private func generateFootnotesHTML(
        definitions: [String: FootnoteDefinition],
        order: [String]
    ) -> String {
        guard !order.isEmpty else { return "" }

        var html = """
        <hr class="footnotes-sep">
        <section class="footnotes">
        <h4>Footnotes</h4>
        <ol class="footnotes-list">

        """

        for (_, identifier) in order.enumerated() {
            guard let definition = definitions[identifier] else { continue }

            // Escape HTML in content to prevent XSS
            let escapedContent = escapeHTML(definition.content)

            html += """
            <li id="fn:\(identifier)" class="footnote-item">
            <p>\(escapedContent) <a href="#fnref:\(identifier)" class="footnote-backref">&crarr;</a></p>
            </li>

            """
        }

        html += """
        </ol>
        </section>
        """

        return html
    }

    /// Escape HTML special characters
    private func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
