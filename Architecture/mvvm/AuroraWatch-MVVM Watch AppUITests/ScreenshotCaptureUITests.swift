//
//  ScreenshotCaptureUITests.swift
//  AuroraWatch-MVVM Watch AppUITests
//
//  Created by Sarah Clark on 7/16/26.
//

import XCTest

/// Captures the README screenshots as test attachments.
///
/// Each capture drives the app against stub data so the images are
/// deterministic. Export them from the result bundle with
/// `xcrun xcresulttool export attachments`.
final class ScreenshotCaptureUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches with a stub scenario and waits for an identifier to appear.
    @MainActor
    private func launchApp(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_STUB_SCENARIO"] = scenario
        app.launch()
        return app
    }

    /// Attaches a screenshot that survives the test run.
    @MainActor
    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCaptureForecastList() throws {
        let app = launchApp(scenario: "happy")

        let firstRow = app.descendants(matching: .any).matching(identifier: "forecast.row.0").firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 10))

        attachScreenshot(of: app, named: "ForecastList")
    }

    @MainActor
    func testCaptureForecastDetail() throws {
        let app = launchApp(scenario: "g3")

        let stormRow = app.descendants(matching: .any).matching(identifier: "forecast.row.1").firstMatch
        XCTAssertTrue(stormRow.waitForExistence(timeout: 10))
        stormRow.tap()

        let kpValue = app.descendants(matching: .any).matching(identifier: "forecast.detail.kp").firstMatch
        XCTAssertTrue(kpValue.waitForExistence(timeout: 5))

        attachScreenshot(of: app, named: "ForecastDetail")
    }
}
