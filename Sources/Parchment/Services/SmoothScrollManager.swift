import Cocoa
import QuartzCore

/// Manages smooth, spring-physics based scrolling for a beautiful reading experience
final class SmoothScrollManager: NSObject {
    
    private weak var scrollView: NSScrollView?
    private var displayLink: CVDisplayLink?
    private var targetOffset: CGPoint?
    private var velocity: CGPoint = .zero
    private var isDecelerating = false
    
    // Spring physics parameters
    private let springStiffness: CGFloat = 200.0
    private let springDamping: CGFloat = 25.0
    private let velocityThreshold: CGFloat = 0.5
    private let positionThreshold: CGFloat = 0.5
    
    // Smooth scroll settings
    var scrollDuration: TimeInterval = 0.4
    var scrollCurve: CAMediaTimingFunction = .init(name: .easeInEaseOut)
    var enableMomentumScrolling = true
    var enableRubberBanding = true
    
    init(scrollView: NSScrollView) {
        self.scrollView = scrollView
        super.init()
        setupDisplayLink()
        observeScrollEvents()
    }
    
    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }
    
    // MARK: - Smooth Scrolling
    
    /// Smoothly scroll to a specific point
    func smoothScroll(to point: CGPoint, animated: Bool = true) {
        guard animated else {
            scrollView?.contentView.scroll(to: point)
            return
        }
        
        targetOffset = point
        startDisplayLink()
    }
    
    /// Smoothly scroll to a specific rect, ensuring it's visible
    func smoothScroll(to rect: NSRect, animated: Bool = true) {
        guard let scrollView = scrollView else { return }
        
        let visibleRect = scrollView.contentView.visibleRect
        var targetPoint = visibleRect.origin
        
        // Calculate optimal scroll position
        if rect.minY < visibleRect.minY {
            targetPoint.y = rect.minY
        } else if rect.maxY > visibleRect.maxY {
            targetPoint.y = rect.maxY - visibleRect.height
        }
        
        if rect.minX < visibleRect.minX {
            targetPoint.x = rect.minX
        } else if rect.maxX > visibleRect.maxX {
            targetPoint.x = rect.maxX - visibleRect.width
        }
        
        smoothScroll(to: targetPoint, animated: animated)
    }
    
    /// Smoothly scroll by a relative offset
    func smoothScroll(by offset: CGPoint, animated: Bool = true) {
        guard let scrollView = scrollView else { return }
        
        let currentOffset = scrollView.contentView.visibleRect.origin
        let targetPoint = CGPoint(
            x: currentOffset.x + offset.x,
            y: currentOffset.y + offset.y
        )
        
        smoothScroll(to: targetPoint, animated: animated)
    }
    
    // MARK: - Page Navigation
    
    /// Scroll by page with smooth animation
    func scrollPage(direction: PageDirection) {
        guard let scrollView = scrollView else { return }
        
        let pageHeight = scrollView.contentView.visibleRect.height * 0.9
        let offset: CGPoint
        
        switch direction {
        case .up:
            offset = CGPoint(x: 0, y: -pageHeight)
        case .down:
            offset = CGPoint(x: 0, y: pageHeight)
        }
        
        smoothScroll(by: offset)
    }
    
    enum PageDirection {
        case up, down
    }
    
    // MARK: - Display Link
    
    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        
        guard let displayLink = displayLink else { return }
        
        CVDisplayLinkSetOutputCallback(displayLink, { (_, _, _, _, _, userInfo) -> CVReturn in
            guard let userInfo = userInfo else { return kCVReturnSuccess }
            let manager = Unmanaged<SmoothScrollManager>.fromOpaque(userInfo).takeUnretainedValue()
            manager.displayLinkFired()
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
    }
    
    private func startDisplayLink() {
        guard let displayLink = displayLink else { return }
        if !CVDisplayLinkIsRunning(displayLink) {
            CVDisplayLinkStart(displayLink)
        }
    }
    
    private func stopDisplayLink() {
        guard let displayLink = displayLink else { return }
        if CVDisplayLinkIsRunning(displayLink) {
            CVDisplayLinkStop(displayLink)
        }
    }
    
    private func displayLinkFired() {
        DispatchQueue.main.async { [weak self] in
            self?.updateScrollPosition()
        }
    }
    
    // MARK: - Physics Update
    
    private func updateScrollPosition() {
        guard let scrollView = scrollView,
              let targetOffset = targetOffset else {
            stopDisplayLink()
            return
        }
        
        let currentOffset = scrollView.contentView.visibleRect.origin
        
        // Calculate spring force
        let displacement = CGPoint(
            x: targetOffset.x - currentOffset.x,
            y: targetOffset.y - currentOffset.y
        )
        
        // Apply spring physics
        let springForce = CGPoint(
            x: displacement.x * springStiffness,
            y: displacement.y * springStiffness
        )
        
        let dampingForce = CGPoint(
            x: -velocity.x * springDamping,
            y: -velocity.y * springDamping
        )
        
        let acceleration = CGPoint(
            x: (springForce.x + dampingForce.x) / 100.0,
            y: (springForce.y + dampingForce.y) / 100.0
        )
        
        // Update velocity
        velocity.x += acceleration.x * 0.016 // 60fps frame time
        velocity.y += acceleration.y * 0.016
        
        // Update position
        let newOffset = CGPoint(
            x: currentOffset.x + velocity.x * 0.016,
            y: currentOffset.y + velocity.y * 0.016
        )
        
        // Apply rubber banding at edges if enabled
        let constrainedOffset = enableRubberBanding ? 
            applyRubberBanding(to: newOffset) : 
            constrainToContent(newOffset)
        
        scrollView.contentView.scroll(to: constrainedOffset)
        
        // Check if we've reached the target
        let distanceToTarget = abs(displacement.x) + abs(displacement.y)
        let currentVelocity = abs(velocity.x) + abs(velocity.y)
        
        if distanceToTarget < positionThreshold && currentVelocity < velocityThreshold {
            scrollView.contentView.scroll(to: targetOffset)
            self.targetOffset = nil
            self.velocity = .zero
            stopDisplayLink()
        }
    }
    
    // MARK: - Constraints
    
    private func constrainToContent(_ point: CGPoint) -> CGPoint {
        guard let scrollView = scrollView,
              let documentView = scrollView.documentView else {
            return point
        }
        
        let contentSize = documentView.frame.size
        let visibleSize = scrollView.contentView.visibleRect.size
        
        let maxX = max(0, contentSize.width - visibleSize.width)
        let maxY = max(0, contentSize.height - visibleSize.height)
        
        return CGPoint(
            x: min(max(0, point.x), maxX),
            y: min(max(0, point.y), maxY)
        )
    }
    
    private func applyRubberBanding(to point: CGPoint) -> CGPoint {
        guard let scrollView = scrollView,
              let documentView = scrollView.documentView else {
            return point
        }
        
        let contentSize = documentView.frame.size
        let visibleSize = scrollView.contentView.visibleRect.size
        
        let maxX = max(0, contentSize.width - visibleSize.width)
        let maxY = max(0, contentSize.height - visibleSize.height)
        
        var rubberBandedPoint = point
        
        // Apply rubber banding effect
        let rubberBandStrength: CGFloat = 0.5
        
        if point.x < 0 {
            rubberBandedPoint.x = point.x * rubberBandStrength
        } else if point.x > maxX {
            let overscroll = point.x - maxX
            rubberBandedPoint.x = maxX + (overscroll * rubberBandStrength)
        }
        
        if point.y < 0 {
            rubberBandedPoint.y = point.y * rubberBandStrength
        } else if point.y > maxY {
            let overscroll = point.y - maxY
            rubberBandedPoint.y = maxY + (overscroll * rubberBandStrength)
        }
        
        return rubberBandedPoint
    }
    
    // MARK: - Scroll Event Observation
    
    private func observeScrollEvents() {
        // Override scroll wheel events for smoother scrolling
        if let scrollView = scrollView {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(scrollViewDidScroll),
                name: NSScrollView.didLiveScrollNotification,
                object: scrollView
            )
        }
    }
    
    @objc private func scrollViewDidScroll(_ notification: Notification) {
        // Handle momentum scrolling
        if enableMomentumScrolling && isDecelerating {
            applyMomentumDeceleration()
        }
    }
    
    private func applyMomentumDeceleration() {
        velocity.x *= 0.95
        velocity.y *= 0.95
        
        if abs(velocity.x) < 0.1 && abs(velocity.y) < 0.1 {
            velocity = .zero
            isDecelerating = false
        }
    }
}

// MARK: - Scroll View Extension

extension NSScrollView {
    private static var smoothScrollManagerKey: UInt8 = 0
    
    /// Attach smooth scrolling to this scroll view
    var smoothScrollManager: SmoothScrollManager? {
        get {
            return objc_getAssociatedObject(self, &NSScrollView.smoothScrollManagerKey) as? SmoothScrollManager
        }
        set {
            objc_setAssociatedObject(self, &NSScrollView.smoothScrollManagerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Enable smooth scrolling with spring physics
    func enableSmoothScrolling() {
        if smoothScrollManager == nil {
            smoothScrollManager = SmoothScrollManager(scrollView: self)
        }
    }
}