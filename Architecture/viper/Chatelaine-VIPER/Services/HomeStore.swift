//
//  HomeStore.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation
import HomeKit

/// The one type in the project that imports HomeKit.
///
/// `HomeStore` wraps `HMHomeManager`, listens to its delegate callbacks, and converts the live,
/// non `Sendable` object graph into immutable snapshots through the mappers. Everything above it
/// depends only on the service protocols, never on this class or on HomeKit. Because HomeKit
/// delivers its callbacks on the main queue and the app runs under main actor default isolation,
/// the whole type is main actor isolated.
final class HomeStore: NSObject, HomeStoreProviding, CharacteristicWriting, NotificationPolicy {

    private let manager = HMHomeManager()

    /// Weakly held observers, notified when the home graph or authorization changes.
    private let observers = NSHashTable<AnyObject>.weakObjects()

    /// The most recently built snapshot of the primary home.
    private var currentHome: HomeSnapshot?

    /// A lookup from characteristic snapshot id to the live characteristic, rebuilt on every update.
    private var characteristicsByID: [String: HMCharacteristic] = [:]

    /// The live primary home, if one exists.
    private var primaryHome: HMHome? { manager.primaryHome ?? manager.homes.first }

    override init() {
        super.init()
        manager.delegate = self
    }

    // MARK: - HomeStoreProviding

    var authorizationStatus: HomeAuthorizationStatus {
        let status = manager.authorizationStatus
        guard status.contains(.determined) else { return .notDetermined }
        guard status.contains(.authorized) else { return .restricted }
        return manager.homes.isEmpty ? .authorizedNoHomes : .authorized
    }

    func loadPrimaryHome() async -> HomeSnapshot? {
        rebuildSnapshot()
        return currentHome
    }

    func addObserver(_ observer: HomeStoreObserver) {
        observers.add(observer)
    }

    func removeObserver(_ observer: HomeStoreObserver) {
        observers.remove(observer)
    }

    // MARK: - CharacteristicWriting

