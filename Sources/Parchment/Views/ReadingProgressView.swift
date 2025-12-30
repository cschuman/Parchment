import Cocoa

/// A subtle vertical progress indicator showing reading position
final class ReadingProgressView: NSView {

    // MARK: - Properties

    private var progress: CGFloat = 0
    private var fadeTimer: Timer?
    private var theme: ParchmentTheme = ParchmentTheme.current

    private let trackWidth: CGFloat = 2
    private let trackInset: CGFloat = 4
    private let cornerRadius: CGFloat = 1

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
        layer?.backgroundColor = NSColor.clear.cgColor
        alphaValue = 0  // Start hidden
    }

    // MARK: - Public Interface

    /// Update progress (0.0 to 1.0)
    func updateProgress(_ value: CGFloat) {
        let clampedProgress = max(0, min(1, value))

        // Only update if changed significantly
        guard abs(clampedProgress - progress) > 0.001 else { return }

        progress = clampedProgress
        needsDisplay = true

        // Show the indicator
        showIndicator()

        // Schedule fade out
        scheduleFadeOut()
    }

    /// Apply theme colors
    func applyTheme(_ theme: ParchmentTheme) {
        self.theme = theme
        needsDisplay = true
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let trackRect = NSRect(
            x: bounds.width - trackWidth - trackInset,
            y: trackInset,
            width: trackWidth,
            height: bounds.height - (trackInset * 2)
        )

        // Draw track background (very subtle)
        let trackColor = theme.textColor.withAlphaComponent(0.1)
        context.setFillColor(trackColor.cgColor)
        let trackPath = NSBezierPath(roundedRect: trackRect, xRadius: cornerRadius, yRadius: cornerRadius)
        trackPath.fill()

        // Draw progress fill
        let fillHeight = trackRect.height * progress
        let fillRect = NSRect(
            x: trackRect.origin.x,
            y: trackRect.origin.y + trackRect.height - fillHeight,
            width: trackRect.width,
            height: fillHeight
        )

        let fillColor = theme.linkColor.withAlphaComponent(0.4)
        context.setFillColor(fillColor.cgColor)
        let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: cornerRadius, yRadius: cornerRadius)
        fillPath.fill()
    }

    // MARK: - Animation

    private func showIndicator() {
        guard alphaValue < 1 else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            animator().alphaValue = 1
        }
    }

    private func scheduleFadeOut() {
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.fadeOut()
        }
    }

    private func fadeOut() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            animator().alphaValue = 0
        }
    }
}
