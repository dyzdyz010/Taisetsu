//
//  LifeTimerUITestsLaunchTests.swift
//  LifeTimerUITests
//
//  Created by 杜艺卓 on 2026/8/3.
//

import XCTest

final class LifeTimerUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "LifeTimer Home"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