    func write(_ value: CharacteristicValue, toCharacteristic characteristicID: String) async throws {
        guard let characteristic = characteristicsByID[characteristicID] else {
            throw CharacteristicWriteError.rejected
        }
        guard characteristic.properties.contains(HMCharacteristicPropertyWritable) else {
            throw CharacteristicWriteError.notWritable
        }
        let hkValue = Self.homeKitValue(from: value)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            characteristic.writeValue(hkValue) { error in
                if error != nil {
                    continuation.resume(throwing: CharacteristicWriteError.rejected)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - NotificationPolicy

    func enableNotifications(for characteristicIDs: [String]) async {
        await setNotifications(true, for: characteristicIDs)
    }

    func disableNotifications(for characteristicIDs: [String]) async {
        await setNotifications(false, for: characteristicIDs)
    }

    private func setNotifications(_ enabled: Bool, for characteristicIDs: [String]) async {
        for id in characteristicIDs {
            guard let characteristic = characteristicsByID[id],
                  characteristic.properties.contains(HMCharacteristicPropertySupportsEventNotification) else {
                continue
            }
            // A failure to (un)subscribe is not fatal, so failures are swallowed deliberately.
            _ = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                characteristic.enableNotification(enabled) { error in
                    if let error { continuation.resume(throwing: error) } else { continuation.resume() }
                }
            }
        }
    }

    // MARK: - Snapshot building

    /// Rebuilds the immutable snapshot from the live primary home and refreshes the lookup table.
    private func rebuildSnapshot() {
        guard let home = primaryHome else {
            currentHome = nil
            characteristicsByID = [:]
            return
        }

        // Make sure we receive live value changes for every accessory in the home.
        for accessory in home.accessories where accessory.delegate == nil {
            accessory.delegate = self
        }

        var lookup: [String: HMCharacteristic] = [:]

        // Map every accessory id that a bridge vends back to the bridge, for the reachability collapse.
        var bridgeForAccessory: [String: String] = [:]
        for accessory in home.accessories {
            let bridgeID = accessory.uniqueIdentifier.uuidString
            for bridged in accessory.uniqueIdentifiersForBridgedAccessories ?? [] {
                bridgeForAccessory[bridged.uuidString] = bridgeID
            }
        }

        let accessories = home.accessories.map { accessory in
            Self.accessorySnapshot(
                accessory,
                bridgeID: bridgeForAccessory[accessory.uniqueIdentifier.uuidString],
                lookup: &lookup
            )
        }

        let rooms = home.rooms.map { room in
            RoomSnapshot(
                id: room.uniqueIdentifier.uuidString,
                name: room.name,
                accessoryIDs: room.accessories.map { $0.uniqueIdentifier.uuidString }
            )
        }

        let zones = home.zones.map { zone in
            ZoneSnapshot(
                id: zone.uniqueIdentifier.uuidString,
                name: zone.name,
                roomIDs: zone.rooms.map { $0.uniqueIdentifier.uuidString }
            )
        }

        characteristicsByID = lookup
        currentHome = HomeSnapshot(
            id: home.uniqueIdentifier.uuidString,
            name: home.name,
            isPrimary: home.isPrimary,
            rooms: rooms,
            zones: zones,
            accessories: accessories
        )
    }

    /// Builds an accessory snapshot and records its characteristics in the lookup table.
    private static func accessorySnapshot(
        _ accessory: HMAccessory,
        bridgeID: String?,
        lookup: inout [String: HMCharacteristic]
    ) -> AccessorySnapshot {
        let services = accessory.services.map { service -> ServiceSnapshot in
            let characteristics = service.characteristics.map { characteristic -> CharacteristicSnapshot in
                let id = characteristic.uniqueIdentifier.uuidString
                lookup[id] = characteristic
                return characteristicSnapshot(characteristic, id: id)
            }
            return ServiceSnapshot(
                id: service.uniqueIdentifier.uuidString,
                type: service.serviceType,
                name: service.name,
                characteristics: characteristics,
                linkedServiceIDs: (service.linkedServices ?? []).map { $0.uniqueIdentifier.uuidString }
            )
        }

        let isBridge = !(accessory.uniqueIdentifiersForBridgedAccessories ?? []).isEmpty
        let descriptor = AccessoryDescriptor(
            id: accessory.uniqueIdentifier.uuidString,
            name: accessory.name,
            setupID: nil,
            roomID: accessory.room?.uniqueIdentifier.uuidString,
            isBridge: isBridge,
            isReachable: accessory.isReachable,
            bridgeID: accessory.isReachable ? nil : bridgeID,
            services: services
        )
        return AccessoryMapper.snapshot(from: descriptor)
    }

    /// Builds one characteristic snapshot from its live metadata and value.
    private static func characteristicSnapshot(_ characteristic: HMCharacteristic, id: String) -> CharacteristicSnapshot {
        let metadata = metadataDescriptor(from: characteristic)
        return CharacteristicMapper.snapshot(
            id: id,
            type: characteristic.characteristicType,
            displayName: characteristic.localizedDescription,
            value: characteristicValue(from: characteristic.value, format: metadata.format),
            metadata: metadata
        )
    }

    // MARK: - Metadata and value bridging

    /// Converts HomeKit metadata into the plain descriptor the mapper understands.
    private static func metadataDescriptor(from characteristic: HMCharacteristic) -> CharacteristicMetadataDescriptor {
        let metadata = characteristic.metadata
        var permissions: CharacteristicPermissions = []
        if characteristic.properties.contains(HMCharacteristicPropertyReadable) { permissions.insert(.read) }
        if characteristic.properties.contains(HMCharacteristicPropertyWritable) { permissions.insert(.write) }
        if characteristic.properties.contains(HMCharacteristicPropertySupportsEventNotification) { permissions.insert(.notify) }

        return CharacteristicMetadataDescriptor(
            format: format(from: metadata?.format),
            permissions: permissions,
            minValue: metadata?.minimumValue?.doubleValue,
            maxValue: metadata?.maximumValue?.doubleValue,
            stepValue: metadata?.stepValue?.doubleValue,
            unit: unit(from: metadata?.units),
            validValues: metadata?.validValues?.map { $0.intValue }
        )
    }

    private static func format(from raw: String?) -> CharacteristicFormat {
        switch raw {
        case HMCharacteristicMetadataFormatBool: .bool
        case HMCharacteristicMetadataFormatInt: .int
        case HMCharacteristicMetadataFormatFloat: .float
        case HMCharacteristicMetadataFormatUInt8: .uint8
        case HMCharacteristicMetadataFormatUInt16: .uint16
        case HMCharacteristicMetadataFormatUInt32: .uint32
        case HMCharacteristicMetadataFormatUInt64: .uint64
        case HMCharacteristicMetadataFormatString: .string
        case HMCharacteristicMetadataFormatData: .data
        case HMCharacteristicMetadataFormatTLV8: .tlv8
        default: .unknown
        }
    }

    private static func unit(from raw: String?) -> CharacteristicUnit {
        switch raw {
        case HMCharacteristicMetadataUnitsPercentage: .percentage
        case HMCharacteristicMetadataUnitsCelsius: .celsius
        case HMCharacteristicMetadataUnitsFahrenheit: .fahrenheit
        case HMCharacteristicMetadataUnitsSeconds: .seconds
        case HMCharacteristicMetadataUnitsArcDegree: .arcDegrees
        case HMCharacteristicMetadataUnitsLux: .lux
        default: .none
        }
    }

    /// Closes HomeKit's `Any?` value into the project's `CharacteristicValue` enum.
    private static func characteristicValue(from value: Any?, format: CharacteristicFormat) -> CharacteristicValue {
        switch value {
        case let number as NSNumber:
            switch format {
            case .bool: .bool(number.boolValue)
            case .float: .double(number.doubleValue)
            default: format.isNumeric ? .int(number.intValue) : .double(number.doubleValue)
            }
        case let string as String:
            .string(string)
        case let data as Data:
            .data(data)
        case .none:
            .unknown
        default:
            .unknown
        }
    }

    /// Converts a `CharacteristicValue` back into the `Any?` HomeKit's write API expects.
    private static func homeKitValue(from value: CharacteristicValue) -> Any? {
        switch value {
        case let .bool(bool): NSNumber(value: bool)
        case let .int(int): NSNumber(value: int)
        case let .double(double): NSNumber(value: double)
        case let .string(string): string
        case let .data(data): data
        case .unknown: nil
        }
    }

    // MARK: - Notifying observers

    private func notifyHomeUpdate() {
        rebuildSnapshot()
        guard let home = currentHome else { return }
        for case let observer as HomeStoreObserver in observers.allObjects {
            observer.homeStoreDidUpdate(home)
        }
    }

    private func notifyAuthorizationChange() {
        let status = authorizationStatus
        for case let observer as HomeStoreObserver in observers.allObjects {
            observer.homeStoreDidChangeAuthorization(status)
        }
    }
}

// MARK: - HMHomeManagerDelegate

extension HomeStore: HMHomeManagerDelegate {

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        if let home = primaryHome, home.delegate == nil {
            home.delegate = self
        }
        notifyHomeUpdate()
        notifyAuthorizationChange()
    }

    func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        primaryHome?.delegate = self
        notifyHomeUpdate()
    }

    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        notifyAuthorizationChange()
    }
}

