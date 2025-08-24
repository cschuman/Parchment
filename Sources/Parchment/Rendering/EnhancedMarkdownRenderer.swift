import Cocoa
import Markdown

/// Enhanced markdown renderer using the TypographyEngine for beautiful text rendering
class EnhancedMarkdownRenderer {
    private let typographyEngine: TypographyEngine
    private let syntaxHighlighter: CodeSyntaxHighlighter
    private let attributedString = NSMutableAttributedString()
    private var currentAttributes: [NSAttributedString.Key: Any] = [:]
    private var listDepth = 0
    private var listCounters: [Int] = []
    private let zoomLevel: CGFloat
    
    init(theme: ParchmentTheme? = nil, zoomLevel: CGFloat = 1.0) {
        // Initialize with theme or default settings
        let settings: TypographyEngine.TypographySettings
        if let theme = theme {
            settings = TypographyEngine.TypographySettings(
                baseFontSize: theme.baseFontSize,
                lineHeightMultiple: theme.lineHeightMultiple,
                paragraphSpacing: 12,
                useOpticalSizing: true,
                enableLigatures: true,
                enableKerning: true,
                theme: .default // This could be extended to use theme fonts
            )
        } else {
            settings = TypographyEngine.TypographySettings()
        }
        
        self.typographyEngine = TypographyEngine(settings: settings)
        self.syntaxHighlighter = CodeSyntaxHighlighter()
        self.zoomLevel = zoomLevel
        self.currentAttributes = typographyEngine.bodyAttributes(zoomLevel: zoomLevel)
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
        case let blockquote as BlockQuote:
            visitBlockquote(blockquote)
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
        case let image as Image:
            visitImage(image)
        case let table as Table:
            visitTable(table)
        case is LineBreak:
            visitLineBreak()
        case is ThematicBreak:
            visitThematicBreak()
        default:
            // Recursively visit children for unknown nodes
            for child in node.children {
                visit(child)
            }
        }
    }
    
    // MARK: - Block Elements
    
    private func visitHeading(_ heading: Heading) {
        let attributes = typographyEngine.headingAttributes(level: heading.level, zoomLevel: zoomLevel)
        let savedAttributes = currentAttributes
        currentAttributes = attributes
        
        // Add anchor for navigation
        let headingStart = attributedString.length
        
        for child in heading.children {
            visit(child)
        }
        
        // Add spacing after heading
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        
        // Store heading location for TOC
        let headingRange = NSRange(location: headingStart, length: attributedString.length - headingStart)
        attributedString.addAttribute(.headingLevel, value: heading.level, range: headingRange)
        
        currentAttributes = savedAttributes
    }
    
    private func visitParagraph(_ paragraph: Paragraph) {
        let attributes = typographyEngine.bodyAttributes(zoomLevel: zoomLevel)
        let savedAttributes = currentAttributes
        currentAttributes = attributes
        
        for child in paragraph.children {
            visit(child)
        }
        
        // Add paragraph spacing
        attributedString.append(NSAttributedString(string: "\n\n", attributes: currentAttributes))
        currentAttributes = savedAttributes
    }
    
    private func visitBlockquote(_ blockquote: BlockQuote) {
        let attributes = typographyEngine.blockquoteAttributes(zoomLevel: zoomLevel)
        let savedAttributes = currentAttributes
        currentAttributes = attributes
        
        // Add quote marker
        let quoteStart = attributedString.length
        
        for child in blockquote.children {
            visit(child)
        }
        
        // Apply blockquote styling to the entire range
        let quoteRange = NSRange(location: quoteStart, length: attributedString.length - quoteStart)
        attributedString.addAttribute(.blockquote, value: true, range: quoteRange)
        
        currentAttributes = savedAttributes
    }
    
    // MARK: - Inline Elements
    
    private func visitText(_ text: Markdown.Text) {
        // Apply smart typography transformations
        let processedText = applySmartTypography(text.string)
        attributedString.append(NSAttributedString(string: processedText, attributes: currentAttributes))
    }
    
    private func visitStrong(_ strong: Strong) {
        let savedAttributes = currentAttributes
        if let currentFont = currentAttributes[.font] as? NSFont {
            currentAttributes.merge(typographyEngine.strongAttributes(baseFont: currentFont)) { _, new in new }
        }
        
        for child in strong.children {
            visit(child)
        }
        
        currentAttributes = savedAttributes
    }
    
    private func visitEmphasis(_ emphasis: Emphasis) {
        let savedAttributes = currentAttributes
        if let currentFont = currentAttributes[.font] as? NSFont {
            currentAttributes.merge(typographyEngine.emphasisAttributes(baseFont: currentFont)) { _, new in new }
        }
        
        for child in emphasis.children {
            visit(child)
        }
        
        currentAttributes = savedAttributes
    }
    
    private func visitStrikethrough(_ strikethrough: Strikethrough) {
        let savedAttributes = currentAttributes
        currentAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        currentAttributes[.strikethroughColor] = NSColor.secondaryLabelColor
        
        for child in strikethrough.children {
            visit(child)
        }
        
        currentAttributes = savedAttributes
    }
    
    private func visitInlineCode(_ code: InlineCode) {
        let attributes = typographyEngine.inlineCodeAttributes(zoomLevel: zoomLevel)
        let savedAttributes = currentAttributes
        currentAttributes = attributes
        
        // Add small padding around inline code
        attributedString.append(NSAttributedString(string: " ", attributes: savedAttributes))
        attributedString.append(NSAttributedString(string: code.code, attributes: currentAttributes))
        attributedString.append(NSAttributedString(string: " ", attributes: savedAttributes))
        
        currentAttributes = savedAttributes
    }
    
    // MARK: - Code Blocks
    
    private func visitCodeBlock(_ codeBlock: CodeBlock) {
        let attributes = typographyEngine.codeBlockAttributes(zoomLevel: zoomLevel)
        let savedAttributes = currentAttributes
        currentAttributes = attributes
        
        // Add code block with syntax highlighting if language is specified
        let code: NSAttributedString
        if let language = codeBlock.language {
            // For now, skip syntax highlighting until we fix the interface
            code = NSAttributedString(string: codeBlock.code, attributes: currentAttributes)
        } else {
            code = NSAttributedString(string: codeBlock.code, attributes: currentAttributes)
        }
        
        // Add code block with proper spacing
        attributedString.append(NSAttributedString(string: "\n", attributes: savedAttributes))
        attributedString.append(code)
        attributedString.append(NSAttributedString(string: "\n\n", attributes: savedAttributes))
        
        currentAttributes = savedAttributes
    }
    
    // MARK: - Lists
    
    private func visitUnorderedList(_ list: UnorderedList) {
        listDepth += 1
        let savedAttributes = currentAttributes
        
        for child in list.children {
            visit(child)
        }
        
        listDepth -= 1
        currentAttributes = savedAttributes
    }
    
    private func visitOrderedList(_ list: OrderedList) {
        listDepth += 1
        listCounters.append(1)
        let savedAttributes = currentAttributes
        
        for child in list.children {
            visit(child)
        }
        
        listCounters.removeLast()
        listDepth -= 1
        currentAttributes = savedAttributes
    }
    
    private func visitListItem(_ item: ListItem) {
        // Calculate indentation
        let indentLevel = CGFloat(max(0, listDepth - 1))
        let indent = indentLevel * 25.0
        
        // Create paragraph style with indent
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = indent + 20
        paragraphStyle.firstLineHeadIndent = indent
        paragraphStyle.paragraphSpacing = 4
        
        var listMarker: String
        if !listCounters.isEmpty {
            // Ordered list
            let number = listCounters[listCounters.count - 1]
            listMarker = "\(number). "
            listCounters[listCounters.count - 1] = number + 1
        } else {
            // Unordered list - use different bullets for different levels
            let bullets = ["•", "◦", "▪", "▫"]
            let bulletIndex = min(listDepth - 1, bullets.count - 1)
            listMarker = "\(bullets[bulletIndex]) "
        }
        
        // Add list marker
        var markerAttributes = currentAttributes
        markerAttributes[.paragraphStyle] = paragraphStyle
        attributedString.append(NSAttributedString(string: listMarker, attributes: markerAttributes))
        
        // Add list content with proper indent
        var contentAttributes = currentAttributes
        contentAttributes[.paragraphStyle] = paragraphStyle
        let savedAttributes = currentAttributes
        currentAttributes = contentAttributes
        
        for child in item.children {
            visit(child)
        }
        
        // Ensure proper line ending
        if !attributedString.string.hasSuffix("\n") {
            attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        }
        
        currentAttributes = savedAttributes
    }
    
    // MARK: - Links and Images
    
    private func visitLink(_ link: Link) {
        let savedAttributes = currentAttributes
        currentAttributes.merge(typographyEngine.linkAttributes()) { _, new in new }
        
        if let destination = link.destination {
            currentAttributes[.link] = URL(string: destination)
        }
        
        for child in link.children {
            visit(child)
        }
        
        currentAttributes = savedAttributes
    }
    
    private func visitImage(_ image: Image) {
        // Placeholder for image - actual image loading would be async
        let imageAttributes = currentAttributes
        let placeholder = " [Image: \(image.title ?? "untitled")] "
        attributedString.append(NSAttributedString(string: placeholder, attributes: imageAttributes))
        
        // Store image URL for async loading
        if let source = image.source {
            let range = NSRange(location: attributedString.length - placeholder.count, length: placeholder.count)
            attributedString.addAttribute(.imageURL, value: source, range: range)
        }
    }
    
    // MARK: - Tables
    
    private func visitTable(_ table: Table) {
        // Enhanced table rendering would go here
        // For now, use a simple representation
        let tableStart = attributedString.length
        
        for child in table.children {
            if child is Table.Head || child is Table.Body {
                for row in child.children {
                    if let tableRow = row as? Table.Row {
                        for (index, cell) in tableRow.children.enumerated() {
                            if index > 0 {
                                attributedString.append(NSAttributedString(string: " | ", attributes: currentAttributes))
                            }
                            if let tableCell = cell as? Table.Cell {
                                for cellChild in tableCell.children {
                                    visit(cellChild)
                                }
                            }
                        }
                        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
                    }
                }
                if child is Table.Head {
                    // Add separator after header
                    let separator = String(repeating: "—", count: 40)
                    attributedString.append(NSAttributedString(string: "\(separator)\n", attributes: currentAttributes))
                }
            }
        }
        
        // Mark table range for special formatting
        let tableRange = NSRange(location: tableStart, length: attributedString.length - tableStart)
        attributedString.addAttribute(.table, value: true, range: tableRange)
        
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
    }
    
    // MARK: - Special Elements
    
    private func visitLineBreak() {
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
    }
    
    private func visitThematicBreak() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.paragraphSpacing = 20
        paragraphStyle.paragraphSpacingBefore = 20
        
        var attributes = currentAttributes
        attributes[.paragraphStyle] = paragraphStyle
        attributes[.foregroundColor] = NSColor.tertiaryLabelColor
        
        let separator = "⁎  ⁎  ⁎"
        attributedString.append(NSAttributedString(string: "\n\(separator)\n\n", attributes: attributes))
    }
    
    // MARK: - Typography Enhancements
    
    private func applySmartTypography(_ text: String) -> String {
        var result = text
        
        // Smart quotes
        result = result.replacingOccurrences(of: "\"", with: "\u{201C}")  // Left double quote
        result = result.replacingOccurrences(of: "'", with: "\u{2018}")   // Left single quote
        
        // Em dashes
        result = result.replacingOccurrences(of: "--", with: "—")
        
        // Ellipsis
        result = result.replacingOccurrences(of: "...", with: "…")
        
        // Non-breaking spaces before punctuation (French typography)
        // This could be configurable based on locale
        
        return result
    }
    
    private func applyFinalFormatting() {
        // Remove trailing whitespace
        while attributedString.string.hasSuffix("\n\n\n") {
            let range = NSRange(location: attributedString.length - 1, length: 1)
            attributedString.deleteCharacters(in: range)
        }
        
        // Ensure document ends with single newline
        if !attributedString.string.hasSuffix("\n") {
            attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
        }
    }
}

// MARK: - Custom Attribute Keys

extension NSAttributedString.Key {
    static let headingLevel = NSAttributedString.Key("ParchmentHeadingLevel")
    static let blockquote = NSAttributedString.Key("ParchmentBlockquote")
    static let imageURL = NSAttributedString.Key("ParchmentImageURL")
    static let table = NSAttributedString.Key("ParchmentTable")
}