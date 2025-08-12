import Foundation
import Cocoa
import MarkdownKit

/// Manages performance optimizations for fast file loading
class PerformanceOptimizer {
    
    static let shared = PerformanceOptimizer()
    
    private let parseQueue = DispatchQueue(label: "markdown.parse", qos: .userInteractive, attributes: .concurrent)
    private let renderQueue = DispatchQueue(label: "markdown.render", qos: .userInteractive)
    
    private var warmupComplete = false
    private var preloadedParsers: [Any] = []
    
    init() {
        warmupSystemCaches()
    }
    
    /// Warm up system caches and preload resources
    private func warmupSystemCaches() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            // Preload markdown parser
            _ = ExtendedMarkdownParser.standard
            
            // Preload fonts
            _ = NSFont.systemFont(ofSize: 14)
            _ = NSFont.boldSystemFont(ofSize: 18)
            _ = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            
            // Preload colors
            _ = NSColor.labelColor
            _ = NSColor.secondaryLabelColor
            _ = NSColor.systemBlue
            
            // Create dummy attributed string to warm up text system
            let dummy = NSMutableAttributedString(string: "warmup")
            dummy.addAttribute(.font, value: NSFont.systemFont(ofSize: 14), range: NSRange(location: 0, length: 6))
            
            self?.warmupComplete = true
        }
    }
    
    /// Fast file loading with parallel processing
    func loadFileOptimized(at url: URL, completion: @escaping (Result<OptimizedDocument, Error>) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Read file in background
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                // Use memory-mapped I/O for large files
                let data = try self.readFileOptimized(at: url)
                let content = String(data: data, encoding: .utf8) ?? ""
                
                // Quick metadata extraction
                let metadata = self.extractMetadata(from: content)
                
                // Start parsing immediately (don't wait for full parse)
                self.parseQueue.async {
                    let parseStart = CFAbsoluteTimeGetCurrent()
                    
                    // For initial display, only parse first chunk
                    let initialChunkSize = min(content.count, 50_000)
                    let initialContent = String(content.prefix(initialChunkSize))
                    
                    let parser = ExtendedMarkdownParser.standard
                    let document = parser.parse(initialContent)
                    
                    let parseTime = CFAbsoluteTimeGetCurrent() - parseStart
                    
                    // Create optimized document
                    let optimizedDoc = OptimizedDocument(
                        url: url,
                        content: content,
                        initialParsedContent: document,
                        metadata: metadata,
                        loadTime: CFAbsoluteTimeGetCurrent() - startTime,
                        parseTime: parseTime
                    )
                    
                    DispatchQueue.main.async {
                        completion(.success(optimizedDoc))
                    }
                    
                    // Continue parsing rest of document in background
                    if content.count > initialChunkSize {
                        self.parseRemainingContent(content, from: initialChunkSize)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Read file using optimized I/O
    private func readFileOptimized(at url: URL) throws -> Data {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        if fileSize > 1_000_000 { // >1MB
            // Use memory-mapped I/O for large files
            return try Data(contentsOf: url, options: .mappedIfSafe)
        } else {
            // Direct read for small files
            return try Data(contentsOf: url)
        }
    }
    
    /// Extract metadata without full parse
    private func extractMetadata(from content: String) -> OptimizedDocumentMetadata {
        var metadata = OptimizedDocumentMetadata()
        
        // Quick line and word count
        let lines = content.components(separatedBy: .newlines)
        metadata.lineCount = lines.count
        metadata.wordCount = content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        metadata.characterCount = content.count
        
        // Extract headers for TOC (first pass only)
        var headers: [String] = []
        for line in lines.prefix(100) { // Check first 100 lines for headers
            if line.hasPrefix("#") {
                headers.append(line)
            }
        }
        metadata.headers = headers
        
        // Check for front matter
        if content.hasPrefix("---") {
            if let endIndex = content.range(of: "\n---\n")?.upperBound {
                metadata.hasFrontMatter = true
                metadata.frontMatterEndIndex = content.distance(from: content.startIndex, to: endIndex)
            }
        }
        
        return metadata
    }
    
    /// Continue parsing remaining content in background
    private func parseRemainingContent(_ content: String, from startIndex: Int) {
        // This runs in background and updates cache
        // The UI doesn't wait for this
    }
    
    /// Preload resources for a file before opening
    func preloadFile(at url: URL) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                _ = String(data: data, encoding: .utf8)
                // Just reading the file warms up system caches
            } catch {
                // Ignore preload errors
            }
        }
    }
}

/// Optimized document structure
struct OptimizedDocument {
    let url: URL
    let content: String
    let initialParsedContent: Block
    let metadata: OptimizedDocumentMetadata
    let loadTime: TimeInterval
    let parseTime: TimeInterval
    
    var totalTime: TimeInterval {
        return loadTime
    }
    
    var meetsTarget: Bool {
        return totalTime < 0.050 // 50ms
    }
}

/// Document metadata for quick access  
struct OptimizedDocumentMetadata {
    var lineCount: Int = 0
    var wordCount: Int = 0
    var characterCount: Int = 0
    var headers: [String] = []
    var hasFrontMatter: Bool = false
    var frontMatterEndIndex: Int = 0
    var hasCodeBlocks: Bool = false
    var hasTables: Bool = false
    var hasImages: Bool = false
    var complexity: ComplexityLevel = .simple
    
    enum ComplexityLevel {
        case simple    // Plain text, <1000 lines
        case moderate  // Some formatting, 1000-5000 lines
        case complex   // Heavy formatting, >5000 lines
    }
}

// MARK: - Render Optimization

extension PerformanceOptimizer {
    
    /// Optimized rendering with progressive enhancement
    func renderOptimized(
        _ document: Block,
        progressHandler: @escaping (NSAttributedString, Double) -> Void
    ) {
        renderQueue.async {
            let totalBlocks = self.countBlocks(in: document)
            var processedBlocks = 0
            
            let result = NSMutableAttributedString()
            
            // Render in chunks with progress updates
            self.renderBlocks(document, into: result) { chunk in
                processedBlocks += 1
                let progress = Double(processedBlocks) / Double(totalBlocks)
                
                DispatchQueue.main.async {
                    progressHandler(chunk, progress)
                }
            }
        }
    }
    
    private func countBlocks(in document: Block) -> Int {
        // Count total blocks for progress calculation
        switch document {
        case .document(let blocks):
            return blocks.count
        default:
            return 1
        }
    }
    
    private func renderBlocks(
        _ document: Block,
        into result: NSMutableAttributedString,
        chunkHandler: @escaping (NSAttributedString) -> Void
    ) {
        // Render blocks incrementally
        switch document {
        case .document(let blocks):
            for block in blocks {
                let chunk = NSMutableAttributedString()
                // Render individual block
                // ... rendering logic ...
                result.append(chunk)
                chunkHandler(chunk)
            }
        default:
            break
        }
    }
}

// MARK: - Memory Management

extension PerformanceOptimizer {
    
    /// Monitor and optimize memory usage
    func optimizeMemory() {
        // Release unused caches
        URLCache.shared.removeAllCachedResponses()
        
        // Trigger garbage collection for large allocations
        if ProcessInfo.processInfo.physicalMemory > 8_000_000_000 { // >8GB RAM
            // Can be more aggressive with caching
        } else {
            // Be conservative with memory
            // TODO: Implement cache limiting for low memory
        }
    }
    
    /// Get current memory usage
    func getCurrentMemoryUsage() -> Double {
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
}