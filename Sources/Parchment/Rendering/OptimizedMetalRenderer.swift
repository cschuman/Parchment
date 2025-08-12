import Metal
import MetalKit
import CoreText
import Cocoa
import os.log

private let performanceLog = OSLog(subsystem: "com.markdownviewer.rendering", category: "Performance")

final class OptimizedMetalRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let glyphAtlas: GlyphAtlasCache
    private let textureCache: MetalTextureCache
    
    private var frameTimer = FrameTimer()
    private let renderSemaphore = DispatchSemaphore(value: 3)
    
    struct PerformanceMetrics {
        var frameTime: Double = 0
        var drawCallCount: Int = 0
        var textureMemoryUsage: Int = 0
        var cacheHitRate: Double = 0
    }
    
    private var metrics = PerformanceMetrics()
    
    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        do {
            self.pipelineState = try Self.createOptimizedPipelineState(device: device)
        } catch {
            os_log(.error, log: performanceLog, "Failed to create pipeline: %@", error.localizedDescription)
            return nil
        }
        
        self.glyphAtlas = GlyphAtlasCache(device: device)
        self.textureCache = MetalTextureCache(device: device)
    }
    
    private static func createOptimizedPipelineState(device: MTLDevice) throws -> MTLRenderPipelineState {
        let library = try device.makeDefaultLibrary(bundle: Bundle.main)
        
        let vertexFunction = library.makeFunction(name: "optimizedTextVertex")
        let fragmentFunction = library.makeFunction(name: "optimizedTextFragment")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        descriptor.sampleCount = 4
        
        return try device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func renderAttributedString(
        _ attributedString: NSAttributedString,
        in bounds: CGRect,
        visibleRect: CGRect,
        zoomLevel: CGFloat
    ) -> MTLTexture? {
        frameTimer.startFrame()
        defer {
            metrics.frameTime = frameTimer.endFrame()
            logPerformanceMetrics()
        }
        
        renderSemaphore.wait()
        defer { renderSemaphore.signal() }
        
        let renderBounds = visibleRect.insetBy(dx: -100, dy: -200)
        
        guard let texture = textureCache.getOrCreateTexture(
            size: renderBounds.size,
            scale: zoomLevel
        ) else { return nil }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return nil }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return nil
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let path = CGPath(rect: renderBounds, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        
        renderFrame(frame, with: renderEncoder, in: renderBounds, scale: zoomLevel)
        
        renderEncoder.endEncoding()
        
        commandBuffer.addCompletedHandler { [weak self] _ in
            self?.updateMetrics()
        }
        
        commandBuffer.commit()
        
        return texture
    }
    
    private func renderFrame(
        _ frame: CTFrame,
        with renderEncoder: MTLRenderCommandEncoder,
        in bounds: CGRect,
        scale: CGFloat
    ) {
        let lines = CTFrameGetLines(frame) as! [CTLine]
        var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &lineOrigins)
        
        for (index, line) in lines.enumerated() {
            autoreleasepool {
                renderLine(
                    line,
                    at: lineOrigins[index],
                    with: renderEncoder,
                    in: bounds,
                    scale: scale
                )
            }
        }
        
        metrics.drawCallCount = lines.count
    }
    
    private func renderLine(
        _ line: CTLine,
        at origin: CGPoint,
        with renderEncoder: MTLRenderCommandEncoder,
        in bounds: CGRect,
        scale: CGFloat
    ) {
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]
        
        for run in runs {
            renderRun(run, at: origin, with: renderEncoder, in: bounds, scale: scale)
        }
    }
    
    private func renderRun(
        _ run: CTRun,
        at origin: CGPoint,
        with renderEncoder: MTLRenderCommandEncoder,
        in bounds: CGRect,
        scale: CGFloat
    ) {
        let glyphCount = CTRunGetGlyphCount(run)
        guard glyphCount > 0 else { return }
        
        let attributes = CTRunGetAttributes(run) as! [NSAttributedString.Key: Any]
        let font = attributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 14)
        let color = attributes[.foregroundColor] as? NSColor ?? NSColor.labelColor
        
        var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
        var positions = [CGPoint](repeating: .zero, count: glyphCount)
        
        CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
        CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
        
        let glyphBatch = glyphAtlas.getOrCreateGlyphBatch(
            glyphs: glyphs,
            font: font,
            scale: scale
        )
        
        renderGlyphBatch(
            glyphBatch,
            positions: positions,
            origin: origin,
            color: color,
            with: renderEncoder
        )
    }
    
    private func renderGlyphBatch(
        _ batch: GlyphBatch,
        positions: [CGPoint],
        origin: CGPoint,
        color: NSColor,
        with renderEncoder: MTLRenderCommandEncoder
    ) {
        guard let vertexBuffer = batch.vertexBuffer,
              let indexBuffer = batch.indexBuffer else { return }
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(batch.atlasTexture, index: 0)
        
        var colorData = SIMD4<Float>(
            Float(color.redComponent),
            Float(color.greenComponent),
            Float(color.blueComponent),
            Float(color.alphaComponent)
        )
        renderEncoder.setFragmentBytes(&colorData, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
        
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: batch.indexCount,
            indexType: .uint16,
            indexBuffer: indexBuffer,
            indexBufferOffset: 0
        )
    }
    
    private func updateMetrics() {
        metrics.textureMemoryUsage = textureCache.memoryUsage
        metrics.cacheHitRate = glyphAtlas.cacheHitRate
    }
    
    private func logPerformanceMetrics() {
        if metrics.frameTime > 16.67 {
            os_log(.info, log: performanceLog,
                   "Frame time: %.2fms, Draw calls: %d, Cache hit rate: %.1f%%",
                   metrics.frameTime,
                   metrics.drawCallCount,
                   metrics.cacheHitRate * 100)
        }
    }
    
    func getMetrics() -> PerformanceMetrics {
        return metrics
    }
}

