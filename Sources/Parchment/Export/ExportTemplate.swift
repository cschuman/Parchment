import Cocoa

/// Export template defining document styling for different use cases
public struct ExportTemplate: Equatable, Hashable {

    /// Template identifier
    public let id: String

    /// Display name for UI
    public let name: String

    /// Brief description of the template's purpose
    public let description: String

    /// Font family for body text
    public let bodyFont: String

    /// Font family for headings
    public let headingFont: String

    /// Font family for code blocks
    public let codeFont: String

    /// Base font size in points
    public let fontSize: Int

    /// Line height multiplier
    public let lineHeight: Double

    /// Page margins (top, right, bottom, left) in points
    public let margins: (top: CGFloat, right: CGFloat, bottom: CGFloat, left: CGFloat)

    /// Maximum content width in pixels (for HTML)
    public let maxWidth: Int

    /// Whether to show page numbers
    public let showPageNumbers: Bool

    /// Whether to show word count
    public let showWordCount: Bool

    /// Custom CSS for template-specific styling
    public let customCSS: String

    /// Header content generator (nil for no custom header)
    public let headerStyle: HeaderStyle

    /// Footer content generator (nil for no custom footer)
    public let footerStyle: FooterStyle

    // MARK: - Equatable

    public static func == (lhs: ExportTemplate, rhs: ExportTemplate) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Header/Footer Styles

    public enum HeaderStyle: Equatable, Hashable {
        case none
        case standard          // Title and date
        case academic          // Title, author placeholder, date
        case manuscript        // Title, word count, author placeholder
    }

    public enum FooterStyle: Equatable, Hashable {
        case none
        case standard          // Page number, exported from Parchment
        case academic          // Page number only, centered
        case manuscript        // Page number with author surname placeholder
    }
}

// MARK: - Built-in Templates

extension ExportTemplate {

    /// Default template - clean, versatile styling
    public static let standard = ExportTemplate(
        id: "standard",
        name: "Standard",
        description: "Clean, versatile styling for general use",
        bodyFont: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif",
        headingFont: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif",
        codeFont: "'SF Mono', Monaco, Consolas, monospace",
        fontSize: 12,
        lineHeight: 1.6,
        margins: (top: 72, right: 72, bottom: 72, left: 72),  // 1 inch
        maxWidth: 900,
        showPageNumbers: true,
        showWordCount: true,
        customCSS: "",
        headerStyle: .standard,
        footerStyle: .standard
    )

    /// Academic template - formal styling for papers and essays
    public static let academic = ExportTemplate(
        id: "academic",
        name: "Academic",
        description: "Serif fonts, double-spaced, Chicago/MLA style formatting",
        bodyFont: "'Times New Roman', Times, Georgia, 'Palatino Linotype', serif",
        headingFont: "'Times New Roman', Times, Georgia, 'Palatino Linotype', serif",
        codeFont: "'Courier New', Courier, monospace",
        fontSize: 12,
        lineHeight: 2.0,  // Double-spaced
        margins: (top: 72, right: 72, bottom: 72, left: 72),  // 1 inch margins
        maxWidth: 650,  // Narrower for academic formatting
        showPageNumbers: true,
        showWordCount: false,
        customCSS: ExportTemplate.academicCSS,
        headerStyle: .academic,
        footerStyle: .academic
    )

    /// GitHub template - GitHub-flavored markdown styling
    public static let github = ExportTemplate(
        id: "github",
        name: "GitHub",
        description: "GitHub-style markdown with syntax highlighting",
        bodyFont: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif",
        headingFont: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif",
        codeFont: "'SF Mono', 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace",
        fontSize: 14,
        lineHeight: 1.5,
        margins: (top: 32, right: 32, bottom: 32, left: 32),
        maxWidth: 980,
        showPageNumbers: false,
        showWordCount: false,
        customCSS: ExportTemplate.githubCSS,
        headerStyle: .none,
        footerStyle: .none
    )

    /// Manuscript template - traditional manuscript formatting
    public static let manuscript = ExportTemplate(
        id: "manuscript",
        name: "Manuscript",
        description: "Monospace font, wide margins, double-spaced for submissions",
        bodyFont: "'Courier New', Courier, 'Lucida Console', monospace",
        headingFont: "'Courier New', Courier, 'Lucida Console', monospace",
        codeFont: "'Courier New', Courier, monospace",
        fontSize: 12,
        lineHeight: 2.0,  // Double-spaced
        margins: (top: 72, right: 108, bottom: 72, left: 108),  // 1.5 inch left/right
        maxWidth: 600,  // Narrower for manuscript format
        showPageNumbers: true,
        showWordCount: true,
        customCSS: ExportTemplate.manuscriptCSS,
        headerStyle: .manuscript,
        footerStyle: .manuscript
    )

