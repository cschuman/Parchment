import Foundation
import Cocoa
import Markdown
import os.log

private let renderLog = OSLog(subsystem: "com.markdownviewer.rendering", category: "Progressive")

final class ProgressiveRenderingEngine {
    
    enum RenderPriority {
        case immediate
        case high
        case normal
        case low
    }
    
    struct RenderChunk {
        let range: NSRange
        let priority: RenderPriority
        let content: String
        var rendered: NSAttributedString?
        var renderTime: TimeInterval = 0
    }
    
    private let chunkSize = 500
    private let renderQueue = OperationQueue()
    private let resultQueue = DispatchQueue(label: "com.markdownviewer.render.results", attributes: .concurrent)
    private var chunks: [RenderChunk] = []
    private var renderCallbacks: [(NSAttributedString) -> Void] = []
    
    private let syntaxHighlighter = SyntaxHighlighter()
    private let renderCache = NSCache<NSString, NSAttributedString>()
    
    init() {
        renderQueue.maxConcurrentOperationCount = 4
        renderQueue.qualityOfService = .userInitiated
        renderCache.countLimit = 50
    }
    
    func renderProgressively(
        markdown: String,
        visibleRange: NSRange,
        completion: @escaping (NSAttributedString) -> Void,
        progressUpdate: @escaping (NSAttributedString, Double) -> Void
    ) {
        os_log(.debug, log: renderLog, "Starting progressive render for %d characters", markdown.count)
        
        chunks = createChunks(from: markdown, visibleRange: visibleRange)
        
        let totalResult = NSMutableAttributedString()
        var renderedChunks = 0
        let totalChunks = chunks.count
        
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.placeholderTextColor
        ]
        
        for i in 0..<chunks.count {
            let placeholder = NSAttributedString(
                string: String(repeating: "█", count: min(20, chunks[i].content.count / 50)) + "\n",
                attributes: placeholderAttributes
            )
            totalResult.append(placeholder)
        }
        
        completion(totalResult)
        
