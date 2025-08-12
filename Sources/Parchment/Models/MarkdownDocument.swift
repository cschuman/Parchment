import Foundation

class MarkdownDocument {
    let id: String
    let url: URL?
    let content: String
    let createdAt: Date
    var lastModified: Date
    var metadata: DocumentMetadata
    
    init(url: URL?, content: String) {
        self.id = UUID().uuidString
        self.url = url
        self.content = content
        self.createdAt = Date()
        self.lastModified = Date()
        self.metadata = DocumentMetadata(content: content)
    }
}

struct DocumentMetadata {
    let wordCount: Int
    let characterCount: Int
    let lineCount: Int
    let headers: [MarkdownHeader]
    let estimatedReadingTime: Int
    
    init(content: String) {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        self.wordCount = words.count
        self.characterCount = content.count
        self.lineCount = content.components(separatedBy: .newlines).count
        self.estimatedReadingTime = Int(ceil(Double(wordCount) / 200.0))
        self.headers = []
    }
}

class MarkdownHeader: Equatable, Hashable {
    let id: String
    let level: Int
    let title: String
    let lineNumber: Int
    weak var parent: MarkdownHeader?
    var children: [MarkdownHeader] = []
    
    init(level: Int, title: String, lineNumber: Int, parent: MarkdownHeader? = nil) {
        self.id = UUID().uuidString
        self.level = level
        self.title = title
        self.lineNumber = lineNumber
        self.parent = parent
    }
    
    static func == (lhs: MarkdownHeader, rhs: MarkdownHeader) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ReadingStatistics {
    let wordCount: Int
    let characterCount: Int
    let readingTime: Int
    let complexityScore: Int
    let progress: Double
}