    /// All available templates
    public static let all: [ExportTemplate] = [
        .standard,
        .academic,
        .github,
        .manuscript
    ]

    /// Get template by ID
    public static func template(withId id: String) -> ExportTemplate? {
        all.first { $0.id == id }
    }
}

// MARK: - Template CSS Definitions

extension ExportTemplate {

    /// Academic template CSS
    private static let academicCSS: String = """
        /* Academic Template - Chicago/MLA Style */

        body {
            text-align: left;
            text-indent: 0;
        }

        /* First line indent for paragraphs (except first after heading) */
        p + p {
            text-indent: 0.5in;
        }

        h1 {
            text-align: center;
            font-weight: bold;
            font-size: 1em;
            margin-top: 0;
            margin-bottom: 2em;
            border: none;
            padding: 0;
        }

        h2 {
            font-weight: bold;
            font-size: 1em;
            margin-top: 2em;
            margin-bottom: 1em;
            border: none;
            padding: 0;
        }

        h3, h4, h5, h6 {
            font-weight: bold;
            font-style: italic;
            font-size: 1em;
            margin-top: 1.5em;
            margin-bottom: 1em;
        }

        blockquote {
            margin-left: 0.5in;
            margin-right: 0.5in;
            font-style: normal;
            border-left: none;
            padding-left: 0;
        }

        /* Block quotes over 4 lines should be indented */
        blockquote p {
            text-indent: 0;
        }

        /* Works Cited / Bibliography styling */
        .bibliography, .works-cited {
            margin-top: 2em;
        }

        .bibliography p, .works-cited p {
            text-indent: -0.5in;
            padding-left: 0.5in;
        }

        /* Footnotes */
        .footnotes {
            font-size: 0.9em;
            margin-top: 2em;
            padding-top: 1em;
            border-top: 1px solid #ccc;
        }

        /* Page break before major sections */
        .page-break {
            page-break-before: always;
        }

        /* Academic header */
        .academic-header {
            text-align: right;
            margin-bottom: 2em;
        }

        .academic-header .author {
            display: block;
        }

        .academic-header .course {
            display: block;
        }

        .academic-header .date {
            display: block;
        }

        @media print {
            body {
                orphans: 3;
                widows: 3;
            }

            h1, h2, h3 {
                page-break-after: avoid;
            }

            blockquote, pre {
                page-break-inside: avoid;
            }
        }
        """

