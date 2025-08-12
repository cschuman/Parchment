import Foundation
import Cocoa
import MarkdownKit

// MARK: - Table of Contents Plugin

class TableOfContentsPlugin: BaseMarkdownPlugin, MarkdownActionPlugin {
    
    init() {
        super.init(
            identifier: "com.parchment.toc",
            name: "Table of Contents",
            version: "1.0.0",
            description: "Generate table of contents from headers",
            author: "Parchment"
        )
    }
    
    var menuItems: [PluginMenuItem] {
        return [
            PluginMenuItem(
                title: "Insert Table of Contents",
                action: #selector(insertTOC),
                keyEquivalent: "t",
                keyModifiers: [.command, .shift]
            )
        ]
    }
    
    var toolbarItems: [PluginToolbarItem] {
        return [
            PluginToolbarItem(
                identifier: "toc",
                label: "TOC",
                icon: NSImage(systemSymbolName: "list.bullet.indent", accessibilityDescription: "Table of Contents"),
                action: #selector(insertTOC)
            )
        ]
    }
    
    var keyboardShortcuts: [PluginKeyboardShortcut] {
        return [
            PluginKeyboardShortcut(
                key: "t",
                modifiers: [.command, .shift],
                action: #selector(insertTOC)
            )
        ]
    }
    
    @objc private func insertTOC() {
        // Implementation would insert TOC at cursor
    }
}

// MARK: - Word Count Plugin

class WordCountPlugin: BaseMarkdownPlugin, MarkdownRendererPlugin {
    
    private var wordCount = 0
    private var characterCount = 0
    
    init() {
        super.init(
            identifier: "com.parchment.wordcount",
            name: "Word Count",
            version: "1.0.0",
            description: "Display word and character count",
            author: "Parchment"
        )
    }
    
    func renderBlock(_ block: MarkdownKit.Block, defaultRenderer: (MarkdownKit.Block) -> NSAttributedString?) -> NSAttributedString? {
        // Let default renderer handle it
        return nil
    }
    
    func postprocessRendered(_ attributedString: NSAttributedString) -> NSAttributedString {
        // Count words and characters
        let text = attributedString.string
        wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        characterCount = text.count
        
        // Post notification for status bar update
        NotificationCenter.default.post(
            name: Notification.Name("WordCountUpdated"),
            object: nil,
            userInfo: ["words": wordCount, "characters": characterCount]
        )
        
        return attributedString
    }
}

// MARK: - Emoji Plugin

class EmojiPlugin: BaseMarkdownPlugin, MarkdownParserPlugin, MarkdownCompletionPlugin {
    
    private let emojiMap: [String: String] = [
        ":smile:": "😊",
        ":heart:": "❤️",
        ":thumbsup:": "👍",
        ":star:": "⭐",
        ":fire:": "🔥",
        ":rocket:": "🚀",
        ":check:": "✅",
        ":x:": "❌",
        ":warning:": "⚠️",
        ":bulb:": "💡",
        ":bug:": "🐛",
        ":sparkles:": "✨",
        ":tada:": "🎉",
        ":construction:": "🚧",
        ":memo:": "📝",
        ":art:": "🎨",
        ":zap:": "⚡",
        ":lipstick:": "💄",
        ":lock:": "🔒",
        ":key:": "🔑"
    ]
    
    init() {
        super.init(
            identifier: "com.parchment.emoji",
            name: "Emoji Support",
            version: "1.0.0",
            description: "Convert :emoji: codes to emoji characters",
            author: "Parchment"
        )
    }
    
    func preprocessMarkdown(_ markdown: String) -> String {
        var result = markdown
        
        for (code, emoji) in emojiMap {
            result = result.replacingOccurrences(of: code, with: emoji)
        }
        
        return result
    }
    
    func postprocessDocument(_ document: MarkdownKit.Block) -> MarkdownKit.Block {
        // No post-processing needed
        return document
    }
    
