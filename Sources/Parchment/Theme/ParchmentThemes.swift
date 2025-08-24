import Cocoa

/// Beautiful, hand-crafted themes for Parchment
struct ParchmentTheme {
    let name: String
    let backgroundColor: NSColor
    let textColor: NSColor
    let headingColor: NSColor
    let linkColor: NSColor
    let codeBackgroundColor: NSColor
    let codeTextColor: NSColor
    let blockquoteColor: NSColor
    let selectionColor: NSColor
    let cursorColor: NSColor
    let lineNumberColor: NSColor
    
    // Typography settings
    let bodyFontName: String
    let headingFontName: String
    let codeFontName: String
    let baseFontSize: CGFloat
    let lineHeightMultiple: CGFloat
    
    // Visual settings
    let cornerRadius: CGFloat
    let contentInsets: NSEdgeInsets
    let useShadows: Bool
    let animationDuration: TimeInterval
}

extension ParchmentTheme {
    
    /// Clean, minimal theme inspired by iA Writer
    static let minimal = ParchmentTheme(
        name: "Minimal",
        backgroundColor: NSColor(calibratedWhite: 0.98, alpha: 1.0),
        textColor: NSColor(calibratedWhite: 0.15, alpha: 1.0),
        headingColor: NSColor(calibratedWhite: 0.0, alpha: 1.0),
        linkColor: NSColor(calibratedRed: 0.0, green: 0.478, blue: 1.0, alpha: 1.0),
        codeBackgroundColor: NSColor(calibratedWhite: 0.94, alpha: 1.0),
        codeTextColor: NSColor(calibratedWhite: 0.2, alpha: 1.0),
        blockquoteColor: NSColor(calibratedWhite: 0.4, alpha: 1.0),
        selectionColor: NSColor(calibratedRed: 0.678, green: 0.847, blue: 1.0, alpha: 0.3),
        cursorColor: NSColor(calibratedRed: 0.0, green: 0.478, blue: 1.0, alpha: 1.0),
        lineNumberColor: NSColor(calibratedWhite: 0.7, alpha: 1.0),
        bodyFontName: "-apple-system",
        headingFontName: "-apple-system",
        codeFontName: "SF Mono",
        baseFontSize: 16,
        lineHeightMultiple: 1.7,
        cornerRadius: 0,
        contentInsets: NSEdgeInsets(top: 40, left: 60, bottom: 40, right: 60),
        useShadows: false,
        animationDuration: 0.25
    )
    
