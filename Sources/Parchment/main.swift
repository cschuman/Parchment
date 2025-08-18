import Cocoa


// Disable Touch Bar before creating NSApplication
if #available(macOS 10.12.2, *) {
    UserDefaults.standard.set(false, forKey: "NSApplicationTouchBarEnabled")
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

// Disable automatic Touch Bar
if #available(macOS 10.12.2, *) {
    app.isAutomaticCustomizeTouchBarMenuItemEnabled = false
}

let delegate = AppDelegate()
app.delegate = delegate

app.run()