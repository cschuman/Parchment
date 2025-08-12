import Cocoa

extension AppDelegate {
    
    func setupEnhancedMenus() {
        guard let mainMenu = NSApp.mainMenu else { return }
        
        // Add Typography menu
        addTypographyMenu(to: mainMenu)
        
        // Add Navigation menu
        addNavigationMenu(to: mainMenu)
        
        // Add Performance menu
        addPerformanceMenu(to: mainMenu)
        
        // Enhance existing View menu
        enhanceViewMenu()
    }
    
    private func addTypographyMenu(to mainMenu: NSMenu) {
        let typographyMenuItem = NSMenuItem()
        mainMenu.insertItem(typographyMenuItem, at: 3) // After View menu
        
        let typographyMenu = NSMenu(title: "Typography")
        typographyMenuItem.submenu = typographyMenu
        
        // Reading Modes
        typographyMenu.addItem(NSMenuItem(title: "Reading Modes", action: nil, keyEquivalent: ""))
        typographyMenu.addItem(NSMenuItem(title: "  Normal", action: #selector(switchToNormalMode), keyEquivalent: "1"))
        typographyMenu.addItem(NSMenuItem(title: "  Focus", action: #selector(switchToFocusMode), keyEquivalent: "2"))
        typographyMenu.addItem(NSMenuItem(title: "  Speed Reading", action: #selector(switchToSpeedMode), keyEquivalent: "3"))
        typographyMenu.addItem(NSMenuItem(title: "  Night Mode", action: #selector(switchToNightMode), keyEquivalent: "4"))
        typographyMenu.addItem(NSMenuItem(title: "  Paper Mode", action: #selector(switchToPaperMode), keyEquivalent: "5"))
        typographyMenu.addItem(NSMenuItem(title: "  Bionic Reading", action: #selector(switchToBionicMode), keyEquivalent: "6"))
        typographyMenu.addItem(NSMenuItem(title: "  Dyslexic Mode", action: #selector(switchToDyslexicMode), keyEquivalent: "7"))
        
        typographyMenu.addItem(NSMenuItem.separator())
        
        // Focus Styles
        typographyMenu.addItem(NSMenuItem(title: "Focus Style", action: nil, keyEquivalent: ""))
        typographyMenu.addItem(NSMenuItem(title: "  Paragraph Focus", action: #selector(setParagraphFocus), keyEquivalent: ""))
        typographyMenu.addItem(NSMenuItem(title: "  Sentence Focus", action: #selector(setSentenceFocus), keyEquivalent: ""))
        typographyMenu.addItem(NSMenuItem(title: "  Line Focus", action: #selector(setLineFocus), keyEquivalent: ""))
        typographyMenu.addItem(NSMenuItem(title: "  Gradual Focus", action: #selector(setGradualFocus), keyEquivalent: ""))
        typographyMenu.addItem(NSMenuItem(title: "  Spotlight Focus", action: #selector(setSpotlightFocus), keyEquivalent: ""))
    }
    
    private func addNavigationMenu(to mainMenu: NSMenu) {
        let navigationMenuItem = NSMenuItem()
        mainMenu.insertItem(navigationMenuItem, at: 4)
        
        let navigationMenu = NSMenu(title: "Navigate")
        navigationMenuItem.submenu = navigationMenu
        
        navigationMenu.addItem(NSMenuItem(title: "Fuzzy Search", action: #selector(showFuzzySearch), keyEquivalent: "p"))
        navigationMenu.addItem(NSMenuItem(title: "Show Table of Contents", action: #selector(showFloatingTOC), keyEquivalent: "l"))
        navigationMenu.addItem(NSMenuItem(title: "Show Breadcrumbs", action: #selector(showBreadcrumbs), keyEquivalent: ""))
        navigationMenu.addItem(NSMenuItem.separator())
        navigationMenu.addItem(NSMenuItem(title: "Next Header", action: #selector(navigateToNextHeader), keyEquivalent: "]"))
        navigationMenu.addItem(NSMenuItem(title: "Previous Header", action: #selector(navigateToPreviousHeader), keyEquivalent: "["))
        navigationMenu.addItem(NSMenuItem.separator())
        navigationMenu.addItem(NSMenuItem(title: "Back", action: #selector(navigateBack), keyEquivalent: ""))
        navigationMenu.addItem(NSMenuItem(title: "Forward", action: #selector(navigateForward), keyEquivalent: ""))
    }
    
    private func addPerformanceMenu(to mainMenu: NSMenu) {
        let performanceMenuItem = NSMenuItem()
        mainMenu.insertItem(performanceMenuItem, at: 5)
        
        let performanceMenu = NSMenu(title: "Performance")
        performanceMenuItem.submenu = performanceMenu
        
        performanceMenu.addItem(NSMenuItem(title: "Show Performance Overlay", action: #selector(togglePerformanceOverlay), keyEquivalent: ""))
        performanceMenu.addItem(NSMenuItem(title: "Show Reading Progress", action: #selector(toggleReadingProgress), keyEquivalent: ""))
        performanceMenu.addItem(NSMenuItem(title: "Enable Progressive Rendering", action: #selector(toggleProgressiveRendering), keyEquivalent: ""))
        performanceMenu.addItem(NSMenuItem.separator())
        performanceMenu.addItem(NSMenuItem(title: "Clear Cache", action: #selector(clearCache), keyEquivalent: ""))
        performanceMenu.addItem(NSMenuItem(title: "Performance Report", action: #selector(showPerformanceReport), keyEquivalent: ""))
    }
    
    private func enhanceViewMenu() {
        guard let viewMenu = NSApp.mainMenu?.item(withTitle: "View")?.submenu else { return }
        
        // Add separator before existing items
        viewMenu.insertItem(NSMenuItem.separator(), at: 0)
        
        // Add new view options
        viewMenu.insertItem(NSMenuItem(title: "Code Block Theater Mode", action: #selector(toggleCodeTheaterMode), keyEquivalent: ""), at: 0)
        viewMenu.insertItem(NSMenuItem(title: "Show Mini Map", action: #selector(toggleMiniMap), keyEquivalent: ""), at: 0)
        viewMenu.insertItem(NSMenuItem(title: "Toggle Typewriter Mode", action: #selector(toggleTypewriterMode), keyEquivalent: ""), at: 0)
    }
    
    // MARK: - Typography Actions
    
    @objc private func switchToNormalMode() {
        windowController?.markdownViewController?.switchToNormalMode()
    }
    
    @objc private func switchToFocusMode() {
        windowController?.markdownViewController?.switchToFocusMode()
    }
    
    @objc private func switchToSpeedMode() {
        windowController?.markdownViewController?.switchToSpeedMode()
    }
    
    @objc private func switchToNightMode() {
        windowController?.markdownViewController?.switchToNightMode()
    }
    
    @objc private func switchToPaperMode() {
        windowController?.markdownViewController?.switchToPaperMode()
    }
    
    @objc private func switchToBionicMode() {
        windowController?.markdownViewController?.switchToBionicMode()
    }
    
    @objc private func switchToDyslexicMode() {
        windowController?.markdownViewController?.switchToDyslexicMode()
    }
    
    // MARK: - Focus Style Actions
    
    @objc private func setParagraphFocus() {
        windowController?.markdownViewController?.setFocusStyle(.paragraph)
    }
    
    @objc private func setSentenceFocus() {
        windowController?.markdownViewController?.setFocusStyle(.sentence)
    }
    
    @objc private func setLineFocus() {
        windowController?.markdownViewController?.setFocusStyle(.line)
    }
    
    @objc private func setGradualFocus() {
        windowController?.markdownViewController?.setFocusStyle(.gradual)
    }
    
    @objc private func setSpotlightFocus() {
        windowController?.markdownViewController?.setFocusStyle(.spotlight)
    }
    
    // MARK: - Navigation Actions
    
    @objc private func showFuzzySearch() {
        windowController?.markdownViewController?.showFuzzySearch()
    }
    
    @objc private func showFloatingTOC() {
        windowController?.markdownViewController?.toggleFloatingTOC()
    }
    
    @objc private func showBreadcrumbs() {
        windowController?.markdownViewController?.toggleBreadcrumbs()
    }
    
    @objc private func navigateToNextHeader() {
        windowController?.markdownViewController?.navigateToNextHeader()
    }
    
    @objc private func navigateToPreviousHeader() {
        windowController?.markdownViewController?.navigateToPreviousHeader()
    }
    
    @objc private func navigateBack() {
        windowController?.markdownViewController?.navigateBack()
    }
    
    @objc private func navigateForward() {
        windowController?.markdownViewController?.navigateForward()
    }
    
    // MARK: - Performance Actions
    
    @objc private func togglePerformanceOverlay() {
        windowController?.markdownViewController?.togglePerformanceOverlay()
    }
    
    @objc private func toggleReadingProgress() {
        windowController?.markdownViewController?.toggleReadingProgress()
    }
    
    @objc private func toggleProgressiveRendering() {
        windowController?.markdownViewController?.toggleProgressiveRendering()
    }
    
    @objc private func clearCache() {
        // Clear all caches
        ImageCache.shared.clear()
        windowController?.markdownViewController?.clearRenderCache()
    }
    
    @objc private func showPerformanceReport() {
        let report = PerformanceMonitor.shared.generatePerformanceReport()
        
        let alert = NSAlert()
        alert.messageText = "Performance Report"
        alert.informativeText = report
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - View Actions
    
    @objc private func toggleCodeTheaterMode() {
        windowController?.markdownViewController?.toggleCodeTheaterMode()
    }
    
    @objc private func toggleMiniMap() {
        windowController?.markdownViewController?.toggleMiniMap()
    }
    
    @objc private func toggleTypewriterMode() {
        windowController?.markdownViewController?.toggleTypewriterMode()
    }
}

// Methods are implemented in MarkdownViewController+Features.swift and MarkdownViewController.swift