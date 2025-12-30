import Cocoa
import Markdown

/// Enhanced markdown renderer using the TypographyEngine for beautiful text rendering
final class EnhancedMarkdownRenderer {
    private let typographyEngine: TypographyEngine
    private let syntaxHighlighter: CodeSyntaxHighlighter
    private let theme: ParchmentTheme
    private let zoomLevel: CGFloat

    /// Render context holds all mutable state for a single render operation
    /// This ensures thread-safety by isolating state per render call
    private final class RenderContext {
        let attributedString = NSMutableAttributedString()
        var currentAttributes: [NSAttributedString.Key: Any]
        var listDepth = 0
        var listCounters: [Int] = []

        init(baseAttributes: [NSAttributedString.Key: Any]) {
            self.currentAttributes = baseAttributes
        }
    }

    init(theme: ParchmentTheme = ParchmentTheme.current, zoomLevel: CGFloat = 1.0) {
        self.theme = theme
        self.zoomLevel = zoomLevel
        self.typographyEngine = TypographyEngine(theme: theme, zoomLevel: zoomLevel)
        self.syntaxHighlighter = CodeSyntaxHighlighter()
    }
    
    public func render(_ document: Document) -> NSAttributedString {
        // Create isolated context for this render operation (thread-safe)
        let context = RenderContext(baseAttributes: typographyEngine.bodyAttributes())

        for child in document.children {
            visit(child, context: context)
        }

        // Apply final polish
        applyFinalFormatting(context: context)

        return NSAttributedString(attributedString: context.attributedString)
    }

    private func visit(_ node: any Markup, context: RenderContext) {
        switch node {
        case let heading as Heading:
            visitHeading(heading, context: context)
        case let paragraph as Paragraph:
            visitParagraph(paragraph, context: context)
        case let text as Markdown.Text:
            visitText(text, context: context)
        case let strong as Strong:
            visitStrong(strong, context: context)
        case let emphasis as Emphasis:
            visitEmphasis(emphasis, context: context)
        case let code as InlineCode:
            visitInlineCode(code, context: context)
        case let codeBlock as CodeBlock:
            visitCodeBlock(codeBlock, context: context)
        case let list as UnorderedList:
            visitUnorderedList(list, context: context)
        case let list as OrderedList:
            visitOrderedList(list, context: context)
        case let item as ListItem:
            visitListItem(item, context: context)
        case let link as Link:
            visitLink(link, context: context)
        case let blockquote as BlockQuote:
            visitBlockQuote(blockquote, context: context)
        case let table as Table:
            visitTable(table, context: context)
        case is LineBreak:
            context.attributedString.append(NSAttributedString(string: "\n", attributes: context.currentAttributes))
        default:
            // Visit children for unknown nodes
            for child in node.children {
                visit(child, context: context)
            }
        }
    }
    
    private func visitHeading(_ heading: Heading, context: RenderContext) {
        let savedAttributes = context.currentAttributes
        context.currentAttributes = typographyEngine.headingAttributes(level: heading.level)

        for child in heading.children {
            visit(child, context: context)
        }

        context.attributedString.append(NSAttributedString(string: "\n", attributes: context.currentAttributes))
        context.currentAttributes = savedAttributes
    }

    private func visitParagraph(_ paragraph: Paragraph, context: RenderContext) {
        let savedAttributes = context.currentAttributes
        context.currentAttributes = typographyEngine.bodyAttributes()

        for child in paragraph.children {
            visit(child, context: context)
        }

        context.attributedString.append(NSAttributedString(string: "\n", attributes: context.currentAttributes))
        context.currentAttributes = savedAttributes
    }

    private func visitText(_ text: Markdown.Text, context: RenderContext) {
        let smartText = typographyEngine.applySmartTypography(to: text.string)
        context.attributedString.append(NSAttributedString(string: smartText, attributes: context.currentAttributes))
    }

    private func visitStrong(_ strong: Strong, context: RenderContext) {
        let savedFont = context.currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 16)
        let boldFont = NSFontManager.shared.convert(savedFont, toHaveTrait: .boldFontMask)
        context.currentAttributes[.font] = boldFont

        for child in strong.children {
            visit(child, context: context)
        }

