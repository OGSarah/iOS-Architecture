//
//  TriggerReading.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

/// The read seam the automation list depends on to show the saved automations.
@MainActor
protocol TriggerReading: AnyObject {
    /// Loads a summary of every automation in the primary home.
    /// - Returns: The automations, in the home's order.
    func automations() async -> [AutomationSummary]
}
