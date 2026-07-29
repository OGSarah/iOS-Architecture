//
//  MatterCommissioner.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import Foundation
import MatterSupport
#if canImport(ThreadNetwork)
import ThreadNetwork
#endif

/// The concrete `AccessoryCommissioning` seam, wrapping MatterSupport and ThreadNetwork.
///
/// Commissioning hands control to an out of process system flow and a companion extension, neither
/// of which exists in the Simulator, so `isAvailable` reports `false` there and the setup module
/// shows a clear unavailable state rather than failing mid flow. On device the request is performed
/// and any failure, including a missing entitlement, degrades to a reported error. ThreadNetwork is
/// only present on device SDKs, so its use is guarded by `canImport`.
final class MatterCommissioner: AccessoryCommissioning {

    private let ecosystemName: String
    private let homeName: String

    init(ecosystemName: String = "Chatelaine", homeName: String = "Home") {
        self.ecosystemName = ecosystemName
        self.homeName = homeName
    }

    var isAvailable: Bool {
        // Matter commissioning cannot run in the Simulator, so it is honestly reported unavailable.
        #if targetEnvironment(simulator)
        false
        #else
        true
        #endif
    }

    func commission(setupPayload: String) async throws -> CommissionResult {
        guard isAvailable else { throw CommissionError.unavailable }

        // Warm the Thread credentials so the border router handoff has what it needs. A failure here
        // is not fatal, because the system flow can still fall back to its default network.
        await prefetchThreadCredentials()

        let topology = MatterAddDeviceRequest.Topology(
            ecosystemName: ecosystemName,
            homes: [MatterAddDeviceRequest.Home(displayName: homeName)]
        )
        let request = MatterAddDeviceRequest(topology: topology)

        do {
            try await request.perform()
            // The newly paired accessory arrives through the HomeKit graph, which the store observes,
            // so no specific accessory id is returned here.
            return .added(accessoryID: "")
        } catch {
            throw CommissionError.failed
        }
    }

    /// Reads the preferred Thread network credentials, if any, ahead of commissioning.
    private func prefetchThreadCredentials() async {
        #if canImport(ThreadNetwork) && !targetEnvironment(simulator)
        let client = THClient()
        _ = await withCheckedContinuation { (continuation: CheckedContinuation<THCredentials?, Never>) in
            client.retrievePreferredCredentials { credentials, _ in
                continuation.resume(returning: credentials)
            }
        }
        #endif
    }
}
