import Cocoa
import QuartzCore

final class BreadcrumbNavigationView: NSView {
    
    struct NavigationNode {
        let title: String
        let url: URL
        let depth: Int
        let timestamp: Date
        let icon: String?
        var isCurrentLocation: Bool
    }
    
    private var breadcrumbs: [NavigationNode] = []
    private var crumbViews: [BreadcrumbItemView] = []
    private var containerView: NSStackView!
    private var scrollView: NSScrollView!
    
    private let maxVisibleCrumbs = 5
    private var isAnimating = false
    
    weak var delegate: BreadcrumbNavigationDelegate?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor
        layer?.cornerRadius = 8
        layer?.shadowRadius = 4
        layer?.shadowOpacity = 0.1
        layer?.shadowOffset = CGSize(width: 0, height: 2)
        
        scrollView = NSScrollView()
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)
        
        containerView = NSStackView()
        containerView.orientation = .horizontal
        containerView.spacing = 0
        containerView.alignment = .centerY
        containerView.distribution = .fill
        scrollView.documentView = containerView
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func pushLocation(_ node: NavigationNode) {
        for i in 0..<breadcrumbs.count {
            breadcrumbs[i].isCurrentLocation = false
        }
        
        var newNode = node
        newNode.isCurrentLocation = true
        breadcrumbs.append(newNode)
        
        if breadcrumbs.count > 10 {
            breadcrumbs.removeFirst()
        }
        
        animateNewBreadcrumb(newNode)
        updateBreadcrumbVisibility()
    }
    
    func popToLocation(at index: Int) {
        guard index < breadcrumbs.count else { return }
        
        let targetNode = breadcrumbs[index]
        
        animatePopTransition(to: index) {
            self.breadcrumbs.removeSubrange((index + 1)..<self.breadcrumbs.count)
            self.updateBreadcrumbViews()
            self.delegate?.breadcrumbNavigation(self, didSelectNode: targetNode)
        }
    }
    
    private func animateNewBreadcrumb(_ node: NavigationNode) {
        let crumbView = createBreadcrumbView(for: node, at: breadcrumbs.count - 1)
        crumbView.alphaValue = 0
        crumbView.layer?.transform = CATransform3DMakeScale(0.8, 0.8, 1)
        
        containerView.addArrangedSubview(crumbView)
        crumbViews.append(crumbView)
        
        if breadcrumbs.count > 1 {
            let separator = createSeparatorView()
            separator.alphaValue = 0
            containerView.insertArrangedSubview(separator, at: containerView.arrangedSubviews.count - 1)
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            
            crumbView.animator().alphaValue = 1
            crumbView.layer?.transform = CATransform3DIdentity
            
            if let separator = containerView.arrangedSubviews.dropLast().last {
                separator.animator().alphaValue = 1
            }
            
            scrollToEnd()
        }
    }
    
    private func animatePopTransition(to index: Int, completion: @escaping () -> Void) {
        guard !isAnimating else { return }
        isAnimating = true
        
        let viewsToRemove = Array(crumbViews[(index + 1)...])
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            for view in viewsToRemove {
                view.animator().alphaValue = 0
                view.layer?.transform = CATransform3DMakeScale(0.9, 0.9, 1)
            }
        }) {
            viewsToRemove.forEach { $0.removeFromSuperview() }
            self.crumbViews.removeSubrange((index + 1)..<self.crumbViews.count)
            self.isAnimating = false
            completion()
        }
    }
    
    private func createBreadcrumbView(for node: NavigationNode, at index: Int) -> BreadcrumbItemView {
        let itemView = BreadcrumbItemView(node: node, index: index)
        itemView.delegate = self
        return itemView
    }
    
    private func createSeparatorView() -> NSView {
        let separator = NSImageView()
        separator.image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: nil)
        separator.contentTintColor = NSColor.tertiaryLabelColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            separator.widthAnchor.constraint(equalToConstant: 16),
            separator.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        return separator
    }
    
    private func updateBreadcrumbViews() {
        containerView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        crumbViews.removeAll()
        
        for (index, node) in breadcrumbs.enumerated() {
            if index > 0 {
                containerView.addArrangedSubview(createSeparatorView())
            }
            
            let crumbView = createBreadcrumbView(for: node, at: index)
            containerView.addArrangedSubview(crumbView)
            crumbViews.append(crumbView)
        }
    }
    
    private func updateBreadcrumbVisibility() {
        if breadcrumbs.count > maxVisibleCrumbs {
            let startIndex = breadcrumbs.count - maxVisibleCrumbs
            
            for (index, view) in crumbViews.enumerated() {
                let shouldShow = index >= startIndex
                
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    view.animator().alphaValue = shouldShow ? 1 : 0.3
                    view.layer?.transform = shouldShow ?
                        CATransform3DIdentity :
                        CATransform3DMakeScale(0.9, 0.9, 1)
                }
            }
        }
    }
    
    private func scrollToEnd() {
        guard let documentView = scrollView.documentView else { return }
        
        let maxX = documentView.frame.maxX - scrollView.frame.width
        let targetPoint = NSPoint(x: max(0, maxX), y: 0)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            scrollView.contentView.animator().setBoundsOrigin(targetPoint)
        }
    }
}

