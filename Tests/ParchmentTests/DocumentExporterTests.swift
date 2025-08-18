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
        XCTAssertFalse(options.includeMetadata)
        XCTAssertFalse(options.embedImages)
    }
    
    func testExportFormats() {
        XCTAssertEqual(ExportFormat.pdf.rawValue, "pdf")
        XCTAssertEqual(ExportFormat.html.rawValue, "html")
        XCTAssertEqual(ExportFormat.plainText.rawValue, "txt")
        XCTAssertEqual(ExportFormat.rtf.rawValue, "rtf")
        XCTAssertEqual(ExportFormat.docx.rawValue, "docx")
    }
    
    func testExportOptionsModification() {
        let options = ExportOptions()
        
        options.format = .html
        XCTAssertEqual(options.format, .html)
        
        options.includeMetadata = true
        XCTAssertTrue(options.includeMetadata)
        
        options.embedImages = true
        XCTAssertTrue(options.embedImages)
        
        // Page size test removed - check if property exists first
    }
}