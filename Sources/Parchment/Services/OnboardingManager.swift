import Cocoa

/// Manages contextual onboarding tooltips for progressive feature discovery
final class OnboardingManager {

    // MARK: - Singleton

    static let shared = OnboardingManager()

    // MARK: - Types

    enum Tip: String, CaseIterable {
        case tocNavigation = "toc_navigation"
        case focusMode = "focus_mode"
        case autoTheme = "auto_theme"
        case readingPosition = "reading_position"

        var message: String {
            switch self {
            case .tocNavigation:
                return "Tip: Use Cmd+[ and Cmd+] to navigate between headers"
            case .focusMode:
                return "Focus Mode: Current paragraph is highlighted. Press Esc to exit."
            case .autoTheme:
                return "Tip: Enable 'Follow System Appearance' in the Theme menu for auto dark mode"
            case .readingPosition:
                return "Tip: Your reading position is saved automatically"
            }
        }
    }

    // MARK: - Properties

    private let userDefaultsPrefix = "onboarding_tip_shown_"
    private let documentCountKey = "onboarding_document_count"
    private weak var currentTooltip: OnboardingTooltipWindow?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Interface

    /// Check if a tip should be shown
    func shouldShow(_ tip: Tip) -> Bool {
        !UserDefaults.standard.bool(forKey: userDefaultsPrefix + tip.rawValue)
    }

    /// Mark a tip as shown
    func markShown(_ tip: Tip) {
        UserDefaults.standard.set(true, forKey: userDefaultsPrefix + tip.rawValue)
    }

    /// Increment document open count and check for reading position tip
    func documentOpened() {
        let count = UserDefaults.standard.integer(forKey: documentCountKey) + 1
        UserDefaults.standard.set(count, forKey: documentCountKey)

        // Show reading position tip after 3rd document
        if count == 3 && shouldShow(.readingPosition) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.showTip(.readingPosition, near: nil)
            }
        }
    }

    /// Show a tooltip near a specific view or centered if no anchor
    func showTip(_ tip: Tip, near anchorView: NSView?) {
        guard shouldShow(tip) else { return }

        // Dismiss any existing tooltip
        currentTooltip?.close()

        let tooltip = OnboardingTooltipWindow(tip: tip, theme: ParchmentTheme.current)
        tooltip.onDismiss = { [weak self] in
            self?.markShown(tip)
            self?.currentTooltip = nil
        }

        // Position near anchor or center of screen
        if let anchor = anchorView, let window = anchor.window {
            let anchorRect = anchor.convert(anchor.bounds, to: nil)
            let screenRect = window.convertToScreen(anchorRect)
            tooltip.position(near: screenRect)
        } else {
            tooltip.centerOnMainScreen()
        }

        tooltip.makeKeyAndOrderFront(nil)
        currentTooltip = tooltip

        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak tooltip] in
            tooltip?.animateClose()
        }
    }

    /// Reset all tips (for testing)
    func resetAllTips() {
        for tip in Tip.allCases {
            UserDefaults.standard.removeObject(forKey: userDefaultsPrefix + tip.rawValue)
        }
        UserDefaults.standard.removeObject(forKey: documentCountKey)
    }
}

// MARK: - Tooltip Window

final class OnboardingTooltipWindow: NSWindow {

    var onDismiss: (() -> Void)?
    private let tip: OnboardingManager.Tip

    init(tip: OnboardingManager.Tip, theme: ParchmentTheme) {
        self.tip = tip

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .floating
        self.hasShadow = true
        self.isReleasedWhenClosed = false

        setupContent(theme: theme)
    }

    private func setupContent(theme: ParchmentTheme) {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 8
        containerView.layer?.backgroundColor = theme.backgroundColor.cgColor
        containerView.layer?.borderWidth = 1
        containerView.layer?.borderColor = theme.textColor.withAlphaComponent(0.2).cgColor

        // Add drop shadow
        containerView.layer?.shadowColor = NSColor.black.cgColor
        containerView.layer?.shadowOpacity = 0.2
        containerView.layer?.shadowRadius = 8
        containerView.layer?.shadowOffset = NSSize(width: 0, height: -2)

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        stackView.edgeInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        // Message label
        let messageLabel = NSTextField(wrappingLabelWithString: tip.message)
        messageLabel.font = NSFont.systemFont(ofSize: 13)
        messageLabel.textColor = theme.textColor
        messageLabel.isEditable = false
        messageLabel.isBordered = false
        messageLabel.backgroundColor = .clear
        messageLabel.preferredMaxLayoutWidth = 280

        stackView.addArrangedSubview(messageLabel)

        // Dismiss button
        let dismissButton = NSButton(title: "Got it", target: self, action: #selector(dismissClicked))
        dismissButton.bezelStyle = .inline
        dismissButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        stackView.addArrangedSubview(dismissButton)

        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        contentView = containerView

        // Set initial alpha for fade-in
        containerView.alphaValue = 0

        // Fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            containerView.animator().alphaValue = 1
        }
    }

    func position(near rect: NSRect) {
        // Position above the anchor with some offset
        let tooltipSize = frame.size
        let x = rect.midX - tooltipSize.width / 2
        let y = rect.maxY + 10

        setFrameOrigin(NSPoint(x: x, y: y))
    }

    func centerOnMainScreen() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - frame.width / 2
            let y = screenFrame.midY - frame.height / 2 + 100 // Slightly above center
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    @objc private func dismissClicked() {
        animateClose()
    }

    func animateClose() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            contentView?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.onDismiss?()
            self?.close()
        })
    }

    override func mouseDown(with event: NSEvent) {
        // Don't dismiss on click inside - only via button
    }
}
