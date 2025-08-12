import Metal
import MetalKit
import CoreText
import Cocoa

class MetalTextRenderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLRenderPipelineState
    private let textureCache: CVMetalTextureCache
    private var renderTargetTexture: MTLTexture?
    
    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        guard let cache = textureCache else { return nil }
        self.textureCache = cache
        
        do {
            self.pipelineState = try MetalTextRenderer.createPipelineState(device: device)
        } catch {
            print("Failed to create pipeline state: \(error)")
            return nil
        }
    }
    
    private static func createPipelineState(device: MTLDevice) throws -> MTLRenderPipelineState {
        let library = try device.makeDefaultLibrary(bundle: Bundle.main)
        
        let vertexFunction = library.makeFunction(name: "textVertexShader")
        let fragmentFunction = library.makeFunction(name: "textFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func renderAttributedString(
        _ attributedString: NSAttributedString,
        in bounds: CGRect,
        with context: CGContext
    ) {
        autoreleasepool {
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
            let path = CGPath(rect: bounds, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
            
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let texture = createTexture(size: bounds.size) else {
                CTFrameDraw(frame, context)
                return
            }
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                CTFrameDraw(frame, context)
                return
            }
            
            renderEncoder.setRenderPipelineState(pipelineState)
            
            let lines = CTFrameGetLines(frame) as! [CTLine]
            var lineOrigins = [CGPoint](repeating: .zero, count: lines.count)
            CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &lineOrigins)
            
            for (index, line) in lines.enumerated() {
                renderLine(line, at: lineOrigins[index], with: renderEncoder, in: bounds)
            }
            
            renderEncoder.endEncoding()
            
            if let drawable = createDrawable(from: texture, context: context) {
                commandBuffer.present(drawable)
            }
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            drawTexture(texture, to: context, in: bounds)
        }
    }
    
    private func createTexture(size: CGSize) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.storageMode = .managed
        
        return device.makeTexture(descriptor: textureDescriptor)
    }
    
    private func renderLine(
        _ line: CTLine,
        at origin: CGPoint,
        with renderEncoder: MTLRenderCommandEncoder,
        in bounds: CGRect
    ) {
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]
        
        for run in runs {
            let glyphCount = CTRunGetGlyphCount(run)
            guard glyphCount > 0 else { continue }
            
            var glyphs = [CGGlyph](repeating: 0, count: glyphCount)
            var positions = [CGPoint](repeating: .zero, count: glyphCount)
            
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
            
            let attributes = CTRunGetAttributes(run) as! [NSAttributedString.Key: Any]
            let font = attributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 14)
            let color = attributes[.foregroundColor] as? NSColor ?? NSColor.labelColor
            
            for i in 0..<glyphCount {
                let position = CGPoint(
                    x: origin.x + positions[i].x,
                    y: bounds.height - origin.y - positions[i].y
                )
                renderGlyph(glyphs[i], font: font, color: color, at: position, with: renderEncoder)
            }
        }
    }
    
    private func renderGlyph(
        _ glyph: CGGlyph,
        font: NSFont,
        color: NSColor,
        at position: CGPoint,
        with renderEncoder: MTLRenderCommandEncoder
    ) {
        
    }
    
    private func createDrawable(from texture: MTLTexture, context: CGContext) -> CAMetalDrawable? {
        return nil
    }
    
    private func drawTexture(_ texture: MTLTexture, to context: CGContext, in bounds: CGRect) {
        guard let cgImage = createCGImage(from: texture) else { return }
        context.draw(cgImage, in: bounds)
    }
    
    private func createCGImage(from texture: MTLTexture) -> CGImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4
        
        let data = UnsafeMutableRawPointer.allocate(byteCount: bytesPerRow * height, alignment: 1)
        defer { data.deallocate() }
        
        texture.getBytes(
            data,
            bytesPerRow: bytesPerRow,
            from: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                          size: MTLSize(width: width, height: height, depth: 1)),
            mipmapLevel: 0
        )
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        
        guard let dataProvider = CGDataProvider(dataInfo: nil,
                                                data: data,
                                                size: bytesPerRow * height,
                                                releaseData: { _, _, _ in }) else {
            return nil
        }
        
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}

class MetalTextView: NSView {
    private var renderer: MetalTextRenderer?
    private var displayLink: CVDisplayLink?
    private var attributedString: NSAttributedString?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupMetal()
        setupDisplayLink()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMetal()
        setupDisplayLink()
    }
    
    private func setupMetal() {
        renderer = MetalTextRenderer()
        wantsLayer = true
        layer?.isOpaque = false
    }
    
    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        
        guard let displayLink = displayLink else { return }
        
        CVDisplayLinkSetOutputCallback(displayLink, { (_, _, _, _, _, userInfo) -> CVReturn in
            let view = Unmanaged<MetalTextView>.fromOpaque(userInfo!).takeUnretainedValue()
            
            DispatchQueue.main.async {
                view.setNeedsDisplay(view.bounds)
            }
            
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        
        CVDisplayLinkStart(displayLink)
    }
    
    func setAttributedString(_ string: NSAttributedString) {
        attributedString = string
        setNeedsDisplay(bounds)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let attributedString = attributedString,
              let renderer = renderer else {
            super.draw(dirtyRect)
            return
        }
        
        renderer.renderAttributedString(attributedString, in: bounds, with: context)
    }
    
    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }
}