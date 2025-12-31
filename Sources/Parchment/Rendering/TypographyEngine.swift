import Cocoa
import CoreText

// MARK: - Variable Font Axis Constants

/// OpenType font variation axis tags
private enum FontVariationAxis {
    /// Weight axis tag ('wght') - controls font weight from thin to black
    static let weight: UInt32 = 0x77676874  // 'wght'
    /// Width axis tag ('wdth') - controls font width from condensed to expanded
    static let width: UInt32 = 0x77647468   // 'wdth'
    /// Optical size axis tag ('opsz') - adjusts design for different point sizes
    static let opticalSize: UInt32 = 0x6F70737A  // 'opsz'
}

/// Maps NSFont.Weight to variable font weight axis values (100-900 scale)
private func variableFontWeight(for weight: NSFont.Weight) -> CGFloat {
    // OpenType weight axis values: 100 (Thin) to 900 (Black)
    switch weight {
    case .ultraLight: return 100
    case .thin: return 200
    case .light: return 300
    case .regular: return 400
    case .medium: return 500
    case .semibold: return 600
    case .bold: return 700
    case .heavy: return 800
    case .black: return 900
    default: return 400
    }
}

/// Provides variable font creation with axis control
struct VariableFontProvider {

    /// Check if a font supports variable font axes
    static func supportsVariableAxes(_ font: NSFont) -> Bool {
        let ctFont = font as CTFont
        guard let axes = CTFontCopyVariationAxes(ctFont) as? [[String: Any]] else {
            return false
        }
        return !axes.isEmpty
    }

    /// Get available variation axes for a font
    static func availableAxes(for font: NSFont) -> [UInt32: (min: CGFloat, max: CGFloat, default: CGFloat)] {
        let ctFont = font as CTFont
        guard let axes = CTFontCopyVariationAxes(ctFont) as? [[String: Any]] else {
            return [:]
        }

        var result: [UInt32: (min: CGFloat, max: CGFloat, default: CGFloat)] = [:]
        for axis in axes {
            guard let identifier = axis[kCTFontVariationAxisIdentifierKey as String] as? UInt32,
                  let minValue = axis[kCTFontVariationAxisMinimumValueKey as String] as? CGFloat,
                  let maxValue = axis[kCTFontVariationAxisMaximumValueKey as String] as? CGFloat,
                  let defaultValue = axis[kCTFontVariationAxisDefaultValueKey as String] as? CGFloat else {
                continue
            }
            result[identifier] = (min: minValue, max: maxValue, default: defaultValue)
        }
        return result
    }

    /// Create a font with specific variable font axis values
    /// Returns nil if the font does not support the requested axes
    static func createVariableFont(
        from baseFont: NSFont,
        weight: CGFloat? = nil,
        width: CGFloat? = nil,
        opticalSize: CGFloat? = nil
    ) -> NSFont? {
        let ctFont = baseFont as CTFont
        let axes = availableAxes(for: baseFont)

        // Build variation dictionary with only supported axes
        var variations: [UInt32: CGFloat] = [:]

        if let weight = weight, let weightAxis = axes[FontVariationAxis.weight] {
            let clampedWeight = min(max(weight, weightAxis.min), weightAxis.max)
            variations[FontVariationAxis.weight] = clampedWeight
        }

        if let width = width, let widthAxis = axes[FontVariationAxis.width] {
            let clampedWidth = min(max(width, widthAxis.min), widthAxis.max)
            variations[FontVariationAxis.width] = clampedWidth
        }

        if let opticalSize = opticalSize, let opsAxis = axes[FontVariationAxis.opticalSize] {
            let clampedOps = min(max(opticalSize, opsAxis.min), opsAxis.max)
            variations[FontVariationAxis.opticalSize] = clampedOps
        }

        guard !variations.isEmpty else {
            return nil
        }

        // Convert UInt32 keys to CFNumber for CoreText
        var cfVariations: [CFNumber: CFNumber] = [:]
        for (key, value) in variations {
            var keyVal = key
            var valueVal = value
            let cfKey = CFNumberCreate(nil, .sInt32Type, &keyVal)!
            let cfValue = CFNumberCreate(nil, .cgFloatType, &valueVal)!
            cfVariations[cfKey] = cfValue
        }

        // Create new font descriptor with variations
        let attributes: [CFString: Any] = [
            kCTFontVariationAttribute: cfVariations
        ]

        let originalDescriptor = CTFontCopyFontDescriptor(ctFont)
        let variantDescriptor = CTFontDescriptorCreateCopyWithAttributes(
            originalDescriptor,
            attributes as CFDictionary
        )

        let variantFont = CTFontCreateWithFontDescriptor(
            variantDescriptor,
            baseFont.pointSize,
            nil
        )

        return variantFont as NSFont
    }