        context.currentAttributes[.font] = savedFont
    }

    private func visitEmphasis(_ emphasis: Emphasis, context: RenderContext) {
        let savedFont = context.currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 16)
        let italicFont = NSFontManager.shared.convert(savedFont, toHaveTrait: .italicFontMask)
        context.currentAttributes[.font] = italicFont

        for child in emphasis.children {
            visit(child, context: context)
        }

        context.currentAttributes[.font] = savedFont
    }

    private func visitInlineCode(_ code: InlineCode, context: RenderContext) {
        let savedAttributes = context.currentAttributes
        context.currentAttributes = typographyEngine.inlineCodeAttributes()

        context.attributedString.append(NSAttributedString(string: " \(code.code) ", attributes: context.currentAttributes))
        context.currentAttributes = savedAttributes
    }

    private func visitCodeBlock(_ codeBlock: CodeBlock, context: RenderContext) {
        let savedAttributes = context.currentAttributes
        context.currentAttributes = typographyEngine.codeBlockAttributes()

        // Add spacing before code block
        context.attributedString.append(NSAttributedString(string: "\n", attributes: savedAttributes))

        // Create a mutable string for the code block with background
        let codeString = NSMutableAttributedString()

        // Attempt syntax highlighting if language is specified
        if let language = codeBlock.language {
            let highlighted = syntaxHighlighter.highlight(
                code: codeBlock.code,
                language: language,
                fontSize: (context.currentAttributes[.font] as? NSFont)?.pointSize ?? 14,
                theme: theme
            )
            codeString.append(highlighted)
        } else {
            codeString.append(NSAttributedString(string: codeBlock.code, attributes: context.currentAttributes))
        }

        // Apply background color to entire code block
        let fullRange = NSRange(location: 0, length: codeString.length)
        codeString.addAttribute(.backgroundColor, value: theme.codeBackgroundColor, range: fullRange)

        // Add padding around code with background
        let paddedCode = NSMutableAttributedString()
        let paddingAttrs = context.currentAttributes
        paddedCode.append(NSAttributedString(string: "  ", attributes: paddingAttrs))
        paddedCode.append(codeString)
        paddedCode.append(NSAttributedString(string: "  ", attributes: paddingAttrs))

        context.attributedString.append(paddedCode)
        context.attributedString.append(NSAttributedString(string: "\n", attributes: savedAttributes))

        context.currentAttributes = savedAttributes
    }

    private func visitUnorderedList(_ list: UnorderedList, context: RenderContext) {
        context.listDepth += 1
        for child in list.children {
            visit(child, context: context)
        }
        context.listDepth -= 1
    }

    private func visitOrderedList(_ list: OrderedList, context: RenderContext) {
        context.listDepth += 1
        context.listCounters.append(1)

        for child in list.children {
            visit(child, context: context)
        }

        context.listCounters.removeLast()
        context.listDepth -= 1
    }

    private func visitListItem(_ item: ListItem, context: RenderContext) {
        let indent = String(repeating: "  ", count: max(0, context.listDepth - 1))

        if !context.listCounters.isEmpty {
            // Ordered list
            let number = context.listCounters[context.listCounters.count - 1]
            context.attributedString.append(NSAttributedString(string: "\(indent)\(number). ", attributes: context.currentAttributes))
            context.listCounters[context.listCounters.count - 1] += 1
        } else {
            // Unordered list with varying bullets
            let bullets = ["•", "◦", "▪", "▫"]
            let bullet = bullets[min(context.listDepth - 1, bullets.count - 1)]
            context.attributedString.append(NSAttributedString(string: "\(indent)\(bullet) ", attributes: context.currentAttributes))
        }

        for child in item.children {
            visit(child, context: context)
        }

        if !context.attributedString.string.hasSuffix("\n") {
            context.attributedString.append(NSAttributedString(string: "\n", attributes: context.currentAttributes))
        }
    }

    private func visitLink(_ link: Link, context: RenderContext) {
        let savedColor = context.currentAttributes[.foregroundColor]
        context.currentAttributes[.foregroundColor] = theme.linkColor
        context.currentAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue

        if let destination = link.destination {
            // Block dangerous URL schemes (XSS prevention)
            let lowercaseDestination = destination.lowercased()
            if !lowercaseDestination.hasPrefix("javascript:") &&
               !lowercaseDestination.hasPrefix("data:") &&
               !lowercaseDestination.hasPrefix("vbscript:") {
                context.currentAttributes[.link] = URL(string: destination)
            }
        }

        for child in link.children {
            visit(child, context: context)
        }

        context.currentAttributes[.foregroundColor] = savedColor
        context.currentAttributes.removeValue(forKey: .underlineStyle)
        context.currentAttributes.removeValue(forKey: .link)
    }

    private func visitBlockQuote(_ blockquote: BlockQuote, context: RenderContext) {
        let savedAttributes = context.currentAttributes
        context.currentAttributes = typographyEngine.blockquoteAttributes()

        context.attributedString.append(NSAttributedString(string: "> ", attributes: context.currentAttributes))

        for child in blockquote.children {
            visit(child, context: context)
        }

        context.currentAttributes = savedAttributes
    }
    
    private func visitTable(_ table: Table, context: RenderContext) {
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
        var tableAttrs = context.currentAttributes
        tableAttrs[.font] = NSFont.monospacedSystemFont(
            ofSize: (theme.baseFontSize - 1) * zoomLevel,
            weight: .regular
        )
        tableAttrs[.foregroundColor] = theme.textColor

        context.attributedString.append(NSAttributedString(string: "\n", attributes: context.currentAttributes))

        // Render headers
        var headerLine = ""
        for (i, header) in headers.enumerated() {
            let width = i < columnWidths.count ? columnWidths[i] : 10
            headerLine += padString(header, toWidth: width)
            if i < headers.count - 1 {
                headerLine += "│"
            }
        }
        context.attributedString.append(NSAttributedString(string: headerLine + "\n", attributes: tableAttrs))

        // Render separator
        var separator = ""
        for (i, width) in columnWidths.enumerated() {
            separator += String(repeating: "─", count: width)
            if i < columnWidths.count - 1 {
                separator += "┼"
            }
        }
        context.attributedString.append(NSAttributedString(string: separator + "\n", attributes: tableAttrs))

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
            context.attributedString.append(NSAttributedString(string: rowLine + "\n", attributes: tableAttrs))
        }

        context.attributedString.append(NSAttributedString(string: "\n", attributes: context.currentAttributes))
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
    
    private func applyFinalFormatting(context: RenderContext) {
        // Remove any trailing whitespace
        while context.attributedString.string.hasSuffix("\n\n\n") {
            context.attributedString.deleteCharacters(in: NSRange(location: context.attributedString.length - 1, length: 1))
        }

        // Ensure proper spacing throughout
        let fullRange = NSRange(location: 0, length: context.attributedString.length)
        context.attributedString.fixAttributes(in: fullRange)
    }
}