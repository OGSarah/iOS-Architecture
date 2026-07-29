//
//  AccessoryDetailViewModel.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Everything the AccessoryDetail View is allowed to see, already formatted.
///
/// There is no `AccessorySnapshot` here. The View renders these strings and never learns that an
/// entity produced them, which is the boundary the presenter test guards.
struct AccessoryDetailViewModel: Equatable {

    /// One service row, tappable to open that service's controls.
    struct ServiceRow: Equatable, Identifiable {
        let id: String
        let name: String
        /// A short summary such as "2 controls".
        let detail: String
        let accessibilityLabel: String
    }

    let title: String
    /// A reachability note such as "Unreachable, bridge offline", or `nil` when reachable.
    let statusText: String?
    let services: [ServiceRow]
}
