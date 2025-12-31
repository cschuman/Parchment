import Cocoa
import UniformTypeIdentifiers

/// Coordinates document export functionality
final class ExportCoordinator {

    private let documentExporter = DocumentExporter()
    private weak var window: NSWindow?
    private var previewController: ExportPreviewController?
    private var currentDocument: MarkdownDocument?

    init(window: NSWindow?) {
        self.window = window
    }

    func updateWindow(_ window: NSWindow?) {
        self.window = window
    }

    /// Export document with preview - shows preview panel first, then proceeds to save
    func exportDocument(_ document: MarkdownDocument, format: DocumentExporter.ExportFormat) {
        // For formats that support preview, show preview first
        if supportsPreview(format) {
            showExportPreview(document: document, format: format)
        } else {
            // For formats without preview support (DOCX, plain text), go directly to save
            exportDirectly(document, format: format)
        }
    }

    /// Export without preview - for backwards compatibility or programmatic export
    func exportDirectly(_ document: MarkdownDocument, format: DocumentExporter.ExportFormat) {
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

    // MARK: - Preview Support

    private func supportsPreview(_ format: DocumentExporter.ExportFormat) -> Bool {
        switch format {
        case .pdf, .html, .rtf:
            return true
        case .docx, .plainText:
            return false
        }
    }

    private func showExportPreview(document: MarkdownDocument, format: DocumentExporter.ExportFormat) {
        guard let window = window else {
            showError("No window available for export preview")
            return
        }

        currentDocument = document
        previewController = ExportPreviewController(document: document, exporter: documentExporter)
        previewController?.delegate = self
        previewController?.setInitialFormat(format)

        guard let previewVC = previewController else { return }

        window.contentViewController?.presentAsSheet(previewVC)
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

    private func dismissPreview() {
        if let previewVC = previewController {
            previewVC.dismiss(nil)
        }
        previewController = nil
        currentDocument = nil
    }

    private func proceedWithExport(document: MarkdownDocument, format: DocumentExporter.ExportFormat, options: ExportOptions) {
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
}

// MARK: - ExportPreviewDelegate

extension ExportCoordinator: ExportPreviewDelegate {

    func exportPreviewDidConfirm(_ controller: ExportPreviewController, format: DocumentExporter.ExportFormat, options: ExportOptions) {
        guard let document = currentDocument else {
            dismissPreview()
            showError("No document available for export")
            return
        }

        dismissPreview()
        proceedWithExport(document: document, format: format, options: options)
    }

    func exportPreviewDidCancel(_ controller: ExportPreviewController) {
        dismissPreview()
    }
}
