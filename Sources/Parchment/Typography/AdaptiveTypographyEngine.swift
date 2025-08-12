import Cocoa
import CoreText
import os.log

private let typographyLog = OSLog(subsystem: "com.markdownviewer", category: "Typography")

final class AdaptiveTypographyEngine {
    
    enum ReadingMode: String {
        case normal
        case focus
        case speed
        case night
        case paper
        case bionic
        case dyslexic
    }
    
    struct TypographyMetrics {
        var optimalLineLength: CGFloat = 0
        var lineHeight: CGFloat = 0
        var paragraphSpacing: CGFloat = 0
        var fontSize: CGFloat = 0
        var letterSpacing: CGFloat = 0
        var wordSpacing: CGFloat = 0
        var readingTime: TimeInterval = 0
        var complexity: Double = 0
    }
    
    struct ReadingEnvironment {
        var viewportWidth: CGFloat
        var viewportHeight: CGFloat
        var screenScale: CGFloat
        var ambientBrightness: Double
        var readingDistance: CGFloat
        var userPreferences: UserPreferences
    }
    
    struct UserPreferences {
        var preferredFontSize: CGFloat = 16
        var preferredLineLength: Int = 70
        var preferredContrast: Double = 1.0
        var reducedMotion: Bool = false
    }
    
    private var currentMode: ReadingMode = .normal
    private var currentMetrics = TypographyMetrics()
    private let goldenRatio: CGFloat = 1.618
    private let modularScale: [CGFloat] = [0.618, 0.786, 1.0, 1.272, 1.618, 2.058, 2.618]
    
    func calculateOptimalTypography(
        for content: String,
        environment: ReadingEnvironment,
        mode: ReadingMode
    ) -> NSAttributedString {
        currentMode = mode
        currentMetrics = computeMetrics(for: content, environment: environment)
        
        switch mode {
        case .normal:
            return renderNormalMode(content, metrics: currentMetrics)
        case .focus:
            return renderFocusMode(content, metrics: currentMetrics)
        case .speed:
            return renderSpeedMode(content, metrics: currentMetrics)
        case .night:
            return renderNightMode(content, metrics: currentMetrics)
        case .paper:
            return renderPaperMode(content, metrics: currentMetrics)
        case .bionic:
            return renderBionicMode(content, metrics: currentMetrics)
        case .dyslexic:
            return renderDyslexicMode(content, metrics: currentMetrics)
        }
    }
    
    private func computeMetrics(
        for content: String,
        environment: ReadingEnvironment
    ) -> TypographyMetrics {
        var metrics = TypographyMetrics()
        
        // Calculate optimal line length (45-75 characters)
        let idealCharacters = environment.userPreferences.preferredLineLength
        let averageCharWidth = environment.userPreferences.preferredFontSize * 0.5
        metrics.optimalLineLength = min(
            CGFloat(idealCharacters) * averageCharWidth,
            environment.viewportWidth - 120
        )
        
        // Dynamic font size based on viewport and reading distance
        let viewportFactor = sqrt(environment.viewportWidth * environment.viewportHeight) / 1000
        let distanceFactor = environment.readingDistance / 60
        metrics.fontSize = environment.userPreferences.preferredFontSize * viewportFactor * distanceFactor
        
        // Optical sizing - adjust font weight and spacing based on size
        if metrics.fontSize < 12 {
            metrics.letterSpacing = 0.5
            metrics.wordSpacing = 1.2
        } else if metrics.fontSize < 18 {
            metrics.letterSpacing = 0.3
            metrics.wordSpacing = 1.0
        } else {
            metrics.letterSpacing = -0.2
            metrics.wordSpacing = 0.9
        }
        
        // Calculate line height using modular scale
        let baseLineHeight = metrics.fontSize * goldenRatio
        metrics.lineHeight = round(baseLineHeight / 4) * 4
        
        // Paragraph spacing based on line height
        metrics.paragraphSpacing = metrics.lineHeight * 0.75
        
        // Calculate reading time and complexity
        let words = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        metrics.readingTime = Double(words.count) / 200.0 * 60
        
        let avgWordLength = Double(content.count) / Double(max(words.count, 1))
        let sentenceCount = content.components(separatedBy: CharacterSet(charactersIn: ".!?")).count - 1
        let avgSentenceLength = Double(words.count) / Double(max(sentenceCount, 1))
        
        metrics.complexity = (avgWordLength * 0.3 + avgSentenceLength * 0.7) / 20.0
        
        return metrics
    }
    
    private func renderNormalMode(_ content: String, metrics: TypographyMetrics) -> NSAttributedString {
        let font = createOptimizedFont(size: metrics.fontSize, weight: .regular)
        let paragraphStyle = createParagraphStyle(metrics: metrics)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle,
            .kern: metrics.letterSpacing,
            .expansion: metrics.wordSpacing - 1.0,
            .ligature: 2,
            .baselineOffset: 0
        ]
        
