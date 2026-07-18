//
//  CallStripView.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// The strip of call buttons for inserting a plain, bob, or single at the selected lead end.
///
/// It is passive: each button reports its `Call` through `onCall`, and it exposes a prompt
/// and an enabled state the presenter's view controller can set. It never decides whether a
/// call is legal.
final class CallStripView: UIView {

    /// Called with the chosen call when a button is tapped.
    var onCall: ((Call) -> Void)?

    /// The prompt shown above the buttons.
    private let promptLabel = UILabel()

    /// The horizontal stack of call buttons.
    private let buttonStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    /// Enables or disables the buttons and updates the prompt to match.
    ///
    /// - Parameter enabled: Whether a lead end is selected and calls can be placed.
    func setEnabled(_ enabled: Bool) {
        buttonStack.arrangedSubviews.forEach { ($0 as? UIButton)?.isEnabled = enabled }
        buttonStack.alpha = enabled ? 1 : 0.4
        promptLabel.text = enabled
            ? "Place a call at the selected lead end"
            : "Select a lead end to place a call"
    }

    /// Builds the prompt and the three call buttons.
    private func setUp() {
        backgroundColor = Theme.navyElevated

        promptLabel.font = Theme.font(.caption1)
        promptLabel.textColor = Theme.secondaryText
        promptLabel.adjustsFontForContentSizeCategory = true
        promptLabel.translatesAutoresizingMaskIntoConstraints = false

        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 10
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        for call in Call.allCases {
            buttonStack.addArrangedSubview(makeButton(for: call))
        }

        addSubview(promptLabel)
        addSubview(buttonStack)
        accessibilityIdentifier = AccessibilityID.CallStrip.container

        NSLayoutConstraint.activate([
            promptLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            promptLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            promptLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            buttonStack.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 6),
            buttonStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            buttonStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])

        setEnabled(false)
    }

    /// Builds one styled call button.
    private func makeButton(for call: Call) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = call.name
        configuration.baseBackgroundColor = Theme.gold
        configuration.baseForegroundColor = Theme.navy
        configuration.cornerStyle = .large
        configuration.buttonSize = .large

        let button = UIButton(configuration: configuration)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = identifier(for: call)
        button.accessibilityLabel = "\(call.name) call"
        button.addAction(UIAction { [weak self] _ in self?.onCall?(call) }, for: .primaryActionTriggered)
        return button
    }

    /// The accessibility identifier for a call's button.
    private func identifier(for call: Call) -> String {
        switch call {
            case .plain: return AccessibilityID.CallStrip.plain
            case .bob: return AccessibilityID.CallStrip.bob
            case .single: return AccessibilityID.CallStrip.single
        }
    }
}
