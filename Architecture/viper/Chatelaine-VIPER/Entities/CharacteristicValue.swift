//
//  CharacteristicValue.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation

/// The closed set of value types a HomeKit characteristic can carry.
///
/// HomeKit hands characteristic values back as `Any?`. This project closes that into an enum at the
/// mapping boundary so that nothing above the `Services` layer ever performs a conditional cast.
enum CharacteristicValue: Sendable, Equatable, Hashable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case data(Data)
    /// A value that could not be represented, kept as a case rather than a crash.
    case unknown

    /// The value expressed as a `Double` when it is numeric or boolean, otherwise `nil`.
    var doubleValue: Double? {
        switch self {
        case let .int(value): Double(value)
        case let .double(value): value
        case let .bool(value): value ? 1 : 0
        default: nil
        }
    }

    /// The value expressed as a `Bool` when it is boolean or a 0 or 1 number, otherwise `nil`.
    var boolValue: Bool? {
        switch self {
        case let .bool(value): value
        case let .int(value): value == 0 ? false : (value == 1 ? true : nil)
        default: nil
        }
    }
}
