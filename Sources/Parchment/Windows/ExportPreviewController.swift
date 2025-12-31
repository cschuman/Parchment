import Cocoa
import PDFKit
import WebKit

/// Delegate protocol for export preview actions
protocol ExportPreviewDelegate: AnyObject {
    func exportPreviewDidConfirm(_ controller: ExportPreviewController, format: DocumentExporter.ExportFormat, options: ExportOptions)
    func exportPreviewDidCancel(_ controller: ExportPreviewController)
}

/// Controller for the export preview sheet that shows a preview of the exported document
final class ExportPreviewController: NSViewController {

    // MARK: - Properties

    private let document: MarkdownDocument
    private let documentExporter: DocumentExporter
    private var currentFormat: DocumentExporter.ExportFormat = .pdf
    private var exportOptions: ExportOptions

    weak var delegate: ExportPreviewDelegate?

    // MARK: - UI Components

    private var formatSelector: NSSegmentedControl!
    private var previewContainer: NSView!
    private var pdfPreview: PDFView?
    private var htmlPreview: WKWebView?
    private var rtfPreview: NSScrollView?
    private var loadingIndicator: NSProgressIndicator!
    private var cancelButton: NSButton!
    private var exportButton: NSButton!
    private var optionsDisclosure: NSButton!
    private var optionsContainer: NSStackView!

    // Options controls
    private var templateSelector: NSPopUpButton!
    private var includeHeaderCheckbox: NSButton!
    private var includeFooterCheckbox: NSButton!
    private var themeSelector: NSPopUpButton!

    // MARK: - Initialization