        return NSAttributedString(string: content, attributes: attributes)
    }
    
    private func renderFocusMode(_ content: String, metrics: TypographyMetrics) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let paragraphs = content.components(separatedBy: "\n\n")
        
        let focusedFont = createOptimizedFont(size: metrics.fontSize * 1.1, weight: .regular)
        let dimmedFont = createOptimizedFont(size: metrics.fontSize, weight: .light)
        
        for (index, paragraph) in paragraphs.enumerated() {
            let isFocused = index == 0
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = isFocused ? 1.8 : 1.6
            paragraphStyle.paragraphSpacing = metrics.paragraphSpacing * (isFocused ? 1.5 : 1.0)
            paragraphStyle.alignment = .natural
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: isFocused ? focusedFont : dimmedFont,
                .foregroundColor: isFocused ? NSColor.labelColor : NSColor.secondaryLabelColor,
                .paragraphStyle: paragraphStyle,
                .kern: metrics.letterSpacing,
                .expansion: isFocused ? 0.1 : 0
            ]
            
            result.append(NSAttributedString(string: paragraph + "\n\n", attributes: attributes))
        }
        
        return result
    }
    
    private func renderSpeedMode(_ content: String, metrics: TypographyMetrics) -> NSAttributedString {
        let font = NSFont.systemFont(ofSize: metrics.fontSize * 1.2, weight: .medium)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.3
        paragraphStyle.paragraphSpacing = metrics.paragraphSpacing * 0.5
        paragraphStyle.alignment = .left
        paragraphStyle.hyphenationFactor = 0
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle,
            .kern: -0.5,
            .ligature: 0
        ]
        
        return NSAttributedString(string: content, attributes: attributes)
    }
    
    private func renderNightMode(_ content: String, metrics: TypographyMetrics) -> NSAttributedString {
        let font = createOptimizedFont(size: metrics.fontSize * 1.05, weight: .regular)
        let paragraphStyle = createParagraphStyle(metrics: metrics)
        
        let nightColor = NSColor(calibratedRed: 0.95, green: 0.92, blue: 0.86, alpha: 1.0)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: nightColor,
            .backgroundColor: NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.1, alpha: 1.0),
            .paragraphStyle: paragraphStyle,
            .kern: metrics.letterSpacing * 1.2,
            .expansion: 0.05
        ]
        
        return NSAttributedString(string: content, attributes: attributes)
    }
    
    private func renderPaperMode(_ content: String, metrics: TypographyMetrics) -> NSAttributedString {
        let font = NSFont(name: "Georgia", size: metrics.fontSize) ?? NSFont.systemFont(ofSize: metrics.fontSize)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.6
        paragraphStyle.paragraphSpacing = metrics.paragraphSpacing
        paragraphStyle.firstLineHeadIndent = metrics.fontSize * 2
        paragraphStyle.alignment = .justified
        paragraphStyle.hyphenationFactor = 0.9
        
        let sepiaColor = NSColor(calibratedRed: 0.35, green: 0.28, blue: 0.22, alpha: 1.0)
        let paperColor = NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.1)
        shadow.shadowOffset = NSSize(width: 0, height: -0.5)
        shadow.shadowBlurRadius = 0.5
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: sepiaColor,
            .backgroundColor: paperColor,
            .paragraphStyle: paragraphStyle,
            .kern: 0.2,
            .ligature: 2,
            .shadow: shadow
        ]
        
        return NSAttributedString(string: content, attributes: attributes)
    }
    
    private func renderBionicMode(_ content: String, metrics: TypographyMetrics) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let words = content.components(separatedBy: .whitespaces)
        
        let regularFont = createOptimizedFont(size: metrics.fontSize, weight: .regular)
        let boldFont = createOptimizedFont(size: metrics.fontSize, weight: .bold)
        let paragraphStyle = createParagraphStyle(metrics: metrics)
        
        for (index, word) in words.enumerated() {
            if word.isEmpty { continue }
            
            let fixationLength = min(3, (word.count + 1) / 2)
            let fixationPart = String(word.prefix(fixationLength))
            let remainingPart = String(word.dropFirst(fixationLength))
            
            let boldAttributes: [NSAttributedString.Key: Any] = [
                .font: boldFont,
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle
            ]
            
            let regularAttributes: [NSAttributedString.Key: Any] = [
                .font: regularFont,
                .foregroundColor: NSColor.labelColor.withAlphaComponent(0.85),
                .paragraphStyle: paragraphStyle
            ]
            
            result.append(NSAttributedString(string: fixationPart, attributes: boldAttributes))
            result.append(NSAttributedString(string: remainingPart, attributes: regularAttributes))
            
            if index < words.count - 1 {
                result.append(NSAttributedString(string: " ", attributes: regularAttributes))
            }
        }
        
        return result
    }
    
    private func renderDyslexicMode(_ content: String, metrics: TypographyMetrics) -> NSAttributedString {
        let font = NSFont(name: "OpenDyslexic", size: metrics.fontSize) ??
                   NSFont.systemFont(ofSize: metrics.fontSize, weight: .medium)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 2.0
        paragraphStyle.paragraphSpacing = metrics.paragraphSpacing * 1.5
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.2, alpha: 1.0),
            .backgroundColor: NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.94, alpha: 1.0),
            .paragraphStyle: paragraphStyle,
            .kern: 1.5,
            .expansion: 0.2,
            .ligature: 0
        ]
        
        return NSAttributedString(string: content, attributes: attributes)
    }
    
    private func createOptimizedFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
        let displaySize: CGFloat = 20
        let textSize: CGFloat = 14
        
        let fontName: String
        if size > displaySize {
            fontName = "SF Pro Display"
        } else if size < textSize {
            fontName = "SF Pro Text"
        } else {
            fontName = "SF Pro Text"
        }
        
        if let font = NSFont(name: fontName, size: size) {
            return NSFont.systemFont(ofSize: size, weight: weight)
        }
        
        return NSFont.systemFont(ofSize: size, weight: weight)
    }
    
    private func createParagraphStyle(metrics: TypographyMetrics) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = metrics.lineHeight / metrics.fontSize
        style.paragraphSpacing = metrics.paragraphSpacing
        style.paragraphSpacingBefore = metrics.paragraphSpacing * 0.5
        style.lineBreakStrategy = [.pushOut, .hangulWordPriority]
        style.hyphenationFactor = 0.8
        style.tighteningFactorForTruncation = 0.05
        style.allowsDefaultTighteningForTruncation = true
        
        return style
    }
    
    func getCurrentMetrics() -> TypographyMetrics {
        return currentMetrics
    }
}