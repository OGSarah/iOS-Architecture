//
//  RepositoryListViewControllerTests.swift
//  GitHubBrowser-MVCTests
//
//  Created by Sarah Clark on 7/15/26.
//

import Foundation
import Testing
import UIKit
@testable import GitHubBrowser_MVC

// Serialized because every test shares ListStubURLProtocol's handler,
// which is global state; a class is used so deinit can clear it. The
// suite uses its own StubURLProtocol subclass so it cannot race
// RepositoryModelTests running in parallel.
@MainActor
@Suite(.serialized)
final class RepositoryListViewControllerTests {

    private let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))

    deinit {
        ListStubURLProtocol.requestHandler = nil
    }

    /// Creates the controller with a stubbed session, hosts it in a
    /// window so it can present alerts, and waits for the initial load
    /// kicked off by `viewDidLoad` to finish.
    private func makeLoadedController() async -> RepositoryListViewController {
        let viewController = RepositoryListViewController(username: "octocat", session: ListStubURLProtocol.makeSession())
        window.rootViewController = viewController
        window.makeKeyAndVisible()
        viewController.loadViewIfNeeded()
        await viewController.loadTask?.value
        return viewController
    }

    @Test func `Loading success populates the table and hides the empty state`() async throws {
        let json = """
        [
            {
                "id": 1,
                "name": "first-repo",
                "full_name": "octocat/first-repo",
                "description": "The first repository",
                "stargazers_count": 42,
                "forks_count": 7,
                "language": "Swift",
                "html_url": "https://github.com/octocat/first-repo",
                "updated_at": "2026-06-01T12:00:00Z"
            },
            {
                "id": 2,
                "name": "second-repo",
                "full_name": "octocat/second-repo",
                "description": null,
                "stargazers_count": 3,
                "forks_count": 0,
                "language": null,
                "html_url": "https://github.com/octocat/second-repo",
                "updated_at": "2026-05-01T12:00:00Z"
            }
        ]
        """.data(using: .utf8)!

        ListStubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let viewController = await makeLoadedController()

        let tableView = try #require(viewController.view.firstSubview(
            withAccessibilityIdentifier: AccessibilityID.RepositoryList.tableView
        ) as? UITableView)

        // The diffable data source applies its snapshot asynchronously.
        await waitUntil { tableView.numberOfSections == 1 && tableView.numberOfRows(inSection: 0) == 2 }
        #expect(tableView.numberOfRows(inSection: 0) == 2)

        let emptyStateLabel = try #require(viewController.view.firstSubview(
            withAccessibilityIdentifier: AccessibilityID.RepositoryList.emptyStateLabel
        ))
        #expect(emptyStateLabel.isHidden)
    }

    @Test func `An empty response shows the empty state label`() async throws {
        ListStubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("[]".utf8))
        }

        let viewController = await makeLoadedController()

        let emptyStateLabel = try #require(viewController.view.firstSubview(
            withAccessibilityIdentifier: AccessibilityID.RepositoryList.emptyStateLabel
        ))
        await waitUntil { !emptyStateLabel.isHidden }
        #expect(!emptyStateLabel.isHidden)
    }

    @Test func `A failed load presents an error alert with the error message`() async throws {
        ListStubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let viewController = await makeLoadedController()

        await waitUntil { viewController.presentedViewController != nil }
        let alert = try #require(viewController.presentedViewController as? UIAlertController)
        #expect(alert.title == "Couldn't load repositories")
        #expect(alert.message == "GitHub returned an error (status: 500).")
        #expect(alert.actions.map(\.title) == ["Try Again", "Cancel"])
    }
}
