import Cocoa
import CoreText

final class FontManager {
    static let shared = FontManager()
    
    private init() {}
    
    func registerCustomFonts() {
        // Register OpenDyslexic font
        if let fontURL = Bundle.main.url(forResource: "OpenDyslexic-Regular", withExtension: "otf") {
            registerFont(at: fontURL)
            print("Found OpenDyslexic font at: \(fontURL)")
        } else {
            print("OpenDyslexic font not found in bundle")
            // Try alternative path
            if let resourcePath = Bundle.main.resourcePath {
                let fontPath = "\(resourcePath)/OpenDyslexic-Regular.otf"
                if FileManager.default.fileExists(atPath: fontPath) {
                    let fontURL = URL(fileURLWithPath: fontPath)
                    registerFont(at: fontURL)
                    print("Registered OpenDyslexic from direct path")
                }
            }
        }
        
        // Debug: List all available fonts with "Dys" in name
        let fonts = NSFontManager.shared.availableFonts.filter { $0.lowercased().contains("dys") }
        print("Available dyslexic fonts: \(fonts)")
    }
    
    private func registerFont(at url: URL) {
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            if let error = error?.takeRetainedValue() {
                print("Failed to register font: \(error)")
            }
        } else {
            print("Successfully registered font from: \(url.lastPathComponent)")
        }
    }
    
    func availableFontNames() -> [String] {
        return NSFontManager.shared.availableFonts
    }
    
    func isFontAvailable(_ fontName: String) -> Bool {
        return NSFont(name: fontName, size: 12) != nil
    }
}