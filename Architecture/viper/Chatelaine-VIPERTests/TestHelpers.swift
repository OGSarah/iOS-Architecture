//
//  TestHelpers.swift
//  Chatelaine-VIPERTests
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation
@testable import Chatelaine_VIPER

// The app runs under main actor default isolation, so the value types and pure mappers are main
// actor isolated. The test helpers and suites are marked @MainActor to match, which lets them
// reference those types directly.

/// Builds characteristic metadata descriptors for the mapping tests without touching HomeKit.
@MainActor
enum MetadataBuilder {

    /// Assembles a descriptor from individually overridable parts.
    static func make(
        format: CharacteristicFormat,
        read: Bool = true,
        write: Bool = true,
        notify: Bool = true,
        min: Double? = nil,
        max: Double? = nil,
        step: Double? = nil,
        unit: CharacteristicUnit = .none,
        validValues: [Int]? = nil
    ) -> CharacteristicMetadataDescriptor {
        var permissions: CharacteristicPermissions = []
        if read { permissions.insert(.read) }
        if write { permissions.insert(.write) }
        if notify { permissions.insert(.notify) }
        return CharacteristicMetadataDescriptor(
            format: format,
            permissions: permissions,
            minValue: min,
            maxValue: max,
            stepValue: step,
            unit: unit,
            validValues: validValues
        )
    }
}

/// Builds accessory descriptors for the reachability tests.
@MainActor
enum AccessoryBuilder {

    static func make(
        id: String,
        name: String = "Accessory",
        roomID: String? = "room.bedroom",
        isBridge: Bool = false,
        isReachable: Bool = true,
        bridgeID: String? = nil,
        services: [ServiceSnapshot] = []
    ) -> AccessoryDescriptor {
        AccessoryDescriptor(
            id: id,
            name: name,
            setupID: nil,
            roomID: roomID,
            isBridge: isBridge,
            isReachable: isReachable,
            bridgeID: bridgeID,
            services: services
        )
    }
}

/// A small canned household used across the presenter and interactor tests.
@MainActor
enum TestHouseholds {

    static func lightService(power: Bool = false, brightness: Int = 60) -> ServiceSnapshot {
        ServiceSnapshot(
            id: "service.light",
            type: "lightbulb",
            name: "Overhead Light",
            characteristics: [
                CharacteristicSnapshot(
                    id: "char.power",
                    type: "power",
                    displayName: "Power",
                    value: .bool(power),
                    controlKind: .toggle,
                    isWritable: true
                ),
                CharacteristicSnapshot(
                    id: "char.brightness",
                    type: "brightness",
                    displayName: "Brightness",
                    value: .int(brightness),
                    controlKind: .slider(min: 0, max: 100, unit: .percentage),
                    isWritable: true
                )
            ],
            linkedServiceIDs: []
        )
    }

    static func home() -> HomeSnapshot {
        let light = AccessorySnapshot(
            id: "accessory.light",
            name: "Bedroom Overhead Light",
            setupID: "12663208",
            roomID: "room.bedroom",
            reachability: .reachable,
            isBridge: false,
            services: [lightService()]
        )
        let bedroom = RoomSnapshot(id: "room.bedroom", name: "Bedroom", accessoryIDs: ["accessory.light"])
        return HomeSnapshot(
            id: "home.chatelaine",
            name: "Chatelaine House",
            isPrimary: true,
            rooms: [bedroom],
            zones: [],
            accessories: [light]
        )
    }
}
