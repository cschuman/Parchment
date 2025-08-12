import Cocoa
import Foundation

class StatusBarView: NSView {
    private var statusLabel: NSTextField!
    private var performanceLabel: NSTextField!
    private var memoryLabel: NSTextField!
    private var systemLabel: NSTextField!
    
    private var updateTimer: Timer?
    private var frameRateMonitor: FrameRateMonitor?
    
    // Performance metrics
    private var lastParseTime: TimeInterval = 0
    private var lastRenderTime: TimeInterval = 0
    private var lastDrawTime: TimeInterval = 0
    private var currentFPS: Int = 0
    private var cacheHitRate: Double = 0
    
    // File metrics
    private var currentFilePath: String = ""
    private var fileSize: Int64 = 0
    private var lineCount: Int = 0
    private var wordCount: Int = 0
    
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
        layer?.backgroundColor = NSColor(white: 0.95, alpha: 1.0).cgColor
        
        // Create status sections
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 20
        stackView.edgeInsets = NSEdgeInsets(top: 2, left: 10, bottom: 2, right: 10)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // File info section
        statusLabel = createLabel()
        statusLabel.stringValue = "No document"
        stackView.addArrangedSubview(statusLabel)
        
        // Add separator
        stackView.addArrangedSubview(createSeparator())
        
        // Performance section
        performanceLabel = createLabel()
        performanceLabel.stringValue = "Parse: -- | Render: -- | FPS: --"
        stackView.addArrangedSubview(performanceLabel)
        
        // Add separator
        stackView.addArrangedSubview(createSeparator())
        
        // Memory section
        memoryLabel = createLabel()
        memoryLabel.stringValue = "Memory: -- | Cache: --"
        stackView.addArrangedSubview(memoryLabel)
        
        // Add separator
        stackView.addArrangedSubview(createSeparator())
        
        // System section
        systemLabel = createLabel()
        systemLabel.stringValue = "CPU: --"
        stackView.addArrangedSubview(systemLabel)
        
        // Add spacer to push content to the left
        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(spacer)
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 22)
        ])
        
        // Dark mode support
        if #available(macOS 10.14, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(appearanceChanged),
                name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
                object: nil
            )
            updateAppearance()
        }
    }
    
    private func createLabel() -> NSTextField {
        let label = NSTextField()
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        label.textColor = NSColor.secondaryLabelColor
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }
    
    private func createSeparator() -> NSView {
        let separator = NSView()
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
    
    @objc private func appearanceChanged() {
        updateAppearance()
    }
    
    private func updateAppearance() {
        if #available(macOS 10.14, *) {
            let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            layer?.backgroundColor = isDark ? NSColor(white: 0.15, alpha: 1.0).cgColor : NSColor(white: 0.95, alpha: 1.0).cgColor
        }
    }
    
    private func startMonitoring() {
        // Update status bar every 100ms
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
        
        // Initialize frame rate monitor
        frameRateMonitor = FrameRateMonitor { [weak self] fps in
            self?.currentFPS = fps
        }
    }
    
    private func updateMetrics() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update file info
            if !self.currentFilePath.isEmpty {
                let fileName = URL(fileURLWithPath: self.currentFilePath).lastPathComponent
                let sizeStr = self.formatFileSize(self.fileSize)
                self.statusLabel.stringValue = "📄 \(fileName) | \(sizeStr) | \(self.lineCount) lines | \(self.wordCount) words"
            }
            
            // Update performance metrics
            let parseStr = self.lastParseTime > 0 ? String(format: "%.1fms", self.lastParseTime * 1000) : "--"
            let renderStr = self.lastRenderTime > 0 ? String(format: "%.1fms", self.lastRenderTime * 1000) : "--"
            let fpsStr = self.currentFPS > 0 ? "\(self.currentFPS)" : "--"
            self.performanceLabel.stringValue = "Parse: \(parseStr) | Render: \(renderStr) | FPS: \(fpsStr)"
            
            // Update memory metrics
            let memoryUsage = self.getCurrentMemoryUsage()
            let memoryStr = String(format: "%.1fMB", memoryUsage)
            let cacheStr = self.cacheHitRate > 0 ? String(format: "%.0f%%", self.cacheHitRate * 100) : "--"
            self.memoryLabel.stringValue = "Memory: \(memoryStr) | Cache: \(cacheStr)"
            
            // Update CPU usage
            let cpuUsage = self.getCurrentCPUUsage()
            let cpuStr = String(format: "%.1f%%", cpuUsage)
            self.systemLabel.stringValue = "CPU: \(cpuStr)"
        }
    }
    
    // MARK: - Public Methods
    
    func updateFileInfo(path: String, size: Int64, lines: Int, words: Int) {
        currentFilePath = path
        fileSize = size
        lineCount = lines
        wordCount = words
    }
    
    func updateParseTime(_ time: TimeInterval) {
        lastParseTime = time
    }
    
    func updateRenderTime(_ time: TimeInterval) {
        lastRenderTime = time
    }
    
    func updateDrawTime(_ time: TimeInterval) {
        lastDrawTime = time
    }
    
    func updateCacheHitRate(_ rate: Double) {
        cacheHitRate = rate
    }
    
    // MARK: - Helper Methods
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func getCurrentMemoryUsage() -> Double {
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
            return Double(info.resident_size) / 1024.0 / 1024.0
        }
        return 0
    }
    
    private func getCurrentCPUUsage() -> Double {
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
            // This is a simplified CPU calculation
            // For more accurate results, we'd need to track thread times
            return 0.0 // Placeholder - implement proper CPU tracking
        }
        return 0
    }
    
    deinit {
        updateTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Frame Rate Monitor

class FrameRateMonitor {
    private var displayLink: CVDisplayLink?
    private var frameCount = 0
    private var lastTime = CACurrentMediaTime()
    private let callback: (Int) -> Void
    
    init(callback: @escaping (Int) -> Void) {
        self.callback = callback
        setupDisplayLink()
    }
    
    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        
        guard let displayLink = displayLink else { return }
        
        CVDisplayLinkSetOutputCallback(displayLink, { (_, _, _, _, _, userInfo) -> CVReturn in
            let monitor = Unmanaged<FrameRateMonitor>.fromOpaque(userInfo!).takeUnretainedValue()
            monitor.tick()
            return kCVReturnSuccess
        }, Unmanaged.passUnretained(self).toOpaque())
        
        CVDisplayLinkStart(displayLink)
    }
    
    private func tick() {
        frameCount += 1
        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - lastTime
        
        if elapsed >= 1.0 {
            let fps = Int(Double(frameCount) / elapsed)
            DispatchQueue.main.async {
                self.callback(fps)
            }
            frameCount = 0
            lastTime = currentTime
        }
    }
    
    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }
}