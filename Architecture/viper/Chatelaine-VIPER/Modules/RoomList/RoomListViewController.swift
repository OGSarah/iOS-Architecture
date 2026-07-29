//
//  RoomListViewController.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// A passive, sectioned list of rooms and their accessories, driven entirely by `display(_:)`.
final class RoomListViewController: UIViewController, RoomListViewInput, UICollectionViewDelegate {

    private let output: RoomListViewOutput

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<String, String>!
    private var accessoriesByID: [String: RoomListViewModel.Accessory] = [:]
    private var sectionNames: [String: String] = [:]

    init(output: RoomListViewOutput) {
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
        configureCollectionView()
        configureDataSource()
        output.viewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        output.viewWillDisappear()
    }

    // MARK: - RoomListViewInput

    func display(_ viewModel: RoomListViewModel) {
        title = viewModel.title
        accessoriesByID = Dictionary(
            uniqueKeysWithValues: viewModel.sections.flatMap(\.accessories).map { ($0.id, $0) }
        )
        sectionNames = Dictionary(uniqueKeysWithValues: viewModel.sections.map { ($0.id, $0.name) })

        var snapshot = NSDiffableDataSourceSnapshot<String, String>()
        for section in viewModel.sections {
            snapshot.appendSections([section.id])
            snapshot.appendItems(section.accessories.map(\.id), toSection: section.id)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: - Setup

    private func configureCollectionView() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = AccessibilityIdentifiers.RoomList.collection
        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { [weak self] cell, _, identifier in
            guard let accessory = self?.accessoriesByID[identifier] else { return }
            var content = cell.defaultContentConfiguration()
            content.text = accessory.name
            content.secondaryText = accessory.statusText
            content.secondaryTextProperties.color = UIColor(named: "WarningAmber") ?? .systemOrange
            cell.contentConfiguration = content
            cell.accessibilityLabel = accessory.accessibilityLabel
            cell.accessories = [.disclosureIndicator()]
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, indexPath in
            let sectionID = self?.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            var content = header.defaultContentConfiguration()
            content.text = sectionID.flatMap { self?.sectionNames[$0] }
            header.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, identifier in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }

    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let identifier = dataSource.itemIdentifier(for: indexPath) else { return }
        output.didSelectAccessory(accessoryID: identifier)
    }
}
