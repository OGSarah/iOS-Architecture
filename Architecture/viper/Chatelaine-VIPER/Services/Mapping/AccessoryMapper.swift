//
//  AccessoryMapper.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// A plain, `Sendable` description of an accessory as HomeKit reports it.
///
/// `HomeStore` builds one of these from an `HMAccessory` so the reachability rules below can be
/// tested without a device. The key rule is the bridge collapse, where an accessory that is
/// unreachable because its bridge is down reports `unreachableViaBridge` rather than a bare
/// `unreachable`, letting the Presenter group many offline accessories under one warning.
struct AccessoryDescriptor: Sendable, Equatable, Hashable {
    let id: String
    let name: String
    let setupID: String?
    let roomID: String?
    let isBridge: Bool
    let isReachable: Bool
    /// The bridge this accessory sits behind, or `nil` when it connects directly.
    let bridgeID: String?
    let services: [ServiceSnapshot]
}

/// Turns accessory descriptors into immutable snapshots, resolving reachability along the way.
enum AccessoryMapper {

    /// Maps a single accessory descriptor to a snapshot.
    /// - Parameter descriptor: The plain description built from HomeKit.
    /// - Returns: An immutable `AccessorySnapshot` with resolved reachability.
    static func snapshot(from descriptor: AccessoryDescriptor) -> AccessorySnapshot {
        AccessorySnapshot(
            id: descriptor.id,
            name: descriptor.name,
            setupID: descriptor.setupID,
            roomID: descriptor.roomID,
            reachability: reachability(for: descriptor),
            isBridge: descriptor.isBridge,
            services: descriptor.services
        )
    }

    /// Resolves reachability, attributing an outage to a bridge when one is responsible.
    /// - Parameter descriptor: The accessory being resolved.
    /// - Returns: `.reachable`, `.unreachable`, or `.unreachableViaBridge`.
    static func reachability(for descriptor: AccessoryDescriptor) -> Reachability {
        guard !descriptor.isReachable else { return .reachable }
        if let bridgeID = descriptor.bridgeID {
            return .unreachableViaBridge(bridgeID: bridgeID)
        }
        return .unreachable
    }
}
