import Foundation
import Cocoa

/// Manages theme customization and appearance
class ThemeManager {
    
    static let shared = ThemeManager()
    
    // Current theme
    private(set) var currentTheme: Theme = .default
    
    // Available themes
    private var themes: [String: Theme] = [:]
    
    // Theme change notification
    static let themeDidChangeNotification = Notification.Name("ThemeDidChange")
    
    init() {
        loadBuiltInThemes()
        loadCustomThemes()
        
        // Load saved theme preference
        if let savedThemeName = UserDefaults.standard.string(forKey: "SelectedTheme"),
           let savedTheme = themes[savedThemeName] {
            currentTheme = savedTheme
        }
    }
    
    private func loadBuiltInThemes() {
        // Default Light Theme
        themes["Default"] = Theme(
            name: "Default",
            isDark: false,
            colors: ColorScheme(
                background: NSColor.textBackgroundColor,
                text: NSColor.labelColor,
                headingText: NSColor.labelColor,
                linkText: NSColor.linkColor,
                codeBackground: NSColor(white: 0.95, alpha: 1.0),
                codeText: NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
                blockquoteBackground: NSColor(white: 0.92, alpha: 1.0),
                blockquoteBorder: NSColor.systemGray,
                selection: NSColor.selectedTextBackgroundColor,
                cursor: NSColor.labelColor,
                lineNumbers: NSColor.tertiaryLabelColor
            ),
            fonts: FontScheme(
                body: NSFont.systemFont(ofSize: 14),
                heading1: NSFont.boldSystemFont(ofSize: 28),
                heading2: NSFont.boldSystemFont(ofSize: 24),
                heading3: NSFont.boldSystemFont(ofSize: 20),
                heading4: NSFont.boldSystemFont(ofSize: 18),
                heading5: NSFont.boldSystemFont(ofSize: 16),
                heading6: NSFont.boldSystemFont(ofSize: 14),
                code: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                quote: NSFont.systemFont(ofSize: 14).withItalic()
            ),
            spacing: SpacingScheme(
                lineSpacing: 1.5,
                paragraphSpacing: 12,
                headingSpacing: 20,
                codeBlockPadding: 12,
                blockquotePadding: 16
            )
        )
        
        // Dark Theme
        themes["Dark"] = Theme(
            name: "Dark",
            isDark: true,
            colors: ColorScheme(
                background: NSColor(hex: "#1e1e1e"),
                text: NSColor(hex: "#d4d4d4"),
                headingText: NSColor(hex: "#e0e0e0"),
                linkText: NSColor(hex: "#69b7ff"),
                codeBackground: NSColor(hex: "#2d2d30"),
                codeText: NSColor(hex: "#ce9178"),
                blockquoteBackground: NSColor(hex: "#252526"),
                blockquoteBorder: NSColor(hex: "#464647"),
                selection: NSColor(hex: "#264f78"),
                cursor: NSColor(hex: "#aeafad"),
                lineNumbers: NSColor(hex: "#858585")
            ),
            fonts: FontScheme(
                body: NSFont.systemFont(ofSize: 14),
                heading1: NSFont.boldSystemFont(ofSize: 28),
                heading2: NSFont.boldSystemFont(ofSize: 24),
                heading3: NSFont.boldSystemFont(ofSize: 20),
                heading4: NSFont.boldSystemFont(ofSize: 18),
                heading5: NSFont.boldSystemFont(ofSize: 16),
                heading6: NSFont.boldSystemFont(ofSize: 14),
                code: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                quote: NSFont.systemFont(ofSize: 14).withItalic()
            ),
            spacing: SpacingScheme(
                lineSpacing: 1.5,
                paragraphSpacing: 12,
                headingSpacing: 20,
                codeBlockPadding: 12,
                blockquotePadding: 16
            )
        )
        
        // Solarized Light
        themes["Solarized Light"] = Theme(
            name: "Solarized Light",
            isDark: false,
            colors: ColorScheme(
                background: NSColor(hex: "#fdf6e3"),
                text: NSColor(hex: "#657b83"),
                headingText: NSColor(hex: "#586e75"),
                linkText: NSColor(hex: "#268bd2"),
                codeBackground: NSColor(hex: "#eee8d5"),
                codeText: NSColor(hex: "#2aa198"),
                blockquoteBackground: NSColor(hex: "#eee8d5"),
                blockquoteBorder: NSColor(hex: "#93a1a1"),
                selection: NSColor(hex: "#d33682").withAlphaComponent(0.2),
                cursor: NSColor(hex: "#586e75"),
                lineNumbers: NSColor(hex: "#93a1a1")
            ),
            fonts: FontScheme.default,
            spacing: SpacingScheme.default
        )
        
        // Solarized Dark
        themes["Solarized Dark"] = Theme(
            name: "Solarized Dark",
            isDark: true,
            colors: ColorScheme(
                background: NSColor(hex: "#002b36"),
                text: NSColor(hex: "#839496"),
                headingText: NSColor(hex: "#93a1a1"),
                linkText: NSColor(hex: "#268bd2"),
                codeBackground: NSColor(hex: "#073642"),
                codeText: NSColor(hex: "#2aa198"),
                blockquoteBackground: NSColor(hex: "#073642"),
                blockquoteBorder: NSColor(hex: "#586e75"),
                selection: NSColor(hex: "#d33682").withAlphaComponent(0.2),
                cursor: NSColor(hex: "#839496"),
                lineNumbers: NSColor(hex: "#586e75")
            ),
            fonts: FontScheme.default,
            spacing: SpacingScheme.default
        )
        
        // GitHub Theme
        themes["GitHub"] = Theme(
            name: "GitHub",
            isDark: false,
            colors: ColorScheme(
                background: NSColor.white,
                text: NSColor(hex: "#24292e"),
                headingText: NSColor(hex: "#24292e"),
                linkText: NSColor(hex: "#0366d6"),
                codeBackground: NSColor(hex: "#f6f8fa"),
                codeText: NSColor(hex: "#e36209"),
                blockquoteBackground: NSColor(hex: "#f6f8fa"),
                blockquoteBorder: NSColor(hex: "#dfe2e5"),
                selection: NSColor(hex: "#0366d6").withAlphaComponent(0.2),
                cursor: NSColor(hex: "#24292e"),
                lineNumbers: NSColor(hex: "#959da5")
            ),
            fonts: FontScheme(
                body: NSFont(name: "SF Pro Text", size: 16) ?? NSFont.systemFont(ofSize: 16),
                heading1: NSFont(name: "SF Pro Display", size: 32) ?? NSFont.boldSystemFont(ofSize: 32),
                heading2: NSFont(name: "SF Pro Display", size: 24) ?? NSFont.boldSystemFont(ofSize: 24),
                heading3: NSFont(name: "SF Pro Display", size: 20) ?? NSFont.boldSystemFont(ofSize: 20),
                heading4: NSFont(name: "SF Pro Display", size: 16) ?? NSFont.boldSystemFont(ofSize: 16),
                heading5: NSFont(name: "SF Pro Display", size: 14) ?? NSFont.boldSystemFont(ofSize: 14),
                heading6: NSFont(name: "SF Pro Display", size: 13) ?? NSFont.boldSystemFont(ofSize: 13),
                code: NSFont(name: "SF Mono", size: 13) ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
                quote: NSFont(name: "SF Pro Text", size: 16)?.withItalic() ?? NSFont.systemFont(ofSize: 16).withItalic()
            ),
            spacing: SpacingScheme(
                lineSpacing: 1.6,
                paragraphSpacing: 16,
                headingSpacing: 24,
                codeBlockPadding: 16,
                blockquotePadding: 16
            )
        )
        
        // Dracula Theme
        themes["Dracula"] = Theme(
            name: "Dracula",
            isDark: true,
            colors: ColorScheme(
                background: NSColor(hex: "#282a36"),
                text: NSColor(hex: "#f8f8f2"),
                headingText: NSColor(hex: "#bd93f9"),
                linkText: NSColor(hex: "#8be9fd"),
                codeBackground: NSColor(hex: "#44475a"),
                codeText: NSColor(hex: "#50fa7b"),
                blockquoteBackground: NSColor(hex: "#44475a"),
                blockquoteBorder: NSColor(hex: "#6272a4"),
                selection: NSColor(hex: "#44475a"),
                cursor: NSColor(hex: "#f8f8f2"),
                lineNumbers: NSColor(hex: "#6272a4")
            ),
            fonts: FontScheme.default,
            spacing: SpacingScheme.default
        )
    }
    
