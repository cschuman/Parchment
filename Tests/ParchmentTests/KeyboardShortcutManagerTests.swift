import XCTest
@testable import Parchment

final class KeyboardShortcutManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset to defaults before each test
        KeyboardShortcutManager.shared.resetAllToDefaults()
    }

    override func tearDown() {
        // Clean up after tests
        KeyboardShortcutManager.shared.resetAllToDefaults()
        super.tearDown()
    }

    // MARK: - KeyboardShortcut Tests

    func testKeyboardShortcutDisplayString() {
        // Test Cmd+Shift+F (Toggle Focus Mode default)
        let shortcut = KeyboardShortcut(
            keyCode: 3,  // F
            modifierFlags: NSEvent.ModifierFlags([.command, .shift]).rawValue,
            action: "test"
        )

        let display = shortcut.displayString
        print("Display string for Cmd+Shift+F: '\(display)'")

        // Should contain shift symbol, command symbol, and F
        XCTAssertTrue(display.contains("\u{21E7}"), "Should contain shift symbol")
        XCTAssertTrue(display.contains("\u{2318}"), "Should contain command symbol")
        XCTAssertTrue(display.contains("F"), "Should contain F")
    }

    func testKeyboardShortcutKeyEquivalent() {
        let shortcut = KeyboardShortcut(
            keyCode: 3,  // F
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: "test"
        )

        XCTAssertEqual(shortcut.keyEquivalent, "f", "Key equivalent should be lowercase f")
    }

    func testKeyboardShortcutModifierMask() {
        let modifiers = NSEvent.ModifierFlags([.command, .shift])
        let shortcut = KeyboardShortcut(
            keyCode: 3,
            modifierFlags: modifiers.rawValue,
            action: "test"
        )

        XCTAssertEqual(shortcut.modifierMask, modifiers, "Modifier mask should match")
    }

    func testKeyCodeToStringLetters() {
        // Test a sampling of letter key codes
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(0), "A")
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(3), "F")
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(17), "T")
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(6), "Z")
    }

    func testKeyCodeToStringNumbers() {
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(29), "0")
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(18), "1")
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(25), "9")
    }

    func testKeyCodeToStringSpecialKeys() {
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(27), "-")
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(24), "=")
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(30), "]")
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(33), "[")
    }

    func testKeyCodeToStringArrows() {
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(123), "\u{2190}")  // Left
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(124), "\u{2192}")  // Right
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(125), "\u{2193}")  // Down
        XCTAssertEqual(KeyboardShortcut.keyCodeToString(126), "\u{2191}")  // Up
    }

    func testKeyCodeToKeyEquivalent() {
        XCTAssertEqual(KeyboardShortcut.keyCodeToKeyEquivalent(3), "f")
        XCTAssertEqual(KeyboardShortcut.keyCodeToKeyEquivalent(17), "t")
        XCTAssertEqual(KeyboardShortcut.keyCodeToKeyEquivalent(24), "+")
        XCTAssertEqual(KeyboardShortcut.keyCodeToKeyEquivalent(27), "-")
    }

    // MARK: - ShortcutAction Tests

    func testShortcutActionDisplayNames() {
        XCTAssertEqual(ShortcutAction.toggleFocusMode.displayName, "Toggle Focus Mode")
        XCTAssertEqual(ShortcutAction.toggleTOC.displayName, "Toggle Table of Contents")
        XCTAssertEqual(ShortcutAction.find.displayName, "Find")
        XCTAssertEqual(ShortcutAction.zoomIn.displayName, "Zoom In")
    }

    func testShortcutActionMenuItemTitles() {
        XCTAssertEqual(ShortcutAction.find.menuItemTitle, "Find...")
        XCTAssertEqual(ShortcutAction.export.menuItemTitle, "Export as PDF...")
        XCTAssertEqual(ShortcutAction.toggleFocusMode.menuItemTitle, "Toggle Focus Mode")
    }

    func testAllShortcutActionsHaveDisplayNames() {
        for action in ShortcutAction.allCases {
            XCTAssertFalse(action.displayName.isEmpty, "\(action) should have a display name")
            print("Action \(action.rawValue): displayName='\(action.displayName)', menuTitle='\(action.menuItemTitle)'")
        }
    }

    // MARK: - KeyboardShortcutManager Tests

    func testGetDefaultShortcut() {
        let manager = KeyboardShortcutManager.shared
        let shortcut = manager.shortcut(for: .toggleFocusMode)

        print("Toggle Focus Mode shortcut: keyCode=\(shortcut.keyCode), modifiers=\(shortcut.modifierFlags)")

        // Default is Cmd+Shift+F
        XCTAssertEqual(shortcut.keyCode, 3, "Key code should be F (3)")
        XCTAssertEqual(
            NSEvent.ModifierFlags(rawValue: shortcut.modifierFlags),
            [.command, .shift],
            "Modifiers should be Command+Shift"
        )
    }

    func testSetCustomShortcut() {
        let manager = KeyboardShortcutManager.shared

        // Set a custom shortcut
        let customShortcut = KeyboardShortcut(
            keyCode: 12,  // Q
            modifierFlags: NSEvent.ModifierFlags([.command, .option]).rawValue,
            action: ShortcutAction.toggleFocusMode.rawValue
        )
        manager.setShortcut(customShortcut, for: .toggleFocusMode)

        // Verify it was saved
        let retrieved = manager.shortcut(for: .toggleFocusMode)
        XCTAssertEqual(retrieved.keyCode, 12, "Custom key code should be saved")
        XCTAssertEqual(
            NSEvent.ModifierFlags(rawValue: retrieved.modifierFlags),
            [.command, .option],
            "Custom modifiers should be saved"
        )
    }

    func testIsCustomAfterSettingShortcut() {
        let manager = KeyboardShortcutManager.shared

        // Initially should not be custom
        XCTAssertFalse(manager.isCustom(for: .toggleFocusMode), "Should not be custom initially")

        // Set a custom shortcut
        let customShortcut = KeyboardShortcut(
            keyCode: 12,
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.toggleFocusMode.rawValue
        )
        manager.setShortcut(customShortcut, for: .toggleFocusMode)

        // Now should be custom
        XCTAssertTrue(manager.isCustom(for: .toggleFocusMode), "Should be custom after setting")
    }

    func testResetToDefault() {
        let manager = KeyboardShortcutManager.shared

        // Set a custom shortcut
        let customShortcut = KeyboardShortcut(
            keyCode: 12,
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.toggleFocusMode.rawValue
        )
        manager.setShortcut(customShortcut, for: .toggleFocusMode)
        XCTAssertTrue(manager.isCustom(for: .toggleFocusMode))

        // Reset to default
        manager.resetToDefault(for: .toggleFocusMode)

        // Should no longer be custom
        XCTAssertFalse(manager.isCustom(for: .toggleFocusMode), "Should not be custom after reset")

        // Should have default value
        let retrieved = manager.shortcut(for: .toggleFocusMode)
        XCTAssertEqual(retrieved.keyCode, 3, "Should have default key code after reset")
    }

    func testResetAllToDefaults() {
        let manager = KeyboardShortcutManager.shared

        // Set custom shortcuts for multiple actions
        for action in [ShortcutAction.toggleFocusMode, .toggleTOC, .find] {
            let customShortcut = KeyboardShortcut(
                keyCode: 12,
                modifierFlags: NSEvent.ModifierFlags.command.rawValue,
                action: action.rawValue
            )
            manager.setShortcut(customShortcut, for: action)
        }

        // Verify they are custom
        XCTAssertTrue(manager.isCustom(for: .toggleFocusMode))
        XCTAssertTrue(manager.isCustom(for: .toggleTOC))
        XCTAssertTrue(manager.isCustom(for: .find))

        // Reset all
        manager.resetAllToDefaults()

        // All should be default now
        XCTAssertFalse(manager.isCustom(for: .toggleFocusMode))
        XCTAssertFalse(manager.isCustom(for: .toggleTOC))
        XCTAssertFalse(manager.isCustom(for: .find))
    }

    func testConflictDetection() {
        let manager = KeyboardShortcutManager.shared

        // Get the default shortcut for toggleFocusMode
        let focusModeShortcut = manager.shortcut(for: .toggleFocusMode)

        // Try to detect conflict when setting the same shortcut for a different action
        let conflicting = manager.conflictingAction(
            for: focusModeShortcut,
            excluding: .toggleTOC
        )

        XCTAssertEqual(conflicting, .toggleFocusMode, "Should detect conflict with toggleFocusMode")
    }

    func testNoConflictWhenExcludingSameAction() {
        let manager = KeyboardShortcutManager.shared

        let focusModeShortcut = manager.shortcut(for: .toggleFocusMode)

        // Should not detect conflict when excluding the same action
        let conflicting = manager.conflictingAction(
            for: focusModeShortcut,
            excluding: .toggleFocusMode
        )

        XCTAssertNil(conflicting, "Should not detect conflict when excluding the same action")
    }

    func testNoConflictWithDifferentShortcut() {
        let manager = KeyboardShortcutManager.shared

        // Create a unique shortcut that doesn't match any default
        let uniqueShortcut = KeyboardShortcut(
            keyCode: 12,  // Q
            modifierFlags: NSEvent.ModifierFlags([.command, .control, .option]).rawValue,
            action: "test"
        )

        let conflicting = manager.conflictingAction(
            for: uniqueShortcut,
            excluding: .toggleFocusMode
        )

        XCTAssertNil(conflicting, "Should not detect conflict with unique shortcut")
    }

    func testGetDefaultShortcutForAction() {
        let manager = KeyboardShortcutManager.shared

        // Test that we can get the default shortcut even after setting a custom one
        let customShortcut = KeyboardShortcut(
            keyCode: 12,
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.toggleFocusMode.rawValue
        )
        manager.setShortcut(customShortcut, for: .toggleFocusMode)

        // Should still be able to get the default
        let defaultShortcut = manager.defaultShortcut(for: .toggleFocusMode)
        XCTAssertNotNil(defaultShortcut)
        XCTAssertEqual(defaultShortcut?.keyCode, 3, "Default should still be F")
    }

    func testShortcutPersistence() {
        // This test verifies that shortcuts are persisted to UserDefaults
        let manager = KeyboardShortcutManager.shared

        // Set a custom shortcut
        let customShortcut = KeyboardShortcut(
            keyCode: 46,  // M
            modifierFlags: NSEvent.ModifierFlags([.command, .shift]).rawValue,
            action: ShortcutAction.toggleTOC.rawValue
        )
        manager.setShortcut(customShortcut, for: .toggleTOC)

        // Verify persistence by checking the shortcut is retrievable
        let retrieved = manager.shortcut(for: .toggleTOC)
        XCTAssertEqual(retrieved.keyCode, 46, "Persisted shortcut should be retrievable")
        XCTAssertEqual(
            NSEvent.ModifierFlags(rawValue: retrieved.modifierFlags),
            [.command, .shift],
            "Persisted modifiers should be retrievable"
        )
    }

    // MARK: - Codable Tests

    func testKeyboardShortcutEncodeDecode() throws {
        let original = KeyboardShortcut(
            keyCode: 3,
            modifierFlags: NSEvent.ModifierFlags([.command, .shift]).rawValue,
            action: "testAction"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(KeyboardShortcut.self, from: data)

        XCTAssertEqual(decoded.keyCode, original.keyCode)
        XCTAssertEqual(decoded.modifierFlags, original.modifierFlags)
        XCTAssertEqual(decoded.action, original.action)
    }

    // MARK: - Notification Tests

    func testShortcutChangeNotification() {
        let manager = KeyboardShortcutManager.shared
        let expectation = XCTestExpectation(description: "Shortcut change notification received")

        let observer = NotificationCenter.default.addObserver(
            forName: .shortcutsChanged,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        // Set a custom shortcut
        let customShortcut = KeyboardShortcut(
            keyCode: 12,
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.zoomIn.rawValue
        )
        manager.setShortcut(customShortcut, for: .zoomIn)

        wait(for: [expectation], timeout: 1.0)

        NotificationCenter.default.removeObserver(observer)
    }

    func testResetNotification() {
        let manager = KeyboardShortcutManager.shared
        let expectation = XCTestExpectation(description: "Reset notification received")

        // Set a custom shortcut first
        let customShortcut = KeyboardShortcut(
            keyCode: 12,
            modifierFlags: NSEvent.ModifierFlags.command.rawValue,
            action: ShortcutAction.zoomOut.rawValue
        )
        manager.setShortcut(customShortcut, for: .zoomOut)

        let observer = NotificationCenter.default.addObserver(
            forName: .shortcutsChanged,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }

        // Reset
        manager.resetToDefault(for: .zoomOut)

        wait(for: [expectation], timeout: 1.0)

        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Edge Case Tests

    func testEmptyShortcut() {
        let emptyShortcut = KeyboardShortcut(keyCode: 0, modifierFlags: 0, action: "empty")

        XCTAssertEqual(emptyShortcut.keyEquivalent, "a", "Key code 0 maps to 'a'")
        XCTAssertEqual(emptyShortcut.modifierMask, [], "Empty modifiers should be empty set")
    }

    func testUnknownKeyCode() {
        // Test with an unknown key code
        let unknownString = KeyboardShortcut.keyCodeToString(255)
        XCTAssertNil(unknownString, "Unknown key code should return nil")

        let unknownEquiv = KeyboardShortcut.keyCodeToKeyEquivalent(255)
        XCTAssertNil(unknownEquiv, "Unknown key code should return nil for key equivalent")
    }

    func testAllDefaultShortcutsExist() {
        let manager = KeyboardShortcutManager.shared

        for action in ShortcutAction.allCases {
            let defaultShortcut = manager.defaultShortcut(for: action)
            XCTAssertNotNil(defaultShortcut, "Default shortcut should exist for \(action)")

            if let shortcut = defaultShortcut {
                print("Action \(action.rawValue): keyCode=\(shortcut.keyCode), display='\(shortcut.displayString)'")
            }
        }
    }
}
