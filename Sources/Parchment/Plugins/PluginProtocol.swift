import Foundation
import Cocoa
import MarkdownKit

/// Protocol that all plugins must conform to
public protocol MarkdownPlugin: AnyObject {
    
    /// Unique identifier for the plugin
    var identifier: String { get }
    
    /// Display name of the plugin
    var name: String { get }
    
    /// Version of the plugin
    var version: String { get }
    
    /// Description of what the plugin does
    var description: String { get }
    
    /// Author of the plugin
    var author: String { get }
    
    /// Whether the plugin is currently enabled
    var isEnabled: Bool { get set }
    
    /// Called when the plugin is loaded
    func pluginDidLoad()
    
    /// Called when the plugin is enabled
    func pluginDidEnable()
    
    /// Called when the plugin is disabled
    func pluginDidDisable()
    
    /// Called when the plugin is about to be unloaded
    func pluginWillUnload()
    
    /// Configure the plugin with settings
    func configure(settings: [String: Any])
    
    /// Get current configuration
    func getConfiguration() -> [String: Any]
}

/// Plugin capabilities
public protocol MarkdownParserPlugin: MarkdownPlugin {
    /// Process markdown before parsing
    func preprocessMarkdown(_ markdown: String) -> String
    
    /// Process parsed document after parsing
    func postprocessDocument(_ document: MarkdownKit.Block) -> MarkdownKit.Block
}

public protocol MarkdownRendererPlugin: MarkdownPlugin {
    /// Customize rendering of specific block types
    func renderBlock(_ block: MarkdownKit.Block, defaultRenderer: (MarkdownKit.Block) -> NSAttributedString?) -> NSAttributedString?
    
    /// Post-process rendered attributed string
    func postprocessRendered(_ attributedString: NSAttributedString) -> NSAttributedString
}

public protocol MarkdownExporterPlugin: MarkdownPlugin {
    /// Supported export formats
    var supportedFormats: [String] { get }
    
    /// Export document to specified format
    func exportDocument(_ document: MarkdownKit.Block, toFormat format: String) -> Data?
}

public protocol MarkdownCompletionPlugin: MarkdownPlugin {
    /// Provide completions at cursor position
    func completions(for text: String, at range: NSRange) -> [CompletionItem]
}

public protocol MarkdownActionPlugin: MarkdownPlugin {
    /// Menu items provided by the plugin
    var menuItems: [PluginMenuItem] { get }
    
    /// Toolbar items provided by the plugin
    var toolbarItems: [PluginToolbarItem] { get }
    
    /// Keyboard shortcuts
    var keyboardShortcuts: [PluginKeyboardShortcut] { get }
}

/// Completion item for autocomplete
public struct CompletionItem {
    public let text: String
    public let displayText: String
    public let detail: String?
    public let icon: NSImage?
    
    public init(text: String, displayText: String, detail: String? = nil, icon: NSImage? = nil) {
        self.text = text
        self.displayText = displayText
        self.detail = detail
        self.icon = icon
    }
}

/// Plugin menu item
public struct PluginMenuItem {
    public let title: String
    public let action: Selector
    public let keyEquivalent: String
    public let keyModifiers: NSEvent.ModifierFlags
    
    public init(title: String, action: Selector, keyEquivalent: String = "", keyModifiers: NSEvent.ModifierFlags = []) {
        self.title = title
        self.action = action
        self.keyEquivalent = keyEquivalent
        self.keyModifiers = keyModifiers
    }
}

/// Plugin toolbar item
public struct PluginToolbarItem {
    public let identifier: String
    public let label: String
    public let icon: NSImage?
    public let action: Selector
    
    public init(identifier: String, label: String, icon: NSImage? = nil, action: Selector) {
        self.identifier = identifier
        self.label = label
        self.icon = icon
        self.action = action
    }
}

/// Plugin keyboard shortcut
public struct PluginKeyboardShortcut {
    public let key: String
    public let modifiers: NSEvent.ModifierFlags
    public let action: Selector
    
    public init(key: String, modifiers: NSEvent.ModifierFlags, action: Selector) {
        self.key = key
        self.modifiers = modifiers
        self.action = action
    }
}

/// Base class for plugins with default implementations
open class BaseMarkdownPlugin: MarkdownPlugin {
    public let identifier: String
    public let name: String
    public let version: String
    public let description: String
    public let author: String
    public var isEnabled: Bool = false
    
    private var configuration: [String: Any] = [:]
    
    public init(identifier: String, name: String, version: String, description: String, author: String) {
        self.identifier = identifier
        self.name = name
        self.version = version
        self.description = description
        self.author = author
    }
    
    open func pluginDidLoad() {
        // Override in subclass
    }
    
    open func pluginDidEnable() {
        isEnabled = true
    }
    
    open func pluginDidDisable() {
        isEnabled = false
    }
    
    open func pluginWillUnload() {
        // Override in subclass
    }
    
    open func configure(settings: [String: Any]) {
        configuration = settings
    }
    
    open func getConfiguration() -> [String: Any] {
        return configuration
    }
}