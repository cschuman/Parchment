import Cocoa

/// Shared utility for displaying alerts
enum AlertHelper {

    /// Show an error alert with the given message
    /// - Parameters:
    ///   - message: The error message to display
    ///   - window: Optional window to present the alert as a sheet. If nil, shows modal.
    static func showError(_ message: String, in window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")

        if let window = window {
            alert.beginSheetModal(for: window) { _ in }
        } else {
            alert.runModal()
        }
    }

    /// Show a warning alert with the given message
    static func showWarning(_ message: String, in window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = "Warning"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")

        if let window = window {
            alert.beginSheetModal(for: window) { _ in }
        } else {
            alert.runModal()
        }
    }
}
