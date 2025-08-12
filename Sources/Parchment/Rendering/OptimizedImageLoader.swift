import Cocoa
import CoreImage
import Accelerate
import os.log

private let imageLog = OSLog(subsystem: "com.markdownviewer", category: "ImageLoading")

final class OptimizedImageLoader {
    static let shared = OptimizedImageLoader()
    
    private let loadingQueue = OperationQueue()
    private let imageCache = NSCache<NSString, NSImage>()
    private let placeholderCache = NSCache<NSString, NSImage>()
    private let thumbnailCache = NSCache<NSString, NSImage>()
    
    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .priorityRequestLow: false
    ])
    
    private var loadingTasks: [URL: URLSessionDataTask] = [:]
    
    init() {
        loadingQueue.maxConcurrentOperationCount = 4
        loadingQueue.qualityOfService = .userInitiated
        
        imageCache.countLimit = 50
        imageCache.totalCostLimit = 100 * 1024 * 1024
        
        placeholderCache.countLimit = 100
        thumbnailCache.countLimit = 100
    }
    
    func loadImage(
        from url: URL,
        targetSize: CGSize? = nil,
        placeholder: @escaping (NSImage) -> Void,
        progress: @escaping (Double) -> Void,
        completion: @escaping (NSImage?) -> Void
    ) {
        let cacheKey = url.absoluteString as NSString
        
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            os_log(.debug, log: imageLog, "Image cache hit: %@", url.lastPathComponent)
            completion(cachedImage)
            return
        }
        
        let blurhash = generateBlurhash(for: url)
        let placeholderImage = createBeautifulPlaceholder(
            size: targetSize ?? CGSize(width: 400, height: 300),
            blurhash: blurhash
        )
        placeholder(placeholderImage)
        
        if url.isFileURL {
            loadLocalImage(from: url, targetSize: targetSize, completion: completion)
        } else {
            loadRemoteImage(from: url, targetSize: targetSize, progress: progress, completion: completion)
        }
    }
    
    private func loadLocalImage(
        from url: URL,
        targetSize: CGSize?,
        completion: @escaping (NSImage?) -> Void
    ) {
        loadingQueue.addOperation { [weak self] in
            guard let self = self else { return }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            guard let image = NSImage(contentsOf: url) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let processedImage: NSImage
            if let targetSize = targetSize {
                processedImage = self.resizeImageWithQuality(image, to: targetSize)
            } else {
                processedImage = image
            }
            
            let loadTime = CFAbsoluteTimeGetCurrent() - startTime
            os_log(.debug, log: imageLog, "Local image loaded in %.2fms", loadTime * 1000)
            
            self.imageCache.setObject(processedImage, forKey: url.absoluteString as NSString)
            
            DispatchQueue.main.async {
                completion(processedImage)
            }
        }
    }
    
    private func loadRemoteImage(
        from url: URL,
        targetSize: CGSize?,
        progress: @escaping (Double) -> Void,
        completion: @escaping (NSImage?) -> Void
    ) {
        if let existingTask = loadingTasks[url] {
            existingTask.cancel()
        }
        
        var receivedData = Data()
        var expectedLength: Int64 = 0
        
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            self.loadingTasks.removeValue(forKey: url)
            
            guard error == nil,
                  let data = data,
                  let image = NSImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let processedImage: NSImage
            if let targetSize = targetSize {
                processedImage = self.resizeImageWithQuality(image, to: targetSize)
            } else {
                processedImage = image
            }
            
            self.imageCache.setObject(
                processedImage,
                forKey: url.absoluteString as NSString,
                cost: data.count
            )
            
            DispatchQueue.main.async {
                completion(processedImage)
            }
        }
        
        loadingTasks[url] = task
        task.resume()
    }
    
    private func createBeautifulPlaceholder(size: CGSize, blurhash: String?) -> NSImage {
        let cacheKey = "\(size.width)x\(size.height)-\(blurhash ?? "default")" as NSString
        
        if let cached = placeholderCache.object(forKey: cacheKey) {
            return cached
        }
        
        let placeholder = NSImage(size: size)
        placeholder.lockFocus()
        
        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.95, green: 0.95, blue: 0.96, alpha: 1.0),
            NSColor(calibratedRed: 0.92, green: 0.92, blue: 0.94, alpha: 1.0)
        ])
        
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: -45)
        
        let shimmerLayer = CAGradientLayer()
        shimmerLayer.frame = CGRect(origin: .zero, size: size)
        shimmerLayer.colors = [
            NSColor.white.withAlphaComponent(0).cgColor,
            NSColor.white.withAlphaComponent(0.3).cgColor,
            NSColor.white.withAlphaComponent(0).cgColor
        ]
        shimmerLayer.locations = [0, 0.5, 1]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        shimmerLayer.add(animation, forKey: "shimmer")
        
        let iconSize: CGFloat = min(size.width, size.height) * 0.15
        let iconRect = NSRect(
            x: (size.width - iconSize) / 2,
            y: (size.height - iconSize) / 2,
            width: iconSize,
            height: iconSize
        )
        
        NSColor.white.withAlphaComponent(0.5).setFill()
        let path = NSBezierPath(roundedRect: iconRect, xRadius: iconSize * 0.1, yRadius: iconSize * 0.1)
        path.fill()
        
        let imageIcon = NSBezierPath()
        let mountainPath = NSBezierPath()
        mountainPath.move(to: NSPoint(x: iconRect.minX + iconSize * 0.2, y: iconRect.minY + iconSize * 0.7))
        mountainPath.line(to: NSPoint(x: iconRect.minX + iconSize * 0.4, y: iconRect.minY + iconSize * 0.3))
        mountainPath.line(to: NSPoint(x: iconRect.minX + iconSize * 0.6, y: iconRect.minY + iconSize * 0.5))
        mountainPath.line(to: NSPoint(x: iconRect.minX + iconSize * 0.8, y: iconRect.minY + iconSize * 0.2))
        mountainPath.line(to: NSPoint(x: iconRect.maxX, y: iconRect.minY + iconSize * 0.7))
        mountainPath.lineWidth = 2
        NSColor.white.withAlphaComponent(0.7).setStroke()
        mountainPath.stroke()
        
        let sunRect = NSRect(
            x: iconRect.minX + iconSize * 0.65,
            y: iconRect.minY + iconSize * 0.15,
            width: iconSize * 0.15,
            height: iconSize * 0.15
        )
        let sunPath = NSBezierPath(ovalIn: sunRect)
        NSColor.white.withAlphaComponent(0.7).setFill()
        sunPath.fill()
        
        placeholder.unlockFocus()
        
        placeholderCache.setObject(placeholder, forKey: cacheKey)
        
        return placeholder
    }
    
    private func resizeImageWithQuality(_ image: NSImage, to targetSize: CGSize) -> NSImage {
        let aspectRatio = image.size.width / image.size.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        var newSize = targetSize
        if aspectRatio > targetAspectRatio {
            newSize.height = targetSize.width / aspectRatio
        } else {
            newSize.width = targetSize.height * aspectRatio
        }
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        
        NSGraphicsContext.current?.imageInterpolation = .high
        
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        
        newImage.unlockFocus()
        
        return newImage
    }
    
    private func generateBlurhash(for url: URL) -> String? {
        return nil
    }
    
    func createThumbnail(for image: NSImage, size: CGSize) -> NSImage {
        let cacheKey = "\(image.hash)-\(size.width)x\(size.height)" as NSString
        
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let ciImage = CIImage(bitmapImageRep: bitmap) else {
            return image
        }
        
        let scale = min(size.width / image.size.width, size.height / image.size.height)
        
        let filter = CIFilter(name: "CILanczosScaleTransform")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(scale, forKey: kCIInputScaleKey)
        filter?.setValue(1.0, forKey: kCIInputAspectRatioKey)
        
        guard let outputImage = filter?.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        let thumbnail = NSImage(cgImage: cgImage, size: size)
        thumbnailCache.setObject(thumbnail, forKey: cacheKey)
        
        return thumbnail
    }
    
    func cancelLoading(for url: URL) {
        loadingTasks[url]?.cancel()
        loadingTasks.removeValue(forKey: url)
    }
    
    func preloadImages(urls: [URL], priority: Operation.QueuePriority = .low) {
        for url in urls {
            let operation = BlockOperation { [weak self] in
                let semaphore = DispatchSemaphore(value: 0)
                
                self?.loadImage(
                    from: url,
                    placeholder: { _ in },
                    progress: { _ in },
                    completion: { _ in
                        semaphore.signal()
                    }
                )
                
                _ = semaphore.wait(timeout: .now() + 10)
            }
            
            operation.queuePriority = priority
            loadingQueue.addOperation(operation)
        }
    }
    
    func clearCache() {
        imageCache.removeAllObjects()
        placeholderCache.removeAllObjects()
        thumbnailCache.removeAllObjects()
    }
    
    var cacheSize: Int {
        // Return approximate cache size (can't get exact from NSCache)
        return 0
    }
}

