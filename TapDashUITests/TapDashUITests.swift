import XCTest

/// UI tests drive the real app the way a player would: launching it, finding elements and tapping them.
/// Elements are found by the `accessibilityIdentifier`s set in GameView.swift.
final class TapDashUITests: XCTestCase {

    private var app: XCUIApplication!

    @MainActor
    override func setUpWithError() throws {
        // In UI tests it's usually best to stop at the first failure.
        continueAfterFailure = false

        app = XCUIApplication()
        // Launch arguments are read by UserDefaults (the same trick as Lesson 5),
        // so every test starts with a best score of 0, whatever was saved before.
        app.launchArguments = ["-bestScore", "0"]
        app.launch()
    }

    @MainActor
    func testStartScreenIsShownOnLaunch() throws {
        XCTAssertTrue(app.staticTexts["Tap Dash"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["startButton"].exists)
        XCTAssertFalse(app.buttons["target"].exists, "The target should only appear once a round starts")
    }

    @MainActor
    func testTappingTheTargetScoresPoints() throws {
        let startButton = app.buttons["startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let target = app.buttons["target"]
        XCTAssertTrue(target.waitForExistence(timeout: 2), "Starting a round should show the target")

        let score = app.staticTexts["score"]
        XCTAssertEqual(score.value as? String, "0")

        for _ in 0..<3 {
            target.tap()
        }

        XCTAssertEqual(score.value as? String, "3")
    }

    @MainActor
    func testTimerCountsDown() throws {
        app.buttons["startButton"].tap()

        let time = app.staticTexts["time"]
        XCTAssertEqual(time.value as? String, "30 seconds")

        // Wait up to 3 seconds for the timer to drop below 30.
        let tickedDown = NSPredicate(format: "value != %@", "30 seconds")
        expectation(for: tickedDown, evaluatedWith: time)
        waitForExpectations(timeout: 3)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // Measures how long the app takes to launch.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
