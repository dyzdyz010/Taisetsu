import XCTest

final class TaisetsuUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCreatesAnAnniversaryFromTheEmptyState() throws {
        let app = makeApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["首页"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["日历"].exists)
        XCTAssertTrue(app.tabBars.buttons["设置"].exists)

        let addButton = app.buttons["add-anniversary"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let nameField = app.textFields["名称"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("UI 测试纪念日")
        app.buttons["save-anniversary"].tap()

        XCTAssertTrue(app.staticTexts["UI 测试纪念日"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEditorUsesDateWheelsAndStructuredRecurrenceControls() throws {
        let app = makeApplication()
        app.launch()

        let addButton = app.buttons["add-anniversary"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        XCTAssertTrue(app.pickers["date-wheel-year"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.pickers["date-wheel-month"].exists)
        XCTAssertTrue(app.pickers["date-wheel-day"].exists)

        app.swipeUp()
        let recurrenceToggle = app.switches["recurrence-enabled"]
        XCTAssertTrue(recurrenceToggle.waitForExistence(timeout: 3))
        recurrenceToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        app.swipeUp()
        XCTAssertTrue(app.steppers["recurrence-interval"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["recurrence-unit"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.descendants(matching: .any)["next-occurrence-preview"].waitForExistence(timeout: 3)
        )
    }

    @MainActor
    func testRepeatUnitMenuRespondsToTap() throws {
        let app = makeApplication(language: "en")
        app.launch()

        let addButton = app.buttons["add-anniversary"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        app.swipeUp()
        let recurrenceToggle = app.switches["recurrence-enabled"]
        XCTAssertTrue(recurrenceToggle.waitForExistence(timeout: 3))
        recurrenceToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        app.swipeUp()

        let recurrenceUnit = app.buttons["recurrence-unit"]
        XCTAssertTrue(recurrenceUnit.waitForExistence(timeout: 3))
        recurrenceUnit.tap()

        XCTAssertTrue(app.buttons["Week"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            makeApplication().launch()
        }
    }

    @MainActor
    func testLaunchesWithEnglishLocalization() throws {
        let app = makeApplication(language: "en")
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Calendar"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
        XCTAssertTrue(app.navigationBars["Taisetsu"].exists)
    }

    @MainActor
    private func makeApplication(language: String = "zh-Hans") -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", language == "zh-Hans" ? "zh_CN" : "en_US",
        ]
        return app
    }
}
