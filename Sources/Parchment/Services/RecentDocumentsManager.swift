import Foundation

/// Manages recently opened documents with persistence
final class RecentDocumentsManager {

    // MARK: - Configuration

    private enum Configuration {
        static let maxRecentDocuments = 10
        static let userDefaultsKey = "RecentDocuments"
    }

    // MARK: - Properties

    private(set) var recentDocuments: [URL] = []

    /// Callback when recent documents list changes
    var onDocumentsChanged: (() -> Void)?

    // MARK: - Initialization

    init() {
        loadRecentDocuments()
    }

    // MARK: - Public Interface

    /// Add a document to the recent documents list
    func addDocument(_ url: URL) {
        recentDocuments.removeAll { $0 == url }
        recentDocuments.insert(url, at: 0)

        if recentDocuments.count > Configuration.maxRecentDocuments {
            recentDocuments.removeLast()
        }

        saveRecentDocuments()
        onDocumentsChanged?()
    }

    /// Clear all recent documents
    func clearAll() {
        recentDocuments.removeAll()
        saveRecentDocuments()
        onDocumentsChanged?()
    }

    /// Remove a specific document from recent list
    func removeDocument(_ url: URL) {
        recentDocuments.removeAll { $0 == url }
        saveRecentDocuments()
        onDocumentsChanged?()
    }

    /// Persist recent documents to disk
    func persist() {
        saveRecentDocuments()
    }

    // MARK: - Private Implementation

    private func loadRecentDocuments() {
        guard let data = UserDefaults.standard.data(forKey: Configuration.userDefaultsKey),
              let urls = try? JSONDecoder().decode([URL].self, from: data) else {
            return
        }
        recentDocuments = urls
    }

    private func saveRecentDocuments() {
        guard let data = try? JSONEncoder().encode(recentDocuments) else {
            Logger.warning("Failed to encode recent documents")
            return
        }
        UserDefaults.standard.set(data, forKey: Configuration.userDefaultsKey)
        UserDefaults.standard.synchronize()
    }
}
