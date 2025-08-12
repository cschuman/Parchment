import Cocoa
import QuartzCore

/// A sophisticated page container that creates a beautiful reading experience with side bars
class PageContainerView: NSView {
    
    // MARK: - Properties
    
    private var contentView: NSView!
    private var leftBarLayer: CAGradientLayer!
    private var rightBarLayer: CAGradientLayer!
    private var contentShadowLayer: CALayer!
    private var pageBackgroundLayer: CALayer!
    
    // Design constants
    private let pageWidth: CGFloat = 700
    private let sideBarWidth: CGFloat = 80
    private let contentInset: CGFloat = 40
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.97, alpha: 1.0).cgColor
        
        setupPageBackground()
        setupSideBars()
        setupContentArea()
        setupShadows()
    }
    
    // MARK: - Layout Setup
    
    private func setupPageBackground() {
        pageBackgroundLayer = CALayer()
        pageBackgroundLayer.backgroundColor = NSColor.white.cgColor
        pageBackgroundLayer.cornerRadius = 2
        layer?.addSublayer(pageBackgroundLayer)
    }
    
    private func setupSideBars() {
        // Left sidebar with gradient
        leftBarLayer = CAGradientLayer()
        leftBarLayer.colors = [
            NSColor(calibratedWhite: 0, alpha: 0.03).cgColor,
            NSColor(calibratedWhite: 0, alpha: 0.01).cgColor,
            NSColor(calibratedWhite: 0, alpha: 0.0).cgColor
        ]
        leftBarLayer.locations = [0.0, 0.7, 1.0]
        leftBarLayer.startPoint = CGPoint(x: 0, y: 0.5)
        leftBarLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        // Right sidebar with gradient
        rightBarLayer = CAGradientLayer()
        rightBarLayer.colors = [
            NSColor(calibratedWhite: 0, alpha: 0.03).cgColor,
            NSColor(calibratedWhite: 0, alpha: 0.01).cgColor,
            NSColor(calibratedWhite: 0, alpha: 0.0).cgColor
        ]
        rightBarLayer.locations = [0.0, 0.7, 1.0]
        rightBarLayer.startPoint = CGPoint(x: 1, y: 0.5)
        rightBarLayer.endPoint = CGPoint(x: 0, y: 0.5)
        
        layer?.addSublayer(leftBarLayer)
        layer?.addSublayer(rightBarLayer)
    }
    
    private func setupContentArea() {
        contentView = NSView()
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.white.cgColor
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: contentInset),
            contentView.widthAnchor.constraint(equalToConstant: pageWidth),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInset)
        ])
    }
    
    private func setupShadows() {
        // Multiple shadow layers for depth
        contentShadowLayer = CALayer()
        contentShadowLayer.backgroundColor = NSColor.clear.cgColor
        contentShadowLayer.shadowColor = NSColor.black.cgColor
        contentShadowLayer.shadowOpacity = 0.08
        contentShadowLayer.shadowOffset = CGSize(width: 0, height: 4)
        contentShadowLayer.shadowRadius = 20
        
        // Additional close shadow for paper effect
        let closeShadow = CALayer()
        closeShadow.backgroundColor = NSColor.clear.cgColor
        closeShadow.shadowColor = NSColor.black.cgColor
        closeShadow.shadowOpacity = 0.05
        closeShadow.shadowOffset = CGSize(width: 0, height: 1)
        closeShadow.shadowRadius = 3
        
        layer?.insertSublayer(contentShadowLayer, below: contentView.layer)
        layer?.insertSublayer(closeShadow, below: contentView.layer)
    }
    
    // MARK: - Layout
    
    override func layout() {
        super.layout()
        
        let centerX = bounds.width / 2
        let pageRect = CGRect(
            x: centerX - pageWidth / 2,
            y: contentInset,
            width: pageWidth,
            height: bounds.height - contentInset * 2
        )
        
        // Update page background
        pageBackgroundLayer.frame = pageRect.insetBy(dx: -2, dy: -2)
        
        // Update side bars
        leftBarLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: pageRect.minX,
            height: bounds.height
        )
        
        rightBarLayer.frame = CGRect(
            x: pageRect.maxX,
            y: 0,
            width: bounds.width - pageRect.maxX,
            height: bounds.height
        )
        
        // Update shadow
        contentShadowLayer.frame = pageRect
        contentShadowLayer.shadowPath = CGPath(rect: CGRect(origin: .zero, size: pageRect.size), transform: nil)
    }
    
    // MARK: - Appearance Updates
    
    override func updateLayer() {
        super.updateLayer()
        
        // Adapt colors for dark mode
        if effectiveAppearance.name == .darkAqua {
            layer?.backgroundColor = NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.13, alpha: 1.0).cgColor
            pageBackgroundLayer.backgroundColor = NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.20, alpha: 1.0).cgColor
            contentView.layer?.backgroundColor = NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.20, alpha: 1.0).cgColor
            
            leftBarLayer.colors = [
                NSColor(calibratedWhite: 1, alpha: 0.02).cgColor,
                NSColor(calibratedWhite: 1, alpha: 0.01).cgColor,
                NSColor(calibratedWhite: 1, alpha: 0.0).cgColor
            ]
            
            rightBarLayer.colors = leftBarLayer.colors
        } else {
            layer?.backgroundColor = NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.97, alpha: 1.0).cgColor
            pageBackgroundLayer.backgroundColor = NSColor.white.cgColor
            contentView.layer?.backgroundColor = NSColor.white.cgColor
            
            leftBarLayer.colors = [
                NSColor(calibratedWhite: 0, alpha: 0.03).cgColor,
                NSColor(calibratedWhite: 0, alpha: 0.01).cgColor,
                NSColor(calibratedWhite: 0, alpha: 0.0).cgColor
            ]
            
            rightBarLayer.colors = leftBarLayer.colors
        }
    }
    
    // MARK: - Animation Support
    
    func animatePageTurn(direction: PageTurnDirection, completion: (() -> Void)? = nil) {
        let animation = CABasicAnimation(keyPath: "transform.rotation.y")
        animation.duration = 0.6
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        switch direction {
        case .forward:
            animation.fromValue = 0
            animation.toValue = -0.05
        case .backward:
            animation.fromValue = 0
            animation.toValue = 0.05
        }
        
        animation.autoreverses = true
        animation.isRemovedOnCompletion = true
        
        contentView.layer?.add(animation, forKey: "pageTurn")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration) {
            completion?()
        }
    }
    
    enum PageTurnDirection {
        case forward
        case backward
    }
    
    // MARK: - Focus Mode Support
    
    func setFocusMode(_ enabled: Bool, animated: Bool = true) {
        let targetOpacity: Float = enabled ? 0.08 : 0.03
        
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                CATransaction.begin()
                CATransaction.setAnimationDuration(0.3)
                
                // Increase side bar opacity in focus mode
                leftBarLayer.opacity = targetOpacity
                rightBarLayer.opacity = targetOpacity
                
                // Slightly dim the background
                if enabled {
                    layer?.backgroundColor = NSColor(calibratedRed: 0.94, green: 0.94, blue: 0.95, alpha: 1.0).cgColor
                } else {
                    layer?.backgroundColor = NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.97, alpha: 1.0).cgColor
                }
                
                CATransaction.commit()
            })
        } else {
            leftBarLayer.opacity = targetOpacity
            rightBarLayer.opacity = targetOpacity
        }
    }
    
    // MARK: - Content Management
    
    func embedTextView(_ textView: NSTextView) {
        // Remove any existing text view
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Add the text view to content area
        textView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
        
        // Configure text view for optimal appearance
        textView.backgroundColor = NSColor.clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 20, height: 20)
    }
}

// MARK: - Custom Drawing for Extra Polish

extension PageContainerView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Add subtle paper texture
        if let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            
            // Very subtle noise texture for paper feel
            let noiseLayer = CALayer()
            noiseLayer.frame = bounds
            noiseLayer.backgroundColor = NSColor(calibratedWhite: 0.5, alpha: 0.01).cgColor
            noiseLayer.compositingFilter = "multiplyBlendMode"
            
            context.restoreGState()
        }
    }
}