import Cocoa

/// Syntax highlighting colors for code blocks
public struct SyntaxColors {
    let keyword: NSColor
    let string: NSColor
    let comment: NSColor
    let number: NSColor
    let type: NSColor
    let function: NSColor
    let variable: NSColor
    let operatorColor: NSColor

    static let light = SyntaxColors(
        keyword: NSColor.systemPurple,
        string: NSColor.systemRed,
        comment: NSColor.systemGreen,
        number: NSColor.systemBlue,
        type: NSColor.systemTeal,
        function: NSColor.systemIndigo,
        variable: NSColor.systemOrange,
        operatorColor: NSColor.systemBrown
    )

    static let dark = SyntaxColors(
        keyword: NSColor(calibratedRed: 0.78, green: 0.56, blue: 0.95, alpha: 1.0),
        string: NSColor(calibratedRed: 0.95, green: 0.54, blue: 0.54, alpha: 1.0),
        comment: NSColor(calibratedRed: 0.55, green: 0.75, blue: 0.55, alpha: 1.0),
        number: NSColor(calibratedRed: 0.55, green: 0.75, blue: 0.95, alpha: 1.0),
        type: NSColor(calibratedRed: 0.55, green: 0.85, blue: 0.85, alpha: 1.0),
        function: NSColor(calibratedRed: 0.65, green: 0.65, blue: 0.95, alpha: 1.0),
        variable: NSColor(calibratedRed: 0.95, green: 0.75, blue: 0.55, alpha: 1.0),
        operatorColor: NSColor(calibratedRed: 0.85, green: 0.75, blue: 0.65, alpha: 1.0)
    )

    static let sepia = SyntaxColors(
        keyword: NSColor(calibratedRed: 0.55, green: 0.30, blue: 0.55, alpha: 1.0),
        string: NSColor(calibratedRed: 0.70, green: 0.35, blue: 0.30, alpha: 1.0),
        comment: NSColor(calibratedRed: 0.50, green: 0.55, blue: 0.45, alpha: 1.0),
        number: NSColor(calibratedRed: 0.35, green: 0.50, blue: 0.65, alpha: 1.0),
        type: NSColor(calibratedRed: 0.40, green: 0.55, blue: 0.55, alpha: 1.0),
        function: NSColor(calibratedRed: 0.45, green: 0.40, blue: 0.60, alpha: 1.0),
        variable: NSColor(calibratedRed: 0.65, green: 0.50, blue: 0.35, alpha: 1.0),
        operatorColor: NSColor(calibratedRed: 0.55, green: 0.45, blue: 0.40, alpha: 1.0)
    )

