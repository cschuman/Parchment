import Foundation

/// Caches recently viewed documents with their scroll position and zoom level
final class DocumentCache {
    static let shared = DocumentCache()

    private let cache = NSCache<NSString, CachedDocumentWrapper>()
    private let metadataQueue = DispatchQueue(label: "document.cache.metadata", attributes: .concurrent)
    private var documentPaths: Set<String> = []  // Track keys for iteration

    private static let maxCacheCount = 10
    private static let maxCacheCost = 100 * 1024 * 1024  // 100MB total cost limit
    private static let persistenceKey = "DocumentCacheMetadata"

    /// Private init enforces singleton pattern - use DocumentCache.shared
    private init() {
        cache.countLimit = Self.maxCacheCount
        cache.totalCostLimit = Self.maxCacheCost
        restoreMetadata()
    }

    // MARK: - Cache Entry

    /// Wrapper class to store struct in NSCache
    private class CachedDocumentWrapper {
        let document: MarkdownDocument
        let rendered: NSAttributedString?
        let scrollPosition: CGPoint
        let zoomLevel: CGFloat
        let timestamp: Date

        init(document: MarkdownDocument, rendered: NSAttributedString?, scrollPosition: CGPoint, zoomLevel: CGFloat, timestamp: Date) {
            self.document = document
            self.rendered = rendered
            self.scrollPosition = scrollPosition
            self.zoomLevel = zoomLevel
            self.timestamp = timestamp
        }
    }

    /// Public-facing struct for cache entries
    struct CachedDocument {
        let document: MarkdownDocument
        let rendered: NSAttributedString?
        let scrollPosition: CGPoint
        let zoomLevel: CGFloat
        let timestamp: Date
    }

    // MARK: - Public Interface

    func cacheDocument(_ document: MarkdownDocument, rendered: NSAttributedString? = nil, scrollPosition: CGPoint = .zero, zoomLevel: CGFloat = 1.0) {
        guard let url = document.url else { return }

        let wrapper = CachedDocumentWrapper(
            document: document,
            rendered: rendered,
            scrollPosition: scrollPosition,
            zoomLevel: zoomLevel,
            timestamp: Date()
        )

        // Estimate cost based on content size (document + rendered if present)
        let contentCost = document.content.utf8.count
        let renderedCost = rendered?.length ?? 0
        let totalCost = contentCost + (renderedCost * 2)  // Attributed strings use ~2 bytes per character

        cache.setObject(wrapper, forKey: url.path as NSString, cost: totalCost)

        metadataQueue.async(flags: .barrier) { [weak self] in
            self?.documentPaths.insert(url.path)
        }
    }

    func getCachedDocument(for url: URL) -> CachedDocument? {
        guard let wrapper = cache.object(forKey: url.path as NSString) else {
            return nil
        }

        return CachedDocument(
            document: wrapper.document,
            rendered: wrapper.rendered,
            scrollPosition: wrapper.scrollPosition,
            zoomLevel: wrapper.zoomLevel,
            timestamp: wrapper.timestamp
        )
    }

    func updateScrollPosition(for url: URL, position: CGPoint) {
        guard let existing = cache.object(forKey: url.path as NSString) else { return }

        let updated = CachedDocumentWrapper(
            document: existing.document,
            rendered: existing.rendered,
            scrollPosition: position,
            zoomLevel: existing.zoomLevel,
            timestamp: Date()
        )

        // Preserve estimated cost
        let contentCost = existing.document.content.utf8.count
        let renderedCost = existing.rendered?.length ?? 0
        let totalCost = contentCost + (renderedCost * 2)

        cache.setObject(updated, forKey: url.path as NSString, cost: totalCost)
    }

    func updateZoomLevel(for url: URL, zoomLevel: CGFloat) {
        guard let existing = cache.object(forKey: url.path as NSString) else { return }

        let updated = CachedDocumentWrapper(
            document: existing.document,
            rendered: existing.rendered,
            scrollPosition: existing.scrollPosition,
            zoomLevel: zoomLevel,
            timestamp: Date()
        )

        // Preserve estimated cost
        let contentCost = existing.document.content.utf8.count
        let renderedCost = existing.rendered?.length ?? 0
        let totalCost = contentCost + (renderedCost * 2)

        cache.setObject(updated, forKey: url.path as NSString, cost: totalCost)
    }

    func removeDocument(for url: URL) {
        cache.removeObject(forKey: url.path as NSString)

        metadataQueue.async(flags: .barrier) { [weak self] in
            self?.documentPaths.remove(url.path)
        }
    }

    func clearCache() {
        cache.removeAllObjects()

        metadataQueue.async(flags: .barrier) { [weak self] in
            self?.documentPaths.removeAll()
        }
    }

    // MARK: - Persistence

    /// Persists scroll positions and zoom levels (not document content)
    func persistMetadata() {
        var metadata: [String: [String: Any]] = [:]

        metadataQueue.sync {
            for path in documentPaths {
                if let wrapper = cache.object(forKey: path as NSString) {
                    metadata[path] = [
                        "scrollX": wrapper.scrollPosition.x,
                        "scrollY": wrapper.scrollPosition.y,
                        "zoomLevel": wrapper.zoomLevel,
                        "timestamp": wrapper.timestamp.timeIntervalSince1970
                    ]
                }
            }
        }

        UserDefaults.standard.set(metadata, forKey: Self.persistenceKey)
    }

    private func restoreMetadata() {
        guard let metadata = UserDefaults.standard.dictionary(forKey: Self.persistenceKey) as? [String: [String: Any]] else {
            return
        }

        // Metadata is restored, but documents will be loaded lazily when accessed
        // We only persist scroll positions and zoom levels, not the actual content
        for (path, _) in metadata {
            documentPaths.insert(path)
        }
    }

    /// Returns persisted metadata for a file path (used when reopening documents)
    func getPersistedMetadata(for path: String) -> (scrollPosition: CGPoint, zoomLevel: CGFloat)? {
        guard let metadata = UserDefaults.standard.dictionary(forKey: Self.persistenceKey) as? [String: [String: Any]],
              let entry = metadata[path] else {
            return nil
        }

        let scrollX = entry["scrollX"] as? CGFloat ?? 0
        let scrollY = entry["scrollY"] as? CGFloat ?? 0
        let zoomLevel = entry["zoomLevel"] as? CGFloat ?? 1.0

        return (CGPoint(x: scrollX, y: scrollY), zoomLevel)
    }
}
