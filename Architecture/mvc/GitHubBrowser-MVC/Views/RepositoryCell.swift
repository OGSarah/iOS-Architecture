//
//  RepositoryCell.swift
//  GitHubBrowser-MVC
//
//  Created by Sarah Clark on 7/15/26.
//

import UIKit

/// The View. It only knows how to lay itself out and display whatever
/// it is given. It never reaches out to the model layer or the
/// network on its own.
final class RepositoryCell: UITableViewCell {

    /// The identifier the list controller registers and dequeues with.
    static let reuseIdentifier = "RepositoryCell"

    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let statsLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpViews()
    }

    /// Builds the label stack and applies fonts, colors, and identifiers.
    private func setUpViews() {
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.numberOfLines = 1
        nameLabel.accessibilityIdentifier = AccessibilityID.Cell.nameLabel

        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2
        descriptionLabel.accessibilityIdentifier = AccessibilityID.Cell.descriptionLabel

        statsLabel.font = .preferredFont(forTextStyle: .footnote)
        statsLabel.textColor = .tertiaryLabel
        statsLabel.accessibilityIdentifier = AccessibilityID.Cell.statsLabel

        let stack = UIStackView(arrangedSubviews: [nameLabel, descriptionLabel, statsLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        accessoryType = .disclosureIndicator
        accessibilityIdentifier = AccessibilityID.Cell.cell
    }

    /// Populates the cell's labels with the given repository's data,
    /// falling back to placeholder text when the description is missing
    /// and omitting the language from the stats line when it is unknown.
    ///
    /// - Parameter repository: The repository to display.
    func configure(with repository: Repository) {
        nameLabel.text = repository.name
        descriptionLabel.text = repository.description ?? "No description"

        let stars = RepositoryFormatting.compactCount(repository.stargazersCount)
        let forks = RepositoryFormatting.compactCount(repository.forksCount)
        let updated = RepositoryFormatting.relativeUpdatedAt(repository.updatedAt)

        var statsParts = ["\u{2605} \(stars)", "\u{2442} \(forks)"]
        if let language = repository.language {
            statsParts.append(language)
        }
        statsParts.append("updated \(updated)")

        statsLabel.text = statsParts.joined(separator: "  •  ")
    }
}
