//
//  RowCell.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// A single row line in the grid: its number, its bells, and its call.
///
/// The cell only lays out the values it is configured with. The traced bell is drawn in the
/// blue-line colour inside a filled marker, so the aligned markers down the grid form the
/// blue line. Lead ends carry a divider and their call symbol, a false row is tinted and
/// labelled, and selection and playback are shown as background fills.
final class RowCell: UICollectionViewCell {

    /// The row's index, shown in a leading gutter.
    private let numberLabel = UILabel()

    /// The horizontal stack of one label per bell.
    private let bellsStack = UIStackView()

    /// The call symbol shown at the trailing edge on lead ends.
    private let callLabel = UILabel()

    /// The hairline divider drawn beneath a lead-end row.
    private let divider = UIView()

    /// The labels currently in the bells stack, reused between configurations.
    private var bellLabels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    /// Builds the cell's fixed layout once.
    private func setUp() {
        numberLabel.font = Theme.font(.caption1)
        numberLabel.textColor = Theme.secondaryText
        numberLabel.textAlignment = .center
        numberLabel.setContentHuggingPriority(.required, for: .horizontal)
        numberLabel.translatesAutoresizingMaskIntoConstraints = false

        bellsStack.axis = .horizontal
        bellsStack.distribution = .fillEqually
        bellsStack.alignment = .center
        bellsStack.translatesAutoresizingMaskIntoConstraints = false

        callLabel.font = Theme.rowFont()
        callLabel.textColor = Theme.gold
        callLabel.textAlignment = .center
        callLabel.setContentHuggingPriority(.required, for: .horizontal)
        callLabel.translatesAutoresizingMaskIntoConstraints = false

        divider.backgroundColor = Theme.gold.withAlphaComponent(0.35)
        divider.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(numberLabel)
        contentView.addSubview(bellsStack)
        contentView.addSubview(callLabel)
        contentView.addSubview(divider)

        NSLayoutConstraint.activate([
            numberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            numberLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            numberLabel.widthAnchor.constraint(equalToConstant: 34),

            bellsStack.leadingAnchor.constraint(equalTo: numberLabel.trailingAnchor, constant: 8),
            bellsStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            bellsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),

            callLabel.leadingAnchor.constraint(equalTo: bellsStack.trailingAnchor, constant: 8),
            callLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            callLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            callLabel.widthAnchor.constraint(equalToConstant: 22),

            divider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])

        isAccessibilityElement = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        for label in bellLabels { label.backgroundColor = .clear }
    }

    /// Configures the cell for a row and its current states.
    ///
    /// - Parameters:
    ///   - row: The row to draw.
    ///   - isFalse: Whether this row is the marked false row.
    ///   - isSelected: Whether this row is the selected lead end.
    ///   - isPlaying: Whether this row is currently sounding.
    func configure(row: EditorRow, isFalse: Bool, isSelected: Bool, isPlaying: Bool) {
        numberLabel.text = "\(row.index)"
        rebuildBells(for: row, isFalse: isFalse)

        if row.callSymbol.isEmpty {
            callLabel.text = row.isLeadEnd ? "\u{00B7}" : ""
            callLabel.textColor = Theme.gold.withAlphaComponent(0.5)
        } else {
            callLabel.text = row.callSymbol
            callLabel.textColor = Theme.gold
        }

        divider.isHidden = !row.isLeadEnd

        // Background reflects, in priority order, playback then selection then falseness.
        if isPlaying {
            contentView.backgroundColor = Theme.gold.withAlphaComponent(0.40)
        } else if isSelected {
            contentView.backgroundColor = Theme.gold.withAlphaComponent(0.22)
        } else if isFalse {
            contentView.backgroundColor = Theme.falseRow.withAlphaComponent(0.20)
        } else {
            contentView.backgroundColor = .clear
        }

        configureAccessibility(row: row, isFalse: isFalse)
    }

    // MARK: Private

    /// Rebuilds the per-bell labels, highlighting the traced bell.
    private func rebuildBells(for row: EditorRow, isFalse: Bool) {
        let symbols = Array(row.notation)
        if bellLabels.count != symbols.count {
            for label in bellLabels { label.removeFromSuperview() }
            bellLabels = symbols.map { _ in
                let label = UILabel()
                label.font = Theme.rowFont()
                label.textAlignment = .center
                label.adjustsFontForContentSizeCategory = true
                label.clipsToBounds = true
                bellsStack.addArrangedSubview(label)
                return label
            }
        }
        for (column, symbol) in symbols.enumerated() {
            let label = bellLabels[column]
            label.text = String(symbol)
            let isTraced = row.blueLineColumn == column + 1
            if isTraced {
                label.textColor = .white
                label.backgroundColor = Theme.blueLine
                label.layer.cornerRadius = 14
            } else {
                label.backgroundColor = .clear
                label.textColor = isFalse ? Theme.falseRow : Theme.primaryText
            }
        }
    }

    /// Composes the VoiceOver label and traits for the row.
    private func configureAccessibility(row: EditorRow, isFalse: Bool) {
        accessibilityIdentifier = AccessibilityID.Editor.row(row.index)
        let spelled = row.notation.map(String.init).joined(separator: " ")
        var parts = ["Row \(row.index), \(spelled)"]
        if !row.callSymbol.isEmpty {
            parts.append(row.callSymbol == "-" ? "bob" : "single")
        }
        if row.isLeadEnd { parts.append("lead end") }
        if isFalse { parts.append("false, repeats an earlier row") }
        accessibilityLabel = parts.joined(separator: ", ")
        accessibilityTraits = row.isLeadEnd ? .button : .staticText
        accessibilityHint = row.isLeadEnd ? "Double tap to place a call here" : nil
    }
}