    // Dracula theme colors - purple/pink/cyan accents
    static let dracula = SyntaxColors(
        keyword: NSColor(calibratedRed: 1.0, green: 0.47, blue: 0.78, alpha: 1.0),      // Pink
        string: NSColor(calibratedRed: 0.95, green: 0.98, blue: 0.48, alpha: 1.0),      // Yellow
        comment: NSColor(calibratedRed: 0.38, green: 0.45, blue: 0.53, alpha: 1.0),     // Gray
        number: NSColor(calibratedRed: 0.74, green: 0.58, blue: 0.98, alpha: 1.0),      // Purple
        type: NSColor(calibratedRed: 0.55, green: 0.95, blue: 0.90, alpha: 1.0),        // Cyan
        function: NSColor(calibratedRed: 0.31, green: 0.98, blue: 0.48, alpha: 1.0),    // Green
        variable: NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.95, alpha: 1.0),    // Foreground
        operatorColor: NSColor(calibratedRed: 1.0, green: 0.47, blue: 0.78, alpha: 1.0) // Pink
    )

    // Nord theme colors - arctic, bluish palette
    static let nord = SyntaxColors(
        keyword: NSColor(calibratedRed: 0.51, green: 0.63, blue: 0.76, alpha: 1.0),     // Frost blue
        string: NSColor(calibratedRed: 0.64, green: 0.75, blue: 0.55, alpha: 1.0),      // Aurora green
        comment: NSColor(calibratedRed: 0.38, green: 0.43, blue: 0.50, alpha: 1.0),     // Polar night 4
        number: NSColor(calibratedRed: 0.71, green: 0.56, blue: 0.68, alpha: 1.0),      // Aurora purple
        type: NSColor(calibratedRed: 0.56, green: 0.74, blue: 0.73, alpha: 1.0),        // Frost cyan
        function: NSColor(calibratedRed: 0.53, green: 0.75, blue: 0.82, alpha: 1.0),    // Frost light blue
        variable: NSColor(calibratedRed: 0.85, green: 0.87, blue: 0.91, alpha: 1.0),    // Snow storm 1
        operatorColor: NSColor(calibratedRed: 0.51, green: 0.63, blue: 0.76, alpha: 1.0) // Frost blue
    )

    // Solarized Dark colors
    static let solarizedDark = SyntaxColors(
        keyword: NSColor(calibratedRed: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),     // Green
        string: NSColor(calibratedRed: 0.16, green: 0.63, blue: 0.60, alpha: 1.0),      // Cyan
        comment: NSColor(calibratedRed: 0.35, green: 0.43, blue: 0.46, alpha: 1.0),     // Base01
        number: NSColor(calibratedRed: 0.83, green: 0.37, blue: 0.00, alpha: 1.0),      // Orange
        type: NSColor(calibratedRed: 0.71, green: 0.54, blue: 0.00, alpha: 1.0),        // Yellow
        function: NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),    // Blue
        variable: NSColor(calibratedRed: 0.58, green: 0.63, blue: 0.63, alpha: 1.0),    // Base1
        operatorColor: NSColor(calibratedRed: 0.86, green: 0.20, blue: 0.18, alpha: 1.0) // Red
    )

    // Solarized Light colors
    static let solarizedLight = SyntaxColors(
        keyword: NSColor(calibratedRed: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),     // Green
        string: NSColor(calibratedRed: 0.16, green: 0.63, blue: 0.60, alpha: 1.0),      // Cyan
        comment: NSColor(calibratedRed: 0.58, green: 0.63, blue: 0.63, alpha: 1.0),     // Base1
        number: NSColor(calibratedRed: 0.83, green: 0.37, blue: 0.00, alpha: 1.0),      // Orange
        type: NSColor(calibratedRed: 0.71, green: 0.54, blue: 0.00, alpha: 1.0),        // Yellow
        function: NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),    // Blue
        variable: NSColor(calibratedRed: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),    // Base00
        operatorColor: NSColor(calibratedRed: 0.86, green: 0.20, blue: 0.18, alpha: 1.0) // Red
    )
}

/// Beautiful, hand-crafted themes for Parchment
public struct ParchmentTheme {
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
    var codeColor: NSColor { codeTextColor }  // Alias for compatibility

    // Syntax highlighting colors
    let syntaxColors: SyntaxColors

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