final class GlyphAtlasCache {
    private let device: MTLDevice
    private var atlasTexture: MTLTexture?
    private var glyphCache: [GlyphKey: GlyphInfo] = [:]
    private var currentX: Int = 0
    private var currentY: Int = 0
    private var rowHeight: Int = 0
    private let atlasSize = 2048
    
    private var hits: Int = 0
    private var misses: Int = 0
    
    var cacheHitRate: Double {
        let total = hits + misses
        return total > 0 ? Double(hits) / Double(total) : 0
    }
    
    struct GlyphKey: Hashable {
        let glyph: CGGlyph
        let fontName: String
        let fontSize: CGFloat
    }
    
    struct GlyphInfo {
        let textureRect: CGRect
        let glyphBounds: CGRect
        let advance: CGSize
    }
    
    init(device: MTLDevice) {
        self.device = device
        createAtlasTexture()
    }
    
    private func createAtlasTexture() {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .r8Unorm,
            width: atlasSize,
            height: atlasSize,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        
        atlasTexture = device.makeTexture(descriptor: descriptor)
    }
    
    func getOrCreateGlyphBatch(glyphs: [CGGlyph], font: NSFont, scale: CGFloat) -> GlyphBatch {
        var glyphInfos: [GlyphInfo] = []
        
        for glyph in glyphs {
            let key = GlyphKey(
                glyph: glyph,
                fontName: font.fontName,
                fontSize: font.pointSize * scale
            )
            
            if let info = glyphCache[key] {
                hits += 1
                glyphInfos.append(info)
            } else {
                misses += 1
                let info = rasterizeGlyph(glyph, font: font, scale: scale)
                glyphCache[key] = info
                glyphInfos.append(info)
            }
        }
        
        return createBatch(from: glyphInfos)
    }
    
