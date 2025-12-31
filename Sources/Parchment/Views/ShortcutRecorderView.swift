import Cocoa

/// Protocol for shortcut recorder delegate
protocol ShortcutRecorderViewDelegate: AnyObject {
    func shortcutRecorderView(_ view: ShortcutRecorderView, didRecordShortcut shortcut: KeyboardShortcut)
    func shortcutRecorderViewDidClear(_ view: ShortcutRecorderView)
}

/// A view that records keyboard shortcuts from user input
final class ShortcutRecorderView: NSView {

    // MARK: - Properties

    weak var delegate: ShortcutRecorderViewDelegate?

    private(set) var currentShortcut: KeyboardShortcut?
    private var isRecording = false

    private let textField: NSTextField
    private let clearButton: NSButton

    private var trackingArea: NSTrackingArea?

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        textField = NSTextField()
        clearButton = NSButton()
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        textField = NSTextField()
        clearButton = NSButton()
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Setup

    private func setupViews() {
        wantsLayer = true
        layer?.cornerRadius = 4
        layer?.borderWidth = 1
        updateAppearance()

        // Text field for displaying shortcut
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.alignment = .center
        textField.font = .systemFont(ofSize: 12)
        textField.textColor = .secondaryLabelColor
        textField.stringValue = "Click to record"
        addSubview(textField)

        // Clear button
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.bezelStyle = .inline
        clearButton.isBordered = false
        clearButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Clear")
        clearButton.imagePosition = .imageOnly
        clearButton.target = self
        clearButton.action = #selector(clearShortcut)
        clearButton.isHidden = true
        addSubview(clearButton)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -4),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),

            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 16),
            clearButton.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    // MARK: - Public Interface

    func setShortcut(_ shortcut: KeyboardShortcut?) {
        currentShortcut = shortcut
        updateDisplay()
    }

    // MARK: - View Lifecycle

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let existingArea = trackingArea {
            removeTrackingArea(existingArea)
        }

        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        startRecording()
        return true
    }

    override func resignFirstResponder() -> Bool {
        stopRecording()
        return true
    }

    // MARK: - Mouse Handling

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func mouseEntered(with event: NSEvent) {
        if currentShortcut != nil && !isRecording {
            clearButton.isHidden = false
        }
    }

    override func mouseExited(with event: NSEvent) {
        clearButton.isHidden = true
    }

    // MARK: - Keyboard Handling

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        // Escape cancels recording
        if event.keyCode == 53 {
            stopRecording()
            return
        }

        // Delete/Backspace clears the shortcut
        if event.keyCode == 51 {
            clearShortcut()
            stopRecording()
            return
        }

        // Ignore modifier-only keypresses
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if isModifierOnlyKeyCode(event.keyCode) {
            return
        }

        // Require at least Command or Control modifier
        guard modifiers.contains(.command) || modifiers.contains(.control) else {
            NSSound.beep()
            return
        }

        // Create the shortcut
        let shortcut = KeyboardShortcut(
            keyCode: event.keyCode,
            modifierFlags: modifiers.rawValue,
            action: currentShortcut?.action ?? ""
        )

        currentShortcut = shortcut
        updateDisplay()
        stopRecording()

        delegate?.shortcutRecorderView(self, didRecordShortcut: shortcut)
    }

    override func flagsChanged(with event: NSEvent) {
        // Could show modifier preview here if desired
    }

    // MARK: - Actions

    @objc private func clearShortcut() {
        currentShortcut = nil
        updateDisplay()
        delegate?.shortcutRecorderViewDidClear(self)
    }

    // MARK: - Private Methods

    private func startRecording() {
        isRecording = true
        textField.stringValue = "Type shortcut..."
        textField.textColor = .labelColor
        updateAppearance()
    }

    private func stopRecording() {
        isRecording = false
        updateDisplay()
        updateAppearance()
    }

    private func updateDisplay() {
        if let shortcut = currentShortcut {
            textField.stringValue = shortcut.displayString
            textField.textColor = .labelColor
            textField.font = .systemFont(ofSize: 13, weight: .medium)
        } else {
            textField.stringValue = "Click to record"
            textField.textColor = .secondaryLabelColor
            textField.font = .systemFont(ofSize: 12)
        }
        clearButton.isHidden = currentShortcut == nil || !isMouseInBounds()
    }

    private func updateAppearance() {
        if isRecording {
            layer?.borderColor = NSColor.controlAccentColor.cgColor
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.1).cgColor
        } else {
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }
    }

    private func isMouseInBounds() -> Bool {
        guard let window = window else { return false }
        let mouseLocation = window.mouseLocationOutsideOfEventStream
        let localPoint = convert(mouseLocation, from: nil)
        return bounds.contains(localPoint)
    }

    private func isModifierOnlyKeyCode(_ keyCode: UInt16) -> Bool {
        // Modifier key codes
        let modifierKeyCodes: Set<UInt16> = [
            54,  // Right Command
            55,  // Left Command
            56,  // Left Shift
            57,  // Caps Lock
            58,  // Left Option
            59,  // Left Control
            60,  // Right Shift
            61,  // Right Option
            62,  // Right Control
            63   // Function
        ]
        return modifierKeyCodes.contains(keyCode)
    }
}
