import Foundation
import Cocoa
import QuartzCore

/// Sophisticated animation engine for award-winning UI transitions
class AnimationEngine {
    
    // MARK: - Animation Presets
    
    enum AnimationCurve {
        case easeInOut
        case spring
        case smooth
        case bounce
        case elastic
        
        var timingFunction: CAMediaTimingFunction {
            switch self {
            case .easeInOut:
                return CAMediaTimingFunction(controlPoints: 0.42, 0, 0.58, 1.0)
            case .spring:
                return CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
            case .smooth:
                return CAMediaTimingFunction(controlPoints: 0.45, 0.05, 0.55, 0.95)
            case .bounce:
                return CAMediaTimingFunction(controlPoints: 0.68, -0.55, 0.265, 1.55)
            case .elastic:
                return CAMediaTimingFunction(controlPoints: 0.68, -0.6, 0.32, 1.6)
            }
        }
    }
    
    // MARK: - Smooth Scroll Animation
    
    static func animateScroll(to point: NSPoint, in scrollView: NSScrollView, duration: TimeInterval = 0.5) {
        let clipView = scrollView.contentView
        let currentPoint = clipView.bounds.origin
        
        // Calculate the animation path with easing
        let animator = ScrollAnimator(
            from: currentPoint,
            to: point,
            duration: duration,
            curve: .spring
        )
        
        animator.animate { intermediatePoint in
            clipView.animator().setBoundsOrigin(intermediatePoint)
            scrollView.reflectScrolledClipView(clipView)
        }
    }
    
    // MARK: - Focus Mode Animation
    
    static func animateFocusMode(enabled: Bool, in textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.6
            context.timingFunction = AnimationCurve.smooth.timingFunction
            context.allowsImplicitAnimation = true
            
            if enabled {
                // Dim non-focused content
                dimNonFocusedContent(in: textStorage, textView: textView)
            } else {
                // Restore full brightness
                restoreFullBrightness(in: textStorage)
            }
        })
    }
    
    private static func dimNonFocusedContent(in textStorage: NSTextStorage, textView: NSTextView) {
        let visibleRange = textView.visibleRange()
        let fullRange = NSRange(location: 0, length: textStorage.length)
        
        textStorage.beginEditing()
        
        // Apply dimming with gradient falloff
        textStorage.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            var newAttributes = attributes
            
            let distanceFromVisible = abs(range.location - visibleRange.location)
            let dimFactor = min(1.0, CGFloat(distanceFromVisible) / 1000.0)
            let alpha = 0.3 + (0.7 * (1.0 - dimFactor))
            
            if let color = attributes[.foregroundColor] as? NSColor {
                newAttributes[.foregroundColor] = color.withAlphaComponent(alpha)
            }
            
            textStorage.addAttributes(newAttributes, range: range)
        }
        
        textStorage.endEditing()
    }
    
    private static func restoreFullBrightness(in textStorage: NSTextStorage) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        
        textStorage.beginEditing()
        
        textStorage.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            var newAttributes = attributes
            
            if let color = attributes[.foregroundColor] as? NSColor {
                newAttributes[.foregroundColor] = color.withAlphaComponent(1.0)
            }
            
            textStorage.addAttributes(newAttributes, range: range)
        }
        
        textStorage.endEditing()
    }
    
    // MARK: - Link Hover Animation
    
    static func animateLinkHover(_ link: NSRange, in textView: NSTextView, isHovering: Bool) {
        guard let textStorage = textView.textStorage else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            context.timingFunction = AnimationCurve.smooth.timingFunction
            
            textStorage.beginEditing()
            
            if isHovering {
                // Add underline animation
                textStorage.addAttributes([
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .underlineColor: NSColor(calibratedRed: 0.0, green: 0.478, blue: 1.0, alpha: 0.8)
                ], range: link)
                
                // Slight color shift
                if let currentColor = textStorage.attribute(.foregroundColor, at: link.location, effectiveRange: nil) as? NSColor {
                    let brighterColor = currentColor.blended(withFraction: 0.2, of: .systemBlue) ?? currentColor
                    textStorage.addAttribute(.foregroundColor, value: brighterColor, range: link)
                }
            } else {
                // Remove hover effects
                textStorage.removeAttribute(.underlineStyle, range: link)
                textStorage.removeAttribute(.underlineColor, range: link)
            }
            
            textStorage.endEditing()
        })
    }
    
    // MARK: - Selection Animation
    
    static func animateSelection(_ range: NSRange, in textView: NSTextView) {
        // Create a subtle pulse effect around the selection
        let selectionLayer = CALayer()
        selectionLayer.frame = rectForRange(range, in: textView)
        selectionLayer.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.1).cgColor
        selectionLayer.cornerRadius = 2
        
        textView.layer?.addSublayer(selectionLayer)
        
        // Pulse animation
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 0
        pulse.toValue = 1
        pulse.duration = 0.3
        pulse.autoreverses = true
        pulse.repeatCount = 2
        pulse.timingFunction = AnimationCurve.smooth.timingFunction
        
        selectionLayer.add(pulse, forKey: "pulse")
        
        // Remove layer after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            selectionLayer.removeFromSuperlayer()
        }
    }
    
    private static func rectForRange(_ range: NSRange, in textView: NSTextView) -> CGRect {
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return .zero
        }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        
        return rect
    }
    
    // MARK: - Page Turn Animation
    
    static func animatePageTurn(in scrollView: NSScrollView, direction: PageDirection) {
        guard let documentView = scrollView.documentView else { return }
        
        let pageHeight = scrollView.contentView.bounds.height
        let currentOffset = scrollView.contentView.bounds.origin.y
        let newOffset: CGFloat
        
        switch direction {
        case .next:
            newOffset = currentOffset + pageHeight
        case .previous:
            newOffset = max(0, currentOffset - pageHeight)
        }
        
        // Create a sophisticated page turn effect
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            context.timingFunction = AnimationCurve.spring.timingFunction
            context.allowsImplicitAnimation = true
            
            // Add a subtle scale effect
            documentView.layer?.transform = CATransform3DMakeScale(0.98, 0.98, 1.0)
            
            scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: newOffset))
            scrollView.reflectScrolledClipView(scrollView.contentView)
            
        }, completionHandler: {
            // Reset transform
            documentView.layer?.transform = CATransform3DIdentity
        })
    }
    
    enum PageDirection {
        case next
        case previous
    }
}

