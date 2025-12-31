import Cocoa

/// Represents a customizable keyboard shortcut
struct KeyboardShortcut: Codable, Equatable {
    let keyCode: UInt16
    let modifierFlags: UInt
    let action: String

    /// Human-readable description of the shortcut
    var displayString: String {
        var parts: [String] = []
        let modifiers = NSEvent.ModifierFlags(rawValue: modifierFlags)

        if modifiers.contains(.control) { parts.append("\u{2303}") }  // Control
        if modifiers.contains(.option) { parts.append("\u{2325}") }   // Option
        if modifiers.contains(.shift) { parts.append("\u{21E7}") }    // Shift
        if modifiers.contains(.command) { parts.append("\u{2318}") }  // Command

        if let keyString = KeyboardShortcut.keyCodeToString(keyCode) {
            parts.append(keyString)
        }

        return parts.joined()
    }

    /// Key equivalent string for NSMenuItem
    var keyEquivalent: String {
        KeyboardShortcut.keyCodeToKeyEquivalent(keyCode) ?? ""
    }

    /// Modifier mask for NSMenuItem
    var modifierMask: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlags)
    }

    /// Convert key code to display string
    static func keyCodeToString(_ keyCode: UInt16) -> String? {
        switch keyCode {
        // Letters
        case 0: return "A"
        case 11: return "B"
        case 8: return "C"
        case 2: return "D"
        case 14: return "E"
        case 3: return "F"
        case 5: return "G"
        case 4: return "H"
        case 34: return "I"
        case 38: return "J"
        case 40: return "K"
        case 37: return "L"
        case 46: return "M"
        case 45: return "N"
        case 31: return "O"
        case 35: return "P"
        case 12: return "Q"
        case 15: return "R"
        case 1: return "S"
        case 17: return "T"
        case 32: return "U"
        case 9: return "V"
        case 13: return "W"
        case 7: return "X"
        case 16: return "Y"
        case 6: return "Z"
        // Numbers
        case 29: return "0"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        // Special keys
        case 36: return "\u{21A9}"   // Return
        case 48: return "\u{21E5}"   // Tab
        case 49: return "\u{2423}"   // Space
        case 51: return "\u{232B}"   // Delete
        case 53: return "\u{238B}"   // Escape
        case 123: return "\u{2190}"  // Left arrow
        case 124: return "\u{2192}"  // Right arrow
        case 125: return "\u{2193}"  // Down arrow
        case 126: return "\u{2191}"  // Up arrow
        // Punctuation
        case 27: return "-"
        case 24: return "="
        case 30: return "]"
        case 33: return "["
        case 39: return "'"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 47: return "."
        case 50: return "`"
        // Function keys
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        default: return nil
        }
    }

    /// Convert key code to key equivalent character for menu items
    static func keyCodeToKeyEquivalent(_ keyCode: UInt16) -> String? {
        switch keyCode {
        // Letters (lowercase for menu equivalents)
        case 0: return "a"
        case 11: return "b"
        case 8: return "c"
        case 2: return "d"
        case 14: return "e"
        case 3: return "f"
        case 5: return "g"
        case 4: return "h"
        case 34: return "i"
        case 38: return "j"
        case 40: return "k"
        case 37: return "l"
        case 46: return "m"
        case 45: return "n"
        case 31: return "o"
        case 35: return "p"
        case 12: return "q"
        case 15: return "r"
        case 1: return "s"
        case 17: return "t"
        case 32: return "u"
        case 9: return "v"
        case 13: return "w"
        case 7: return "x"
        case 16: return "y"
        case 6: return "z"
        // Numbers
        case 29: return "0"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        // Special
        case 27: return "-"
        case 24: return "+"
        case 30: return "]"
        case 33: return "["
        case 44: return "/"
        // Arrow keys need special handling
        case 123: return String(UnicodeScalar(NSLeftArrowFunctionKey)!)
        case 124: return String(UnicodeScalar(NSRightArrowFunctionKey)!)
        case 125: return String(UnicodeScalar(NSDownArrowFunctionKey)!)
        case 126: return String(UnicodeScalar(NSUpArrowFunctionKey)!)
        default: return nil
        }
    }
}

