//
//  HomeSnapshot.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// A grouping of rooms that cuts across the room hierarchy rather than nesting inside it.
struct ZoneSnapshot: Sendable, Equatable, Hashable, Identifiable {
    let id: String
    let name: String
    let roomIDs: [String]
}

/// An immutable snapshot of one dwelling and everything it owns.
///
/// This is the top of the value graph the Interactors work with. Nothing here is a HomeKit
/// reference type, so it can cross to a Presenter under Swift 6 strict concurrency.
struct HomeSnapshot: Sendable, Equatable, Hashable, Identifiable {
    let id: String
    let name: String
    let isPrimary: Bool
    let rooms: [RoomSnapshot]
    let zones: [ZoneSnapshot]
    let accessories: [AccessorySnapshot]

    /// Looks up an accessory by id.
    /// - Parameter accessoryID: The identifier to find.
    /// - Returns: The matching accessory, or `nil` when it is not in this home.
    func accessory(_ accessoryID: String) -> AccessorySnapshot? {
        accessories.first { $0.id == accessoryID }
    }

    /// The accessories that belong to a given room, in the home's accessory order.
    /// - Parameter roomID: The room to filter by.
    /// - Returns: The accessories assigned to that room.
    func accessories(in roomID: String) -> [AccessorySnapshot] {
        accessories.filter { $0.roomID == roomID }
    }
}