    func completions(for text: String, at range: NSRange) -> [CompletionItem] {
        // Check if we're in an emoji code
        let beforeRange = NSRange(location: max(0, range.location - 10), length: min(10, range.location))
        let beforeText = (text as NSString).substring(with: beforeRange)
        
        if let colonIndex = beforeText.lastIndex(of: ":") {
            let prefix = String(beforeText[colonIndex...])
            
            return emojiMap.compactMap { (code, emoji) in
                if code.hasPrefix(prefix) {
                    return CompletionItem(
                        text: code,
                        displayText: "\(code) \(emoji)",
                        detail: "Emoji",
                        icon: nil
                    )
                }
                return nil
            }
        }
        
        return []
    }
}

// MARK: - Syntax Highlight Plugin

class SyntaxHighlightPlugin: BaseMarkdownPlugin, MarkdownRendererPlugin {
    
    init() {
        super.init(
            identifier: "com.parchment.syntaxhighlight",
            name: "Syntax Highlighting",
            version: "1.0.0",
            description: "Syntax highlighting for code blocks",
            author: "Parchment"
        )
    }
    
    func renderBlock(_ block: MarkdownKit.Block, defaultRenderer: (MarkdownKit.Block) -> NSAttributedString?) -> NSAttributedString? {
        // For now, return nil to use default renderer
        // TODO: Implement code block detection once Block type structure is known
        return nil
    }
    
    func postprocessRendered(_ attributedString: NSAttributedString) -> NSAttributedString {
        return attributedString
    }
    
    private func renderCodeBlock(language: String, code: String) -> NSAttributedString {
        let result = NSMutableAttributedString(string: code)
        let theme = ThemeManager.shared.currentTheme
        
        // Apply base code styling
        result.addAttribute(.font, value: theme.fonts.code, range: NSRange(location: 0, length: code.count))
        result.addAttribute(.foregroundColor, value: theme.colors.codeText, range: NSRange(location: 0, length: code.count))
        
        // Simple keyword highlighting for Swift
        if language.lowercased() == "swift" {
            highlightSwift(in: result)
        } else if language.lowercased() == "javascript" || language.lowercased() == "js" {
            highlightJavaScript(in: result)
        }
        
        return result
    }
    
    private func highlightSwift(in attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        
        // Keywords
        let keywords = ["func", "var", "let", "class", "struct", "enum", "protocol", "extension",
                       "if", "else", "for", "while", "switch", "case", "default", "return",
                       "import", "public", "private", "internal", "static", "final"]
        
        for keyword in keywords {
            highlightPattern("\\b\(keyword)\\b", color: NSColor(hex: "#569cd6"), in: attributedString)
        }
        
        // Strings
        highlightPattern("\"[^\"]*\"", color: NSColor(hex: "#ce9178"), in: attributedString)
        
        // Comments
        highlightPattern("//.*$", color: NSColor(hex: "#6a9955"), in: attributedString, options: [.anchorsMatchLines])
        highlightPattern("/\\*[\\s\\S]*?\\*/", color: NSColor(hex: "#6a9955"), in: attributedString)
        
        // Numbers
        highlightPattern("\\b\\d+(\\.\\d+)?\\b", color: NSColor(hex: "#b5cea8"), in: attributedString)
    }
    
    private func highlightJavaScript(in attributedString: NSMutableAttributedString) {
        // Keywords
        let keywords = ["function", "var", "let", "const", "class", "extends", "implements",
                       "if", "else", "for", "while", "switch", "case", "default", "return",
                       "import", "export", "async", "await", "try", "catch", "finally"]
        
        for keyword in keywords {
            highlightPattern("\\b\(keyword)\\b", color: NSColor(hex: "#569cd6"), in: attributedString)
        }
        
        // Strings
        highlightPattern("\"[^\"]*\"", color: NSColor(hex: "#ce9178"), in: attributedString)
        highlightPattern("'[^']*'", color: NSColor(hex: "#ce9178"), in: attributedString)
        highlightPattern("`[^`]*`", color: NSColor(hex: "#ce9178"), in: attributedString)
        
        // Comments
        highlightPattern("//.*$", color: NSColor(hex: "#6a9955"), in: attributedString, options: [.anchorsMatchLines])
        highlightPattern("/\\*[\\s\\S]*?\\*/", color: NSColor(hex: "#6a9955"), in: attributedString)
    }
    
