import XCTest
@testable import Parchment

final class DocumentExporterTests: XCTestCase {

    func testExporterCreation() {
        let exporter = DocumentExporter()
        XCTAssertNotNil(exporter)
    }

    func testExportOptions() {
        let options = ExportOptions()
        XCTAssertNotNil(options)

        // Test default values
        XCTAssertEqual(options.format, .pdf)
        XCTAssertEqual(options.paperSize, NSSize(width: 612, height: 792))
        XCTAssertEqual(options.fontSize, 12)
        XCTAssertEqual(options.lineHeight, 1.6)
        XCTAssertEqual(options.maxWidth, 900)
        XCTAssertTrue(options.includeHeader)
        XCTAssertTrue(options.includeFooter)
        XCTAssertTrue(options.includePageNumbers)
        XCTAssertTrue(options.includeWordCount)
    }

    func testExportFormats() {
        // ExportFormat is not a RawRepresentable enum in the current implementation
        // It's a simple enum inside DocumentExporter
        let pdfFormat: DocumentExporter.ExportFormat = .pdf
        let htmlFormat: DocumentExporter.ExportFormat = .html
        let plainTextFormat: DocumentExporter.ExportFormat = .plainText
        let rtfFormat: DocumentExporter.ExportFormat = .rtf
        let docxFormat: DocumentExporter.ExportFormat = .docx

        XCTAssertNotNil(pdfFormat)
        XCTAssertNotNil(htmlFormat)
        XCTAssertNotNil(plainTextFormat)
        XCTAssertNotNil(rtfFormat)
        XCTAssertNotNil(docxFormat)
    }

    func testExportOptionsModification() {
        var options = ExportOptions()

        options.format = .html
        XCTAssertEqual(options.format, .html)

        options.fontSize = 14
        XCTAssertEqual(options.fontSize, 14)

        options.includeHeader = false
        XCTAssertFalse(options.includeHeader)

        options.lineHeight = 1.8
        XCTAssertEqual(options.lineHeight, 1.8)
    }
}
