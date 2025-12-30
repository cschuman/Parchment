import Foundation
import Markdown

/// Renders Markdown AST to HTML string
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
