import Foundation
import Cocoa
import Markdown
import os.log

private let perfLog = OSLog(subsystem: "com.parchment", category: "Performance")

/// Optimized file opening with sub-50ms performance for typical documents
final class FastFileOpener {
    
    static let shared = FastFileOpener()
    
    // Pre-warmed resources
    private var preloadedFonts: Set<String> = []
    private let renderQueue = DispatchQueue(label: "com.parchment.render", qos: .userInteractive)
    private let cacheQueue = DispatchQueue(label: "com.parchment.cache", qos: .utility)
    
    // Quick cache for recently opened files  
    private var quickCache = NSCache<NSString, NSData>()
    private var documentCache: [String: CachedDocument] = [:]
    
    struct CachedDocument {
        let attributedString: NSAttributedString
        let tableOfContents: [TOCItem]
        let metadata: DocumentMetadata
        let timestamp: Date
    }
    
    struct DocumentMetadata {
        let wordCount: Int
        let characterCount: Int
        let readingTime: Int // in minutes
        let hasCodeBlocks: Bool
        let hasImages: Bool
    }
    
    struct TOCItem {
        let title: String
        let level: Int
        let range: NSRange
    }
    
    private init() {
        setupCache()
        prewarmResources()
    }
    
    // MARK: - Fast File Opening
    
    /// Open a markdown file with optimized performance
    func openFile(at url: URL, completion: @escaping (Result<OpenedDocument, Error>) -> Void) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check document cache first
        if let cached = documentCache[url.path] {
            let cacheAge = Date().timeIntervalSince(cached.timestamp)
            if cacheAge < 5.0 { // Use cache if less than 5 seconds old
                let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                os_log(.info, log: perfLog, "Cache hit - opened in %.2fms", elapsed)
                
                completion(.success(OpenedDocument(
                    attributedString: cached.attributedString,
                    tableOfContents: cached.tableOfContents,
                    metadata: cached.metadata
                )))
                return
            }
        }
        
        // Read file asynchronously
        renderQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Read file with optimal settings
                let content = try self.readFileOptimized(at: url)
                
                // Parse markdown
                let document = Document(parsing: content)
                
                // Generate attributed string and TOC in parallel
                var attributedString: NSAttributedString?
                var tableOfContents: [TOCItem] = []
                var metadata: DocumentMetadata?
                
                let group = DispatchGroup()
                
                // Render attributed string
                group.enter()
                self.renderQueue.async {
                    attributedString = self.renderAttributedString(from: document)
                    group.leave()
                }
                
                // Extract TOC
                group.enter()
                self.renderQueue.async {
                    tableOfContents = self.extractTableOfContents(from: document)
                    group.leave()
                }
                
                // Calculate metadata
                group.enter()
                self.renderQueue.async {
                    metadata = self.calculateMetadata(from: document, content: content)
                    group.leave()
                }
                
                group.wait()
                
                // Cache the result
                if let attrString = attributedString, let meta = metadata {
                    let cached = CachedDocument(
                        attributedString: attrString,
                        tableOfContents: tableOfContents,
                        metadata: meta,
                        timestamp: Date()
                    )
                    self.documentCache[url.path] = cached
                }
                
                let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                os_log(.info, log: perfLog, "File opened in %.2fms", elapsed)
                