    init(document: MarkdownDocument, exporter: DocumentExporter? = nil) {
        self.document = document
        self.documentExporter = exporter ?? DocumentExporter()
        self.exportOptions = ExportOptions()

        // Set initial theme based on app appearance
        if NSApp.appearance?.name == .darkAqua {
            self.exportOptions.theme = .dark
        }

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 550))
        containerView.wantsLayer = true
        self.view = containerView

        setupUI()
        setupConstraints()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updatePreview()
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Format selector
        formatSelector = NSSegmentedControl(labels: ["PDF", "HTML", "RTF"], trackingMode: .selectOne, target: self, action: #selector(formatChanged(_:)))
        formatSelector.selectedSegment = 0
        formatSelector.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(formatSelector)

        // Preview container
        previewContainer = NSView()
        previewContainer.wantsLayer = true
        previewContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        previewContainer.layer?.cornerRadius = 8
        previewContainer.layer?.borderWidth = 1
        previewContainer.layer?.borderColor = NSColor.separatorColor.cgColor
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewContainer)

        // Loading indicator
        loadingIndicator = NSProgressIndicator()
        loadingIndicator.style = .spinning
        loadingIndicator.controlSize = .regular
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.isHidden = true
        previewContainer.addSubview(loadingIndicator)

        // Options disclosure button
        optionsDisclosure = NSButton(title: "Options", target: self, action: #selector(toggleOptions(_:)))
        optionsDisclosure.bezelStyle = .disclosure
        optionsDisclosure.state = .off
        optionsDisclosure.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(optionsDisclosure)

        // Options container
        optionsContainer = NSStackView()
        optionsContainer.orientation = .vertical
        optionsContainer.alignment = .leading
        optionsContainer.spacing = 8
        optionsContainer.translatesAutoresizingMaskIntoConstraints = false
        optionsContainer.isHidden = true
        view.addSubview(optionsContainer)

        setupOptionsControls()

        // Buttons
        cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelExport(_:)))
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}" // Escape key
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)

        exportButton = NSButton(title: "Export...", target: self, action: #selector(confirmExport(_:)))
        exportButton.bezelStyle = .rounded
        exportButton.keyEquivalent = "\r" // Return key
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exportButton)

        setupPreviewViews()
    }

    private func setupOptionsControls() {
        // Template selector
        let templateLabel = NSTextField(labelWithString: "Template:")
        templateSelector = NSPopUpButton()
        templateSelector.addItems(withTitles: ExportTemplate.all.map { $0.name })
        templateSelector.selectItem(at: 0)  // Standard template
        templateSelector.target = self
        templateSelector.action = #selector(templateChanged(_:))

        // Add tooltips for template descriptions
        for (index, template) in ExportTemplate.all.enumerated() {
            templateSelector.item(at: index)?.toolTip = template.description
        }

        let templateStack = NSStackView(views: [templateLabel, templateSelector])
        templateStack.orientation = .horizontal
        templateStack.spacing = 8

        // Include header checkbox
        includeHeaderCheckbox = NSButton(checkboxWithTitle: "Include header", target: self, action: #selector(optionsChanged(_:)))
        includeHeaderCheckbox.state = exportOptions.includeHeader ? .on : .off

        // Include footer checkbox
        includeFooterCheckbox = NSButton(checkboxWithTitle: "Include footer", target: self, action: #selector(optionsChanged(_:)))
        includeFooterCheckbox.state = exportOptions.includeFooter ? .on : .off

        // Theme selector
        let themeLabel = NSTextField(labelWithString: "Theme:")
        themeSelector = NSPopUpButton()
        themeSelector.addItems(withTitles: ["Light", "Dark"])
        themeSelector.selectItem(at: exportOptions.theme == .dark ? 1 : 0)
        themeSelector.target = self
        themeSelector.action = #selector(optionsChanged(_:))

        let themeStack = NSStackView(views: [themeLabel, themeSelector])
        themeStack.orientation = .horizontal
        themeStack.spacing = 8

        optionsContainer.addArrangedSubview(templateStack)
        optionsContainer.addArrangedSubview(includeHeaderCheckbox)
        optionsContainer.addArrangedSubview(includeFooterCheckbox)
        optionsContainer.addArrangedSubview(themeStack)
    }

    @objc private func templateChanged(_ sender: NSPopUpButton) {
        let selectedIndex = sender.indexOfSelectedItem
        guard selectedIndex >= 0 && selectedIndex < ExportTemplate.all.count else { return }

        let template = ExportTemplate.all[selectedIndex]
        exportOptions.applyTemplate(template)

        // Update UI controls to reflect template settings
        includeHeaderCheckbox.state = exportOptions.includeHeader ? .on : .off
        includeFooterCheckbox.state = exportOptions.includeFooter ? .on : .off

        updatePreview()
    }

    private func setupPreviewViews() {
        // PDF Preview
        pdfPreview = PDFView()
        pdfPreview?.autoScales = true
        pdfPreview?.displayMode = .singlePageContinuous
        pdfPreview?.backgroundColor = .controlBackgroundColor
        pdfPreview?.translatesAutoresizingMaskIntoConstraints = false
        pdfPreview?.isHidden = false

        // HTML Preview
        let webConfig = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = false
        webConfig.defaultWebpagePreferences = preferences
        webConfig.suppressesIncrementalRendering = true

        htmlPreview = WKWebView(frame: .zero, configuration: webConfig)
        htmlPreview?.translatesAutoresizingMaskIntoConstraints = false
        htmlPreview?.isHidden = true

        // RTF Preview
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.backgroundColor = .textBackgroundColor
        scrollView.documentView = textView

        rtfPreview = scrollView
        rtfPreview?.isHidden = true

        // Add all preview views to container
        if let pdfView = pdfPreview {
            previewContainer.addSubview(pdfView)
        }
        if let htmlView = htmlPreview {
            previewContainer.addSubview(htmlView)
        }
        if let rtfView = rtfPreview {
            previewContainer.addSubview(rtfView)
        }
    }

    private func setupConstraints() {
        guard let pdfView = pdfPreview,
              let htmlView = htmlPreview,
              let rtfView = rtfPreview else { return }

        NSLayoutConstraint.activate([
            // Format selector
            formatSelector.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            formatSelector.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Preview container
            previewContainer.topAnchor.constraint(equalTo: formatSelector.bottomAnchor, constant: 16),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            previewContainer.bottomAnchor.constraint(equalTo: optionsDisclosure.topAnchor, constant: -16),

            // Loading indicator (centered in preview container)
            loadingIndicator.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),

            // Preview views (fill container)
            pdfView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            htmlView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            htmlView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            htmlView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            htmlView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            rtfView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            rtfView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            rtfView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            rtfView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            // Options disclosure
            optionsDisclosure.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            optionsDisclosure.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -12),

            // Options container
            optionsContainer.topAnchor.constraint(equalTo: optionsDisclosure.bottomAnchor, constant: 8),
            optionsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 36),
            optionsContainer.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            // Buttons
            cancelButton.trailingAnchor.constraint(equalTo: exportButton.leadingAnchor, constant: -12),
            cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),

            exportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            exportButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
        ])
    }

    // MARK: - Actions

    @objc private func formatChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            currentFormat = .pdf
        case 1:
            currentFormat = .html
        case 2:
            currentFormat = .rtf
        default:
            currentFormat = .pdf
        }

        updatePreviewVisibility()
        updatePreview()
    }

    @objc private func toggleOptions(_ sender: NSButton) {
        let isExpanded = sender.state == .on
        optionsContainer.isHidden = !isExpanded

        // Animate the view height change
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            view.layoutSubtreeIfNeeded()
        }
    }

    @objc private func optionsChanged(_ sender: Any) {
        exportOptions.includeHeader = includeHeaderCheckbox.state == .on
        exportOptions.includeFooter = includeFooterCheckbox.state == .on
        exportOptions.theme = themeSelector.indexOfSelectedItem == 1 ? .dark : .light

        updatePreview()
    }

    @objc private func cancelExport(_ sender: NSButton) {
        delegate?.exportPreviewDidCancel(self)
    }

    @objc private func confirmExport(_ sender: NSButton) {
        exportOptions.format = currentFormat
        delegate?.exportPreviewDidConfirm(self, format: currentFormat, options: exportOptions)
    }

    // MARK: - Preview Updates

    private func updatePreviewVisibility() {
        pdfPreview?.isHidden = currentFormat != .pdf
        htmlPreview?.isHidden = currentFormat != .html
        rtfPreview?.isHidden = currentFormat != .rtf
    }

    private func updatePreview() {
        showLoading(true)

        Task { @MainActor in
            do {
                switch currentFormat {
                case .pdf:
                    try await updatePDFPreview()
                case .html:
                    updateHTMLPreview()
                case .rtf:
                    try updateRTFPreview()
                case .docx, .plainText:
                    // These formats don't support preview
                    break
                }
            } catch {
                Logger.error("Failed to generate preview: \(error)")
                showPreviewError(error)
            }

            showLoading(false)
        }
    }

    private func showLoading(_ show: Bool) {
        loadingIndicator.isHidden = !show
        if show {
            loadingIndicator.startAnimation(nil)
        } else {
            loadingIndicator.stopAnimation(nil)
        }
    }

    private func showPreviewError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Preview Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")

        if let window = view.window {
            alert.beginSheetModal(for: window, completionHandler: nil)
        }
    }

    // MARK: - Preview Generation

    private func updatePDFPreview() async throws {
        let pdfData = try await documentExporter.generatePDFPreview(document: document, options: exportOptions)

        await MainActor.run {
            if let pdfDocument = PDFDocument(data: pdfData) {
                pdfPreview?.document = pdfDocument
            }
        }
    }

    private func updateHTMLPreview() {
        let html = documentExporter.generateHTMLPreview(document: document, options: exportOptions)
        htmlPreview?.loadHTMLString(html, baseURL: nil)
    }

    private func updateRTFPreview() throws {
        let attributedString = try documentExporter.generateRTFPreview(document: document, options: exportOptions)

        if let textView = rtfPreview?.documentView as? NSTextView {
            textView.textStorage?.setAttributedString(attributedString)
        }
    }

    // MARK: - Public Methods

    /// Set the initial format for the preview
    func setInitialFormat(_ format: DocumentExporter.ExportFormat) {
        currentFormat = format

        switch format {
        case .pdf:
            formatSelector.selectedSegment = 0
        case .html:
            formatSelector.selectedSegment = 1
        case .rtf:
            formatSelector.selectedSegment = 2
        case .docx, .plainText:
            // Default to PDF for unsupported preview formats
            formatSelector.selectedSegment = 0
            currentFormat = .pdf
        }

        updatePreviewVisibility()
    }
}