    private func highlightPattern(_ pattern: String, color: NSColor, in attributedString: NSMutableAttributedString, options: NSRegularExpression.Options = []) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let range = NSRange(location: 0, length: attributedString.length)
            
            regex.enumerateMatches(in: attributedString.string, options: [], range: range) { match, _, _ in
                guard let matchRange = match?.range else { return }
                attributedString.addAttribute(.foregroundColor, value: color, range: matchRange)
            }
        } catch {
            // Ignore regex errors
        }
    }
}

// MARK: - Wiki Link Plugin

class WikiLinkPlugin: BaseMarkdownPlugin, MarkdownParserPlugin {
    
    init() {
        super.init(
            identifier: "com.parchment.wikilink",
            name: "Wiki Links",
            version: "1.0.0",
            description: "Support [[wiki-style]] links",
            author: "Parchment"
        )
    }
    
    func preprocessMarkdown(_ markdown: String) -> String {
        // Convert [[wiki links]] to [wiki links](wiki-links.md)
        let pattern = "\\[\\[([^\\]]+)\\]\\]"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: markdown.count)
            
            let result = regex.stringByReplacingMatches(
                in: markdown,
                options: [],
                range: range,
                withTemplate: "[$1]($1.md)"
            )
            
            return result
        } catch {
            return markdown
        }
    }
    
    func postprocessDocument(_ document: MarkdownKit.Block) -> MarkdownKit.Block {
        return document
    }
}

// MARK: - Footnote Plugin

class FootnotePlugin: BaseMarkdownPlugin, MarkdownParserPlugin, MarkdownRendererPlugin {
    
    private var footnotes: [String: String] = [:]
    private var footnoteCounter = 0
    
    init() {
        super.init(
            identifier: "com.parchment.footnote",
            name: "Footnotes",
            version: "1.0.0",
            description: "Support for footnotes[^1]",
            author: "Parchment"
        )
    }
    
    func preprocessMarkdown(_ markdown: String) -> String {
        // Extract footnote definitions
        let definitionPattern = "\\[\\^([^\\]]+)\\]:\\s*(.+)"
        
        do {
            let regex = try NSRegularExpression(pattern: definitionPattern, options: [.anchorsMatchLines])
            let range = NSRange(location: 0, length: markdown.count)
            
            regex.enumerateMatches(in: markdown, options: [], range: range) { match, _, _ in
                guard let match = match,
                      let idRange = Range(match.range(at: 1), in: markdown),
                      let textRange = Range(match.range(at: 2), in: markdown) else { return }
                
                let id = String(markdown[idRange])
                let text = String(markdown[textRange])
                footnotes[id] = text
            }
            
            // Remove footnote definitions from main text
            let cleanedMarkdown = regex.stringByReplacingMatches(
                in: markdown,
                options: [],
                range: range,
                withTemplate: ""
            )
            
            return cleanedMarkdown
        } catch {
            return markdown
        }
    }
    
    func postprocessDocument(_ document: MarkdownKit.Block) -> MarkdownKit.Block {
        return document
    }
    
    func renderBlock(_ block: MarkdownKit.Block, defaultRenderer: (MarkdownKit.Block) -> NSAttributedString?) -> NSAttributedString? {
        return nil
    }
    
    func postprocessRendered(_ attributedString: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: attributedString)
        
        // Replace footnote references with superscript numbers
        let referencePattern = "\\[\\^([^\\]]+)\\]"
        
