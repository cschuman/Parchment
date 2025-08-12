import Cocoa

class StyleManager {
    static let shared = StyleManager()
    
    private init() {}
    
    func defaultTextAttributes(fontSize: CGFloat = 14.0) -> [NSAttributedString.Key: Any] {
        return [
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: defaultParagraphStyle()
        ]
    }
    
    func headingAttributes(level: Int, fontSize: CGFloat = 14.0) -> [NSAttributedString.Key: Any] {
        let baseFontSize = fontSize
        let headingSize = baseFontSize * (2.0 - (Double(level - 1) * 0.2))
        let weight: NSFont.Weight = level <= 2 ? .bold : .semibold
        
        return [
            .font: NSFont.systemFont(ofSize: headingSize, weight: weight),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: headingParagraphStyle(level: level)
        ]
    }
    
    func codeAttributes(fontSize: CGFloat = 14.0) -> [NSAttributedString.Key: Any] {
        return [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize * 0.9, weight: .regular),
            .foregroundColor: NSColor.systemPink,
            .backgroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.1)
        ]
    }
    
    func codeBlockAttributes(fontSize: CGFloat = 14.0) -> [NSAttributedString.Key: Any] {
        return [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize * 0.9, weight: .regular),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: NSColor.secondaryLabelColor.withAlphaComponent(0.05),
            .paragraphStyle: codeBlockParagraphStyle()
        ]
    }
    
    func linkAttributes(fontSize: CGFloat = 14.0) -> [NSAttributedString.Key: Any] {
        return [
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }
    
    func blockQuoteAttributes(fontSize: CGFloat = 14.0) -> [NSAttributedString.Key: Any] {
        return [
            .font: NSFont(descriptor: NSFont.systemFont(ofSize: fontSize).fontDescriptor.withSymbolicTraits(.italic), size: fontSize) ?? NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: blockQuoteParagraphStyle()
        ]
    }
    
    private func defaultParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4.0
        style.paragraphSpacing = 12.0
        style.hyphenationFactor = 0.9
        return style
    }
    
    private func headingParagraphStyle(level: Int) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2.0
        style.paragraphSpacingBefore = level == 1 ? 24.0 : 16.0
        style.paragraphSpacing = level == 1 ? 16.0 : 12.0
        return style
    }
    
    private func codeBlockParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2.0
        style.paragraphSpacing = 16.0
        style.firstLineHeadIndent = 16.0
        style.headIndent = 16.0
        style.tailIndent = -16.0
        return style
    }
    
    private func blockQuoteParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4.0
        style.paragraphSpacing = 12.0
        style.firstLineHeadIndent = 20.0
        style.headIndent = 20.0
        style.tailIndent = -20.0
        return style
    }
    
    func applyTheme(_ theme: Theme) {
        switch theme {
        case .system:
            break
        case .light:
            NSAppearance.current = NSAppearance(named: .aqua)
        case .dark:
            NSAppearance.current = NSAppearance(named: .darkAqua)
        }
    }
    
    enum Theme: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
    }
}