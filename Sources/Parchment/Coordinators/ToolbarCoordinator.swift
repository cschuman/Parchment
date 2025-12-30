import Cocoa

/// Protocol for toolbar action callbacks
protocol ToolbarActionDelegate: AnyObject {
    func toggleFocusMode()
    func toggleTableOfContents()
    func showReadingStatistics()
}

/// Coordinates toolbar creation and item handling
final class ToolbarCoordinator: NSObject, NSToolbarDelegate {

    weak var actionDelegate: ToolbarActionDelegate?

    func createToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = true
        return toolbar
    }

    // MARK: - NSToolbarDelegate

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        switch itemIdentifier {
        case .focusMode:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Focus Mode"
            item.toolTip = "Toggle Focus Mode - Dims surrounding text"
            item.image = NSImage(systemSymbolName: "circle.dashed", accessibilityDescription: "Focus Mode")
            item.action = #selector(handleFocusMode)
            item.target = self
            return item

        case .tableOfContents:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Contents"
            item.toolTip = "Toggle Table of Contents"
            item.image = NSImage(systemSymbolName: "list.bullet.indent", accessibilityDescription: "Table of Contents")
            item.action = #selector(handleTableOfContents)
            item.target = self
            return item

        case .readingStats:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Statistics"
            item.toolTip = "Show Reading Statistics"
            item.image = NSImage(systemSymbolName: "chart.bar", accessibilityDescription: "Statistics")
            item.action = #selector(handleReadingStats)
            item.target = self
            return item

        default:
            return nil
        }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.focusMode, .tableOfContents, .flexibleSpace, .readingStats]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.focusMode, .tableOfContents, .readingStats, .flexibleSpace]
    }

    // MARK: - Action Handlers

    @objc private func handleFocusMode() {
        actionDelegate?.toggleFocusMode()
    }

    @objc private func handleTableOfContents() {
        actionDelegate?.toggleTableOfContents()
    }

    @objc private func handleReadingStats() {
        actionDelegate?.showReadingStatistics()
    }
}

// MARK: - Toolbar Item Identifiers

extension NSToolbarItem.Identifier {
    static let focusMode = NSToolbarItem.Identifier("FocusMode")
    static let tableOfContents = NSToolbarItem.Identifier("TableOfContents")
    static let readingStats = NSToolbarItem.Identifier("ReadingStats")
}
