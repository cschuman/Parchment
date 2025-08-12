import Foundation
import Cocoa
import MarkdownKit

/// Manages loading and lifecycle of plugins
class PluginManager {
    
    static let shared = PluginManager()
    
    /// All loaded plugins
    private var plugins: [String: MarkdownPlugin] = [:]
    
    /// Plugin load order
    private var pluginOrder: [String] = []
    
    /// Plugin state persistence
    private let stateKey = "PluginStates"
    
    /// Plugin directories
    private var pluginDirectories: [URL] = []
    
    /// Notification for plugin events
    static let pluginDidLoadNotification = Notification.Name("PluginDidLoad")
    static let pluginDidUnloadNotification = Notification.Name("PluginDidUnload")
    static let pluginDidEnableNotification = Notification.Name("PluginDidEnable")
    static let pluginDidDisableNotification = Notification.Name("PluginDidDisable")
    
    init() {
        setupPluginDirectories()
        loadPluginStates()
    }
    
    private func setupPluginDirectories() {
        // User plugins directory
        if let userPlugins = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Parchment")
            .appendingPathComponent("Plugins") {
            pluginDirectories.append(userPlugins)
            
            // Create directory if it doesn't exist
            try? FileManager.default.createDirectory(at: userPlugins, withIntermediateDirectories: true)
        }
        
        // Built-in plugins in app bundle
        if let builtInPlugins = Bundle.main.url(forResource: "Plugins", withExtension: nil) {
            pluginDirectories.append(builtInPlugins)
        }
    }
    
    private func loadPluginStates() {
        if let states = UserDefaults.standard.dictionary(forKey: stateKey) as? [String: Bool] {
            // States will be applied when plugins are loaded
        }
    }
    
    private func savePluginStates() {
        var states: [String: Bool] = [:]
        for (identifier, plugin) in plugins {
            states[identifier] = plugin.isEnabled
        }
        UserDefaults.standard.set(states, forKey: stateKey)
    }
    
    // MARK: - Plugin Loading
    
    /// Load all plugins from plugin directories
    func loadAllPlugins() {
        // Ensure we don't double-load plugins
        guard plugins.isEmpty else { return }
        
        // Load built-in plugins first
        loadBuiltInPlugins()
        
        // Then load user plugins
        for directory in pluginDirectories {
            loadPluginsFromDirectory(directory)
        }
        
        // Apply saved states
        if let states = UserDefaults.standard.dictionary(forKey: stateKey) as? [String: Bool] {
            for (identifier, enabled) in states {
                if enabled, let _ = plugins[identifier] {
                    enablePlugin(identifier)
                }
            }
        }
    }
    
    private func loadBuiltInPlugins() {
        // Register built-in plugins
        registerPlugin(TableOfContentsPlugin())
        registerPlugin(WordCountPlugin())
        registerPlugin(EmojiPlugin())
        registerPlugin(SyntaxHighlightPlugin())
        registerPlugin(WikiLinkPlugin())
        registerPlugin(FootnotePlugin())
        registerPlugin(MermaidPlugin())
    }
    
