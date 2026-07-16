//
//  AuroraWatch_MVVM_Watch_AppUITests.swift
//  AuroraWatch-MVVM Watch AppUITests
//
//  Created by Sarah Clark on 7/16/26.
//

import XCTest

/// End to end flows driven in the watch simulator.
///
/// Every launch passes a `UITEST_STUB_SCENARIO` value that the app, in
/// DEBUG builds only, uses to serve fixture data instead of calling NOAA,
/// so the suite is fast, deterministic, and immune to rate limits.
final class AuroraWatch_MVVM_Watch_AppUITests: XCTestCase {

    /// Mirrored copies of the app's accessibility identifiers. The two
    /// targets do not share source files; if a value changes in
    /// `AccessibilityIdentifiers.swift`, change it here as well.
    private enum ID {
        static let forecastList = "forecast.list"
        static func forecastRow(at index: Int) -> String { "forecast.row.\(index)" }
        static let emptyView = "forecast.empty"
        static let errorView = "forecast.error"
        static let retryButton = "forecast.error.retry"
        static let detailView = "forecast.detail"
        static let detailKp = "forecast.detail.kp"
        static let stormBadge = "storm.badge"
    }

    /// The stub scenarios the app understands, mirrored from
    /// `UITestForecastStub.swift`.
    private enum Scenario: String {
        case happy, g3, empty, error, recovers
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app serving the given stub scenario.
    @MainActor
    private func launchApp(scenario: Scenario) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_STUB_SCENARIO"] = scenario.rawValue
        app.launch()
        return app
    }

    /// Finds an element by accessibility identifier regardless of the
    /// element type SwiftUI happened to expose it as.
    @MainActor
    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor
    func testListRendersStubbedForecast() throws {
        let app = launchApp(scenario: .happy)

        XCTAssertTrue(element(ID.forecastRow(at: 0), in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(element(ID.forecastRow(at: 3), in: app).exists)
        XCTAssertTrue(app.staticTexts["Kp 6.67"].exists)
    }

    @MainActor
    func testNavigatesToDetailAndBack() throws {
        let app = launchApp(scenario: .happy)

        let firstRow = element(ID.forecastRow(at: 0), in: app)
        XCTAssertTrue(firstRow.waitForExistence(timeout: 10))
        firstRow.tap()

        let kpValue = element(ID.detailKp, in: app)
        XCTAssertTrue(kpValue.waitForExistence(timeout: 5))
        XCTAssertEqual(kpValue.label, "Kp 2.33")

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(element(ID.forecastRow(at: 0), in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testStormBadgeShownForG3Window() throws {
        let app = launchApp(scenario: .g3)

        XCTAssertTrue(element(ID.forecastRow(at: 1), in: app).waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["G3"].exists)

        element(ID.forecastRow(at: 1), in: app).tap()
        let kpValue = element(ID.detailKp, in: app)
        XCTAssertTrue(kpValue.waitForExistence(timeout: 5))
        XCTAssertEqual(kpValue.label, "Kp 7.33")
    }

    @MainActor
    func testEmptyForecastShowsEmptyState() throws {
        let app = launchApp(scenario: .empty)

        XCTAssertTrue(element(ID.emptyView, in: app).waitForExistence(timeout: 10))
    }

    @MainActor
    func testErrorStateOffersRetryAndRecovers() throws {
        let app = launchApp(scenario: .recovers)

        XCTAssertTrue(element(ID.errorView, in: app).waitForExistence(timeout: 10))

        let retry = app.buttons[ID.retryButton]
        XCTAssertTrue(retry.exists)
        retry.tap()

        XCTAssertTrue(element(ID.forecastRow(at: 0), in: app).waitForExistence(timeout: 10))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchEnvironment["UITEST_STUB_SCENARIO"] = Scenario.happy.rawValue
            app.launch()
        }
    }
}
