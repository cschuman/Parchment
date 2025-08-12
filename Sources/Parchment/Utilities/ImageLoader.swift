import Cocoa

class ImageLoader {
    static let shared = ImageLoader()
    
    private let session = URLSession.shared
    private var imageCache: [URL: NSImage] = [:]
    private let cacheQueue = DispatchQueue(label: "image.cache", attributes: .concurrent)
    
    private init() {}
    
    func loadImage(from url: URL) async -> NSImage? {
        if let cached = getCachedImage(for: url) {
            return cached
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            if let image = NSImage(data: data) {
                cacheImage(image, for: url)
                return image
            }
        } catch {
            print("Failed to load image from \(url): \(error)")
        }
        
        return nil
    }
    
    private func getCachedImage(for url: URL) -> NSImage? {
        return cacheQueue.sync {
            imageCache[url]
        }
    }
    
    private func cacheImage(_ image: NSImage, for url: URL) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.imageCache[url] = image
            
            if self?.imageCache.count ?? 0 > 50 {
                self?.imageCache.removeAll()
            }
        }
    }
}

class ImageCache {
    static let shared = ImageCache()
    
    private var cache: [String: NSImage] = [:]
    private let queue = DispatchQueue(label: "image.cache.local", attributes: .concurrent)
    
    private init() {}
    
    func get(_ key: String) -> NSImage? {
        return queue.sync {
            cache[key]
        }
    }
    
    func set(_ key: String, image: NSImage) {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache[key] = image
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
        }
    }
}