    /// Create a font with smooth weight transition for heading hierarchy
    /// Uses variable font weight axis for precise control, falls back to standard weights
    static func createHeadingFont(
        name: String,
        size: CGFloat,
        targetWeight: NSFont.Weight,
        headingLevel: Int
    ) -> NSFont {
        // First, get a base font
        let baseFont: NSFont
        if name == "-apple-system" {
            baseFont = NSFont.systemFont(ofSize: size, weight: .regular)
        } else if let customFont = NSFont(name: name, size: size) {
            baseFont = customFont
        } else {
            baseFont = NSFont.systemFont(ofSize: size, weight: targetWeight)
        }

        // Check if variable font axes are available
        let axes = availableAxes(for: baseFont)

        if axes[FontVariationAxis.weight] != nil {
            // Use variable font weight for smooth transitions
            let targetWeightValue = variableFontWeight(for: targetWeight)

            // Apply smooth weight curve based on heading level
            // H1: full weight, H6: lighter weight for visual hierarchy
            let weightCurve: [CGFloat] = [0, 1.0, 0.95, 0.9, 0.85, 0.8, 0.75]
            let multiplier = weightCurve[min(headingLevel, 6)]
            let adjustedWeight = 400 + (targetWeightValue - 400) * multiplier

            // Also apply optical size if available for better rendering at different sizes
            let opticalSize = axes[FontVariationAxis.opticalSize] != nil ? size : nil

            if let variableFont = createVariableFont(
                from: baseFont,
                weight: adjustedWeight,
                opticalSize: opticalSize
            ) {
                return variableFont
            }
        }

        // Fallback: use standard font weight
        if name == "-apple-system" {
            return NSFont.systemFont(ofSize: size, weight: targetWeight)
        } else if let customFont = NSFont(name: name, size: size) {
            let traits: NSFontTraitMask = targetWeight.rawValue >= NSFont.Weight.bold.rawValue ? .boldFontMask : []
            if traits != [] {
                return NSFontManager.shared.convert(customFont, toHaveTrait: traits)
            }
            return customFont
        }

        return NSFont.systemFont(ofSize: size, weight: targetWeight)
    }
}

/// Enhanced typography engine for beautiful markdown rendering
final class TypographyEngine {

    private let theme: ParchmentTheme
    private let zoomLevel: CGFloat

    /// Whether to use variable font features when available
    let useVariableFonts: Bool

    // MARK: - Baseline Grid

    /// Base grid unit for vertical rhythm (8pt baseline grid)
    static let baselineGridSize: CGFloat = 8.0

    // MARK: - Cached Regex Patterns (compiled once, reused for performance)

    private static let doubleQuoteRegex = try? NSRegularExpression(pattern: "\"([^\"]*?)\"", options: [])
    private static let singleQuoteRegex = try? NSRegularExpression(pattern: "'([^']*?)'", options: [])
    private static let apostropheRegex = try? NSRegularExpression(pattern: "([a-zA-Z])'([a-zA-Z])", options: [])

    init(theme: ParchmentTheme = ParchmentTheme.current, zoomLevel: CGFloat = 1.0, useVariableFonts: Bool = true) {
        self.theme = theme
        self.zoomLevel = zoomLevel
        self.useVariableFonts = useVariableFonts
    }

