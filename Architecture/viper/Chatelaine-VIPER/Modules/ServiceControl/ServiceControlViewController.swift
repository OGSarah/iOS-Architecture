//
//  ServiceControlViewController.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// A passive collection view over a list layout, driven entirely by `display(_:)`.
///
/// It has no branch on accessory type, no number formatter, no reference to any entity, and no
/// knowledge that HomeKit exists. Its whole job is to bind a view model to cells and to call back
/// with the identifier of whatever was touched.
final class ServiceControlViewController: UIViewController, ServiceControlViewInput {

    private let output: ServiceControlViewOutput

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, String>!
    private var rowsByID: [String: ServiceControlViewModel.Row] = [:]

    init(output: ServiceControlViewOutput) {
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

    // MARK: - ServiceControlViewInput

    func display(_ viewModel: ServiceControlViewModel) {
        title = viewModel.title
        rowsByID = Dictionary(uniqueKeysWithValues: viewModel.rows.map { ($0.id, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(viewModel.rows.map(\.id))
        // Reconfigure existing items so control values refresh without recreating cells.
        snapshot.reconfigureItems(viewModel.rows.map(\.id).filter { rowsByID[$0] != nil })
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    // MARK: - Setup

    private func configureCollectionView() {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = .systemBackground
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.accessibilityIdentifier = AccessibilityIdentifiers.ServiceControl.collection
        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        let registration = UICollectionView.CellRegistration<ServiceControlCell, String> { [weak self] cell, _, identifier in
            guard let self, let row = rowsByID[identifier] else { return }
            cell.configure(with: row, output: output)
        }
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, identifier in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: identifier)
        }
    }
}
