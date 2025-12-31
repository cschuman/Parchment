import Cocoa

/// Manages Handoff user activities for document viewing continuity across devices
final class HandoffManager {

    // MARK: - Types

    /// Activity type identifier for viewing documents
    static let activityType = "com.parchment.viewing"

    /// User info keys for activity data
    enum UserInfoKey {
        static let documentPath = "documentPath"
        static let scrollPercentage = "scrollPercentage"
        static let themeName = "theme"
    }

    // MARK: - Singleton

    static let shared = HandoffManager()

    // MARK: - Properties

    /// The current user activity being advertised
    private(set) var currentActivity: NSUserActivity?

    /// Debounce timer for scroll updates
    private var updateTimer: Timer?

    /// Minimum interval between activity updates (seconds)
    private let updateDebounceInterval: TimeInterval = 1.0

    /// Last scroll percentage to avoid redundant updates
    private var lastScrollPercentage: Double = 0

    // MARK: - Initialization

    private init() {}

    deinit {
        invalidateCurrentActivity()
    }

    // MARK: - Activity Creation

    /// Creates and begins advertising a new user activity for the given document
    /// - Parameters:
    ///   - url: The document URL
    ///   - scrollPercentage: Current scroll position (0.0 to 1.0)
    ///   - theme: Current theme name
    func beginActivity(for url: URL, scrollPercentage: Double, theme: String) {
        // Invalidate any existing activity
        invalidateCurrentActivity()

        // Create new activity
        let activity = NSUserActivity(activityType: Self.activityType)
        activity.title = "Viewing \(url.lastPathComponent)"
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = false // Spotlight handles search separately
        activity.isEligibleForPublicIndexing = false

        // Set user info with document state
        activity.userInfo = [
            UserInfoKey.documentPath: url.path,
            UserInfoKey.scrollPercentage: scrollPercentage,
            UserInfoKey.themeName: theme
        ]

        // Required for Handoff: set needsSave to true to trigger delegate callbacks
        activity.needsSave = true

        // Make activity current
        activity.becomeCurrent()
        currentActivity = activity
        lastScrollPercentage = scrollPercentage

        Logger.info("Handoff: Started activity for \(url.lastPathComponent) at \(Int(scrollPercentage * 100))%")
    }

    /// Updates the current activity with new scroll position
    /// - Parameter scrollPercentage: New scroll position (0.0 to 1.0)
    func updateScrollPosition(_ scrollPercentage: Double) {
        // Ignore small changes to reduce update frequency
        guard abs(scrollPercentage - lastScrollPercentage) > 0.01 else { return }

        // Debounce updates
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: updateDebounceInterval, repeats: false) { [weak self] _ in
            self?.performScrollUpdate(scrollPercentage)
        }
    }

    /// Updates the current activity with new theme
    /// - Parameter theme: New theme name
    func updateTheme(_ theme: String) {
        guard let activity = currentActivity,
              var userInfo = activity.userInfo else { return }

        userInfo[UserInfoKey.themeName] = theme
        activity.userInfo = userInfo
        activity.needsSave = true

        Logger.info("Handoff: Updated theme to \(theme)")
    }

    /// Invalidates the current activity when document is closed
    func invalidateCurrentActivity() {
        updateTimer?.invalidate()
        updateTimer = nil

        currentActivity?.invalidate()
        currentActivity = nil
        lastScrollPercentage = 0

        Logger.info("Handoff: Invalidated current activity")
    }

    // MARK: - Receiving Handoff

    /// Handles an incoming Handoff activity
    /// - Parameter userActivity: The received user activity
    /// - Returns: HandoffData if successfully parsed, nil otherwise
    func handleIncomingActivity(_ userActivity: NSUserActivity) -> HandoffData? {
        guard userActivity.activityType == Self.activityType else {
            Logger.warning("Handoff: Received unknown activity type: \(userActivity.activityType)")
            return nil
        }

        guard let userInfo = userActivity.userInfo,
              let documentPath = userInfo[UserInfoKey.documentPath] as? String else {
            Logger.error("Handoff: Missing document path in activity")
            return nil
        }

        let scrollPercentage = userInfo[UserInfoKey.scrollPercentage] as? Double ?? 0
        let themeName = userInfo[UserInfoKey.themeName] as? String

        let url = URL(fileURLWithPath: documentPath)

        // Verify file exists
        guard FileManager.default.fileExists(atPath: documentPath) else {
            Logger.error("Handoff: Document not found at path: \(documentPath)")
            return nil
        }

        Logger.info("Handoff: Received activity for \(url.lastPathComponent) at \(Int(scrollPercentage * 100))%")

        return HandoffData(
            documentURL: url,
            scrollPercentage: scrollPercentage,
            themeName: themeName
        )
    }

    // MARK: - Private Methods

    private func performScrollUpdate(_ scrollPercentage: Double) {
        guard let activity = currentActivity,
              var userInfo = activity.userInfo else { return }

        userInfo[UserInfoKey.scrollPercentage] = scrollPercentage
        activity.userInfo = userInfo
        activity.needsSave = true
        lastScrollPercentage = scrollPercentage

        Logger.debug("Handoff: Updated scroll position to \(Int(scrollPercentage * 100))%")
    }
}

// MARK: - HandoffData

/// Data extracted from an incoming Handoff activity
struct HandoffData {
    let documentURL: URL
    let scrollPercentage: Double
    let themeName: String?
}
