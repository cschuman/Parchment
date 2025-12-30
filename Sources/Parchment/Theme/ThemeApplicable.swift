import Cocoa

/// Protocol for views and controllers that can apply a theme
protocol ThemeApplicable: AnyObject {
    func applyTheme(_ theme: ParchmentTheme)
}