    /// Whether this is a dark theme (based on background brightness)
    var isDark: Bool {
        // Convert to grayscale to get brightness
        guard let rgbColor = backgroundColor.usingColorSpace(.sRGB) else {
            return false
        }
        // Luminance formula: 0.299*R + 0.587*G + 0.114*B
        let luminance = 0.299 * rgbColor.redComponent +
                        0.587 * rgbColor.greenComponent +
                        0.114 * rgbColor.blueComponent
        return luminance < 0.5
    }
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
        syntaxColors: .light,
        bodyFontName: "-apple-system",
        headingFontName: "-apple-system",
        codeFontName: "SF Mono",
        baseFontSize: 16,
        lineHeightMultiple: 1.4,
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
        syntaxColors: .light,
        bodyFontName: "Charter",
        headingFontName: "Georgia",
        codeFontName: "SF Mono",
        baseFontSize: 18,
        lineHeightMultiple: 1.5,
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
        syntaxColors: .dark,
        bodyFontName: "-apple-system",
        headingFontName: "-apple-system",
        codeFontName: "SF Mono",
        baseFontSize: 16,
        lineHeightMultiple: 1.4,
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
        syntaxColors: .sepia,
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
        syntaxColors: .light,
        bodyFontName: "-apple-system",
        headingFontName: "-apple-system",
        codeFontName: "SF Mono",
        baseFontSize: 18,
        lineHeightMultiple: 1.5,
        cornerRadius: 0,
        contentInsets: NSEdgeInsets(top: 40, left: 60, bottom: 40, right: 60),
        useShadows: false,
        animationDuration: 0.15
    )

    /// Dracula - popular dark theme with purple/pink accents
    static let dracula = ParchmentTheme(
        name: "Dracula",
        backgroundColor: NSColor(calibratedRed: 0.16, green: 0.16, blue: 0.21, alpha: 1.0),        // #282a36
        textColor: NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.95, alpha: 1.0),              // #f8f8f2
        headingColor: NSColor(calibratedRed: 0.74, green: 0.58, blue: 0.98, alpha: 1.0),           // #bd93f9 Purple
        linkColor: NSColor(calibratedRed: 0.55, green: 0.95, blue: 0.90, alpha: 1.0),              // #8be9fd Cyan
        codeBackgroundColor: NSColor(calibratedRed: 0.13, green: 0.14, blue: 0.18, alpha: 1.0),    // Darker bg
        codeTextColor: NSColor(calibratedRed: 0.31, green: 0.98, blue: 0.48, alpha: 1.0),          // #50fa7b Green
        blockquoteColor: NSColor(calibratedRed: 0.38, green: 0.45, blue: 0.53, alpha: 1.0),        // Comment gray
        selectionColor: NSColor(calibratedRed: 0.27, green: 0.28, blue: 0.35, alpha: 0.7),         // Selection
        cursorColor: NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.95, alpha: 1.0),            // Foreground
        lineNumberColor: NSColor(calibratedRed: 0.38, green: 0.45, blue: 0.53, alpha: 1.0),        // Comment
        syntaxColors: .dracula,
        bodyFontName: "-apple-system",
        headingFontName: "-apple-system",
        codeFontName: "SF Mono",
        baseFontSize: 16,
        lineHeightMultiple: 1.4,
        cornerRadius: 0,
        contentInsets: NSEdgeInsets(top: 40, left: 60, bottom: 40, right: 60),
        useShadows: false,
        animationDuration: 0.25
    )

    /// Nord - arctic, bluish dark theme
    static let nord = ParchmentTheme(
        name: "Nord",
        backgroundColor: NSColor(calibratedRed: 0.18, green: 0.20, blue: 0.25, alpha: 1.0),        // #2e3440 Polar Night
        textColor: NSColor(calibratedRed: 0.85, green: 0.87, blue: 0.91, alpha: 1.0),              // #d8dee9 Snow Storm
        headingColor: NSColor(calibratedRed: 0.92, green: 0.93, blue: 0.95, alpha: 1.0),           // #eceff4 Snow Storm 3
        linkColor: NSColor(calibratedRed: 0.53, green: 0.75, blue: 0.82, alpha: 1.0),              // #88c0d0 Frost
        codeBackgroundColor: NSColor(calibratedRed: 0.23, green: 0.26, blue: 0.32, alpha: 1.0),    // #3b4252 Polar Night 2
        codeTextColor: NSColor(calibratedRed: 0.76, green: 0.80, blue: 0.85, alpha: 1.0),          // #c2c9d4
        blockquoteColor: NSColor(calibratedRed: 0.62, green: 0.67, blue: 0.74, alpha: 1.0),        // Muted text
        selectionColor: NSColor(calibratedRed: 0.29, green: 0.34, blue: 0.42, alpha: 0.6),         // Selection
        cursorColor: NSColor(calibratedRed: 0.53, green: 0.75, blue: 0.82, alpha: 1.0),            // Frost
        lineNumberColor: NSColor(calibratedRed: 0.38, green: 0.43, blue: 0.50, alpha: 1.0),        // Polar Night 4
        syntaxColors: .nord,
        bodyFontName: "-apple-system",
        headingFontName: "-apple-system",
        codeFontName: "SF Mono",
        baseFontSize: 16,
        lineHeightMultiple: 1.4,
        cornerRadius: 0,
        contentInsets: NSEdgeInsets(top: 40, left: 60, bottom: 40, right: 60),
        useShadows: false,
        animationDuration: 0.25
    )

    /// Solarized Dark - classic dark theme with muted colors
    static let solarizedDark = ParchmentTheme(
        name: "Solarized Dark",
        backgroundColor: NSColor(calibratedRed: 0.00, green: 0.17, blue: 0.21, alpha: 1.0),        // #002b36 Base03
        textColor: NSColor(calibratedRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0),              // #839496 Base0
        headingColor: NSColor(calibratedRed: 0.58, green: 0.63, blue: 0.63, alpha: 1.0),           // #93a1a1 Base1
        linkColor: NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),              // #268bd2 Blue
        codeBackgroundColor: NSColor(calibratedRed: 0.03, green: 0.21, blue: 0.26, alpha: 1.0),    // #073642 Base02
        codeTextColor: NSColor(calibratedRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0),          // Base0
        blockquoteColor: NSColor(calibratedRed: 0.35, green: 0.43, blue: 0.46, alpha: 1.0),        // Base01
        selectionColor: NSColor(calibratedRed: 0.03, green: 0.21, blue: 0.26, alpha: 0.6),         // Selection
        cursorColor: NSColor(calibratedRed: 0.83, green: 0.37, blue: 0.00, alpha: 1.0),            // Orange
        lineNumberColor: NSColor(calibratedRed: 0.35, green: 0.43, blue: 0.46, alpha: 1.0),        // Base01
        syntaxColors: .solarizedDark,
        bodyFontName: "-apple-system",
        headingFontName: "-apple-system",
        codeFontName: "SF Mono",
        baseFontSize: 16,
        lineHeightMultiple: 1.4,
        cornerRadius: 0,
        contentInsets: NSEdgeInsets(top: 40, left: 60, bottom: 40, right: 60),
        useShadows: false,
        animationDuration: 0.25
    )

    /// Solarized Light - classic light theme with muted colors
    static let solarizedLight = ParchmentTheme(
        name: "Solarized Light",
        backgroundColor: NSColor(calibratedRed: 0.99, green: 0.96, blue: 0.89, alpha: 1.0),        // #fdf6e3 Base3
        textColor: NSColor(calibratedRed: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),              // #657b83 Base00
        headingColor: NSColor(calibratedRed: 0.35, green: 0.43, blue: 0.46, alpha: 1.0),           // #586e75 Base01
        linkColor: NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),              // #268bd2 Blue
        codeBackgroundColor: NSColor(calibratedRed: 0.93, green: 0.90, blue: 0.83, alpha: 1.0),    // #eee8d5 Base2
        codeTextColor: NSColor(calibratedRed: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),          // Base00
        blockquoteColor: NSColor(calibratedRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0),        // Base0
        selectionColor: NSColor(calibratedRed: 0.93, green: 0.90, blue: 0.83, alpha: 0.6),         // Selection
        cursorColor: NSColor(calibratedRed: 0.83, green: 0.37, blue: 0.00, alpha: 1.0),            // Orange
        lineNumberColor: NSColor(calibratedRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0),        // Base0
        syntaxColors: .solarizedLight,
        bodyFontName: "-apple-system",
        headingFontName: "-apple-system",
        codeFontName: "SF Mono",
        baseFontSize: 16,
        lineHeightMultiple: 1.4,
        cornerRadius: 0,
        contentInsets: NSEdgeInsets(top: 40, left: 60, bottom: 40, right: 60),
        useShadows: false,
        animationDuration: 0.25
    )

    /// All available themes
    static let all: [ParchmentTheme] = [
        .minimal,
        .elegant,
        .midnight,
        .sepia,
        .highContrast,
        .dracula,
        .nord,
        .solarizedDark,
        .solarizedLight
    ]
    
    /// Get theme by name
    static func theme(named name: String) -> ParchmentTheme? {
        return all.first { $0.name == name }
    }
    
    /// Get theme by index (for keyboard shortcuts)
    static func theme(at index: Int) -> ParchmentTheme? {
        guard index >= 0 && index < all.count else { return nil }
        return all[index]
    }
    
    /// Current theme (persisted in UserDefaults)
    static var current: ParchmentTheme {
        get {
            let themeName = UserDefaults.standard.string(forKey: "selectedTheme") ?? "Minimal"
            return theme(named: themeName) ?? .minimal
        }
        set {
            UserDefaults.standard.set(newValue.name, forKey: "selectedTheme")
            NotificationCenter.default.post(name: .themeDidChange, object: nil)
        }
    }

    // MARK: - Auto Dark/Light Mode

    /// Whether to follow system appearance (default: true)
    static var followSystemAppearance: Bool {
        get {
            // Default to true if not set
            if UserDefaults.standard.object(forKey: "followSystemAppearance") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "followSystemAppearance")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "followSystemAppearance")
        }
    }

    /// Theme to use for light system appearance
    static let lightTheme: ParchmentTheme = .minimal

    /// Theme to use for dark system appearance
    static let darkTheme: ParchmentTheme = .midnight

    /// Returns the appropriate theme for the current system appearance
    static func themeForSystemAppearance() -> ParchmentTheme {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark ? darkTheme : lightTheme
    }

    /// Apply theme with smooth cross-fade animation
    static func applyThemeAnimated(_ theme: ParchmentTheme, duration: TimeInterval = 0.3) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.allowsImplicitAnimation = true
            current = theme
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let themeDidChange = Notification.Name("ParchmentThemeDidChange")
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