    private func loadCustomThemes() {
        // Load custom themes from Application Support directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Parchment")
            .appendingPathComponent("Themes")
        
        guard let themesDir = appSupport else { return }
        
        do {
            let themeFiles = try FileManager.default.contentsOfDirectory(
                at: themesDir,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            
            for themeFile in themeFiles where themeFile.pathExtension == "json" {
                if let theme = loadThemeFromFile(at: themeFile) {
                    themes[theme.name] = theme
                }
            }
        } catch {
            // No custom themes directory yet
        }
    }
    
    private func loadThemeFromFile(at url: URL) -> Theme? {
        // TODO: Implement custom theme loading from JSON
        // For now, return nil as Theme is no longer Codable
        return nil
    }
    
    // MARK: - Public Methods
    
    func setTheme(_ theme: Theme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.name, forKey: "SelectedTheme")
        
        // Apply system appearance if needed
        if theme.isDark {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else {
            NSApp.appearance = NSAppearance(named: .aqua)
        }
        
        // Notify observers
        NotificationCenter.default.post(name: ThemeManager.themeDidChangeNotification, object: theme)
    }
    
    func setTheme(named name: String) {
        if let theme = themes[name] {
            setTheme(theme)
        }
    }
    
    func availableThemes() -> [Theme] {
        return Array(themes.values).sorted { $0.name < $1.name }
    }
    
    func saveCustomTheme(_ theme: Theme) {
        // TODO: Implement custom theme saving to JSON
        // For now, just add to in-memory themes
        themes[theme.name] = theme
    }
}

// MARK: - Theme Model

struct Theme {
    let name: String
    let isDark: Bool
    let colors: ColorScheme
    let fonts: FontScheme
    let spacing: SpacingScheme
    
