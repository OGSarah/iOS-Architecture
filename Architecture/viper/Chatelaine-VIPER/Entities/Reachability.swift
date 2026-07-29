//
//  Reachability.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// Whether an accessory can be reached, and the reason when it cannot.
///
/// Reachability is an enum rather than a `Bool` so the Presenter can collapse many bridged
/// accessories that went offline together into a single warning, keyed by the bridge id, instead
/// of showing one identical warning per accessory.
enum Reachability: Sendable, Equatable, Hashable {
    case reachable
    case unreachable
    case unreachableViaBridge(bridgeID: String)

    /// Whether the accessory is currently reachable.
    var isReachable: Bool { self == .reachable }
}
