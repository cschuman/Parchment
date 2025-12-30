import Cocoa

/// Loads custom CSS themes from the user's Application Support directory
final class CustomThemeLoader {

    // MARK: - Properties

    static let shared = CustomThemeLoader()

    private let themesDirectory: URL
    private var customThemes: [ParchmentTheme] = []

    // MARK: - Initialization

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        themesDirectory = appSupport.appendingPathComponent("Parchment/themes", isDirectory: true)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: themesDirectory, withIntermediateDirectories: true)

        // Create template file if themes directory is empty
        createTemplateIfNeeded()
    }

    // MARK: - Public Interface

    /// Load all custom themes from the themes directory
    func loadCustomThemes() -> [ParchmentTheme] {
        customThemes.removeAll()

        guard let files = try? FileManager.default.contentsOfDirectory(at: themesDirectory, includingPropertiesForKeys: nil) else {
            return []
        }

        for file in files where file.pathExtension == "css" {
            if let theme = parseTheme(from: file) {
                customThemes.append(theme)
            }
        }

        return customThemes
    }

    /// Get the themes directory path
    var themesDirectoryPath: String {
        themesDirectory.path
    }

    // MARK: - Private Methods

    private func createTemplateIfNeeded() {
        let templatePath = themesDirectory.appendingPathComponent("_template.css")

        guard !FileManager.default.fileExists(atPath: templatePath.path) else { return }

        let template = """
        /* Parchment Custom Theme Template
         *
         * Save this file with a new name (e.g., MyTheme.css) to create a custom theme.
         * Files starting with underscore are ignored.
         *
         * All colors support: hex (#RRGGBB), rgb(r,g,b), or rgba(r,g,b,a)
         */

        /* Theme name - displayed in theme picker */
        --theme-name: "My Custom Theme";

        /* Main colors */
        --background-color: #ffffff;
        --text-color: #333333;
        --heading-color: #000000;
        --link-color: #0066cc;

        /* Code blocks */
        --code-background: #f5f5f5;
        --code-text: #333333;

        /* Blockquotes */
        --blockquote-color: #666666;

        /* Selection and cursor */
        --selection-color: rgba(0, 102, 204, 0.2);
        --cursor-color: #0066cc;

        /* Line numbers */
        --line-number-color: #999999;

        /* Syntax highlighting (optional) */
        --syntax-keyword: #9b59b6;
        --syntax-string: #e74c3c;
        --syntax-comment: #7f8c8d;
        --syntax-number: #3498db;
        --syntax-type: #1abc9c;
        --syntax-function: #2980b9;
        --syntax-variable: #e67e22;
        --syntax-operator: #95a5a6;

        /* Typography (optional) */
        --body-font: "-apple-system";
        --heading-font: "-apple-system";
        --code-font: "SF Mono";
        --base-font-size: 16;
        --line-height: 1.4;
        """

        try? template.write(to: templatePath, atomically: true, encoding: .utf8)
    }

    private func parseTheme(from url: URL) -> ParchmentTheme? {
        // Skip template files (starting with underscore)
        guard !url.lastPathComponent.hasPrefix("_") else { return nil }

        guard let css = try? String(contentsOf: url, encoding: .utf8) else { return nil }

        // Parse CSS variables
        var variables: [String: String] = [:]

        // Match CSS variable declarations: --name: value;
        let pattern = #"--([a-zA-Z-]+):\s*([^;]+);"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(css.startIndex..., in: css)
        let matches = regex.matches(in: css, range: range)

        for match in matches {
            if let nameRange = Range(match.range(at: 1), in: css),
               let valueRange = Range(match.range(at: 2), in: css) {
                let name = String(css[nameRange])
                let value = String(css[valueRange]).trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: "'", with: "")
                variables[name] = value
            }
        }

        // Get theme name (required)
        guard let themeName = variables["theme-name"], !themeName.isEmpty else { return nil }

        // Parse colors with fallbacks
        let backgroundColor = parseColor(variables["background-color"]) ?? .white
        let textColor = parseColor(variables["text-color"]) ?? .black
        let headingColor = parseColor(variables["heading-color"]) ?? textColor
        let linkColor = parseColor(variables["link-color"]) ?? .systemBlue
        let codeBackground = parseColor(variables["code-background"]) ?? backgroundColor.withAlphaComponent(0.9)
        let codeText = parseColor(variables["code-text"]) ?? textColor
        let blockquoteColor = parseColor(variables["blockquote-color"]) ?? textColor.withAlphaComponent(0.7)
        let selectionColor = parseColor(variables["selection-color"]) ?? linkColor.withAlphaComponent(0.2)
        let cursorColor = parseColor(variables["cursor-color"]) ?? linkColor
        let lineNumberColor = parseColor(variables["line-number-color"]) ?? textColor.withAlphaComponent(0.5)

        // Parse syntax colors
        let syntaxColors = SyntaxColors(
            keyword: parseColor(variables["syntax-keyword"]) ?? .systemPurple,
            string: parseColor(variables["syntax-string"]) ?? .systemRed,
            comment: parseColor(variables["syntax-comment"]) ?? .systemGreen,
            number: parseColor(variables["syntax-number"]) ?? .systemBlue,
            type: parseColor(variables["syntax-type"]) ?? .systemTeal,
            function: parseColor(variables["syntax-function"]) ?? .systemIndigo,
            variable: parseColor(variables["syntax-variable"]) ?? .systemOrange,
            operatorColor: parseColor(variables["syntax-operator"]) ?? .systemGray
        )

        // Parse typography settings
        let bodyFont = variables["body-font"] ?? "-apple-system"
        let headingFont = variables["heading-font"] ?? "-apple-system"
        let codeFont = variables["code-font"] ?? "SF Mono"
        let fontSize = CGFloat(Double(variables["base-font-size"] ?? "16") ?? 16)
        let lineHeight = CGFloat(Double(variables["line-height"] ?? "1.4") ?? 1.4)

        return ParchmentTheme(
            name: themeName,
            backgroundColor: backgroundColor,
            textColor: textColor,
            headingColor: headingColor,
            linkColor: linkColor,
            codeBackgroundColor: codeBackground,
            codeTextColor: codeText,
            blockquoteColor: blockquoteColor,
            selectionColor: selectionColor,
            cursorColor: cursorColor,
            lineNumberColor: lineNumberColor,
            syntaxColors: syntaxColors,
            bodyFontName: bodyFont,
            headingFontName: headingFont,
            codeFontName: codeFont,
            baseFontSize: fontSize,
            lineHeightMultiple: lineHeight,
            cornerRadius: 0,
            contentInsets: NSEdgeInsets(top: 40, left: 60, bottom: 40, right: 60),
            useShadows: false,
            animationDuration: 0.25
        )
    }

    private func parseColor(_ value: String?) -> NSColor? {
        guard let value = value?.trimmingCharacters(in: .whitespaces) else { return nil }

        // Hex color: #RRGGBB or #RGB
        if value.hasPrefix("#") {
            return NSColor(hex: value)
        }

        // rgb(r, g, b) or rgba(r, g, b, a)
        if value.hasPrefix("rgb") {
            let pattern = #"rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) else {
                return nil
            }

            guard let rRange = Range(match.range(at: 1), in: value),
                  let gRange = Range(match.range(at: 2), in: value),
                  let bRange = Range(match.range(at: 3), in: value) else {
                return nil
            }

            let r = CGFloat(Double(value[rRange]) ?? 0) / 255.0
            let g = CGFloat(Double(value[gRange]) ?? 0) / 255.0
            let b = CGFloat(Double(value[bRange]) ?? 0) / 255.0

            var a: CGFloat = 1.0
            if match.range(at: 4).location != NSNotFound,
               let aRange = Range(match.range(at: 4), in: value) {
                a = CGFloat(Double(value[aRange]) ?? 1.0)
            }

            return NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
        }

        return nil
    }
}

// MARK: - NSColor Hex Extension

extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b, a: CGFloat

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else if length == 3 {
            r = CGFloat((rgb & 0xF00) >> 8) / 15.0
            g = CGFloat((rgb & 0x0F0) >> 4) / 15.0
            b = CGFloat(rgb & 0x00F) / 15.0
            a = 1.0
        } else {
            return nil
        }

        self.init(calibratedRed: r, green: g, blue: b, alpha: a)
    }
}