        for (index, chunk) in chunks.enumerated() {
            let operation = RenderOperation(
                chunk: chunk,
                index: index,
                syntaxHighlighter: syntaxHighlighter
            ) { [weak self] renderedChunk, chunkIndex in
                guard let self = self else { return }
                
                self.resultQueue.async(flags: .barrier) {
                    self.chunks[chunkIndex].rendered = renderedChunk
                    renderedChunks += 1
                    
                    let progress = Double(renderedChunks) / Double(totalChunks)
                    
                    let currentResult = self.assembleRenderedChunks()
                    
                    DispatchQueue.main.async {
                        progressUpdate(currentResult, progress)
                        
                        if renderedChunks == totalChunks {
                            os_log(.debug, log: renderLog, "Progressive render complete")
                        }
                    }
                }
            }
            
            operation.queuePriority = priorityToQueuePriority(chunk.priority)
            renderQueue.addOperation(operation)
        }
    }
    
    private func createChunks(from markdown: String, visibleRange: NSRange) -> [RenderChunk] {
        var chunks: [RenderChunk] = []
        let lines = markdown.components(separatedBy: .newlines)
        
        var currentChunk = ""
        var currentLocation = 0
        var lineCount = 0
        
        for (index, line) in lines.enumerated() {
            currentChunk += line + "\n"
            lineCount += 1
            
            if lineCount >= chunkSize || index == lines.count - 1 {
                let chunkRange = NSRange(
                    location: currentLocation,
                    length: currentChunk.count
                )
                
                let priority: RenderPriority
                if NSLocationInRange(visibleRange.location, chunkRange) {
                    priority = .immediate
                } else if abs(chunkRange.location - visibleRange.location) < 5000 {
                    priority = .high
                } else if abs(chunkRange.location - visibleRange.location) < 20000 {
                    priority = .normal
                } else {
                    priority = .low
                }
                
                chunks.append(RenderChunk(
                    range: chunkRange,
                    priority: priority,
                    content: currentChunk,
                    rendered: nil
                ))
                
                currentLocation += currentChunk.count
                currentChunk = ""
                lineCount = 0
            }
        }
        
        chunks.sort { $0.priority.rawValue < $1.priority.rawValue }
        
        return chunks
    }
    
    private func assembleRenderedChunks() -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        let sortedChunks = chunks.sorted { $0.range.location < $1.range.location }
        
        for chunk in sortedChunks {
            if let rendered = chunk.rendered {
                result.append(rendered)
            } else {
                let placeholderAttributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 14),
                    .foregroundColor: NSColor.placeholderTextColor,
                    .backgroundColor: NSColor.controlBackgroundColor.withAlphaComponent(0.1)
                ]
                
                let lines = chunk.content.components(separatedBy: .newlines).count
                let placeholder = String(repeating: "░░░░░░░░░░░░░░░░░░░░\n", count: min(lines, 5))
                result.append(NSAttributedString(string: placeholder, attributes: placeholderAttributes))
            }
        }
        
        return result
    }
    
    private func priorityToQueuePriority(_ priority: RenderPriority) -> Operation.QueuePriority {
        switch priority {
        case .immediate: return .veryHigh
        case .high: return .high
        case .normal: return .normal
        case .low: return .low
        }
    }
    
    func cancelRendering() {
        renderQueue.cancelAllOperations()
    }
    
    func preRenderInBackground(markdown: String, range: NSRange) {
        let chunk = RenderChunk(
            range: range,
            priority: .low,
            content: String(markdown[Range(range, in: markdown)!]),
            rendered: nil
        )
        
        let operation = RenderOperation(
            chunk: chunk,
            index: -1,
            syntaxHighlighter: syntaxHighlighter
        ) { [weak self] rendered, _ in
            let key = "\(range.location)-\(range.length)" as NSString
            self?.renderCache.setObject(rendered, forKey: key)
        }
        
        operation.queuePriority = .veryLow
        renderQueue.addOperation(operation)
    }
}

private class RenderOperation: Operation {
    let chunk: ProgressiveRenderingEngine.RenderChunk
    let index: Int
    let syntaxHighlighter: SyntaxHighlighter
    let completion: (NSAttributedString, Int) -> Void
    
    init(
        chunk: ProgressiveRenderingEngine.RenderChunk,
        index: Int,
        syntaxHighlighter: SyntaxHighlighter,
        completion: @escaping (NSAttributedString, Int) -> Void
    ) {
        self.chunk = chunk
        self.index = index
        self.syntaxHighlighter = syntaxHighlighter
        self.completion = completion
    }
    
    override func main() {
        guard !isCancelled else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let document = Document(parsing: chunk.content)
        let visitor = OptimizedAttributedStringVisitor(
            syntaxHighlighter: syntaxHighlighter
        )
        
        let walker = DocumentWalker(visitor: visitor)
        walker.visit(document)
        
        let renderTime = CFAbsoluteTimeGetCurrent() - startTime
        
        if renderTime > 0.1 {
            os_log(.info, log: renderLog,
                   "Slow chunk render: %.2fms for %d characters",
                   renderTime * 1000,
                   chunk.content.count)
        }
        
        guard !isCancelled else { return }
        
        completion(visitor.attributedString, index)
    }
}

class OptimizedAttributedStringVisitor: AttributedStringVisitor {
    override init(zoomLevel: CGFloat = 1.0, syntaxHighlighter: SyntaxHighlighter) {
        super.init(zoomLevel: zoomLevel, syntaxHighlighter: syntaxHighlighter)
        // Attributes are already set up in parent class
    }
}

extension ProgressiveRenderingEngine.RenderPriority: Comparable {
    var rawValue: Int {
        switch self {
        case .immediate: return 0
        case .high: return 1
        case .normal: return 2
        case .low: return 3
        }
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}