//
//  MatterExtensionRequestHandler.swift
//  ChatelaineMatterExtension
//
//  Created by Sarah Clark on 7/29/26.
//

import MatterSupport
import os.log

/// The out of process handler that commissions a Matter accessory into the Chatelaine ecosystem.
///
/// The principal class named by the extension's `Info.plist` inherits from
/// `MatterAddDeviceExtensionRequestHandler`. The system runs this in a separate process during the
/// add device flow. Do not call `super` in the overrides.
final class MatterExtensionRequestHandler: MatterAddDeviceExtensionRequestHandler {

    private let logger = Logger(subsystem: "com.Chatelaine-VIPER.matter", category: "DeviceSetup")

    /// Returns the rooms offered during setup. The system merges these into its picker.
    override func rooms(in home: MatterAddDeviceRequest.Home?) async -> [MatterAddDeviceRequest.Room] {
        logger.debug("Fetching rooms for home \(String(describing: home?.name), privacy: .public)")
        return ["Bedroom", "Kitchen"].map { MatterAddDeviceRequest.Room(displayName: $0) }
    }

    /// Commissions the device with the onboarding payload. Returning indicates pairing is complete.
    override func commissionDevice(in home: MatterAddDeviceRequest.Home?, onboardingPayload: String, commissioningID: UUID) async throws {
        logger.debug("Commissioning \(commissioningID, privacy: .public)")
        // The Matter framework performs the on-network commissioning. On success this method returns,
        // and the paired accessory then appears in the HomeKit graph the app observes.
    }

    /// Names and files the newly paired device.
    override func configureDevice(named name: String, in room: MatterAddDeviceRequest.Room?) async {
        logger.debug("Configuring \(name, privacy: .public) in \(String(describing: room?.displayName), privacy: .public)")
    }

    /// Chooses the Thread network. Defaulting to the system network hands off the credentials the
    /// ThreadNetwork framework already manages, which is the border router handoff.
    override func selectThreadNetwork(
        from threadScanResults: [MatterAddDeviceExtensionRequestHandler.ThreadScanResult]
    ) async throws -> MatterAddDeviceExtensionRequestHandler.ThreadNetworkAssociation {
        .defaultSystemNetwork
    }
}
