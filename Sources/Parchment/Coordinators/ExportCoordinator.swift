import Cocoa
import UniformTypeIdentifiers

/// Coordinates document export functionality
final class ExportCoordinator {

    private let documentExporter = DocumentExporter()
    private weak var window: NSWindow?

    init(window: NSWindow?) {
        self.window = window
    }

    func updateWindow(_ window: NSWindow?) {
        self.window = window
    }

    func exportDocument(_ document: MarkdownDocument, format: DocumentExporter.ExportFormat) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = contentTypes(for: format)
        savePanel.canCreateDirectories = true
        savePanel.nameFieldStringValue = (document.url?.deletingPathExtension().lastPathComponent ?? "Untitled") + fileExtension(for: format)

        guard let window = window else {
            showError("No window available for export")
            return
        }

        savePanel.beginSheetModal(for: window) { [weak self] response in
            guard let self = self, response == .OK, let url = savePanel.url else { return }

            Task { [weak self] in
                guard let self = self else { return }
                do {
                    let options = self.createExportOptions(for: format)
                    try await self.documentExporter.export(document: document, to: format, at: url, options: options)

                    await MainActor.run { [weak self] in
                        self?.showExportSuccess(url: url)
                    }
                } catch {
                    await MainActor.run { [weak self] in
                        self?.showError("Export failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Private

    private func contentTypes(for format: DocumentExporter.ExportFormat) -> [UTType] {
        switch format {
        case .pdf:
            return [.pdf]
        case .html:
            return [.html]
        case .rtf:
            return [.rtf]
        case .docx:
            if let docxType = UTType(filenameExtension: "docx") {
                return [docxType]
            }
            return [.data]
        case .plainText:
            return [.plainText]
        }
    }

    private func fileExtension(for format: DocumentExporter.ExportFormat) -> String {
        switch format {
        case .pdf:
            return ".pdf"
        case .html:
            return ".html"
        case .rtf:
            return ".rtf"
        case .docx:
            return ".docx"
        case .plainText:
            return ".txt"
        }
    }

    private func createExportOptions(for format: DocumentExporter.ExportFormat) -> ExportOptions {
        var options = ExportOptions()
        options.format = format

        if NSApp.appearance?.name == .darkAqua {
            options.theme = .dark
        }

        return options
    }

    private func showExportSuccess(url: URL) {
        let alert = NSAlert()
        alert.messageText = "Export Successful"
        alert.informativeText = "Document exported to \(url.lastPathComponent)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Show in Finder")

        guard let window = window else {
            _ = alert.runModal()
            return
        }
        alert.beginSheetModal(for: window) { response in
            if response == .alertSecondButtonReturn {
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
            }
        }
    }

    private func showError(_ message: String) {
        AlertHelper.showError(message, in: window)
    }
}