class AnimatedImageView: NSImageView {
    private var isLoading = false
    private var progressLayer: CAShapeLayer?
    private var shimmerLayer: CAGradientLayer?
    
    func setImage(from url: URL, targetSize: CGSize? = nil) {
        startLoadingAnimation()
        
        OptimizedImageLoader.shared.loadImage(
            from: url,
            targetSize: targetSize ?? bounds.size,
            placeholder: { [weak self] placeholder in
                DispatchQueue.main.async {
                    self?.image = placeholder
                }
            },
            progress: { [weak self] progress in
                DispatchQueue.main.async {
                    self?.updateProgress(progress)
                }
            },
            completion: { [weak self] image in
                DispatchQueue.main.async {
                    self?.stopLoadingAnimation()
                    if let image = image {
                        self?.crossfadeToImage(image)
                    }
                }
            }
        )
    }
    
    private func startLoadingAnimation() {
        isLoading = true
        
        shimmerLayer = CAGradientLayer()
        shimmerLayer?.frame = bounds
        shimmerLayer?.colors = [
            NSColor.clear.cgColor,
            NSColor.white.withAlphaComponent(0.3).cgColor,
            NSColor.clear.cgColor
        ]
        shimmerLayer?.locations = [0, 0.5, 1]
        shimmerLayer?.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer?.endPoint = CGPoint(x: 1, y: 0.5)
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        
        shimmerLayer?.add(animation, forKey: "shimmer")
        layer?.addSublayer(shimmerLayer!)
    }
    
    private func stopLoadingAnimation() {
        isLoading = false
        shimmerLayer?.removeFromSuperlayer()
        progressLayer?.removeFromSuperlayer()
    }
    
    private func updateProgress(_ progress: Double) {
        
    }
    
    private func crossfadeToImage(_ newImage: NSImage) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().alphaValue = 0
        } completionHandler: {
            self.image = newImage
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                self.animator().alphaValue = 1
            }
        }
    }
}