    /// GitHub template CSS
    private static let githubCSS: String = """
        /* GitHub Markdown CSS */

        body {
            color: #1f2328;
            background-color: #ffffff;
        }

        h1, h2, h3, h4, h5, h6 {
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }

        h1 {
            font-size: 2em;
            padding-bottom: 0.3em;
            border-bottom: 1px solid #d1d9e0;
        }

        h2 {
            font-size: 1.5em;
            padding-bottom: 0.3em;
            border-bottom: 1px solid #d1d9e0;
        }

        h3 { font-size: 1.25em; }
        h4 { font-size: 1em; }
        h5 { font-size: 0.875em; }
        h6 { font-size: 0.85em; color: #656d76; }

        p {
            margin-top: 0;
            margin-bottom: 16px;
        }

        a {
            color: #0969da;
            text-decoration: none;
        }

        a:hover {
            text-decoration: underline;
        }

        code {
            padding: 0.2em 0.4em;
            margin: 0;
            font-size: 85%;
            white-space: break-spaces;
            background-color: rgba(175, 184, 193, 0.2);
            border-radius: 6px;
        }

        pre {
            padding: 16px;
            overflow: auto;
            font-size: 85%;
            line-height: 1.45;
            background-color: #f6f8fa;
            border-radius: 6px;
            margin-top: 0;
            margin-bottom: 16px;
        }

        pre code {
            padding: 0;
            background-color: transparent;
            border-radius: 0;
        }

        /* GitHub syntax highlighting colors */
        .hljs-keyword, .hljs-selector-tag { color: #cf222e; }
        .hljs-string, .hljs-attr { color: #0a3069; }
        .hljs-comment { color: #6e7781; font-style: italic; }
        .hljs-number { color: #0550ae; }
        .hljs-built_in { color: #8250df; }
        .hljs-function { color: #8250df; }
        .hljs-type, .hljs-class { color: #953800; }
        .hljs-variable { color: #e16f24; }

        blockquote {
            padding: 0 1em;
            color: #656d76;
            border-left: 0.25em solid #d1d9e0;
            margin: 0 0 16px 0;
        }

        blockquote > :first-child {
            margin-top: 0;
        }

        blockquote > :last-child {
            margin-bottom: 0;
        }

        table {
            border-spacing: 0;
            border-collapse: collapse;
            display: block;
            width: max-content;
            max-width: 100%;
            overflow: auto;
            margin-top: 0;
            margin-bottom: 16px;
        }

        th, td {
            padding: 6px 13px;
            border: 1px solid #d1d9e0;
        }

        th {
            font-weight: 600;
            background-color: #f6f8fa;
        }

        tr:nth-child(2n) {
            background-color: #f6f8fa;
        }

        img {
            max-width: 100%;
            box-sizing: border-box;
            background-color: #ffffff;
        }

        hr {
            height: 0.25em;
            padding: 0;
            margin: 24px 0;
            background-color: #d1d9e0;
            border: 0;
        }

        ul, ol {
            padding-left: 2em;
            margin-top: 0;
            margin-bottom: 16px;
        }

        li + li {
            margin-top: 0.25em;
        }

        li > p {
            margin-top: 16px;
        }

        /* Task list styling */
        .task-list-item {
            list-style-type: none;
        }

        .task-list-item input {
            margin: 0 0.2em 0.25em -1.6em;
            vertical-align: middle;
        }

        /* GitHub-style alerts */
        .markdown-alert {
            padding: 0.5rem 1rem;
            margin-bottom: 16px;
            color: inherit;
            border-left: 0.25rem solid;
            border-radius: 6px;
        }

        .markdown-alert-note {
            border-color: #0969da;
            background-color: #ddf4ff;
        }

        .markdown-alert-tip {
            border-color: #1a7f37;
            background-color: #dafbe1;
        }

        .markdown-alert-important {
            border-color: #8250df;
            background-color: #fbefff;
        }

        .markdown-alert-warning {
            border-color: #9a6700;
            background-color: #fff8c5;
        }

        .markdown-alert-caution {
            border-color: #cf222e;
            background-color: #ffebe9;
        }

        @media print {
            body {
                color: #000000;
            }

            a {
                color: #000000;
            }

            pre, code {
                background-color: #f0f0f0;
            }
        }
        """

    /// Manuscript template CSS
    private static let manuscriptCSS: String = """
        /* Manuscript Template - Standard Submission Format */

        body {
            text-align: left;
        }

        /* Title page styling */
        .manuscript-header {
            text-align: left;
            margin-bottom: 3in;
        }

        .manuscript-header .title {
            text-align: center;
            font-weight: normal;
            text-transform: uppercase;
            margin-top: 3in;
        }

        .manuscript-header .byline {
            text-align: center;
            margin-top: 1em;
        }

        .manuscript-header .contact {
            position: absolute;
            top: 1in;
            left: 1in;
        }

        .manuscript-header .wordcount {
            position: absolute;
            top: 1in;
            right: 1in;
            text-align: right;
        }

        h1 {
            text-align: center;
            font-weight: normal;
            font-size: 1em;
            text-transform: uppercase;
            margin-top: 0;
            margin-bottom: 2em;
            border: none;
            padding: 0;
            page-break-before: always;
        }

        h1:first-of-type {
            page-break-before: avoid;
        }

        h2 {
            font-weight: bold;
            font-size: 1em;
            margin-top: 2em;
            margin-bottom: 1em;
            border: none;
            padding: 0;
        }

        h3, h4, h5, h6 {
            font-weight: normal;
            font-style: italic;
            font-size: 1em;
        }

        /* First line indent */
        p {
            text-indent: 0.5in;
            margin-bottom: 0;
        }

        /* No indent after headings, blockquotes, or section breaks */
        h1 + p, h2 + p, h3 + p, h4 + p, h5 + p, h6 + p,
        blockquote + p,
        .scene-break + p {
            text-indent: 0;
        }

        /* Scene breaks */
        .scene-break, hr {
            text-align: center;
            border: none;
            margin: 2em 0;
        }

        .scene-break::before, hr::before {
            content: "#";
            display: block;
        }

        /* Block quotes */
        blockquote {
            margin-left: 0.5in;
            margin-right: 0.5in;
            font-style: normal;
            border-left: none;
            padding-left: 0;
        }

        blockquote p {
            text-indent: 0;
        }

        /* Emphasis */
        em, i {
            text-decoration: underline;
            font-style: normal;
        }

        strong, b {
            font-weight: normal;
            text-transform: uppercase;
        }

        /* Running header */
        .running-header {
            position: running(header);
            font-size: 0.9em;
        }

        .running-header .surname {
            text-transform: uppercase;
        }

        @page {
            @top-right {
                content: element(header);
            }
        }

        /* Word count styling */
        .word-count {
            text-align: right;
            margin-bottom: 2em;
        }

        /* End marker */
        .the-end {
            text-align: center;
            margin-top: 2em;
        }

        .the-end::before {
            content: "THE END";
        }

        @media print {
            body {
                orphans: 3;
                widows: 3;
            }

            h1 {
                page-break-before: always;
            }

            h1:first-of-type {
                page-break-before: avoid;
            }
        }
        """
}