                DispatchQueue.main.async {
                    completion(.success(OpenedDocument(
                        attributedString: attributedString ?? NSAttributedString(),
                        tableOfContents: tableOfContents,
                        metadata: metadata ?? DocumentMetadata(
                            wordCount: 0,
                            characterCount: 0,
                            readingTime: 0,
                            hasCodeBlocks: false,
                            hasImages: false
                        )
                    )))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Optimized File Reading
    
    private func readFileOptimized(at url: URL) throws -> String {
        // Use memory mapping for large files
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
        
        if fileSize > 1_000_000 { // > 1MB
            // Use memory mapping for large files
            return try readLargeFile(at: url)
        } else {
            // Direct read for small files
            return try String(contentsOf: url, encoding: .utf8)
        }
    }
    
    private func readLargeFile(at url: URL) throws -> String {
        let data = try Data(contentsOf: url, options: .mappedIfSafe)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    // MARK: - Optimized Rendering
    
    private func renderAttributedString(from document: Document) -> NSAttributedString {
        // Use the enhanced typography engine
        let typography = TypographyEngine()
        let visitor = OptimizedAttributedStringVisitor(typography: typography)
        return visitor.render(document)
    }
    
    private func extractTableOfContents(from document: Document) -> [TOCItem] {
        var items: [TOCItem] = []
        var currentPosition = 0
        
        document.children.forEach { node in
            if let heading = node as? Heading {
                let title = heading.plainText
                items.append(TOCItem(
                    title: title,
                    level: heading.level,
                    range: NSRange(location: currentPosition, length: title.count)
                ))
            }
            currentPosition += node.plainText.count + 2 // Account for newlines
        }
        
        return items
    }
    
    private func calculateMetadata(from document: Document, content: String) -> DocumentMetadata {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let wordCount = words.count
        let characterCount = content.count
        let readingTime = max(1, wordCount / 200) // Average reading speed
        
        var hasCodeBlocks = false
        var hasImages = false
        
        document.children.forEach { node in
            checkNode(node, hasCode: &hasCodeBlocks, hasImages: &hasImages)
        }
        
        return DocumentMetadata(
            wordCount: wordCount,
            characterCount: characterCount,
            readingTime: readingTime,
            hasCodeBlocks: hasCodeBlocks,
            hasImages: hasImages
        )
    }
    
    private func checkNode(_ node: any Markup, hasCode: inout Bool, hasImages: inout Bool) {
        if node is CodeBlock {
            hasCode = true
        } else if node is Image {
            hasImages = true
        }
        
        node.children.forEach { child in
            checkNode(child, hasCode: &hasCode, hasImages: &hasImages)
        }
    }
    
    // MARK: - Resource Prewarming
    
    private func prewarmResources() {
        // Prewarm fonts
        let fontNames = ["SF Pro Display", "SF Pro Text", "SF Mono", "New York", "Charter", "Georgia"]
        fontNames.forEach { name in
            _ = NSFont(name: name, size: 16)
            preloadedFonts.insert(name)
        }
        
        // Prewarm parser
        _ = Document(parsing: "# Test")
    }
    
    private func setupCache() {
        quickCache.countLimit = 10
        quickCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
}

// MARK: - Optimized Visitor

private class OptimizedAttributedStringVisitor {
    private let typography: TypographyEngine
    private let attributedString = NSMutableAttributedString()
    
    init(typography: TypographyEngine) {
        self.typography = typography
    }
    
    func render(_ document: Document) -> NSAttributedString {
        // Batch render for performance
        var chunks: [(String, [NSAttributedString.Key: Any])] = []
        
        document.children.forEach { node in
            collectChunks(from: node, into: &chunks)
        }
        
        // Batch apply attributes
        for (text, attributes) in chunks {
            attributedString.append(NSAttributedString(string: text, attributes: attributes))
        }
        
        return NSAttributedString(attributedString: attributedString)
    }
    
    private func collectChunks(from node: any Markup, into chunks: inout [(String, [NSAttributedString.Key: Any])]) {
        switch node {
        case let heading as Heading:
            let attributes = typography.headingAttributes(level: heading.level)
            chunks.append((heading.plainText + "\n\n", attributes))
            
        case let paragraph as Paragraph:
            let attributes = typography.bodyAttributes()
            chunks.append((paragraph.plainText + "\n\n", attributes))
            
        case let code as CodeBlock:
            let attributes = typography.codeBlockAttributes()
            chunks.append((code.code + "\n\n", attributes))
            
        default:
            // Recursively handle other nodes
            node.children.forEach { child in
                collectChunks(from: child, into: &chunks)
            }
        }
    }
}

// MARK: - Result Types

struct OpenedDocument {
    let attributedString: NSAttributedString
    let tableOfContents: [FastFileOpener.TOCItem]
    let metadata: FastFileOpener.DocumentMetadata
}

// MARK: - Markup Extensions

private extension Markup {
    var plainText: String {
        var text = ""
        collectText(from: self, into: &text)
        return text
    }
    
    private func collectText(from node: any Markup, into text: inout String) {
        if let textNode = node as? Markdown.Text {
            text += textNode.string
        }
        
        node.children.forEach { child in
            collectText(from: child, into: &text)
        }
    }
}