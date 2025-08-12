import Foundation

struct AppVersion {
    static let current = Version(major: 1, minor: 2, patch: 0, build: getBuildNumber())
    
    struct Version {
        let major: Int
        let minor: Int
        let patch: Int
        let build: String
        
        var string: String {
            "\(major).\(minor).\(patch)"
        }
        
        var fullString: String {
            "\(major).\(minor).\(patch) (\(build))"
        }
    }
    
    static func getBuildNumber() -> String {
        // Use current date and time as build number
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd.HHmm"
        return formatter.string(from: Date())
    }
    
    static let changelog: [ChangelogEntry] = [
        ChangelogEntry(
            version: "1.2.0",
            date: Date(),
            changes: [
                "✨ Added 7 typography modes including Bionic and Dyslexic reading",
                "🎨 Implemented elegant mode indicator with animations",
                "📊 Added real-time performance monitoring overlay",
                "🔍 Integrated fuzzy search functionality",
                "📑 Added floating table of contents with progress indicators",
                "🌙 Night mode for reduced eye strain",
                "📖 Paper mode for classic reading experience",
                "⚡ Speed reading mode with optimized typography",
                "🧠 Bionic reading for faster comprehension",
                "♿ Dyslexic mode with OpenDyslexic font",
                "🔧 Fixed TOC progress bar direction",
                "🔧 Fixed typography mode switching degradation"
            ]
        ),
        ChangelogEntry(
            version: "1.1.0",
            date: Date(timeIntervalSinceNow: -86400 * 7),
            changes: [
                "Added Metal-accelerated text rendering",
                "Implemented progressive document loading",
                "Added wiki-link support",
                "Performance optimizations"
            ]
        ),
        ChangelogEntry(
            version: "1.0.0",
            date: Date(timeIntervalSinceNow: -86400 * 30),
            changes: [
                "Initial release",
                "Basic markdown rendering",
                "Table of contents",
                "Syntax highlighting"
            ]
        )
    ]
    
    struct ChangelogEntry {
        let version: String
        let date: Date
        let changes: [String]
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    static func checkForUpdates() -> Bool {
        // In a real app, this would check against a server
        // For now, we'll just return false
        return false
    }
}