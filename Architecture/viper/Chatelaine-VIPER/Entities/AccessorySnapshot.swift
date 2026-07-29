//
//  AccessorySnapshot.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// An immutable snapshot of one physical device, or one endpoint behind a bridge.
struct AccessorySnapshot: Sendable, Equatable, Hashable, Identifiable {
    let id: String
    let name: String
    /// The setup id printed on the accessory, kept for the setup flow and diagnostics.
    let setupID: String?
    /// The room the accessory belongs to, or `nil` when it is a bridge.
    let roomID: String?
    let reachability: Reachability
    let isBridge: Bool
    let services: [ServiceSnapshot]

    /// Whether the accessory exposes any writable characteristic across its services.
    var hasWritableControl: Bool {
        services.contains { service in
            service.characteristics.contains(where: \.isWritable)
        }
    }
}
