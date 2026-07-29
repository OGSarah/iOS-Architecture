//
//  AccessorySetupViewController.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// A passive setup screen. It shows the add action when commissioning is available, and a clear
/// unavailable message when it is not.
final class AccessorySetupViewController: UIViewController, AccessorySetupViewInput {

    private let output: AccessorySetupViewOutput

    private let iconView = UIImageView(image: UIImage(systemName: "sensor.tag.radiowaves.forward.fill"))
    private let messageLabel = UILabel()
    private let addButton = UIButton(configuration: .borderedProminent())

    init(output: AccessorySetupViewOutput) {
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
        configureCancelButton()
        configureLayout()
        output.viewDidLoad()
    }

    // MARK: - AccessorySetupViewInput

    func display(_ viewModel: AccessorySetupViewModel) {
        title = viewModel.title
        messageLabel.text = viewModel.message
        addButton.configuration?.title = viewModel.addButtonTitle
        addButton.isEnabled = viewModel.isAddEnabled
    }

    func showError(_ reason: String) {
        UIAccessibility.post(notification: .announcement, argument: reason)
        let alert = UIAlertController(title: "Setup Failed", message: reason, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Setup

    private func configureCancelButton() {
        let cancel = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.output.didTapCancel()
        })
        cancel.accessibilityIdentifier = AccessibilityIdentifiers.Setup.cancelButton
        navigationItem.leftBarButtonItem = cancel
    }

    private func configureLayout() {
        iconView.tintColor = UIColor(named: "AccentColor")
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 56)

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = .label
        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.adjustsFontForContentSizeCategory = true

        addButton.configuration?.buttonSize = .large
        addButton.configuration?.baseBackgroundColor = UIColor(named: "AccentColor")
        addButton.addAction(UIAction { [weak self] _ in self?.output.didTapAddDevice() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [iconView, messageLabel, addButton])
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: -16)
        ])
    }
}
