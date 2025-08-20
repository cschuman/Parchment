#!/usr/bin/env swift

import Cocoa

print("Testing window creation...")

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let window = NSWindow(
    contentRect: NSRect(x: 100, y: 100, width: 600, height: 400),
    styleMask: [.titled, .closable, .miniaturizable, .resizable],
    backing: .buffered,
    defer: false
)

window.title = "Test Window"
window.center()
window.makeKeyAndOrderFront(nil)

print("Window created successfully")
print("Press Ctrl+C to exit")

app.run()