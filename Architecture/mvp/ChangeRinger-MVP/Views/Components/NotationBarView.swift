//
//  NotationBarView.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// The bar for viewing and editing the method's place notation directly.
///
/// It is passive: it shows whatever notation string it is given and reports an edited string
/// through `onCommit` when the user finishes typing. It never parses or validates the
/// notation, which is the presenter's job.
final class NotationBarView: UIView {

    /// Called with the edited notation when the user commits an edit.
    var onCommit: ((String) -> Void)?

    /// The caption above the field.
    private let captionLabel = UILabel()

    /// The editable notation field.
    private let field = UITextField()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    /// The notation text shown in the field.
    ///
    /// - Parameter notation: The notation string to display.
    func setNotation(_ notation: String) {
        field.text = notation
    }

    /// Builds the caption and field layout.
    private func setUp() {
        backgroundColor = Theme.navyElevated

        captionLabel.text = "Place notation"
        captionLabel.font = Theme.font(.caption1)
        captionLabel.textColor = Theme.secondaryText
        captionLabel.adjustsFontForContentSizeCategory = true
        captionLabel.translatesAutoresizingMaskIntoConstraints = false

        field.font = Theme.rowFont()
        field.textColor = Theme.primaryText
        field.tintColor = Theme.gold
        field.autocapitalizationType = .allCharacters
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.borderStyle = .none
        field.delegate = self
        field.accessibilityIdentifier = AccessibilityID.Editor.notationField
        field.accessibilityLabel = "Place notation"
        field.adjustsFontForContentSizeCategory = true
        field.translatesAutoresizingMaskIntoConstraints = false

        addSubview(captionLabel)
        addSubview(field)

        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            field.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 2),
            field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            field.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
}

extension NotationBarView: UITextFieldDelegate {

    /// Commits the edit and dismisses the keyboard when the user taps Done.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    /// Reports the committed notation once editing ends.
    func textFieldDidEndEditing(_ textField: UITextField) {
        onCommit?(textField.text ?? "")
    }
}
