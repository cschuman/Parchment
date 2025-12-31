import Cocoa
import Quartz
import WebKit
import Markdown

final class DocumentExporter {

    enum ExportFormat {
        case pdf
        case html
        case rtf
        case docx
        case plainText
    }

    enum ExportError: Error, LocalizedError {
        case invalidDocument
        case renderingFailed
        case fileWriteFailed
        case pandocNotFound
        case invalidOutputPath
        case pandocExecutionFailed(Int32)

        var errorDescription: String? {
            switch self {
            case .invalidDocument:
                return "Invalid document"
            case .renderingFailed:
                return "Rendering failed"
            case .fileWriteFailed:
                return "Failed to write file"
            case .pandocNotFound:
                return "Pandoc is not installed at the expected location"
            case .invalidOutputPath:
                return "Invalid output path"
            case .pandocExecutionFailed(let code):
                return "Pandoc failed with exit code \(code)"
            }
        }
    }

    private let htmlRenderer = HTMLRenderer()
    private var webView: WKWebView?

    init() {
        setupWebView()
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true

        // Security: Disable JavaScript execution in export WebView
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false
        configuration.defaultWebpagePreferences = preferences

        // Additional security settings
        configuration.preferences.isElementFullscreenEnabled = false

        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 1000), configuration: configuration)
    }

    func export(
        document: MarkdownDocument,
        to format: ExportFormat,
        at url: URL,
        options: ExportOptions = ExportOptions()
    ) async throws {
        // Security: Validate output path
        try validateOutputPath(url)

        switch format {
        case .pdf:
            try await exportToPDF(document: document, to: url, options: options)
        case .html:
            try exportToHTML(document: document, to: url, options: options)
        case .rtf:
            try exportToRTF(document: document, to: url, options: options)
        case .docx:
            try await exportToDOCX(document: document, to: url, options: options)
        case .plainText:
            try exportToPlainText(document: document, to: url)
        }
    }

    // MARK: - Security Validation

    private func validateOutputPath(_ url: URL) throws {
        // Must be a file URL
        guard url.isFileURL else {
            throw ExportError.invalidOutputPath
        }

        let path = url.path
        let filename = url.lastPathComponent

        // Block filenames starting with dash (command-line flag injection prevention)
        if filename.hasPrefix("-") {
            throw ExportError.invalidOutputPath
        }

        // Block paths containing equals sign (argument injection prevention)
        if path.contains("=") {
            throw ExportError.invalidOutputPath
        }

        // Path must not contain shell metacharacters or control characters
        let dangerousChars = CharacterSet(charactersIn: ";|&$`\"'\\<>(){}[]!#~\0\n\r")
        if path.unicodeScalars.contains(where: { dangerousChars.contains($0) }) {
            throw ExportError.invalidOutputPath
        }

        // Block paths with Unicode normalization tricks
        let normalized = path.precomposedStringWithCanonicalMapping
        if normalized != path {
            throw ExportError.invalidOutputPath
        }

        // Path must be absolute
        guard path.hasPrefix("/") else {
            throw ExportError.invalidOutputPath
        }

        // Check parent directory exists and is writable
        let parentDir = url.deletingLastPathComponent().path
        guard FileManager.default.isWritableFile(atPath: parentDir) else {
            throw ExportError.fileWriteFailed
        }
    }

    private static func escapeHTML(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&#x27;")
        return result
    }

    // MARK: - Export Implementations

    private func exportToPDF(
        document: MarkdownDocument,
        to url: URL,
        options: ExportOptions
    ) async throws {
        let html = renderToHTML(document: document, options: options)

        guard let webView = webView else {
            throw ExportError.renderingFailed
        }

        await MainActor.run {
            webView.loadHTMLString(html, baseURL: nil)
        }

        try await Task.sleep(nanoseconds: 500_000_000)

        let pdfData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            DispatchQueue.main.async {
                let printInfo = NSPrintInfo()
                printInfo.paperSize = options.paperSize
                printInfo.topMargin = options.margins.top
                printInfo.bottomMargin = options.margins.bottom
                printInfo.leftMargin = options.margins.left
                printInfo.rightMargin = options.margins.right

                webView.createPDF(configuration: WKPDFConfiguration()) { result in
                    switch result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }

        try pdfData.write(to: url)
    }

    private func exportToHTML(
        document: MarkdownDocument,
        to url: URL,
        options: ExportOptions
    ) throws {
        let html = renderToHTML(document: document, options: options)
        try html.write(to: url, atomically: true, encoding: .utf8)
    }

    private func exportToRTF(
        document: MarkdownDocument,
        to url: URL,
        options: ExportOptions
    ) throws {
        let html = renderToHTML(document: document, options: options)

        guard let htmlData = html.data(using: .utf8),
              let attributedString = NSAttributedString(
                html: htmlData,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
              ) else {
            throw ExportError.renderingFailed
        }

        let rtfData = try attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )

        try rtfData.write(to: url)
    }

    private func exportToDOCX(
        document: MarkdownDocument,
        to url: URL,
        options: ExportOptions
    ) async throws {
        // Security: Use fixed pandoc paths only
        let pandocPaths = [
            "/usr/local/bin/pandoc",
            "/opt/homebrew/bin/pandoc",
            "/usr/bin/pandoc"
        ]

        var pandocPath: String?
        for path in pandocPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                pandocPath = path
                break
            }
        }

        guard let executablePath = pandocPath else {
            throw ExportError.pandocNotFound
        }

        let html = renderToHTML(document: document, options: options)

        let pandocTask = Process()
        pandocTask.executableURL = URL(fileURLWithPath: executablePath)

        // Security: Use stdin for HTML content, only pass output path as argument
        // The output path has already been validated in validateOutputPath
        pandocTask.arguments = [
            "-f", "html",
            "-t", "docx",
            "-o", url.path,
            "--standalone"
        ]

        let inputPipe = Pipe()
        let errorPipe = Pipe()
        pandocTask.standardInput = inputPipe
        pandocTask.standardError = errorPipe

        try pandocTask.run()

        if let htmlData = html.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(htmlData)
            inputPipe.fileHandleForWriting.closeFile()
        }

        pandocTask.waitUntilExit()

        if pandocTask.terminationStatus != 0 {
            throw ExportError.pandocExecutionFailed(pandocTask.terminationStatus)
        }
    }

    private func exportToPlainText(
        document: MarkdownDocument,
        to url: URL
    ) throws {
        try document.content.write(to: url, atomically: true, encoding: .utf8)
    }

    private func renderToHTML(
        document: MarkdownDocument,
        options: ExportOptions
    ) -> String {
        // Process footnotes before parsing
        let footnoteProcessor = FootnoteProcessor.shared
        let (processedMarkdown, footnotesHTML) = footnoteProcessor.processForHTML(document.content)

        let parsedDocument = Document(parsing: processedMarkdown)
        let bodyHTML = htmlRenderer.render(parsedDocument) + footnotesHTML

        let css = generateCSS(for: options)
        // Security: Escape title to prevent XSS
        let rawTitle = document.url?.deletingPathExtension().lastPathComponent ?? "Untitled"
        let title = Self.escapeHTML(rawTitle)

        // Security: Add Content Security Policy meta tag
        let csp = "default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; script-src 'none';"

        // Generate header/footer using template
        let headerHTML = options.includeHeader
            ? options.template.generateHeader(for: document, wordCount: document.metadata.wordCount)
            : ""
        let footerHTML = options.includeFooter
            ? options.template.generateFooter(for: document, wordCount: document.metadata.wordCount, readingTime: document.metadata.estimatedReadingTime)
            : ""

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <meta http-equiv="Content-Security-Policy" content="\(csp)">
            <title>\(title)</title>
            <style>\(css)</style>
        </head>
        <body>
            <div class="container">
                \(headerHTML)
                <main>
                    \(bodyHTML)
                </main>
                \(footerHTML)
            </div>
        </body>
        </html>
        """
    }

    private func generateCSS(for options: ExportOptions) -> String {
        // Use template CSS if a template is selected
        return options.template.generateCSS(with: options)
    }

    // MARK: - Preview Generation

    /// Generate HTML preview string for display in preview panel
    /// - Parameters:
    ///   - document: The markdown document to preview
    ///   - options: Export options affecting rendering
    /// - Returns: Complete HTML string ready for display
    func generateHTMLPreview(document: MarkdownDocument, options: ExportOptions) -> String {
        return renderToHTML(document: document, options: options)
    }

    /// Generate PDF data for preview display
    /// - Parameters:
    ///   - document: The markdown document to preview
    ///   - options: Export options affecting rendering
    /// - Returns: PDF data that can be loaded into a PDFView
    /// - Throws: ExportError if rendering fails
    func generatePDFPreview(document: MarkdownDocument, options: ExportOptions) async throws -> Data {
        let html = renderToHTML(document: document, options: options)

        guard let webView = webView else {
            throw ExportError.renderingFailed
        }

        await MainActor.run {
            webView.loadHTMLString(html, baseURL: nil)
        }

        // Wait for content to load
        try await Task.sleep(nanoseconds: 500_000_000)

        let pdfData = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            DispatchQueue.main.async {
                let config = WKPDFConfiguration()
                config.rect = CGRect(
                    x: 0,
                    y: 0,
                    width: options.paperSize.width,
                    height: options.paperSize.height
                )

                webView.createPDF(configuration: config) { result in
                    switch result {
                    case .success(let data):
                        continuation.resume(returning: data)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }

        return pdfData
    }

    /// Generate RTF attributed string for preview display
    /// - Parameters:
    ///   - document: The markdown document to preview
    ///   - options: Export options affecting rendering
    /// - Returns: Attributed string that can be displayed in an NSTextView
    /// - Throws: ExportError if rendering fails
    func generateRTFPreview(document: MarkdownDocument, options: ExportOptions) throws -> NSAttributedString {
        let html = renderToHTML(document: document, options: options)

        guard let htmlData = html.data(using: .utf8),
              let attributedString = NSAttributedString(
                html: htmlData,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
              ) else {
            throw ExportError.renderingFailed
        }

        return attributedString
    }
}

struct ExportOptions {
    var format: DocumentExporter.ExportFormat = .pdf
    var paperSize: NSSize = NSSize(width: 612, height: 792)
    var margins: (top: CGFloat, right: CGFloat, bottom: CGFloat, left: CGFloat) = (72, 72, 72, 72)
    var fontSize: Int = 12
    var fontFamily: String = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif"
    var lineHeight: Double = 1.6
    var maxWidth: Int = 900
    var theme: Theme = .light
    var includeHeader: Bool = true
    var includeFooter: Bool = true
    var includePageNumbers: Bool = true
    var includeWordCount: Bool = true
    var customCSS: String = ""
    var template: ExportTemplate = .standard

    enum Theme {
        case light
        case dark
    }

    /// Apply template settings to these options
    mutating func applyTemplate(_ template: ExportTemplate) {
        self.template = template
        self.margins = template.margins
        self.fontSize = template.fontSize
        self.fontFamily = template.bodyFont
        self.lineHeight = template.lineHeight
        self.maxWidth = template.maxWidth
        self.includePageNumbers = template.showPageNumbers
        self.includeWordCount = template.showWordCount
        self.includeHeader = template.headerStyle != .none
        self.includeFooter = template.footerStyle != .none
    }
}
