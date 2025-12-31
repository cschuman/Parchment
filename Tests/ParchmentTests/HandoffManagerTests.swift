import XCTest
@testable import Parchment

final class HandoffManagerTests: XCTestCase {

    // MARK: - Properties

    private var manager: HandoffManager!
    private var testFileURL: URL!
    private var testFilePath: String!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        manager = HandoffManager.shared

        // Create a temporary test file
        let tempDir = FileManager.default.temporaryDirectory
        testFileURL = tempDir.appendingPathComponent("test-handoff-\(UUID().uuidString).md")
        testFilePath = testFileURL.path

        let testContent = """
        # Test Document

        This is a test markdown document for Handoff testing.

        ## Section 1

        Some content in section 1.

        ## Section 2

        Some content in section 2.
        """

        do {
            try testContent.write(toFile: testFilePath, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("Failed to create test file: \(error)")
        }
    }

    override func tearDown() {
        // Clean up test file
        try? FileManager.default.removeItem(at: testFileURL)

        // Invalidate any current activity
        manager.invalidateCurrentActivity()

        super.tearDown()
    }

    // MARK: - Activity Type Tests

    func testActivityTypeIsCorrect() {
        XCTAssertEqual(HandoffManager.activityType, "com.parchment.viewing",
                       "Activity type should match the expected identifier")
    }

    // MARK: - Begin Activity Tests

    func testBeginActivityCreatesCurrentActivity() {
        // Given
        let scrollPercentage = 0.5
        let theme = "Minimal"

        // When
        manager.beginActivity(for: testFileURL, scrollPercentage: scrollPercentage, theme: theme)

        // Then
        XCTAssertNotNil(manager.currentActivity,
                        "Current activity should be created after beginActivity")
    }

    func testBeginActivitySetsCorrectTitle() {
        // Given
        let scrollPercentage = 0.25
        let theme = "Elegant"

        // When
        manager.beginActivity(for: testFileURL, scrollPercentage: scrollPercentage, theme: theme)

        // Then
        XCTAssertNotNil(manager.currentActivity?.title,
                        "Activity should have a title")
        XCTAssertTrue(manager.currentActivity?.title?.contains(testFileURL.lastPathComponent) ?? false,
                      "Activity title should contain the document filename")
    }

    func testBeginActivitySetsUserInfo() {
        // Given
        let scrollPercentage = 0.75
        let theme = "Midnight"

        // When
        manager.beginActivity(for: testFileURL, scrollPercentage: scrollPercentage, theme: theme)

        // Then
        guard let userInfo = manager.currentActivity?.userInfo else {
            XCTFail("Activity should have userInfo")
            return
        }

        XCTAssertEqual(userInfo[HandoffManager.UserInfoKey.documentPath] as? String, testFileURL.path,
                       "UserInfo should contain correct document path")
        XCTAssertEqual(userInfo[HandoffManager.UserInfoKey.scrollPercentage] as? Double, scrollPercentage,
                       "UserInfo should contain correct scroll percentage")
        XCTAssertEqual(userInfo[HandoffManager.UserInfoKey.themeName] as? String, theme,
                       "UserInfo should contain correct theme name")
    }

    func testBeginActivitySetsHandoffEligibility() {
        // Given
        let scrollPercentage = 0.0
        let theme = "Sepia"

        // When
        manager.beginActivity(for: testFileURL, scrollPercentage: scrollPercentage, theme: theme)

        // Then
        XCTAssertTrue(manager.currentActivity?.isEligibleForHandoff ?? false,
                      "Activity should be eligible for Handoff")
    }

    func testBeginActivityInvalidatesPreviousActivity() {
        // Given - create first activity
        manager.beginActivity(for: testFileURL, scrollPercentage: 0.0, theme: "Minimal")
        let firstActivity = manager.currentActivity

        // Create a second test file
        let secondURL = FileManager.default.temporaryDirectory.appendingPathComponent("second-\(UUID().uuidString).md")
        try? "# Second".write(toFile: secondURL.path, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: secondURL) }

        // When - create second activity
        manager.beginActivity(for: secondURL, scrollPercentage: 0.5, theme: "Elegant")

