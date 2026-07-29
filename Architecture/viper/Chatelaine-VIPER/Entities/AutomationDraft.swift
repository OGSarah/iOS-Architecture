//
//  AutomationDraft.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// One write an action set performs when a trigger fires.
struct DraftAction: Sendable, Equatable, Hashable, Identifiable {
    let id: String
    let characteristicID: String
    let targetValue: CharacteristicValue
}

/// An automation being assembled, which may or may not yet be valid.
///
/// A draft is data only. Being invalid is an expected state rather than an error, and validation
/// lives in the Interactor, not here. `AutomationDraft.ID` lets the Router carry a draft across the
/// builder flow without the draft knowing anything about navigation.
struct AutomationDraft: Sendable, Equatable, Hashable, Identifiable {
    let id: String
    var name: String
    var condition: TriggerCondition
    var actions: [DraftAction]
}
