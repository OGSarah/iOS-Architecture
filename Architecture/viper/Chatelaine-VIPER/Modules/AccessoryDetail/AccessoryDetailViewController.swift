//
//  AccessoryDetailViewController.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// A passive list of an accessory's services, driven entirely by `display(_:)`.
final class AccessoryDetailViewController: UIViewController, AccessoryDetailViewInput, UICollectionViewDelegate {

    private let output: AccessoryDetailViewOutput

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>!
    private var rowsByID: [String: AccessoryDetailViewModel.ServiceRow] = [:]
    private var statusText: String?

    init(output: AccessoryDetailViewOutput) {
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

    // MARK: - AccessoryDetailViewInput

    func display(_ viewModel: AccessoryDetailViewModel) {
        title = viewModel.title
        statusText = viewModel.statusText
        rowsByID = Dictionary(uniqueKeysWithValues: viewModel.services.map { ($0.id, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.services.map(\.id))
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
        collectionView.accessibilityIdentifier = AccessibilityIdentifiers.AccessoryDetail.collection
        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { [weak self] cell, _, identifier in
            guard let row = self?.rowsByID[identifier] else { return }
            var content = cell.defaultContentConfiguration()
            content.text = row.name
            content.secondaryText = row.detail
            cell.contentConfiguration = content
            cell.accessibilityLabel = row.accessibilityLabel
            cell.accessories = [.disclosureIndicator()]
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] header, _, _ in
            var content = header.defaultContentConfiguration()
            content.text = self?.statusText ?? "Services"
            content.textProperties.color = self?.statusText == nil ? .secondaryLabel : (UIColor(named: "WarningAmber") ?? .systemOrange)
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
        output.didSelectService(serviceID: identifier)
    }
}
