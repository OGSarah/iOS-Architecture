//
//  AutomationSummary.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// An immutable summary of a saved automation, for the list view.
///
/// The builder works with an `AutomationDraft`. Once saved, the list only needs enough to show a
/// row, which is this. Nothing here is an `HMTrigger`.
struct AutomationSummary: Sendable, Equatable, Hashable, Identifiable {
    let id: String
    let name: String
    /// A short description of what the automation reacts to, for example "Timer".
    let detail: String
    let isEnabled: Bool
}
