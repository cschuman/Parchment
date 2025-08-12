import Foundation
import Cocoa
import QuartzCore

/// A sophisticated page-style renderer that creates a beautiful reading experience
class PageStyleRenderer: NSObject {
    
    // MARK: - Design System Constants
    
    struct DesignSystem {
        // Page dimensions
        static let pageMaxWidth: CGFloat = 680
        static let pageMarginRatio: CGFloat = 0.618 // Golden ratio
        static let sidebarWidth: CGFloat = 40
        static let sidebarOpacity: CGFloat = 0.03
        
        // Typography
        static let baseFontSize: CGFloat = 16
        static let lineHeight: CGFloat = 1.7
        static let paragraphSpacing: CGFloat = 1.2
        static let letterSpacing: CGFloat = 0.02
        
        // Heading scales (perfect fourth musical ratio)
        static let h1Scale: CGFloat = 2.441
        static let h2Scale: CGFloat = 1.953
        static let h3Scale: CGFloat = 1.563
        static let h4Scale: CGFloat = 1.25
        static let h5Scale: CGFloat = 1.0
        static let h6Scale: CGFloat = 0.8
        
        // Colors with subtle gradients
        static let textColor = NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.13, alpha: 1.0)
        static let headingColor = NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.08, alpha: 1.0)
        static let linkColor = NSColor(calibratedRed: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
        static let codeBackground = NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)
        static let blockquoteAccent = NSColor(calibratedRed: 0.67, green: 0.67, blue: 0.70, alpha: 1.0)
        
        // Animations
        static let microAnimationDuration: TimeInterval = 0.15
        static let smoothAnimationDuration: TimeInterval = 0.35
        static let springDamping: CGFloat = 0.825
        
        // Spacing rhythm (based on musical intervals)
        static let rhythmUnit: CGFloat = 8
        static func rhythm(_ multiplier: CGFloat) -> CGFloat {
            return rhythmUnit * multiplier
        }
    }
    
    // MARK: - Properties
    
    private weak var textView: NSTextView?
    private var pageContainerView: NSView?
    private var leftSidebarView: NSView?
    private var rightSidebarView: NSView?
    private var contentView: NSView?
    private var currentTheme: Theme = .light
    
    // MARK: - Initialization
    
    func setupPageLayout(in scrollView: NSScrollView, textView: NSTextView) {
        self.textView = textView
        
        // Create the page container
        createPageContainer(in: scrollView)
        
        // Style the text view
        styleTextView(textView)
        
        // Add subtle animations
        enableSmoothTransitions()
    }
    
    private func createPageContainer(in scrollView: NSScrollView) {
        guard let documentView = scrollView.documentView else { return }
        
        // Create main page container
        pageContainerView = NSView()
        pageContainerView?.wantsLayer = true
        pageContainerView?.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        
        // Create elegant sidebars with gradient
        leftSidebarView = createSidebar(isLeft: true)
        rightSidebarView = createSidebar(isLeft: false)
        
        // Create content area with shadow
        contentView = NSView()
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.white.cgColor
        contentView?.layer?.cornerRadius = 2
        contentView?.layer?.shadowColor = NSColor.black.cgColor
        contentView?.layer?.shadowOpacity = 0.05
        contentView?.layer?.shadowOffset = CGSize(width: 0, height: 2)
        contentView?.layer?.shadowRadius = 20
        
        // Apply sophisticated shadow with multiple layers for depth
        applySophisticatedShadow(to: contentView)
    }
    
    private func createSidebar(isLeft: Bool) -> NSView {
        let sidebar = NSView()
        sidebar.wantsLayer = true
        
        // Create gradient layer for sidebar
        let gradient = CAGradientLayer()
        gradient.colors = [
            NSColor.black.withAlphaComponent(0.02).cgColor,
            NSColor.black.withAlphaComponent(0.0).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = isLeft ? CGPoint(x: 1, y: 0.5) : CGPoint(x: 0, y: 0.5)
        gradient.endPoint = isLeft ? CGPoint(x: 0, y: 0.5) : CGPoint(x: 1, y: 0.5)
        
        sidebar.layer?.addSublayer(gradient)
        
        return sidebar
    }
    
    private func applySophisticatedShadow(to view: NSView?) {
        guard let layer = view?.layer else { return }
        
        // Remove existing shadows
        layer.shadowPath = nil
        
        // Create compound shadow for more realistic depth
        let shadowPath = CGPath(rect: view?.bounds ?? .zero, transform: nil)
        layer.shadowPath = shadowPath
        
        // Primary shadow (soft and distant)
        layer.shadowColor = NSColor.black.cgColor
        layer.shadowOpacity = 0.03
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.shadowRadius = 25
        
        // Add secondary shadow layer for close shadow
        let closeLayer = CALayer()
        closeLayer.frame = layer.bounds
        closeLayer.shadowColor = NSColor.black.cgColor
        closeLayer.shadowOpacity = 0.06
        closeLayer.shadowOffset = CGSize(width: 0, height: 1)
        closeLayer.shadowRadius = 3
        closeLayer.shadowPath = shadowPath
        layer.addSublayer(closeLayer)
    }
    
    private func styleTextView(_ textView: NSTextView) {
        // Configure text container for optimal reading
        textView.textContainer?.containerSize = NSSize(
            width: DesignSystem.pageMaxWidth,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.lineFragmentPadding = 0
        
        // Set sophisticated insets
        let horizontalInset = DesignSystem.rhythm(8)
        let verticalInset = DesignSystem.rhythm(10)
        textView.textContainerInset = NSSize(width: horizontalInset, height: verticalInset)
        
        // Typography settings
        textView.usesAdaptiveColorMappingForDarkAppearance = true
        textView.allowsUndo = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // Enable typography features
        textView.usesInspectorBar = false
        textView.importsGraphics = true
    }
    
    private func enableSmoothTransitions() {
        // Enable Core Animation for smooth transitions
        textView?.wantsLayer = true
        textView?.layerContentsRedrawPolicy = .onSetNeedsDisplay
        
        // Add subtle spring animations to scrolling
        if let scrollView = textView?.enclosingScrollView {
            scrollView.contentView.wantsLayer = true
            scrollView.contentView.layerContentsRedrawPolicy = .duringViewResize
        }
    }
    
    // MARK: - Enhanced Typography
    
    func createAttributedString(from markdown: String, zoomLevel: CGFloat = 1.0) -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        // This is a simplified version - integrate with existing markdown parser
        let baseFont = createOptimizedFont(size: DesignSystem.baseFontSize * zoomLevel)
        let paragraphStyle = createSophisticatedParagraphStyle()
        
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: DesignSystem.textColor,
            .paragraphStyle: paragraphStyle,
            .kern: DesignSystem.letterSpacing,
            .ligature: 2, // Enable all ligatures
            .baselineOffset: 0.5 // Slight baseline adjustment for better optical alignment
        ]
        
        result.append(NSAttributedString(string: markdown, attributes: defaultAttributes))
        
        return result
    }
    
    private func createOptimizedFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        // Try to use high-quality system fonts with optical sizes
        let descriptor = NSFontDescriptor.preferredFontDescriptor(forTextStyle: .body)
            .withSymbolicTraits(.monoSpace)
        
        // Use SF Pro Display for headings, SF Pro Text for body
        let fontName = size > 20 ? "SF Pro Display" : "SF Pro Text"
        
        if let font = NSFont(name: fontName, size: size) {
            return NSFont(descriptor: font.fontDescriptor.withSymbolicTraits(.bold), size: size) ?? font
        }
        
        // Fallback to system font
        return NSFont.systemFont(ofSize: size, weight: weight)
    }
    
    private func createSophisticatedParagraphStyle() -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        
        // Optimal line height for readability
        style.lineHeightMultiple = DesignSystem.lineHeight
        style.paragraphSpacing = DesignSystem.baseFontSize * DesignSystem.paragraphSpacing
        style.paragraphSpacingBefore = DesignSystem.rhythm(1)
        
        // Subtle first line indent for paragraphs
        style.firstLineHeadIndent = 0
        style.headIndent = 0
        style.tailIndent = 0
        
        // Hyphenation for better text flow
        style.hyphenationFactor = 0.9
        style.tighteningFactorForTruncation = 0.05
        
        // Alignment and breaking
        style.alignment = .left
        style.lineBreakMode = .byWordWrapping
        style.lineBreakStrategy = [.pushOut]
        
        return style
    }
    
    // MARK: - Animation Helpers
    
    func animateIn(view: NSView, delay: TimeInterval = 0) {
        view.alphaValue = 0
        view.layer?.transform = CATransform3DMakeTranslation(0, 10, 0)
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = DesignSystem.smoothAnimationDuration
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
            context.allowsImplicitAnimation = true
            
            view.animator().alphaValue = 1.0
            view.layer?.transform = CATransform3DIdentity
        })
    }
    
    func animateFocusRing(around view: NSView) {
        let focusRing = CALayer()
        focusRing.frame = view.bounds.insetBy(dx: -2, dy: -2)
        focusRing.cornerRadius = 4
        focusRing.borderColor = DesignSystem.linkColor.cgColor
        focusRing.borderWidth = 2
        focusRing.opacity = 0
        
        view.layer?.addSublayer(focusRing)
        
        // Animate the focus ring
        let fadeIn = CABasicAnimation(keyPath: "opacity")
        fadeIn.fromValue = 0
        fadeIn.toValue = 0.6
        fadeIn.duration = DesignSystem.microAnimationDuration
        
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.95
        scale.toValue = 1.0
        scale.duration = DesignSystem.microAnimationDuration
        
        let group = CAAnimationGroup()
        group.animations = [fadeIn, scale]
        group.duration = DesignSystem.microAnimationDuration
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.isRemovedOnCompletion = false
        group.fillMode = .forwards
        
        focusRing.add(group, forKey: "focusAnimation")
        
        // Remove after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let fadeOut = CABasicAnimation(keyPath: "opacity")
            fadeOut.fromValue = 0.6
            fadeOut.toValue = 0
            fadeOut.duration = DesignSystem.smoothAnimationDuration
            fadeOut.isRemovedOnCompletion = false
            fadeOut.fillMode = .forwards
            
            focusRing.add(fadeOut, forKey: "fadeOut")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.smoothAnimationDuration) {
                focusRing.removeFromSuperlayer()
            }
        }
    }
    
    // MARK: - Theme Support
    
    enum Theme {
        case light
        case dark
        case sepia
        case highContrast
        
        var backgroundColor: NSColor {
            switch self {
            case .light:
                return NSColor(calibratedRed: 0.99, green: 0.99, blue: 0.98, alpha: 1.0)
            case .dark:
                return NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.13, alpha: 1.0)
            case .sepia:
                return NSColor(calibratedRed: 0.96, green: 0.94, blue: 0.89, alpha: 1.0)
            case .highContrast:
                return NSColor.white
            }
        }
        
        var textColor: NSColor {
            switch self {
            case .light:
                return DesignSystem.textColor
            case .dark:
                return NSColor(calibratedRed: 0.92, green: 0.92, blue: 0.94, alpha: 1.0)
            case .sepia:
                return NSColor(calibratedRed: 0.25, green: 0.20, blue: 0.15, alpha: 1.0)
            case .highContrast:
                return NSColor.black
            }
        }
    }
    
    func applyTheme(_ theme: Theme, animated: Bool = true) {
        currentTheme = theme
        
        let applyColors = {
            self.contentView?.layer?.backgroundColor = theme.backgroundColor.cgColor
            self.textView?.backgroundColor = theme.backgroundColor
            self.textView?.textColor = theme.textColor
        }
        
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = DesignSystem.smoothAnimationDuration
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                applyColors()
            })
        } else {
            applyColors()
        }
    }
}

// MARK: - Custom Text View for Enhanced Rendering

class EnhancedMarkdownTextView: NSTextView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupEnhancements()
    }
    
    private func setupEnhancements() {
        // Enable subpixel antialiasing for crisp text
        self.usesAdaptiveColorMappingForDarkAppearance = true
        
        // Smooth scrolling
        self.enclosingScrollView?.scrollerStyle = .overlay
        self.enclosingScrollView?.horizontalScrollElasticity = .none
        self.enclosingScrollView?.verticalScrollElasticity = .automatic
    }
    
    override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)
        
        // Add subtle texture or gradient if needed
        if let context = NSGraphicsContext.current?.cgContext {
            // Add very subtle gradient overlay
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    NSColor.white.withAlphaComponent(0.0).cgColor,
                    NSColor.white.withAlphaComponent(0.02).cgColor
                ] as CFArray,
                locations: [0.0, 1.0]
            )
            
            if let gradient = gradient {
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: rect.midX, y: rect.minY),
                    end: CGPoint(x: rect.midX, y: rect.maxY),
                    options: []
                )
            }
        }
    }
}