//
//  RepositoryDetailViewControllerTests.swift
//  GitHubBrowser-MVCTests
//
//  Created by Sarah Clark on 7/15/26.
//

import Testing
import UIKit
@testable import GitHubBrowser_MVC

@MainActor
struct RepositoryDetailViewControllerTests {

    private func labelText(in viewController: UIViewController, identifier: String) -> String? {
        (viewController.view.firstSubview(withAccessibilityIdentifier: identifier) as? UILabel)?.text
    }

    @Test func `View displays repository details after loading`() throws {
        let viewController = RepositoryDetailViewController(repository: .fixture())
        viewController.loadViewIfNeeded()

        #expect(labelText(in: viewController, identifier: AccessibilityID.Detail.nameLabel) == "octocat/example-repo")
        #expect(labelText(in: viewController, identifier: AccessibilityID.Detail.descriptionLabel) == "An example repository")

        let stats = try #require(labelText(in: viewController, identifier: AccessibilityID.Detail.statsLabel))
        #expect(stats.contains("42 stars"))
        #expect(stats.contains("7 forks"))
        #expect(stats.contains("Swift"))
        #expect(stats.contains("updated"))
    }

    @Test func `Missing description shows the fallback text`() {
        let viewController = RepositoryDetailViewController(repository: .fixture(description: nil))
        viewController.loadViewIfNeeded()

        #expect(labelText(in: viewController, identifier: AccessibilityID.Detail.descriptionLabel) == "No description provided.")
    }

    @Test func `Title is the repository name`() {
        let viewController = RepositoryDetailViewController(repository: .fixture(name: "example-repo"))

        #expect(viewController.title == "example-repo")
    }
}
