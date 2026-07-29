//
//  AutomationBuilderViewController.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// A passive form for assembling an automation. It gathers inputs and hands them to the Presenter.
///
/// The event half and the action half are separate sections, mirroring the model. The View decides
/// nothing about validity, it only collects and forwards.
final class AutomationBuilderViewController: UIViewController, AutomationBuilderViewInput {

    private let output: AutomationBuilderViewOutput

    private let nameField = UITextField()
    private let typeControl = UISegmentedControl(items: ["Timer", "Threshold Range"])
    private let lowerStepper = UIStepper()
    private let lowerLabel = UILabel()
    private let upperStepper = UIStepper()
    private let upperLabel = UILabel()
    private let turnOnSwitch = UISwitch()
    private let errorLabel = UILabel()
    private let thresholdSection = UIStackView()

    private var characteristicID = "char.temperature"

    init(output: AutomationBuilderViewOutput) {
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
        configureNavigationItems()
        configureForm()
        output.viewDidLoad()
    }

    // MARK: - AutomationBuilderViewInput

    func display(_ viewModel: AutomationBuilderViewModel) {
        title = viewModel.title
        nameField.text = viewModel.defaultName
        characteristicID = viewModel.defaultCharacteristicID
        lowerStepper.value = viewModel.defaultLower
        upperStepper.value = viewModel.defaultUpper
        typeControl.selectedSegmentIndex = 1
        updateStepperLabels()
        updateThresholdVisibility()
    }

    func showError(_ reason: String) {
        errorLabel.text = reason
        errorLabel.isHidden = false
        UIAccessibility.post(notification: .announcement, argument: reason)
    }

    // MARK: - Setup

    private func configureNavigationItems() {
        let cancel = UIBarButtonItem(systemItem: .cancel, primaryAction: UIAction { [weak self] _ in
            self?.output.didTapCancel()
        })
        cancel.accessibilityIdentifier = AccessibilityIdentifiers.AutomationBuilder.cancelButton
        navigationItem.leftBarButtonItem = cancel

        let save = UIBarButtonItem(systemItem: .save, primaryAction: UIAction { [weak self] _ in
            self?.saveTapped()
        })
        save.accessibilityIdentifier = AccessibilityIdentifiers.AutomationBuilder.saveButton
        navigationItem.rightBarButtonItem = save
    }

    private func configureForm() {
        nameField.borderStyle = .roundedRect
        nameField.placeholder = "Automation name"
        nameField.font = .preferredFont(forTextStyle: .body)
        nameField.adjustsFontForContentSizeCategory = true
        nameField.accessibilityLabel = "Automation name"

        typeControl.accessibilityIdentifier = AccessibilityIdentifiers.AutomationBuilder.saveButton + ".type"
        typeControl.addAction(UIAction { [weak self] _ in self?.updateThresholdVisibility() }, for: .valueChanged)

        lowerStepper.minimumValue = -40
        lowerStepper.maximumValue = 60
        lowerStepper.stepValue = 1
        lowerStepper.addAction(UIAction { [weak self] _ in self?.updateStepperLabels() }, for: .valueChanged)
        lowerStepper.accessibilityLabel = "Lower bound"

        upperStepper.minimumValue = -40
        upperStepper.maximumValue = 60
        upperStepper.stepValue = 1
        upperStepper.addAction(UIAction { [weak self] _ in self?.updateStepperLabels() }, for: .valueChanged)
        upperStepper.accessibilityLabel = "Upper bound"

        [lowerLabel, upperLabel].forEach {
            $0.font = .preferredFont(forTextStyle: .subheadline)
            $0.adjustsFontForContentSizeCategory = true
            $0.textColor = .secondaryLabel
        }

        turnOnSwitch.isOn = true
        turnOnSwitch.onTintColor = UIColor(named: "AccentColor")
        turnOnSwitch.accessibilityLabel = "Turn target on when the automation fires"

        errorLabel.font = .preferredFont(forTextStyle: .footnote)
        errorLabel.adjustsFontForContentSizeCategory = true
        errorLabel.textColor = UIColor(named: "WarningAmber")
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        let lowerRow = labeledRow("Lower", control: lowerStepper, valueLabel: lowerLabel)
        let upperRow = labeledRow("Upper", control: upperStepper, valueLabel: upperLabel)
        thresholdSection.axis = .vertical
        thresholdSection.spacing = 12
        thresholdSection.addArrangedSubview(lowerRow)
        thresholdSection.addArrangedSubview(upperRow)

        let actionRow = labeledRow("Turn on", control: turnOnSwitch, valueLabel: nil)

        let stack = UIStackView(arrangedSubviews: [
            sectionTitle("Name"), nameField,
            sectionTitle("When"), typeControl, thresholdSection,
            sectionTitle("Do"), actionRow,
            errorLabel
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    // MARK: - Actions

    private func saveTapped() {
        errorLabel.isHidden = true
        let input = AutomationBuilderInput(
            name: nameField.text ?? "",
            triggerType: typeControl.selectedSegmentIndex == 0 ? .timer : .thresholdRange,
            characteristicID: characteristicID,
            lower: lowerStepper.value,
            upper: upperStepper.value,
            turnOn: turnOnSwitch.isOn
        )
        output.didTapSave(input)
    }

    private func updateThresholdVisibility() {
        thresholdSection.isHidden = typeControl.selectedSegmentIndex == 0
    }

    private func updateStepperLabels() {
        lowerLabel.text = "\(Int(lowerStepper.value)) degrees C"
        upperLabel.text = "\(Int(upperStepper.value)) degrees C"
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }

    private func labeledRow(_ title: String, control: UIView, valueLabel: UILabel?) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true

        let arranged = [titleLabel, valueLabel, control].compactMap { $0 }
        let row = UIStackView(arrangedSubviews: arranged)
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        control.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }
}
