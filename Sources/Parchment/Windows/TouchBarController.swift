import Cocoa

// MARK: - Touch Bar Identifiers

@available(macOS 10.12.2, *)
private extension NSTouchBarItem.Identifier {
    static let themeSelector = NSTouchBarItem.Identifier("com.parchment.touchbar.themeSelector")
    static let navigation = NSTouchBarItem.Identifier("com.parchment.touchbar.navigation")
    static let zoomControls = NSTouchBarItem.Identifier("com.parchment.touchbar.zoom")
    static let focusMode = NSTouchBarItem.Identifier("com.parchment.touchbar.focusMode")
    static let themeGroup = NSTouchBarItem.Identifier("com.parchment.touchbar.themeGroup")
}

@available(macOS 10.12.2, *)
private extension NSTouchBar.CustomizationIdentifier {
    static let parchmentBar = NSTouchBar.CustomizationIdentifier("com.parchment.touchbar")
}

// MARK: - Touch Bar Controller

@available(macOS 10.12.2, *)
final class TouchBarController: NSObject, NSTouchBarDelegate {

    // MARK: - Properties

    weak var windowController: MainWindowController?

    private var currentThemeIndex: Int = 0
    private var zoomLevel: CGFloat = 1.0

    // MARK: - Initialization

    init(windowController: MainWindowController) {
        self.windowController = windowController
        super.init()

        // Update current theme index
        if let index = ParchmentTheme.all.firstIndex(where: { $0.name == ParchmentTheme.current.name }) {
            currentThemeIndex = index
        }
    }

    // MARK: - Touch Bar Creation

    func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .parchmentBar
        touchBar.defaultItemIdentifiers = [
            .themeGroup,
            .flexibleSpace,
            .navigation,
            .flexibleSpace,
            .zoomControls,
            .focusMode
        ]
        touchBar.customizationAllowedItemIdentifiers = [
            .themeGroup,
            .navigation,
            .zoomControls,
            .focusMode,
            .flexibleSpace
        ]
        return touchBar
    }

    // MARK: - NSTouchBarDelegate

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case .themeGroup:
            return makeThemeGroupItem(identifier: identifier)

        case .navigation:
            return makeNavigationItem(identifier: identifier)

        case .zoomControls:
            return makeZoomItem(identifier: identifier)

        case .focusMode:
            return makeFocusModeItem(identifier: identifier)

        default:
            return nil
        }
    }

    // MARK: - Item Creation

    private func makeThemeGroupItem(identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: identifier)

        let scrubber = NSScrubber()
        scrubber.delegate = self
        scrubber.dataSource = self
        scrubber.mode = .free
        scrubber.selectionBackgroundStyle = .roundedBackground
        scrubber.showsArrowButtons = true

        let layout = NSScrubberFlowLayout()
        layout.itemSize = NSSize(width: 80, height: 30)
        scrubber.scrubberLayout = layout

        scrubber.register(NSScrubberTextItemView.self, forItemIdentifier: NSUserInterfaceItemIdentifier("ThemeItem"))

        item.view = scrubber
        item.customizationLabel = "Themes"

        return item
    }

    private func makeNavigationItem(identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: identifier)

        let segmentedControl = NSSegmentedControl(images: [
            NSImage(systemSymbolName: "chevron.up", accessibilityDescription: "Previous")!,
            NSImage(systemSymbolName: "chevron.down", accessibilityDescription: "Next")!
        ], trackingMode: .momentary, target: self, action: #selector(navigationPressed(_:)))

        segmentedControl.segmentStyle = .separated
        item.view = segmentedControl
        item.customizationLabel = "Navigation"

        return item
    }

    private func makeZoomItem(identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: identifier)

        let segmentedControl = NSSegmentedControl(images: [
            NSImage(systemSymbolName: "minus.magnifyingglass", accessibilityDescription: "Zoom Out")!,
            NSImage(systemSymbolName: "plus.magnifyingglass", accessibilityDescription: "Zoom In")!
        ], trackingMode: .momentary, target: self, action: #selector(zoomPressed(_:)))

        segmentedControl.segmentStyle = .separated
        item.view = segmentedControl
        item.customizationLabel = "Zoom"

        return item
    }

    private func makeFocusModeItem(identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: identifier)

        let button = NSButton(
            image: NSImage(systemSymbolName: "eye", accessibilityDescription: "Focus Mode")!,
            target: self,
            action: #selector(focusModePressed(_:))
        )
        button.bezelColor = nil

        item.view = button
        item.customizationLabel = "Focus Mode"

        return item
    }

    // MARK: - Actions

    @objc private func navigationPressed(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            windowController?.jumpToPreviousHeader()
        } else {
            windowController?.jumpToNextHeader()
        }
    }

    @objc private func zoomPressed(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            windowController?.adjustZoom(delta: -0.1)
        } else {
            windowController?.adjustZoom(delta: 0.1)
        }
    }

    @objc private func focusModePressed(_ sender: NSButton) {
        windowController?.toggleFocusMode()
    }
}

// MARK: - NSScrubberDataSource

@available(macOS 10.12.2, *)
extension TouchBarController: NSScrubberDataSource {
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return ParchmentTheme.all.count
    }

    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        let itemView = scrubber.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("ThemeItem"), owner: nil) as? NSScrubberTextItemView ?? NSScrubberTextItemView()

        let theme = ParchmentTheme.all[index]
        itemView.textField.stringValue = theme.name
        itemView.textField.font = NSFont.systemFont(ofSize: 12)

        return itemView
    }
}

// MARK: - NSScrubberDelegate

@available(macOS 10.12.2, *)
extension TouchBarController: NSScrubberDelegate {
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt selectedIndex: Int) {
        guard selectedIndex >= 0 && selectedIndex < ParchmentTheme.all.count else { return }

        currentThemeIndex = selectedIndex
        let theme = ParchmentTheme.all[selectedIndex]
        ParchmentTheme.current = theme
    }
}