    private func loadPluginsFromDirectory(_ directory: URL) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            for url in contents {
                if url.pathExtension == "mdplugin" {
                    loadPlugin(from: url)
                }
            }
        } catch {
            print("Failed to load plugins from \(directory): \(error)")
        }
    }
    
    private func loadPlugin(from url: URL) {
        // For dynamic plugins, we'd need to:
        // 1. Load the bundle
        // 2. Find the principal class
        // 3. Instantiate and register
        // This requires more complex setup with dylibs/frameworks
        
        // For now, plugins are compiled into the app
    }
    
    /// Register a plugin
    func registerPlugin(_ plugin: MarkdownPlugin) {
        plugins[plugin.identifier] = plugin
        pluginOrder.append(plugin.identifier)
        plugin.pluginDidLoad()
        
        NotificationCenter.default.post(
            name: PluginManager.pluginDidLoadNotification,
            object: plugin
        )
    }
    
    /// Unregister a plugin
    func unregisterPlugin(_ identifier: String) {
        guard let plugin = plugins[identifier] else { return }
        
        if plugin.isEnabled {
            disablePlugin(identifier)
        }
        
        plugin.pluginWillUnload()
        plugins.removeValue(forKey: identifier)
        pluginOrder.removeAll { $0 == identifier }
        
        NotificationCenter.default.post(
            name: PluginManager.pluginDidUnloadNotification,
            object: plugin
        )
    }
    
    // MARK: - Plugin State Management
    
    /// Enable a plugin
    func enablePlugin(_ identifier: String) {
        guard let plugin = plugins[identifier], !plugin.isEnabled else { return }
        
        plugin.pluginDidEnable()
        savePluginStates()
        
        NotificationCenter.default.post(
            name: PluginManager.pluginDidEnableNotification,
            object: plugin
        )
    }
    
    /// Disable a plugin
    func disablePlugin(_ identifier: String) {
        guard let plugin = plugins[identifier], plugin.isEnabled else { return }
        
        plugin.pluginDidDisable()
        savePluginStates()
        
        NotificationCenter.default.post(
            name: PluginManager.pluginDidDisableNotification,
            object: plugin
        )
    }
    
    /// Toggle plugin enabled state
    func togglePlugin(_ identifier: String) {
        guard let plugin = plugins[identifier] else { return }
        
        if plugin.isEnabled {
            disablePlugin(identifier)
        } else {
            enablePlugin(identifier)
        }
    }
    
    // MARK: - Plugin Access
    
    /// Get all plugins
    func getAllPlugins() -> [MarkdownPlugin] {
        return pluginOrder.compactMap { plugins[$0] }
    }
    
    /// Get enabled plugins
    func getEnabledPlugins() -> [MarkdownPlugin] {
        return getAllPlugins().filter { $0.isEnabled }
    }
    
    /// Get plugin by identifier
    func getPlugin(_ identifier: String) -> MarkdownPlugin? {
        return plugins[identifier]
    }
    
    /// Get plugins of specific type
    func getPlugins<T: MarkdownPlugin>(ofType type: T.Type) -> [T] {
        return getEnabledPlugins().compactMap { $0 as? T }
    }
    
    // MARK: - Plugin Processing
    
    /// Process markdown through parser plugins
    func preprocessMarkdown(_ markdown: String) -> String {
        var result = markdown
        
        for plugin in getEnabledPlugins().compactMap({ $0 as? MarkdownParserPlugin }) {
            result = plugin.preprocessMarkdown(result)
        }
        
        return result
    }
    
    /// Process document through parser plugins
    func postprocessDocument(_ document: MarkdownKit.Block) -> MarkdownKit.Block {
        var result = document
        
        for plugin in getEnabledPlugins().compactMap({ $0 as? MarkdownParserPlugin }) {
            result = plugin.postprocessDocument(result)
        }
        
        return result
    }
    
    /// Render block through renderer plugins
    func renderBlock(_ block: MarkdownKit.Block, defaultRenderer: (MarkdownKit.Block) -> NSAttributedString?) -> NSAttributedString? {
        for plugin in getEnabledPlugins().compactMap({ $0 as? MarkdownRendererPlugin }) {
            if let rendered = plugin.renderBlock(block, defaultRenderer: defaultRenderer) {
                return rendered
            }
        }
        
        return defaultRenderer(block)
    }
    
    /// Post-process rendered content
    func postprocessRendered(_ attributedString: NSAttributedString) -> NSAttributedString {
        var result = attributedString
        
        for plugin in getEnabledPlugins().compactMap({ $0 as? MarkdownRendererPlugin }) {
            result = plugin.postprocessRendered(result)
        }
        
        return result
    }
    
    /// Get completions from plugins
    func getCompletions(for text: String, at range: NSRange) -> [CompletionItem] {
        var completions: [CompletionItem] = []
        
        for plugin in getEnabledPlugins().compactMap({ $0 as? MarkdownCompletionPlugin }) {
            completions.append(contentsOf: plugin.completions(for: text, at: range))
        }
        
        return completions
    }
    
    /// Export document through plugins
    func exportDocument(_ document: MarkdownKit.Block, toFormat format: String) -> Data? {
        for plugin in getEnabledPlugins().compactMap({ $0 as? MarkdownExporterPlugin }) {
            if plugin.supportedFormats.contains(format),
               let data = plugin.exportDocument(document, toFormat: format) {
                return data
            }
        }
        
        return nil
    }
    
    /// Get all menu items from plugins
    func getPluginMenuItems() -> [(plugin: MarkdownPlugin, items: [PluginMenuItem])] {
        var result: [(plugin: MarkdownPlugin, items: [PluginMenuItem])] = []
        
        for plugin in getEnabledPlugins().compactMap({ $0 as? MarkdownActionPlugin }) {
            result.append((plugin, plugin.menuItems))
        }
        
        return result
    }
    
    /// Get all toolbar items from plugins
    func getPluginToolbarItems() -> [(plugin: MarkdownPlugin, items: [PluginToolbarItem])] {
        var result: [(plugin: MarkdownPlugin, items: [PluginToolbarItem])] = []
        
        for plugin in getEnabledPlugins().compactMap({ $0 as? MarkdownActionPlugin }) {
            result.append((plugin, plugin.toolbarItems))
        }
        
        return result
    }
}

// MARK: - Plugin Settings

extension PluginManager {
    
    /// Configure a plugin
    func configurePlugin(_ identifier: String, settings: [String: Any]) {
        guard let plugin = plugins[identifier] else { return }
        plugin.configure(settings: settings)
        
        // Save configuration
        var allConfigs = UserDefaults.standard.dictionary(forKey: "PluginConfigurations") ?? [:]
        allConfigs[identifier] = settings
        UserDefaults.standard.set(allConfigs, forKey: "PluginConfigurations")
    }
    
    /// Get plugin configuration
    func getPluginConfiguration(_ identifier: String) -> [String: Any]? {
        guard let plugin = plugins[identifier] else { return nil }
        return plugin.getConfiguration()
    }
    
    /// Load saved configurations
    private func loadPluginConfigurations() {
        guard let configs = UserDefaults.standard.dictionary(forKey: "PluginConfigurations") else { return }
        
        for (identifier, settings) in configs {
            if let plugin = plugins[identifier],
               let settings = settings as? [String: Any] {
                plugin.configure(settings: settings)
            }
        }
    }
}