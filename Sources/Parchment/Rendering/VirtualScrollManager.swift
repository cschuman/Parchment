import Foundation
import Cocoa

/// Manages virtual scrolling for large documents by only rendering visible content
class VirtualScrollManager {
    private var totalLines: Int = 0
    private var lineHeights: [CGFloat] = []
    private var documentHeight: CGFloat = 0
    private var averageLineHeight: CGFloat = 20.0
    private var visibleRange: NSRange = NSRange(location: 0, length: 0)
    private var renderBuffer: Int = 50 // Extra lines to render above/below viewport
    
    // Cache for rendered chunks
    private var chunkCache: [Int: NSAttributedString] = [:]
    private let chunkSize = 100 // Lines per chunk
    private let maxCachedChunks = 20
    
    // Performance tracking
    private var lastRenderTime: TimeInterval = 0
    private var cacheHits: Int = 0
    private var cacheMisses: Int = 0
    
    /// Initialize with document content
    func prepareDocument(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        totalLines = lines.count
        
        // Estimate line heights initially (will refine as we render)
        lineHeights = Array(repeating: averageLineHeight, count: totalLines)
        documentHeight = CGFloat(totalLines) * averageLineHeight
        
        // Clear cache when document changes
        chunkCache.removeAll()
        cacheHits = 0
        cacheMisses = 0
    }
    
    /// Calculate which lines should be rendered based on scroll position
    func calculateVisibleRange(scrollY: CGFloat, viewportHeight: CGFloat) -> NSRange {
        // Find first visible line
        var currentY: CGFloat = 0
        var startLine = 0
        
        for (index, height) in lineHeights.enumerated() {
            if currentY + height > scrollY {
                startLine = max(0, index - renderBuffer)
                break
            }
            currentY += height
        }
        
        // Find last visible line
        let bottomY = scrollY + viewportHeight
        var endLine = startLine
        
        for index in startLine..<totalLines {
            if currentY > bottomY + (CGFloat(renderBuffer) * averageLineHeight) {
                endLine = index
                break
            }
            currentY += lineHeights[index]
        }
        
        if endLine == startLine {
            endLine = min(totalLines, startLine + Int(viewportHeight / averageLineHeight) + renderBuffer * 2)
        }
        
        let length = endLine - startLine
        visibleRange = NSRange(location: startLine, length: length)
        
        return visibleRange
    }
    
    /// Get the chunk index for a given line
    private func chunkIndex(for line: Int) -> Int {
        return line / chunkSize
    }
    
    /// Render only the visible portion of the document
    func renderVisibleContent(_ content: String, range: NSRange, renderBlock: (String) -> NSAttributedString) -> NSAttributedString {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let lines = content.components(separatedBy: .newlines)
        let result = NSMutableAttributedString()
        
        // Add spacer for content above visible range
        if range.location > 0 {
            let spacerHeight = lineHeights[0..<range.location].reduce(0, +)
            let spacer = NSAttributedString(string: "\n", attributes: [
                .font: NSFont.systemFont(ofSize: 1),
                .paragraphStyle: { () -> NSParagraphStyle in
                    let style = NSMutableParagraphStyle()
                    style.minimumLineHeight = spacerHeight
                    style.maximumLineHeight = spacerHeight
                    return style
                }()
            ])
            result.append(spacer)
        }
        
        // Render visible lines using chunks
        let startChunk = chunkIndex(for: range.location)
        let endChunk = chunkIndex(for: NSMaxRange(range) - 1)
        
        for chunk in startChunk...endChunk {
            if let cachedChunk = chunkCache[chunk] {
                result.append(cachedChunk)
                cacheHits += 1
            } else {
                // Render this chunk
                let chunkStart = chunk * chunkSize
                let chunkEnd = min((chunk + 1) * chunkSize, totalLines)
                let chunkLines = lines[chunkStart..<chunkEnd]
                let chunkContent = chunkLines.joined(separator: "\n")
                
                let rendered = renderBlock(chunkContent)
                chunkCache[chunk] = rendered
                result.append(rendered)
                
                cacheMisses += 1
                
                // Maintain cache size
                if chunkCache.count > maxCachedChunks {
                    evictOldestChunk()
                }
            }
        }
        
        // Add spacer for content below visible range
        let endLine = NSMaxRange(range)
        if endLine < totalLines {
            let spacerHeight = lineHeights[endLine..<totalLines].reduce(0, +)
            let spacer = NSAttributedString(string: "\n", attributes: [
                .font: NSFont.systemFont(ofSize: 1),
                .paragraphStyle: { () -> NSParagraphStyle in
                    let style = NSMutableParagraphStyle()
                    style.minimumLineHeight = spacerHeight
                    style.maximumLineHeight = spacerHeight
                    return style
                }()
            ])
            result.append(spacer)
        }
        
        lastRenderTime = CFAbsoluteTimeGetCurrent() - startTime
        
        return result
    }
    
