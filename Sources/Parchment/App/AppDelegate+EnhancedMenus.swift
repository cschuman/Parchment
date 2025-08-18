import Cocoa

extension AppDelegate {
    
    func setupEnhancedMenus() {
        guard let mainMenu = NSApp.mainMenu else { return }
        
        // Add View menu items
        addViewMenuItems(to: mainMenu)
    }
    
    private func addViewMenuItems(to mainMenu: NSMenu) {
        guard let viewMenu = mainMenu.item(withTitle: "View")?.submenu else { return }
        
        // Add theme options
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(NSMenuItem(title: "Light Theme", action: #selector(switchToLightMode), keyEquivalent: "1"))
        viewMenu.addItem(NSMenuItem(title: "Dark Theme", action: #selector(switchToDarkMode), keyEquivalent: "2"))
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(NSMenuItem(title: "Toggle Focus Mode", action: #selector(handleToggleFocusMode), keyEquivalent: "f"))
    }
    
    // MARK: - Theme Actions
    
    @objc private func switchToLightMode() {
        windowController?.markdownViewController?.applyLightMode()
    }
    
    @objc private func switchToDarkMode() {
        windowController?.markdownViewController?.applyDarkMode()
    }
    
    @objc private func handleToggleFocusMode() {
        windowController?.markdownViewController?.toggleFocusMode()
    }
}