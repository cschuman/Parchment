import Cocoa

/// A tooltip that shows link URL on hover
final class LinkPreviewTooltip: NSWindow {

    // MARK: - Properties

    private let contentLabel: NSTextField
    private var theme: ParchmentTheme

    // MARK: - Initialization

    init(theme: ParchmentTheme) {
        self.theme = theme

        contentLabel = NSTextField(labelWithString: "")
        contentLabel.font = NSFont.systemFont(ofSize: 11)
        contentLabel.lineBreakMode = .byTruncatingMiddle
        contentLabel.maximumNumberOfLines = 1
        contentLabel.translatesAutoresizingMaskIntoConstraints = false

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 28),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.hasShadow = true
        self.isReleasedWhenClosed = false

        setupContent()
    }

    // MARK: - Setup

    private func setupContent() {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 4
        containerView.layer?.backgroundColor = theme.backgroundColor.cgColor
        containerView.layer?.borderWidth = 1
        containerView.layer?.borderColor = theme.textColor.withAlphaComponent(0.15).cgColor

        // Shadow
        containerView.layer?.shadowColor = NSColor.black.cgColor
        containerView.layer?.shadowOpacity = 0.15
        containerView.layer?.shadowRadius = 4
        containerView.layer?.shadowOffset = NSSize(width: 0, height: -1)

        contentLabel.textColor = theme.textColor.withAlphaComponent(0.8)

        containerView.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            contentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            contentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            contentLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        contentView = containerView
        contentView?.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Public Interface

    /// Show the tooltip with a URL near the specified point
    func show(url: URL, near point: NSPoint, in view: NSView) {
        // Format the URL for display
        var displayURL = url.absoluteString
        if displayURL.count > 60 {
            displayURL = String(displayURL.prefix(30)) + "..." + String(displayURL.suffix(27))
        }

        contentLabel.stringValue = displayURL

        // Calculate required width
        let textWidth = contentLabel.intrinsicContentSize.width
        let tooltipWidth = min(max(textWidth + 16, 100), 400)

        // Position the tooltip below the cursor
        guard let window = view.window else { return }
        let screenPoint = window.convertPoint(toScreen: view.convert(point, to: nil))
        let tooltipOrigin = NSPoint(x: screenPoint.x - tooltipWidth / 2, y: screenPoint.y - 32)

        setFrame(NSRect(origin: tooltipOrigin, size: NSSize(width: tooltipWidth, height: 28)), display: true)
        contentView?.frame = NSRect(origin: .zero, size: frame.size)

        // Fade in
        alphaValue = 0
        orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            animator().alphaValue = 1
        }
    }

    /// Hide the tooltip with fade out
    func hide() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
        })
    }

    /// Update theme colors
    func applyTheme(_ theme: ParchmentTheme) {
        self.theme = theme
        contentView?.layer?.backgroundColor = theme.backgroundColor.cgColor
        contentView?.layer?.borderColor = theme.textColor.withAlphaComponent(0.15).cgColor
        contentLabel.textColor = theme.textColor.withAlphaComponent(0.8)
    }
}
