//
//  SettingsViewController.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// A passive grouped settings screen with the motion toggle and the onboarding replay action.
final class SettingsViewController: UIViewController, SettingsViewInput, UITableViewDataSource, UITableViewDelegate {

    private let output: SettingsViewOutput
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var viewModel: SettingsViewModel?

    private enum Section: Int, CaseIterable {
        case motion
        case onboarding
    }

    init(output: SettingsViewOutput) {
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used, this controller is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak self] _ in
            self?.output.didTapDone()
        })
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        output.viewDidLoad()
    }

    // MARK: - SettingsViewInput

    func display(_ viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        title = viewModel.title
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true

        switch Section(rawValue: indexPath.section) {
        case .motion:
            cell.textLabel?.text = viewModel?.animationsRowTitle
            let toggle = UISwitch()
            toggle.isOn = viewModel?.animationsEnabled ?? true
            toggle.onTintColor = Palette.accent
            toggle.accessibilityIdentifier = "settings.animationsToggle"
            toggle.addAction(UIAction { [weak self] _ in self?.output.didToggleAnimations(toggle.isOn) }, for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none

        case .onboarding, .none:
            cell.textLabel?.text = viewModel?.replayTitle
            cell.textLabel?.textColor = Palette.accent
            cell.accessibilityIdentifier = "settings.replayOnboarding"
        }
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .motion: "Motion"
        case .onboarding: "Onboarding"
        case .none: nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .motion: viewModel?.animationsFootnote
        case .onboarding: [viewModel?.appearanceNote, viewModel?.versionText].compactMap { $0 }.joined(separator: "\n\n")
        case .none: nil
        }
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if Section(rawValue: indexPath.section) == .onboarding {
            output.didTapReplayOnboarding()
        }
    }
}
