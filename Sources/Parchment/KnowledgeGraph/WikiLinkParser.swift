import Foundation
import Cocoa

class WikiLinkParser {
    
    struct WikiLink: Hashable {
        let title: String
        let alias: String?
        let range: NSRange
        let targetPath: String?
        
        var displayText: String {
            return alias ?? title
        }
    }
    
    struct Backlink {
        let sourceFile: URL
        let targetFile: URL
        let context: String
        let lineNumber: Int
    }
    
    private let workspaceURL: URL?
    private var linkCache: [URL: Set<WikiLink>] = [:]
    private var backlinkCache: [URL: Set<Backlink>] = [:]
    
    init(workspaceURL: URL? = nil) {
        self.workspaceURL = workspaceURL
    }
    
    func parseWikiLinks(in content: String, for url: URL) -> [WikiLink] {
        var links: [WikiLink] = []
        
        let wikiLinkPattern = "\\[\\[([^\\]\\|]+)(\\|([^\\]]+))?\\]\\]"
        
        do {
            let regex = try NSRegularExpression(pattern: wikiLinkPattern, options: [])
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: content.utf16.count))
            
            for match in matches {
                let titleRange = match.range(at: 1)
                let aliasRange = match.range(at: 3)
                
                if let titleNSRange = Range(titleRange, in: content) {
                    let title = String(content[titleNSRange])
                    
                    var alias: String? = nil
                    if aliasRange.location != NSNotFound,
                       let aliasNSRange = Range(aliasRange, in: content) {
                        alias = String(content[aliasNSRange])
                    }
                    
                    let targetPath = resolveWikiLink(title: title, from: url)
                    
                    let link = WikiLink(
                        title: title,
                        alias: alias,
                        range: match.range,
                        targetPath: targetPath
                    )
                    
                    links.append(link)
                }
            }
        } catch {
            print("Wiki link parsing error: \(error)")
        }
        
        linkCache[url] = Set(links)
        updateBacklinks(for: url, with: links)
        
        return links
    }
    
    private func resolveWikiLink(title: String, from sourceURL: URL) -> String? {
        let workspaceURL = self.workspaceURL ?? sourceURL.deletingLastPathComponent()
        
        let searchPaths = [
            workspaceURL.appendingPathComponent("\(title).md"),
            workspaceURL.appendingPathComponent("\(title).markdown"),
            workspaceURL.appendingPathComponent(title).appendingPathComponent("index.md"),
            workspaceURL.appendingPathComponent(title).appendingPathComponent("README.md")
        ]
        
        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path.path) {
                return path.path
            }
        }
        
        let lowercaseTitle = title.lowercased().replacingOccurrences(of: " ", with: "-")
        let additionalPaths = [
            workspaceURL.appendingPathComponent("\(lowercaseTitle).md"),
            workspaceURL.appendingPathComponent("\(lowercaseTitle).markdown")
        ]
        
        for path in additionalPaths {
            if FileManager.default.fileExists(atPath: path.path) {
                return path.path
            }
        }
        
        return fuzzyFindFile(title: title, in: workspaceURL)
    }
    
    private func fuzzyFindFile(title: String, in directory: URL) -> String? {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        
        let searchTerms = title.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        
        var bestMatch: (url: URL, score: Int)?
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" || fileURL.pathExtension == "markdown" else {
                continue
            }
            
            let filename = fileURL.deletingPathExtension().lastPathComponent.lowercased()
            let score = calculateMatchScore(filename: filename, searchTerms: searchTerms)
            
            if score > 0 {
                if bestMatch == nil || score > bestMatch!.score {
                    bestMatch = (fileURL, score)
                }
            }
        }
        
        return bestMatch?.url.path
    }
    
    private func calculateMatchScore(filename: String, searchTerms: [String]) -> Int {
        var score = 0
        
        for term in searchTerms where !term.isEmpty {
            if filename.contains(term) {
                score += term.count
                
                if filename.hasPrefix(term) {
                    score += 5
                }
                
                if filename == term {
                    score += 10
                }
            }
        }
        
        return score
    }
    
    private func updateBacklinks(for sourceURL: URL, with links: [WikiLink]) {
        for link in links {
            guard let targetPath = link.targetPath,
                  let targetURL = URL(string: "file://\(targetPath)") else {
                continue
            }
            
            let context = extractContext(for: link, from: sourceURL)
            let lineNumber = getLineNumber(for: link.range, in: sourceURL)
            
            let backlink = Backlink(
                sourceFile: sourceURL,
                targetFile: targetURL,
                context: context,
                lineNumber: lineNumber
            )
            
            if backlinkCache[targetURL] == nil {
                backlinkCache[targetURL] = Set()
            }
            backlinkCache[targetURL]?.insert(backlink)
        }
    }
    
    private func extractContext(for link: WikiLink, from url: URL) -> String {
        guard let content = try? String(contentsOf: url) else {
            return ""
        }
        
        let lines = content.components(separatedBy: .newlines)
        var currentLocation = 0
        
        for line in lines {
            let lineRange = NSRange(location: currentLocation, length: line.utf16.count)
            
            if NSLocationInRange(link.range.location, lineRange) {
                return line
            }
            
            currentLocation += line.utf16.count + 1
        }
        
        return ""
    }
    
    private func getLineNumber(for range: NSRange, in url: URL) -> Int {
        guard let content = try? String(contentsOf: url) else {
            return 0
        }
        
        let lines = content.components(separatedBy: .newlines)
        var currentLocation = 0
        
        for (index, line) in lines.enumerated() {
            let lineRange = NSRange(location: currentLocation, length: line.utf16.count)
            
            if NSLocationInRange(range.location, lineRange) {
                return index + 1
            }
            
            currentLocation += line.utf16.count + 1
        }
        
        return 0
    }
    
    func getBacklinks(for url: URL) -> [Backlink] {
        return Array(backlinkCache[url] ?? [])
    }
    
    func refreshWorkspace() {
        guard let workspaceURL = workspaceURL else { return }
        
        linkCache.removeAll()
        backlinkCache.removeAll()
        
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: workspaceURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" || fileURL.pathExtension == "markdown" else {
                continue
            }
            
            if let content = try? String(contentsOf: fileURL) {
                _ = parseWikiLinks(in: content, for: fileURL)
            }
        }
    }
}

extension WikiLinkParser.Backlink: Hashable {
    static func == (lhs: WikiLinkParser.Backlink, rhs: WikiLinkParser.Backlink) -> Bool {
        return lhs.sourceFile == rhs.sourceFile &&
               lhs.targetFile == rhs.targetFile &&
               lhs.lineNumber == rhs.lineNumber
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(sourceFile)
        hasher.combine(targetFile)
        hasher.combine(lineNumber)
    }
}