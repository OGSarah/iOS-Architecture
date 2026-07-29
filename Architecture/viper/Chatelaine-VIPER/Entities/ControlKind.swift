//
//  ControlKind.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation

/// The unit a numeric characteristic is expressed in, used only for display.
enum CharacteristicUnit: String, Sendable, Equatable, Hashable {
    case percentage
    case celsius
    case fahrenheit
    case seconds
    case arcDegrees
    case lux
    case none
}

/// A single option in a `.picker` control, pairing a raw value with a human readable label.
struct PickerOption: Sendable, Equatable, Hashable, Identifiable {
    let id: Int
    let label: String
}

/// The kind of control a characteristic should be rendered as, derived from its metadata.
///
/// This is the value `CharacteristicMapper` produces from a characteristic's format, bounds, step,
/// units, and valid value set. The View switches on it to pick a cell and never inspects accessory
/// type to make the same decision. A brightness characteristic with a step of ten wants a stepper,
/// not a continuous slider, and only the metadata reveals that.
enum ControlKind: Sendable, Equatable, Hashable {
    /// An on or off switch, for a boolean writable characteristic.
    case toggle
    /// A continuous slider between `min` and `max`.
    case slider(min: Double, max: Double, unit: CharacteristicUnit)
    /// A discrete stepper, chosen when the step divides the range into a small number of stops.
    case stepper(min: Double, max: Double, step: Double, unit: CharacteristicUnit)
    /// A picker over an enumerated set of valid values.
    case picker(options: [PickerOption])
    /// A read only label, for characteristics with no write permission or an unknown format.
    case readout(unit: CharacteristicUnit)
}
