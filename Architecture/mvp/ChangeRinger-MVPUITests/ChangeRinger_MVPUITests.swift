//
//  ChangeRinger_MVPUITests.swift
//  ChangeRinger-MVPUITests
//
//  Created by Sarah Clark on 7/17/26.
//

import XCTest

/// End-to-end flows driven through the simulator.
///
/// Each launch passes a `UITEST_SCENARIO` value that the app, in DEBUG builds, uses to seed
/// the fixture touch a new document is created with, so no test has to build a composition by
/// tapping out hundreds of rows.
///
/// The accessibility identifiers below are duplicated from the app's `AccessibilityID`
/// because the UI test target cannot import the app module. Keep the two in step.
final class ChangeRinger_MVPUITests: XCTestCase {

    private enum ID {
        static let grid = "editor.grid"
        static let truthBanner = "editor.truthBanner"
        static let playButton = "editor.playButton"
        static let methodButton = "editor.methodButton"
        static let bobButton = "callStrip.bob"
        static func row(_ index: Int) -> String { "editor.row.\(index)" }
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app straight into the editor on a seeded document, returning once the
    /// grid is on screen.
    @MainActor
    private func launchAndCreateDocument(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_SCENARIO"] = scenario
        app.launch()
        XCTAssertTrue(app.collectionViews[ID.grid].waitForExistence(timeout: 20), "Expected the row grid")
        return app
    }

    @MainActor
    func testEditorShowsTheGeneratedRows() {
        let app = launchAndCreateDocument(scenario: "trueTouch")
        XCTAssertTrue(app.descendants(matching: .any)[ID.row(0)].waitForExistence(timeout: 5), "Expected rows")
    }

    @MainActor
    func testChangingTheMethodRegeneratesTheRows() {
        let app = launchAndCreateDocument(scenario: "trueTouch")

        app.buttons[ID.methodButton].tap()

        let majorCell = app.staticTexts["Plain Bob Major"]
        XCTAssertTrue(majorCell.waitForExistence(timeout: 10), "Expected the method picker")
        majorCell.tap()

        // The picker dismisses and the editor regenerates its rows for the new method.
        XCTAssertTrue(app.collectionViews[ID.grid].waitForExistence(timeout: 5), "Expected the editor grid")
        XCTAssertTrue(app.descendants(matching: .any)[ID.row(0)].waitForExistence(timeout: 5), "Expected regenerated rows")
    }

    @MainActor
    func testInsertingABobHitsATruthFailure() {
        let app = launchAndCreateDocument(scenario: "trueTouch")

        // Row 12 (the first lead end) may be just below the fold. Scroll the grid in small
        // steps until the cell is rendered, so the query resolves without overshooting it.
        let grid = app.collectionViews[ID.grid]
        let leadEnd = app.cells[ID.row(12)]
        var attempts = 0
        while !leadEnd.exists && attempts < 8 {
            let start = grid.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
            let end = grid.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45))
            start.press(forDuration: 0.05, thenDragTo: end)
            attempts += 1
        }
        XCTAssertTrue(leadEnd.waitForExistence(timeout: 5), "Expected lead-end row 12")
        leadEnd.tap()

        // Selecting the lead end enables the call buttons; wait for that before tapping.
        let bob = app.buttons[ID.bobButton]
        XCTAssertTrue(bob.waitForExistence(timeout: 5))
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"), object: bob)
        XCTAssertEqual(XCTWaiter().wait(for: [enabled], timeout: 5), .completed, "Expected the bob button to enable")
        bob.tap()

        XCTAssertTrue(app.descendants(matching: .any)[ID.truthBanner].waitForExistence(timeout: 5), "Expected the truth banner")
    }

    @MainActor
    func testPlayingATouch() {
        let app = launchAndCreateDocument(scenario: "trueTouch")
        let play = app.buttons[ID.playButton]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        XCTAssertEqual(play.label, "Play")

        play.tap()

        // The same control switches its label to Stop once playback starts.
        let becameStop = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Stop"),
            object: app.buttons[ID.playButton]
        )
        XCTAssertEqual(XCTWaiter().wait(for: [becameStop], timeout: 5), .completed, "Expected the play control to become Stop")
    }
}