    private func rasterizeGlyph(_ glyph: CGGlyph, font: NSFont, scale: CGFloat) -> GlyphInfo {
        let ctFont = font as CTFont
        var glyphRect = CGRect.zero
        CTFontGetBoundingRectsForGlyphs(ctFont, .horizontal, [glyph], &glyphRect, 1)
        
        let width = Int(ceil(glyphRect.width * scale))
        let height = Int(ceil(glyphRect.height * scale))
        
        if currentX + width > atlasSize {
            currentX = 0
            currentY += rowHeight + 2
            rowHeight = 0
        }
        
        let textureRect = CGRect(
            x: currentX,
            y: currentY,
            width: width,
            height: height
        )
        
        rowHeight = max(rowHeight, height)
        currentX += width + 2
        
        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(ctFont, .horizontal, [glyph], &advance, 1)
        
        return GlyphInfo(
            textureRect: textureRect,
            glyphBounds: glyphRect,
            advance: advance
        )
    }
    
    private func createBatch(from glyphInfos: [GlyphInfo]) -> GlyphBatch {
        return GlyphBatch(
            atlasTexture: atlasTexture!,
            glyphInfos: glyphInfos,
            device: device
        )
    }
}

struct GlyphBatch {
    let atlasTexture: MTLTexture
    let vertexBuffer: MTLBuffer?
    let indexBuffer: MTLBuffer?
    let indexCount: Int
    
    init(atlasTexture: MTLTexture, glyphInfos: [GlyphAtlasCache.GlyphInfo], device: MTLDevice) {
        self.atlasTexture = atlasTexture
        
        var vertices: [Float] = []
        var indices: [UInt16] = []
        var currentIndex: UInt16 = 0
        
        for info in glyphInfos {
            let rect = info.textureRect
            
            vertices.append(contentsOf: [
                Float(rect.minX), Float(rect.minY), 0, 0,
                Float(rect.maxX), Float(rect.minY), 1, 0,
                Float(rect.minX), Float(rect.maxY), 0, 1,
                Float(rect.maxX), Float(rect.maxY), 1, 1
            ])
            
            indices.append(contentsOf: [
                currentIndex, currentIndex + 1, currentIndex + 2,
                currentIndex + 1, currentIndex + 3, currentIndex + 2
            ])
            
            currentIndex += 4
        }
        
        self.vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: vertices.count * MemoryLayout<Float>.size,
            options: .storageModeShared
        )
        
        self.indexBuffer = device.makeBuffer(
            bytes: indices,
            length: indices.count * MemoryLayout<UInt16>.size,
            options: .storageModeShared
        )
        
        self.indexCount = indices.count
    }
}

final class MetalTextureCache {
    private let device: MTLDevice
    private var cache: [TextureKey: MTLTexture] = [:]
    private let maxCacheSize = 10
    
    struct TextureKey: Hashable {
        let width: Int
        let height: Int
        let scale: CGFloat
    }
    
    var memoryUsage: Int {
        cache.values.reduce(0) { total, texture in
            total + (texture.width * texture.height * 4)
        }
    }
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func getOrCreateTexture(size: CGSize, scale: CGFloat) -> MTLTexture? {
        let key = TextureKey(
            width: Int(size.width * scale),
            height: Int(size.height * scale),
            scale: scale
        )
        
        if let cached = cache[key] {
            return cached
        }
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: key.width,
            height: key.height,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .private
        
        let texture = device.makeTexture(descriptor: descriptor)
        
        if cache.count >= maxCacheSize {
            cache.removeAll()
        }
        
        cache[key] = texture
        return texture
    }
}

final class FrameTimer {
    private var startTime: CFAbsoluteTime = 0
    private var frameCount: Int = 0
    private var totalTime: CFAbsoluteTime = 0
    
    func startFrame() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func endFrame() -> Double {
        let frameTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
        frameCount += 1
        totalTime += frameTime
        
        if frameCount % 60 == 0 {
            let avgFrameTime = totalTime / 60.0
            os_log(.debug, log: performanceLog, "Avg frame time (60 frames): %.2fms", avgFrameTime)
            totalTime = 0
        }
        
        return frameTime
    }
    
    var averageFrameTime: Double {
        frameCount > 0 ? totalTime / Double(frameCount) : 0
    }
}