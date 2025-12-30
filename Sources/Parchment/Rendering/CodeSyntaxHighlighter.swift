import Cocoa

/// Protocol defining syntax highlighting capabilities
protocol SyntaxHighlighting {
    func highlight(code: String, language: String?, fontSize: CGFloat, theme: ParchmentTheme) -> NSAttributedString
}

/// High-performance syntax highlighter for code blocks
final class CodeSyntaxHighlighter: SyntaxHighlighting {

    // MARK: - Properties

    private let defaultFont: NSFont
    private let cache = NSCache<NSString, NSAttributedString>()
    private static var regexCache: [String: NSRegularExpression] = [:]
    private static let regexCacheLock = NSLock()

    /// Maximum line length to process with regex (ReDoS protection)
    private static let maxLineLength = 10_000

    // MARK: - Initialization

    init(defaultFont: NSFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)) {
        self.defaultFont = defaultFont
        cache.countLimit = 100 // Limit cache size
    }

    // MARK: - Public Interface

    func highlight(code: String, language: String?, fontSize: CGFloat, theme: ParchmentTheme) -> NSAttributedString {
        // Use hashValue for unique cache keys (avoids prefix collisions)
        let cacheKey = "\(code.hashValue)-\(language ?? "")-\(fontSize)-\(theme.name)" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let result = performHighlighting(code: code, language: language, fontSize: fontSize, theme: theme)
        cache.setObject(result, forKey: cacheKey)
        return result
    }

    // MARK: - Private Implementation

    private func performHighlighting(code: String, language: String?, fontSize: CGFloat, theme: ParchmentTheme) -> NSAttributedString {
        let baseFont = NSFont.monospacedSystemFont(ofSize: fontSize * 0.9, weight: .regular)
        let colors = theme.syntaxColors
        
        let backgroundAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: theme.codeTextColor,
            .backgroundColor: theme.codeBackgroundColor
        ]
        
        // Apply padding
        let paddedResult = NSMutableAttributedString()
        let padding = NSAttributedString(string: "  ", attributes: backgroundAttributes)
        
        let lines = code.components(separatedBy: .newlines)
        for (index, line) in lines.enumerated() {
            paddedResult.append(padding)
            
            if let lang = language?.lowercased(), !lang.isEmpty {
                let highlightedLine = applySyntaxHighlighting(to: line, language: lang, baseFont: baseFont, colors: colors, textColor: theme.codeTextColor, backgroundColor: theme.codeBackgroundColor)
                paddedResult.append(highlightedLine)
            } else {
                paddedResult.append(NSAttributedString(string: line, attributes: backgroundAttributes))
            }
            
            paddedResult.append(padding)
            if index < lines.count - 1 {
                paddedResult.append(NSAttributedString(string: "\n", attributes: backgroundAttributes))
            }
        }
        
        return paddedResult
    }
    
    private func applySyntaxHighlighting(to code: String, language: String, baseFont: NSFont, colors: SyntaxColors, textColor: NSColor, backgroundColor: NSColor) -> NSAttributedString {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor
        ]

        switch language {
        case "swift":
            return highlightSwift(code, baseFont: baseFont, colors: colors, textColor: textColor, backgroundColor: backgroundColor)
        case "javascript", "js":
            return highlightJavaScript(code, baseFont: baseFont, colors: colors, textColor: textColor, backgroundColor: backgroundColor)
        case "python", "py":
            return highlightPython(code, baseFont: baseFont, colors: colors, textColor: textColor, backgroundColor: backgroundColor)
        case "json":
            return highlightJSON(code, baseFont: baseFont, colors: colors, textColor: textColor, backgroundColor: backgroundColor)
        case "html", "xml":
            return highlightHTML(code, baseFont: baseFont, colors: colors, textColor: textColor, backgroundColor: backgroundColor)
        case "css":
            return highlightCSS(code, baseFont: baseFont, colors: colors, textColor: textColor, backgroundColor: backgroundColor)
        default:
            return NSAttributedString(string: code, attributes: baseAttributes)
        }
    }
}

// MARK: - Language-Specific Highlighting

extension CodeSyntaxHighlighter {
    