        do {
            let regex = try NSRegularExpression(pattern: referencePattern, options: [])
            let range = NSRange(location: 0, length: result.length)
            
            var offset = 0
            regex.enumerateMatches(in: result.string, options: [], range: range) { match, _, _ in
                guard let match = match else { return }
                
                let adjustedRange = NSRange(
                    location: match.range.location + offset,
                    length: match.range.length
                )
                
                if let idRange = Range(match.range(at: 1), in: result.string) {
                    let id = String(result.string[idRange])
                    footnoteCounter += 1
                    
                    // Create superscript number
                    let superscript = NSAttributedString(
                        string: "[\(footnoteCounter)]",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 10),
                            .baselineOffset: 4,
                            .foregroundColor: NSColor.systemBlue
                        ]
                    )
                    
                    result.replaceCharacters(in: adjustedRange, with: superscript)
                    offset += superscript.length - match.range.length
                }
            }
            
            // Add footnotes section at the end if there are any
            if !footnotes.isEmpty {
                result.append(NSAttributedString(string: "\n\n---\n\n"))
                
                let footnotesTitle = NSAttributedString(
                    string: "Footnotes\n\n",
                    attributes: [
                        .font: NSFont.boldSystemFont(ofSize: 16)
                    ]
                )
                result.append(footnotesTitle)
                
                var counter = 1
                for (_, text) in footnotes {
                    let footnoteText = NSAttributedString(
                        string: "[\(counter)] \(text)\n",
                        attributes: [
                            .font: NSFont.systemFont(ofSize: 12)
                        ]
                    )
                    result.append(footnoteText)
                    counter += 1
                }
            }
        } catch {
            return attributedString
        }
        
        return result
    }
}

// MARK: - Mermaid Plugin

class MermaidPlugin: BaseMarkdownPlugin, MarkdownRendererPlugin {
    
    private var renderedDiagrams: [String: NSImage] = [:]
    
    init() {
        super.init(
            identifier: "com.parchment.mermaid",
            name: "Mermaid Diagrams",
            version: "1.0.0",
            description: "Render Mermaid diagrams in code blocks",
            author: "Parchment"
        )
    }
    
    func renderBlock(_ block: MarkdownKit.Block, defaultRenderer: (MarkdownKit.Block) -> NSAttributedString?) -> NSAttributedString? {
        // For now, use default renderer
        // TODO: Detect mermaid code blocks and render them
        return nil
    }
    
    func postprocessRendered(_ attributedString: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: attributedString)
        let text = result.string
        
        // Find code blocks that might be Mermaid
        let codeBlockPattern = "```mermaid\\n([^`]+)\\n```"
        
        do {
            let regex = try NSRegularExpression(pattern: codeBlockPattern, options: [])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            var offset = 0
            for match in matches {
                guard let codeRange = Range(match.range(at: 1), in: text) else { continue }
                
                let mermaidCode = String(text[codeRange])
                
                if MermaidRenderer.isMermaidDiagram(mermaidCode) {
                    // Create placeholder
                    let placeholder = MermaidRenderer.createPlaceholderImage()
                    
                    // Create text attachment
                    let attachment = NSTextAttachment()
                    attachment.image = placeholder
                    
                    let attachmentString = NSAttributedString(attachment: attachment)
                    
                    // Replace the code block with the image
                    let adjustedRange = NSRange(
                        location: match.range.location + offset,
                        length: match.range.length
                    )
                    
                    result.replaceCharacters(in: adjustedRange, with: attachmentString)
                    offset += attachmentString.length - match.range.length
                    
                    // Render actual diagram asynchronously
                    MermaidRenderer.shared.renderDiagram(mermaidCode) { image in
                        if let image = image {
                            DispatchQueue.main.async {
                                attachment.image = image
                                // Trigger redraw
                                NotificationCenter.default.post(
                                    name: NSTextView.didChangeNotification,
                                    object: nil
                                )
                            }
                        }
                    }
                }
            }
        } catch {
            print("Failed to process Mermaid diagrams: \(error)")
        }
        
        return result
    }
}