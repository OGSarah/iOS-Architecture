//
//  TruthBannerView.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// The banner that appears when a composition repeats itself.
///
/// It is passive: it shows or hides the message it is told to. When shown it also posts a
/// VoiceOver announcement, so the failure is not conveyed by colour alone. It never decides
/// whether a touch is false.
final class TruthBannerView: UIView {

    /// The warning symbol shown beside the message.
    private let iconView = UIImageView()

    /// The message describing the failure.
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    /// Shows the banner with a message and announces it to assistive technologies.
    ///
    /// - Parameter message: The failure message to display.
    func show(message: String) {
        messageLabel.text = message
        setHidden(false)
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    /// Hides the banner.
    func hide() {
        setHidden(true)
    }

    /// Builds the icon and message layout.
    private func setUp() {
        backgroundColor = Theme.falseRow
        layer.cornerRadius = 12
        accessibilityIdentifier = AccessibilityID.Editor.truthBanner
        isAccessibilityElement = true
        accessibilityTraits = .staticText

        iconView.image = UIImage(systemName: "exclamationmark.triangle.fill")
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.translatesAutoresizingMaskIntoConstraints = false

        messageLabel.font = Theme.font(.subheadline)
        messageLabel.textColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(iconView)
        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            messageLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])

        setHidden(true)
    }

    /// Hides or reveals the banner, keeping its accessibility label in step.
    private func setHidden(_ hidden: Bool) {
        isHidden = hidden
        accessibilityLabel = hidden ? nil : messageLabel.text
    }
}
