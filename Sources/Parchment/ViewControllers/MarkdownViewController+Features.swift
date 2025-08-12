import Cocoa

// MARK: - Associated Keys for Features
private struct AssociatedKeys {
    static var typographyEngine = "typographyEngine"
    static var focusMode = "focusMode"
    static var floatingTOC = "floatingTOC"
    static var fuzzySearch = "fuzzySearch"
    static var performanceOverlay = "performanceOverlay"
    static var progressTracker = "progressTracker"
    static var progressiveRenderer = "progressiveRenderer"
    static var optimizedImageLoader = "optimizedImageLoader"
    static var originalAttributedString = "originalAttributedString"
}

extension MarkdownViewController {
    
    // MARK: - Feature Integration
    
    func setupEnhancedFeatures() {
        setupPerformanceMonitoring()
        setupTypographyEngine()
        setupEnhancedFocusMode()
        setupFloatingTOC()
        setupFuzzySearch()
        setupProgressTracking()
        setupProgressiveRendering()
    }
    
    // MARK: - Performance Monitoring
    
    private func setupPerformanceMonitoring() {
        // Add performance overlay
        let performanceOverlay = PerformanceOverlayView(frame: NSRect(x: 10, y: 10, width: 200, height: 100))
        performanceOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(performanceOverlay)
        
        NSLayoutConstraint.activate([
            performanceOverlay.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            performanceOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            performanceOverlay.widthAnchor.constraint(equalToConstant: 200),
            performanceOverlay.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        performanceOverlay.alphaValue = 0.8
        
        // Start monitoring
        PerformanceMonitor.shared.addMetricsCallback { metrics in
            DispatchQueue.main.async {
                print("FPS: \(metrics.fps), Frame Time: \(metrics.frameTime)ms")
            }
        }
    }
    
    // MARK: - Typography Engine
    
    private func setupTypographyEngine() {
        let typographyEngine = AdaptiveTypographyEngine()
        objc_setAssociatedObject(self, &AssociatedKeys.typographyEngine, typographyEngine, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func applyTypographyMode(_ mode: AdaptiveTypographyEngine.ReadingMode) {
        guard let textStorage = textView.textStorage else { return }
        
        // Show mode indicator
        showModeIndicator(for: mode)
        
        // Get or store original
        var originalAttributedString = objc_getAssociatedObject(self, &AssociatedKeys.originalAttributedString) as? NSAttributedString
        
        // Store original if this is the first mode change
        if originalAttributedString == nil && mode != .normal {
            originalAttributedString = NSAttributedString(attributedString: textStorage)
            objc_setAssociatedObject(self, &AssociatedKeys.originalAttributedString, originalAttributedString, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        // If switching back to normal, restore original
        if mode == .normal {
            if let original = originalAttributedString {
                textStorage.setAttributedString(original)
            }
            textView.backgroundColor = NSColor.textBackgroundColor
            textView.needsDisplay = true
            // Clear the stored original
            objc_setAssociatedObject(self, &AssociatedKeys.originalAttributedString, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        
        // Store current mode
        UserDefaults.standard.set(mode.rawValue, forKey: "CurrentTypographyMode")
        
        // Start from original if we have it, otherwise current
        if let original = originalAttributedString {
            textStorage.setAttributedString(original)
        }
        
        // Apply mode-specific modifications
        textStorage.beginEditing()
        
        textStorage.enumerateAttributes(in: NSRange(location: 0, length: textStorage.length), options: []) { attributes, range, _ in
            var updatedAttributes = attributes
            
            // Get the current font and preserve its traits (bold, italic, etc.)
            let currentFont = attributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 14)
            let fontDescriptor = currentFont.fontDescriptor
            let symbolicTraits = fontDescriptor.symbolicTraits
            
            switch mode {
            case .normal:
                // Reset to default sizes but preserve traits
                let baseSize: CGFloat = currentFont.pointSize > 20 ? 24 : (currentFont.pointSize > 16 ? 18 : 14)
                updatedAttributes[.font] = NSFont.systemFont(ofSize: baseSize, weight: symbolicTraits.contains(.bold) ? .bold : .regular)
                updatedAttributes[.foregroundColor] = NSColor.labelColor
                textView.backgroundColor = NSColor.textBackgroundColor
                
            case .focus:
                let newSize = currentFont.pointSize * 1.15
                updatedAttributes[.font] = NSFont.systemFont(ofSize: newSize, weight: symbolicTraits.contains(.bold) ? .bold : .medium)
                if let paragraphStyle = updatedAttributes[.paragraphStyle] as? NSMutableParagraphStyle {
                    paragraphStyle.lineSpacing = 8
                } else {
                    updatedAttributes[.paragraphStyle] = createParagraphStyle(lineSpacing: 8)
                }
                
            case .speed:
                let newSize = currentFont.pointSize * 1.3
                updatedAttributes[.font] = NSFont.systemFont(ofSize: newSize, weight: .semibold)
                if let paragraphStyle = updatedAttributes[.paragraphStyle] as? NSMutableParagraphStyle {
                    paragraphStyle.lineSpacing = 12
                } else {
                    updatedAttributes[.paragraphStyle] = createParagraphStyle(lineSpacing: 12)
                }
                
            case .night:
                let newSize = currentFont.pointSize * 1.1
                updatedAttributes[.font] = NSFont.systemFont(ofSize: newSize, weight: symbolicTraits.contains(.bold) ? .bold : .regular)
                // Adjust colors for night mode
                if let _ = updatedAttributes[.link] {
                    updatedAttributes[.foregroundColor] = NSColor(calibratedRed: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
                } else {
                    updatedAttributes[.foregroundColor] = NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.85, alpha: 1.0)
                }
                textView.backgroundColor = NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.1, alpha: 1.0)
                
            case .paper:
                let newSize = currentFont.pointSize * 1.05
                let paperFont = NSFont(name: "Georgia", size: newSize) ?? NSFont.systemFont(ofSize: newSize)
                updatedAttributes[.font] = paperFont
                // Sepia tone colors
                if let _ = updatedAttributes[.link] {
                    updatedAttributes[.foregroundColor] = NSColor(calibratedRed: 0.4, green: 0.2, blue: 0.1, alpha: 1.0)
                } else {
                    updatedAttributes[.foregroundColor] = NSColor(calibratedRed: 0.2, green: 0.15, blue: 0.1, alpha: 1.0)
                }
                textView.backgroundColor = NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
                
            case .bionic:
                // Keep existing font but we'll apply bionic reading separately
                break
                
            case .dyslexic:
                let newSize = currentFont.pointSize * 1.2
                // Use OpenDyslexic font - try different name variations
                let dyslexicFont = NSFont(name: "OpenDyslexic-Regular", size: newSize) ??
                                  NSFont(name: "OpenDyslexic", size: newSize) ??
                                  NSFont(name: "opendyslexic", size: newSize) ??
                                  NSFont.systemFont(ofSize: newSize)
                updatedAttributes[.font] = dyslexicFont
                if let paragraphStyle = updatedAttributes[.paragraphStyle] as? NSMutableParagraphStyle {
                    paragraphStyle.lineSpacing = 10
                } else {
                    updatedAttributes[.paragraphStyle] = createParagraphStyle(lineSpacing: 10)
                }
                // High contrast colors for dyslexic mode
                if let _ = updatedAttributes[.link] {
                    updatedAttributes[.foregroundColor] = NSColor(calibratedRed: 0.0, green: 0.3, blue: 0.8, alpha: 1.0)
                } else {
                    updatedAttributes[.foregroundColor] = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.3, alpha: 1.0)
                }
                textView.backgroundColor = NSColor(calibratedRed: 1.0, green: 0.98, blue: 0.9, alpha: 1.0)
            }
            
            textStorage.setAttributes(updatedAttributes, range: range)
        }
        
        if mode == .bionic {
            applyBionicReading(to: textStorage)
        }
        
        textStorage.endEditing()
        textView.needsDisplay = true
    }
    
    private func createParagraphStyle(lineSpacing: CGFloat) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = lineSpacing * 1.5
        return style
    }
    
    private func applyBionicReading(to textStorage: NSTextStorage) {
        // Bionic Reading: A technique that bolds the first part of each word
        // to create "artificial fixation points" that help the brain process text faster
        // Research suggests it can improve reading speed and comprehension
        
        let text = textStorage.string
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var location = 0
        
        for word in words {
            if !word.isEmpty {
                let wordRange = (text as NSString).range(of: word, options: [], range: NSRange(location: location, length: text.count - location))
                if wordRange.location != NSNotFound {
                    // Bold approximately 40-50% of each word for optimal effect
                    let boldLength = max(1, Int(Double(word.count) * 0.45))
                    let boldRange = NSRange(location: wordRange.location, length: boldLength)
                    
                    // Get existing font and make it bold
                    if let existingFont = textStorage.attribute(.font, at: wordRange.location, effectiveRange: nil) as? NSFont {
                        let boldFont = NSFontManager.shared.convert(existingFont, toHaveTrait: .boldFontMask)
                        textStorage.addAttribute(.font, value: boldFont, range: boldRange)
                    }
                    location = wordRange.location + wordRange.length
                }
            }
        }
    }
    
    private func showModeIndicator(for mode: AdaptiveTypographyEngine.ReadingMode) {
        // Create or get existing indicator
        let indicator: ModeIndicatorView
        if let existing = view.subviews.first(where: { $0 is ModeIndicatorView }) as? ModeIndicatorView {
            indicator = existing
        } else {
            indicator = ModeIndicatorView(frame: NSRect(x: 0, y: 0, width: 220, height: 140))
            indicator.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(indicator)
            
            NSLayoutConstraint.activate([
                indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
                indicator.widthAnchor.constraint(equalToConstant: 220),
                indicator.heightAnchor.constraint(equalToConstant: 140)
            ])
        }
        
        // Show appropriate message
        switch mode {
        case .normal:
            indicator.showMode("Normal Mode", subtitle: "Standard reading view")
        case .focus:
            indicator.showMode("Focus Mode", subtitle: "Enhanced concentration")
        case .speed:
            indicator.showMode("Speed Reading", subtitle: "Optimized for rapid scanning")
        case .night:
            indicator.showMode("Night Mode", subtitle: "Reduced eye strain")
        case .paper:
            indicator.showMode("Paper Mode", subtitle: "Classic book feeling")
        case .bionic:
            indicator.showMode("Bionic Reading", subtitle: "Faster comprehension through fixation points")
        case .dyslexic:
            indicator.showMode("Dyslexic Mode", subtitle: "Optimized for dyslexic readers")
        }
    }
    
    // MARK: - Enhanced Focus Mode
    
    private func setupEnhancedFocusMode() {
        let focusMode = EnhancedFocusMode(textView: textView)
        objc_setAssociatedObject(self, &AssociatedKeys.focusMode, focusMode, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func toggleEnhancedFocusMode() {
        guard let focusMode = objc_getAssociatedObject(self, &AssociatedKeys.focusMode) as? EnhancedFocusMode else { return }
        
        if focusModeEnabled {
            focusMode.disable()
        } else {
            focusMode.enable(with: .paragraph)
        }
        focusModeEnabled.toggle()
    }
    
    // MARK: - Floating TOC
    
    private func setupFloatingTOC() {
        let floatingTOC = FloatingTOCView(textView: textView, scrollView: scrollView)
        floatingTOC.translatesAutoresizingMaskIntoConstraints = false
        floatingTOC.isHidden = true  // Start hidden
        view.addSubview(floatingTOC)
        
        NSLayoutConstraint.activate([
            floatingTOC.topAnchor.constraint(equalTo: view.topAnchor, constant: 60),
            floatingTOC.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            floatingTOC.widthAnchor.constraint(equalToConstant: 280),
            floatingTOC.heightAnchor.constraint(equalToConstant: 400)
        ])
        
        objc_setAssociatedObject(self, &AssociatedKeys.floatingTOC, floatingTOC, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        floatingTOC.delegate = self
        
        // Update TOC when document loads
        if let document = currentDocument {
            floatingTOC.updateWithContent(document.content)
        }
    }
    
    func updateFloatingTOC() {
        guard let floatingTOC = objc_getAssociatedObject(self, &AssociatedKeys.floatingTOC) as? FloatingTOCView,
              let document = currentDocument else { return }
        
        floatingTOC.updateWithContent(document.content)
    }
    
    func toggleFloatingTOC() {
        guard let toc = objc_getAssociatedObject(self, &AssociatedKeys.floatingTOC) as? FloatingTOCView else { return }
        toc.isHidden.toggle()
        if !toc.isHidden && currentDocument != nil {
            updateFloatingTOC()
        }
    }
    
    // MARK: - Fuzzy Search
    
    private func setupFuzzySearch() {
        let fuzzySearch = InstantFuzzySearch()
        fuzzySearch.textView = textView
        fuzzySearch.delegate = self
        
        objc_setAssociatedObject(self, &AssociatedKeys.fuzzySearch, fuzzySearch, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func showFuzzySearch() {
        guard let fuzzySearch = objc_getAssociatedObject(self, &AssociatedKeys.fuzzySearch) as? InstantFuzzySearch else { return }
        
        // Create popover
        let popover = NSPopover()
        popover.contentViewController = fuzzySearch
        popover.behavior = .transient
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: .maxY)
    }
    
    // MARK: - Progress Tracking
    
    private func setupProgressTracking() {
        let progressTracker = ReadingProgressTracker(scrollView: scrollView, textView: textView)
        objc_setAssociatedObject(self, &AssociatedKeys.progressTracker, progressTracker, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        if let document = currentDocument, let url = document.url {
            progressTracker.startTracking(for: url, content: document.content)
        }
    }
    
    // MARK: - Progressive Rendering
    
    private func setupProgressiveRendering() {
        let progressiveRenderer = ProgressiveRenderingEngine()
        objc_setAssociatedObject(self, &AssociatedKeys.progressiveRenderer, progressiveRenderer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func loadDocumentWithProgressiveRendering(_ document: MarkdownDocument) {
        guard let progressiveRenderer = objc_getAssociatedObject(self, &AssociatedKeys.progressiveRenderer) as? ProgressiveRenderingEngine else {
            loadDocument(document)
            return
        }
        
        currentDocument = document
        
        progressiveRenderer.renderProgressively(
            markdown: document.content,
            visibleRange: visibleRange,
            completion: { [weak self] initialContent in
                DispatchQueue.main.async {
                    self?.textView.textStorage?.setAttributedString(initialContent)
                }
            },
            progressUpdate: { [weak self] content, progress in
                DispatchQueue.main.async {
                    self?.textView.textStorage?.setAttributedString(content)
                    print("Rendering progress: \(Int(progress * 100))%")
                }
            }
        )
        
        // Update other features
        updateFloatingTOC()
    }
    
    // MARK: - Public Methods for Menu Actions
    
    func switchToNormalMode() {
        applyTypographyMode(.normal)
    }
    
    func switchToFocusMode() {
        applyTypographyMode(.focus)
        toggleEnhancedFocusMode()
    }
    
    func switchToSpeedMode() {
        applyTypographyMode(.speed)
    }
    
    func switchToNightMode() {
        applyTypographyMode(.night)
        view.window?.backgroundColor = NSColor(calibratedRed: 0.08, green: 0.08, blue: 0.1, alpha: 1.0)
    }
    
    func switchToPaperMode() {
        applyTypographyMode(.paper)
        view.window?.backgroundColor = NSColor(calibratedRed: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
    }
    
    func switchToBionicMode() {
        applyTypographyMode(.bionic)
    }
    
    func switchToDyslexicMode() {
        applyTypographyMode(.dyslexic)
    }
    
    // MARK: - Performance Methods
    
    func togglePerformanceOverlay() {
        // Find the performance overlay in subviews
        for subview in view.subviews {
            if subview is PerformanceOverlayView {
                subview.isHidden.toggle()
                return
            }
        }
        // If not found, the overlay wasn't created yet - setupPerformanceMonitoring should have created it
        setupPerformanceMonitoring()
    }
    
    func toggleReadingProgress() {
        guard let progressTracker = objc_getAssociatedObject(self, &AssociatedKeys.progressTracker) as? ReadingProgressTracker else { return }
        // Toggle progress display
        progressTracker.showProgressIndicator.toggle()
    }
    
    func toggleProgressiveRendering() {
        // Toggle progressive rendering mode
        UserDefaults.standard.set(!UserDefaults.standard.bool(forKey: "UseProgressiveRendering"), forKey: "UseProgressiveRendering")
    }
    
    func clearRenderCache() {
        // Clear any render caches
        ImageCache.shared.clear()
    }
    
    func toggleCodeTheaterMode() {
        // Implementation for code theater mode
    }
    
    func toggleMiniMap() {
        // Implementation for mini map
    }
    
    func setFocusStyle(_ style: EnhancedFocusMode.FocusStyle) {
        guard let focusMode = objc_getAssociatedObject(self, &AssociatedKeys.focusMode) as? EnhancedFocusMode else { return }
        focusMode.enable(with: style)
    }
    
    func toggleBreadcrumbs() {
        // Implementation for breadcrumbs
    }
    
    func navigateBack() {
        // Implementation for navigation history
    }
    
    func navigateForward() {
        // Implementation for navigation history
    }
    
    func toggleTypewriterMode() {
        typewriterScrollingEnabled.toggle()
        if typewriterScrollingEnabled {
            enableTypewriterScrolling()
        } else {
            disableTypewriterScrolling()
        }
    }
}

// MARK: - InstantFuzzySearchDelegate

extension MarkdownViewController: InstantFuzzySearchDelegate {
    func instantFuzzySearch(_ search: InstantFuzzySearch, didSelectResult result: InstantFuzzySearch.SearchResult) {
        textView.scrollRangeToVisible(result.location)
        textView.showFindIndicator(for: result.location)
    }
    
    func instantFuzzySearchDidClear(_ search: InstantFuzzySearch) {
        // Clear any highlights
    }
}

// MARK: - FloatingTOCDelegate

extension MarkdownViewController: FloatingTOCDelegate {
    func floatingTOC(_ toc: FloatingTOCView, didSelectItem item: FloatingTOCView.TOCItem) {
        textView.scrollRangeToVisible(item.range)
    }
}