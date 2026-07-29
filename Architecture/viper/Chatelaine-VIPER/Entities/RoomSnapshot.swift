//
//  RoomSnapshot.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// An immutable snapshot of a named space that owns some accessories.
struct RoomSnapshot: Sendable, Equatable, Hashable, Identifiable {
    let id: String
    let name: String
    let accessoryIDs: [String]
}
