import Cocoa
import QuartzCore

final class EnhancedFocusMode {
    
    enum FocusStyle {
        case paragraph
        case sentence
        case line
        case gradual
        case spotlight
    }
    
    struct FocusConfiguration {
        var style: FocusStyle = .paragraph
        var focusOpacity: CGFloat = 1.0
        var dimOpacity: CGFloat = 0.3
        var transitionDuration: TimeInterval = 0.3
        var focusRange: Int = 1
        var gradientSoftness: CGFloat = 100
        var tracksCursor: Bool = true
        var autoAdvance: Bool = false
        var autoAdvanceSpeed: TimeInterval = 5.0
    }
    
    private weak var textView: NSTextView?
    private var configuration = FocusConfiguration()
    private var focusLayer: CALayer?
    private var gradientMask: CAGradientLayer?
    private var spotlightLayer: CALayer?
    private var currentFocusRange: NSRange = NSRange(location: 0, length: 0)
    private var autoAdvanceTimer: Timer?
    
    init(textView: NSTextView) {
        self.textView = textView
        setupLayers()
        observeTextViewChanges()
    }
    
    private func setupLayers() {
        guard let textView = textView else { return }
        
        textView.wantsLayer = true
        
        focusLayer = CALayer()
        focusLayer?.backgroundColor = NSColor.clear.cgColor
        focusLayer?.zPosition = 100
        
        gradientMask = CAGradientLayer()
        gradientMask?.colors = [
            NSColor.black.withAlphaComponent(0).cgColor,
            NSColor.black.cgColor,
            NSColor.black.cgColor,
            NSColor.black.withAlphaComponent(0).cgColor
        ]
        gradientMask?.locations = [0, 0.2, 0.8, 1.0]
        gradientMask?.startPoint = CGPoint(x: 0.5, y: 0)
        gradientMask?.endPoint = CGPoint(x: 0.5, y: 1)
        
        spotlightLayer = CALayer()
        spotlightLayer?.backgroundColor = NSColor.black.withAlphaComponent(0.7).cgColor
        spotlightLayer?.compositingFilter = "multiplyBlendMode"
    }
    