    /// Elegant serif theme inspired by Medium
    static let elegant = ParchmentTheme(
        name: "Elegant",
        backgroundColor: NSColor(calibratedWhite: 1.0, alpha: 1.0),
        textColor: NSColor(calibratedWhite: 0.08, alpha: 1.0),
        headingColor: NSColor(calibratedWhite: 0.0, alpha: 1.0),
        linkColor: NSColor(calibratedRed: 0.11, green: 0.56, blue: 0.48, alpha: 1.0),
        codeBackgroundColor: NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.96, alpha: 1.0),
        codeTextColor: NSColor(calibratedWhite: 0.15, alpha: 1.0),
        blockquoteColor: NSColor(calibratedWhite: 0.3, alpha: 1.0),
        selectionColor: NSColor(calibratedRed: 0.11, green: 0.56, blue: 0.48, alpha: 0.2),
        cursorColor: NSColor(calibratedRed: 0.11, green: 0.56, blue: 0.48, alpha: 1.0),
        lineNumberColor: NSColor(calibratedWhite: 0.75, alpha: 1.0),
        bodyFontName: "Charter",
        headingFontName: "Georgia",
        codeFontName: "SF Mono",
        baseFontSize: 18,
        lineHeightMultiple: 1.8,
        cornerRadius: 0,
        contentInsets: NSEdgeInsets(top: 50, left: 80, bottom: 50, right: 80),
        useShadows: false,
        animationDuration: 0.3
    )
    
    /// Dark theme optimized for night reading
    static let midnight = ParchmentTheme(
        name: "Midnight",
        backgroundColor: NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.10, alpha: 1.0),
        textColor: NSColor(calibratedRed: 0.82, green: 0.84, blue: 0.86, alpha: 1.0),
        headingColor: NSColor(calibratedWhite: 0.95, alpha: 1.0),
        linkColor: NSColor(calibratedRed: 0.40, green: 0.68, blue: 1.0, alpha: 1.0),
        codeBackgroundColor: NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.08, alpha: 1.0),
        codeTextColor: NSColor(calibratedRed: 0.78, green: 0.80, blue: 0.82, alpha: 1.0),
        blockquoteColor: NSColor(calibratedWhite: 0.6, alpha: 1.0),
        selectionColor: NSColor(calibratedRed: 0.20, green: 0.34, blue: 0.50, alpha: 0.5),
        cursorColor: NSColor(calibratedRed: 0.40, green: 0.68, blue: 1.0, alpha: 1.0),
        lineNumberColor: NSColor(calibratedWhite: 0.4, alpha: 1.0),
        bodyFontName: "-apple-system",
        headingFontName: "-apple-system",
        codeFontName: "SF Mono",
        baseFontSize: 16,
        lineHeightMultiple: 1.7,
        cornerRadius: 0,
        contentInsets: NSEdgeInsets(top: 40, left: 60, bottom: 40, right: 60),
        useShadows: false,
        animationDuration: 0.25
    )
    
    /// Warm, paper-like theme for comfortable reading
    static let sepia = ParchmentTheme(
        name: "Sepia",
        backgroundColor: NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.89, alpha: 1.0),
        textColor: NSColor(calibratedRed: 0.24, green: 0.20, blue: 0.15, alpha: 1.0),
        headingColor: NSColor(calibratedRed: 0.18, green: 0.15, blue: 0.10, alpha: 1.0),
        linkColor: NSColor(calibratedRed: 0.55, green: 0.35, blue: 0.20, alpha: 1.0),
        codeBackgroundColor: NSColor(calibratedRed: 0.94, green: 0.91, blue: 0.84, alpha: 1.0),
        codeTextColor: NSColor(calibratedRed: 0.30, green: 0.25, blue: 0.20, alpha: 1.0),
        blockquoteColor: NSColor(calibratedRed: 0.45, green: 0.40, blue: 0.35, alpha: 1.0),
        selectionColor: NSColor(calibratedRed: 0.90, green: 0.82, blue: 0.65, alpha: 0.4),
        cursorColor: NSColor(calibratedRed: 0.55, green: 0.35, blue: 0.20, alpha: 1.0),
        lineNumberColor: NSColor(calibratedRed: 0.60, green: 0.55, blue: 0.45, alpha: 1.0),
        bodyFontName: "Baskerville",
        headingFontName: "Baskerville",
        codeFontName: "SF Mono",
        baseFontSize: 17,
        lineHeightMultiple: 1.75,
        cornerRadius: 0,
        contentInsets: NSEdgeInsets(top: 45, left: 70, bottom: 45, right: 70),
        useShadows: false,
        animationDuration: 0.3
    )
    
    /// High contrast theme for accessibility
    static let highContrast = ParchmentTheme(
        name: "High Contrast",
        backgroundColor: NSColor.white,
        textColor: NSColor.black,
        headingColor: NSColor.black,
        linkColor: NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.8, alpha: 1.0),
        codeBackgroundColor: NSColor(calibratedWhite: 0.9, alpha: 1.0),
        codeTextColor: NSColor.black,
        blockquoteColor: NSColor(calibratedWhite: 0.2, alpha: 1.0),
        selectionColor: NSColor(calibratedRed: 1.0, green: 1.0, blue: 0.0, alpha: 0.5),
        cursorColor: NSColor.black,
        lineNumberColor: NSColor(calibratedWhite: 0.5, alpha: 1.0),
        bodyFontName: "-apple-system",
        headingFontName: "-apple-system",
        codeFontName: "SF Mono",
        baseFontSize: 18,
        lineHeightMultiple: 1.8,
        cornerRadius: 0,
        contentInsets: NSEdgeInsets(top: 40, left: 60, bottom: 40, right: 60),
        useShadows: false,
        animationDuration: 0.15
    )
    
    /// All available themes
    static let all: [ParchmentTheme] = [
        .minimal,
        .elegant,
        .midnight,
        .sepia,
        .highContrast
    ]
    
    /// Get theme by name
    static func theme(named name: String) -> ParchmentTheme? {
        return all.first { $0.name == name }
    }
}

// MARK: - Theme Application

extension NSTextView {
    func applyTheme(_ theme: ParchmentTheme) {
        backgroundColor = theme.backgroundColor
        textColor = theme.textColor
        insertionPointColor = theme.cursorColor
        selectedTextAttributes = [
            .backgroundColor: theme.selectionColor
        ]
        
        // Apply typography settings
        if let storage = textStorage {
            storage.font = NSFont(
                name: theme.bodyFontName,
                size: theme.baseFontSize
            ) ?? NSFont.systemFont(ofSize: theme.baseFontSize)
        }
        
        // Apply paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = theme.lineHeightMultiple
        typingAttributes[.paragraphStyle] = paragraphStyle
    }
}

extension NSScrollView {
    func applyTheme(_ theme: ParchmentTheme) {
        backgroundColor = theme.backgroundColor
        drawsBackground = true
        
        // Apply content insets
        contentView.contentInsets = theme.contentInsets
    }
}