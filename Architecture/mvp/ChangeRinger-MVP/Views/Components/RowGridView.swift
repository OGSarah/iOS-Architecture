//
//  RowGridView.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// The scrolling grid of rows, with the blue line traced through it.
///
/// This is a passive view. It draws exactly the `EditorRow` values it is handed and reports
/// only raw taps back through `onSelectLeadEnd`; it makes no decision about what a tap means.
/// It is built on a compositional layout, one full-width row per line, with a diffable data
/// source so updating the rows is a single snapshot apply.
final class RowGridView: UIView {

    /// Called when the user taps a lead-end row, reporting that row's index.
    var onSelectLeadEnd: ((Int) -> Void)?

    /// The height of a single row line.
    private let rowHeight: CGFloat = 40

    /// The rows currently shown.
    private var rows: [EditorRow] = []

    /// The index of the false row, if any, drawn with a red marking.
    private var falseIndex: Int?

    /// The selected lead-end row, if any.
    private var selectedIndex: Int?

    /// The row currently sounding during playback, if any.
    private var playbackIndex: Int?

    /// The collection view presenting the rows.
    private var collectionView: UICollectionView!

    /// The diffable data source, keyed by row index.
    private var dataSource: UICollectionViewDiffableDataSource<Int, Int>!

    /// The cell registration for a row.
    private var registration: UICollectionView.CellRegistration<RowCell, Int>!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    /// Builds the collection view, its layout, and the data source.
    private func setUp() {
        let layout = UICollectionViewCompositionalLayout { [rowHeight] _, _ in
            let size = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(rowHeight)
            )
            let item = NSCollectionLayoutItem(layoutSize: size)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
            return NSCollectionLayoutSection(group: group)
        }

        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = AccessibilityID.Editor.grid
        addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        registration = UICollectionView.CellRegistration<RowCell, Int> { [weak self] cell, _, index in
            guard let self, self.rows.indices.contains(index) else { return }
            cell.configure(
                row: self.rows[index],
                isFalse: self.falseIndex == index,
                isSelected: self.selectedIndex == index,
                isPlaying: self.playbackIndex == index
            )
        }

        dataSource = UICollectionViewDiffableDataSource<Int, Int>(collectionView: collectionView) {
            [weak self] collectionView, indexPath, index in
            collectionView.dequeueConfiguredReusableCell(
                using: self!.registration,
                for: indexPath,
                item: index
            )
        }
    }

    /// Replaces the rows shown in the grid.
    ///
    /// - Parameter rows: The formatted rows to display.
    func setRows(_ rows: [EditorRow]) {
        self.rows = rows
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(Array(rows.indices), toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    /// Marks a row as false, or clears the marking, scrolling it into view when set.
    ///
    /// - Parameter index: The false row's index, or `nil` to clear.
    func setFalseRow(_ index: Int?) {
        let changed = [falseIndex, index].compactMap { $0 }
        falseIndex = index
        reconfigure(changed)
        if let index { scroll(to: index) }
    }

    /// Sets the selected lead-end row, or clears it.
    ///
    /// - Parameter index: The selected row's index, or `nil` to clear.
    func setSelectedRow(_ index: Int?) {
        let changed = [selectedIndex, index].compactMap { $0 }
        selectedIndex = index
        reconfigure(changed)
    }

    /// Highlights the row currently sounding during playback, scrolling it into view.
    ///
    /// - Parameter index: The playing row's index, or `nil` to clear.
    func setPlaybackRow(_ index: Int?) {
        let changed = [playbackIndex, index].compactMap { $0 }
        playbackIndex = index
        reconfigure(changed)
        if let index { scroll(to: index) }
    }

    // MARK: Private

    /// Reconfigures the given row indices in place.
    ///
    /// The indices are deduplicated first: a caller often passes the previously marked row
    /// and the newly marked row together, and those can be the same index (for example when a
    /// false row is re-marked at the same position). A diffable snapshot rejects a
    /// reconfigure list that names the same identifier twice, so the set is made unique here.
    private func reconfigure(_ indices: [Int]) {
        let unique = Set(indices)
        guard !unique.isEmpty else { return }
        var snapshot = dataSource.snapshot()
        let existing = unique.filter { snapshot.itemIdentifiers.contains($0) }
        guard !existing.isEmpty else { return }
        snapshot.reconfigureItems(Array(existing))
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    /// Scrolls a row into view if it is not already visible.
    private func scroll(to index: Int) {
        guard rows.indices.contains(index) else { return }
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredVertically, animated: !UIAccessibility.isReduceMotionEnabled)
    }
}

extension RowGridView: UICollectionViewDelegate {

    /// Forwards a tap on a lead-end row as raw intent; ignores taps on other rows.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard rows.indices.contains(indexPath.item), rows[indexPath.item].isLeadEnd else { return }
        onSelectLeadEnd?(indexPath.item)
    }
}
