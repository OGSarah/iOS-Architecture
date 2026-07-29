//
//  CharacteristicWriting.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// The reason a characteristic write failed, carried back so the Presenter can show it inline.
struct CharacteristicWriteError: Error, Sendable, Equatable {
    /// A short human readable reason, for example "Accessory unreachable".
    let reason: String

    static let unreachable = CharacteristicWriteError(reason: "Accessory unreachable")
    static let notWritable = CharacteristicWriteError(reason: "This control is read only")
    static let rejected = CharacteristicWriteError(reason: "The accessory rejected the change")
}

/// The write side seam an Interactor uses to change a characteristic value.
///
/// Writes are asynchronous and failable. A rejected write leaves the on screen value ahead of
/// reality, which is exactly why the Interactor keeps the previous value and rolls back on failure.
@MainActor
protocol CharacteristicWriting: AnyObject {
    /// Writes a value to a characteristic.
    /// - Parameters:
    ///   - value: The new value to write.
    ///   - characteristicID: The characteristic to write to.
    /// - Throws: A `CharacteristicWriteError` when HomeKit rejects the write.
    func write(_ value: CharacteristicValue, toCharacteristic characteristicID: String) async throws
}
