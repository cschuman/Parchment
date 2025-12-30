import Cocoa

// MARK: - Simple Theme Support
extension MarkdownViewController {
    
    func setupEnhancedFeatures() {
        // Setup dark mode support
        observeAppearanceChanges()
    }
    
    private func observeAppearanceChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appearanceDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    @objc private func appearanceDidChange() {
        updateTextViewAppearance()
    }
    
    func updateTextViewAppearance() {
        if NSApp.effectiveAppearance.name == .darkAqua {
            textView.backgroundColor = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
            textView.textColor = NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        } else {
            textView.backgroundColor = NSColor.textBackgroundColor
            textView.textColor = NSColor.labelColor
        }
    }
    
    // MARK: - Simple Reading Modes
    
    func applyLightMode() {
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.labelColor
        scrollView.backgroundColor = NSColor.controlBackgroundColor
    }
    
    func applyDarkMode() {
        textView.backgroundColor = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)
        textView.textColor = NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        scrollView.backgroundColor = NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.1, alpha: 1.0)
    }
    
    // MARK: - Focus Mode (Simple Implementation)
    
    var focusModeEnabled: Bool {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.focusModeEnabled) as? Bool ?? false }
        set { objc_setAssociatedObject(self, &AssociatedKeys.focusModeEnabled, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    func toggleFocusMode() {
        focusModeEnabled = !focusModeEnabled

        if focusModeEnabled {
            // Enable typewriter scrolling for focused reading
            enableTypewriterScrolling()

            // Hide distractions
            NSApp.presentationOptions = [.autoHideDock, .autoHideMenuBar]
            view.window?.toggleFullScreen(nil)

            // Show first-use tooltip
            showFocusModeTooltipIfNeeded()
        } else {
            // Disable typewriter scrolling
            disableTypewriterScrolling()

            // Restore normal view
            NSApp.presentationOptions = []
            if view.window?.styleMask.contains(.fullScreen) == true {
                view.window?.toggleFullScreen(nil)
            }
        }
    }

    private func showFocusModeTooltipIfNeeded() {
        let key = "hasSeenFocusModeTooltip"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        UserDefaults.standard.set(true, forKey: key)

        // Show tooltip notification
        let notification = NSTextField(labelWithString: "Focus Mode: Distractions hidden, typewriter scrolling enabled. Press ⇧⌘F or Esc to exit.")
        notification.font = NSFont.systemFont(ofSize: 13)
        notification.textColor = .white
        notification.backgroundColor = NSColor.black.withAlphaComponent(0.8)
        notification.isBezeled = false
        notification.drawsBackground = true
        notification.alignment = .center
        notification.wantsLayer = true
        notification.layer?.cornerRadius = 8

        notification.frame = NSRect(x: 0, y: 0, width: 500, height: 40)
        notification.sizeToFit()
        notification.frame.size.width += 32
        notification.frame.size.height += 16

        // Center in view
        let viewBounds = view.bounds
        notification.frame.origin.x = (viewBounds.width - notification.frame.width) / 2
        notification.frame.origin.y = viewBounds.height - notification.frame.height - 100

        notification.alphaValue = 0
        view.addSubview(notification)

        // Fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            notification.animator().alphaValue = 1.0
        }

        // Fade out after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                notification.animator().alphaValue = 0
            }, completionHandler: {
                notification.removeFromSuperview()
            })
        }
    }
}

// MARK: - Associated Keys
private struct AssociatedKeys {
    static var focusModeEnabled = "focusModeEnabled"
}