/// Defines all configurable shortcut actions
enum ShortcutAction: String, CaseIterable {
    case toggleFocusMode = "toggleFocusMode"
    case toggleTOC = "toggleTOC"
    case toggleDistractionFree = "toggleDistractionFree"
    case find = "find"
    case export = "export"
    case nextHeader = "nextHeader"
    case previousHeader = "previousHeader"
    case zoomIn = "zoomIn"
    case zoomOut = "zoomOut"
    case toggleReadingMode = "toggleReadingMode"
    case showStatistics = "showStatistics"
    case toggleStatusBar = "toggleStatusBar"

    var displayName: String {
        switch self {
        case .toggleFocusMode: return "Toggle Focus Mode"
        case .toggleTOC: return "Toggle Table of Contents"
        case .toggleDistractionFree: return "Distraction-Free Mode"
        case .find: return "Find"
        case .export: return "Export as PDF"
        case .nextHeader: return "Next Header"
        case .previousHeader: return "Previous Header"
        case .zoomIn: return "Zoom In"
        case .zoomOut: return "Zoom Out"
        case .toggleReadingMode: return "Toggle Reading Mode"
        case .showStatistics: return "Show Reading Statistics"
        case .toggleStatusBar: return "Toggle Status Bar"
        }
    }

    var menuItemTitle: String {
        switch self {
        case .toggleFocusMode: return "Toggle Focus Mode"
        case .toggleTOC: return "Toggle Table of Contents"
        case .toggleDistractionFree: return "Distraction-Free Mode"
        case .find: return "Find..."
        case .export: return "Export as PDF..."
        case .nextHeader: return "Next Header"
        case .previousHeader: return "Previous Header"
        case .zoomIn: return "Zoom In"
        case .zoomOut: return "Zoom Out"
        case .toggleReadingMode: return "Toggle Reading Mode"
        case .showStatistics: return "Show Reading Statistics"
        case .toggleStatusBar: return "Toggle Status Bar"
        }
    }
}

/// Manages user-configurable keyboard shortcuts with persistence
final class KeyboardShortcutManager {

    // MARK: - Singleton

    static let shared = KeyboardShortcutManager()

    // MARK: - Configuration

    private enum Configuration {
        static let userDefaultsKey = "KeyboardShortcuts"
    }

    // MARK: - Properties

    private var shortcuts: [String: KeyboardShortcut] = [:]

    /// Callback when shortcuts change
    var onShortcutsChanged: (() -> Void)?

    // MARK: - Default Shortcuts

    private static let defaultShortcuts: [ShortcutAction: KeyboardShortcut] = [
        .toggleFocusMode: KeyboardShortcut(
            keyCode: 3,  // F
            modifierFlags: NSEvent.ModifierFlags([.command, .shift]).rawValue,
            action: ShortcutAction.toggleFocusMode.rawValue
        ),
        .toggleTOC: KeyboardShortcut(
            keyCode: 17,  // T
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.toggleTOC.rawValue
        ),
        .toggleDistractionFree: KeyboardShortcut(
            keyCode: 2,  // D
            modifierFlags: NSEvent.ModifierFlags([.command, .shift]).rawValue,
            action: ShortcutAction.toggleDistractionFree.rawValue
        ),
        .find: KeyboardShortcut(
            keyCode: 3,  // F
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.find.rawValue
        ),
        .export: KeyboardShortcut(
            keyCode: 14,  // E
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.export.rawValue
        ),
        .nextHeader: KeyboardShortcut(
            keyCode: 30,  // ]
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.nextHeader.rawValue
        ),
        .previousHeader: KeyboardShortcut(
            keyCode: 33,  // [
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.previousHeader.rawValue
        ),
        .zoomIn: KeyboardShortcut(
            keyCode: 24,  // + (=)
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.zoomIn.rawValue
        ),
        .zoomOut: KeyboardShortcut(
            keyCode: 27,  // -
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.zoomOut.rawValue
        ),
        .toggleReadingMode: KeyboardShortcut(
            keyCode: 15,  // R
            modifierFlags: NSEvent.ModifierFlags([.command, .shift]).rawValue,
            action: ShortcutAction.toggleReadingMode.rawValue
        ),
        .showStatistics: KeyboardShortcut(
            keyCode: 44,  // /
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.showStatistics.rawValue
        ),
        .toggleStatusBar: KeyboardShortcut(
            keyCode: 11,  // B
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.toggleStatusBar.rawValue
        )
    ]

