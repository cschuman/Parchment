import Foundation
import Cocoa
import os.log
import QuartzCore

private let perfLog = OSLog(subsystem: "com.markdownviewer", category: "Performance")

final class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    struct Metrics {
        var fps: Double = 0
        var frameTime: Double = 0
        var cpuUsage: Double = 0
        var memoryUsage: Int64 = 0
        var cacheHitRate: Double = 0
        var renderTime: Double = 0
        var parseTime: Double = 0
        var scrollPerformance: ScrollMetrics = ScrollMetrics()
    }
    
    struct ScrollMetrics {
        var isSmooth: Bool = true
        var droppedFrames: Int = 0
        var averageVelocity: Double = 0
        var jankEvents: Int = 0
    }
    
    private var displayLink: CVDisplayLink?
    private var frameCount: Int = 0
    private var lastFrameTime: CFAbsoluteTime = 0
    private var metrics = Metrics()
    private var metricsCallbacks: [(Metrics) -> Void] = []
    
    private let metricsQueue = DispatchQueue(label: "com.markdownviewer.metrics", qos: .utility)
    private var frameTimeBuffer: [Double] = []
    private let maxBufferSize = 120
    
    private init() {
        setupDisplayLink()
        startCPUMonitoring()
        startMemoryMonitoring()
    }
    
    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        
        guard let displayLink = displayLink else { return }
        
        CVDisplayLinkSetOutputCallback(displayLink, { (_, _, _, _, _, userInfo) -> CVReturn in
            let monitor = Unmanaged<PerformanceMonitor>.fromOpaque(userInfo!).takeUnretainedValue()
            monitor.updateFrameMetrics()
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        
        CVDisplayLinkStart(displayLink)
    }
    
    private func updateFrameMetrics() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        
        if lastFrameTime > 0 {
            let frameTime = (currentTime - lastFrameTime) * 1000.0
            
            metricsQueue.async { [weak self] in
                guard let self = self else { return }
                
                self.frameTimeBuffer.append(frameTime)
                if self.frameTimeBuffer.count > self.maxBufferSize {
                    self.frameTimeBuffer.removeFirst()
                }
                
                self.metrics.frameTime = frameTime
                self.metrics.fps = 1000.0 / frameTime
                
                if frameTime > 20.0 {
                    self.metrics.scrollPerformance.droppedFrames += 1
                    os_log(.info, log: perfLog, "Dropped frame detected: %.2fms", frameTime)
                }
                
                if frameTime > 33.0 {
                    self.metrics.scrollPerformance.jankEvents += 1
                    self.metrics.scrollPerformance.isSmooth = false
                }
                
                self.frameCount += 1
                if self.frameCount % 60 == 0 {
                    self.calculateAverageMetrics()
                    self.notifyCallbacks()
                }
            }
        }
        
        lastFrameTime = currentTime
    }
    
    private func calculateAverageMetrics() {
        guard !frameTimeBuffer.isEmpty else { return }
        
        let averageFrameTime = frameTimeBuffer.reduce(0, +) / Double(frameTimeBuffer.count)
        metrics.fps = 1000.0 / averageFrameTime
        
        let variance = frameTimeBuffer.map { pow($0 - averageFrameTime, 2) }.reduce(0, +) / Double(frameTimeBuffer.count)
        let standardDeviation = sqrt(variance)
        
        metrics.scrollPerformance.isSmooth = standardDeviation < 5.0 && averageFrameTime < 18.0
        
        if !metrics.scrollPerformance.isSmooth {
            os_log(.default, log: perfLog,
                   "Performance degradation: Avg frame time: %.2fms, StdDev: %.2f",
                   averageFrameTime, standardDeviation)
        }
    }
    
    private func startCPUMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCPUUsage()
        }
    }
    
    private func updateCPUUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            metrics.cpuUsage = Double(info.resident_size) / Double(1024 * 1024)
        }
    }
    
    private func startMemoryMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            metrics.memoryUsage = Int64(info.resident_size)
            
            if metrics.memoryUsage > 500 * 1024 * 1024 {
                os_log(.default, log: perfLog,
                       "High memory usage: %d MB",
                       metrics.memoryUsage / (1024 * 1024))
            }
        }
    }
    
    func trackRenderTime(_ time: TimeInterval) {
        metricsQueue.async { [weak self] in
            self?.metrics.renderTime = time * 1000.0
            
            if time > 0.1 {
                os_log(.info, log: perfLog, "Slow render: %.2fms", time * 1000.0)
            }
        }
    }
    
    func trackParseTime(_ time: TimeInterval) {
        metricsQueue.async { [weak self] in
            self?.metrics.parseTime = time * 1000.0
            
            if time > 0.05 {
                os_log(.info, log: perfLog, "Slow parse: %.2fms", time * 1000.0)
            }
        }
    }
    
    func trackCacheHitRate(_ rate: Double) {
        metricsQueue.async { [weak self] in
            self?.metrics.cacheHitRate = rate
        }
    }
    
    func trackScrollVelocity(_ velocity: CGFloat) {
        metricsQueue.async { [weak self] in
            self?.metrics.scrollPerformance.averageVelocity = Double(abs(velocity))
        }
    }
    
    func resetScrollMetrics() {
        metricsQueue.async { [weak self] in
            self?.metrics.scrollPerformance = ScrollMetrics()
        }
    }
    
    func addMetricsCallback(_ callback: @escaping (Metrics) -> Void) {
        metricsQueue.async { [weak self] in
            self?.metricsCallbacks.append(callback)
        }
    }
    
    private func notifyCallbacks() {
        let currentMetrics = metrics
        DispatchQueue.main.async { [weak self] in
            self?.metricsCallbacks.forEach { $0(currentMetrics) }
        }
    }
    
    func getCurrentMetrics() -> Metrics {
        return metrics
    }
    
    func getCacheHitRate() -> Double {
        return metrics.cacheHitRate
    }
    
    func getAverageRenderTime() -> TimeInterval {
        return metrics.renderTime
    }
    
    func generatePerformanceReport() -> String {
        let report = """
        === Performance Report ===
        FPS: \(String(format: "%.1f", metrics.fps))
        Frame Time: \(String(format: "%.2fms", metrics.frameTime))
        CPU Usage: \(String(format: "%.1f%%", metrics.cpuUsage))
        Memory: \(metrics.memoryUsage / (1024 * 1024)) MB
        Cache Hit Rate: \(String(format: "%.1f%%", metrics.cacheHitRate * 100))
        Render Time: \(String(format: "%.2fms", metrics.renderTime))
        Parse Time: \(String(format: "%.2fms", metrics.parseTime))
        
        Scroll Performance:
        - Smooth: \(metrics.scrollPerformance.isSmooth ? "Yes" : "No")
        - Dropped Frames: \(metrics.scrollPerformance.droppedFrames)
        - Jank Events: \(metrics.scrollPerformance.jankEvents)
        =======================
        """
        
        return report
    }
    
    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }
}

