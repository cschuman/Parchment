import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.regular)

// Enable Touch Bar customization menu item
if #available(macOS 10.12.2, *) {
    app.isAutomaticCustomizeTouchBarMenuItemEnabled = true
}

let delegate = AppDelegate()
app.delegate = delegate

app.run()
