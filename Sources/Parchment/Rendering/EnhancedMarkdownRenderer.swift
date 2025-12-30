import Cocoa
import Markdown

/// Enhanced markdown renderer using the TypographyEngine for beautiful text rendering
final class EnhancedMarkdownRenderer {
    private let typographyEngine: TypographyEngine
    private let syntaxHighlighter: CodeSyntaxHighlighter
    private let attributedString = NSMutableAttributedString()
    private var currentAttributes: [NSAttributedString.Key: Any] = [:]
    private var listDepth = 0
    private var listCounters: [Int] = []
    private let theme: ParchmentTheme
    private let zoomLevel: CGFloat
    
    init(theme: ParchmentTheme = ParchmentTheme.current, zoomLevel: CGFloat = 1.0) {
        self.theme = theme
        self.zoomLevel = zoomLevel
        self.typographyEngine = TypographyEngine(theme: theme, zoomLevel: zoomLevel)
        self.syntaxHighlighter = CodeSyntaxHighlighter()
        self.currentAttributes = typographyEngine.bodyAttributes()
    }
    
    public func render(_ document: Document) -> NSAttributedString {
        attributedString.setAttributedString(NSAttributedString())
        
        for child in document.children {
            visit(child)
        }
        
        // Apply final polish
        applyFinalFormatting()
        
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
        case let blockquote as BlockQuote:
            visitBlockQuote(blockquote)
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
        let savedAttributes = currentAttributes
        currentAttributes = typographyEngine.headingAttributes(level: heading.level)
        
        for child in heading.children {
            visit(child)
        }
        
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        currentAttributes = savedAttributes
    }
    
    private func visitParagraph(_ paragraph: Paragraph) {
        let savedAttributes = currentAttributes
        currentAttributes = typographyEngine.bodyAttributes()
        
        for child in paragraph.children {
            visit(child)
        }
        
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        currentAttributes = savedAttributes
    }
    
    private func visitText(_ text: Markdown.Text) {
        let smartText = typographyEngine.applySmartTypography(to: text.string)
        attributedString.append(NSAttributedString(string: smartText, attributes: currentAttributes))
    }
    
    private func visitStrong(_ strong: Strong) {
        let savedFont = currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 16)
        let boldFont = NSFontManager.shared.convert(savedFont, toHaveTrait: .boldFontMask)
        currentAttributes[.font] = boldFont
        
        for child in strong.children {
            visit(child)
        }
        
