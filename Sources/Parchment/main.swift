import Cocoa

fputs("main.swift: Starting\n", stderr)

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

fputs("main.swift: Creating AppDelegate\n", stderr)
let delegate = AppDelegate()
app.delegate = delegate

fputs("main.swift: Running app\n", stderr)
app.run()