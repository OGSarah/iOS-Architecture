//
//  ScriptedHomeStore.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

#if DEBUG
import Foundation

/// A `HomeServicing` that replays a fixed household, used by the UI tests in DEBUG builds only.
///
/// It lets every end to end flow run without HomeKit permission, the accessory simulator, or a write
/// actually reaching hardware. Writes to the AC unit are rejected on purpose, so the optimistic write
/// and rollback flow has something deterministic to exercise.
final class ScriptedHomeStore: HomeServicing {

    private let observers = NSHashTable<AnyObject>.weakObjects()
    private var home: HomeSnapshot = ScriptedHomeStore.makeHousehold()

    var authorizationStatus: HomeAuthorizationStatus { .authorized }

    func loadPrimaryHome() async -> HomeSnapshot? { home }

    func addObserver(_ observer: HomeStoreObserver) { observers.add(observer) }

    func removeObserver(_ observer: HomeStoreObserver) { observers.remove(observer) }

    // MARK: - CharacteristicWriting

    func write(_ value: CharacteristicValue, toCharacteristic characteristicID: String) async throws {
        // The AC unit always rejects, so the rollback flow is deterministic.
        if characteristicID.hasPrefix("ac.") {
            throw CharacteristicWriteError.unreachable
        }
        home = Self.applying(value, to: characteristicID, in: home)
        for case let observer as HomeStoreObserver in observers.allObjects {
            observer.homeStoreDidUpdate(home)
        }
    }

    // MARK: - NotificationPolicy

    func enableNotifications(for characteristicIDs: [String]) async {}
    func disableNotifications(for characteristicIDs: [String]) async {}

    // MARK: - TriggerReading

    func automations() async -> [AutomationSummary] { [] }

    // MARK: - TriggerWriting

    func save(_ draft: AutomationDraft) async throws {
        guard case .valid = AutomationValidator.validate(draft) else {
            throw TriggerWriteError.invalidDraft
        }
        // A valid draft is accepted without touching HomeKit.
    }

    func remove(_ automationID: String) async throws {}

    // MARK: - Household

    private static func applying(_ value: CharacteristicValue, to characteristicID: String, in home: HomeSnapshot) -> HomeSnapshot {
        let accessories = home.accessories.map { accessory -> AccessorySnapshot in
            let services = accessory.services.map { service -> ServiceSnapshot in
                let characteristics = service.characteristics.map { characteristic in
                    characteristic.id == characteristicID ? characteristic.withValue(value) : characteristic
                }
                return ServiceSnapshot(
                    id: service.id,
                    type: service.type,
                    name: service.name,
                    characteristics: characteristics,
                    linkedServiceIDs: service.linkedServiceIDs
                )
            }
            return AccessorySnapshot(
                id: accessory.id,
                name: accessory.name,
                setupID: accessory.setupID,
                roomID: accessory.roomID,
                reachability: accessory.reachability,
                isBridge: accessory.isBridge,
                services: services
            )
        }
        return HomeSnapshot(id: home.id, name: home.name, isPrimary: home.isPrimary, rooms: home.rooms, zones: home.zones, accessories: accessories)
    }

    private static func makeHousehold() -> HomeSnapshot {
        let bedroom = RoomSnapshot(id: "room.bedroom", name: "Bedroom", accessoryIDs: ["light", "ac", "purifier", "fan"])
        let kitchen = RoomSnapshot(id: "room.kitchen", name: "Kitchen", accessoryIDs: ["faucet"])

        let light = AccessorySnapshot(
            id: "light", name: "Bedroom Overhead Light", setupID: "12663208", roomID: "room.bedroom",
            reachability: .reachable, isBridge: false,
            services: [ServiceSnapshot(id: "light.service", type: "lightbulb", name: "Overhead Light", characteristics: [
                CharacteristicSnapshot(id: "light.power", type: "power", displayName: "Power", value: .bool(false), controlKind: .toggle, isWritable: true),
                CharacteristicSnapshot(id: "light.brightness", type: "brightness", displayName: "Brightness", value: .int(60), controlKind: .slider(min: 0, max: 100, unit: .percentage), isWritable: true)
            ], linkedServiceIDs: [])]
        )

        let ac = AccessorySnapshot(
            id: "ac", name: "AC Unit", setupID: "99831234", roomID: "room.bedroom",
            reachability: .reachable, isBridge: false,
            services: [ServiceSnapshot(id: "ac.service", type: "heaterCooler", name: "AC Unit", characteristics: [
                CharacteristicSnapshot(id: "ac.active", type: "active", displayName: "Active", value: .bool(false), controlKind: .toggle, isWritable: true),
                CharacteristicSnapshot(id: "ac.current", type: "currentTemperature", displayName: "Current Temperature", value: .double(24.5), controlKind: .readout(unit: .celsius), isWritable: false),
                CharacteristicSnapshot(id: "ac.target", type: "targetTemperature", displayName: "Target Temperature", value: .double(21), controlKind: .stepper(min: 16, max: 30, step: 0.5, unit: .celsius), isWritable: true)
            ], linkedServiceIDs: [])]
        )

        let purifier = AccessorySnapshot(
            id: "purifier", name: "Air Purifier", setupID: "93344740", roomID: "room.bedroom",
            reachability: .reachable, isBridge: false,
            services: [ServiceSnapshot(id: "purifier.service", type: "airPurifier", name: "Air Purifier", characteristics: [
                CharacteristicSnapshot(id: "purifier.active", type: "active", displayName: "Active", value: .bool(true), controlKind: .toggle, isWritable: true),
                CharacteristicSnapshot(id: "purifier.quality", type: "airQuality", displayName: "Air Quality", value: .int(2), controlKind: .readout(unit: .none), isWritable: false)
            ], linkedServiceIDs: [])]
        )

        let fan = AccessorySnapshot(
            id: "fan", name: "Bedroom Fan", setupID: "54314619", roomID: "room.bedroom",
            reachability: .unreachableViaBridge(bridgeID: "bridge"), isBridge: false,
            services: [ServiceSnapshot(id: "fan.service", type: "fan", name: "Fan", characteristics: [
                CharacteristicSnapshot(id: "fan.power", type: "power", displayName: "Power", value: .bool(false), controlKind: .toggle, isWritable: true),
                CharacteristicSnapshot(id: "fan.speed", type: "rotationSpeed", displayName: "Speed", value: .int(0), controlKind: .stepper(min: 0, max: 100, step: 10, unit: .percentage), isWritable: true)
            ], linkedServiceIDs: [])]
        )

        let faucet = AccessorySnapshot(
            id: "faucet", name: "Kitchen Faucet", setupID: "15070485", roomID: "room.kitchen",
            reachability: .reachable, isBridge: false,
            services: [ServiceSnapshot(id: "faucet.service", type: "valve", name: "Faucet", characteristics: [
                CharacteristicSnapshot(id: "faucet.active", type: "active", displayName: "Active", value: .bool(false), controlKind: .toggle, isWritable: true)
            ], linkedServiceIDs: [])]
        )

        let bridge = AccessorySnapshot(
            id: "bridge", name: "Bridge", setupID: "06029003", roomID: nil,
            reachability: .reachable, isBridge: true, services: []
        )

        return HomeSnapshot(
            id: "home.chatelaine", name: "Chatelaine House", isPrimary: true,
            rooms: [bedroom, kitchen], zones: [],
            accessories: [bridge, light, ac, purifier, fan, faucet]
        )
    }
}
#endif
