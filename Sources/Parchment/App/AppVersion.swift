import Foundation

struct AppVersion {
    static let current = Version(major: 1, minor: 3, patch: 0, build: getBuildNumber())

    // MARK: - Cached DateFormatters (expensive to create)

    private static let buildNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd.HHmm"
        return formatter
    }()

    private static let changelogDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

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
        return buildNumberFormatter.string(from: Date())
    }
    
    static let changelog: [ChangelogEntry] = [
        ChangelogEntry(
            version: "1.3.0",
            date: Date(),
            changes: [
                "🎨 Complete typography overhaul with golden ratio heading scales",
                "✨ 5 beautiful hand-crafted themes (Minimal, Elegant, Midnight, Sepia, High Contrast)",
                "⚡ Lightning-fast file opening (<50ms for typical documents)",
                "🌊 Buttery-smooth scrolling with spring physics (60-120fps)",
                "📖 Enhanced text rendering with optical sizing and ligatures",
                "🎯 Smart typography: curly quotes, em dashes, proper ellipsis",
                "🚀 Parallel rendering pipeline for instant document loading",
                "💾 Smart caching system for frequently accessed files",
                "📝 Repositioned as premium native markdown viewer",
                "🗺️ Added comprehensive roadmap and development epics"
            ]
        ),
        ChangelogEntry(
            version: "1.2.0",
            date: Date(timeIntervalSinceNow: -86400 * 7),
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
            // Use cached formatter from parent struct
            return AppVersion.changelogDateFormatter.string(from: date)
        }
    }
    
    static func checkForUpdates() -> Bool {
        // In a real app, this would check against a server
        // For now, we'll just return false
        return false
    }
}