// MARK: - CSS Generation

extension ExportTemplate {

    /// Generate complete CSS for this template
    /// - Parameter options: Export options for additional customization
    /// - Returns: Complete CSS string
    func generateCSS(with options: ExportOptions) -> String {
        let themeColors = options.theme == .dark ? darkThemeColors : lightThemeColors

        return """
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --font-family: \(bodyFont);
            --heading-font: \(headingFont);
            --code-font: \(codeFont);
            --font-size: \(fontSize)pt;
            --line-height: \(lineHeight);
            --text-color: \(themeColors.text);
            --bg-color: \(themeColors.background);
            --code-bg: \(themeColors.codeBackground);
            --border-color: \(themeColors.border);
            --link-color: \(themeColors.link);
        }

        body {
            font-family: var(--font-family);
            font-size: var(--font-size);
            line-height: var(--line-height);
            color: var(--text-color);
            background-color: var(--bg-color);
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }

        .container {
            max-width: \(maxWidth)px;
            margin: 0 auto;
            padding: \(margins.top)pt \(margins.right)pt \(margins.bottom)pt \(margins.left)pt;
        }

        h1, h2, h3, h4, h5, h6 {
            font-family: var(--heading-font);
            margin-top: 1.5em;
            margin-bottom: 0.5em;
            font-weight: 600;
            line-height: 1.25;
        }

        h1 { font-size: 2em; border-bottom: 2px solid var(--border-color); padding-bottom: 0.3em; }
        h2 { font-size: 1.5em; border-bottom: 1px solid var(--border-color); padding-bottom: 0.2em; }
        h3 { font-size: 1.25em; }
        h4 { font-size: 1.1em; }
        h5 { font-size: 1em; }
        h6 { font-size: 0.9em; }

        p { margin-bottom: 1em; }

        code {
            font-family: var(--code-font);
            background-color: var(--code-bg);
            padding: 2px 6px;
            border-radius: 4px;
            font-size: 0.9em;
        }

        pre {
            background-color: var(--code-bg);
            padding: 16px;
            border-radius: 8px;
            overflow-x: auto;
            margin: 1em 0;
        }

        pre code {
            background-color: transparent;
            padding: 0;
            font-size: 0.875em;
        }

        blockquote {
            border-left: 4px solid var(--border-color);
            margin: 1em 0;
            padding-left: 1em;
            opacity: 0.8;
        }

        a {
            color: var(--link-color);
            text-decoration: none;
        }

        a:hover { text-decoration: underline; }

        table {
            border-collapse: collapse;
            width: 100%;
            margin: 1em 0;
        }

        th, td {
            border: 1px solid var(--border-color);
            padding: 8px 12px;
            text-align: left;
        }

        th {
            background-color: var(--code-bg);
            font-weight: 600;
        }

        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 1em 0;
            border-radius: 4px;
        }

        hr {
            border: none;
            border-top: 2px solid var(--border-color);
            margin: 2em 0;
        }

        ul, ol {
            padding-left: 2em;
            margin: 1em 0;
        }

        li { margin: 0.25em 0; }

        .header {
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 1em;
            margin-bottom: 2em;
        }

        .footer {
            border-top: 1px solid var(--border-color);
            padding-top: 1em;
            margin-top: 2em;
            font-size: 0.875em;
            opacity: 0.7;
        }

        /* Footnote styles */
        .footnotes-sep { margin-top: 2em; margin-bottom: 1em; }
        .footnotes { font-size: 0.875em; }
        .footnotes h4 { font-size: 1em; margin-bottom: 0.5em; }
        .footnotes-list { padding-left: 1.5em; }
        .footnote-item { margin: 0.5em 0; }
        .footnote-ref { font-size: 0.75em; vertical-align: super; text-decoration: none; color: var(--link-color); }
        .footnote-backref { text-decoration: none; margin-left: 0.25em; }

        @media print {
            body { color: black; background-color: white; }
            .container { max-width: none; }
            pre, code { background-color: #f5f5f5; }
            a { color: black; text-decoration: underline; }
        }

        /* Template-specific styles */
        \(customCSS)

        /* User custom CSS */
        \(options.customCSS)
        """
    }

