//
//  GitHubBrowser_MVCUITests.swift
//  GitHubBrowser-MVCUITests
//
//  Created by Sarah Clark on 7/15/26.
//

import XCTest

/// End-to-end tests driven against stubbed network data.
///
/// Each test launches the app with a `UITEST_STUB_SCENARIO` launch
/// environment value that `SceneDelegate` reads to serve fixture JSON
/// instead of calling the live GitHub API, keeping these tests fast and
/// deterministic. The fixture data lives in the app target's
/// `TestSupport/UITestNetworkStub.swift`.
///
/// The identifier strings mirror the app's `AccessibilityID` constants;
/// the UI test target cannot import the app module, so update both
/// places together.
final class GitHubBrowser_MVCUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches the app with the given stubbed network scenario.
    ///
    /// - Parameter scenario: One of `"success"`, `"empty"`, or `"error"`.
    /// - Returns: The launched application, ready for queries.
    @MainActor
    private func launchApp(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_STUB_SCENARIO"] = scenario
        app.launch()
        return app
    }

    // MARK: - List screen

    @MainActor
    func testListShowsRepositoriesFromStubbedNetwork() throws {
        let app = launchApp(scenario: "success")

        XCTAssertTrue(app.navigationBars["apple"].waitForExistence(timeout: 5))

        let table = app.tables["repositoryList.tableView"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))

        XCTAssertTrue(table.staticTexts["swift-algorithms"].waitForExistence(timeout: 5))
        XCTAssertTrue(table.staticTexts["mystery-repo"].exists)

        // The stats line renders the fixture's 6200 stars compactly.
        let stats = table.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "6.2k")).firstMatch
        XCTAssertTrue(stats.exists)
    }

    @MainActor
    func testEmptyStateIsShownWhenUserHasNoRepositories() throws {
        let app = launchApp(scenario: "empty")

        let emptyStateLabel = app.staticTexts["repositoryList.emptyStateLabel"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(emptyStateLabel.label, "No repositories found")
    }

    @MainActor
    func testErrorAlertIsShownWhenTheRequestFails() throws {
        let app = launchApp(scenario: "error")

        let alert = app.alerts["Couldn't load repositories"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts["GitHub returned an error (status: 500)."].exists)
        XCTAssertTrue(alert.buttons["Try Again"].exists)

        alert.buttons["Cancel"].tap()
        XCTAssertFalse(alert.exists)
    }

    // MARK: - Detail screen

    @MainActor
    func testSelectingARepositoryShowsItsDetail() throws {
        let app = launchApp(scenario: "success")

        let table = app.tables["repositoryList.tableView"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        XCTAssertTrue(table.staticTexts["swift-algorithms"].waitForExistence(timeout: 5))

        table.staticTexts["swift-algorithms"].tap()

        let nameLabel = app.staticTexts["repositoryDetail.nameLabel"]
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(nameLabel.label, "uitest/swift-algorithms")

        // Present and hittable, but deliberately not tapped: tapping
        // would background the app into Safari.
        let openButton = app.buttons["repositoryDetail.openInGitHubButton"]
        XCTAssertTrue(openButton.exists)
        XCTAssertTrue(openButton.isHittable)

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(table.waitForExistence(timeout: 5))
    }

    @MainActor
    func testRepositoryWithoutDescriptionShowsFallback() throws {
        let app = launchApp(scenario: "success")

        let table = app.tables["repositoryList.tableView"]
        XCTAssertTrue(table.waitForExistence(timeout: 5))
        XCTAssertTrue(table.staticTexts["mystery-repo"].waitForExistence(timeout: 5))

        table.staticTexts["mystery-repo"].tap()

        let descriptionLabel = app.staticTexts["repositoryDetail.descriptionLabel"]
        XCTAssertTrue(descriptionLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(descriptionLabel.label, "No description provided.")
    }

    // MARK: - Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
