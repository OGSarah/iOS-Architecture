//
//  HomeListViewController.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// A passive sidebar list of the home and its zones, driven entirely by `display(_:)`.
final class HomeListViewController: UIViewController, HomeListViewInput, UICollectionViewDelegate {

    private let output: HomeListViewOutput

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>!
    private var rowsByID: [String: HomeListViewModel.Row] = [:]

    private let emptyLabel = UILabel()

    init(output: HomeListViewOutput) {
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used, this controller is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "BrandNavy")
        configureCollectionView()
        configureEmptyLabel()
        configureDataSource()
        output.viewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        output.viewWillDisappear()
    }

    // MARK: - HomeListViewInput

    func display(_ viewModel: HomeListViewModel) {
        title = viewModel.title
        rowsByID = Dictionary(uniqueKeysWithValues: viewModel.rows.map { ($0.id, $0) })

        emptyLabel.text = viewModel.emptyMessage
        emptyLabel.isHidden = viewModel.rows.isEmpty == false || viewModel.emptyMessage == nil
        collectionView.isHidden = viewModel.rows.isEmpty

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.rows.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - Setup

    private func configureCollectionView() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
        configuration.backgroundColor = UIColor(named: "BrandNavy")
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = AccessibilityIdentifiers.HomeList.collection
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
            content.secondaryText = row.subtitle
            content.image = UIImage(systemName: row.kind == .home ? "house.fill" : "square.stack.3d.up.fill")
            content.imageProperties.tintColor = UIColor(named: "AccentColor")
            cell.contentConfiguration = content
            cell.accessibilityLabel = row.accessibilityLabel
        }
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, identifier in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: identifier)
        }
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return }
        output.didSelectRow(id: identifier)
    }
}
