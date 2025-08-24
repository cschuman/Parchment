import Cocoa

/// Enhanced typography engine for beautiful markdown rendering
final class TypographyEngine {
    
    struct TypographySettings {
        var baseFontSize: CGFloat = 16
        var lineHeightMultiple: CGFloat = 1.6
        var paragraphSpacing: CGFloat = 12
        var useOpticalSizing: Bool = true
        var enableLigatures: Bool = true
        var enableKerning: Bool = true
        var theme: TypographyTheme = .default
    }
    
    enum TypographyTheme {
        case `default`
        case serif
        case mono
        case elegant
        
        var bodyFont: String {
            switch self {
            case .default: return "-apple-system"
            case .serif: return "New York"
            case .mono: return "SF Mono"
            case .elegant: return "Hoefler Text"
            }
        }
        
        var headingFont: String {
            switch self {
            case .default: return "-apple-system"
            case .serif: return "New York"
            case .mono: return "SF Mono"
            case .elegant: return "Hoefler Text"
            }
        }
        
        var codeFont: String {
            return "SF Mono"
        }
    }
    
    private let settings: TypographySettings
    
    init(settings: TypographySettings = TypographySettings()) {
        self.settings = settings
    }
    
    /// Create optimized paragraph style for body text
    func bodyParagraphStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = settings.lineHeightMultiple
        style.paragraphSpacing = settings.paragraphSpacing
        style.paragraphSpacingBefore = 0
        style.lineBreakMode = .byWordWrapping
        
        // Add subtle first-line indent for better readability
        style.firstLineHeadIndent = 0
        style.headIndent = 0
        style.tailIndent = 0
        
        return style
    }
    
    /// Create heading attributes with perfect visual hierarchy
    func headingAttributes(level: Int, zoomLevel: CGFloat = 1.0) -> [NSAttributedString.Key: Any] {
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
        let fontSize = settings.baseFontSize * scale * zoomLevel
        
        // Use different weights for hierarchy
        let weight: NSFont.Weight = {
            switch level {
            case 1: return .bold
            case 2: return .semibold
            case 3: return .medium
            default: return .regular
            }
        }()
        
        let font = createFont(
            name: settings.theme.headingFont,
            size: fontSize,
            weight: weight
        )
        
        // Tighter line height for headings
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.paragraphSpacingBefore = settings.paragraphSpacing * 1.5
        paragraphStyle.paragraphSpacing = settings.paragraphSpacing * 0.75
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
        
        // Add kerning for large headings
        if level <= 2 && settings.enableKerning {
            attributes[.kern] = -0.5
        }
        
        return attributes
    }
    
    /// Create body text attributes with optimal readability
    func bodyAttributes(zoomLevel: CGFloat = 1.0) -> [NSAttributedString.Key: Any] {
        let font = createFont(
            name: settings.theme.bodyFont,
            size: settings.baseFontSize * zoomLevel,
            weight: .regular
        )
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: bodyParagraphStyle()
        ]
        
        // Enable ligatures for better text flow
        if settings.enableLigatures {
            attributes[.ligature] = 1
        }
        
        return attributes
    }
    
    /// Create code block attributes with monospace font
    func codeBlockAttributes(zoomLevel: CGFloat = 1.0) -> [NSAttributedString.Key: Any] {
        let fontSize = (settings.baseFontSize * 0.9) * zoomLevel
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.4
        paragraphStyle.paragraphSpacing = settings.paragraphSpacing
        
        // Add background for code blocks
        let backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5)
        
        return [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: backgroundColor,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    /// Create inline code attributes
    func inlineCodeAttributes(zoomLevel: CGFloat = 1.0) -> [NSAttributedString.Key: Any] {
        let fontSize = (settings.baseFontSize * 0.9) * zoomLevel
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        let backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.3)
        
        return [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: backgroundColor
        ]
    }
    
    /// Create blockquote attributes with visual distinction
    func blockquoteAttributes(zoomLevel: CGFloat = 1.0) -> [NSAttributedString.Key: Any] {
        let font = createFont(
            name: settings.theme.bodyFont,
            size: settings.baseFontSize * zoomLevel,
            weight: .regular,
            italic: true
        )
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = settings.lineHeightMultiple
        paragraphStyle.headIndent = 30
        paragraphStyle.firstLineHeadIndent = 30
        paragraphStyle.paragraphSpacing = settings.paragraphSpacing
        
        return [
            .font: font,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]
    }
    
    /// Create emphasis (italic) attributes
    func emphasisAttributes(baseFont: NSFont) -> [NSAttributedString.Key: Any] {
        let italicFont = NSFontManager.shared.convert(
            baseFont,
            toHaveTrait: .italicFontMask
        )
        
        return [.font: italicFont]
    }
    
    /// Create strong (bold) attributes
    func strongAttributes(baseFont: NSFont) -> [NSAttributedString.Key: Any] {
        let boldFont = NSFontManager.shared.convert(
            baseFont,
            toHaveTrait: .boldFontMask
        )
        
        return [.font: boldFont]
    }
    
    /// Create link attributes with subtle styling
    func linkAttributes() -> [NSAttributedString.Key: Any] {
        return [
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: NSColor.linkColor.withAlphaComponent(0.3),
            .cursor: NSCursor.pointingHand
        ]
    }
    
    // MARK: - Private Helpers
    
    private func createFont(name: String, size: CGFloat, weight: NSFont.Weight = .regular, italic: Bool = false) -> NSFont {
        var font: NSFont
        
        if name == "-apple-system" {
            font = NSFont.systemFont(ofSize: size, weight: weight)
        } else if let customFont = NSFont(name: name, size: size) {
            font = customFont
        } else {
            font = NSFont.systemFont(ofSize: size, weight: weight)
        }
        
        // Apply optical sizing if available and enabled
        if settings.useOpticalSizing {
            if let opticalFont = applyOpticalSizing(to: font) {
                font = opticalFont
            }
        }
        
        // Apply italic if needed
        if italic {
            font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        }
        
        return font
    }
    
    private func applyOpticalSizing(to font: NSFont) -> NSFont? {
        // Create font descriptor with optical size attribute
        let descriptor = font.fontDescriptor.addingAttributes([
            .featureSettings: [
                [
                    NSFontDescriptor.FeatureKey.typeIdentifier: kStylisticAlternativesType,
                    NSFontDescriptor.FeatureKey.selectorIdentifier: kStylisticAltOneOnSelector
                ]
            ]
        ])
        
        return NSFont(descriptor: descriptor, size: font.pointSize)
    }
}