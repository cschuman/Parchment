import Cocoa

/// Enhanced typography engine for beautiful markdown rendering
final class TypographyEngine {

    private let theme: ParchmentTheme
    private let zoomLevel: CGFloat

    // MARK: - Cached Regex Patterns (compiled once, reused for performance)

    private static let doubleQuoteRegex = try? NSRegularExpression(pattern: "\"([^\"]*?)\"", options: [])
    private static let singleQuoteRegex = try? NSRegularExpression(pattern: "'([^']*?)'", options: [])
    private static let apostropheRegex = try? NSRegularExpression(pattern: "([a-zA-Z])'([a-zA-Z])", options: [])

    init(theme: ParchmentTheme = ParchmentTheme.current, zoomLevel: CGFloat = 1.0) {
        self.theme = theme
        self.zoomLevel = zoomLevel
    }
    
    /// Create heading attributes with golden ratio scaling
    func headingAttributes(level: Int) -> [NSAttributedString.Key: Any] {
        // Golden ratio inspired scaling
        let scales: [CGFloat] = [
            0,      // unused
            2.488,  // h1: 40pt at base 16
            2.074,  // h2: 33pt
            1.728,  // h3: 28pt
            1.44,   // h4: 23pt
            1.2,    // h5: 19pt
            1.0     // h6: 16pt
        ]

        let scale = scales[min(level, 6)]
        let fontSize = theme.baseFontSize * scale * zoomLevel

        // Use different weights for hierarchy
        let baseWeight: NSFont.Weight = {
            switch level {
            case 1: return .bold
            case 2: return .semibold
            case 3: return .medium
            default: return .regular
            }
        }()

        // Apply optical weight adjustment for better visual balance
        let weight = opticalWeight(baseWeight: baseWeight, pointSize: fontSize, isDark: theme.isDark)

        let font = createFont(
            name: theme.headingFontName,
            size: fontSize,
            weight: weight
        )
        
        // Tighter line height for headings
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.paragraphSpacingBefore = 16
        paragraphStyle.paragraphSpacing = 8
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.headingColor,
            .paragraphStyle: paragraphStyle
        ]
        
        // Add kerning for large headings
        if level <= 2 {
            attributes[.kern] = -0.5
        }
        
        return attributes
    }
    
    /// Create body text attributes with optimal readability
    func bodyAttributes() -> [NSAttributedString.Key: Any] {
        let font = createFont(
            name: theme.bodyFontName,
            size: theme.baseFontSize * zoomLevel,
            weight: .regular
        )
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = theme.lineHeightMultiple
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: theme.textColor,
            .paragraphStyle: paragraphStyle
        ]
        
        // Enable ligatures for better text flow
        attributes[.ligature] = 1
        
        return attributes
    }
    
    /// Create code block attributes
    func codeBlockAttributes() -> [NSAttributedString.Key: Any] {
        let fontSize = theme.baseFontSize * 0.9 * zoomLevel
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.3
        paragraphStyle.paragraphSpacing = 8
        
        return [
            .font: font,
            .foregroundColor: theme.codeTextColor,
            .backgroundColor: theme.codeBackgroundColor,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    /// Create inline code attributes
    func inlineCodeAttributes() -> [NSAttributedString.Key: Any] {
        let fontSize = theme.baseFontSize * 0.9 * zoomLevel
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        return [
            .font: font,
            .foregroundColor: theme.codeTextColor,
            .backgroundColor: theme.codeBackgroundColor
        ]
    }
    
    /// Create blockquote attributes
    func blockquoteAttributes() -> [NSAttributedString.Key: Any] {
        var attrs = bodyAttributes()
        if let font = attrs[.font] as? NSFont {
            let italicDescriptor = font.fontDescriptor.withSymbolicTraits(.italic)
            attrs[.font] = NSFont(descriptor: italicDescriptor, size: font.pointSize)
        }
        attrs[.foregroundColor] = theme.blockquoteColor
        
        if let paragraphStyle = attrs[.paragraphStyle] as? NSMutableParagraphStyle {
            paragraphStyle.headIndent = 30
            paragraphStyle.firstLineHeadIndent = 30
        }
        
        return attrs
    }
    
    /// Apply smart typography replacements using cached regex patterns
    func applySmartTypography(to text: String) -> String {
        var result = text

        // Smart quotes - use cached regex for performance
        if let regex = Self.doubleQuoteRegex {
            result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(result.startIndex..., in: result), withTemplate: "\u{201C}$1\u{201D}")
        }
        if let regex = Self.singleQuoteRegex {
            result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(result.startIndex..., in: result), withTemplate: "\u{2018}$1\u{2019}")
        }

        // Handle apostrophes
        if let regex = Self.apostropheRegex {
            result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(result.startIndex..., in: result), withTemplate: "$1\u{2019}$2")
        }

        // Em dashes (simple string replacements - no regex needed)
        result = result.replacingOccurrences(of: "--", with: "\u{2014}")
        result = result.replacingOccurrences(of: " - ", with: " \u{2014} ")

        // Ellipsis
        result = result.replacingOccurrences(of: "...", with: "\u{2026}")

        return result
    }
    
    // MARK: - Private Helpers
    
    private func createFont(name: String, size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        if name == "-apple-system" {
            return NSFont.systemFont(ofSize: size, weight: weight)
        } else if let customFont = NSFont(name: name, size: size) {
            // Try to apply weight if possible
            let traits: NSFontTraitMask = weight == .bold ? .boldFontMask : []
            if traits != [] {
                return NSFontManager.shared.convert(customFont, toHaveTrait: traits)
            }
            return customFont
        } else {
            return NSFont.systemFont(ofSize: size, weight: weight)
        }
    }

    /// Calculate optical font weight based on size and theme
    /// Larger text appears heavier, so we reduce weight for large headings
    /// Dark mode text can feel harsh, so we lighten slightly
    private func opticalWeight(baseWeight: NSFont.Weight, pointSize: CGFloat, isDark: Bool) -> NSFont.Weight {
        // Weight order for stepping: ultraLight, thin, light, regular, medium, semibold, bold, heavy, black
        let weights: [NSFont.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]

        guard let baseIndex = weights.firstIndex(of: baseWeight) else {
            return baseWeight
        }

        var adjustment = 0

        // Larger text = lighter weight (reduces visual heaviness)
        if pointSize > 32 {
            adjustment -= 2  // Very large: reduce by 2 steps
        } else if pointSize > 24 {
            adjustment -= 1  // Large: reduce by 1 step
        }

        // Dark mode = slightly lighter (reduces eye strain)
        if isDark {
            adjustment -= 1
        }

        let newIndex = max(0, min(weights.count - 1, baseIndex + adjustment))
        return weights[newIndex]
    }
}