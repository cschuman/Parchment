import Cocoa
import QuartzCore

final class ModeIndicatorView: NSView {
    
    private var titleLabel: NSTextField!
    private var subtitleLabel: NSTextField!
    private var iconView: NSImageView!
    private var blurView: NSVisualEffectView!
    
    private var dismissTimer: Timer?
    
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
        
        // Create blur background for elegance
        blurView = NSVisualEffectView()
        blurView.blendingMode = .behindWindow
        blurView.material = .hudWindow
        blurView.state = .active
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = 16
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        
        // Icon
        iconView = NSImageView()
        iconView.imageScaling = .scaleProportionallyDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentTintColor = .white
        addSubview(iconView)
        
        // Title
        titleLabel = NSTextField(labelWithString: "")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // Subtitle
        subtitleLabel = NSTextField(labelWithString: "")
        subtitleLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = NSColor.white.withAlphaComponent(0.8)
        subtitleLabel.alignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            // Blur view fills the entire view
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Icon at top
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
            
            // Title below icon
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            // Subtitle below title
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
        
        // Start hidden
        alphaValue = 0
    }
    
    func showMode(_ mode: String, subtitle: String? = nil, icon: NSImage? = nil) {
        titleLabel.stringValue = mode
        subtitleLabel.stringValue = subtitle ?? ""
        subtitleLabel.isHidden = subtitle == nil
        
        if let icon = icon {
            iconView.image = icon
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
            // Use SF Symbols or default icon based on mode
            iconView.image = iconForMode(mode)
            iconView.isHidden = false
        }
        
        // Cancel any existing dismiss timer
        dismissTimer?.invalidate()
        
        // Animate in with spring effect
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
            context.allowsImplicitAnimation = true
            
            // Scale and fade in
            self.animator().alphaValue = 1.0
            self.layer?.transform = CATransform3DIdentity
            
        }) {
            // Auto-dismiss after 2.5 seconds
            self.dismissTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                self.hide()
            }
        }
        
        // Add subtle bounce animation
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [0.8, 1.05, 0.95, 1.0]
        scaleAnimation.keyTimes = [0, 0.4, 0.7, 1.0]
        scaleAnimation.duration = 0.5
        scaleAnimation.timingFunctions = [
            CAMediaTimingFunction(name: .easeOut),
            CAMediaTimingFunction(name: .easeInEaseOut),
            CAMediaTimingFunction(name: .easeInEaseOut)
        ]
        layer?.add(scaleAnimation, forKey: "bounce")
    }
    
    private func hide() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            self.animator().alphaValue = 0
            
            // Subtle scale down
            var transform = CATransform3DIdentity
            transform = CATransform3DScale(transform, 0.9, 0.9, 1.0)
            self.layer?.transform = transform
        })
    }
    
    private func iconForMode(_ mode: String) -> NSImage? {
        // Create simple icons for each mode
        let config = NSImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        
        switch mode.lowercased() {
        case "focus mode":
            return NSImage(systemSymbolName: "eye", accessibilityDescription: nil)?
                .withSymbolConfiguration(config)
        case "night mode":
            return NSImage(systemSymbolName: "moon.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(config)
        case "speed reading":
            return NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(config)
        case "paper mode":
            return NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil)?
                .withSymbolConfiguration(config)
        case "bionic reading":
            return NSImage(systemSymbolName: "brain", accessibilityDescription: nil)?
                .withSymbolConfiguration(config)
        case "dyslexic mode":
            return NSImage(systemSymbolName: "character.book.closed", accessibilityDescription: nil)?
                .withSymbolConfiguration(config)
        case "normal":
            return NSImage(systemSymbolName: "text.alignleft", accessibilityDescription: nil)?
                .withSymbolConfiguration(config)
        default:
            return NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)?
                .withSymbolConfiguration(config)
        }
    }
}