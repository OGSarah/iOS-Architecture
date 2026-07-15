//
//  RepositoryDetailViewController.swift
//  GitHubBrowser-MVC
//
//  Created by Sarah Clark on 7/15/26.
//

import UIKit

/// A second, simpler controller. It receives its model directly from
/// the list controller rather than fetching anything itself, which
/// keeps navigation between screens explicit and easy to follow.
final class RepositoryDetailViewController: UIViewController {

    /// The repository this screen displays, handed over by the list
    /// controller when the user selects a row.
    private let repository: Repository

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let statsLabel = UILabel()
    private let openInGitHubButton = UIButton(type: .system)

    /// Creates a detail controller for a single repository.
    ///
    /// - Parameter repository: The repository to display. The navigation
    ///   title is derived from its name.
    init(repository: Repository) {
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
        title = repository.name
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpViews()
        configure()
    }

    /// Builds the scroll view and the vertical stack of labels and the
    /// button, and assigns accessibility identifiers for the tests.
    private func setUpViews() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        nameLabel.font = .preferredFont(forTextStyle: .title1)
        nameLabel.numberOfLines = 0
        nameLabel.accessibilityIdentifier = AccessibilityID.Detail.nameLabel

        descriptionLabel.font = .preferredFont(forTextStyle: .body)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.accessibilityIdentifier = AccessibilityID.Detail.descriptionLabel

        statsLabel.font = .preferredFont(forTextStyle: .footnote)
        statsLabel.textColor = .tertiaryLabel
        statsLabel.numberOfLines = 0
        statsLabel.accessibilityIdentifier = AccessibilityID.Detail.statsLabel

        openInGitHubButton.setTitle("Open in GitHub", for: .normal)
        openInGitHubButton.addTarget(self, action: #selector(openInGitHubTapped), for: .touchUpInside)
        openInGitHubButton.accessibilityIdentifier = AccessibilityID.Detail.openInGitHubButton

        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        [nameLabel, descriptionLabel, statsLabel, openInGitHubButton].forEach {
            contentStack.addArrangedSubview($0)
        }

        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    /// Populates the labels from the repository, falling back to
    /// placeholder text when the description is missing and omitting
    /// the language line when it is unknown.
    private func configure() {
        nameLabel.text = repository.fullName
        descriptionLabel.text = repository.description ?? "No description provided."

        let stars = RepositoryFormatting.compactCount(repository.stargazersCount)
        let forks = RepositoryFormatting.compactCount(repository.forksCount)
        let updated = RepositoryFormatting.relativeUpdatedAt(repository.updatedAt)

        var statsParts = ["\u{2605} \(stars) stars", "\u{2442} \(forks) forks"]
        if let language = repository.language {
            statsParts.append(language)
        }
        statsParts.append("updated \(updated)")

        statsLabel.text = statsParts.joined(separator: "\n")
    }

    /// Opens the repository's page on github.com in the user's browser.
    @objc private func openInGitHubTapped() {
        UIApplication.shared.open(repository.htmlURL)
    }
}
