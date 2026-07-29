//
//  CharacteristicMapper.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation

/// The read, write, and notify permissions a characteristic declares.
struct CharacteristicPermissions: OptionSet, Sendable, Equatable, Hashable {
    let rawValue: Int
    static let read = CharacteristicPermissions(rawValue: 1 << 0)
    static let write = CharacteristicPermissions(rawValue: 1 << 1)
    static let notify = CharacteristicPermissions(rawValue: 1 << 2)
}

/// The HomeKit characteristic value formats, closed into a case so mapping never sees a raw string.
enum CharacteristicFormat: Sendable, Equatable, Hashable {
    case bool
    case int
    case float
    case uint8
    case uint16
    case uint32
    case uint64
    case string
    case data
    case tlv8
    case unknown

    /// Whether the format is a numeric quantity that a slider or stepper can represent.
    var isNumeric: Bool {
        switch self {
        case .int, .float, .uint8, .uint16, .uint32, .uint64: true
        default: false
        }
    }
}

/// A plain, `Sendable` description of a characteristic's metadata.
///
/// `HomeStore` builds one of these from `HMCharacteristicMetadata` so the mapping logic below stays
/// free of HomeKit and can be exercised directly by the tests over every format, bound, and step.
struct CharacteristicMetadataDescriptor: Sendable, Equatable, Hashable {
    let format: CharacteristicFormat
    let permissions: CharacteristicPermissions
    let minValue: Double?
    let maxValue: Double?
    let stepValue: Double?
    let unit: CharacteristicUnit
    /// An enumerated set of valid raw values, present only for pickers.
    let validValues: [Int]?

    var isReadable: Bool { permissions.contains(.read) }
    var isWritable: Bool { permissions.contains(.write) }
}

/// Turns characteristic metadata into the control the View should render.
///
/// The rules are deliberate and are the highest value logic in the project, so they live in one
/// pure function with no UIKit and no HomeKit. The View never repeats any of this.
enum CharacteristicMapper {

    /// The largest number of discrete stops that still prefers a stepper over a slider.
    static let maxStepperStops: Double = 20

    /// Decides the control kind for a characteristic from its metadata.
    /// - Parameter metadata: The characteristic's format, permissions, bounds, step, and valid values.
    /// - Returns: The `ControlKind` the View should render.
    static func controlKind(for metadata: CharacteristicMetadataDescriptor) -> ControlKind {
        // An enumerated set of writable values is always a picker, regardless of format.
        if metadata.isWritable, let validValues = metadata.validValues, !validValues.isEmpty {
            let options = validValues.map { PickerOption(id: $0, label: String($0)) }
            return .picker(options: options)
        }

        switch metadata.format {
        case .bool:
            // A writable boolean is a switch. A read only boolean is just a label.
            return metadata.isWritable ? .toggle : .readout(unit: metadata.unit)

        case .int, .float, .uint8, .uint16, .uint32, .uint64:
            // Numeric controls need bounds. Without them, degrade to a readout rather than guess.
            guard let minValue = metadata.minValue,
                  let maxValue = metadata.maxValue,
                  maxValue > minValue else {
                return .readout(unit: metadata.unit)
            }
            // A read only numeric value is a label, even though it has a range.
            guard metadata.isWritable else {
                return .readout(unit: metadata.unit)
            }
            // A coarse step means discrete stops, which a stepper expresses better than a slider.
            if let step = metadata.stepValue, step > 0 {
                let stops = (maxValue - minValue) / step
                if stops <= maxStepperStops {
                    return .stepper(min: minValue, max: maxValue, step: step, unit: metadata.unit)
                }
            }
            return .slider(min: minValue, max: maxValue, unit: metadata.unit)

        case .string, .data, .tlv8, .unknown:
            // Unknown and opaque formats degrade to a readout rather than to a crash.
            return .readout(unit: metadata.unit)
        }
    }

    /// Builds a full characteristic snapshot from its identity, value, and metadata.
    /// - Parameters:
    ///   - id: The characteristic identifier.
    ///   - type: A stable type key, for example "brightness".
    ///   - displayName: A human readable name for the value.
    ///   - value: The current value.
    ///   - metadata: The metadata used to choose the control kind and writability.
    /// - Returns: An immutable `CharacteristicSnapshot`.
    static func snapshot(
        id: String,
        type: String,
        displayName: String,
        value: CharacteristicValue,
        metadata: CharacteristicMetadataDescriptor
    ) -> CharacteristicSnapshot {
        CharacteristicSnapshot(
            id: id,
            type: type,
            displayName: displayName,
            value: value,
            controlKind: controlKind(for: metadata),
            isWritable: metadata.isWritable
        )
    }
}
