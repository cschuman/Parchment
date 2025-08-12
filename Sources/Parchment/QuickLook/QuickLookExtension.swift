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
            print("Failed to write preview HTML: \(error)")
        }
    }
}

class HTMLRenderer {
    var html = ""
    private var listDepth = 0
    private var orderedListCounters: [Int] = []
    
    func render(_ document: Document) -> String {
        html = ""
        visit(document)
        return html
    }
    
    func visit(_ markup: Markup) {
        switch markup {
        case let node as Document:
            visitDocument(node)
        case let node as Heading:
            visitHeading(node)
        case let node as Paragraph:
            visitParagraph(node)
        case let node as Text:
            visitText(node)
        case let node as Strong:
            visitStrong(node)
        case let node as Emphasis:
            visitEmphasis(node)
        case let node as InlineCode:
            visitInlineCode(node)
        case let node as CodeBlock:
            visitCodeBlock(node)
        case let node as Link:
            visitLink(node)
        case let node as Image:
            visitImage(node)
        case let node as UnorderedList:
            visitUnorderedList(node)
        case let node as OrderedList:
            visitOrderedList(node)
        case let node as ListItem:
            visitListItem(node)
        case let node as BlockQuote:
            visitBlockQuote(node)
        case let node as ThematicBreak:
            visitThematicBreak(node)
        case let node as Table:
            visitTable(node)
        default:
            visitChildren(of: markup)
        }
    }
    
    func visitDocument(_ document: Document) {
        visitChildren(of: document)
    }
    
    func visitHeading(_ heading: Heading) {
        let level = heading.level
        html += "<h\(level)>"
        visitChildren(of: heading)
        html += "</h\(level)>\n"
    }
    
    func visitParagraph(_ paragraph: Paragraph) {
        html += "<p>"
        visitChildren(of: paragraph)
        html += "</p>\n"
    }
    
    func visitText(_ text: Text) {
        html += escapeHTML(text.string)
    }
    
    func visitStrong(_ strong: Strong) {
        html += "<strong>"
        visitChildren(of: strong)
        html += "</strong>"
    }
    
    func visitEmphasis(_ emphasis: Emphasis) {
        html += "<em>"
        visitChildren(of: emphasis)
        html += "</em>"
    }
    
    func visitInlineCode(_ inlineCode: InlineCode) {
        html += "<code>\(escapeHTML(inlineCode.code))</code>"
    }
    
    func visitCodeBlock(_ codeBlock: CodeBlock) {
        html += "<pre><code"
        if let language = codeBlock.language {
            html += " class=\"language-\(language)\""
        }
        html += ">"
        html += escapeHTML(codeBlock.code)
        html += "</code></pre>\n"
    }
    
    func visitLink(_ link: Link) {
        html += "<a href=\"\(escapeHTML(link.destination ?? ""))\">"
        visitChildren(of: link)
        html += "</a>"
    }
    
    func visitImage(_ image: Image) {
        html += "<img src=\"\(escapeHTML(image.source ?? ""))\""
        if let title = image.title {
            html += " alt=\"\(escapeHTML(title))\""
        }
        html += ">"
    }
    
    func visitUnorderedList(_ list: UnorderedList) {
        html += "<ul>\n"
        listDepth += 1
        visitChildren(of: list)
        listDepth -= 1
        html += "</ul>\n"
    }
    
    func visitOrderedList(_ list: OrderedList) {
        html += "<ol>\n"
        listDepth += 1
        orderedListCounters.append(1)
        visitChildren(of: list)
        orderedListCounters.removeLast()
        listDepth -= 1
        html += "</ol>\n"
    }
    
    func visitListItem(_ listItem: ListItem) {
        html += "<li>"
        visitChildren(of: listItem)
        html += "</li>\n"
    }
    
    func visitBlockQuote(_ blockQuote: BlockQuote) {
        html += "<blockquote>\n"
        visitChildren(of: blockQuote)
        html += "</blockquote>\n"
    }
    
    func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        html += "<hr>\n"
    }
    
    func visitTable(_ table: Table) {
        html += "<table>\n"
        visitChildren(of: table)
        html += "</table>\n"
    }
    
    private func visitChildren(of node: Markup) {
        for child in node.children {
            visit(child)
        }
    }
    
    private func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}