    /// Update actual line heights after rendering
    func updateLineHeights(_ heights: [CGFloat], startingAt line: Int) {
        for (index, height) in heights.enumerated() {
            let lineIndex = line + index
            if lineIndex < lineHeights.count {
                lineHeights[lineIndex] = height
            }
        }
        
        // Recalculate document height
        documentHeight = lineHeights.reduce(0, +)
        
        // Update average for better estimates
        averageLineHeight = documentHeight / CGFloat(totalLines)
    }
    
    /// Evict the oldest chunk from cache
    private func evictOldestChunk() {
        // Simple strategy: remove chunks furthest from current visible range
        let centerLine = visibleRange.location + visibleRange.length / 2
        let centerChunk = chunkIndex(for: centerLine)
        
        var furthestChunk: Int?
        var maxDistance = 0
        
        for chunk in chunkCache.keys {
            let distance = abs(chunk - centerChunk)
            if distance > maxDistance {
                maxDistance = distance
                furthestChunk = chunk
            }
        }
        
        if let chunkToRemove = furthestChunk {
            chunkCache.removeValue(forKey: chunkToRemove)
        }
    }
    
    /// Get performance metrics
    func getMetrics() -> (renderTime: TimeInterval, cacheHitRate: Double) {
        let total = cacheHits + cacheMisses
        let hitRate = total > 0 ? Double(cacheHits) / Double(total) : 0
        return (lastRenderTime, hitRate)
    }
    
    /// Prefetch chunks near the visible range
    func prefetchNearbyChunks(_ content: String, renderBlock: @escaping (String) -> NSAttributedString) {
        let centerChunk = chunkIndex(for: visibleRange.location + visibleRange.length / 2)
        let prefetchRange = (centerChunk - 2)...(centerChunk + 2)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let lines = content.components(separatedBy: .newlines)
            
            for chunk in prefetchRange {
                if chunk >= 0 && chunk < (self.totalLines / self.chunkSize) {
                    if self.chunkCache[chunk] == nil {
                        let chunkStart = chunk * self.chunkSize
                        let chunkEnd = min((chunk + 1) * self.chunkSize, self.totalLines)
                        
                        if chunkStart < lines.count && chunkEnd <= lines.count {
                            let chunkLines = lines[chunkStart..<chunkEnd]
                            let chunkContent = chunkLines.joined(separator: "\n")
                            
                            let rendered = renderBlock(chunkContent)
                            
                            DispatchQueue.main.async {
                                if self.chunkCache[chunk] == nil {
                                    self.chunkCache[chunk] = rendered
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Clear all caches
    func clearCache() {
        chunkCache.removeAll()
        cacheHits = 0
        cacheMisses = 0
    }
}

// MARK: - Viewport Tracker

class ViewportTracker {
    private var scrollView: NSScrollView
    private var lastScrollPosition: CGPoint = .zero
    private var scrollVelocity: CGFloat = 0
    private var lastScrollTime: TimeInterval = 0
    
    init(scrollView: NSScrollView) {
        self.scrollView = scrollView
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidScroll),
            name: NSScrollView.didLiveScrollNotification,
            object: scrollView
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidEndScrolling),
            name: NSScrollView.didEndLiveScrollNotification,
            object: scrollView
        )
    }
    
    @objc private func scrollViewDidScroll(_ notification: Notification) {
        let currentPosition = scrollView.contentView.bounds.origin
        let currentTime = CACurrentMediaTime()
        
        if lastScrollTime > 0 {
            let timeDelta = currentTime - lastScrollTime
            let positionDelta = currentPosition.y - lastScrollPosition.y
            scrollVelocity = abs(positionDelta / CGFloat(timeDelta))
        }
        
        lastScrollPosition = currentPosition
        lastScrollTime = currentTime
    }
    
    @objc private func scrollViewDidEndScrolling(_ notification: Notification) {
        scrollVelocity = 0
    }
    
    /// Get current scroll metrics
    func getScrollMetrics() -> (position: CGPoint, velocity: CGFloat, isScrolling: Bool) {
        return (lastScrollPosition, scrollVelocity, scrollVelocity > 0)
    }
    
    /// Predict where scroll will end based on velocity
    func predictScrollDestination() -> CGFloat {
        guard scrollVelocity > 0 else { return lastScrollPosition.y }
        
        // Simple deceleration model
        let deceleration: CGFloat = 1000.0 // pixels/second²
        let timeToStop = scrollVelocity / deceleration
        let distance = (scrollVelocity * timeToStop) - (0.5 * deceleration * timeToStop * timeToStop)
        
        return lastScrollPosition.y + distance
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}