//
//  ServiceSnapshot.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// An immutable snapshot of one capability of an accessory, for example a light or a fan.
struct ServiceSnapshot: Sendable, Equatable, Hashable, Identifiable {
    let id: String
    /// A stable service type key, for example "lightbulb" or "fan".
    let type: String
    let name: String
    let characteristics: [CharacteristicSnapshot]
    /// Ids of services this one links to, used to group a fan and a light in one ceiling fixture.
    let linkedServiceIDs: [String]
}
