import Cocoa

/// Handles window state restoration for Stage Manager and macOS window management
///
/// This class implements `NSWindowRestoration` to properly restore windows
/// after app relaunch, supporting:
/// - Stage Manager window grouping persistence
/// - Window frame and position restoration
/// - Document state recovery
final class WindowRestoration: NSObject, NSWindowRestoration {

    /// Restores a window from saved state
    ///
    /// Called by AppKit when the app relaunches and needs to restore windows
    /// from the previous session. This is especially important for Stage Manager
    /// where window arrangements should be preserved.
    ///
    /// - Parameters:
    ///   - identifier: The window's restoration identifier
    ///   - state: The encoded state from the previous session
    ///   - completionHandler: Handler to call with the restored window
    static func restoreWindow(
        withIdentifier identifier: NSUserInterfaceItemIdentifier,
        state: NSCoder,
        completionHandler: @escaping (NSWindow?, Error?) -> Void
    ) {
        // Ensure restoration happens on main thread
        DispatchQueue.main.async {
            do {
                let window = try restoreWindowSync(identifier: identifier, state: state)
                completionHandler(window, nil)
            } catch {
                Logger.error("Window restoration failed: \(error)")
                completionHandler(nil, error)
            }
        }
    }

    /// Synchronous window restoration implementation
    private static func restoreWindowSync(
        identifier: NSUserInterfaceItemIdentifier,
        state: NSCoder
    ) throws -> NSWindow {
        // Get the app delegate to access or create window controller
        guard let appDelegate = NSApp.delegate as? AppDelegate else {
            throw WindowRestorationError.appDelegateNotFound
        }

        // Create window controller if needed
        if appDelegate.windowController == nil {
            appDelegate.windowController = MainWindowController()
        }

        guard let windowController = appDelegate.windowController,
              let window = windowController.window else {
            throw WindowRestorationError.windowCreationFailed
        }

        // Restore window frame from saved state
        if let frameString = state.decodeObject(forKey: "windowFrame") as? String {
            let savedFrame = NSRectFromString(frameString)
            if savedFrame != .zero {
                // Validate frame is on a current screen
                if let targetScreen = screenContaining(frame: savedFrame) ?? NSScreen.main {
                    let visibleFrame = targetScreen.visibleFrame
                    var adjustedFrame = savedFrame

                    // Ensure window fits within screen bounds
                    adjustedFrame = constrainFrame(adjustedFrame, to: visibleFrame)
                    window.setFrame(adjustedFrame, display: false)
                }
            }
        }

        // Show the window
        windowController.showWindow(nil)

        // Restore document if URL was saved
        if let urlString = state.decodeObject(forKey: "documentURL") as? String,
           let documentURL = URL(string: urlString),
           FileManager.default.fileExists(atPath: documentURL.path) {
            windowController.loadDocument(at: documentURL)
        }

        return window
    }

    /// Finds the screen that contains most of the given frame
    private static func screenContaining(frame: NSRect) -> NSScreen? {
        var maxIntersection: CGFloat = 0
        var targetScreen: NSScreen?

        for screen in NSScreen.screens {
            let intersection = frame.intersection(screen.frame)
            let area = intersection.width * intersection.height
            if area > maxIntersection {
                maxIntersection = area
                targetScreen = screen
            }
        }

        return targetScreen
    }

    /// Constrains a window frame to fit within visible screen bounds
    private static func constrainFrame(_ frame: NSRect, to visibleFrame: NSRect) -> NSRect {
        var adjusted = frame

        // Ensure width and height don't exceed screen
        adjusted.size.width = min(adjusted.width, visibleFrame.width)
        adjusted.size.height = min(adjusted.height, visibleFrame.height)

        // Ensure origin keeps window on screen
        if adjusted.maxX > visibleFrame.maxX {
            adjusted.origin.x = visibleFrame.maxX - adjusted.width
        }
        if adjusted.origin.x < visibleFrame.origin.x {
            adjusted.origin.x = visibleFrame.origin.x
        }
        if adjusted.maxY > visibleFrame.maxY {
            adjusted.origin.y = visibleFrame.maxY - adjusted.height
        }
        if adjusted.origin.y < visibleFrame.origin.y {
            adjusted.origin.y = visibleFrame.origin.y
        }

        return adjusted
    }
}

// MARK: - Errors

/// Errors that can occur during window restoration
enum WindowRestorationError: LocalizedError {
    case appDelegateNotFound
    case windowCreationFailed

    var errorDescription: String? {
        switch self {
        case .appDelegateNotFound:
            return "Application delegate not found during window restoration"
        case .windowCreationFailed:
            return "Failed to create or access main window"
        }
    }
}
