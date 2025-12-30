import AppIntents
import Cocoa

// MARK: - Open Document Intent

@available(macOS 13.0, *)
struct OpenDocumentIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Document in Parchment"
    static var description = IntentDescription("Opens a markdown file in Parchment")

    @Parameter(title: "File Path", description: "Path to the markdown file")
    var filePath: String

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$filePath) in Parchment")
    }

    func perform() async throws -> some IntentResult {
        let url = URL(fileURLWithPath: filePath)

        guard FileManager.default.fileExists(atPath: filePath) else {
            throw IntentError.fileNotFound
        }

        let validExtensions = ["md", "markdown", "mdown", "mkd", "mkdn", "txt"]
        guard validExtensions.contains(url.pathExtension.lowercased()) else {
            throw IntentError.invalidFileType
        }

        await MainActor.run {
            NSWorkspace.shared.open(
                [url],
                withApplicationAt: Bundle.main.bundleURL,
                configuration: NSWorkspace.OpenConfiguration()
            )
        }

        return .result()
    }
}

// MARK: - Export Document Intent

@available(macOS 13.0, *)
struct ExportDocumentIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Markdown Document"
    static var description = IntentDescription("Exports a markdown file to another format")

    @Parameter(title: "Source File", description: "Path to the markdown file to export")
    var sourcePath: String

    @Parameter(title: "Export Format", description: "Format to export to")
    var format: ExportFormatEnum

    @Parameter(title: "Output Path", description: "Where to save the exported file (optional)")
    var outputPath: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Export \(\.$sourcePath) as \(\.$format)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard FileManager.default.fileExists(atPath: sourcePath) else {
            throw IntentError.fileNotFound
        }

        let sourceURL = URL(fileURLWithPath: sourcePath)
        let content = try String(contentsOf: sourceURL, encoding: .utf8)

        let outputURL: URL
        if let outputPath = outputPath {
            outputURL = URL(fileURLWithPath: outputPath)
        } else {
            outputURL = sourceURL.deletingPathExtension().appendingPathExtension(format.fileExtension)
        }

        switch format {
        case .html:
            let html = convertToHTML(content)
            try html.write(to: outputURL, atomically: true, encoding: .utf8)

        case .plainText:
            let plainText = stripMarkdown(content)
            try plainText.write(to: outputURL, atomically: true, encoding: .utf8)

        case .pdf:
            throw IntentError.pdfExportRequiresApp
        }

        return .result(value: outputURL.path)
    }

    private func convertToHTML(_ markdown: String) -> String {
        // Simple markdown to HTML conversion
        var html = "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n"
        html += "<title>Exported Document</title>\n"
        html += "<style>body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; max-width: 800px; margin: 40px auto; padding: 20px; }</style>\n"
        html += "</head>\n<body>\n"

        let lines = markdown.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("# ") {
                html += "<h1>\(line.dropFirst(2))</h1>\n"
            } else if line.hasPrefix("## ") {
                html += "<h2>\(line.dropFirst(3))</h2>\n"
            } else if line.hasPrefix("### ") {
                html += "<h3>\(line.dropFirst(4))</h3>\n"
            } else if line.isEmpty {
                html += "<br>\n"
            } else {
                html += "<p>\(line)</p>\n"
            }
        }

        html += "</body>\n</html>"
        return html
    }

    private func stripMarkdown(_ markdown: String) -> String {
        var text = markdown
        // Remove headers
        text = text.replacingOccurrences(of: "^#{1,6}\\s+", with: "", options: .regularExpression)
        // Remove bold/italic
        text = text.replacingOccurrences(of: "[*_]{1,2}([^*_]+)[*_]{1,2}", with: "$1", options: .regularExpression)
        // Remove links
        text = text.replacingOccurrences(of: "\\[([^\\]]+)\\]\\([^)]+\\)", with: "$1", options: .regularExpression)
        // Remove code
        text = text.replacingOccurrences(of: "`[^`]+`", with: "", options: .regularExpression)
        return text
    }
}

// MARK: - Export Format Enum

@available(macOS 13.0, *)
enum ExportFormatEnum: String, AppEnum {
    case html
    case plainText
    case pdf

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Export Format"
    }

    static var caseDisplayRepresentations: [ExportFormatEnum: DisplayRepresentation] {
        [
            .html: "HTML",
            .plainText: "Plain Text",
            .pdf: "PDF"
        ]
    }

    var fileExtension: String {
        switch self {
        case .html: return "html"
        case .plainText: return "txt"
        case .pdf: return "pdf"
        }
    }
}

// MARK: - Get Reading Statistics Intent

@available(macOS 13.0, *)
struct GetReadingStatisticsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Reading Statistics"
    static var description = IntentDescription("Returns reading statistics for a markdown file")

    @Parameter(title: "File Path", description: "Path to the markdown file")
    var filePath: String

    static var parameterSummary: some ParameterSummary {
        Summary("Get statistics for \(\.$filePath)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<ReadingStatisticsResult> {
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw IntentError.fileNotFound
        }

        let content = try String(contentsOfFile: filePath, encoding: .utf8)

        let wordCount = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count

        let characterCount = content.count
        let lineCount = content.components(separatedBy: .newlines).count

        // Average reading speed: 200-250 words per minute
        let readingTimeMinutes = max(1, wordCount / 225)

        let result = ReadingStatisticsResult(
            wordCount: wordCount,
            characterCount: characterCount,
            lineCount: lineCount,
            readingTimeMinutes: readingTimeMinutes
        )

        return .result(value: result)
    }
}

// MARK: - Reading Statistics Result

@available(macOS 13.0, *)
struct ReadingStatisticsResult: AppEntity {
    let wordCount: Int
    let characterCount: Int
    let lineCount: Int
    let readingTimeMinutes: Int

    var id: String { "\(wordCount)-\(characterCount)-\(lineCount)" }

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Reading Statistics"
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(wordCount) words",
            subtitle: "\(readingTimeMinutes) min read"
        )
    }

    static var defaultQuery = ReadingStatisticsQuery()
}

@available(macOS 13.0, *)
struct ReadingStatisticsQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ReadingStatisticsResult] {
        []
    }

    func suggestedEntities() async throws -> [ReadingStatisticsResult] {
        []
    }
}

// MARK: - Intent Errors

enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case fileNotFound
    case invalidFileType
    case exportFailed
    case pdfExportRequiresApp

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .fileNotFound:
            return "File not found at the specified path"
        case .invalidFileType:
            return "File must be a markdown file (.md, .markdown, .txt)"
        case .exportFailed:
            return "Failed to export document"
        case .pdfExportRequiresApp:
            return "PDF export requires running Parchment app"
        }
    }
}

// MARK: - App Shortcuts Provider

@available(macOS 13.0, *)
struct ParchmentShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenDocumentIntent(),
            phrases: [
                "Open \(\.$filePath) in \(.applicationName)",
                "View \(\.$filePath) with \(.applicationName)"
            ],
            shortTitle: "Open Document",
            systemImageName: "doc.text"
        )

        AppShortcut(
            intent: GetReadingStatisticsIntent(),
            phrases: [
                "Get reading statistics for \(\.$filePath)",
                "How long to read \(\.$filePath)"
            ],
            shortTitle: "Reading Statistics",
            systemImageName: "chart.bar"
        )

        AppShortcut(
            intent: ExportDocumentIntent(),
            phrases: [
                "Export \(\.$sourcePath) to \(\.$format)",
                "Convert \(\.$sourcePath) to \(\.$format)"
            ],
            shortTitle: "Export Document",
            systemImageName: "square.and.arrow.up"
        )
    }
}
