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

    private nonisolated enum Section {
        case repositories
    }

    private let username: String
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let emptyStateLabel = UILabel()

    private var dataSource: UITableViewDiffableDataSource<Section, Repository>!
    private var loadTask: Task<Void, Never>?

    init(username: String) {
        self.username = username
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
    private func setUpTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(RepositoryCell.self, forCellReuseIdentifier: RepositoryCell.reuseIdentifier)
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setUpEmptyStateLabel() {
        emptyStateLabel.text = "No repositories found"
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.isHidden = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(emptyStateLabel)
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func setUpActivityIndicator() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setUpRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

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

    private func loadRepositories() {
        loadTask?.cancel()
        emptyStateLabel.isHidden = true

        if tableView.refreshControl?.isRefreshing != true {
            activityIndicator.startAnimating()
        }

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let repositories = try await Repository.fetchAll(forUsername: self.username)
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

    private func applySnapshot(with repositories: [Repository]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Repository>()
        snapshot.appendSections([.repositories])
        snapshot.appendItems(repositories, toSection: .repositories)
        dataSource.apply(snapshot, animatingDifferences: true)

        emptyStateLabel.isHidden = !repositories.isEmpty
    }

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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let repository = dataSource.itemIdentifier(for: indexPath) else { return }
        let detailViewController = RepositoryDetailViewController(repository: repository)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

