import Cocoa
import Foundation

final class StatusBarView: NSView, ThemeApplicable {
    private var fileLabel: NSTextField!
    private var wordCountLabel: NSTextField!
    private var readingTimeLabel: NSTextField!
    private var progressLabel: NSTextField!

    // Reading metrics
    private var currentFileName: String = ""
    private var wordCount: Int = 0
    private var scrollProgress: Double = 0

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
        layer?.backgroundColor = NSColor(white: 0.95, alpha: 1.0).cgColor

        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.edgeInsets = NSEdgeInsets(top: 2, left: 12, bottom: 2, right: 12)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // File name
        fileLabel = createLabel(accessibilityLabel: "Document name")
        fileLabel.stringValue = "No document"
        stackView.addArrangedSubview(fileLabel)

        // Spacer to push metrics to right
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(spacer)

        // Word count
        wordCountLabel = createLabel(accessibilityLabel: "Word count")
        wordCountLabel.stringValue = ""
        stackView.addArrangedSubview(wordCountLabel)

        // Reading time
        readingTimeLabel = createLabel(accessibilityLabel: "Estimated reading time")
        readingTimeLabel.stringValue = ""
        stackView.addArrangedSubview(readingTimeLabel)

        // Progress
        progressLabel = createLabel(accessibilityLabel: "Reading progress")
        progressLabel.stringValue = ""
        stackView.addArrangedSubview(progressLabel)

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    private func createLabel(accessibilityLabel: String? = nil) -> NSTextField {
        let label = NSTextField()
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        label.textColor = NSColor.secondaryLabelColor
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        label.setAccessibilityElement(true)
        label.setAccessibilityRole(.staticText)
        if let accessibilityLabel = accessibilityLabel {
            label.setAccessibilityLabel(accessibilityLabel)
        }

        return label
    }

    // MARK: - Theme Support

    func applyTheme(_ theme: ParchmentTheme) {
        layer?.backgroundColor = theme.backgroundColor.withAlphaComponent(0.95).cgColor
        let textColor = theme.textColor.withAlphaComponent(0.6)
        fileLabel?.textColor = textColor
        wordCountLabel?.textColor = textColor
        readingTimeLabel?.textColor = textColor
        progressLabel?.textColor = textColor
    }

    // MARK: - Public Methods

    func updateFileInfo(path: String, size: Int64, lines: Int, words: Int) {
        currentFileName = URL(fileURLWithPath: path).lastPathComponent
        wordCount = words
        updateDisplay()
    }

    func updateScrollProgress(_ progress: Double) {
        scrollProgress = min(max(progress, 0), 1)
        updateProgressDisplay()
    }

    // MARK: - Private Methods

    private func updateDisplay() {
        fileLabel.stringValue = currentFileName.isEmpty ? "No document" : currentFileName

        if wordCount > 0 {
            wordCountLabel.stringValue = "\(formatNumber(wordCount)) words"

            // Calculate reading time at 200 WPM
            let minutes = Double(wordCount) / 200.0
            if minutes < 1 {
                readingTimeLabel.stringValue = "<1 min read"
            } else {
                readingTimeLabel.stringValue = "~\(Int(ceil(minutes))) min read"
            }
        } else {
            wordCountLabel.stringValue = ""
            readingTimeLabel.stringValue = ""
        }

        updateProgressDisplay()
    }

    private func updateProgressDisplay() {
        if wordCount > 0 {
            let percent = Int(scrollProgress * 100)
            progressLabel.stringValue = "\(percent)%"
        } else {
            progressLabel.stringValue = ""
        }
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    // MARK: - Deprecated methods (kept for compatibility during transition)

    func updateParseTime(_ time: TimeInterval) {
        // No longer displayed
    }

    func updateRenderTime(_ time: TimeInterval) {
        // No longer displayed
    }

    func updateDrawTime(_ time: TimeInterval) {
        // No longer displayed
    }

    func updateCacheHitRate(_ rate: Double) {
        // No longer displayed
    }
}
