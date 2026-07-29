//
//  ServiceControlCell.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// One row of the service, drawing whichever control the view model's `ControlKind` calls for.
///
/// The cell contains a title, a value, an optional inline reason, and exactly one control chosen
/// from the row. It forwards raw events to the view output and knows nothing about writes.
final class ServiceControlCell: UICollectionViewListCell {

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let reasonLabel = UILabel()
    private let controlContainer = UIView()

    /// The characteristic id this cell currently represents, used when forwarding events.
    private var characteristicID: String?
    private weak var output: ServiceControlViewOutput?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used, this cell is built in code")
    }

    /// Binds a row to the cell, replacing the control with the one the row calls for.
    /// - Parameters:
    ///   - row: The row to render.
    ///   - output: The view output raw events are forwarded to.
    func configure(with row: ServiceControlViewModel.Row, output: ServiceControlViewOutput) {
        characteristicID = row.id
        self.output = output

        titleLabel.text = row.title
        valueLabel.text = row.valueText
        reasonLabel.text = row.reason
        reasonLabel.isHidden = row.reason == nil
        reasonLabel.accessibilityIdentifier = AccessibilityIdentifiers.ServiceControl.reason(row.id)

        controlContainer.subviews.forEach { $0.removeFromSuperview() }
        if let control = makeControl(for: row) {
            control.accessibilityIdentifier = AccessibilityIdentifiers.ServiceControl.control(row.id)
            control.accessibilityLabel = row.accessibilityLabel
            control.isEnabled = row.isEnabled
            control.translatesAutoresizingMaskIntoConstraints = false
            controlContainer.addSubview(control)
            NSLayoutConstraint.activate([
                control.leadingAnchor.constraint(equalTo: controlContainer.leadingAnchor),
                control.trailingAnchor.constraint(equalTo: controlContainer.trailingAnchor),
                control.centerYAnchor.constraint(equalTo: controlContainer.centerYAnchor),
                control.topAnchor.constraint(greaterThanOrEqualTo: controlContainer.topAnchor),
                control.bottomAnchor.constraint(lessThanOrEqualTo: controlContainer.bottomAnchor)
            ])
        }
    }

    // MARK: - Layout

    private func setUpLayout() {
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label

        valueLabel.font = .preferredFont(forTextStyle: .subheadline)
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.textColor = .secondaryLabel

        reasonLabel.font = .preferredFont(forTextStyle: .footnote)
        reasonLabel.adjustsFontForContentSizeCategory = true
        reasonLabel.textColor = UIColor(named: "WarningAmber")
        reasonLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel, reasonLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let rowStack = UIStackView(arrangedSubviews: [textStack, controlContainer])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        controlContainer.setContentHuggingPriority(.required, for: .horizontal)
        controlContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true

        contentView.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            rowStack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            rowStack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    // MARK: - Control building

    /// Builds the control the row asks for, wired to forward events to the output.
    private func makeControl(for row: ServiceControlViewModel.Row) -> UIControl? {
        switch row.control {
        case .toggle:
            return makeSwitch(isOn: row.valueText == "On")
        case let .slider(minimum, maximum, _):
            return makeSlider(minimum: minimum, maximum: maximum, valueText: row.valueText)
        case let .stepper(minimum, maximum, step, _):
            return makeStepper(minimum: minimum, maximum: maximum, step: step, valueText: row.valueText)
        case let .picker(options):
            return makePicker(options: options)
        case .readout:
            return nil
        }
    }

    private func makeSwitch(isOn: Bool) -> UISwitch {
        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.onTintColor = UIColor(named: "AccentColor")
        toggle.addAction(UIAction { [weak self] _ in
            guard let self, let id = characteristicID else { return }
            output?.didToggle(characteristicID: id, isOn: toggle.isOn)
        }, for: .valueChanged)
        return toggle
    }

    private func makeSlider(minimum: Double, maximum: Double, valueText: String) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = Float(minimum)
        slider.maximumValue = Float(maximum)
        slider.value = Float(Self.leadingNumber(in: valueText) ?? minimum)
        slider.minimumTrackTintColor = UIColor(named: "AccentColor")
        slider.addAction(UIAction { [weak self] _ in
            guard let self, let id = characteristicID else { return }
            output?.didChangeValue(Double(slider.value), characteristicID: id)
        }, for: .valueChanged)
        return slider
    }

    private func makeStepper(minimum: Double, maximum: Double, step: Double, valueText: String) -> UIStepper {
        let stepper = UIStepper()
        stepper.minimumValue = minimum
        stepper.maximumValue = maximum
        stepper.stepValue = step
        stepper.value = Self.leadingNumber(in: valueText) ?? minimum
        stepper.addAction(UIAction { [weak self] _ in
            guard let self, let id = characteristicID else { return }
            output?.didChangeValue(stepper.value, characteristicID: id)
        }, for: .valueChanged)
        return stepper
    }

    private func makePicker(options: [PickerOption]) -> UIButton {
        var configuration = UIButton.Configuration.tinted()
        configuration.baseForegroundColor = UIColor(named: "AccentColor")
        let button = UIButton(configuration: configuration)
        button.showsMenuAsPrimaryAction = true
        button.menu = UIMenu(children: options.map { option in
            UIAction(title: option.label) { [weak self] _ in
                guard let self, let id = characteristicID else { return }
                output?.didSelectOption(optionID: option.id, characteristicID: id)
            }
        })
        return button
    }

    /// Extracts the leading number from a formatted value string such as "60%".
    private static func leadingNumber(in text: String) -> Double? {
        let prefix = text.prefix { $0.isNumber || $0 == "." || $0 == "-" }
        return Double(prefix)
    }
}