// MARK: - HMHomeDelegate

extension HomeStore: HMHomeDelegate {

    func home(_ home: HMHome, didUpdate room: HMRoom, for accessory: HMAccessory) {
        notifyHomeUpdate()
    }

    func home(_ home: HMHome, didAdd accessory: HMAccessory) {
        notifyHomeUpdate()
    }

    func home(_ home: HMHome, didRemove accessory: HMAccessory) {
        notifyHomeUpdate()
    }
}

// MARK: - HMAccessoryDelegate

extension HomeStore: HMAccessoryDelegate {

    // HMAccessoryDelegate is not main actor annotated, unlike the home and manager delegates.
    // HomeKit delivers these callbacks on the main thread, so it is safe to assume isolation.

    nonisolated func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        MainActor.assumeIsolated { notifyHomeUpdate() }
    }

    nonisolated func accessoryDidUpdateReachability(_ accessory: HMAccessory) {
        MainActor.assumeIsolated { notifyHomeUpdate() }
    }
}

// MARK: - TriggerReading

extension HomeStore: TriggerReading {

    func automations() async -> [AutomationSummary] {
        guard let home = primaryHome else { return [] }
        return TriggerMapper.summaries(from: home.triggers)
    }
}

// MARK: - TriggerWriting

extension HomeStore: TriggerWriting {

