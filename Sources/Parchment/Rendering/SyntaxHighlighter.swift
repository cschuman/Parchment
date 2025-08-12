import Foundation
import Cocoa
import SwiftSyntax

class SyntaxHighlighter {
    
    func highlight(code: String, language: String, fontSize: CGFloat) -> NSAttributedString {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.05)
        ]
        
        let attributedString = NSMutableAttributedString(string: code, attributes: baseAttributes)
        
        switch language.lowercased() {
        case "swift":
            return highlightSwift(code: code, fontSize: fontSize)
        case "javascript", "js":
            return highlightJavaScript(code: code, fontSize: fontSize)
        case "python", "py":
            return highlightPython(code: code, fontSize: fontSize)
        case "html", "xml":
            return highlightHTML(code: code, fontSize: fontSize)
        case "css":
            return highlightCSS(code: code, fontSize: fontSize)
        case "json":
            return highlightJSON(code: code, fontSize: fontSize)
        case "markdown", "md":
            return highlightMarkdown(code: code, fontSize: fontSize)
        case "bash", "sh", "shell":
            return highlightBash(code: code, fontSize: fontSize)
        default:
            return attributedString
        }
    }
    
    private func highlightSwift(code: String, fontSize: CGFloat) -> NSAttributedString {
        return genericHighlight(
            code: code,
            fontSize: fontSize,
            keywords: ["func", "var", "let", "class", "struct", "enum", "protocol", "extension", "if", "else", "for", "while", "return", "import", "public", "private", "internal", "static", "final", "override", "init", "deinit", "self", "super", "nil", "true", "false", "try", "catch", "throw", "async", "await", "actor"],
            stringPattern: "\"[^\"]*\"|#\"[^\"]*\"#",
            commentPattern: "//.*$|/\\*[\\s\\S]*?\\*/"
        )
    }
    
    private func highlightJavaScript(code: String, fontSize: CGFloat) -> NSAttributedString {
        return genericHighlight(
            code: code,
            fontSize: fontSize,
            keywords: ["function", "var", "let", "const", "if", "else", "for", "while", "return", "class", "extends", "import", "export", "async", "await"],
            stringPattern: "\"[^\"]*\"|'[^']*'|`[^`]*`",
            commentPattern: "//.*$|/\\*[\\s\\S]*?\\*/"
        )
    }
    
    private func highlightPython(code: String, fontSize: CGFloat) -> NSAttributedString {
        return genericHighlight(
            code: code,
            fontSize: fontSize,
            keywords: ["def", "class", "import", "from", "if", "elif", "else", "for", "while", "return", "pass", "break", "continue", "try", "except", "finally", "with", "as", "lambda"],
            stringPattern: "\"\"\"[\\s\\S]*?\"\"\"|'''[\\s\\S]*?'''|\"[^\"]*\"|'[^']*'",
            commentPattern: "#.*$"
        )
    }
    
    private func highlightHTML(code: String, fontSize: CGFloat) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.05)
        ]
        
        attributedString.append(NSAttributedString(string: code, attributes: baseAttributes))
        
        let tagPattern = "</?\\w+[^>]*>"
        let attributePattern = "\\w+=\"[^\"]*\""
        
        highlightPattern(tagPattern, in: attributedString, color: .systemBlue)
        highlightPattern(attributePattern, in: attributedString, color: .systemPurple)
        highlightPattern("<!--[\\s\\S]*?-->", in: attributedString, color: .systemGreen)
        
        return attributedString
    }
    
    private func highlightCSS(code: String, fontSize: CGFloat) -> NSAttributedString {
        return genericHighlight(
            code: code,
            fontSize: fontSize,
            keywords: [],
            stringPattern: "\"[^\"]*\"|'[^']*'",
            commentPattern: "/\\*[\\s\\S]*?\\*/",
            additionalPatterns: [
                ("\\.[\\w-]+", NSColor.systemTeal),
                ("#[\\w-]+", NSColor.systemIndigo),
                ("\\b\\d+(?:px|em|rem|%|vh|vw)\\b", NSColor.systemBlue)
            ]
        )
    }
    
    private func highlightJSON(code: String, fontSize: CGFloat) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.05)
        ]
        
        attributedString.append(NSAttributedString(string: code, attributes: baseAttributes))
        
        highlightPattern("\"[^\"]*\"\\s*:", in: attributedString, color: .systemPurple)
        highlightPattern(": \"[^\"]*\"", in: attributedString, color: .systemRed)
        highlightPattern("\\b\\d+(?:\\.\\d+)?\\b", in: attributedString, color: .systemBlue)
        highlightPattern("\\b(?:true|false|null)\\b", in: attributedString, color: .systemOrange)
        
        return attributedString
    }
    
    private func highlightMarkdown(code: String, fontSize: CGFloat) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.05)
        ]
        
        attributedString.append(NSAttributedString(string: code, attributes: baseAttributes))
        
        highlightPattern("^#{1,6}\\s+.*$", in: attributedString, color: .systemBlue)
        highlightPattern("\\*\\*[^*]+\\*\\*", in: attributedString, color: .systemPurple)
        highlightPattern("\\*[^*]+\\*", in: attributedString, color: .systemIndigo)
        highlightPattern("`[^`]+`", in: attributedString, color: .systemPink)
        highlightPattern("\\[[^\\]]+\\]\\([^)]+\\)", in: attributedString, color: .linkColor)
        
        return attributedString
    }
    
    private func highlightBash(code: String, fontSize: CGFloat) -> NSAttributedString {
        return genericHighlight(
            code: code,
            fontSize: fontSize,
            keywords: ["if", "then", "else", "elif", "fi", "for", "while", "do", "done", "case", "esac", "function", "return", "export", "source"],
            stringPattern: "\"[^\"]*\"|'[^']*'",
            commentPattern: "#.*$",
            additionalPatterns: [
                ("\\$\\w+|\\${[^}]+}", NSColor.systemTeal),
                ("\\b(?:echo|cd|ls|pwd|mkdir|rm|cp|mv|grep|sed|awk)\\b", NSColor.systemIndigo)
            ]
        )
    }
    
    private func genericHighlight(
        code: String,
        fontSize: CGFloat,
        keywords: [String],
        stringPattern: String,
        commentPattern: String,
        additionalPatterns: [(String, NSColor)] = []
    ) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.05)
        ]
        
        attributedString.append(NSAttributedString(string: code, attributes: baseAttributes))
        
        if !keywords.isEmpty {
            let keywordPattern = "\\b(" + keywords.joined(separator: "|") + ")\\b"
            highlightPattern(keywordPattern, in: attributedString, color: .systemPurple)
        }
        
        highlightPattern(stringPattern, in: attributedString, color: .systemRed)
        highlightPattern(commentPattern, in: attributedString, color: .systemGreen)
        highlightPattern("\\b\\d+(?:\\.\\d+)?\\b", in: attributedString, color: .systemBlue)
        
        for (pattern, color) in additionalPatterns {
            highlightPattern(pattern, in: attributedString, color: color)
        }
        
        return attributedString
    }
    
    private func highlightPattern(_ pattern: String, in attributedString: NSMutableAttributedString, color: NSColor) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
            let range = NSRange(location: 0, length: attributedString.length)
            
            regex.enumerateMatches(in: attributedString.string, options: [], range: range) { match, _, _ in
                if let matchRange = match?.range {
                    attributedString.addAttribute(.foregroundColor, value: color, range: matchRange)
                }
            }
        } catch {
            print("Regex error: \(error)")
        }
    }
}

extension NSFont {
    func withTraits(_ traits: NSFontTraitMask) -> NSFont {
        let fontManager = NSFontManager.shared
        return fontManager.convert(self, toHaveTrait: traits)
    }
}