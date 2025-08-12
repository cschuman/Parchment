import Cocoa
import Quartz
import WebKit
import Markdown

class DocumentExporter {
    
    enum ExportFormat {
        case pdf
        case html
        case rtf
        case docx
        case plainText
    }
    
    enum ExportError: Error {
        case invalidDocument
        case renderingFailed
        case fileWriteFailed
    }
    
    private let htmlRenderer = HTMLRenderer()
    private var webView: WKWebView?
    
    init() {
        setupWebView()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.suppressesIncrementalRendering = true
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 1000), configuration: configuration)
    }
    
    func export(
        document: MarkdownDocument,
        to format: ExportFormat,
        at url: URL,
        options: ExportOptions = ExportOptions()
    ) async throws {
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
                
                let printOperation = webView.printOperation(with: printInfo)
                printOperation.showsPrintPanel = false
                printOperation.showsProgressPanel = false
                
                let pdfInfo = NSMutableDictionary()
                pdfInfo[kCGPDFContextTitle as String] = document.url?.lastPathComponent ?? "Untitled"
                pdfInfo[kCGPDFContextAuthor as String] = NSFullUserName()
                pdfInfo[kCGPDFContextCreator as String] = "Parchment"
                
                printOperation.pdfPanel.options = [.showsPaperSize, .showsOrientation]
                
                webView.evaluateJavaScript("document.documentElement.outerHTML") { html, error in
                    if error != nil {
                        continuation.resume(throwing: ExportError.renderingFailed)
                        return
                    }
                    
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
        let html = renderToHTML(document: document, options: options)
        
        let pandocTask = Process()
        pandocTask.executableURL = URL(fileURLWithPath: "/usr/local/bin/pandoc")
        pandocTask.arguments = [
            "-f", "html",
            "-t", "docx",
            "-o", url.path,
            "--standalone"
        ]
        
        let inputPipe = Pipe()
        pandocTask.standardInput = inputPipe
        
        try pandocTask.run()
        
        if let htmlData = html.data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(htmlData)
            inputPipe.fileHandleForWriting.closeFile()
        }
        
        pandocTask.waitUntilExit()
        
        if pandocTask.terminationStatus != 0 {
            throw ExportError.renderingFailed
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
        let parsedDocument = Document(parsing: document.content)
        let bodyHTML = htmlRenderer.render(parsedDocument)
        
        let css = generateCSS(for: options)
        let title = document.url?.deletingPathExtension().lastPathComponent ?? "Untitled"
        
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(title)</title>
            <style>\(css)</style>
            \(options.includeHighlightJS ? highlightJSIncludes() : "")
        </head>
        <body>
            <div class="container">
                \(options.includeHeader ? generateHeader(for: document) : "")
                <main>
                    \(bodyHTML)
                </main>
                \(options.includeFooter ? generateFooter(for: document, options: options) : "")
            </div>
            \(options.includeHighlightJS ? highlightJSScript() : "")
        </body>
        </html>
        """
    }
    
    private func generateCSS(for options: ExportOptions) -> String {
        return """
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        :root {
            --font-family: \(options.fontFamily);
            --font-size: \(options.fontSize)pt;
            --line-height: \(options.lineHeight);
            --text-color: \(options.theme == .light ? "#1d1d1f" : "#f5f5f7");
            --bg-color: \(options.theme == .light ? "#ffffff" : "#1d1d1f");
            --code-bg: \(options.theme == .light ? "#f5f5f7" : "#2d2d2f");
            --border-color: \(options.theme == .light ? "#d2d2d7" : "#424245");
            --link-color: \(options.theme == .light ? "#0066cc" : "#0a84ff");
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
            max-width: \(options.maxWidth)px;
            margin: 0 auto;
            padding: \(options.margins.top)pt \(options.margins.left)pt \(options.margins.bottom)pt \(options.margins.right)pt;
        }
        
        h1, h2, h3, h4, h5, h6 {
            margin-top: 1.5em;
            margin-bottom: 0.5em;
            font-weight: 600;
            line-height: 1.25;
        }
        
        h1 { font-size: 2.5em; border-bottom: 2px solid var(--border-color); padding-bottom: 0.3em; }
        h2 { font-size: 2em; border-bottom: 1px solid var(--border-color); padding-bottom: 0.2em; }
        h3 { font-size: 1.5em; }
        h4 { font-size: 1.25em; }
        h5 { font-size: 1.1em; }
        h6 { font-size: 1em; }
        
        p { margin-bottom: 1em; }
        
        code {
            background-color: var(--code-bg);
            padding: 2px 6px;
            border-radius: 4px;
            font-family: "SF Mono", Monaco, Consolas, monospace;
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
            border-radius: 8px;
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
        
        @media print {
            body {
                color: black;
                background-color: white;
            }
            
            .container {
                max-width: none;
            }
            
            pre, code {
                background-color: #f5f5f5;
            }
            
            a {
                color: black;
                text-decoration: underline;
            }
        }
        
        \(options.customCSS)
        """
    }
    
    private func generateHeader(for document: MarkdownDocument) -> String {
        let title = document.url?.deletingPathExtension().lastPathComponent ?? "Untitled"
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
        
        return """
        <header class="header">
            <h1>\(title)</h1>
            <p>\(date)</p>
        </header>
        """
    }
    
    private func generateFooter(for document: MarkdownDocument, options: ExportOptions) -> String {
        var footer = "<footer class=\"footer\">"
        
        if options.includePageNumbers {
            footer += "<p>Page <span class=\"page-number\"></span></p>"
        }
        
        if options.includeWordCount {
            footer += "<p>\(document.metadata.wordCount) words • \(document.metadata.estimatedReadingTime) min read</p>"
        }
        
        footer += "<p>Exported from Parchment</p>"
        footer += "</footer>"
        
        return footer
    }
    
    private func highlightJSIncludes() -> String {
        return """
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/github.min.css">
        <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
        """
    }
    
    private func highlightJSScript() -> String {
        return """
        <script>
            hljs.highlightAll();
        </script>
        """
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
    var includeHighlightJS: Bool = true
    var customCSS: String = ""
    
    enum Theme {
        case light
        case dark
    }
}