class BreadcrumbItemView: NSView {
    let node: BreadcrumbNavigationView.NavigationNode
    let index: Int
    weak var delegate: BreadcrumbItemViewDelegate?
    
    private var titleLabel: NSTextField!
    private var iconView: NSImageView?
    private var hoverLayer: CALayer!
    private var isHovering = false
    
    init(node: BreadcrumbNavigationView.NavigationNode, index: Int) {
        self.node = node
        self.index = index
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = 6
        
        hoverLayer = CALayer()
        hoverLayer.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.1).cgColor
        hoverLayer.cornerRadius = 6
        hoverLayer.opacity = 0
        layer?.addSublayer(hoverLayer)
        
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        if let iconName = node.icon {
            iconView = NSImageView()
            iconView?.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
            iconView?.contentTintColor = node.isCurrentLocation ? 
                NSColor.controlAccentColor : NSColor.secondaryLabelColor
            stackView.addArrangedSubview(iconView!)
        }
        
        titleLabel = NSTextField(labelWithString: node.title)
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: node.isCurrentLocation ? .semibold : .regular)
        titleLabel.textColor = node.isCurrentLocation ? 
            NSColor.controlAccentColor : NSColor.labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        stackView.addArrangedSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
        
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        addGestureRecognizer(clickGesture)
        
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        guard !node.isCurrentLocation else { return }
        
        isHovering = true
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.15)
        hoverLayer.opacity = 1
        CATransaction.commit()
        
        NSCursor.pointingHand.push()
        
        showPreviewPopover()
    }
    
    override func mouseExited(with event: NSEvent) {
        isHovering = false
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.15)
        hoverLayer.opacity = 0
        CATransaction.commit()
        
        NSCursor.pop()
        
        hidePreviewPopover()
    }
    
    override func updateLayer() {
        super.updateLayer()
        hoverLayer.frame = bounds
    }
    
    @objc private func handleClick() {
        guard !node.isCurrentLocation else { return }
        
        let feedbackGenerator = NSHapticFeedbackManager.defaultPerformer
        feedbackGenerator.perform(.generic, performanceTime: .default)
        
        delegate?.breadcrumbItemView(self, didSelectItemAt: index)
    }
    
    private func showPreviewPopover() {
        // Show document preview on hover
    }
    
    private func hidePreviewPopover() {
        // Hide preview
    }
}

protocol BreadcrumbNavigationDelegate: AnyObject {
    func breadcrumbNavigation(_ navigation: BreadcrumbNavigationView, didSelectNode node: BreadcrumbNavigationView.NavigationNode)
}

protocol BreadcrumbItemViewDelegate: AnyObject {
    func breadcrumbItemView(_ view: BreadcrumbItemView, didSelectItemAt index: Int)
}

extension BreadcrumbNavigationView: BreadcrumbItemViewDelegate {
    func breadcrumbItemView(_ view: BreadcrumbItemView, didSelectItemAt index: Int) {
        popToLocation(at: index)
    }
}