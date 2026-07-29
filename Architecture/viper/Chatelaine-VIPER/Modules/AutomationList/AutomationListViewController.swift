//
//  AutomationListViewController.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// A passive list of saved automations with add and done bar buttons.
final class AutomationListViewController: UIViewController, AutomationListViewInput {

    private let output: AutomationListViewOutput

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>!
    private var rowsByID: [String: AutomationListViewModel.Row] = [:]
    private let emptyLabel = UILabel()

    init(output: AutomationListViewOutput) {
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used, this controller is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureNavigationItems()
        configureCollectionView()
        configureEmptyLabel()
        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload each time so a newly created automation appears on return from the builder.
        output.viewDidLoad()
    }

    // MARK: - AutomationListViewInput

    func display(_ viewModel: AutomationListViewModel) {
        title = viewModel.title
        rowsByID = Dictionary(uniqueKeysWithValues: viewModel.rows.map { ($0.id, $0) })
        emptyLabel.text = viewModel.emptyMessage
        emptyLabel.isHidden = viewModel.emptyMessage == nil

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.rows.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - Setup

    private func configureNavigationItems() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak self] _ in
            self?.output.didTapDone()
        })
        let addButton = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
            self?.output.didTapCreate()
        })
        addButton.accessibilityLabel = "Create automation"
        navigationItem.rightBarButtonItem = addButton
    }

    private func configureCollectionView() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
    }

    private func configureEmptyLabel() {
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = UIColor(named: "TextSecondary")
        emptyLabel.font = .preferredFont(forTextStyle: .body)
        emptyLabel.adjustsFontForContentSizeCategory = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            emptyLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { [weak self] cell, _, identifier in
            guard let row = self?.rowsByID[identifier] else { return }
            var content = cell.defaultContentConfiguration()
            content.text = row.name
            content.secondaryText = row.detail
            cell.contentConfiguration = content
            cell.accessibilityLabel = row.accessibilityLabel
        }
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, identifier in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: identifier)
        }
    }
}
