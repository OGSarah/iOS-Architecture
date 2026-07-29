//
//  RoomListViewModel.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Rooms and their accessories, already formatted for the supplementary column.
struct RoomListViewModel: Equatable {

    struct Accessory: Equatable, Identifiable {
        let id: String
        let name: String
        /// A short reachability note, or `nil` when reachable.
        let statusText: String?
        let accessibilityLabel: String
    }

    struct Section: Equatable, Identifiable {
        let id: String
        let name: String
        let accessories: [Accessory]
    }

    let title: String
    let sections: [Section]
}