// MARK: - Scroll Animator

private class ScrollAnimator {
    private let from: NSPoint
    private let to: NSPoint
    private let duration: TimeInterval
    private let curve: AnimationEngine.AnimationCurve
    private var displayLink: CVDisplayLink?
    private var startTime: TimeInterval = 0
    private var animationBlock: ((NSPoint) -> Void)?
    
    init(from: NSPoint, to: NSPoint, duration: TimeInterval, curve: AnimationEngine.AnimationCurve) {
        self.from = from
        self.to = to
        self.duration = duration
        self.curve = curve
    }
    
    func animate(update: @escaping (NSPoint) -> Void) {
        animationBlock = update
        startTime = CACurrentMediaTime()
        
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        
        if let displayLink = displayLink {
            CVDisplayLinkSetOutputCallback(displayLink, { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, context) -> CVReturn in
                let animator = Unmanaged<ScrollAnimator>.fromOpaque(context!).takeUnretainedValue()
                animator.updateAnimation()
                return kCVReturnSuccess
            }, Unmanaged.passUnretained(self).toOpaque())
            
            CVDisplayLinkStart(displayLink)
        }
    }
    
    private func updateAnimation() {
        let elapsed = CACurrentMediaTime() - startTime
        let progress = min(1.0, elapsed / duration)
        
        if progress >= 1.0 {
            animationBlock?(to)
            stopAnimation()
            return
        }
        
        // Apply easing curve
        let easedProgress = easeInOutCubic(progress)
        
        let currentPoint = NSPoint(
            x: from.x + (to.x - from.x) * easedProgress,
            y: from.y + (to.y - from.y) * easedProgress
        )
        
        DispatchQueue.main.async {
            self.animationBlock?(currentPoint)
        }
    }
    
    private func stopAnimation() {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
            self.displayLink = nil
        }
    }
    
    private func easeInOutCubic(_ t: CGFloat) -> CGFloat {
        if t < 0.5 {
            return 4 * t * t * t
        } else {
            let p = 2 * t - 2
            return 1 + p * p * p / 2
        }
    }
}

// MARK: - Typewriter Scrolling

extension AnimationEngine {
    
    static func enableTypewriterScrolling(in scrollView: NSScrollView, textView: NSTextView) {
        // Keep current line centered in view
        NotificationCenter.default.addObserver(
            forName: NSTextView.didChangeSelectionNotification,
            object: textView,
            queue: .main
        ) { _ in
            animateTypewriterScroll(scrollView: scrollView, textView: textView)
        }
    }
    
    private static func animateTypewriterScroll(scrollView: NSScrollView, textView: NSTextView) {
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }
        
        let selectedRange = textView.selectedRange()
        let glyphRange = layoutManager.glyphRange(forCharacterRange: selectedRange, actualCharacterRange: nil)
        let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphRange.location, effectiveRange: nil)
        
        let viewHeight = scrollView.contentView.bounds.height
        let targetY = lineRect.midY - viewHeight / 2
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = AnimationCurve.smooth.timingFunction
            context.allowsImplicitAnimation = true
            
            scrollView.contentView.animator().setBoundsOrigin(NSPoint(x: 0, y: targetY))
            scrollView.reflectScrolledClipView(scrollView.contentView)
        })
    }
}

// MARK: - NSTextView Extensions

extension NSTextView {
    func visibleRange() -> NSRange {
        guard let layoutManager = layoutManager,
              let textContainer = textContainer else {
            return NSRange(location: 0, length: 0)
        }
        
        let visibleRect = visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        return characterRange
    }
}