    func save(_ draft: AutomationDraft) async throws {
        guard let home = primaryHome else { throw TriggerWriteError.rejected }
        guard case let .valid(validDraft) = AutomationValidator.validate(draft) else {
            throw TriggerWriteError.invalidDraft
        }

        let name = validDraft.name.isEmpty ? "Automation" : validDraft.name
        let trigger = try TriggerMapper.makeTrigger(name: name, condition: validDraft.condition, lookup: characteristicsByID)

        let actionSet = try await addActionSet(named: "\(name) actions", in: home)
        for action in validDraft.actions {
            guard let characteristic = characteristicsByID[action.characteristicID] else { continue }
            try await addWriteAction(action.targetValue, to: actionSet, characteristic: characteristic)
        }

        try await add(trigger, to: home)
        try await addActionSet(actionSet, to: trigger)
        try await setEnabled(true, for: trigger)
    }

    func remove(_ automationID: String) async throws {
        guard let home = primaryHome,
              let trigger = home.triggers.first(where: { $0.uniqueIdentifier.uuidString == automationID }) else {
            throw TriggerWriteError.rejected
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.removeTrigger(trigger) { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        }
    }

    // MARK: Continuation helpers

    private func addActionSet(named name: String, in home: HMHome) async throws -> HMActionSet {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HMActionSet, Error>) in
            home.addActionSet(withName: name) { actionSet, error in
                if let actionSet {
                    continuation.resume(returning: actionSet)
                } else {
                    continuation.resume(throwing: error ?? TriggerWriteError.rejected)
                }
            }
        }
    }

    private func addWriteAction(_ value: CharacteristicValue, to actionSet: HMActionSet, characteristic: HMCharacteristic) async throws {
        // The write action is generic over its value type, so build it with the concrete type.
        let action: HMAction
        switch value {
        case let .bool(bool): action = HMCharacteristicWriteAction(characteristic: characteristic, targetValue: NSNumber(value: bool))
        case let .int(int): action = HMCharacteristicWriteAction(characteristic: characteristic, targetValue: NSNumber(value: int))
        case let .double(double): action = HMCharacteristicWriteAction(characteristic: characteristic, targetValue: NSNumber(value: double))
        case let .string(string): action = HMCharacteristicWriteAction(characteristic: characteristic, targetValue: string as NSString)
        case .data, .unknown: return
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            actionSet.addAction(action) { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        }
    }

    private func add(_ trigger: HMTrigger, to home: HMHome) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            home.addTrigger(trigger) { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        }
    }

    private func addActionSet(_ actionSet: HMActionSet, to trigger: HMTrigger) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            trigger.addActionSet(actionSet) { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        }
    }

    private func setEnabled(_ enabled: Bool, for trigger: HMTrigger) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            trigger.enable(enabled) { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        }
    }
}
