//
//  AccessoryCommissioning.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// The outcome of a commissioning attempt.
enum CommissionResult: Sendable, Equatable {
    /// The device was added and its new accessory id is available.
    case added(accessoryID: String)
    /// The user cancelled the system commissioning UI.
    case cancelled
}

/// The reason commissioning could not proceed or complete.
struct CommissionError: Error, Sendable, Equatable {
    let reason: String

    /// The Matter setup payload entitlement is missing, or the platform cannot commission here.
    static let unavailable = CommissionError(reason: "Matter setup is not available on this device")
    static let failed = CommissionError(reason: "The device could not be added")
}

/// One protocol over MatterSupport and ThreadNetwork, so the setup module depends on a single seam.
///
/// The concrete implementation degrades to `isAvailable == false` when the Matter entitlement is
/// missing or the code runs where commissioning cannot happen, rather than crashing.
@MainActor
protocol AccessoryCommissioning: AnyObject {
    /// Whether commissioning can be attempted in the current environment.
    var isAvailable: Bool { get }

    /// Starts commissioning a device from a setup payload, handing off to system UI.
    /// - Parameter setupPayload: The Matter onboarding payload for the device.
    /// - Returns: The result once the system flow returns.
    /// - Throws: A `CommissionError` when setup is unavailable or fails.
    func commission(setupPayload: String) async throws -> CommissionResult
}
