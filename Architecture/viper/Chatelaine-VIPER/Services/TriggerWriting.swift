//
//  TriggerWriting.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// The reason a trigger could not be saved.
struct TriggerWriteError: Error, Sendable, Equatable {
    let reason: String

    static let invalidDraft = TriggerWriteError(reason: "The automation is not complete")
    static let rejected = TriggerWriteError(reason: "HomeKit rejected the automation")
}

/// The seam the automation modules use to persist or remove triggers.
@MainActor
protocol TriggerWriting: AnyObject {
    /// Saves an automation draft as a HomeKit trigger.
    /// - Parameter draft: The validated draft to persist.
    /// - Throws: A `TriggerWriteError` when the draft is invalid or HomeKit rejects it.
    func save(_ draft: AutomationDraft) async throws

    /// Removes an automation by id.
    /// - Parameter automationID: The identifier of the automation to remove.
    /// - Throws: A `TriggerWriteError` when removal fails.
    func remove(_ automationID: String) async throws
}