    // MARK: - Initialization

    private init() {
        loadShortcuts()
    }

    // MARK: - Public Interface

    /// Get the shortcut for a specific action
    func shortcut(for action: ShortcutAction) -> KeyboardShortcut {
        if let customShortcut = shortcuts[action.rawValue] {
            return customShortcut
        }
        return Self.defaultShortcuts[action] ?? KeyboardShortcut(
            keyCode: 0,
            modifierFlags: 0,
            action: action.rawValue
        )
    }

    /// Set a custom shortcut for an action
    func setShortcut(_ shortcut: KeyboardShortcut, for action: ShortcutAction) {
        shortcuts[action.rawValue] = shortcut
        saveShortcuts()
        onShortcutsChanged?()
        NotificationCenter.default.post(name: .shortcutsChanged, object: nil)
    }

    /// Reset a specific action to its default shortcut
    func resetToDefault(for action: ShortcutAction) {
        shortcuts.removeValue(forKey: action.rawValue)
        saveShortcuts()
        onShortcutsChanged?()
        NotificationCenter.default.post(name: .shortcutsChanged, object: nil)
    }

    /// Reset all shortcuts to defaults
    func resetAllToDefaults() {
        shortcuts.removeAll()
        saveShortcuts()
        onShortcutsChanged?()
        NotificationCenter.default.post(name: .shortcutsChanged, object: nil)
    }

    /// Check if a shortcut conflicts with another action
    func conflictingAction(for shortcut: KeyboardShortcut, excluding action: ShortcutAction) -> ShortcutAction? {
        for otherAction in ShortcutAction.allCases {
            guard otherAction != action else { continue }
            let otherShortcut = self.shortcut(for: otherAction)
            if otherShortcut.keyCode == shortcut.keyCode &&
               otherShortcut.modifierFlags == shortcut.modifierFlags {
                return otherAction
            }
        }
        return nil
    }

    /// Check if an action has a custom (non-default) shortcut
    func isCustom(for action: ShortcutAction) -> Bool {
        return shortcuts[action.rawValue] != nil
    }

    /// Get the default shortcut for an action
    func defaultShortcut(for action: ShortcutAction) -> KeyboardShortcut? {
        return Self.defaultShortcuts[action]
    }

    /// Apply shortcuts to a menu
    func applyShortcuts(to menu: NSMenu) {
        applyShortcutsRecursively(to: menu)
    }

    // MARK: - Private Implementation

    private func applyShortcutsRecursively(to menu: NSMenu) {
        for item in menu.items {
            // Check if this menu item matches any shortcut action
            for action in ShortcutAction.allCases {
                if item.title == action.menuItemTitle {
                    let shortcut = self.shortcut(for: action)
                    item.keyEquivalent = shortcut.keyEquivalent
                    item.keyEquivalentModifierMask = shortcut.modifierMask
                }
            }

            // Recurse into submenus
            if let submenu = item.submenu {
                applyShortcutsRecursively(to: submenu)
            }
        }
    }

    private func loadShortcuts() {
        guard let data = UserDefaults.standard.data(forKey: Configuration.userDefaultsKey),
              let decoded = try? JSONDecoder().decode([String: KeyboardShortcut].self, from: data) else {
            return
        }
        shortcuts = decoded
    }

    private func saveShortcuts() {
        guard let data = try? JSONEncoder().encode(shortcuts) else {
            Logger.warning("Failed to encode keyboard shortcuts")
            return
        }
        UserDefaults.standard.set(data, forKey: Configuration.userDefaultsKey)
        UserDefaults.standard.synchronize()
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let shortcutsChanged = Notification.Name("KeyboardShortcutsChanged")
}
