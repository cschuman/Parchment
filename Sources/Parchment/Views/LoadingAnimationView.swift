import Cocoa

/// A subtle loading animation view shown while documents are being parsed
final class LoadingAnimationView: NSView {

    // MARK: - Properties

    private var progressIndicator: NSProgressIndicator!
    private var messageLabel: NSTextField!
    private var currentTheme: ParchmentTheme = ParchmentTheme.current

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = currentTheme.backgroundColor.cgColor

        // Container for centered content
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        // Spinning progress indicator
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .spinning
        progressIndicator.controlSize = .regular
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressIndicator.isIndeterminate = true
        containerView.addSubview(progressIndicator)

        // Loading message
        messageLabel = NSTextField(labelWithString: "Loading...")
        messageLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        messageLabel.textColor = currentTheme.textColor.withAlphaComponent(0.6)
        messageLabel.alignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            // Center container
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 200),
            containerView.heightAnchor.constraint(equalToConstant: 80),

            // Progress indicator
            progressIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            progressIndicator.topAnchor.constraint(equalTo: containerView.topAnchor),

            // Message label
            messageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])

        // Initially hidden
        alphaValue = 0
        isHidden = true
    }

    // MARK: - Public Interface

    /// Show the loading animation with optional message
    func show(message: String = "Loading...") {
        messageLabel.stringValue = message
        isHidden = false
        progressIndicator.startAnimation(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1
        }
    }

    /// Hide the loading animation with fade out
    func hide(completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.progressIndicator.stopAnimation(nil)
            self?.isHidden = true
            completion?()
        })
    }

    /// Update the loading message
    func updateMessage(_ message: String) {
        messageLabel.stringValue = message
    }

    // MARK: - Theme Support

    func applyTheme(_ theme: ParchmentTheme, animated: Bool = true) {
        currentTheme = theme

        let applyColors = { [weak self] in
            self?.layer?.backgroundColor = theme.backgroundColor.cgColor
            self?.messageLabel.textColor = theme.textColor.withAlphaComponent(0.6)
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true
                applyColors()
            }
        } else {
            applyColors()
        }
    }
}