    private func observeTextViewChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewDidChangeSelection),
            name: NSTextView.didChangeSelectionNotification,
            object: textView
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidScroll),
            name: NSScrollView.didLiveScrollNotification,
            object: textView?.enclosingScrollView
        )
    }
    
    func enable(with style: FocusStyle = .paragraph) {
        configuration.style = style
        
        switch style {
        case .paragraph:
            enableParagraphFocus()
        case .sentence:
            enableSentenceFocus()
        case .line:
            enableLineFocus()
        case .gradual:
            enableGradualFocus()
        case .spotlight:
            enableSpotlightFocus()
        }
        
        if configuration.autoAdvance {
            startAutoAdvance()
        }
    }
    
    func disable() {
        stopAutoAdvance()
        removeAllFocusEffects()
    }
    
    private func enableParagraphFocus() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        let visibleRange = textView.visibleRange()
        let text = textStorage.string as NSString
        
        var paragraphRange = text.paragraphRange(for: visibleRange)
        
        if configuration.focusRange > 1 {
            for _ in 1..<configuration.focusRange {
                let nextLocation = NSMaxRange(paragraphRange)
                if nextLocation < text.length {
                    let nextParagraph = text.paragraphRange(
                        for: NSRange(location: nextLocation, length: 0)
                    )
                    paragraphRange = NSUnionRange(paragraphRange, nextParagraph)
                }
            }
        }
        
        animateFocusTransition(to: paragraphRange)
    }
    
    private func enableSentenceFocus() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        let cursorLocation = textView.selectedRange().location
        let text = textStorage.string as NSString
        
        var sentenceRange = NSRange(location: 0, length: 0)
        text.enumerateSubstrings(
            in: NSRange(location: 0, length: text.length),
            options: [.bySentences, .localized]
        ) { _, range, _, stop in
            if NSLocationInRange(cursorLocation, range) {
                sentenceRange = range
                stop.pointee = true
            }
        }
        
        if sentenceRange.length > 0 {
            animateFocusTransition(to: sentenceRange)
        }
    }
    
    private func enableLineFocus() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        let cursorLocation = textView.selectedRange().location
        let text = textStorage.string as NSString
        let lineRange = text.lineRange(for: NSRange(location: cursorLocation, length: 0))
        
        animateFocusTransition(to: lineRange)
    }
    
    private func enableGradualFocus() {
        guard let textView = textView else { return }
        
        let visibleRect = textView.visibleRect
        let centerY = visibleRect.midY
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(configuration.transitionDuration)
        
        if gradientMask?.superlayer == nil {
            textView.layer?.mask = gradientMask
        }
        
        gradientMask?.frame = textView.bounds
        
        let focusHeight = configuration.gradientSoftness * 2
        let topLocation = max(0, (centerY - focusHeight/2) / textView.bounds.height)
        let bottomLocation = min(1, (centerY + focusHeight/2) / textView.bounds.height)
        
        gradientMask?.locations = [
            0,
            NSNumber(value: Double(topLocation)),
            NSNumber(value: Double(bottomLocation)),
            1
        ]
        
        CATransaction.commit()
    }
    
    private func enableSpotlightFocus() {
        guard let textView = textView else { return }
        
        let cursorLocation = textView.selectedRange().location
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        let glyphRange = layoutManager.glyphRange(
            forCharacterRange: NSRange(location: cursorLocation, length: 0),
            actualCharacterRange: nil
        )
        let rect = layoutManager.boundingRect(
            forGlyphRange: glyphRange,
            in: textContainer
        )
        
        createSpotlightEffect(at: rect.center, radius: 200)
    }
    
    private func animateFocusTransition(to range: NSRange) {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(configuration.transitionDuration)
        CATransaction.setAnimationTimingFunction(
            CAMediaTimingFunction(name: .easeInEaseOut)
        )
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        
        textStorage.enumerateAttribute(
            .foregroundColor,
            in: fullRange,
            options: []
        ) { _, attributeRange, _ in
            let isDimmed = !NSLocationInRange(attributeRange.location, range)
            let targetOpacity = isDimmed ? configuration.dimOpacity : configuration.focusOpacity
            
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.toValue = targetOpacity
            animation.duration = configuration.transitionDuration
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            
            textStorage.addAttribute(
                .foregroundColor,
                value: NSColor.labelColor.withAlphaComponent(targetOpacity),
                range: attributeRange
            )
        }
        
        currentFocusRange = range
        
        CATransaction.commit()
        
        if configuration.tracksCursor {
            ensureRangeIsVisible(range)
        }
    }
    
    private func createSpotlightEffect(at center: CGPoint, radius: CGFloat) {
        guard let textView = textView else { return }
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(configuration.transitionDuration)
        
        if spotlightLayer?.superlayer == nil {
            textView.layer?.addSublayer(spotlightLayer!)
        }
        
        spotlightLayer?.frame = textView.bounds
        
        let spotlightPath = CGMutablePath()
        spotlightPath.addRect(textView.bounds)
        spotlightPath.addEllipse(in: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = spotlightPath
        maskLayer.fillRule = .evenOdd
        
        spotlightLayer?.mask = maskLayer
        
        CATransaction.commit()
    }
    
    private func ensureRangeIsVisible(_ range: NSRange) {
        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        textView.scrollToVisible(rect.insetBy(dx: 0, dy: -50))
    }
    
    private func startAutoAdvance() {
        stopAutoAdvance()
        
        autoAdvanceTimer = Timer.scheduledTimer(withTimeInterval: configuration.autoAdvanceSpeed, repeats: true) { [weak self] _ in
            self?.advanceToNextSection()
        }
    }
    
    private func stopAutoAdvance() {
        autoAdvanceTimer?.invalidate()
        autoAdvanceTimer = nil
    }
    
    private func advanceToNextSection() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        let text = textStorage.string as NSString
        let nextLocation = NSMaxRange(currentFocusRange)
        
        guard nextLocation < text.length else {
            currentFocusRange = NSRange(location: 0, length: 0)
            return
        }
        
        switch configuration.style {
        case .paragraph:
            let nextRange = text.paragraphRange(for: NSRange(location: nextLocation, length: 0))
            animateFocusTransition(to: nextRange)
            
        case .sentence:
            var nextRange = NSRange(location: 0, length: 0)
            text.enumerateSubstrings(
                in: NSRange(location: nextLocation, length: text.length - nextLocation),
                options: [.bySentences]
            ) { _, range, _, stop in
                nextRange = range
                stop.pointee = true
            }
            if nextRange.length > 0 {
                animateFocusTransition(to: nextRange)
            }
            
        default:
            break
        }
    }
    
    private func removeAllFocusEffects() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(configuration.transitionDuration)
        
        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.removeAttribute(.foregroundColor, range: fullRange)
        textStorage.addAttribute(
            .foregroundColor,
            value: NSColor.labelColor,
            range: fullRange
        )
        
        gradientMask?.removeFromSuperlayer()
        spotlightLayer?.removeFromSuperlayer()
        textView.layer?.mask = nil
        
        CATransaction.commit()
    }
    
    @objc private func textViewDidChangeSelection(_ notification: Notification) {
        guard configuration.tracksCursor else { return }
        
        switch configuration.style {
        case .paragraph:
            enableParagraphFocus()
        case .sentence:
            enableSentenceFocus()
        case .line:
            enableLineFocus()
        case .spotlight:
            enableSpotlightFocus()
        default:
            break
        }
    }
    
    @objc private func scrollViewDidScroll(_ notification: Notification) {
        switch configuration.style {
        case .gradual:
            enableGradualFocus()
        case .spotlight:
            if configuration.tracksCursor {
                enableSpotlightFocus()
            }
        default:
            break
        }
    }
}

// NSTextView.visibleRange() extension is defined in AnimationEngine.swift

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}