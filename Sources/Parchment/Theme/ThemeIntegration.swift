import Cocoa

/// Bridge between existing ThemeManager and new ParchmentTheme system
extension ThemeManager {
    
    /// Convert current Theme to ParchmentTheme for use with EnhancedMarkdownRenderer
    var currentParchmentTheme: ParchmentTheme? {
        // Map existing themes to new ParchmentThemes
        switch currentTheme.name {
        case "Default":
            return .minimal
        case "Dark", "Solarized Dark", "Dracula":
            return .midnight
        case "Solarized Light":
            return .sepia
        case "GitHub":
            return .elegant
        default:
            // Create a custom ParchmentTheme from the current Theme
            return createParchmentTheme(from: currentTheme)
        }
    }
    
    private func createParchmentTheme(from theme: Theme) -> ParchmentTheme {
        return ParchmentTheme(
            name: theme.name,
            backgroundColor: theme.colors.background,
            textColor: theme.colors.text,
            headingColor: theme.colors.headingText,
            linkColor: theme.colors.linkText,
            codeBackgroundColor: theme.colors.codeBackground,
            codeTextColor: theme.colors.codeText,
            blockquoteColor: theme.colors.blockquoteBackground,
            selectionColor: theme.colors.selection,
            cursorColor: theme.colors.cursor,
            lineNumberColor: theme.colors.lineNumbers,
            bodyFontName: theme.fonts.body.fontName,
            headingFontName: theme.fonts.heading1.fontName,
            codeFontName: theme.fonts.code.fontName,
            baseFontSize: theme.fonts.body.pointSize,
            lineHeightMultiple: theme.spacing.lineSpacing,
            cornerRadius: 0,
            contentInsets: NSEdgeInsets(top: 40, left: 60, bottom: 40, right: 60),
            useShadows: false,
            animationDuration: 0.25
        )
    }
    
    /// Apply ParchmentTheme to the application
    func applyParchmentTheme(_ parchmentTheme: ParchmentTheme) {
        // Update the current theme to match
        if let matchingTheme = availableThemes().first(where: { $0.name == parchmentTheme.name }) {
            setTheme(matchingTheme)
        } else {
            // Create a new Theme from ParchmentTheme
            let newTheme = Theme(
                name: parchmentTheme.name,
                isDark: parchmentTheme.backgroundColor.brightnessComponent < 0.5,
                colors: ColorScheme(
                    background: parchmentTheme.backgroundColor,
                    text: parchmentTheme.textColor,
                    headingText: parchmentTheme.headingColor,
                    linkText: parchmentTheme.linkColor,
                    codeBackground: parchmentTheme.codeBackgroundColor,
                    codeText: parchmentTheme.codeTextColor,
                    blockquoteBackground: parchmentTheme.blockquoteColor,
                    blockquoteBorder: parchmentTheme.blockquoteColor,
                    selection: parchmentTheme.selectionColor,
                    cursor: parchmentTheme.cursorColor,
                    lineNumbers: parchmentTheme.lineNumberColor
                ),
                fonts: FontScheme(
                    body: NSFont(name: parchmentTheme.bodyFontName, size: parchmentTheme.baseFontSize) 
                        ?? NSFont.systemFont(ofSize: parchmentTheme.baseFontSize),
                    heading1: NSFont(name: parchmentTheme.headingFontName, size: parchmentTheme.baseFontSize * 2.488) 
                        ?? NSFont.boldSystemFont(ofSize: parchmentTheme.baseFontSize * 2.488),
                    heading2: NSFont(name: parchmentTheme.headingFontName, size: parchmentTheme.baseFontSize * 2.074)
                        ?? NSFont.boldSystemFont(ofSize: parchmentTheme.baseFontSize * 2.074),
                    heading3: NSFont(name: parchmentTheme.headingFontName, size: parchmentTheme.baseFontSize * 1.728)
                        ?? NSFont.boldSystemFont(ofSize: parchmentTheme.baseFontSize * 1.728),
                    heading4: NSFont(name: parchmentTheme.headingFontName, size: parchmentTheme.baseFontSize * 1.44)
                        ?? NSFont.boldSystemFont(ofSize: parchmentTheme.baseFontSize * 1.44),
                    heading5: NSFont(name: parchmentTheme.headingFontName, size: parchmentTheme.baseFontSize * 1.2)
                        ?? NSFont.boldSystemFont(ofSize: parchmentTheme.baseFontSize * 1.2),
                    heading6: NSFont(name: parchmentTheme.headingFontName, size: parchmentTheme.baseFontSize)
                        ?? NSFont.boldSystemFont(ofSize: parchmentTheme.baseFontSize),
                    code: NSFont(name: parchmentTheme.codeFontName, size: parchmentTheme.baseFontSize * 0.9)
                        ?? NSFont.monospacedSystemFont(ofSize: parchmentTheme.baseFontSize * 0.9, weight: .regular),
                    quote: NSFont(name: parchmentTheme.bodyFontName, size: parchmentTheme.baseFontSize)?.withItalic()
                        ?? NSFont.systemFont(ofSize: parchmentTheme.baseFontSize).withItalic()
                ),
                spacing: SpacingScheme(
                    lineSpacing: parchmentTheme.lineHeightMultiple,
                    paragraphSpacing: 12,
                    headingSpacing: 20,
                    codeBlockPadding: 12,
                    blockquotePadding: 16
                ),
                syntaxColors: SyntaxColors()
            )
            setTheme(newTheme)
        }
    }
}

// Extension to get brightness for dark mode detection
extension NSColor {
    var brightnessComponent: CGFloat {
        guard let rgb = usingColorSpace(.deviceRGB) else { return 0.5 }
        return (rgb.redComponent * 0.299 + rgb.greenComponent * 0.587 + rgb.blueComponent * 0.114)
    }
}