//
//  ServiceControlPresenter.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation

/// The hub of the module and the only stateful type in it.
///
/// It receives intent from the View, drives the Interactor, converts snapshots into a view model of
/// already formatted strings and already chosen control kinds, and asks the Router to navigate. It
/// never formats a value the View could have formatted differently, and it never calls a navigation
/// API directly.
final class ServiceControlPresenter {

    weak var view: ServiceControlViewInput?
    private let interactor: ServiceControlInteractorInput
    private let router: ServiceControlRouterInput

    /// The current snapshot, held so intent can be resolved against the latest values.
    private var service: ServiceSnapshot
    /// Inline reasons keyed by characteristic id, shown after a rejected write and cleared on change.
    private var reasons: [String: String] = [:]

    init(service: ServiceSnapshot, interactor: ServiceControlInteractorInput, router: ServiceControlRouterInput) {
        self.service = service
        self.interactor = interactor
        self.router = router
    }
}

// MARK: - ServiceControlViewOutput

extension ServiceControlPresenter: ServiceControlViewOutput {

    func viewDidLoad() {
        interactor.loadInitial()
        interactor.startNotifications()
    }

    func viewWillDisappear() {
        interactor.stopNotifications()
    }

    func didToggle(characteristicID: String, isOn: Bool) {
        reasons[characteristicID] = nil
        interactor.setValue(.bool(isOn), for: characteristicID)
    }

    func didChangeValue(_ value: Double, characteristicID: String) {
        reasons[characteristicID] = nil
        interactor.setValue(numericValue(value, for: characteristicID), for: characteristicID)
    }

    func didSelectOption(optionID: Int, characteristicID: String) {
        reasons[characteristicID] = nil
        interactor.setValue(.int(optionID), for: characteristicID)
    }
}

// MARK: - ServiceControlInteractorOutput

extension ServiceControlPresenter: ServiceControlInteractorOutput {

    func didUpdate(service: ServiceSnapshot) {
        self.service = service
        view?.display(makeViewModel())
    }

    func didFailWrite(previous: ServiceSnapshot, reason: String) {
        service = previous
        // Attach the reason to whichever characteristic changed, best effort by diffing is overkill,
        // so the reason is shown against the whole service and announced for VoiceOver.
        reasons = previous.characteristics.reduce(into: [:]) { $0[$1.id] = reason }
        view?.display(makeViewModel())
        view?.announce(reason)
    }
}

// MARK: - View model construction

private extension ServiceControlPresenter {

    func makeViewModel() -> ServiceControlViewModel {
        let rows = service.characteristics.map { characteristic in
            ServiceControlViewModel.Row(
                id: characteristic.id,
                title: characteristic.displayName,
                valueText: valueText(for: characteristic),
                control: characteristic.controlKind,
                isEnabled: characteristic.isWritable,
                reason: reasons[characteristic.id],
                accessibilityLabel: "\(characteristic.displayName), \(valueText(for: characteristic))"
            )
        }
        return ServiceControlViewModel(title: service.name, statusNote: nil, rows: rows)
    }

    /// Builds the display text for a value, honoring the control's unit.
    func valueText(for characteristic: CharacteristicSnapshot) -> String {
        switch characteristic.value {
        case let .bool(isOn):
            return isOn ? "On" : "Off"
        case let .int(number):
            return unitText(Double(number), unit: unit(of: characteristic.controlKind))
        case let .double(number):
            return unitText(number, unit: unit(of: characteristic.controlKind))
        case let .string(text):
            return text
        case .data, .unknown:
            return "Unavailable"
        }
    }

    /// Formats a number with its unit, keeping the decimals a value actually has.
    func unitText(_ number: Double, unit: CharacteristicUnit) -> String {
        let rounded = number.rounded()
        let base = number == rounded ? String(Int(rounded)) : String(format: "%.1f", number)
        switch unit {
        case .percentage: return "\(base)%"
        case .celsius: return "\(base) degrees C"
        case .fahrenheit: return "\(base) degrees F"
        case .seconds: return "\(base) s"
        case .arcDegrees: return "\(base) degrees"
        case .lux: return "\(base) lux"
        case .none: return base
        }
    }

    /// Chooses the numeric case matching the characteristic's current value type.
    func numericValue(_ value: Double, for characteristicID: String) -> CharacteristicValue {
        let current = service.characteristics.first { $0.id == characteristicID }?.value
        if case .double = current { return .double(value) }
        return .int(Int(value.rounded()))
    }

    func unit(of control: ControlKind) -> CharacteristicUnit {
        switch control {
        case let .slider(_, _, unit): unit
        case let .stepper(_, _, _, unit): unit
        case let .readout(unit): unit
        case .toggle, .picker: .none
        }
    }
}