    static let `default` = Theme(
        name: "Default",
        isDark: false,
        colors: ColorScheme.default,
        fonts: FontScheme.default,
        spacing: SpacingScheme.default
    )
}

struct ColorScheme {
    let background: NSColor
    let text: NSColor
    let headingText: NSColor
    let linkText: NSColor
    let codeBackground: NSColor
    let codeText: NSColor
    let blockquoteBackground: NSColor
    let blockquoteBorder: NSColor
    let selection: NSColor
    let cursor: NSColor
    let lineNumbers: NSColor
    
    static let `default` = ColorScheme(
        background: NSColor.textBackgroundColor,
        text: NSColor.labelColor,
        headingText: NSColor.labelColor,
        linkText: NSColor.linkColor,
        codeBackground: NSColor(white: 0.95, alpha: 1.0),
        codeText: NSColor.labelColor,
        blockquoteBackground: NSColor(white: 0.92, alpha: 1.0),
        blockquoteBorder: NSColor.systemGray,
        selection: NSColor.selectedTextBackgroundColor,
        cursor: NSColor.labelColor,
        lineNumbers: NSColor.tertiaryLabelColor
    )
}

struct FontScheme {
    let body: NSFont
    let heading1: NSFont
    let heading2: NSFont
    let heading3: NSFont
    let heading4: NSFont
    let heading5: NSFont
    let heading6: NSFont
    let code: NSFont
    let quote: NSFont
    
    static let `default` = FontScheme(
        body: NSFont.systemFont(ofSize: 14),
        heading1: NSFont.boldSystemFont(ofSize: 28),
        heading2: NSFont.boldSystemFont(ofSize: 24),
        heading3: NSFont.boldSystemFont(ofSize: 20),
        heading4: NSFont.boldSystemFont(ofSize: 18),
        heading5: NSFont.boldSystemFont(ofSize: 16),
        heading6: NSFont.boldSystemFont(ofSize: 14),
        code: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
        quote: NSFont.systemFont(ofSize: 14).withItalic()
    )
}

struct SpacingScheme {
    let lineSpacing: CGFloat
    let paragraphSpacing: CGFloat
    let headingSpacing: CGFloat
    let codeBlockPadding: CGFloat
    let blockquotePadding: CGFloat
    
    static let `default` = SpacingScheme(
        lineSpacing: 1.5,
        paragraphSpacing: 12,
        headingSpacing: 20,
        codeBlockPadding: 12,
        blockquotePadding: 16
    )
}

// MARK: - Extensions

extension NSFont {
    func withItalic() -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Codable Support

// Custom wrapper types for Codable support
struct CodableColor: Codable {
    let hex: String
    
    init(color: NSColor) {
        self.hex = String(format: "#%02X%02X%02X",
                         Int(color.redComponent * 255),
                         Int(color.greenComponent * 255),
                         Int(color.blueComponent * 255))
    }
    
    var nsColor: NSColor {
        return NSColor(hex: hex)
    }
}

struct CodableFont: Codable {
    let name: String
    let size: CGFloat
    
    init(font: NSFont) {
        self.name = font.fontName
        self.size = font.pointSize
    }
    
    var nsFont: NSFont {
        return NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size)
    }
}