class PerformanceOverlayView: NSView {
    private var metricsLabel: NSTextField!
    private var fpsGraph: FPSGraphView!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
        startMonitoring()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        startMonitoring()
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        layer?.cornerRadius = 8
        
        metricsLabel = NSTextField(labelWithString: "")
        metricsLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        metricsLabel.textColor = NSColor.green
        metricsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(metricsLabel)
        
        fpsGraph = FPSGraphView()
        fpsGraph.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fpsGraph)
        
        NSLayoutConstraint.activate([
            metricsLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            metricsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            metricsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            
            fpsGraph.topAnchor.constraint(equalTo: metricsLabel.bottomAnchor, constant: 10),
            fpsGraph.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            fpsGraph.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            fpsGraph.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            fpsGraph.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func startMonitoring() {
        PerformanceMonitor.shared.addMetricsCallback { [weak self] metrics in
            self?.updateMetrics(metrics)
        }
    }
    
    private func updateMetrics(_ metrics: PerformanceMonitor.Metrics) {
        let text = """
        FPS: \(String(format: "%.1f", metrics.fps))
        Frame: \(String(format: "%.2fms", metrics.frameTime))
        Memory: \(metrics.memoryUsage / (1024 * 1024)) MB
        Cache: \(String(format: "%.0f%%", metrics.cacheHitRate * 100))
        """
        
        metricsLabel.stringValue = text
        fpsGraph.addFPSValue(metrics.fps)
        
        metricsLabel.textColor = metrics.fps < 30 ? .systemRed :
                                 metrics.fps < 50 ? .systemYellow : .systemGreen
    }
}

class FPSGraphView: NSView {
    private var fpsValues: [Double] = []
    private let maxValues = 60
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard !fpsValues.isEmpty else { return }
        
        let path = NSBezierPath()
        path.lineWidth = 1.0
        
        for (index, fps) in fpsValues.enumerated() {
            let x = CGFloat(index) * (bounds.width / CGFloat(maxValues))
            let y = CGFloat(fps / 60.0) * bounds.height
            
            if index == 0 {
                path.move(to: NSPoint(x: x, y: y))
            } else {
                path.line(to: NSPoint(x: x, y: y))
            }
        }
        
        NSColor.systemGreen.withAlphaComponent(0.8).setStroke()
        path.stroke()
        
        let targetLine = NSBezierPath()
        targetLine.move(to: NSPoint(x: 0, y: bounds.height))
        targetLine.line(to: NSPoint(x: bounds.width, y: bounds.height))
        targetLine.lineWidth = 0.5
        targetLine.setLineDash([2, 2], count: 2, phase: 0)
        NSColor.systemGreen.withAlphaComponent(0.3).setStroke()
        targetLine.stroke()
    }
    
    func addFPSValue(_ fps: Double) {
        fpsValues.append(fps)
        if fpsValues.count > maxValues {
            fpsValues.removeFirst()
        }
        needsDisplay = true
    }
}