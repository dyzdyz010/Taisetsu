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
    func testCountStylePickerRespondsToTap() throws {
        let app = makeApplication(language: "en")
        app.launch()

        let addButton = app.buttons["add-anniversary"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        app.swipeUp()

        let countStyle = app.descendants(matching: .any)["count-style"]
        XCTAssertTrue(countStyle.waitForExistence(timeout: 3))
        countStyle.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["Count Up"].waitForExistence(timeout: 3)
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            makeApplication().launch()
        }
    }

    @MainActor
    func testCalendarNavigationPerformance() throws {
        let app = makeApplication(language: "en")
        app.launch()

        let calendarTab = app.tabBars.buttons["Calendar"]
        XCTAssertTrue(calendarTab.waitForExistence(timeout: 5))
        calendarTab.tap()
        let next = app.buttons["calendar-next-month"]
        let previous = app.buttons["calendar-previous-month"]
        XCTAssertTrue(next.waitForExistence(timeout: 3))
        XCTAssertTrue(previous.exists)

        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<5 {
                next.tap()
                previous.tap()
            }
        }

        XCTAssertTrue(next.exists)
        XCTAssertTrue(previous.exists)
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
    func testIPadUsesSidebarNavigation() throws {
        let app = makeApplication(language: "en", orientation: .landscapeLeft)
        app.launch()

        let windowSize = app.windows.firstMatch.frame.size
        guard min(windowSize.width, windowSize.height) >= 700 else {
            throw XCTSkip("This navigation contract applies only to regular-width iPad layouts.")
        }

        XCTAssertTrue(
            app.descendants(matching: .any)["app-sidebar"].waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.tabBars.firstMatch.exists)

        let calendar = app.buttons["sidebar-calendar"]
        XCTAssertTrue(calendar.exists)
        calendar.tap()
        XCTAssertTrue(app.navigationBars["Calendar"].waitForExistence(timeout: 3))

        let settings = app.buttons["sidebar-settings"]
        XCTAssertTrue(settings.exists)
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))

        let home = app.buttons["sidebar-home"]
        XCTAssertTrue(home.exists)
        home.tap()
        XCTAssertTrue(app.navigationBars["Taisetsu"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testCalendarSyncSettingsFollowSupportedLocales() throws {
        let cases = [
            ("en", "en_US", "Settings", "Calendar Sync", "Stopped"),
            ("zh-Hans", "zh_CN", "设置", "日历同步", "已停止"),
            ("zh-Hant", "zh_TW", "設定", "行事曆同步", "已停止"),
            ("nb", "nb_NO", "Innstillinger", "Kalendersynkronisering", "Stoppet"),
            ("de", "de_DE", "Einstellungen", "Kalendersynchronisierung", "Gestoppt"),
        ]

        for (language, locale, settingsTitle, syncTitle, stopped) in cases {
            let app = makeApplication(language: language, locale: locale)
            app.launch()

            let settingsTab = app.tabBars.buttons.element(boundBy: 2)
            XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
            XCTAssertEqual(settingsTab.label, settingsTitle)
            settingsTab.tap()
            XCTAssertTrue(app.navigationBars[settingsTitle].waitForExistence(timeout: 3))

            let calendarSync = app.buttons["calendar-sync-settings"]
            XCTAssertTrue(calendarSync.waitForExistence(timeout: 3))
            calendarSync.tap()
            XCTAssertTrue(app.navigationBars[syncTitle].waitForExistence(timeout: 3))
            let syncStatus = app.staticTexts["calendar-sync-status"]
            XCTAssertTrue(syncStatus.waitForExistence(timeout: 3))
            XCTAssertEqual(syncStatus.label, stopped)

            app.terminate()
        }
    }

    @MainActor
    private func makeApplication(
        language: String = "zh-Hans",
        locale: String? = nil,
        orientation: UIDeviceOrientation = .portrait
    ) -> XCUIApplication {
        XCUIDevice.shared.orientation = orientation
        let app = XCUIApplication()
        let locale = locale ?? (language == "zh-Hans" ? "zh_CN" : "en_US")
        app.launchArguments = [
            "-ui-testing",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ]
        return app
    }
}