        // Then
        XCTAssertNotEqual(manager.currentActivity, firstActivity,
                          "New activity should replace previous activity")
        XCTAssertTrue(manager.currentActivity?.userInfo?[HandoffManager.UserInfoKey.documentPath] as? String == secondURL.path,
                      "Current activity should be for the second document")
    }

    // MARK: - Update Scroll Position Tests

    func testUpdateScrollPositionUpdatesUserInfo() {
        // Given
        manager.beginActivity(for: testFileURL, scrollPercentage: 0.0, theme: "Minimal")

        // When
        manager.updateScrollPosition(0.5)

        // Allow debounce timer to fire
        let expectation = self.expectation(description: "Debounce timer")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Then
        let scrollPercentage = manager.currentActivity?.userInfo?[HandoffManager.UserInfoKey.scrollPercentage] as? Double
        XCTAssertNotNil(scrollPercentage, "Scroll percentage should be in userInfo")
        XCTAssertEqual(scrollPercentage ?? 0, 0.5, accuracy: 0.01,
                       "Scroll percentage should be updated to 0.5")
    }

    func testUpdateScrollPositionIgnoresSmallChanges() {
        // Given
        manager.beginActivity(for: testFileURL, scrollPercentage: 0.5, theme: "Minimal")

        // When - update with very small change
        manager.updateScrollPosition(0.505)

        // Allow time for any updates
        let expectation = self.expectation(description: "Wait for potential update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Then - should still be original value (0.5) because change was < 0.01
        let scrollPercentage = manager.currentActivity?.userInfo?[HandoffManager.UserInfoKey.scrollPercentage] as? Double
        XCTAssertEqual(scrollPercentage ?? 0, 0.5, accuracy: 0.01,
                       "Small scroll changes should be ignored")
    }

    // MARK: - Update Theme Tests

    func testUpdateThemeUpdatesUserInfo() {
        // Given
        manager.beginActivity(for: testFileURL, scrollPercentage: 0.5, theme: "Minimal")

        // When
        manager.updateTheme("Midnight")

        // Then
        let themeName = manager.currentActivity?.userInfo?[HandoffManager.UserInfoKey.themeName] as? String
        XCTAssertEqual(themeName, "Midnight",
                       "Theme should be updated in userInfo")
    }

    func testUpdateThemeDoesNothingWithoutActivity() {
        // Given - no activity started

        // When
        manager.updateTheme("Midnight")

        // Then - should not crash and no activity should exist
        XCTAssertNil(manager.currentActivity,
                     "No activity should exist when updateTheme called without beginActivity")
    }

    // MARK: - Invalidate Activity Tests

    func testInvalidateCurrentActivityClearsActivity() {
        // Given
        manager.beginActivity(for: testFileURL, scrollPercentage: 0.5, theme: "Minimal")
        XCTAssertNotNil(manager.currentActivity, "Activity should exist before invalidation")

        // When
        manager.invalidateCurrentActivity()

        // Then
        XCTAssertNil(manager.currentActivity,
                     "Activity should be nil after invalidation")
    }

    func testInvalidateCurrentActivityIsSafeToCallMultipleTimes() {
        // Given
        manager.beginActivity(for: testFileURL, scrollPercentage: 0.5, theme: "Minimal")

        // When - call multiple times
        manager.invalidateCurrentActivity()
        manager.invalidateCurrentActivity()
        manager.invalidateCurrentActivity()

        // Then - should not crash
        XCTAssertNil(manager.currentActivity,
                     "Activity should remain nil after multiple invalidations")
    }

    // MARK: - Handle Incoming Activity Tests

    func testHandleIncomingActivityWithValidData() {
        // Given
        let activity = NSUserActivity(activityType: HandoffManager.activityType)
        activity.userInfo = [
            HandoffManager.UserInfoKey.documentPath: testFilePath!,
            HandoffManager.UserInfoKey.scrollPercentage: 0.75,
            HandoffManager.UserInfoKey.themeName: "Elegant"
        ]

        // When
        let result = manager.handleIncomingActivity(activity)

        // Then
        XCTAssertNotNil(result, "Should return HandoffData for valid activity")
        XCTAssertEqual(result?.documentURL.path, testFilePath,
                       "Document URL should match")
        XCTAssertEqual(result?.scrollPercentage ?? 0, 0.75, accuracy: 0.001,
                       "Scroll percentage should match")
        XCTAssertEqual(result?.themeName, "Elegant",
                       "Theme name should match")
    }

    func testHandleIncomingActivityWithWrongActivityType() {
        // Given
        let activity = NSUserActivity(activityType: "com.other.activity")
        activity.userInfo = [
            HandoffManager.UserInfoKey.documentPath: testFilePath!
        ]

        // When
        let result = manager.handleIncomingActivity(activity)

        // Then
        XCTAssertNil(result,
                     "Should return nil for wrong activity type")
    }

    func testHandleIncomingActivityWithMissingPath() {
        // Given
        let activity = NSUserActivity(activityType: HandoffManager.activityType)
        activity.userInfo = [
            HandoffManager.UserInfoKey.scrollPercentage: 0.5
        ]

        // When
        let result = manager.handleIncomingActivity(activity)

        // Then
        XCTAssertNil(result,
                     "Should return nil when document path is missing")
    }

    func testHandleIncomingActivityWithNonexistentFile() {
        // Given
        let activity = NSUserActivity(activityType: HandoffManager.activityType)
        activity.userInfo = [
            HandoffManager.UserInfoKey.documentPath: "/nonexistent/file.md",
            HandoffManager.UserInfoKey.scrollPercentage: 0.5
        ]

        // When
        let result = manager.handleIncomingActivity(activity)

        // Then
        XCTAssertNil(result,
                     "Should return nil when file does not exist")
    }

    func testHandleIncomingActivityWithMissingTheme() {
        // Given
        let activity = NSUserActivity(activityType: HandoffManager.activityType)
        activity.userInfo = [
            HandoffManager.UserInfoKey.documentPath: testFilePath!,
            HandoffManager.UserInfoKey.scrollPercentage: 0.5
            // Note: no theme
        ]

        // When
        let result = manager.handleIncomingActivity(activity)

        // Then
        XCTAssertNotNil(result,
                        "Should return HandoffData even without theme")
        XCTAssertNil(result?.themeName,
                     "Theme should be nil when not provided")
    }

    func testHandleIncomingActivityWithMissingScrollPercentage() {
        // Given
        let activity = NSUserActivity(activityType: HandoffManager.activityType)
        activity.userInfo = [
            HandoffManager.UserInfoKey.documentPath: testFilePath!
            // Note: no scroll percentage
        ]

        // When
        let result = manager.handleIncomingActivity(activity)

        // Then
        XCTAssertNotNil(result,
                        "Should return HandoffData even without scroll percentage")
        XCTAssertEqual(result?.scrollPercentage, 0,
                       "Scroll percentage should default to 0")
    }

    // MARK: - UserInfoKey Tests

    func testUserInfoKeyValues() {
        XCTAssertEqual(HandoffManager.UserInfoKey.documentPath, "documentPath",
                       "documentPath key should match expected value")
        XCTAssertEqual(HandoffManager.UserInfoKey.scrollPercentage, "scrollPercentage",
                       "scrollPercentage key should match expected value")
        XCTAssertEqual(HandoffManager.UserInfoKey.themeName, "theme",
                       "themeName key should match expected value")
    }

    // MARK: - HandoffData Tests

    func testHandoffDataInitialization() {
        // Given
        let url = URL(fileURLWithPath: "/path/to/document.md")
        let scrollPercentage = 0.5
        let themeName = "Minimal"

        // When
        let data = HandoffData(
            documentURL: url,
            scrollPercentage: scrollPercentage,
            themeName: themeName
        )

        // Then
        XCTAssertEqual(data.documentURL, url,
                       "documentURL should match")
        XCTAssertEqual(data.scrollPercentage, scrollPercentage,
                       "scrollPercentage should match")
        XCTAssertEqual(data.themeName, themeName,
                       "themeName should match")
    }

    func testHandoffDataWithNilTheme() {
        // Given
        let url = URL(fileURLWithPath: "/path/to/document.md")
        let scrollPercentage = 0.75

        // When
        let data = HandoffData(
            documentURL: url,
            scrollPercentage: scrollPercentage,
            themeName: nil
        )

        // Then
        XCTAssertEqual(data.documentURL, url,
                       "documentURL should match")
        XCTAssertEqual(data.scrollPercentage, scrollPercentage,
                       "scrollPercentage should match")
        XCTAssertNil(data.themeName,
                     "themeName should be nil")
    }
}
