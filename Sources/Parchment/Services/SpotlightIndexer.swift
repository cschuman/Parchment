import CoreSpotlight
import Cocoa
import UniformTypeIdentifiers

/// Indexes markdown documents for Spotlight search
final class SpotlightIndexer {

    // MARK: - Singleton

    static let shared = SpotlightIndexer()

    // MARK: - Properties

    private let searchableIndex = CSSearchableIndex.default()
    private let domainIdentifier = "com.parchment.documents"
    private let indexQueue = DispatchQueue(label: "com.parchment.spotlight.indexer", qos: .utility)

    // MARK: - Public Interface

    /// Index a document for Spotlight search
    func indexDocument(at url: URL, content: String) {
        indexQueue.async { [weak self] in
            self?.performIndexing(url: url, content: content)
        }
    }

    /// Remove a document from the Spotlight index
    func removeDocument(at url: URL) {
        let identifier = identifierForURL(url)
        searchableIndex.deleteSearchableItems(withIdentifiers: [identifier]) { error in
            if let error = error {
                Logger.error("Failed to remove Spotlight index for \(url.path): \(error)")
            } else {
                Logger.info("Removed Spotlight index for: \(url.lastPathComponent)")
            }
        }
    }

    /// Remove all indexed documents
    func removeAllIndexedDocuments() {
        searchableIndex.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
            if let error = error {
                Logger.error("Failed to remove all Spotlight indexes: \(error)")
            } else {
                Logger.info("Removed all Parchment Spotlight indexes")
            }
        }
    }

    /// Index all recently opened documents
    func indexRecentDocuments() {
        // Get recent documents from NSDocumentController
        let recentURLs = NSDocumentController.shared.recentDocumentURLs

        for url in recentURLs {
            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            if let content = try? String(contentsOf: url, encoding: .utf8) {
                indexDocument(at: url, content: content)
            }
        }
    }

    // MARK: - Private Methods

    private func performIndexing(url: URL, content: String) {
        let identifier = identifierForURL(url)

        // Extract metadata
        let title = extractTitle(from: content) ?? url.deletingPathExtension().lastPathComponent
        let headers = extractHeaders(from: content)
        let wordCount = countWords(in: content)
        let preview = extractPreview(from: content)

        // Create searchable item attributes
        let attributes = CSSearchableItemAttributeSet(contentType: UTType.plainText)
        attributes.title = title
        attributes.displayName = url.lastPathComponent
        attributes.contentDescription = preview
        attributes.textContent = content
        attributes.keywords = headers
        attributes.path = url.path
        attributes.contentURL = url

        // Add custom metadata
        attributes.addedDate = Date()
        attributes.contentModificationDate = fileModificationDate(for: url)

        // Thumbnail (optional - could be first few lines rendered)
        attributes.thumbnailData = generateThumbnail(for: content)

        // Create searchable item
        let item = CSSearchableItem(
            uniqueIdentifier: identifier,
            domainIdentifier: domainIdentifier,
            attributeSet: attributes
        )

        // Set expiration (documents don't expire, but re-index on modification)
        item.expirationDate = .distantFuture

        // Index the item
        searchableIndex.indexSearchableItems([item]) { error in
            if let error = error {
                Logger.error("Spotlight indexing failed for \(url.lastPathComponent): \(error)")
            } else {
                Logger.info("Spotlight indexed: \(url.lastPathComponent) (\(wordCount) words)")
            }
        }
    }

    private func identifierForURL(_ url: URL) -> String {
        // Use file path as unique identifier
        return "parchment:\(url.path)"
    }

    private func extractTitle(from content: String) -> String? {
        // Look for first H1 header
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                return String(trimmed.dropFirst(2))
            }
        }
        return nil
    }

    private func extractHeaders(from content: String) -> [String] {
        var headers: [String] = []
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                // Remove # prefix
                var header = trimmed
                while header.hasPrefix("#") {
                    header = String(header.dropFirst())
                }
                header = header.trimmingCharacters(in: .whitespaces)
                if !header.isEmpty {
                    headers.append(header)
                }
            }
        }

        return headers
    }

    private func countWords(in content: String) -> Int {
        return content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    private func extractPreview(from content: String) -> String {
        // Get first 200 characters of actual content (skip frontmatter and headers)
        var preview = ""
        let lines = content.components(separatedBy: .newlines)
        var inFrontmatter = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip frontmatter
            if trimmed == "---" {
                inFrontmatter = !inFrontmatter
                continue
            }
            if inFrontmatter { continue }

            // Skip headers and empty lines for preview
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            preview += trimmed + " "
            if preview.count > 200 { break }
        }

        return String(preview.prefix(200)).trimmingCharacters(in: .whitespaces)
    }

    private func fileModificationDate(for url: URL) -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.modificationDate] as? Date
    }

    private func generateThumbnail(for content: String) -> Data? {
        // Create a simple text thumbnail
        let thumbnailSize = CGSize(width: 256, height: 256)
        let preview = String(content.prefix(500))

        let image = NSImage(size: thumbnailSize)
        image.lockFocus()

        // Background
        NSColor.white.setFill()
        NSRect(origin: .zero, size: thumbnailSize).fill()

        // Text
        let font = NSFont.systemFont(ofSize: 10)
        let textColor = NSColor.darkGray
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]

        let rect = NSRect(x: 10, y: 10, width: thumbnailSize.width - 20, height: thumbnailSize.height - 20)
        preview.draw(in: rect, withAttributes: attributes)

        image.unlockFocus()

        return image.tiffRepresentation
    }
}

// MARK: - Spotlight Search Handler

/// Handles Spotlight search result clicks
final class SpotlightSearchHandler {

    static let shared = SpotlightSearchHandler()

    /// Handle a Spotlight search result
    func handleSearchResult(userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == CSSearchableItemActionType,
              let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else {
            return false
        }

        // Extract file path from identifier
        guard identifier.hasPrefix("parchment:") else { return false }
        let filePath = String(identifier.dropFirst("parchment:".count))

        // Open the file
        let url = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else {
            Logger.error("Spotlight search result file not found: \(filePath)")
            return false
        }

        // Notify app delegate to open the file
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenDocumentFromSpotlight"),
            object: nil,
            userInfo: ["url": url]
        )

        return true
    }
}
