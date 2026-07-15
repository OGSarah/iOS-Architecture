//
//  RepositoryListViewController.swift
//  GitHubBrowser-MVC
//
//  Created by Sarah Clark on 7/15/26.
//

import SwiftUI
import UIKit

/// The Controller. It owns the view, asks the model for data, and
/// updates the view when that data changes. This is where MVC tends
/// to accumulate responsibility, so this controller is kept to three
/// jobs only: loading state, requesting data, and updating the table.
final class RepositoryListViewController: UIViewController {

    /// The single section shown by the diffable data source.
    private nonisolated enum Section {
        case repositories
    }

    /// The GitHub account whose public repositories are listed.
    private let username: String

    /// The session used to fetch repositories. Injected so unit tests
    /// and UI test runs can substitute a stubbed session.
    private let session: URLSession

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let emptyStateLabel = UILabel()

    private var dataSource: UITableViewDiffableDataSource<Section, Repository>!

    /// The in-flight load. Kept so a refresh can cancel the previous
    /// fetch, and exposed read-only so tests can await its completion.
    private(set) var loadTask: Task<Void, Never>?

    /// Creates a list controller for a GitHub user's repositories.
    ///
    /// - Parameters:
    ///   - username: The GitHub account whose repositories to fetch. Also
    ///     used as the navigation title.
    ///   - session: The session used for fetching. Defaults to `.shared`;
    ///     tests pass a session backed by a stubbed `URLProtocol`.
    init(username: String, session: URLSession = .shared) {
        self.username = username
        self.session = session
        super.init(nibName: nil, bundle: nil)
        title = username
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setUpTableView()
        setUpEmptyStateLabel()
        setUpActivityIndicator()
        setUpDataSource()
        setUpRefreshControl()

        loadRepositories()
    }

    // MARK: - View setup

    /// Pins the table view to the edges and registers the cell class.
    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(RepositoryCell.self, forCellReuseIdentifier: RepositoryCell.reuseIdentifier)
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.accessibilityIdentifier = AccessibilityID.RepositoryList.tableView

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    /// Centers the label that is shown when the user has no repositories.
    private func setUpEmptyStateLabel() {
        emptyStateLabel.text = "No repositories found"
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.accessibilityIdentifier = AccessibilityID.RepositoryList.emptyStateLabel

        view.addSubview(emptyStateLabel)
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }

    /// Centers the spinner shown during the initial load.
    private func setUpActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.accessibilityIdentifier = AccessibilityID.RepositoryList.activityIndicator

        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    /// Attaches pull-to-refresh, wired to `handleRefresh` via target-action.
    private func setUpRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    /// Creates the diffable data source that maps a `Repository` to a
    /// configured `RepositoryCell`.
    private func setUpDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, Repository>(tableView: tableView) { tableView, indexPath, repository in
            let cell = tableView.dequeueReusableCell(withIdentifier: RepositoryCell.reuseIdentifier, for: indexPath) as! RepositoryCell
            cell.configure(with: repository)
            return cell
        }
    }

    // MARK: - Loading

    @objc private func handleRefresh() {
        loadRepositories()
    }

    /// Asks the model for the user's repositories and updates the view
    /// with the result. Cancels any load already in flight, shows the
    /// spinner unless a pull-to-refresh is driving the reload, and hands
    /// failures to `showError(_:)`.
    private func loadRepositories() {
        loadTask?.cancel()
        emptyStateLabel.isHidden = true

        if tableView.refreshControl?.isRefreshing != true {
            activityIndicator.startAnimating()
        }

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let repositories = try await Repository.fetchAll(forUsername: self.username, session: self.session)
                if Task.isCancelled { return }
                self.applySnapshot(with: repositories)
            } catch {
                if Task.isCancelled { return }
                self.showError(error)
            }

            self.activityIndicator.stopAnimating()
            self.tableView.refreshControl?.endRefreshing()
        }
    }

    /// Replaces the table's contents with the given repositories and
    /// toggles the empty state label.
    ///
    /// - Parameter repositories: The repositories to display.
    private func applySnapshot(with repositories: [Repository]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Repository>()
        snapshot.appendSections([.repositories])
        snapshot.appendItems(repositories, toSection: .repositories)
        dataSource.apply(snapshot, animatingDifferences: true)

        emptyStateLabel.isHidden = !repositories.isEmpty
    }

    /// Presents an alert describing the failure, with a Try Again action
    /// that starts a fresh load.
    ///
    /// - Parameter error: The error thrown by the model layer. A
    ///   ``RepositoryError`` supplies its own user-facing message.
    private func showError(_ error: Error) {
        let message = (error as? RepositoryError)?.message ?? "Something went wrong. Please try again."

        let alert = UIAlertController(title: "Couldn't load repositories", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
            self?.loadRepositories()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate

extension RepositoryListViewController: UITableViewDelegate {

    /// Pushes a detail controller for the selected repository. This is
    /// the View reporting a user action back to the Controller through
    /// UIKit's delegate pattern.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let repository = dataSource.itemIdentifier(for: indexPath) else { return }
        let detailViewController = RepositoryDetailViewController(repository: repository)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