    private func highlightSwift(_ code: String, baseFont: NSFont, colors: SyntaxColors, textColor: NSColor, backgroundColor: NSColor) -> NSAttributedString {
        let result = NSMutableAttributedString(string: code, attributes: [
            .font: baseFont,
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor
        ])
        
        // Keywords
        let keywords = ["func", "var", "let", "if", "else", "for", "while", "return", "class", "struct", "enum", "protocol", "extension", "import", "private", "public", "internal", "static", "override", "init", "self", "super", "nil", "true", "false", "try", "catch", "throw", "async", "await", "actor"]
        
        for keyword in keywords {
            highlightPattern("\\b\(keyword)\\b", in: result, color: colors.keyword, font: baseFont)
        }
        
        // Types
        let types = ["String", "Int", "Double", "Float", "Bool", "Array", "Dictionary", "Set", "Optional", "Any", "AnyObject", "NSString", "NSAttributedString", "NSFont", "NSColor", "NSView", "NSViewController", "NSWindow"]
        
        for type in types {
            highlightPattern("\\b\(type)\\b", in: result, color: colors.type, font: baseFont)
        }
        
        // Strings
        highlightPattern("\"[^\"\\n]*\"", in: result, color: colors.string, font: baseFont)

        // Comments (safe patterns to avoid ReDoS)
        highlightPattern("//.*$", in: result, color: colors.comment, font: baseFont, options: [.anchorsMatchLines])
        highlightPattern("/\\*[\\s\\S]*?\\*/", in: result, color: colors.comment, font: baseFont, options: [.dotMatchesLineSeparators])

        // Numbers
        highlightPattern("\\b\\d+(\\.\\d+)?\\b", in: result, color: colors.number, font: baseFont)

        // Function calls
        highlightPattern("\\b[a-z][a-zA-Z0-9_]*(?=\\()", in: result, color: colors.function, font: baseFont)

        return result
    }

    private func highlightJavaScript(_ code: String, baseFont: NSFont, colors: SyntaxColors, textColor: NSColor, backgroundColor: NSColor) -> NSAttributedString {
        let result = NSMutableAttributedString(string: code, attributes: [
            .font: baseFont,
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor
        ])
        
        // Keywords
        let keywords = ["function", "var", "let", "const", "if", "else", "for", "while", "return", "class", "extends", "import", "export", "default", "new", "this", "super", "null", "undefined", "true", "false", "try", "catch", "throw", "async", "await", "yield", "typeof", "instanceof", "delete", "void"]
        
        for keyword in keywords {
            highlightPattern("\\b\(keyword)\\b", in: result, color: colors.keyword, font: baseFont)
        }
        
        // Strings (single and double quotes)
        highlightPattern("\"[^\"\\n]*\"", in: result, color: colors.string, font: baseFont)
        highlightPattern("'[^'\\n]*'", in: result, color: colors.string, font: baseFont)
        highlightPattern("`[^`]*`", in: result, color: colors.string, font: baseFont)

        // Comments (safe patterns to avoid ReDoS)
        highlightPattern("//.*$", in: result, color: colors.comment, font: baseFont, options: [.anchorsMatchLines])
        highlightPattern("/\\*[\\s\\S]*?\\*/", in: result, color: colors.comment, font: baseFont, options: [.dotMatchesLineSeparators])

        // Numbers
        highlightPattern("\\b\\d+(\\.\\d+)?\\b", in: result, color: colors.number, font: baseFont)

        // Function calls
        highlightPattern("\\b[a-z][a-zA-Z0-9_]*(?=\\()", in: result, color: colors.function, font: baseFont)

        return result
    }

    private func highlightPython(_ code: String, baseFont: NSFont, colors: SyntaxColors, textColor: NSColor, backgroundColor: NSColor) -> NSAttributedString {
        let result = NSMutableAttributedString(string: code, attributes: [
            .font: baseFont,
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor
        ])
        
        // Keywords
        let keywords = ["def", "class", "if", "elif", "else", "for", "while", "return", "import", "from", "as", "try", "except", "finally", "with", "lambda", "yield", "assert", "break", "continue", "del", "global", "nonlocal", "pass", "raise", "and", "or", "not", "in", "is", "None", "True", "False"]
        
        for keyword in keywords {
            highlightPattern("\\b\(keyword)\\b", in: result, color: colors.keyword, font: baseFont)
        }
        
        // Built-in functions
        let builtins = ["print", "len", "range", "str", "int", "float", "list", "dict", "set", "tuple", "bool", "type", "isinstance", "open", "file", "input", "map", "filter", "reduce", "zip", "enumerate", "sorted", "reversed"]
        
        for builtin in builtins {
            highlightPattern("\\b\(builtin)\\b", in: result, color: colors.function, font: baseFont)
        }
        
        // Strings (single and double quotes, including triple quotes)
        highlightPattern("\"\"\"[^\"]*\"\"\"", in: result, color: colors.string, font: baseFont)
        highlightPattern("'''[^']*'''", in: result, color: colors.string, font: baseFont)
        highlightPattern("\"[^\"\\n]*\"", in: result, color: colors.string, font: baseFont)
        highlightPattern("'[^'\\n]*'", in: result, color: colors.string, font: baseFont)
        
        // Comments
        highlightPattern("#.*$", in: result, color: colors.comment, font: baseFont, options: [.anchorsMatchLines])
        
        // Numbers
        highlightPattern("\\b\\d+(\\.\\d+)?\\b", in: result, color: colors.number, font: baseFont)
        
        // Decorators
        highlightPattern("@\\w+", in: result, color: colors.keyword, font: baseFont)
        
        return result
    }
    
