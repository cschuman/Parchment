import Cocoa
import Markdown

/// Converts Markdown documents to NSAttributedString for display
public class MarkdownAttributedStringVisitor {
    let attributedString = NSMutableAttributedString()
    private let zoomLevel: CGFloat
    private var currentAttributes: [NSAttributedString.Key: Any] = [:]
    private var listDepth = 0
    
    public init(zoomLevel: CGFloat = 1.0) {
        self.zoomLevel = zoomLevel
        setupDefaultAttributes()
    }
    
    private func setupDefaultAttributes() {
        currentAttributes = [
            .font: NSFont.systemFont(ofSize: 14 * zoomLevel),
            .foregroundColor: NSColor.labelColor
        ]
    }
    
    public func convertDocument(_ document: Document) -> NSAttributedString {
        for child in document.children {
            visit(child)
        }
        return NSAttributedString(attributedString: attributedString)
    }
    
    private func visit(_ node: any Markup) {
        switch node {
        case let heading as Heading:
            visitHeading(heading)
        case let paragraph as Paragraph:
            visitParagraph(paragraph)
        case let text as Markdown.Text:
            visitText(text)
        case let strong as Strong:
            visitStrong(strong)
        case let emphasis as Emphasis:
            visitEmphasis(emphasis)
        case let strikethrough as Strikethrough:
            visitStrikethrough(strikethrough)
        case let code as InlineCode:
            visitInlineCode(code)
        case let codeBlock as CodeBlock:
            visitCodeBlock(codeBlock)
        case let list as UnorderedList:
            visitUnorderedList(list)
        case let list as OrderedList:
            visitOrderedList(list)
        case let item as ListItem:
            visitListItem(item)
        case let link as Link:
            visitLink(link)
        case let table as Table:
            visitTable(table)
        case is LineBreak:
            attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        default:
            // Visit children for unknown nodes
            for child in node.children {
                visit(child)
            }
        }
    }
    
    private func visitHeading(_ heading: Heading) {
        let sizes: [CGFloat] = [0, 28, 24, 20, 18, 16, 14]
        let fontSize = sizes[min(heading.level, 6)] * zoomLevel
        let savedAttributes = currentAttributes
        currentAttributes[.font] = NSFont.boldSystemFont(ofSize: fontSize)
        for child in heading.children {
            visit(child)
        }
        attributedString.append(NSAttributedString(string: "\n\n", attributes: currentAttributes))
        currentAttributes = savedAttributes
    }
    
    private func visitParagraph(_ paragraph: Paragraph) {
        for child in paragraph.children {
            visit(child)
        }
        attributedString.append(NSAttributedString(string: "\n\n", attributes: currentAttributes))
    }
    
    private func visitText(_ text: Markdown.Text) {
        attributedString.append(NSAttributedString(string: text.string, attributes: currentAttributes))
    }
    
    private func visitStrong(_ strong: Strong) {
        let savedFont = currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 14)
        currentAttributes[.font] = NSFont.boldSystemFont(ofSize: savedFont.pointSize)
        for child in strong.children {
            visit(child)
        }
        currentAttributes[.font] = savedFont
    }
    
    private func visitEmphasis(_ emphasis: Emphasis) {
        let savedFont = currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 14)
        if let italic = NSFont(descriptor: savedFont.fontDescriptor.withSymbolicTraits(.italic), 
                               size: savedFont.pointSize) {
            currentAttributes[.font] = italic
        }
        for child in emphasis.children {
            visit(child)
        }
        currentAttributes[.font] = savedFont
    }
    
    private func visitStrikethrough(_ strikethrough: Strikethrough) {
        let savedStrike = currentAttributes[.strikethroughStyle]
        currentAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        for child in strikethrough.children {
            visit(child)
        }
        if savedStrike != nil {
            currentAttributes[.strikethroughStyle] = savedStrike
        } else {
            currentAttributes.removeValue(forKey: .strikethroughStyle)
        }
    }
    
    private func visitInlineCode(_ code: InlineCode) {
        let savedAttributes = currentAttributes
        currentAttributes[.font] = NSFont.monospacedSystemFont(ofSize: 13 * zoomLevel, weight: .regular)
        currentAttributes[.backgroundColor] = NSColor.quaternaryLabelColor
        attributedString.append(NSAttributedString(string: " \(code.code) ", attributes: currentAttributes))
        currentAttributes = savedAttributes
    }
    
    private func visitCodeBlock(_ codeBlock: CodeBlock) {
        let savedAttributes = currentAttributes
        currentAttributes[.font] = NSFont.monospacedSystemFont(ofSize: 13 * zoomLevel, weight: .regular)
        currentAttributes[.backgroundColor] = NSColor.quaternaryLabelColor
        attributedString.append(NSAttributedString(string: "\n\(codeBlock.code)\n\n", attributes: currentAttributes))
        currentAttributes = savedAttributes
    }
    
    private func visitUnorderedList(_ list: UnorderedList) {
        listDepth += 1
        for child in list.children {
            visit(child)
        }
        listDepth -= 1
    }
    
    private func visitOrderedList(_ list: OrderedList) {
        listDepth += 1
        for (index, child) in list.children.enumerated() {
            if let item = child as? ListItem {
                visitOrderedListItem(item, number: index + 1)
            }
        }
        listDepth -= 1
    }
    
    private func visitListItem(_ item: ListItem) {
        let indent = String(repeating: "  ", count: listDepth - 1)
        attributedString.append(NSAttributedString(string: "\(indent)• ", attributes: currentAttributes))
        for child in item.children {
            visit(child)
        }
        if !attributedString.string.hasSuffix("\n") {
            attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        }
    }
    
    private func visitOrderedListItem(_ item: ListItem, number: Int) {
        let indent = String(repeating: "  ", count: listDepth - 1)
        attributedString.append(NSAttributedString(string: "\(indent)\(number). ", attributes: currentAttributes))
        for child in item.children {
            visit(child)
        }
        if !attributedString.string.hasSuffix("\n") {
            attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        }
    }
    
    private func visitLink(_ link: Link) {
        let savedColor = currentAttributes[.foregroundColor]
        currentAttributes[.foregroundColor] = NSColor.linkColor
        currentAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        if let destination = link.destination {
            currentAttributes[.link] = URL(string: destination)
        }
        for child in link.children {
            visit(child)
        }
        currentAttributes[.foregroundColor] = savedColor
        currentAttributes.removeValue(forKey: .underlineStyle)
        currentAttributes.removeValue(forKey: .link)
    }
    
    private func visitTable(_ table: Table) {
        // Simple table rendering
        for child in table.children {
            if child is Table.Head || child is Table.Body {
                for row in child.children {
                    if let tableRow = row as? Table.Row {
                        for cell in tableRow.children {
                            if let tableCell = cell as? Table.Cell {
                                for cellChild in tableCell.children {
                                    visit(cellChild)
                                }
                                attributedString.append(NSAttributedString(string: " | ", attributes: currentAttributes))
                            }
                        }
                        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
                    }
                }
                if child is Table.Head {
                    attributedString.append(NSAttributedString(string: String(repeating: "-", count: 40) + "\n", 
                                                              attributes: currentAttributes))
                }
            }
        }
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
    }
}