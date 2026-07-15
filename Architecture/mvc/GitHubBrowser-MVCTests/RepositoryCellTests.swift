//
//  RepositoryCellTests.swift
//  GitHubBrowser-MVCTests
//
//  Created by Sarah Clark on 7/15/26.
//

import Testing
import UIKit
@testable import GitHubBrowser_MVC

@MainActor
struct RepositoryCellTests {

    private func makeConfiguredCell(with repository: Repository) -> RepositoryCell {
        let cell = RepositoryCell(style: .default, reuseIdentifier: RepositoryCell.reuseIdentifier)
        cell.configure(with: repository)
        return cell
    }

    private func labelText(in cell: RepositoryCell, identifier: String) -> String? {
        (cell.firstSubview(withAccessibilityIdentifier: identifier) as? UILabel)?.text
    }

    @Test func `Configure populates name, description, and stats`() throws {
        let cell = makeConfiguredCell(with: .fixture(stargazersCount: 1200, forksCount: 7, language: "Swift"))

        #expect(labelText(in: cell, identifier: AccessibilityID.Cell.nameLabel) == "example-repo")
        #expect(labelText(in: cell, identifier: AccessibilityID.Cell.descriptionLabel) == "An example repository")

        let stats = try #require(labelText(in: cell, identifier: AccessibilityID.Cell.statsLabel))
        #expect(stats.contains("1.2k"))
        #expect(stats.contains("7"))
        #expect(stats.contains("Swift"))
        #expect(stats.contains("updated"))
    }

    @Test func `Configure falls back when description is missing`() {
        let cell = makeConfiguredCell(with: .fixture(description: nil))

        #expect(labelText(in: cell, identifier: AccessibilityID.Cell.descriptionLabel) == "No description")
    }

    @Test func `Configure omits language from stats when missing`() throws {
        let cell = makeConfiguredCell(with: .fixture(language: nil))

        let stats = try #require(labelText(in: cell, identifier: AccessibilityID.Cell.statsLabel))
        #expect(!stats.contains("Swift"))
    }
}
