//
//  CharacteristicSnapshot.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// An immutable snapshot of one readable or writable characteristic.
///
/// Produced by the mappers and owned by the Interactor. It carries an already decided `ControlKind`
/// so the View never has to inspect metadata itself.
struct CharacteristicSnapshot: Sendable, Equatable, Hashable, Identifiable {
    let id: String
    /// A stable characteristic type key, for example "power" or "brightness".
    let type: String
    /// A human readable name for the value.
    let displayName: String
    /// The current value at the moment the snapshot was taken.
    let value: CharacteristicValue
    /// The control the value should be rendered as, decided from metadata.
    let controlKind: ControlKind
    /// Whether the characteristic accepts writes.
    let isWritable: Bool

    /// Returns a copy of the snapshot with a new value, leaving everything else unchanged.
    /// - Parameter newValue: The value to substitute, for example during an optimistic write.
    /// - Returns: A new snapshot carrying `newValue`.
    func withValue(_ newValue: CharacteristicValue) -> CharacteristicSnapshot {
        CharacteristicSnapshot(
            id: id,
            type: type,
            displayName: displayName,
            value: newValue,
            controlKind: controlKind,
            isWritable: isWritable
        )
    }
}
