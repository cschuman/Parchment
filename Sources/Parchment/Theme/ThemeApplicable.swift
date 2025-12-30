import Cocoa

/// Protocol for views and controllers that can apply a theme
protocol ThemeApplicable: AnyObject {
    func applyTheme(_ theme: ParchmentTheme, animated: Bool)
}

extension ThemeApplicable {
    /// Default implementation with animation enabled
    func applyTheme(_ theme: ParchmentTheme) {
        applyTheme(theme, animated: true)
    }
}
