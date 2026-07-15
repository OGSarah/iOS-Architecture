//
//  AccessibilityIdentifiers.swift
//  GitHubBrowser-MVC
//
//  Created by Sarah Clark on 7/15/26.
//

/// Accessibility identifiers assigned by the app's views and looked up
/// by the unit and UI tests. Centralizing the strings keeps the app and
/// the unit tests from drifting apart.
///
/// The UI test target cannot import the app module, so the UI tests
/// duplicate these strings as literals; update both places together.
nonisolated enum AccessibilityID {

    /// Elements owned by `RepositoryListViewController`.
    enum RepositoryList {
        static let tableView = "repositoryList.tableView"
        static let emptyStateLabel = "repositoryList.emptyStateLabel"
        static let activityIndicator = "repositoryList.activityIndicator"
    }

    /// Elements owned by `RepositoryCell`.
    enum Cell {
        static let cell = "repositoryCell"
        static let nameLabel = "repositoryCell.nameLabel"
        static let descriptionLabel = "repositoryCell.descriptionLabel"
        static let statsLabel = "repositoryCell.statsLabel"
    }

    /// Elements owned by `RepositoryDetailViewController`.
    enum Detail {
        static let nameLabel = "repositoryDetail.nameLabel"
        static let descriptionLabel = "repositoryDetail.descriptionLabel"
        static let statsLabel = "repositoryDetail.statsLabel"
        static let openInGitHubButton = "repositoryDetail.openInGitHubButton"
    }
}
