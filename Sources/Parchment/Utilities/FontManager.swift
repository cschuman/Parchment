import Cocoa
import CoreText
import os.log

final class FontManager {
    static let shared = FontManager()
    
    private init() {}
    
    func registerCustomFonts() {
        // Register OpenDyslexic font
        if let fontURL = Bundle.main.url(forResource: "OpenDyslexic-Regular", withExtension: "otf") {
            registerFont(at: fontURL)
            Logger.info("Found OpenDyslexic font at: \(fontURL.path)")
        } else {
            Logger.debug("OpenDyslexic font not found in bundle")
            // Try alternative path
            if let resourcePath = Bundle.main.resourcePath {
                let fontPath = "\(resourcePath)/OpenDyslexic-Regular.otf"
                if FileManager.default.fileExists(atPath: fontPath) {
                    let fontURL = URL(fileURLWithPath: fontPath)
                    registerFont(at: fontURL)
                    Logger.info("Registered OpenDyslexic from direct path")
                }
            }
        }
        
        // Debug: List all available fonts with "Dys" in name
        let fonts = NSFontManager.shared.availableFonts.filter { $0.lowercased().contains("dys") }
        Logger.debug("Available dyslexic fonts: \(fonts)")
    }
    
    private func registerFont(at url: URL) {
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            if let error = error?.takeRetainedValue() {
                Logger.error("Failed to register font: \(error)")
            }
        } else {
            Logger.info("Successfully registered font: \(url.lastPathComponent)")
        }
    }
    
    func availableFontNames() -> [String] {
        return NSFontManager.shared.availableFonts
    }
    
    func isFontAvailable(_ fontName: String) -> Bool {
        return NSFont(name: fontName, size: 12) != nil
    }
}