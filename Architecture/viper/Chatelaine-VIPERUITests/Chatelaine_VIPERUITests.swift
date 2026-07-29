//
//  Chatelaine_VIPERUITests.swift
//  Chatelaine-VIPERUITests
//
//  Created by Sarah Clark on 7/29/26.
//

import XCTest

/// End to end flows driven against the scripted household, so none depend on HomeKit permission,
/// the accessory simulator, or a write actually succeeding. Each launch passes a UITEST_SCENARIO the
/// app reads in DEBUG to substitute the scripted store and set the onboarding state.
final class Chatelaine_VIPERUITests: XCTestCase {

    private let timeout: TimeInterval = 10

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launch(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SCENARIO"] = scenario
        app.launchEnvironment["UITEST_ANIMATIONS"] = "off"
        app.launch()
        return app
    }

    @discardableResult
    private func waitFor(_ element: XCUIElement) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    /// Navigates the compact stack from the sidebar into an accessory's controls.
    private func openControls(app: XCUIApplication, accessory: String, service: String) {
        XCTAssertTrue(waitFor(app.staticTexts["Chatelaine House"]))
        app.staticTexts["Chatelaine House"].tap()

        XCTAssertTrue(waitFor(app.staticTexts[accessory]))
        app.staticTexts[accessory].tap()

        // The service row is tapped by name, scoped to the detail collection to avoid the header.
        let detail = app.collectionViews["accessoryDetail.collection"]
        let serviceRow = detail.staticTexts[service]
        XCTAssertTrue(waitFor(serviceRow))
        serviceRow.tap()

        XCTAssertTrue(waitFor(app.collectionViews["serviceControl.collection"]))
    }

    // MARK: - Flows

    func testSelectingThroughTheColumns() {
        let app = launch(scenario: "main")
        openControls(app: app, accessory: "Bedroom Overhead Light", service: "Overhead Light")
    }

    func testTogglingARejectedWriteRollsBack() {
        let app = launch(scenario: "rollback")
        openControls(app: app, accessory: "AC Unit", service: "AC Unit")

        let toggle = app.switches["serviceControl.control.ac.active"]
        XCTAssertTrue(waitFor(toggle))
        toggle.tap()

        // The AC always rejects the write, so an inline reason appears after the rollback.
        XCTAssertTrue(waitFor(app.staticTexts["serviceControl.reason.ac.active"]))
    }

    func testBuildingAndSavingAThresholdAutomation() {
        let app = launch(scenario: "main")
        XCTAssertTrue(waitFor(app.navigationBars.buttons["Automations"]))
        app.navigationBars.buttons["Automations"].tap()

        XCTAssertTrue(waitFor(app.navigationBars["Automations"]))
        app.navigationBars.buttons["Create automation"].tap()

        // The builder defaults to a valid threshold range with one action, so it saves as is.
        let save = app.buttons["automationBuilder.save"]
        XCTAssertTrue(waitFor(save))
        save.tap()

        // Saving returns to the automations list.
        XCTAssertTrue(waitFor(app.navigationBars["Automations"]))
    }

    func testEnteringAndCancellingSetup() {
        let app = launch(scenario: "main")
        XCTAssertTrue(waitFor(app.staticTexts["Chatelaine House"]))
        app.staticTexts["Chatelaine House"].tap()

        let add = app.buttons["roomList.addAccessory"]
        XCTAssertTrue(waitFor(add))
        add.tap()

        XCTAssertTrue(waitFor(app.navigationBars["Set Up Accessory"]))
        app.buttons["setup.cancel"].tap()

        // Cancelling returns to the rooms list.
        XCTAssertTrue(waitFor(app.collectionViews["roomList.collection"]))
    }

    func testRotatingKeepsTheApplicationUsable() {
        let app = launch(scenario: "main")
        XCTAssertTrue(waitFor(app.staticTexts["Chatelaine House"]))
        app.staticTexts["Chatelaine House"].tap()
        XCTAssertTrue(waitFor(app.staticTexts["AC Unit"]))

        let device = XCUIDevice.shared
        device.orientation = .landscapeLeft
        XCTAssertTrue(waitFor(app.staticTexts["AC Unit"]))
        device.orientation = .portrait
        XCTAssertTrue(app.staticTexts["AC Unit"].waitForExistence(timeout: timeout))
    }

    // MARK: - Onboarding and settings

    func testOnboardingShowsOnFirstLaunchAndFinishes() {
        let app = launch(scenario: "onboarding")
        let continueButton = app.buttons["onboarding.continue"]
        XCTAssertTrue(waitFor(continueButton))

        // Advance through the pages until onboarding dismisses to the main sidebar.
        for _ in 0..<5 where continueButton.exists {
            continueButton.tap()
        }
        XCTAssertTrue(waitFor(app.staticTexts["Chatelaine House"]))
    }

    func testMotionToggleInSettings() {
        let app = launch(scenario: "main")
        XCTAssertTrue(waitFor(app.navigationBars.buttons["Settings"]))
        app.navigationBars.buttons["Settings"].tap()

        let toggle = app.switches["settings.animationsToggle"]
        XCTAssertTrue(waitFor(toggle))
        toggle.tap()

        app.navigationBars.buttons["Done"].tap()
        XCTAssertTrue(waitFor(app.staticTexts["Chatelaine House"]))
    }
}