    // MARK: - Theme Colors

    private struct ThemeColors {
        let text: String
        let background: String
        let codeBackground: String
        let border: String
        let link: String
    }

    private var lightThemeColors: ThemeColors {
        ThemeColors(
            text: "#1d1d1f",
            background: "#ffffff",
            codeBackground: "#f5f5f5",
            border: "#d2d2d7",
            link: "#0066cc"
        )
    }

    private var darkThemeColors: ThemeColors {
        ThemeColors(
            text: "#f5f5f7",
            background: "#1d1d1f",
            codeBackground: "#2d2d2f",
            border: "#424245",
            link: "#0a84ff"
        )
    }
}

// MARK: - Header/Footer Generation

extension ExportTemplate {

    /// Generate HTML header based on template style
    /// - Parameters:
    ///   - document: The markdown document
    ///   - wordCount: Document word count
    /// - Returns: HTML string for header section
    func generateHeader(for document: MarkdownDocument, wordCount: Int) -> String {
        let title = escapeHTML(document.url?.deletingPathExtension().lastPathComponent ?? "Untitled")
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)

        switch headerStyle {
        case .none:
            return ""

        case .standard:
            return """
            <header class="header">
                <h1>\(title)</h1>
                <p>\(escapeHTML(date))</p>
            </header>
            """

        case .academic:
            return """
            <header class="header academic-header">
                <p class="author">[Author Name]</p>
                <p class="course">[Course/Institution]</p>
                <p class="instructor">[Instructor Name]</p>
                <p class="date">\(escapeHTML(date))</p>
                <h1 class="title">\(title)</h1>
            </header>
            """

        case .manuscript:
            return """
            <header class="header manuscript-header">
                <div class="contact">
                    <p>[Author Name]</p>
                    <p>[Address]</p>
                    <p>[Email]</p>
                </div>
                <div class="wordcount">
                    <p>Approx. \(formatWordCount(wordCount)) words</p>
                </div>
                <h1 class="title">\(title)</h1>
                <p class="byline">by [Author Name]</p>
            </header>
            """
        }
    }

    /// Generate HTML footer based on template style
    /// - Parameters:
    ///   - document: The markdown document
    ///   - wordCount: Document word count
    ///   - readingTime: Estimated reading time in minutes
    /// - Returns: HTML string for footer section
    func generateFooter(for document: MarkdownDocument, wordCount: Int, readingTime: Int) -> String {
        switch footerStyle {
        case .none:
            return ""

        case .standard:
            var footer = "<footer class=\"footer\">"
            if showPageNumbers {
                footer += "<p>Page <span class=\"page-number\"></span></p>"
            }
            if showWordCount {
                footer += "<p>\(wordCount) words &bull; \(readingTime) min read</p>"
            }
            footer += "<p>Exported from Parchment</p>"
            footer += "</footer>"
            return footer

        case .academic:
            return """
            <footer class="footer academic-footer">
                <p class="page-number-academic"></p>
            </footer>
            """

        case .manuscript:
            return """
            <footer class="footer manuscript-footer">
                <p class="running-header"><span class="surname">[SURNAME]</span> / <span class="page-number"></span></p>
            </footer>
            """
        }
    }

    // MARK: - Helpers

    private func escapeHTML(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&#x27;")
        return result
    }

    private func formatWordCount(_ count: Int) -> String {
        // Round to nearest 100 for manuscript format
        let rounded = ((count + 50) / 100) * 100
        return NumberFormatter.localizedString(from: NSNumber(value: rounded), number: .decimal)
    }
}
