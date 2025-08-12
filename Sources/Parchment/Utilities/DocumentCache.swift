import Foundation

class DocumentCache {
    static let shared = DocumentCache()
    
    private var cache: [String: CachedDocument] = [:]
    private let maxCacheSize = 10
    private let cacheQueue = DispatchQueue(label: "document.cache", attributes: .concurrent)
    
    struct CachedDocument {
        let document: MarkdownDocument
        let rendered: NSAttributedString?
        let scrollPosition: CGPoint
        let zoomLevel: CGFloat
        let timestamp: Date
    }
    
    func cacheDocument(_ document: MarkdownDocument, rendered: NSAttributedString? = nil, scrollPosition: CGPoint = .zero, zoomLevel: CGFloat = 1.0) {
        guard let url = document.url else { return }
        
        let cached = CachedDocument(
            document: document,
            rendered: rendered,
            scrollPosition: scrollPosition,
            zoomLevel: zoomLevel,
            timestamp: Date()
        )
        
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.cache[url.path] = cached
            self?.evictOldestIfNeeded()
        }
    }
    
    func getCachedDocument(for url: URL) -> CachedDocument? {
        return cacheQueue.sync {
            cache[url.path]
        }
    }
    
    func updateScrollPosition(for url: URL, position: CGPoint) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            if var cached = self?.cache[url.path] {
                cached = CachedDocument(
                    document: cached.document,
                    rendered: cached.rendered,
                    scrollPosition: position,
                    zoomLevel: cached.zoomLevel,
                    timestamp: Date()
                )
                self?.cache[url.path] = cached
            }
        }
    }
    
    func updateZoomLevel(for url: URL, zoomLevel: CGFloat) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            if var cached = self?.cache[url.path] {
                cached = CachedDocument(
                    document: cached.document,
                    rendered: cached.rendered,
                    scrollPosition: cached.scrollPosition,
                    zoomLevel: zoomLevel,
                    timestamp: Date()
                )
                self?.cache[url.path] = cached
            }
        }
    }
    
    private func evictOldestIfNeeded() {
        guard cache.count > maxCacheSize else { return }
        
        let sorted = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        if let oldest = sorted.first {
            cache.removeValue(forKey: oldest.key)
        }
    }
    
    func persist() {
        let persistData = cache.compactMapValues { cached -> [String: Any] in
            return [
                "scrollX": cached.scrollPosition.x,
                "scrollY": cached.scrollPosition.y,
                "zoomLevel": cached.zoomLevel,
                "timestamp": cached.timestamp.timeIntervalSince1970
            ]
        }
        
        UserDefaults.standard.set(persistData, forKey: "DocumentCache")
    }
    
    func restore() {
        guard let persistData = UserDefaults.standard.dictionary(forKey: "DocumentCache") else { return }
        
    }
}