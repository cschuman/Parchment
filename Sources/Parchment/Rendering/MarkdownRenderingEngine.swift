import Foundation
import Cocoa
import Markdown
import SwiftSyntax

// Import specific Markdown types we need
typealias Strikethrough = Markdown.Strikethrough
typealias LineBreak = Markdown.LineBreak
typealias SoftBreak = Markdown.SoftBreak

class MarkdownRenderingEngine {
    private let styleManager = StyleManager.shared
    private let syntaxHighlighter = SyntaxHighlighter()
    // Use shared image cache
    
    private let renderQueue = DispatchQueue(label: "markdown.rendering", qos: .userInitiated)
    private var renderCache: [String: NSAttributedString] = [:]
    
    func render(markdown: String, visibleRange: NSRange, zoomLevel: CGFloat) async -> NSAttributedString {
        let cacheKey = "\(markdown.hashValue)-\(zoomLevel)"
        
        if let cached = renderCache[cacheKey] {
            return cached
        }
        
        return await withCheckedContinuation { continuation in
            renderQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: NSAttributedString())
                    return
                }
                
                // Parse markdown with options to enable extensions
                // Note: ParseOptions is the default parser which includes strikethrough
                let document = Document(parsing: markdown, source: nil, options: [])
                
                // Debug: Print document structure
                print("DEBUG: Document has \(document.childCount) children")
                for child in document.children {
                    print("DEBUG: Child type: \(type(of: child))")
                }
                
                let attributedString = self.renderDocument(document, zoomLevel: zoomLevel)
                
                self.renderCache[cacheKey] = attributedString
                
                if self.renderCache.count > 10 {
                    self.renderCache.removeAll()
                }
                
                continuation.resume(returning: attributedString)
            }
        }
    }
    
    private func renderDocument(_ document: Document, zoomLevel: CGFloat) -> NSAttributedString {
        let visitor = AttributedStringVisitor(zoomLevel: zoomLevel, syntaxHighlighter: syntaxHighlighter)
        let walker = DocumentWalker(visitor: visitor)
        walker.visit(document)
        return visitor.attributedString
    }
}

class AttributedStringVisitor {
    let attributedString = NSMutableAttributedString()
    private let zoomLevel: CGFloat
    private let syntaxHighlighter: SyntaxHighlighter
    private var listDepth = 0
    private var currentAttributes: [NSAttributedString.Key: Any] = [:]
    
    init(zoomLevel: CGFloat, syntaxHighlighter: SyntaxHighlighter) {
        self.zoomLevel = zoomLevel
        self.syntaxHighlighter = syntaxHighlighter
        setupDefaultAttributes()
    }
    
