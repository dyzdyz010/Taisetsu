//
//  TaisetsuUITestsLaunchTests.swift
//  TaisetsuUITests
//
//  Created by 杜艺卓 on 2026/8/3.
//

import XCTest

final class TaisetsuUITestsLaunchTests: XCTestCase {

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
        attachment.name = "Taisetsu Home"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
