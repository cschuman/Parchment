import Foundation

/// Represents a saved reading position for a document
struct ReadingPosition: Codable {
    let urlString: String  // Store as string for reliable encoding
    let scrollPercentage: Double
    let lastAccessed: Date

    var url: URL? {
        URL(string: urlString)
    }

    init(url: URL, scrollPercentage: Double) {
        self.urlString = url.absoluteString
        self.scrollPercentage = scrollPercentage
        self.lastAccessed = Date()
    }
}

/// Manages reading positions for documents with LRU eviction
final class ReadingPositionManager {

    // MARK: - Configuration

    private enum Configuration {
        static let maxPositions = 100
        static let userDefaultsKey = "ReadingPositions"
    }

    // MARK: - Singleton

    static let shared = ReadingPositionManager()

    // MARK: - Properties

    private var positions: [String: ReadingPosition] = [:]

    // MARK: - Initialization

    private init() {
        loadPositions()
    }

    // MARK: - Public Interface

    /// Save scroll position for a document
    func save(url: URL, percentage: Double) {
        // Don't save if at the very top (0-1%)
        guard percentage > 0.01 else {
            positions.removeValue(forKey: url.absoluteString)
            savePositions()
            return
        }

        let position = ReadingPosition(url: url, scrollPercentage: percentage)
        positions[url.absoluteString] = position

        // LRU eviction if over limit
        evictOldestIfNeeded()

        savePositions()
    }

    /// Get saved position for a document
    func position(for url: URL) -> Double? {
        guard let position = positions[url.absoluteString] else {
            return nil
        }

        // Update last accessed time
        positions[url.absoluteString] = ReadingPosition(
            url: url,
            scrollPercentage: position.scrollPercentage
        )

        return position.scrollPercentage
    }

    /// Remove position for a document
    func removePosition(for url: URL) {
        positions.removeValue(forKey: url.absoluteString)
        savePositions()
    }

    /// Clear all positions
    func clearAll() {
        positions.removeAll()
        savePositions()
    }

    // MARK: - Private Implementation

    private func loadPositions() {
        guard let data = UserDefaults.standard.data(forKey: Configuration.userDefaultsKey),
              let decoded = try? JSONDecoder().decode([String: ReadingPosition].self, from: data) else {
            return
        }
        positions = decoded
    }

    private func savePositions() {
        guard let data = try? JSONEncoder().encode(positions) else {
            Logger.warning("Failed to encode reading positions")
            return
        }
        UserDefaults.standard.set(data, forKey: Configuration.userDefaultsKey)
    }

    private func evictOldestIfNeeded() {
        guard positions.count > Configuration.maxPositions else { return }

        // Sort by last accessed date, oldest first
        let sorted = positions.sorted { $0.value.lastAccessed < $1.value.lastAccessed }

        // Remove oldest entries until we're at the limit
        let toRemove = positions.count - Configuration.maxPositions
        for i in 0..<toRemove {
            positions.removeValue(forKey: sorted[i].key)
        }
    }
}
