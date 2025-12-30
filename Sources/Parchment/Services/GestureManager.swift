import Cocoa

/// Navigation directions for gesture-based navigation
enum NavigationDirection {
    case next
    case previous
    case nextDocument
    case previousDocument
}

/// Protocol for handling gesture-based interactions
protocol GestureManagerDelegate: AnyObject {
    func gestureManagerDidRequestZoom(_ manager: GestureManager, to level: CGFloat)
    func gestureManagerDidRequestNavigation(_ manager: GestureManager, direction: NavigationDirection)
    func gestureManagerDidToggleFocusMode(_ manager: GestureManager)
    func gestureManagerDidUpdateZoom(_ manager: GestureManager, to level: CGFloat)
}

/// Manages all gesture-based interactions for markdown viewing
final class GestureManager: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: GestureManagerDelegate?
    private weak var scrollView: NSScrollView?
    private var currentZoomLevel: CGFloat = 1.0
    
    // MARK: - Configuration
    
    private struct Configuration {
        static let minZoom: CGFloat = 0.5
        static let maxZoom: CGFloat = 3.0
        static let zoomSnapThreshold: CGFloat = 0.1
        static let swipeVelocityThreshold: CGFloat = 100
        static let zoomAnimationDuration: TimeInterval = 0.2
    }
    
    // MARK: - Initialization
    
    init(scrollView: NSScrollView) {
        self.scrollView = scrollView
        super.init()
        setupGestureRecognizers()
    }
    
    // MARK: - Setup
    
    private func setupGestureRecognizers() {
        guard let scrollView = scrollView else { return }
        
        // Pinch to zoom
        let pinchGesture = NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        scrollView.addGestureRecognizer(pinchGesture)
        
        // Three-finger swipe for navigation between headers
        let threeFingerSwipe = NSPanGestureRecognizer(target: self, action: #selector(handleThreeFingerSwipe(_:)))
        threeFingerSwipe.buttonMask = 0x1
        threeFingerSwipe.numberOfTouchesRequired = 3
        scrollView.addGestureRecognizer(threeFingerSwipe)
        
        // Two-finger swipe for history navigation
        let twoFingerSwipe = NSPanGestureRecognizer(target: self, action: #selector(handleTwoFingerSwipe(_:)))
        twoFingerSwipe.buttonMask = 0x1
        twoFingerSwipe.numberOfTouchesRequired = 2
        scrollView.addGestureRecognizer(twoFingerSwipe)
        
        // Double-tap to toggle focus mode
        let doubleTap = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfClicksRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePinch(_ gesture: NSMagnificationGestureRecognizer) {
        switch gesture.state {
        case .changed:
            let newZoom = currentZoomLevel * (1 + gesture.magnification)
            let clampedZoom = max(Configuration.minZoom, min(Configuration.maxZoom, newZoom))
            
            if abs(clampedZoom - currentZoomLevel) > 0.01 {
                currentZoomLevel = clampedZoom
                delegate?.gestureManagerDidUpdateZoom(self, to: currentZoomLevel)
            }
            
        case .ended:
            // Snap to common zoom levels
            let targetZoom = snapToNearestZoomLevel(currentZoomLevel)
            if targetZoom != currentZoomLevel {
                animateZoomTo(targetZoom)
            }
            
        default:
            break
        }
        
        gesture.magnification = 0
    }
    
    @objc private func handleThreeFingerSwipe(_ gesture: NSPanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let velocity = gesture.velocity(in: scrollView)
        
        if abs(velocity.x) > abs(velocity.y) {
            if velocity.x > 0 {
                delegate?.gestureManagerDidRequestNavigation(self, direction: .previous)
            } else {
                delegate?.gestureManagerDidRequestNavigation(self, direction: .next)
            }
        }
    }
    
    @objc private func handleTwoFingerSwipe(_ gesture: NSPanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let velocity = gesture.velocity(in: scrollView)
        
        // Horizontal swipe for document history
        if abs(velocity.x) > abs(velocity.y) && abs(velocity.x) > Configuration.swipeVelocityThreshold {
            if velocity.x > 0 {
                delegate?.gestureManagerDidRequestNavigation(self, direction: .previousDocument)
            } else {
                delegate?.gestureManagerDidRequestNavigation(self, direction: .nextDocument)
            }
        }
    }
    
    @objc private func handleDoubleTap(_ gesture: NSClickGestureRecognizer) {
        delegate?.gestureManagerDidToggleFocusMode(self)
    }
    
    // MARK: - Zoom Management
    
    private func snapToNearestZoomLevel(_ zoom: CGFloat) -> CGFloat {
        let snapLevels: [CGFloat] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
        
        var nearestLevel = zoom
        var minDistance = CGFloat.greatestFiniteMagnitude
        
        for level in snapLevels {
            let distance = abs(zoom - level)
            if distance < Configuration.zoomSnapThreshold && distance < minDistance {
                nearestLevel = level
                minDistance = distance
            }
        }
        
        return nearestLevel
    }
    
    private func animateZoomTo(_ targetZoom: CGFloat) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Configuration.zoomAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            
            currentZoomLevel = targetZoom
            delegate?.gestureManagerDidRequestZoom(self, to: targetZoom)
        }
    }
    
    // MARK: - Public Interface
    
    func updateZoomLevel(_ level: CGFloat) {
        currentZoomLevel = max(Configuration.minZoom, min(Configuration.maxZoom, level))
    }
    
    func resetZoom() {
        animateZoomTo(1.0)
    }
    
    func zoomIn() {
        let newZoom = min(currentZoomLevel * 1.25, Configuration.maxZoom)
        animateZoomTo(newZoom)
    }
    
    func zoomOut() {
        let newZoom = max(currentZoomLevel * 0.8, Configuration.minZoom)
        animateZoomTo(newZoom)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToPreviousDocument = Notification.Name("navigateToPreviousDocument")
    static let navigateToNextDocument = Notification.Name("navigateToNextDocument")
}