        currentAttributes[.font] = savedFont
    }
    
    private func visitEmphasis(_ emphasis: Emphasis) {
        let savedFont = currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 16)
        let italicFont = NSFontManager.shared.convert(savedFont, toHaveTrait: .italicFontMask)
        currentAttributes[.font] = italicFont
        
        for child in emphasis.children {
            visit(child)
        }
        
        currentAttributes[.font] = savedFont
    }
    
    private func visitInlineCode(_ code: InlineCode) {
        let savedAttributes = currentAttributes
        currentAttributes = typographyEngine.inlineCodeAttributes()
        
        attributedString.append(NSAttributedString(string: " \(code.code) ", attributes: currentAttributes))
        currentAttributes = savedAttributes
    }
    
    private func visitCodeBlock(_ codeBlock: CodeBlock) {
        let savedAttributes = currentAttributes
        currentAttributes = typographyEngine.codeBlockAttributes()
        
        // Add spacing before code block
        attributedString.append(NSAttributedString(string: "\n", attributes: savedAttributes))
        
        // Create a mutable string for the code block with background
        let codeString = NSMutableAttributedString()
        
        // Attempt syntax highlighting if language is specified
        if let language = codeBlock.language {
            let highlighted = syntaxHighlighter.highlight(
                code: codeBlock.code,
                language: language,
                fontSize: (currentAttributes[.font] as? NSFont)?.pointSize ?? 14,
                theme: theme
            )
            codeString.append(highlighted)
        } else {
            codeString.append(NSAttributedString(string: codeBlock.code, attributes: currentAttributes))
        }
        
        // Apply background color to entire code block
        let fullRange = NSRange(location: 0, length: codeString.length)
        codeString.addAttribute(.backgroundColor, value: theme.codeBackgroundColor, range: fullRange)
        
        // Add padding around code with background
        let paddedCode = NSMutableAttributedString()
        let paddingAttrs = currentAttributes
        paddedCode.append(NSAttributedString(string: "  ", attributes: paddingAttrs))
        paddedCode.append(codeString)
        paddedCode.append(NSAttributedString(string: "  ", attributes: paddingAttrs))
        
        attributedString.append(paddedCode)
        attributedString.append(NSAttributedString(string: "\n", attributes: savedAttributes))
        
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
        listCounters.append(1)
        
        for child in list.children {
            visit(child)
        }
        
        listCounters.removeLast()
        listDepth -= 1
    }
    
    private func visitListItem(_ item: ListItem) {
        let indent = String(repeating: "  ", count: max(0, listDepth - 1))
        
        if !listCounters.isEmpty {
            // Ordered list
            let number = listCounters[listCounters.count - 1]
            attributedString.append(NSAttributedString(string: "\(indent)\(number). ", attributes: currentAttributes))
            listCounters[listCounters.count - 1] += 1
        } else {
            // Unordered list with varying bullets
            let bullets = ["•", "◦", "▪", "▫"]
            let bullet = bullets[min(listDepth - 1, bullets.count - 1)]
            attributedString.append(NSAttributedString(string: "\(indent)\(bullet) ", attributes: currentAttributes))
        }
        
        for child in item.children {
            visit(child)
        }
        
        if !attributedString.string.hasSuffix("\n") {
            attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        }
    }
    
    private func visitLink(_ link: Link) {
        let savedColor = currentAttributes[.foregroundColor]
        currentAttributes[.foregroundColor] = theme.linkColor
        currentAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue

        if let destination = link.destination {
            // Block dangerous URL schemes (XSS prevention)
            let lowercaseDestination = destination.lowercased()
            if !lowercaseDestination.hasPrefix("javascript:") &&
               !lowercaseDestination.hasPrefix("data:") &&
               !lowercaseDestination.hasPrefix("vbscript:") {
                currentAttributes[.link] = URL(string: destination)
            }
        }

        for child in link.children {
            visit(child)
        }

        currentAttributes[.foregroundColor] = savedColor
        currentAttributes.removeValue(forKey: .underlineStyle)
        currentAttributes.removeValue(forKey: .link)
    }
    
    private func visitBlockQuote(_ blockquote: BlockQuote) {
        let savedAttributes = currentAttributes
        currentAttributes = typographyEngine.blockquoteAttributes()
        
        attributedString.append(NSAttributedString(string: "> ", attributes: currentAttributes))
        
        for child in blockquote.children {
            visit(child)
        }
        
        currentAttributes = savedAttributes
    }
    
    private func visitTable(_ table: Table) {
        // Extract table data
        var headers: [String] = []
        var rows: [[String]] = []
        
        // Process table structure
        for child in table.children {
            if let head = child as? Table.Head {
                for row in head.children {
                    if let tableRow = row as? Table.Row {
                        headers = extractRowData(tableRow)
                    }
                }
            } else if let body = child as? Table.Body {
                for row in body.children {
                    if let tableRow = row as? Table.Row {
                        rows.append(extractRowData(tableRow))
                    }
                }
            }
        }
        
        // Calculate column widths
        var columnWidths: [Int] = []
        for i in 0..<headers.count {
            var maxWidth = headers[i].count
            for row in rows {
                if i < row.count {
                    maxWidth = max(maxWidth, row[i].count)
                }
            }
            columnWidths.append(min(maxWidth + 2, 30)) // Cap at 30 chars
        }
        
        // Create table attributes (monospace for alignment)
        var tableAttrs = currentAttributes
        tableAttrs[.font] = NSFont.monospacedSystemFont(
            ofSize: (theme.baseFontSize - 1) * zoomLevel,
            weight: .regular
        )
        tableAttrs[.foregroundColor] = theme.textColor
        
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        
        // Render headers
        var headerLine = ""
        for (i, header) in headers.enumerated() {
            let width = i < columnWidths.count ? columnWidths[i] : 10
            headerLine += padString(header, toWidth: width)
            if i < headers.count - 1 {
                headerLine += "│"
            }
        }
        attributedString.append(NSAttributedString(string: headerLine + "\n", attributes: tableAttrs))
        
        // Render separator
        var separator = ""
        for (i, width) in columnWidths.enumerated() {
            separator += String(repeating: "─", count: width)
            if i < columnWidths.count - 1 {
                separator += "┼"
            }
        }
        attributedString.append(NSAttributedString(string: separator + "\n", attributes: tableAttrs))
        
        // Render rows
        for row in rows {
            var rowLine = ""
            for (i, cell) in row.enumerated() {
                let width = i < columnWidths.count ? columnWidths[i] : 10
                rowLine += padString(cell, toWidth: width)
                if i < row.count - 1 {
                    rowLine += "│"
                }
            }
            attributedString.append(NSAttributedString(string: rowLine + "\n", attributes: tableAttrs))
        }
        
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
    }
    
    private func extractRowData(_ row: Table.Row) -> [String] {
        var cells: [String] = []
        for cell in row.children {
            if let tableCell = cell as? Table.Cell {
                var cellText = ""
                for child in tableCell.children {
                    cellText += extractPlainText(from: child)
                }
                cells.append(cellText.trimmingCharacters(in: .whitespaces))
            }
        }
        return cells
    }
    
    private func extractPlainText(from node: any Markup) -> String {
        if let text = node as? Markdown.Text {
            return text.string
        } else if let inlineCode = node as? InlineCode {
            return inlineCode.code
        } else {
            var result = ""
            for child in node.children {
                result += extractPlainText(from: child)
            }
            return result
        }
    }
    
    private func padString(_ str: String, toWidth width: Int) -> String {
        let trimmed = str.prefix(width - 1)
        let padding = width - trimmed.count
        return " " + trimmed + String(repeating: " ", count: max(0, padding - 1))
    }
    
    private func applyFinalFormatting() {
        // Remove any trailing whitespace
        while attributedString.string.hasSuffix("\n\n\n") {
            attributedString.deleteCharacters(in: NSRange(location: attributedString.length - 1, length: 1))
        }
        
        // Ensure proper spacing throughout
        let fullRange = NSRange(location: 0, length: attributedString.length)
        attributedString.fixAttributes(in: fullRange)
    }
}