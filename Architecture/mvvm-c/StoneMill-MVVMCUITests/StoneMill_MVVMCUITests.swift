import XCTest

/// End to end flows driven through the app in the simulator.
///
/// Each launch passes a `UITEST_SCENARIO` environment value that the app, in
/// DEBUG builds only, uses to seed a fixture `GameState`, so no test has to
/// actually play nine placements to reach the phase it wants. Board tests
/// also pass `UITEST_DRIVE`, which shows a control strip of plain buttons so
/// the scripted match runs on ViewModel intents rather than 3D hit testing.
/// Identifiers come from `AXID`, the same file the views compile.
final class StoneMill_MVVMCUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app, optionally seeding a scenario and the control strip.
    private func launch(scenario: String? = nil, drive: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        if let scenario {
            app.launchEnvironment["UITEST_SCENARIO"] = scenario
        }
        if drive {
            app.launchEnvironment["UITEST_DRIVE"] = "1"
        }
        app.launch()
        return app
    }

    /// Setup validation: an incomplete configuration cannot start, and the
    /// validation message clears once both players are named.
    func testSetupValidationBlocksInvalidStart() throws {
        let app = launch(scenario: "freshSetup")

        let start = app.buttons[AXID.Setup.startButton]
        XCTAssertTrue(start.waitForExistence(timeout: 20), "The setup window should appear")
        XCTAssertFalse(start.isEnabled, "Start must be disabled while names are missing")
        XCTAssertTrue(app.staticTexts[AXID.Setup.validationLabel].exists)

        let lightName = app.textFields[AXID.Setup.lightName]
        lightName.tap()
        lightName.typeText("Rowan")
        XCTAssertFalse(start.isEnabled, "The dark player still needs a name")

        let darkName = app.textFields[AXID.Setup.darkName]
        darkName.tap()
        darkName.typeText("Sage")

        XCTAssertTrue(start.isEnabled)
        XCTAssertFalse(app.staticTexts[AXID.Setup.validationLabel].exists, "The validation message clears")
    }

    /// Starting a valid match opens the board volume.
    func testStartOpensBoardVolume() throws {
        let app = launch(scenario: "freshSetup")

        let start = app.buttons[AXID.Setup.startButton]
        XCTAssertTrue(start.waitForExistence(timeout: 20))

        app.textFields[AXID.Setup.lightName].tap()
        app.textFields[AXID.Setup.lightName].typeText("Rowan")
        app.textFields[AXID.Setup.darkName].tap()
        app.textFields[AXID.Setup.darkName].typeText("Sage")
        start.tap()

        let status = app.staticTexts[AXID.Board.status]
        XCTAssertTrue(status.waitForExistence(timeout: 20), "The board volume should open with its status ornament")
        XCTAssertTrue(status.label.contains("Rowan"), "Light moves first")
    }

    /// A scripted match: the seeded position is one slide and one capture
    /// away from a win, driven through the control strip to the results card.
    func testScriptedMatchReachesResults() throws {
        let app = launch(scenario: "oneMoveToWin", drive: true)

        let liftPoint = app.buttons[AXID.Board.point(3)]
        XCTAssertTrue(liftPoint.waitForExistence(timeout: 20), "The seeded board should open")

        liftPoint.tap()
        app.buttons[AXID.Board.point(2)].tap()
        app.buttons[AXID.Board.point(8)].tap()

        let excavationButton = app.buttons[AXID.Board.excavationButton]
        XCTAssertTrue(excavationButton.waitForExistence(timeout: 20), "The results card should appear")

        let status = app.staticTexts[AXID.Board.status]
        XCTAssertTrue(status.label.contains("Rowan wins"), "Light completed the mill and captured to two")
    }

    /// The excavation space opens from a finished match and returns to setup.
    func testOpenAndDismissExcavation() throws {
        let app = launch(scenario: "matchOver", drive: true)

        let excavationButton = app.buttons[AXID.Board.excavationButton]
        XCTAssertTrue(excavationButton.waitForExistence(timeout: 20), "The seeded finished match shows the results card")
        excavationButton.tap()

        let returnButton = app.buttons[AXID.Excavation.returnButton]
        XCTAssertTrue(returnButton.waitForExistence(timeout: 30), "The immersive space should open with its panel")
        returnButton.tap()

        let start = app.buttons[AXID.Setup.startButton]
        XCTAssertTrue(start.waitForExistence(timeout: 30), "Dismissing the space returns to the setup window")
    }
}