    private func setupDefaultAttributes() {
        let baseFontSize = 16.0 * zoomLevel
        currentAttributes = [
            .font: createOptimizedFont(size: baseFontSize),
            .foregroundColor: NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.13, alpha: 1.0),
            .paragraphStyle: createParagraphStyle(),
            .kern: 0.3,
            .ligature: 2
        ]
    }
    
    private func createOptimizedFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        // Use SF Pro for optimal rendering
        let fontName = size > 20 ? "SF Pro Display" : "SF Pro Text"
        if let font = NSFont(name: fontName, size: size) {
            return font
        }
        return NSFont.systemFont(ofSize: size, weight: weight)
    }
    
    private func createParagraphStyle(indent: CGFloat = 0) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.7
        style.paragraphSpacing = 24.0 * zoomLevel
        style.paragraphSpacingBefore = 8.0 * zoomLevel
        style.firstLineHeadIndent = indent
        style.headIndent = indent
        style.hyphenationFactor = 0.9
        style.tighteningFactorForTruncation = 0.05
        style.lineBreakStrategy = [.pushOut]
        return style
    }
    
    func visitHeading(_ heading: Heading) {
        let level = heading.level
        let scales: [CGFloat] = [0, 2.441, 1.953, 1.563, 1.25, 1.0, 0.8] // Musical ratios
        let fontSize = 16.0 * scales[min(level, 6)] * zoomLevel
        let weight: NSFont.Weight = level <= 2 ? .bold : (level <= 4 ? .semibold : .medium)
        
        let headingStyle = NSMutableParagraphStyle()
        headingStyle.lineHeightMultiple = 1.3
        headingStyle.paragraphSpacing = 16.0 * zoomLevel
        headingStyle.paragraphSpacingBefore = 32.0 * zoomLevel
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: createOptimizedFont(size: fontSize, weight: weight),
            .foregroundColor: NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.08, alpha: 1.0),
            .paragraphStyle: headingStyle,
            .headingLevel: level,
            .kern: -0.5
        ]
        
        let text = heading.plainText + "\n"
        attributedString.append(NSAttributedString(string: text, attributes: attributes))
    }
    
    func visitParagraph(_ paragraph: Paragraph) {
        visitChildren(of: paragraph)
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
    }
    
    func visitText(_ text: Text) {
        attributedString.append(NSAttributedString(string: text.string, attributes: currentAttributes))
    }
    
    func visitStrong(_ strong: Strong) {
        let savedFont = currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 14)
        // Preserve font family and just add bold trait
        let boldDescriptor = savedFont.fontDescriptor.withSymbolicTraits(.bold)
        let boldFont = NSFont(descriptor: boldDescriptor, size: savedFont.pointSize) ?? 
                      NSFont.boldSystemFont(ofSize: savedFont.pointSize)
        currentAttributes[.font] = boldFont
        visitChildren(of: strong)
        currentAttributes[.font] = savedFont
    }
    
    func visitEmphasis(_ emphasis: Emphasis) {
        let savedFont = currentAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 14)
        // Preserve font family and just add italic trait
        let italicDescriptor = savedFont.fontDescriptor.withSymbolicTraits(.italic)
        let italicFont = NSFont(descriptor: italicDescriptor, size: savedFont.pointSize) ?? savedFont
        currentAttributes[.font] = italicFont
        visitChildren(of: emphasis)
        currentAttributes[.font] = savedFont
    }
    
    func visitStrikethrough(_ strikethrough: Strikethrough) {
        print("DEBUG: visitStrikethrough called!")
        let savedStrikethrough = currentAttributes[.strikethroughStyle]
        currentAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        currentAttributes[.strikethroughColor] = currentAttributes[.foregroundColor]
        visitChildren(of: strikethrough)
        if savedStrikethrough != nil {
            currentAttributes[.strikethroughStyle] = savedStrikethrough
        } else {
            currentAttributes.removeValue(forKey: .strikethroughStyle)
        }
        currentAttributes.removeValue(forKey: .strikethroughColor)
    }
    
    func visitLineBreak(_ lineBreak: LineBreak) {
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
    }
    
    func visitSoftBreak(_ softBreak: SoftBreak) {
        attributedString.append(NSAttributedString(string: " ", attributes: currentAttributes))
    }
    
    func visitInlineCode(_ inlineCode: InlineCode) {
        let fontSize = (currentAttributes[.font] as? NSFont)?.pointSize ?? 16
        let codeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize * 0.92, weight: .regular),
            .foregroundColor: NSColor(calibratedRed: 0.8, green: 0.2, blue: 0.4, alpha: 1.0),
            .backgroundColor: NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.98, alpha: 1.0),
            .baselineOffset: -0.5
        ]
        
        // Add padding with spaces
        let paddedCode = " \(inlineCode.code) "
        attributedString.append(NSAttributedString(string: paddedCode, attributes: codeAttributes))
    }
    
    func visitCodeBlock(_ codeBlock: CodeBlock) {
        let language = codeBlock.language ?? ""
        let code = codeBlock.code
        
        let fontSize = 14.0 * zoomLevel
        
        // Create code block with padding
        // Use syntax highlighter which handles all formatting
        let highlighted = syntaxHighlighter.highlight(code: code, language: language, fontSize: fontSize)
        attributedString.append(highlighted)
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
    }
    
    private func createCodeBlockParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2.0 * zoomLevel
        style.paragraphSpacing = 16.0 * zoomLevel
        style.firstLineHeadIndent = 16.0 * zoomLevel
        style.headIndent = 16.0 * zoomLevel
        style.tailIndent = -16.0 * zoomLevel
        return style
    }
    
    func visitLink(_ link: Link) {
        let savedColor = currentAttributes[.foregroundColor]
        currentAttributes[.foregroundColor] = NSColor.linkColor
        currentAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        currentAttributes[.link] = link.destination
        visitChildren(of: link)
        currentAttributes[.foregroundColor] = savedColor
        currentAttributes.removeValue(forKey: .underlineStyle)
        currentAttributes.removeValue(forKey: .link)
    }
    
    func visitImage(_ image: Image) {
        // Get alt text from the image children
        var altText = ""
        for child in image.children {
            if let text = child as? Text {
                altText += text.string
            }
        }
        
        if let source = image.source, let url = URL(string: source) {
            let attachment = NSTextAttachment()
            
            // Create placeholder with alt text
            let placeholder = createImagePlaceholder(altText: altText.isEmpty ? "Loading image..." : altText)
            attachment.image = placeholder
            
            // Load image asynchronously
            Task {
                if let loadedImage = await ImageLoader.shared.loadImage(from: url) {
                    DispatchQueue.main.async {
                        attachment.image = loadedImage
                    }
                }
            }
            
            attributedString.append(NSAttributedString(attachment: attachment))
            
            // Add alt text as caption if present
            if !altText.isEmpty {
                let captionAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 12 * zoomLevel),
                    .foregroundColor: NSColor.secondaryLabelColor,
                    .paragraphStyle: createParagraphStyle()
                ]
                attributedString.append(NSAttributedString(string: "\n[\(altText)]\n", 
                                                          attributes: captionAttributes))
            }
        }
    }
    
    private func createImagePlaceholder(altText: String) -> NSImage {
        let size = NSSize(width: 200, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Draw background
        NSColor.quaternaryLabelColor.set()
        NSBezierPath.fill(NSRect(origin: .zero, size: size))
        
        // Draw text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        let text = NSAttributedString(string: altText, attributes: attributes)
        let textSize = text.size()
        let textRect = NSRect(x: (size.width - textSize.width) / 2,
                              y: (size.height - textSize.height) / 2,
                              width: textSize.width,
                              height: textSize.height)
        text.draw(in: textRect)
        
        image.unlockFocus()
        return image
    }
    
    func visitUnorderedList(_ list: UnorderedList) {
        listDepth += 1
        visitChildren(of: list)
        listDepth -= 1
    }
    
    func visitOrderedList(_ list: OrderedList) {
        listDepth += 1
        for (index, item) in list.children.enumerated() {
            visitOrderedListItem(item as! ListItem, number: index + 1)
        }
        listDepth -= 1
    }
    
    func visitListItem(_ listItem: ListItem) {
        let indent = CGFloat(listDepth * 30) * zoomLevel
        let bullet = "• "
        
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.3
        style.paragraphSpacing = 4.0 * zoomLevel
        style.firstLineHeadIndent = indent - 15  // Bullet hangs to the left
        style.headIndent = indent  // Text indented
        style.tabStops = [NSTextTab(textAlignment: .left, location: indent)]
        
        var itemAttributes = currentAttributes
        itemAttributes[.paragraphStyle] = style
        
        // Add bullet with hanging indent
        attributedString.append(NSAttributedString(string: "\t" + bullet, attributes: itemAttributes))
        
        // Visit children for the content
        let savedAttributes = currentAttributes
        currentAttributes = itemAttributes
        visitChildren(of: listItem)
        currentAttributes = savedAttributes
        
        attributedString.append(NSAttributedString(string: "\n", attributes: itemAttributes))
    }
    
    private func visitOrderedListItem(_ listItem: ListItem, number: Int) {
        let indent = CGFloat(listDepth * 30) * zoomLevel
        let marker = "\(number). "
        
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.3
        style.paragraphSpacing = 4.0 * zoomLevel
        style.firstLineHeadIndent = indent - 20  // Number hangs to the left
        style.headIndent = indent  // Text indented
        style.tabStops = [NSTextTab(textAlignment: .left, location: indent)]
        
        var itemAttributes = currentAttributes
        itemAttributes[.paragraphStyle] = style
        
        // Add number with hanging indent
        attributedString.append(NSAttributedString(string: "\t" + marker, attributes: itemAttributes))
        
        // Visit children for the content
        let savedAttributes = currentAttributes
        currentAttributes = itemAttributes
        visitChildren(of: listItem)
        currentAttributes = savedAttributes
        
        attributedString.append(NSAttributedString(string: "\n", attributes: itemAttributes))
    }
    
    func visitBlockQuote(_ blockQuote: BlockQuote) {
        let indent = 20.0 * zoomLevel
        let style = createParagraphStyle(indent: indent)
        var quoteAttributes = currentAttributes
        quoteAttributes[.paragraphStyle] = style
        quoteAttributes[.foregroundColor] = NSColor.secondaryLabelColor
        
        let savedAttributes = currentAttributes
        currentAttributes = quoteAttributes
        visitChildren(of: blockQuote)
        currentAttributes = savedAttributes
    }
    
    func visitTable(_ table: Table) {
        // Create table container with styling
        let tableStyle = NSMutableParagraphStyle()
        tableStyle.paragraphSpacing = 16.0 * zoomLevel
        tableStyle.paragraphSpacingBefore = 16.0 * zoomLevel
        
        var isFirstRow = true
        
        // Visit table children directly - Table contains TableHead and TableBody
        for child in table.children {
            if let head = child as? Table.Head {
                // Process header rows
                for headerChild in head.children {
                    if let row = headerChild as? Table.Row {
                        visitTableRow(row, isHeader: true)
                    }
                }
                // Add separator after header
                let separator = String(repeating: "─", count: 60)
                attributedString.append(NSAttributedString(string: "\(separator)\n", 
                    attributes: [.foregroundColor: NSColor.separatorColor]))
                isFirstRow = false
            } else if let body = child as? Table.Body {
                // Process body rows
                for bodyChild in body.children {
                    if let row = bodyChild as? Table.Row {
                        visitTableRow(row, isHeader: false)
                    }
                }
            }
        }
        
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
    }
    
    private func visitTableRow(_ row: Table.Row, isHeader: Bool) {
        for (index, child) in row.children.enumerated() {
            if let cell = child as? Table.Cell {
                if index > 0 {
                    attributedString.append(NSAttributedString(string: " │ ", 
                        attributes: [.foregroundColor: NSColor.separatorColor]))
                }
                
                let savedAttributes = currentAttributes
                if isHeader {
                    if let font = currentAttributes[.font] as? NSFont {
                        let boldDescriptor = font.fontDescriptor.withSymbolicTraits(.bold)
                        currentAttributes[.font] = NSFont(descriptor: boldDescriptor, size: font.pointSize) ?? 
                                                  NSFont.boldSystemFont(ofSize: font.pointSize)
                    }
                }
                
                // Visit cell contents
                for cellChild in cell.children {
                    visit(cellChild)
                }
                
                currentAttributes = savedAttributes
            }
        }
        attributedString.append(NSAttributedString(string: "\n", attributes: currentAttributes))
    }
    
    func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        let separator = String(repeating: "—", count: 40)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.tertiaryLabelColor,
            .paragraphStyle: createParagraphStyle()
        ]
        attributedString.append(NSAttributedString(string: "\n\(separator)\n", attributes: attributes))
    }
    
    private func visitChildren(of node: Markup) {
        for child in node.children {
            visit(child)
        }
    }
    
    func visit(_ markup: Markup) {
        print("DEBUG: Visiting \(type(of: markup))")
        switch markup {
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
        case let node as Strikethrough:
            print("DEBUG: Found Strikethrough node!")
            visitStrikethrough(node)
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
        case let node as Table:
            visitTable(node)
        case let node as ThematicBreak:
            visitThematicBreak(node)
        case let node as LineBreak:
            visitLineBreak(node)
        case let node as SoftBreak:
            visitSoftBreak(node)
        default:
            visitChildren(of: markup)
        }
    }
}

class DocumentWalker {
    private let visitor: AttributedStringVisitor
    
    init(visitor: AttributedStringVisitor) {
        self.visitor = visitor
    }
    
    func visit(_ document: Document) {
        for child in document.children {
            visitor.visit(child)
        }
    }
}

extension NSAttributedString.Key {
    static let headingLevel = NSAttributedString.Key("HeadingLevel")
}