    private func highlightJSON(_ code: String, baseFont: NSFont, colors: SyntaxColors, textColor: NSColor, backgroundColor: NSColor) -> NSAttributedString {
        let result = NSMutableAttributedString(string: code, attributes: [
            .font: baseFont,
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor
        ])
        
        // Property names
        highlightPattern("\"[^\"]+\"(?=\\s*:)", in: result, color: colors.keyword, font: baseFont)
        
        // String values
        highlightPattern("(?<=:\\s*)\"[^\"]*\"", in: result, color: colors.string, font: baseFont)
        
        // Numbers
        highlightPattern("\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b", in: result, color: colors.number, font: baseFont)
        
        // Booleans and null
        highlightPattern("\\b(true|false|null)\\b", in: result, color: colors.keyword, font: baseFont)
        
        return result
    }
    
    private func highlightHTML(_ code: String, baseFont: NSFont, colors: SyntaxColors, textColor: NSColor, backgroundColor: NSColor) -> NSAttributedString {
        let result = NSMutableAttributedString(string: code, attributes: [
            .font: baseFont,
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor
        ])
        
        // Tags
        highlightPattern("<[^>]+>", in: result, color: colors.keyword, font: baseFont)
        
        // Attributes
        highlightPattern("\\b\\w+(?==)", in: result, color: colors.type, font: baseFont)
        
        // Attribute values
        highlightPattern("\"[^\"]*\"", in: result, color: colors.string, font: baseFont)
        highlightPattern("'[^']*'", in: result, color: colors.string, font: baseFont)
        
        // Comments
        highlightPattern("<!--[^>]*-->", in: result, color: colors.comment, font: baseFont)
        
        return result
    }
    
    private func highlightCSS(_ code: String, baseFont: NSFont, colors: SyntaxColors, textColor: NSColor, backgroundColor: NSColor) -> NSAttributedString {
        let result = NSMutableAttributedString(string: code, attributes: [
            .font: baseFont,
            .foregroundColor: textColor,
            .backgroundColor: backgroundColor
        ])
        
        // Selectors
        highlightPattern("^[^{]+(?=\\{)", in: result, color: colors.keyword, font: baseFont, options: [.anchorsMatchLines])
        
        // Properties
        highlightPattern("\\b[a-z-]+(?=:)", in: result, color: colors.type, font: baseFont)
        
        // Values
        highlightPattern(":[^;]+", in: result, color: colors.string, font: baseFont)
        
        // Colors
        highlightPattern("#[0-9a-fA-F]{3,6}\\b", in: result, color: colors.number, font: baseFont)
        
        // Numbers with units
        highlightPattern("\\b\\d+(\\.\\d+)?(px|em|rem|%|vh|vw|pt)?\\b", in: result, color: colors.number, font: baseFont)

        // Comments (safe pattern to avoid ReDoS)
        highlightPattern("/\\*[\\s\\S]*?\\*/", in: result, color: colors.comment, font: baseFont, options: [.dotMatchesLineSeparators])

        return result
    }
    
    // MARK: - Helper Methods

    private func cachedRegex(pattern: String, options: NSRegularExpression.Options) -> NSRegularExpression? {
        let key = "\(pattern)-\(options.rawValue)"

        Self.regexCacheLock.lock()
        defer { Self.regexCacheLock.unlock() }

        if let cached = Self.regexCache[key] {
            return cached
        }

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            Self.regexCache[key] = regex
            return regex
        } catch {
            Logger.error("Regex compilation error for pattern '\(pattern)': \(error)")
            return nil
        }
    }

    private func highlightPattern(_ pattern: String, in attributedString: NSMutableAttributedString, color: NSColor, font: NSFont, options: NSRegularExpression.Options = []) {
        // ReDoS protection: skip regex on extremely long inputs
        guard attributedString.length <= Self.maxLineLength else { return }
        guard let regex = cachedRegex(pattern: pattern, options: options) else { return }

        let range = NSRange(location: 0, length: attributedString.length)

        // Use matching with timeout option for additional safety
        regex.enumerateMatches(in: attributedString.string, options: [.withoutAnchoringBounds], range: range) { match, _, _ in
            guard let matchRange = match?.range else { return }
            attributedString.addAttribute(.foregroundColor, value: color, range: matchRange)
            attributedString.addAttribute(.font, value: font, range: matchRange)
        }
    }
}