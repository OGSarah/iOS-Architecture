//
//  MethodPickerViewController.swift
//  ChangeRinger-MVP
//
//  Created by Sarah Clark on 7/17/26.
//

import UIKit

/// The passive view controller for choosing a method.
///
/// It conforms to `MethodPickerView` and implements it literally: `display(methods:)` stores
/// the formatted choices and reloads the table. A tap forwards straight to the presenter. It
/// holds no method logic and makes no decisions of its own.
final class MethodPickerViewController: UITableViewController, MethodPickerView {

    /// The presenter driving this screen.
    private let presenter: MethodPickerPresenter

    /// The formatted choices to show.
    private var choices: [MethodChoice] = []

    /// The reuse identifier for a method cell.
    private let cellID = "MethodCell"

    /// Creates the picker with its presenter.
    ///
    /// - Parameter presenter: The presenter to drive the screen.
    init(presenter: MethodPickerPresenter) {
        self.presenter = presenter
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Choose a Method"
        view.backgroundColor = Theme.navy
        tableView.backgroundColor = Theme.navy
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.accessibilityIdentifier = AccessibilityID.MethodPicker.table

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )

        presenter.view = self
        presenter.start()
    }

    // MARK: MethodPickerView

    func display(methods: [MethodChoice]) {
        choices = methods
        tableView.reloadData()
    }

    // MARK: Table view

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        choices.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let choice = choices[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = choice.name
        content.textProperties.color = Theme.primaryText
        content.textProperties.font = Theme.font(.headline)
        content.secondaryText = choice.detail
        content.secondaryTextProperties.color = Theme.secondaryText
        content.secondaryTextProperties.font = Theme.font(.subheadline)
        cell.contentConfiguration = content

        cell.backgroundColor = Theme.navyElevated
        cell.accessibilityIdentifier = AccessibilityID.MethodPicker.row(indexPath.row)
        let selectedBackground = UIView()
        selectedBackground.backgroundColor = Theme.gold.withAlphaComponent(0.25)
        cell.selectedBackgroundView = selectedBackground
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presenter.didSelectMethod(at: indexPath.row)
        dismiss(animated: true)
    }
}
