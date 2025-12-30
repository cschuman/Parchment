import Cocoa
import QuickLookUI
import Markdown

@objc class QuickLookExtension: NSObject, QLPreviewingController {
    
    override init() {
        super.init()
    }
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let html = self.renderMarkdownToHTML(content)
                
                DispatchQueue.main.async {
                    self.createPreview(html: html, for: url)
                    handler(nil)
                }
            } catch {
                handler(error)
            }
        }
    }
    
    private func renderMarkdownToHTML(_ markdown: String) -> String {
        let document = Document(parsing: markdown)
        let htmlRenderer = HTMLRenderer()
        let html = htmlRenderer.render(document)
        
        return wrapInHTMLTemplate(html)
    }
    
    private func wrapInHTMLTemplate(_ content: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src data: https:;">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                :root {
                    --text-color: #1d1d1f;
                    --bg-color: #ffffff;
                    --code-bg: #f5f5f7;
                    --border-color: #d2d2d7;
                    --link-color: #0066cc;
                    --heading-color: #1d1d1f;
                }
                
                @media (prefers-color-scheme: dark) {
                    :root {
                        --text-color: #f5f5f7;
                        --bg-color: #1d1d1f;
                        --code-bg: #2d2d2f;
                        --border-color: #424245;
                        --link-color: #0a84ff;
                        --heading-color: #f5f5f7;
                    }
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
                    line-height: 1.6;
                    color: var(--text-color);
                    background-color: var(--bg-color);
                    max-width: 900px;
                    margin: 0 auto;
                    padding: 40px 20px;
                }
                
                h1, h2, h3, h4, h5, h6 {
                    color: var(--heading-color);
                    margin-top: 1.5em;
                    margin-bottom: 0.5em;
                    font-weight: 600;
                }
                
                h1 { font-size: 2.5em; border-bottom: 2px solid var(--border-color); padding-bottom: 0.3em; }
                h2 { font-size: 2em; border-bottom: 1px solid var(--border-color); padding-bottom: 0.2em; }
                h3 { font-size: 1.5em; }
                h4 { font-size: 1.25em; }
                h5 { font-size: 1.1em; }
                h6 { font-size: 1em; }
                
                code {
                    background-color: var(--code-bg);
                    padding: 2px 6px;
                    border-radius: 4px;
                    font-family: "SF Mono", Monaco, Consolas, "Courier New", monospace;
                    font-size: 0.9em;
                }
                
                pre {
                    background-color: var(--code-bg);
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                    line-height: 1.4;
                }
                
                pre code {
                    background-color: transparent;
                    padding: 0;
                }
                
                blockquote {
                    border-left: 4px solid var(--border-color);
                    margin: 1em 0;
                    padding-left: 1em;
                    color: color-mix(in srgb, var(--text-color) 70%, transparent);
                }
                
                a {
                    color: var(--link-color);
                    text-decoration: none;
                }
                
                a:hover {
                    text-decoration: underline;
                }
                
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
                
                li {
                    margin: 0.25em 0;
                }
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
    }
    
    private func createPreview(html: String, for url: URL) {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("html")
        
        do {
            try html.write(to: tempURL, atomically: true, encoding: .utf8)
        } catch {
            Logger.error("Failed to write preview HTML: \(error)")
        }
    }
}