    // MARK: - Baseline Grid Helpers

    /// Rounds a value to the nearest baseline grid increment
    /// - Parameters:
    ///   - value: The value to snap to the grid
    ///   - gridSize: The grid size (default: 8pt)
    /// - Returns: The value rounded to the nearest grid increment
    static func roundToGrid(_ value: CGFloat, gridSize: CGFloat = baselineGridSize) -> CGFloat {
        return (value / gridSize).rounded() * gridSize
    }

    /// Rounds a value up to the next baseline grid increment
    /// - Parameters:
    ///   - value: The value to snap to the grid
    ///   - gridSize: The grid size (default: 8pt)
    /// - Returns: The value rounded up to the next grid increment
    static func ceilToGrid(_ value: CGFloat, gridSize: CGFloat = baselineGridSize) -> CGFloat {
        return ceil(value / gridSize) * gridSize
    }

    /// Calculates the line height multiple needed to align text to the baseline grid
    /// - Parameters:
    ///   - fontSize: The font size in points
    ///   - desiredMultiple: The preferred line height multiple (used as minimum)
    ///   - gridSize: The grid size (default: 8pt)
    /// - Returns: A line height multiple that aligns to the grid
    static func gridAlignedLineHeightMultiple(
        fontSize: CGFloat,
        desiredMultiple: CGFloat,
        gridSize: CGFloat = baselineGridSize
    ) -> CGFloat {
        // Calculate the raw line height
        let rawLineHeight = fontSize * desiredMultiple
        // Round up to grid to ensure we have enough space
        let gridLineHeight = ceilToGrid(rawLineHeight, gridSize: gridSize)
        // Return the multiple needed to achieve this grid-aligned line height
        return gridLineHeight / fontSize
    }
    
    /// Create heading attributes with golden ratio scaling and variable font support
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

        // Use variable font provider for smooth weight transitions when enabled
        let font: NSFont
        if useVariableFonts {
            font = VariableFontProvider.createHeadingFont(
                name: theme.headingFontName,
                size: fontSize,
                targetWeight: weight,
                headingLevel: level
            )
        } else {
            font = createFont(
                name: theme.headingFontName,
                size: fontSize,
                weight: weight
            )
        }

        // Tighter line height for headings, aligned to baseline grid
        let gridAlignedMultiple = Self.gridAlignedLineHeightMultiple(
            fontSize: fontSize,
            desiredMultiple: 1.2
        )

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = gridAlignedMultiple
        // Snap paragraph spacing to grid (16pt and 8pt are already multiples of 8)
        paragraphStyle.paragraphSpacingBefore = Self.roundToGrid(16 * zoomLevel)
        paragraphStyle.paragraphSpacing = Self.roundToGrid(8 * zoomLevel)

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
        let fontSize = theme.baseFontSize * zoomLevel
        let font = createFont(
            name: theme.bodyFontName,
            size: fontSize,
            weight: .regular
        )

        // Calculate grid-aligned line height
        let gridAlignedMultiple = Self.gridAlignedLineHeightMultiple(
            fontSize: fontSize,
            desiredMultiple: theme.lineHeightMultiple
        )

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = gridAlignedMultiple
        paragraphStyle.paragraphSpacing = Self.roundToGrid(8 * zoomLevel)
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

        // Grid-aligned line height for code blocks
        let gridAlignedMultiple = Self.gridAlignedLineHeightMultiple(
            fontSize: fontSize,
            desiredMultiple: 1.3
        )

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = gridAlignedMultiple
        paragraphStyle.paragraphSpacing = Self.roundToGrid(8 * zoomLevel)

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
            // Grid-aligned indentation (32pt = 4 grid units)
            let indent = Self.roundToGrid(32 * zoomLevel)
            paragraphStyle.headIndent = indent
            paragraphStyle.firstLineHeadIndent = indent
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